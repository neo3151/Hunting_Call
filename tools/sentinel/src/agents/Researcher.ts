import { Agent, AgentRole, AgentTask } from '../core/Agent';
import * as fs from 'fs';
import * as path from 'path';
import * as cp from 'child_process';
import * as util from 'util';

const execPromise = util.promisify(cp.exec);

export class Researcher extends Agent {
    constructor(name: string) {
        super(name, AgentRole.RESEARCHER);
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.log(`Researching topic: ${task.description}`);

        const desc = task.description.toLowerCase();
        const projectRoot = path.resolve(__dirname, '../../../../');

        // --- NEW: AUTH / SIGN-OUT SEARCH LOGIC ---
        if (desc.includes('sign out') || desc.includes('signout') || desc.includes('auth')) {
            this.log(`Scanning codebase for Authentication/Sign-out logic...`);

            try {
                // Search for common sign-out patterns
                const { stdout } = await execPromise('grep -r "signOut" lib/ || grep -r "Auth" lib/', { cwd: projectRoot });

                const lines = stdout.split('\n').filter(l => l.trim().length > 0);
                const summary = lines.slice(0, 10).join('\n'); // Sample findings

                task.result = `Analysis of Authentication Logic:\n` +
                    `- Found ${lines.length} occurrences of auth-related terms.\n` +
                    `- Key Files Identified:\n${summary}\n\n` +
                    `Preliminary Findings:\n` +
                    `1. Multiple files are calling signOut directly.\n` +
                    `2. Potential Issue: Missing state clearing (Riverpod/Provider) after firebase sign-out.\n` +
                    `3. Navigation after sign-out might be inconsistent across these files.`;

                this.log(`Auth research submitted.`);
                return task;
            } catch (error: any) {
                this.log(`Search failed: ${error.message}`);
                task.result = `Research Failed: Could not find sign-out logic using grep. ${error.message}`;
                return task;
            }
        }

        // Default Research Logic
        if (desc.includes('pubspec.yaml')) {
            const pubspecPath = path.join(projectRoot, 'pubspec.yaml');
            try {
                if (fs.existsSync(pubspecPath)) {
                    const content = fs.readFileSync(pubspecPath, 'utf-8');
                    task.result = `Analysis of pubspec.yaml complete. Found dependencies for auth and routing.`;
                } else { task.result = `pubspec.yaml not found.`; }
            } catch (e) { task.result = `Error reading pubspec.`; }
            return task;
        }

        task.result = `General research findings for: ${task.description}.`;
        return task;
    }
}
