import { Director } from './Director';
import { Agent, AgentRole, AgentTask } from '../core/Agent';

// Mock Agent implementation for testing
class MockAgent extends Agent {
    constructor(name: string, role: AgentRole, capabilities: string[] = []) {
        super(name, role);
        this.capabilities = capabilities;
    }
    async processTask(task: AgentTask): Promise<AgentTask> {
        task.status = 'completed';
        task.result = `Result from ${this.name}`;
        return task;
    }
}

describe('Director', () => {
    let director: Director;

    beforeEach(() => {
        director = new Director('Test-Director');
    });

    it('should add workers and set their knowledge base', () => {
        const worker = new MockAgent('Worker-1', AgentRole.WORKER);
        director.addWorker(worker);
        expect(worker.knowledgeBase).toBe(director.knowledgeBase);
    });

    it('should route and complete a task', async () => {
        const worker = new MockAgent('Worker-1', AgentRole.WORKER);
        director.addWorker(worker);

        const task: AgentTask = {
            id: 'T1',
            description: 'do something',
            status: 'pending'
        };

        const result = await director.processTask(task);
        expect(result.status).toBe('completed');
        expect(result.assignedTo).toBe('Worker-1');
    });

    it('should wait for dependencies', async () => {
        const worker = new MockAgent('Worker-1', AgentRole.WORKER);
        director.addWorker(worker);

        const task: AgentTask = {
            id: 'T2',
            description: 'do something',
            status: 'pending',
            dependencies: ['T1']
        };

        const result = await director.processTask(task);
        expect(result.status).toBe('waiting');
    });

    it('should fail if no suitable worker is found', async () => {
        const task: AgentTask = {
            id: 'T1',
            description: 'do something',
            status: 'pending'
        };

        const result = await director.processTask(task);
        expect(result.status).toBe('failed');
        expect(result.result).toContain('No suitable worker');
    });

    it('should retry if a worker fails', async () => {
        const failingWorker = new MockAgent('Failing-Worker', AgentRole.WORKER);
        let calls = 0;
        failingWorker.processTask = async (task: AgentTask) => {
            calls++;
            if (calls < 2) {
                task.status = 'failed';
                return task;
            }
            task.status = 'completed';
            task.result = 'Success on retry';
            return task;
        };

        director.addWorker(failingWorker);

        const task: AgentTask = {
            id: 'T1',
            description: 'do something',
            status: 'pending'
        };

        const result = await director.processTask(task);
        expect(result.status).toBe('completed');
        expect(calls).toBe(2);
    });

    it('should route based on capabilities score', async () => {
        const coder = new MockAgent('Coder', AgentRole.WORKER, ['coding', 'typescript']);
        const researcher = new MockAgent('Researcher', AgentRole.RESEARCHER, ['research', 'analysis']);

        director.addWorker(coder);
        director.addWorker(researcher);

        const task: AgentTask = {
            id: 'T1',
            description: 'research the codebase and analysis',
            status: 'pending'
        };

        const result = await director.processTask(task);
        expect(result.assignedTo).toBe('Researcher');
    });

    it('should detect circular dependencies', async () => {
        const worker = new MockAgent('Worker-1', AgentRole.WORKER);
        director.addWorker(worker);

        const tasks: AgentTask[] = [
            { id: 'T1', description: 'desc 1', status: 'pending', dependencies: ['T2'] },
            { id: 'T2', description: 'desc 2', status: 'pending', dependencies: ['T1'] }
        ];

        const result = await director.processTask(tasks[0], tasks);
        expect(result.status).toBe('failed');
        expect(result.result).toBe('Circular dependency detected.');
    });

    it('should perform QA if a QA agent is present', async () => {
        const worker = new MockAgent('Worker-1', AgentRole.WORKER);
        const qa = new MockAgent('QA-1', AgentRole.QA);

        // Spy on QA agent's processTask
        const qaType = qa as any;
        const spy = jest.spyOn(qaType, 'processTask');

        director.addWorker(worker);
        director.addWorker(qa);

        const task: AgentTask = {
            id: 'T1',
            description: 'do something',
            status: 'pending'
        };

        await director.processTask(task);
        expect(spy).toHaveBeenCalled();
    });
});
