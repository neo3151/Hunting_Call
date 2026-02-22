import { KnowledgeBase } from './KnowledgeBase';

describe('KnowledgeBase', () => {
    let kb: KnowledgeBase;

    beforeEach(() => {
        kb = new KnowledgeBase();
    });

    it('should add and retrieve a fact', () => {
        kb.addFact('test-key', 'test-value', 'test-source');
        expect(kb.hasFact('test-key')).toBe(true);
        const fact = kb.getFact('test-key');
        expect(fact).toBeDefined();
        expect(fact?.value).toBe('test-value');
        expect(fact?.source).toBe('test-source');
    });

    it('should return undefined for non-existent fact', () => {
        expect(kb.getFact('missing')).toBeUndefined();
    });

    it('should return all facts', () => {
        kb.addFact('key1', 'val1', 'src1');
        kb.addFact('key2', 'val2', 'src2');
        const facts = kb.getAllFacts();
        expect(facts.length).toBe(2);
        expect(facts.find(f => f.key === 'key1')).toBeDefined();
        expect(facts.find(f => f.key === 'key2')).toBeDefined();
    });

    it('should check if a fact exists', () => {
        expect(kb.hasFact('key1')).toBe(false);
        kb.addFact('key1', 'val1', 'src1');
        expect(kb.hasFact('key1')).toBe(true);
    });
});
