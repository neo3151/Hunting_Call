import * as fs from 'fs';
import { KnowledgeBase } from './KnowledgeBase';
import { AgentTask } from './Agent';

export class DashboardGenerator {
    static generate(kb: KnowledgeBase, tasks: AgentTask[], review: string, outputPath: string) {
        const facts = kb.getAllFacts();

        const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sentinel Orchestrator Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #0f172a;
            --card-bg: rgba(30, 41, 59, 0.7);
            --accent: #38bdf8;
            --text: #f8fafc;
            --success: #22c55e;
            --waiting: #f59e0b;
        }
        body {
            background-color: var(--bg);
            color: var(--text);
            font-family: 'Outfit', sans-serif;
            margin: 0;
            padding: 40px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .container {
            max-width: 1000px;
            width: 100%;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 30px;
            background: linear-gradient(to right, #38bdf8, #818cf8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: center;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        .card {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 20px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        }
        .card h2 {
            margin-top: 0;
            font-size: 1.25rem;
            color: var(--accent);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            padding-bottom: 10px;
            margin-bottom: 15px;
        }
        .task-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
        }
        .status-badge {
            font-size: 0.75rem;
            padding: 2px 8px;
            border-radius: 99px;
            text-transform: uppercase;
            font-weight: 600;
        }
        .status-completed { background: var(--success); color: white; }
        .status-waiting { background: var(--waiting); color: white; }
        .fact-item {
            display: flex;
            flex-direction: column;
            gap: 4px;
            margin-bottom: 12px;
        }
        .fact-key { font-weight: 600; color: #94a3b8; font-size: 0.85rem; }
        .fact-val { color: var(--text); }
        pre {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 8px;
            font-size: 0.85rem;
            overflow-x: auto;
            white-space: pre-wrap;
            color: #cbd5e1;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>SENTINEL COMMAND CENTER</h1>
        
        <div class="grid">
            <div class="card">
                <h2>Mission Progress</h2>
                ${tasks.map(t => `
                    <div class="task-item">
                        <span>${t.id}</span>
                        <span class="status-badge status-${t.status}">${t.status}</span>
                    </div>
                `).join('')}
            </div>

            <div class="card">
                <h2>Efficiency Leaderboard</h2>
                <div style="display: flex; flex-direction: column; gap: 15px;">
                    ${review.split('AGENT CONTRIBUTIONS:')[1]?.split('---------')[0]?.trim().split('\n').map(line => {
            const parts = line.split('|');
            const name = parts[0]?.replace('-', '').trim();
            const time = parts[1]?.split(':')[1]?.replace('ms', '').trim() || '0';
            const impact = parts[2]?.split(':')[1]?.trim() || '0';
            const width = Math.min(100, (parseInt(impact) * 2));
            return `
                            <div style="flex: 1;">
                                <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 5px;">
                                    <span>${name}</span>
                                    <span style="color: var(--accent);">${impact} pts (${time}ms)</span>
                                </div>
                                <div style="height: 6px; background: rgba(255,255,255,0.1); border-radius: 3px; overflow: hidden;">
                                    <div style="height: 100%; width: ${width}%; background: var(--accent); box-shadow: 0 0 10px var(--accent);"></div>
                                </div>
                            </div>
                        `;
        }).join('') || '<p>No data available</p>'}
                </div>
            </div>
        </div>

        <div class="card" style="margin-top: 20px;">
            <h2>Workplace Review</h2>
            <pre>${review}</pre>
        </div>
    </div>
</body>
</html>
        `;

        fs.writeFileSync(outputPath, html);
    }
}
