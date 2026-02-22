import { Agent, AgentRole, AgentTask } from '../core/Agent';

export class TechnicalWriterAgent extends Agent {
    constructor(name: string) {
        super(name, AgentRole.TECHNICAL_WRITER);
        this.capabilities = ['writing', 'documentation', 'summarization', 'reporting'];
    }

    async processTask(task: AgentTask): Promise<AgentTask> {
        this.think(`Reviewing materials for documentation task: ${task.description}`);
        const stack = this.knowledgeBase?.getFact('general:stack:npm') ||
            this.knowledgeBase?.getFact('general:stack:flutter');

        this.plan(`1. Analyze execution results and task context.
2. Structure the comprehensive report.
3. Draft clear and concise documentation tailored for the target audience.
4. Finalize the content.`);

        this.log(`Drafting documentation for: ${task.description}`);

        // Simulate complex writing phase
        await new Promise(resolve => setTimeout(resolve, 1000));

        task.result = `Documentation/Report finalized for ${task.description}.
Key findings highlighted and structured for clarity.
Target Stack context included: ${stack?.value || 'standard'}.`;

        this.log(`Documentation phase complete.`);
        return task;
    }
}
