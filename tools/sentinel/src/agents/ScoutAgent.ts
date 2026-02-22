import { Agent, AgentRole, AgentTask } from '../core/Agent';
import * as fs from 'fs';
import * as path from 'path';

export class ScoutAgent extends Agent {
    constructor(name: string) {
        super(name, AgentRole.SCOUT);
        this.capabilities = ['exploration', 'discovery', 'environment-scanning', 'explore', 'lateral'];
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.think(`Evaluating exploration boundaries for mission: ${task.description}`);

        // Prioritize structured params, fallback to extraction
        let targetPath = task.params?.targetPath;
        const scope = task.params?.scope;

        if (scope === 'lateral') {
            this.think('Lateral discovery mode enabled. Scanning neighboring environments.');
            const parentDir = path.resolve(process.cwd(), '..');
            const items = fs.readdirSync(parentDir);
            const dirs = items.filter(item => {
                const fullPath = path.join(parentDir, item);
                return fs.statSync(fullPath).isDirectory() && !item.startsWith('.') && item !== 'sentinel-orchestrator';
            });

            this.think(`Discovered ${dirs.length} lateral environments: ${dirs.join(', ')}.`);
            task.result = `Lateral discovery complete. Found ${dirs.length} potential mission targets.`;
            task.status = 'completed';
            task.followUpTasks = dirs.map(dir => ({
                description: `Explore the project directory: ../${dir}`,
                params: { targetPath: `../${dir}` }
            }));
            return task;
        }

        if (!targetPath) {
            // Refined extraction logic: look for strings that look like relative paths
            const pathMatch = task.description.match(/\.\.\/[\w-]+/);
            targetPath = pathMatch ? pathMatch[0] : '.';
        }

        const absolutePath = path.resolve(process.cwd(), targetPath);

        this.plan(`1. Resolve absolute path: ${absolutePath}.
2. Scan directory for signature configuration files (package.json, pubspec.yaml, etc.).
3. Identify tech stack and platform dependencies.
4. Record discovery facts in Knowledge Base.`);

        this.log(`Exploration mission started: ${task.description}`);
        this.log(`Scanning path: ${absolutePath}`);

        try {
            if (fs.existsSync(absolutePath)) {
                this.think(`Path exists. Commencing deep scan of ${targetPath}...`);
                const files = fs.readdirSync(absolutePath);

                // Node.js / NPM Detection
                if (files.includes('package.json')) {
                    this.think(`Detected Node.js/NPM environment.`);
                    this.knowledgeBase?.addFact(`${targetPath}:stack:npm`, 'Node.js/NPM', this.name);
                    if (files.includes('vite.config.ts') || files.includes('vite.config.js')) {
                        this.knowledgeBase?.addFact(`${targetPath}:tool:vite`, 'Vite', this.name);
                    }
                    if (files.includes('ionic.config.json')) {
                        this.knowledgeBase?.addFact(`${targetPath}:framework:ionic`, 'Ionic', this.name);
                    }
                }

                // Flutter Detection
                if (files.includes('pubspec.yaml')) {
                    this.think(`Detected Flutter/Dart environment.`);
                    this.knowledgeBase?.addFact(`${targetPath}:stack:flutter`, 'Flutter/Dart', this.name);
                    if (files.includes('android')) {
                        this.knowledgeBase?.addFact(`${targetPath}:platform:android`, 'Android', this.name);
                    }
                    if (files.includes('ios')) {
                        this.knowledgeBase?.addFact(`${targetPath}:platform:ios`, 'iOS', this.name);
                    }
                }

                // Python Detection
                if (files.includes('requirements.txt') || files.includes('pyproject.toml') || files.includes('.venv')) {
                    this.think(`Detected Python environment.`);
                    this.knowledgeBase?.addFact(`${targetPath}:stack:python`, 'Python', this.name);
                }

                task.result = `Discovery complete for ${targetPath}. Found ${files.length} items. Recorded tech stack facts in Knowledge Base.`;
                task.status = 'completed';

                // Suggest follow-up tasks for newly discovered stacks (if not already audited)
                task.followUpTasks = [];
                const projectKey = targetPath === '.' ? 'global' : targetPath;

                if (this.knowledgeBase?.getFact(`${targetPath}:stack:npm`) &&
                    !this.knowledgeBase?.getFact(`${projectKey}:audit:nodejs`)) {
                    task.followUpTasks.push({
                        description: `Audit the nodejs security for ${targetPath}`,
                        params: { intelligenceSource: 'web-research:nodejs-2026' }
                    });
                }
                if (this.knowledgeBase?.getFact(`${targetPath}:stack:flutter`) &&
                    !this.knowledgeBase?.getFact(`${projectKey}:audit:flutter`)) {
                    task.followUpTasks.push({
                        description: `Audit the flutter best practices for ${targetPath}`,
                        params: { intelligenceSource: 'web-research:flutter-2026' }
                    });
                }
            } else {
                this.think(`Mission abort: Target path ${absolutePath} is unreachable.`);
                task.status = 'failed';
                task.result = `Target path does not exist: ${absolutePath}`;
            }
        } catch (error: any) {
            this.think(`CRITICAL: Exploration error encountered.`);
            task.status = 'failed';
            task.result = `Error during exploration: ${error.message}`;
        }

        return task;
    }
}
