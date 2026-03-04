#!/usr/bin/env python3
"""
OUTCALL — Firestore Stress Test
Simulates concurrent users to find backend breaking points.

Usage:
  pip install firebase-admin
  python scripts/stress_test_firestore.py [--users 50] [--rounds 3]
"""

import argparse
import asyncio
import json
import os
import random
import string
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore

# ─── Config ────────────────────────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT = os.path.join(SCRIPT_DIR, 'service-account.json')
TEST_PREFIX = 'stress_test_'  # All test docs use this prefix for easy cleanup

# Animal IDs to target for leaderboard tests
ANIMAL_IDS = [
    'deer_buck_grunt', 'duck_mallard_greeting', 'turkey_purr',
    'coyote_challenge', 'goose_canadian_honk',
]

# ─── Helpers ───────────────────────────────────────────────────────────────

def random_name():
    return f"{TEST_PREFIX}user_{''.join(random.choices(string.ascii_lowercase, k=6))}"

def random_score():
    return round(random.uniform(20.0, 98.0), 2)

def make_profile_data(user_id: str) -> dict:
    return {
        'id': user_id,
        'name': random_name(),
        'email': f'{user_id}@stresstest.local',
        'joinedDate': datetime.now().isoformat(),
        'birthday': None,
        'totalCalls': random.randint(0, 500),
        'averageScore': random_score(),
        'currentStreak': random.randint(0, 30),
        'longestStreak': random.randint(0, 60),
        'dailyChallengesCompleted': random.randint(0, 100),
        'lastDailyChallengeDate': None,
        'achievements': [f'ach_{i}' for i in range(random.randint(0, 10))],
        'history': [],
    }

def make_leaderboard_entry(user_id: str) -> dict:
    return {
        'userId': user_id,
        'userName': random_name(),
        'score': random_score(),
        'date': datetime.now().isoformat(),
    }

# ─── Test Functions ────────────────────────────────────────────────────────

class StressTestResults:
    def __init__(self):
        self.successes = 0
        self.failures = 0
        self.errors = []
        self.latencies = []

    def record_success(self, latency_ms: float):
        self.successes += 1
        self.latencies.append(latency_ms)

    def record_failure(self, error: str):
        self.failures += 1
        self.errors.append(error)

    def summary(self, label: str) -> str:
        total = self.successes + self.failures
        avg_ms = sum(self.latencies) / len(self.latencies) if self.latencies else 0
        p95_ms = sorted(self.latencies)[int(len(self.latencies) * 0.95)] if self.latencies else 0
        max_ms = max(self.latencies) if self.latencies else 0
        lines = [
            f"\n{'='*60}",
            f"  {label}",
            f"{'='*60}",
            f"  Total:     {total}",
            f"  ✅ Success:  {self.successes}",
            f"  ❌ Failed:   {self.failures}",
            f"  ⏱  Avg:      {avg_ms:.0f} ms",
            f"  ⏱  P95:      {p95_ms:.0f} ms",
            f"  ⏱  Max:      {max_ms:.0f} ms",
        ]
        if self.errors:
            lines.append(f"  Errors (first 5):")
            for e in self.errors[:5]:
                lines.append(f"    - {e}")
        lines.append(f"{'='*60}")
        return '\n'.join(lines)


def test_profile_writes(db, num_users: int) -> StressTestResults:
    """Simulate N users creating/updating profiles concurrently."""
    results = StressTestResults()
    user_ids = [f"{TEST_PREFIX}{i:04d}" for i in range(num_users)]

    def write_profile(uid):
        t0 = time.time()
        try:
            db.collection('profiles').document(uid).set(make_profile_data(uid))
            results.record_success((time.time() - t0) * 1000)
        except Exception as e:
            results.record_failure(str(e))

    with ThreadPoolExecutor(max_workers=min(num_users, 20)) as pool:
        futures = [pool.submit(write_profile, uid) for uid in user_ids]
        for f in as_completed(futures):
            f.result()  # propagate exceptions

    return results


