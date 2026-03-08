/**
 * OUTCALL AI Assistant — Landing page chatbot
 * Uses the Ollama outcall-coach model via Cloudflare Tunnel.
 * Falls back to curated answers if Ollama is unavailable.
 */
(function () {
    'use strict';

    // ── Config ─────────────────────────────────────────────────────────
    const OLLAMA_URL = 'https://farming-idaho-location-taste.trycloudflare.com/api/generate';
    const MODEL = 'outcall-coach';
    const MAX_TOKENS = 150;
    const TIMEOUT_MS = 20000;

    const SYSTEM_PROMPT = `You are the OUTCALL AI Assistant on the OUTCALL landing page. OUTCALL is a premium hunting call training app.

KEY FACTS:
- Real-time audio analysis with FFT spectral breakdown
- AI-powered scoring on pitch, rhythm, timbre, and breath control
- 135+ professional reference calls (elk, turkey, duck, deer, predator, waterfowl, and more)
- Daily challenges, global leaderboards, and achievements
- Weather intel with hunting condition analysis
- AI Coach powered by Gemma 3 gives personalized feedback (premium feature)
- Available on Android (beta), iOS and Desktop coming soon
- Free to use with optional premium upgrade for AI Coach and advanced features
- Built by hunters, for hunters

RULES:
- Keep answers SHORT (2-3 sentences max)
- Be friendly, enthusiastic, and helpful
- If asked about pricing: "Free to download with optional premium for AI Coach features"
- If asked about availability: "Android beta is live, iOS and Desktop coming soon"
- If you don't know something, say "Great question! Drop your email in the beta signup and we'll get back to you"
- Never make up features that aren't listed above`;

    // ── Curated FAQ fallback ─────────────────────────────────────────
    const FAQ = {
        'price|cost|free|pay|subscription|premium': 'OUTCALL is free to download! There\'s an optional premium upgrade that unlocks the AI Coach (powered by Gemma 3) for personalized feedback on your technique.',
        'animal|species|call|elk|turkey|duck|deer': 'We have 135+ professional reference calls across elk, turkey, duck, deer, predator, waterfowl, and more — with new species added regularly!',
        'android|ios|iphone|desktop|platform|download': 'The Android beta is live right now! iOS and Desktop versions are coming soon. Sign up for early access above.',
        'score|scoring|rating|how.*work': 'OUTCALL analyzes your calls in real-time using FFT spectral analysis. You get scored on pitch accuracy, rhythm, timbre (tone quality), and breath control — then see exactly where to improve.',
        'ai|coach|feedback|gemma': 'Our AI Coach uses Gemma 3 to analyze your performance and give personalized tips after every attempt. It remembers your past sessions and adapts its advice as you improve. It\'s a premium feature.',
        'weather|hunt.*condition': 'OUTCALL includes real-time weather data with Solunar activity forecasting so you know exactly when conditions favor your hunt.',
        'leaderboard|rank|compete': 'Yes! We have global leaderboards where you can compete with hunters worldwide. Plus daily challenges to keep your skills sharp.',
        'beta|early.*access|sign.*up|waitlist': 'You can join the beta right now! Just enter your email in the signup form above and you\'ll get early access.',
    };

    function getFallbackAnswer(question) {
        const q = question.toLowerCase();
        for (const [pattern, answer] of Object.entries(FAQ)) {
            if (new RegExp(pattern, 'i').test(q)) return answer;
        }
        return 'Great question! I\'m not 100% sure on that one. Drop your email in the beta signup above and our team will get back to you personally!';
    }

    // ── Ollama API ─────────────────────────────────────────────────────
    async function askOllama(question) {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

        try {
            const res = await fetch(OLLAMA_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                signal: controller.signal,
                body: JSON.stringify({
                    model: MODEL,
                    prompt: question,
                    system: SYSTEM_PROMPT,
                    stream: false,
                    options: { temperature: 0.7, top_p: 0.9, num_predict: MAX_TOKENS },
                }),
            });
            clearTimeout(timer);

            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            const data = await res.json();
            const answer = (data.response || '').trim();
            return answer.length > 10 ? answer : getFallbackAnswer(question);
        } catch (e) {
            clearTimeout(timer);
            console.log('Chatbot: Ollama unavailable, using fallback', e.message);
            return getFallbackAnswer(question);
        }
    }

    // ── Chat Widget DOM ───────────────────────────────────────────────
    function createWidget() {
        // Floating button
        const fab = document.createElement('button');
        fab.id = 'chat-fab';
        fab.innerHTML = '<i class="fas fa-comment-dots"></i>';
        fab.title = 'Ask AI about OUTCALL';

        // Chat panel
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
          <div class="chat-bubble">Hey there! 👋 I'm the OUTCALL AI assistant. Ask me anything about the app — features, pricing, availability, or how the scoring works!</div>
        </div>
      </div>
      <form class="chat-input-area" id="chat-form">
        <input type="text" id="chat-input" placeholder="Type a question..." autocomplete="off">
        <button type="submit" class="chat-send"><i class="fas fa-paper-plane"></i></button>
      </form>
    `;

        document.body.appendChild(fab);
        document.body.appendChild(panel);

        // Quick-reply chips
        const chips = document.createElement('div');
        chips.className = 'chat-chips';
        chips.innerHTML = [
            'What animals are supported?',
            'How does scoring work?',
            'Is it free?',
        ].map(q => `<button class="chat-chip">${q}</button>`).join('');
        document.getElementById('chat-messages').appendChild(chips);

        // Events
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

        // Chip clicks
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
        // Remove chips if still visible
        const chips = document.querySelector('.chat-chips');
        if (chips) chips.remove();

        appendMessage(question, 'user');
        const typing = appendTyping();

        const answer = await askOllama(question);
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
