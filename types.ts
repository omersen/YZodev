export interface Session {
    time: string;
    title: string;
    desc: string;
}

export interface AgendaDay {
    id: string;
    title: string;
    icon: string;
    color: string;
    goal: string;
    sessions: Session[];
}

export interface RubricItem {
    criteria: string;
    levels: {
        4: string; // Mükemmel
        3: string; // İyi
        2: string; // Geliştirilebilir
        1: string; // Yetersiz
    }
}

export interface HomeworkExample {
    id: number;
    title: string;
    classLevel: string;
    icon: string;
    aim: string;
    desc: string; // Short description
    instructions: string; // Full student instructions
    steps: string[];
    policy: string;
    deliverable: string;
    duration: string;
    rubric: RubricItem[];
}

export interface PromptPart {
    label: string;
    value: string;
}

export interface PolicyTemplate {
    title: string;
    text: string;
    border: string;
}

export interface ChecklistItem {
    id: string;
    question: string;
    dimension: string;
}

export interface DimensionDetail {
    id: number;
    title: string;
    icon: string;
    color: string;
    border: string;
    desc: string;
    aiRelation: string; // How AI relates to this (what it can/can't do)
    sciExample: string; // Specific Science Education example
}

export interface ResearchStudy {
    id: string;
    title: string;
    year: string;
    author: string;
    summary: string;
    tag: string;
}

export interface AnalysisResult {
    score: number;
    feedback: string;
    dimension: string;
    status: 'success' | 'warning' | 'danger';
}

export interface TrainingSkill {
    icon: string;
    title: string;
    desc: string;
}

export interface ApplicationStep {
    id: number;
    title: string;
    status: 'completed' | 'current' | 'upcoming';
    date?: string;
}