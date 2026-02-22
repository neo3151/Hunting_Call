import { Agent, AgentRole, AgentTask } from '../core/Agent';

export class QAAgent extends Agent {
    constructor(name: string) {
        super(name, AgentRole.QA);
        this.capabilities = ['testing', 'quality-assurance', 'validation'];
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.think(`Reviewing output for task ${task.id}: "${task.description}"`);
        this.plan(`1. Validate result length and technical depth.
2. Verify specialized requirements (e.g., "Findings" section for research).
3. Ensure consistency with project tech stack.
4. Provide constructive feedback if rejection is required.`);

        this.log(`Reviewing work for task: ${task.id}`);

        // Simulate review time
        await new Promise(resolve => setTimeout(resolve, 800));

        if (!task.result || task.result.length < 30) {
            this.think(`Result rejected: Insufficient detail (${task.result?.length || 0} chars).`);
            task.status = 'failed';
            task.feedback = 'Result is insufficient. Please provide more technical detail.';
            this.log('Result rejected: Insufficient detail.');
        } else if (task.description.toLowerCase().includes('research') && !task.result.includes('Findings') && !task.assignedTo?.includes('Scout')) {
            this.think(`Result rejected: Missing "Findings" section.`);
            task.status = 'failed';
            task.feedback = 'Research results must include a "Findings" section.';
            this.log('Result rejected: Missing Findings section.');
        } else {
            this.think(`Result meets all quality standards.`);
            task.status = 'completed';
            this.log('Result approved.');
        }

        return task;
    }
}
