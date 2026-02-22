import { Logger } from './Logger';
import * as fs from 'fs';

export interface Fact {
    key: string;
    value: any;
    source: string;
    timestamp: number;
}

export class KnowledgeBase {
    private facts: Map<string, Fact> = new Map();

    addFact(key: string, value: any, source: string) {
        this.facts.set(key, {
            key,
            value,
            source,
            timestamp: Date.now()
        });
        Logger.info('KnowledgeBase', `New fact added: ${key} (from ${source})`);
    }

    getFact(key: string): Fact | undefined {
        return this.facts.get(key);
    }

    getAllFacts(): Fact[] {
        return Array.from(this.facts.values());
    }

    hasFact(key: string): boolean {
        return this.facts.has(key);
    }

    saveToFile(filePath: string) {
        try {
            const data = JSON.stringify(Array.from(this.facts.entries()), null, 2);
            fs.writeFileSync(filePath, data);
            Logger.info('KnowledgeBase', `Saved ${this.facts.size} facts to ${filePath}`);
        } catch (error: any) {
            Logger.error('KnowledgeBase', `Failed to save facts: ${error.message}`);
        }
    }

    loadFromFile(filePath: string) {
        try {
            if (fs.existsSync(filePath)) {
                const data = fs.readFileSync(filePath, 'utf-8');
                const entries = JSON.parse(data);
                this.facts = new Map(entries);
                Logger.info('KnowledgeBase', `Loaded ${this.facts.size} facts from ${filePath}`);
            }
        } catch (error: any) {
            Logger.error('KnowledgeBase', `Failed to load facts: ${error.message}`);
        }
    }
}