def test_profile_reads(db, num_reads: int) -> StressTestResults:
    """Simulate N concurrent profile reads."""
    results = StressTestResults()

    def read_profile(uid):
        t0 = time.time()
        try:
            doc = db.collection('profiles').document(uid).get()
            if doc.exists:
                results.record_success((time.time() - t0) * 1000)
            else:
                results.record_failure(f"Doc {uid} not found")
        except Exception as e:
            results.record_failure(str(e))

    user_ids = [f"{TEST_PREFIX}{i:04d}" for i in range(num_reads)]
    with ThreadPoolExecutor(max_workers=min(num_reads, 20)) as pool:
        futures = [pool.submit(read_profile, uid) for uid in user_ids]
        for f in as_completed(futures):
            f.result()

    return results


def test_leaderboard_contention(db, num_writers: int) -> StressTestResults:
    """Simulate N users trying to write to the SAME leaderboard doc concurrently.
    This is the most realistic stress scenario — Firestore transactions
    on the same document will contend and potentially fail.
    """
    results = StressTestResults()
    animal_id = f"{TEST_PREFIX}leaderboard"

    # Seed the doc
    db.collection('leaderboards').document(animal_id).set({
        'scores': [],
        'lastUpdated': datetime.now().isoformat(),
    })

    def submit_score(writer_id):
        t0 = time.time()
        try:
            @firestore.transactional
            def update_in_transaction(transaction, doc_ref):
                snapshot = doc_ref.get(transaction=transaction)
                scores = snapshot.get('scores') if snapshot.exists else []
                entry = make_leaderboard_entry(f'{TEST_PREFIX}user_{writer_id}')
                scores.append(entry)
                # Keep top 10 only (as per Firestore rules)
                scores = sorted(scores, key=lambda s: s['score'], reverse=True)[:10]
                transaction.update(doc_ref, {
                    'scores': scores,
                    'lastUpdated': datetime.now().isoformat(),
                })

            doc_ref = db.collection('leaderboards').document(animal_id)
            transaction = db.transaction()
            update_in_transaction(transaction, doc_ref)
            results.record_success((time.time() - t0) * 1000)
        except Exception as e:
            results.record_failure(str(e))

    with ThreadPoolExecutor(max_workers=min(num_writers, 20)) as pool:
        futures = [pool.submit(submit_score, i) for i in range(num_writers)]
        for f in as_completed(futures):
            f.result()

    return results


