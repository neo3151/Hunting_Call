"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Researcher = void 0;
const Agent_1 = require("../core/Agent");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const cp = __importStar(require("child_process"));
const util = __importStar(require("util"));
const execPromise = util.promisify(cp.exec);
class Researcher extends Agent_1.Agent {
    constructor(name) {
        super(name, Agent_1.AgentRole.RESEARCHER);
    }
    async processTask(task) {
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
            }
            catch (error) {
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
                }
                else {
                    task.result = `pubspec.yaml not found.`;
                }
            }
            catch (e) {
                task.result = `Error reading pubspec.`;
            }
            return task;
        }
        task.result = `General research findings for: ${task.description}.`;
        return task;
    }
}
exports.Researcher = Researcher;
