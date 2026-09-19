const assert = require('node:assert/strict');
const test = require('node:test');
const { entitlementFromSubscription } = require('../lib/index.js');

const productId = 'outcall_premium_monthly';
const futureExpiry = new Date(Date.now() + 60_000).toISOString();
const pastExpiry = new Date(Date.now() - 60_000).toISOString();

function subscription(subscriptionState, expiryTime = futureExpiry) {
  return {
    subscriptionState,
    lineItems: [{ productId, expiryTime, latestSuccessfulOrderId: 'test-order' }],
  };
}

test('active subscriptions are entitled until expiry', () => {
  const result = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_ACTIVE'),
    productId,
  );
  assert.equal(result.entitled, true);
  assert.equal(result.status, 'active');
});

test('grace-period subscriptions remain entitled', () => {
  const result = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_IN_GRACE_PERIOD'),
    productId,
  );
  assert.equal(result.entitled, true);
  assert.equal(result.status, 'grace');
});

test('canceled subscriptions remain entitled only before expiry', () => {
  const current = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_CANCELED'),
    productId,
  );
  const expired = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_CANCELED', pastExpiry),
    productId,
  );
  assert.equal(current.entitled, true);
  assert.equal(current.status, 'canceled_pending');
  assert.equal(expired.entitled, false);
  assert.equal(expired.status, 'expired');
});

test('on-hold and paused subscriptions are not entitled', () => {
  const onHold = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_ON_HOLD'),
    productId,
  );
  const paused = entitlementFromSubscription(
    subscription('SUBSCRIPTION_STATE_PAUSED'),
    productId,
  );
  assert.equal(onHold.entitled, false);
  assert.equal(paused.entitled, false);
});

test('a mismatched product is rejected', () => {
  assert.throws(
    () => entitlementFromSubscription(subscription('SUBSCRIPTION_STATE_ACTIVE'), 'other_product'),
    /does not match/,
  );
});
