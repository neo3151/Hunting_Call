"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Director = void 0;
const Agent_1 = require("../core/Agent");
class Director extends Agent_1.Agent {
    constructor(name) {
        super(name, Agent_1.AgentRole.DIRECTOR);
        this.workers = [];
        this.knowledgeBase = {};
    }
    addWorker(worker) {
        this.workers.push(worker);
    }
    async processTask(task) {
        this.log(`Received mission: ${task.description}`);
        const originalDesc = task.description;
        const desc = originalDesc.toLowerCase();
        // 1. COLLABORATIVE BRAINSTORM
        if (desc.includes('brainstorm')) {
            this.log(`Initiating Strategic Brainstorm...`);
            const results = await Promise.all(this.workers.filter(w => w.role !== Agent_1.AgentRole.DIRECTOR).map(w => w.processTask({ ...task, id: task.id + '-' + w.role })));
            task.result = results.map(r => `[${r.assignedTo || 'Agent'}] ${r.result}`).join('\n\n');
            task.status = 'completed';
            return task;
        }
        // 2. STANDARD DELEGATION
        const descWithContext = this.injectContext(originalDesc);
        task.description = descWithContext;
        let targetWorker = this.workers.find(w => {
            if (desc.includes('run') || desc.includes('build') || desc.includes('doctor') || desc.includes('verify')) {
                return w.role === Agent_1.AgentRole.WORKER;
            }
            const isResearch = desc.includes('research') || desc.includes('investigate') || desc.includes('search');
            return isResearch ? w.role === Agent_1.AgentRole.RESEARCHER : w.role === Agent_1.AgentRole.WORKER;
        }) || this.workers[0];
        if (!targetWorker)
            return task;
        this.log(`Delegating to ${targetWorker.name}...`);
        task.assignedTo = targetWorker.name;
        task.status = 'in-progress';
        let currentTask = await targetWorker.processTask(task);
        // QC and Final QA
        if (currentTask.status === 'completed' && targetWorker.role === Agent_1.AgentRole.WORKER) {
            const qaAgent = this.workers.find(w => w.role === Agent_1.AgentRole.QA);
            if (qaAgent) {
                this.log(`Initiating QA verification...`);
                const qaTask = await qaAgent.processTask({
                    id: currentTask.id + '-QA',
                    description: `Verify: ${originalDesc}`,
                    status: 'pending'
                });
                currentTask.result += `\n\n[QA SIGN-OFF]:\n${qaTask.result}`;
            }
        }
        if (currentTask.status === 'completed') {
            this.knowledgeBase[currentTask.id] = currentTask.result || '';
        }
        return currentTask;
    }
    injectContext(description) {
        const keys = Object.keys(this.knowledgeBase);
        if (keys.length === 0)
            return description;
        return `${description}\n\n[SHARED CONTEXT - DO NOT RE-RESEARCH]:\n${keys.map(k => `- ${k}: ${this.knowledgeBase[k].substring(0, 200)}...`).join('\n')}`;
    }
}
exports.Director = Director;