def test_burst_reads(db, num_reads: int) -> StressTestResults:
    """Burst-read multiple collections simultaneously."""
    results = StressTestResults()

    def read_collection(collection_name):
        t0 = time.time()
        try:
            docs = db.collection(collection_name).limit(50).get()
            results.record_success((time.time() - t0) * 1000)
        except Exception as e:
            results.record_failure(str(e))

    collections = ['profiles', 'leaderboards', 'config']
    tasks = collections * (num_reads // len(collections) + 1)
    tasks = tasks[:num_reads]

    with ThreadPoolExecutor(max_workers=min(num_reads, 20)) as pool:
        futures = [pool.submit(read_collection, c) for c in tasks]
        for f in as_completed(futures):
            f.result()

    return results


def test_profile_list_query(db) -> StressTestResults:
    """Test the collection-level list query that's flagged as temporary
    in Firestore rules. Measures how long it takes to list all profiles.
    """
    results = StressTestResults()
    t0 = time.time()
    try:
        docs = list(db.collection('profiles').get())
        results.record_success((time.time() - t0) * 1000)
        print(f"  📊 Profile list returned {len(docs)} documents")
    except Exception as e:
        results.record_failure(str(e))
    return results


def cleanup_test_data(db):
    """Remove all stress test documents."""
    print("\n🧹 Cleaning up test data...")
    batch = db.batch()
    count = 0

    # Clean profiles
    for doc in db.collection('profiles').get():
        if doc.id.startswith(TEST_PREFIX):
            batch.delete(doc.reference)
            count += 1

    # Clean leaderboards
    for doc in db.collection('leaderboards').get():
        if doc.id.startswith(TEST_PREFIX):
            batch.delete(doc.reference)
            count += 1

    if count > 0:
        batch.commit()
    print(f"  Deleted {count} test documents")


# ─── Main ──────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='OUTCALL Firestore Stress Test')
    parser.add_argument('--users', type=int, default=50, help='Number of simulated users (default: 50)')
    parser.add_argument('--rounds', type=int, default=3, help='Rounds per test (default: 3)')
    parser.add_argument('--no-cleanup', action='store_true', help='Skip cleanup of test data')
    args = parser.parse_args()

    # Initialize Firebase
    if not os.path.exists(SERVICE_ACCOUNT):
        print(f"❌ Service account not found: {SERVICE_ACCOUNT}")
        sys.exit(1)

    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred, {
        'projectId': 'hunting-call-perfection',
    })
    db = firestore.client()

    print(f"""
╔══════════════════════════════════════════════════════╗
║          OUTCALL Firestore Stress Test               ║
║  Project: hunting-call-perfection                    ║
║  Users: {args.users:<5} | Rounds: {args.rounds:<5}                   ║
╚══════════════════════════════════════════════════════╝
""")

    all_results = []

    for round_num in range(1, args.rounds + 1):
        print(f"\n🔄 Round {round_num}/{args.rounds}")
        print("-" * 40)

        # Test 1: Profile Writes
        print(f"  📝 Writing {args.users} profiles concurrently...")
        r = test_profile_writes(db, args.users)
        all_results.append(('Profile Writes', r))
        print(r.summary(f'Round {round_num} — Profile Writes ({args.users} users)'))

        # Test 2: Profile Reads
        print(f"  📖 Reading {args.users} profiles concurrently...")
        r = test_profile_reads(db, args.users)
        all_results.append(('Profile Reads', r))
        print(r.summary(f'Round {round_num} — Profile Reads ({args.users} users)'))

        # Test 3: Leaderboard Contention
        print(f"  🏆 Simulating {args.users} leaderboard submissions to SAME doc...")
        r = test_leaderboard_contention(db, args.users)
        all_results.append(('Leaderboard Contention', r))
        print(r.summary(f'Round {round_num} — Leaderboard Contention ({args.users} writers)'))

        # Test 4: Burst Reads
        print(f"  💨 Burst reading {args.users * 2} documents...")
        r = test_burst_reads(db, args.users * 2)
        all_results.append(('Burst Reads', r))
        print(r.summary(f'Round {round_num} — Burst Reads ({args.users * 2} reads)'))

    # Test 5: Profile List Query
    print(f"\n  📋 Testing profile list query (security concern)...")
    r = test_profile_list_query(db)
    all_results.append(('Profile List', r))
    print(r.summary('Profile List Query'))

    # Summary
    print(f"""
╔══════════════════════════════════════════════════════╗
║                  FINAL SUMMARY                       ║
╠══════════════════════════════════════════════════════╣""")

    total_success = sum(r.successes for _, r in all_results)
    total_failure = sum(r.failures for _, r in all_results)
    total = total_success + total_failure
    all_latencies = []
    for _, r in all_results:
        all_latencies.extend(r.latencies)

    avg = sum(all_latencies) / len(all_latencies) if all_latencies else 0
    p95 = sorted(all_latencies)[int(len(all_latencies) * 0.95)] if all_latencies else 0

    print(f"║  Total operations: {total:<35}║")
    print(f"║  ✅ Successes:      {total_success:<35}║")
    print(f"║  ❌ Failures:       {total_failure:<35}║")
    print(f"║  ⏱  Avg latency:   {avg:.0f} ms{' '*(32-len(f'{avg:.0f} ms'))}║")
    print(f"║  ⏱  P95 latency:   {p95:.0f} ms{' '*(32-len(f'{p95:.0f} ms'))}║")
    print(f"╚══════════════════════════════════════════════════════╝")

    if total_failure > 0:
        print(f"\n⚠️  {total_failure} failures detected — check errors above")
    else:
        print(f"\n✅ All {total} operations succeeded!")

    # Cleanup
    if not args.no_cleanup:
        cleanup_test_data(db)
    else:
        print("\n⚠️  Skipping cleanup (--no-cleanup flag set)")

    return 1 if total_failure > total * 0.1 else 0  # Fail if >10% errors


if __name__ == '__main__':
    sys.exit(main())
