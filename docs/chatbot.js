/**
 * OUTCALL AI Assistant — Landing page chatbot
 * Uses Google Gemini API for fast, reliable AI responses.
 * Falls back to curated FAQ answers if Gemini is unavailable.
 */
(function () {
    'use strict';

    // ── Config ─────────────────────────────────────────────────────────
    const BACKEND_URL = 'https://api.huntingcalls.app';
    const MAX_TOKENS = 250;

    const SYSTEM_PROMPT = `You are the OUTCALL AI Assistant on the landing page. OUTCALL is a premium hunting call training app built by hunters, for hunters.

# APP OVERVIEW
OUTCALL helps hunters master animal calling techniques through real-time audio analysis, AI-powered scoring, and professional reference tracks. Free to download on Android (beta live now). iOS and Desktop coming Q2 2026.

# PRICING
- Free tier: Full access to recording, playback, and basic scoring
- Premium ($25/year): Unlocks AI Coach (personalized feedback powered by Gemma 3), advanced analytics, full leaderboard access, and social features

# SCORING ENGINE (How It Works)
OUTCALL records your call via the microphone at 44.1kHz/16-bit PCM, then runs real-time FFT spectral analysis in a background thread. It compares your call against professional reference tracks using:
- MFCC (Mel-Frequency Cepstral Coefficients) for timbre/tone fingerprinting
- Dynamic Time Warping (DTW) to handle tempo variations fairly
- YIN/CREPE pitch tracking for fundamental frequency accuracy
Scores are 0-100 based on four weighted metrics:
  Pitch Accuracy (40%) — is your dominant frequency hitting the animal's vocal range?
  Tone Quality (30%) — MFCC spectral matching for nasality, buzz, throat-rasp, harmonic layers
  Rhythmic Cadence (20%) — tempo stability, micro-pauses, biological variation (penalizes robotic perfection)
  Duration & Envelope (10%) — attack, sustain, and natural taper vs abrupt cutoff
The engine handles real-world conditions with adaptive noise floor filtering, sibilance rejection for wind, and lower tone penalties for muffled mics.

# CALL LIBRARY (135+ Professional Reference Calls)
17 species-specific calls including:
  Elk: Bugle, Cow Mew
  Turkey: Gobble, Yelp, Cluck & Purr, Cutting, Kee-Kee Run
  Waterfowl: Mallard Greeting, Feeding Chuckle, Goose Honk
  Deer: Buck Grunt, Doe Bleat, Snort Wheeze
  Predator: Coyote Howl, Fox Scream, Bobcat Growl, Rabbit Distress
  Other: Crow Call, Owl Hoot, Hog Grunt

# KEY FEATURES
- Real-time waveform visualization during recording
- AI Coach (premium) — personalized coaching using Gemma 3 with detailed technique tips
- Daily challenges with XP rewards
- Global leaderboards and achievements
- Weather intel with Solunar activity forecasting
- Progress Map — unlock regions as you master new species
- Hunting Log — track sessions, locations, conditions
- Shareable score cards for social media
- Offline-capable for backcountry use

# HUNTING TECHNIQUE KNOWLEDGE
Elk: Bugle technique starts low, smooth transition to high note held 2-3s, sharp drop-off. Tongue pressure on diaphragm controls pitch. Add growl with deep guttural sound. Peak rut mid-September. Use cow calls to locate, challenge bugles when close.
Turkey: Cadence and rhythm matter more than volume. Yelp is the fundamental call (vary tone, pitch, volume). Cutting is rapid excited clucks. Purr is soft content sound for close-range. Master the "phantom hen" — call once, go silent, let the bird come to you.
Waterfowl: Hail call to grab attention at distance, greeting call to welcome circling ducks, feed chuckle for close-range confidence. Match volume to distance. When ducks lock up and commit, stop calling entirely.
Deer: Soft contact grunt for curiosity, tending grunt during rut, snort-wheeze for dominance. Match aggression to rut phase. Early season = sparingly. Peak rut = deeper and louder. Overcalling is the #1 mistake.
Predator: Rabbit distress is the ultimate predator lure. Long sequences (30-40 min). Bears require extended calling. Coyotes may take 25-35 min to appear after a single howl.
General: Start soft, increase only if no response. Wait 15-30 min between sequences. Vary calls — identical repeats sound unnatural. Patience is the most underrated skill.

# COMPETITIVE ADVANTAGE
OUTCALL is the ONLY hunting call app with real-time audio analysis and scoring. Competitors:
- iHunt: Call library/playback only (750+ calls), no training or scoring
- HuntWise: Data/mapping intelligence, no call features at all
- Trophy Scan: Antler scoring via LiDAR, completely different category
No other app analyzes your technique, scores your performance, or gives AI coaching feedback.

# ROADMAP (What's Coming)
Q2 2026: iOS port, Scoring Engine V2 (pYIN/CREPE), offline mode hardening
Q3 2026: Global ranked seasons (Elo system), shareable brag-cards, live head-to-head call-offs via WebRTC
Q4 2026: Smartwatch haptics (identify bird maturity via sub-bass analysis), Bluetooth decoy integration
2027: AI-generated synthetic wildlife opponents for simulated mock hunts

# CONSERVATION & ETHICS
OUTCALL promotes responsible, ethical hunting. Over-calling educates wildlife and makes them call-shy, ruining the experience for other hunters. Less is more — patience kills more animals than perfect technique. We support NWTF, RMEF, and Ducks Unlimited.

# RULES
- Keep answers SHORT (2-4 sentences max)
- Be friendly, enthusiastic, and knowledgeable
- Use specific details from the knowledge above when relevant
- If asked about pricing: mention free + $25/year premium
- If asked about availability: Android beta is live, iOS coming Q2 2026
- If you genuinely don't know something, say "Great question! Drop your email in the beta signup and we'll get back to you"
- Never make up features not listed above`;

    // ── Curated FAQ fallback (instant answers) ───────────────────────
    const FAQ = {
        'price|cost|free|pay|subscription|premium|how much|money':
            'OUTCALL is free to download! There\'s an optional $25/year premium upgrade that unlocks the AI Coach (powered by Gemma 3) for personalized feedback on your technique.',

        'animal|species|elk|turkey|duck|deer|goose|moose|predator|waterfowl|coyote|bear|fox|rabbit|hog|owl|crow':
            'We have 135+ professional reference calls across elk, turkey, duck, deer, goose, moose, predator, waterfowl, coyote, bear, fox, rabbit, hog, owl, crow, and more \u2014 with new species added regularly!',

        'android|ios|iphone|desktop|platform|download|available':
            'The Android beta is live right now! iOS and Desktop versions are coming in Q2 2026. Sign up for early access above.',

        'score|scoring|rating|how.*work|how.*score':
            'OUTCALL scores your calls 0\u2013100 using four metrics: Pitch Accuracy (40%), Tone Quality (30%), Rhythmic Cadence (20%), and Duration & Envelope (10%). It uses FFT spectral analysis, MFCC timbre fingerprinting, and Dynamic Time Warping to compare your call against professional references.',

        'coach|feedback|gemma':
            'Our AI Coach uses Gemma 3 to analyze your performance and give personalized tips after every attempt. It identifies your weakest metric, gives specific technique cues, and tracks your progress over time. It\'s a premium feature ($25/year).',

        'weather|hunt.*condition|solunar':
            'OUTCALL includes real-time weather data with Solunar activity forecasting, barometric pressure tracking, and wind analysis so you know exactly when conditions favor your hunt.',

        'leaderboard|rank|compete|challenge':
            'Yes! We have global leaderboards and daily challenges where you can compete with hunters worldwide. Earn XP, climb the ranks, and unlock achievements. Ranked seasonal competitions are coming in Q3 2026.',

        'beta|early.*access|sign.*up|waitlist':
            'You can join the Android beta right now! Just enter your email in the signup form above and you\'ll get early access. iOS beta coming Q2 2026.',

        'compare|vs|better|different|competitor|ihunt|huntwise|other app':
            'OUTCALL is the only hunting call app that actually analyzes and scores your technique. iHunt is a great call library but has zero training features. HuntWise is mapping/data intelligence with no call features. No competitor offers real-time audio analysis, AI coaching, or performance scoring.',

        'roadmap|coming|future|plan|next|update|watch|wearable':
            'Big things ahead! iOS and Scoring Engine V2 are coming Q2 2026. Q3 brings global ranked seasons and live head-to-head call-offs. Q4 includes smartwatch haptics for in-field bird ID. And in 2027, AI-generated synthetic wildlife opponents for simulated mock hunts!',

        'conserv|ethic|responsible|over.?call':
            'We\'re passionate about ethical hunting. Over-calling educates wildlife and ruins the experience for everyone. OUTCALL teaches patience and proper technique \u2014 start soft, vary your calls, and let the animal dictate the pace. We support NWTF, RMEF, and Ducks Unlimited.',

        'beginner|start|new|learn|first':
            'Welcome! Start by exploring the call library and listening to pro reference tracks. Pick one species you hunt most, record your attempt, and check your score. Focus on Pitch Accuracy first (it\'s 40% of your score), then work on rhythm, then tone quality. 15\u201320 minutes of daily practice beats marathon sessions!',

        'record|microphone|audio|wav':
            'OUTCALL records in studio-quality 44.1kHz/16-bit PCM WAV with live waveform visualization. The analysis runs in a background thread so the app stays smooth at 60 FPS. It works with any device microphone and adapts to environmental noise automatically.',

        'technique|tip|improve|practice':
            'The #1 tip: start soft and listen before you call. Match your aggression to the season \u2014 soft in early season, louder during the rut. Vary your cadence (robotic repetition sounds unnatural). And patience is the most underrated skill in calling. Record yourself, check your score, and focus on your weakest metric first.',
    };

    function getFaqAnswer(question) {
        const q = question.toLowerCase();
        for (const [pattern, answer] of Object.entries(FAQ)) {
            if (new RegExp(pattern, 'i').test(q)) return answer;
        }
        return null;
    }

    // ── Backend Chat API ──────────────────────────────────────────────
    async function askBackend(question) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 15000);

        try {
            const res = await fetch(`${BACKEND_URL}/api/chat`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                signal: controller.signal,
                body: JSON.stringify({
                    message: question,
                    history: [],
                }),
            });
            clearTimeout(timer);

            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            const data = await res.json();
            const answer = (data.response || '').trim();
            if (answer.length > 10) return answer;
        } catch (e) {
            clearTimeout(timer);
            console.log('Chatbot: Backend unavailable', e.message);
        }
        return 'Great question! I\'m not 100% sure on that one. Drop your email in the beta signup above and our team will get back to you personally!';
    }

    // ── Chat Widget DOM ───────────────────────────────────────────────
    function createWidget() {
        const fab = document.createElement('button');
        fab.id = 'chat-fab';
        fab.innerHTML = '<i class="fas fa-comment-dots"></i>';
        fab.title = 'Ask AI about OUTCALL';

        const panel = document.createElement('div');
        panel.id = 'chat-panel';
        panel.innerHTML = `
      <div class="chat-header">
        <div class="chat-header-info">
          <div class="chat-avatar"><i class="fas fa-deer"></i></div>
          <div>
            <div class="chat-title">OUTCALL AI</div>
            <div class="chat-subtitle">Ask me anything</div>
          </div>
        </div>
        <button class="chat-close" id="chat-close">&times;</button>
      </div>
      <div class="chat-messages" id="chat-messages">
        <div class="chat-msg bot">
          <div class="chat-bubble">Hey there! \u{1F44B} I'm the OUTCALL AI assistant. Ask me anything about the app \u2014 features, scoring, species, pricing, or hunting tips!</div>
        </div>
      </div>
      <form class="chat-input-area" id="chat-form">
        <input type="text" id="chat-input" placeholder="Type a question..." autocomplete="off">
        <button type="submit" class="chat-send"><i class="fas fa-paper-plane"></i></button>
      </form>
    `;

        document.body.appendChild(fab);
        document.body.appendChild(panel);

        const chips = document.createElement('div');
        chips.className = 'chat-chips';
        chips.innerHTML = [
            'How does scoring work?',
            'What animals are supported?',
            'Is it free?',
        ].map(q => `<button class="chat-chip">${q}</button>`).join('');
        document.getElementById('chat-messages').appendChild(chips);

        let isOpen = false;

        fab.addEventListener('click', () => {
            isOpen = !isOpen;
            panel.classList.toggle('open', isOpen);
            fab.classList.toggle('active', isOpen);
            if (isOpen) document.getElementById('chat-input').focus();
        });

        document.getElementById('chat-close').addEventListener('click', () => {
            isOpen = false;
            panel.classList.remove('open');
            fab.classList.remove('active');
        });

        document.getElementById('chat-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const input = document.getElementById('chat-input');
            const q = input.value.trim();
            if (!q) return;
            input.value = '';
            sendMessage(q);
        });

        chips.querySelectorAll('.chat-chip').forEach(chip => {
            chip.addEventListener('click', () => {
                sendMessage(chip.textContent);
                chips.remove();
            });
        });
    }

    function appendMessage(text, sender) {
        const msgs = document.getElementById('chat-messages');
        const div = document.createElement('div');
        div.className = `chat-msg ${sender}`;
        div.innerHTML = `<div class="chat-bubble">${escapeHtml(text)}</div>`;
        msgs.appendChild(div);
        msgs.scrollTop = msgs.scrollHeight;
        return div;
    }

    function appendTyping() {
        const msgs = document.getElementById('chat-messages');
        const div = document.createElement('div');
        div.className = 'chat-msg bot typing-indicator';
        div.innerHTML = '<div class="chat-bubble"><span class="dot"></span><span class="dot"></span><span class="dot"></span></div>';
        msgs.appendChild(div);
        msgs.scrollTop = msgs.scrollHeight;
        return div;
    }

    function escapeHtml(text) {
        const d = document.createElement('div');
        d.textContent = text;
        return d.innerHTML;
    }

    async function sendMessage(question) {
        const chips = document.querySelector('.chat-chips');
        if (chips) chips.remove();

        appendMessage(question, 'user');

        const faqAnswer = getFaqAnswer(question);
        if (faqAnswer) {
            appendMessage(faqAnswer, 'bot');
            return;
        }

        const typing = appendTyping();
        const answer = await askBackend(question);
        typing.remove();
        appendMessage(answer, 'bot');
    }

    // ── Init ───────────────────────────────────────────────────────────
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', createWidget);
    } else {
        createWidget();
    }
})();
