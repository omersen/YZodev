import React from 'react';
import { researchStudies } from '../data/content';

export const ResearchLibrary: React.FC = () => {
    return (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
            {researchStudies.map((study) => (
                <div key={study.id} className="bg-white p-6 rounded-lg border border-stone-200 hover:shadow-md transition">
                    <div className="flex justify-between items-start mb-3">
                        <span className="bg-stone-100 text-stone-600 text-xs px-2 py-1 rounded border border-stone-200 font-mono">
                            {study.year}
                        </span>
                        <span className="text-xs font-bold text-teal-600 uppercase tracking-wide">
                            {study.tag}
                        </span>
                    </div>
                    <h4 className="text-lg font-bold text-stone-800 mb-1">{study.title}</h4>
                    <p className="text-xs text-stone-500 mb-3 italic">Yazar: {study.author}</p>
                    <p className="text-sm text-stone-600 leading-relaxed">
                        {study.summary}
                    </p>
                </div>
            ))}
        </div>
    );
};