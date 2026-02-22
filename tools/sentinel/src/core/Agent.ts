import { KnowledgeBase } from './KnowledgeBase';
import { Logger } from './Logger';

export enum AgentRole {
    DIRECTOR = 'Director',
    WORKER = 'Worker',
    RESEARCHER = 'Researcher',
    QA = 'QA',
    SCOUT = 'Scout',
    ARCHITECT = 'Architect',
    OPTIMIZER = 'Optimizer',
    SECURITY = 'Security',
    TECHNICAL_WRITER = 'TechnicalWriter',
    DEVOPS = 'DevOps',
    CODE_ANALYZER = 'CodeAnalyzer'
}

export interface AgentTask {
    id: string;
    missionId?: string; // Context for conversational UI
    description: string;
    assignedTo?: string;
    status: 'pending' | 'in-progress' | 'completed' | 'failed' | 'waiting';
    result?: string;
    feedback?: string;
    dependencies?: string[]; // IDs of tasks that must complete first
    params?: Record<string, any>; // Structured parameters for the task
    followUpTasks?: Partial<AgentTask>[]; // Tasks suggested by the agent after execution
}

export abstract class Agent {
    public capabilities: string[] = [];
    public knowledgeBase?: KnowledgeBase;
    public isBusy: boolean = false;

    constructor(
        public name: string,
        public role: AgentRole
    ) { }

    setKnowledgeBase(kb: KnowledgeBase) {
        this.knowledgeBase = kb;
    }

    log(message: string, missionId?: string) {
        Logger.info(`${this.role}:${this.name}`, message, missionId);
    }

    think(message: string, missionId?: string) {
        Logger.thought(`${this.role}:${this.name}`, message, missionId);
    }

    plan(message: string, missionId?: string) {
        Logger.plan(`${this.role}:${this.name}`, message, missionId);
    }

    speak(message: string, missionId?: string) {
        // "Spoken" messages are just INFO logs but intended for the Chat UI
        Logger.info(`${this.role}:${this.name}`, message, missionId);
    }

    abstract processTask(task: AgentTask): Promise<AgentTask>;
}
