"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Director = void 0;
const Agent_1 = require("../core/Agent");
const KnowledgeBase_1 = require("../core/KnowledgeBase");
class Director extends Agent_1.Agent {
    constructor(name) {
        super(name, Agent_1.AgentRole.DIRECTOR);
        this.workers = [];
        this.completedTasks = new Set();
        this.interactionLogs = [];
        this.highlights = [];
        this.efficiencyMetrics = new Map();
        this.knowledgeBase = new KnowledgeBase_1.KnowledgeBase();
        this.taskQueue = [];
        this.knowledgeBase.loadFromFile('sentinel_kb.json');
    }
    enqueueTask(task) {
        this.taskQueue.push(task);
        this.think(`Task enqueued: ${task.id}. Current queue depth: ${this.taskQueue.length}.`);
    }
    async runAutonomously(maxCycles = 10) {
        this.think(`Initializing autonomous execution mode (Max Cycles: ${maxCycles}).`);
        this.plan(`1. Continuous mission loop monitoring.
2. Recursive task generation from agent findings.
3. Automated dependency resolution.
4. Exit on queue depletion or cycle limit.`);
        let cycle = 0;
        while (this.taskQueue.length > 0 && cycle < maxCycles) {
            cycle++;
            this.think(`--- Starting Autonomy Cycle ${cycle} ---`);
            const currentTask = this.taskQueue.shift();
            // Re-check dependencies if they were added mid-flight
            const result = await this.processTask(currentTask, this.taskQueue);
            if (result.status === 'completed' && result.followUpTasks) {
                this.think(`Mission ${result.id} suggested ${result.followUpTasks.length} follow-up tasks.`, result.missionId);
                for (const partialTask of result.followUpTasks) {
                    const newTask = {
                        id: `Auto-${Math.random().toString(36).substr(2, 5)}`,
                        missionId: result.missionId, // Inherit mission context
                        description: partialTask.description,
                        status: 'pending',
                        params: partialTask.params,
                        dependencies: partialTask.dependencies
                    };
                    this.enqueueTask(newTask);
                }
            }
            else if (result.status === 'waiting') {
                this.think(`Task ${result.id} still waiting. Moving to back of queue.`, result.missionId);
                this.taskQueue.push(result);
            }
            // Small cooldown between cycles
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        if (this.taskQueue.length === 0) {
            this.think(`Autonomous mission complete. All tasks processed.`);
        }
        else {
            this.think(`Autonomous execution halted: Cycle limit reached.`);
        }
    }
    addWorker(worker) {
        worker.setKnowledgeBase(this.knowledgeBase);
        this.workers.push(worker);
        this.log(`Added worker: ${worker.name} (${worker.role})`);
    }
    getWorkers() {
        return [...this.workers];
    }
    addInteraction(message) {
        this.interactionLogs.push(`[${new Date().toISOString()}] ${message}`);
    }
    addHighlight(agent, role, result) {
        this.highlights.push(`${agent} (${role}): "${result}"`);
    }
    updateEfficiency(agent, timeTaken, impact) {
        const current = this.efficiencyMetrics.get(agent) || { totalTime: 0, impactScore: 0 };
        this.efficiencyMetrics.set(agent, {
            totalTime: current.totalTime + timeTaken,
            impactScore: current.impactScore + impact
        });
    }
    getInteractionSummary() {
        return this.interactionLogs.join('\n');
    }
    persistKnowledge() {
        this.knowledgeBase.saveToFile('sentinel_kb.json');
    }
    getWorkplaceReview() {
        const totalInteractions = this.interactionLogs.length;
        const workerStats = this.workers.reduce((acc, w) => {
            acc[w.name] = (acc[w.name] || 0) + 1;
            return acc;
        }, {});
        const incidents = this.interactionLogs.filter(log => log.includes('CRITICAL') || log.includes('REJECTED') || log.includes('failed'));
        let review = '\n' + '='.repeat(40) + '\n';
        review += '       WORKPLACE MISSION REVIEW\n';
        review += '='.repeat(40) + '\n';
        review += `Director: ${this.name}\n`;
        review += `Total Interactions: ${totalInteractions}\n`;
        review += `Incidents Logged: ${incidents.length}\n`;
        review += '-'.repeat(40) + '\n';
        review += 'AGENT CONTRIBUTIONS:\n';
        for (const [name, count] of Object.entries(workerStats)) {
            const role = this.workers.find(w => w.name === name)?.role;
            const metrics = this.efficiencyMetrics.get(name) || { totalTime: 0, impactScore: 0 };
            const avgTime = count > 0 ? (metrics.totalTime / count).toFixed(2) : 0;
            review += `- ${name} (${role}): ${count} tasks | Avg Time: ${avgTime}ms | Impact: ${metrics.impactScore}\n`;
        }
        review += '-'.repeat(40) + '\n';
        review += 'MISSION HIGHLIGHTS (Best Lines):\n';
        if (this.highlights.length === 0) {
            review += 'No specific highlights captured this mission.\n';
        }
        else {
            // Show best 5 highlights
            this.highlights.slice(-5).forEach(h => review += `${h}\n`);
        }
        review += '-'.repeat(40) + '\n';
        review += 'CRITICAL INCIDENTS & FEEDBACK:\n';
        if (incidents.length === 0) {
            review += 'No critical incidents. All agents performed within parameters.\n';
        }
        else {
            incidents.forEach(i => review += `${i}\n`);
        }
        review += '-'.repeat(40) + '\n';
        review += `OVERALL MISSION RATING: ${incidents.length === 0 ? 'OPTIMAL' : 'FUNCTIONAL (With Corrections)'}\n`;
        review += '='.repeat(40) + '\n';
        return review;
    }
    async processTask(task, allTasks) {
        // Ensure missionId exists (default to task.id if new mission)
        if (!task.missionId)
            task.missionId = task.id;
        this.think(`Strategic analysis for mission: ${task.id} - ${task.description}`, task.missionId);
        this.plan(`1. Validate mission constraints and dependencies.
2. Mathematically route task to most capable worker.
3. Supervise execution and handle worker failures.
4. Orchestrate quality assurance and final approval.`, task.missionId);
        this.speak(`I have received a new objective: ${task.description}. Initiating analysis for Mission ${task.id}.`, task.missionId);
        this.addInteraction(`Mission received: ${task.id}`);
        // 1. Check for Circular Dependencies (if allTasks provided)
        if (allTasks && this.hasCircularDependency(task, allTasks)) {
            this.think(`CRITICAL: Circular dependency detected for task ${task.id}. Aborting mission.`);
            this.log(`CRITICAL: Circular dependency detected for task ${task.id}`);
            this.addInteraction(`CRITICAL: Circular dependency for ${task.id}`);
            task.status = 'failed';
            task.result = 'Circular dependency detected.';
            return task;
        }
        // 2. Check Dependencies
        if (task.dependencies && task.dependencies.length > 0) {
            const missing = task.dependencies.filter(id => !this.completedTasks.has(id));
            if (missing.length > 0) {
                this.think(`Task ${task.id} is blocked. Waiting for: ${missing.join(', ')}.`, task.missionId);
                this.speak(`Mission ${task.id} is on hold. I am waiting for prerequisite operations: ${missing.join(', ')}.`, task.missionId);
                task.status = 'waiting';
                return task;
            }
        }
        // 2. Intelligent Routing based on Capabilities
        this.think(`Calculating optimal routing for mission ${task.id}...`, task.missionId);
        let targetWorker = this.routeTask(task);
        if (!targetWorker) {
            const anyBusy = this.workers.some(w => w.isBusy);
            if (anyBusy) {
                this.think(`Routing wait: All suitable workers are currently busy.`, task.missionId);
                task.status = 'waiting';
            }
            else {
                this.think(`Routing failure: No workers meet the capability threshold for this mission.`, task.missionId);
                task.status = 'failed';
                task.result = 'No suitable worker with required capabilities found.';
                this.addInteraction(`Routing failed for ${task.id}: No suitable worker`);
            }
            return task;
        }
        this.think(`Mission ${task.id} delegated to ${targetWorker.name} (${targetWorker.role}).`, task.missionId);
        this.speak(`${targetWorker.name}, you are cleared for this operation. Execute mission ${task.id} immediately.`, task.missionId);
        this.addInteraction(`Delegating ${task.id} to ${targetWorker.name} (${targetWorker.role})`);
        task.assignedTo = targetWorker.name;
        task.status = 'in-progress';
        // Simulate Worker Response
        targetWorker.speak(`Affirmative, Director. I am commencing operation "${task.description}" now.`, task.missionId);
        let currentTask = await this.executeWithRetry(targetWorker, task);
        if (currentTask.status === 'failed') {
            this.addInteraction(`Task ${task.id} failed after retries`);
            return currentTask;
        }
        // Simulate Worker Completion
        targetWorker.speak(`Operation complete. I have updated the mission parameters with my findings.`, task.missionId);
        // 3. Quality Assurance (External QA Agent)
        const qaAgent = this.workers.find(w => w.role === Agent_1.AgentRole.QA);
        // Only run QA if QA agent exists and is not busy
        if (qaAgent && !qaAgent.isBusy) {
            qaAgent.isBusy = true;
            try {
                let attempts = 0;
                const maxAttempts = 3;
                while (attempts < maxAttempts) {
                    attempts++;
                    this.speak(`Requesting quality assurance check from ${qaAgent.name}. Attempt ${attempts}.`, task.missionId);
                    this.addInteraction(`QA check for ${task.id} by ${qaAgent.name} (Attempt ${attempts})`);
                    currentTask = await qaAgent.processTask(currentTask);
                    if (currentTask.status === 'completed') {
                        this.completedTasks.add(currentTask.id);
                        this.addInteraction(`Task ${task.id} APPROVED by ${qaAgent.name}`);
                        this.addHighlight(targetWorker.name, targetWorker.role, currentTask.result || '');
                        this.speak(`Mission ${task.id} approved. Excellent work, team.`, task.missionId);
                        return currentTask;
                    }
                    else {
                        this.speak(`Negative on that result. ${qaAgent.name} rejected with feedback: "${currentTask.feedback}". Retrying...`, task.missionId);
                        this.addInteraction(`Task ${task.id} REJECTED by ${qaAgent.name}. Retrying...`);
                        currentTask = await this.executeWithRetry(targetWorker, currentTask);
                        if (currentTask.status === 'failed')
                            break;
                    }
                }
                this.speak(`Mission ${task.id} failed after maximum quality control cycles. Aborting.`, task.missionId);
                this.addInteraction(`Task ${task.id} FAILED max QC attempts`);
                currentTask.status = 'failed';
            }
            finally {
                qaAgent.isBusy = false;
            }
        }
        else if (qaAgent && qaAgent.isBusy) {
            // Re-queue the task for QA if the agent is busy
            this.speak(`QA personnel are currently engaged. Setting mission ${task.id} to waiting status.`, task.missionId);
            this.addInteraction(`Task ${task.id} waiting for QA availability`);
            currentTask.status = 'waiting';
        }
        else {
            // No QA agent, self-approve if result exists
            this.speak(`No QA personnel available. I am self-approving this task based on current metrics.`, task.missionId);
            this.addInteraction(`Task ${task.id} self-approved (No QA present)`);
            currentTask.status = 'completed';
            this.completedTasks.add(currentTask.id);
            this.addHighlight(targetWorker.name, targetWorker.role, currentTask.result || '');
        }
        return currentTask;
    }
    async executeWithRetry(worker, task, maxRetries = 2) {
        let retries = 0;
        worker.isBusy = true;
        try {
            while (retries <= maxRetries) {
                try {
                    const startTime = Date.now();
                    const result = await worker.processTask(task);
                    const duration = Date.now() - startTime;
                    if (result.status !== 'failed') {
                        this.updateEfficiency(worker.name, duration, 10); // Base impact score
                        return result;
                    }
                    retries++;
                    if (retries <= maxRetries) {
                        this.speak(`${worker.name} encountered an obstacle. Retrying operation (${retries}/${maxRetries})...`, task.missionId);
                        await new Promise(resolve => setTimeout(resolve, 500));
                    }
                }
                catch (error) {
                    this.speak(`Critical error reported by ${worker.name}: ${error.message}`, task.missionId);
                    retries++;
                    if (retries > maxRetries) {
                        task.status = 'failed';
                        task.result = `Execution error: ${error.message}`;
                        return task;
                    }
                }
            }
        }
        finally {
            worker.isBusy = false;
        }
        return task;
    }
    routeTask(task) {
        const desc = task.description.toLowerCase();
        let bestWorker = undefined;
        let maxScore = -1;
        for (const worker of this.workers) {
            // Do not route to busy agents or QA agents
            if (worker.role === Agent_1.AgentRole.QA || worker.isBusy)
                continue;
            let score = 0;
            for (const capability of worker.capabilities) {
                if (desc.includes(capability.toLowerCase())) {
                    score += 10;
                }
            }
            // Bonus for role matching if no specific capability found
            if (worker.role === Agent_1.AgentRole.SCOUT && (desc.includes('explore') || desc.includes('scan') || desc.includes('discovery') || desc.includes('lateral')))
                score += 20;
            if (worker.role === Agent_1.AgentRole.RESEARCHER && (desc.includes('research') || desc.includes('analysis') || desc.includes('source') || desc.includes('intel') || desc.includes('gathering') || desc.includes('audit') || desc.includes('security')))
                score += 15;
            if (worker.role === Agent_1.AgentRole.WORKER && (desc.includes('build') || desc.includes('implement')))
                score += 5;
            if (worker.role === Agent_1.AgentRole.ARCHITECT && (desc.includes('design') || desc.includes('architecture')))
                score += 15;
            if (worker.role === Agent_1.AgentRole.OPTIMIZER && (desc.includes('optimize') || desc.includes('efficiency')))
                score += 15;
            if (worker.role === Agent_1.AgentRole.SECURITY && (desc.includes('audit') || desc.includes('security')))
                score += 15;
            if (worker.role === Agent_1.AgentRole.CODE_ANALYZER && (desc.includes('code') || desc.includes('scan') || desc.includes('analyze') || desc.includes('module') || desc.includes('file')))
                score += 25;
            if (score > maxScore) {
                maxScore = score;
                bestWorker = worker;
            }
        }
        if (bestWorker)
            return bestWorker;
        // Fallback: look for ANY available worker, not just the strictly defined AgentRole.WORKER, that isn't busy
        return this.workers.find(w => !w.isBusy && w.role !== Agent_1.AgentRole.QA);
    }
    hasCircularDependency(task, allTasks) {
        const visited = new Set();
        const stack = new Set();
        const taskMap = new Map(allTasks.map(t => [t.id, t]));
        const findCycle = (id) => {
            if (stack.has(id))
                return true;
            if (visited.has(id))
                return false;
            visited.add(id);
            stack.add(id);
            const t = taskMap.get(id);
            if (t && t.dependencies) {
                for (const depId of t.dependencies) {
                    if (findCycle(depId))
                        return true;
                }
            }
            stack.delete(id);
            return false;
        };
        return findCycle(task.id);
    }
}
exports.Director = Director;
