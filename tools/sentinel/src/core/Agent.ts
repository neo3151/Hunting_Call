export enum AgentRole {
    DIRECTOR = 'Director',
    WORKER = 'Worker',
    RESEARCHER = 'Researcher',
    QA = 'QA'
}

export interface AgentTask {
    id: string;
    description: string;
    assignedTo?: string;
    status: 'pending' | 'in-progress' | 'completed' | 'failed';
    result?: string;
    feedback?: string;
}

export abstract class Agent {
    constructor(
        public name: string,
        public role: AgentRole
    ) { }

    log(message: string) {
        console.log(`[${this.role}] ${this.name}: ${message}`);
    }

    abstract processTask(task: AgentTask): Promise<AgentTask>;
}
