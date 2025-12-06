import React, { useState } from 'react';
import { designChecklist } from '../data/content';

export const DesignChecklist: React.FC = () => {
    const [checkedItems, setCheckedItems] = useState<Record<string, boolean>>({});

    const toggleItem = (id: string) => {
        setCheckedItems(prev => ({ ...prev, [id]: !prev[id] }));
    };

    const checkedCount = Object.values(checkedItems).filter(Boolean).length;
    const totalCount = designChecklist.length;
    const progress = Math.round((checkedCount / totalCount) * 100);

    let feedback = "";
    let color = "";
    
    if (progress < 40) {
        feedback = "Geliştirilmesi gerekiyor. Bilişsel derinlik ve otantiklik boyutlarına odaklanın.";
        color = "text-red-500";
    } else if (progress < 75) {
        feedback = "İyi yolda. Ancak süreç şeffaflığı ve çoklu kanıt ekleyerek güçlendirebilirsiniz.";
        color = "text-amber-500";
    } else {
        feedback = "Harika! Bu ödev 'Nitelikli ve YZ-Dirençli' görünüyor.";
        color = "text-teal-600";
    }

    return (
        <div className="bg-white p-6 rounded-xl border border-stone-200 h-full flex flex-col">
            <div className="flex justify-between items-center mb-4">
                <h3 className="text-xl font-bold text-stone-800">
                    <i className="fas fa-tasks text-teal-600 mr-2"></i> Tasarım Kontrol Listesi
                </h3>
                <span className="text-xs font-mono text-stone-400">{checkedCount}/{totalCount}</span>
            </div>
            
            <p className="text-sm text-stone-500 mb-4">
                Tasarladığınız ödevi aşağıdaki 7 boyutlu kriterlere göre değerlendirin.
            </p>

            {/* Progress Bar */}
            <div className="w-full bg-stone-100 rounded-full h-2.5 mb-6">
                <div 
                    className="bg-teal-600 h-2.5 rounded-full transition-all duration-500" 
                    style={{ width: `${progress}%` }}
                ></div>
            </div>

            {/* List */}
            <div className="space-y-3 overflow-y-auto max-h-[400px] pr-2 grow custom-scrollbar">
                {designChecklist.map((item) => (
                    <div 
                        key={item.id} 
                        onClick={() => toggleItem(item.id)}
                        className={`flex items-start p-3 rounded-lg border cursor-pointer transition-all ${
                            checkedItems[item.id] 
                                ? 'bg-teal-50 border-teal-200' 
                                : 'bg-white border-stone-200 hover:border-stone-300'
                        }`}
                    >
                        <div className={`w-5 h-5 rounded border flex items-center justify-center mr-3 shrink-0 mt-0.5 transition-colors ${
                            checkedItems[item.id] ? 'bg-teal-500 border-teal-500' : 'border-stone-300'
                        }`}>
                            {checkedItems[item.id] && <i className="fas fa-check text-white text-xs"></i>}
                        </div>
                        <div>
                            <span className="text-xs font-bold text-stone-400 uppercase block mb-1">{item.dimension}</span>
                            <p className={`text-sm ${checkedItems[item.id] ? 'text-stone-800' : 'text-stone-500'}`}>{item.question}</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Feedback Footer */}
            <div className="mt-6 pt-4 border-t border-stone-100">
                <p className={`text-sm font-bold ${color} text-center`}>
                    {checkedCount === 0 ? "Kontrole başlamak için maddeleri işaretleyin." : feedback}
                </p>
            </div>
        </div>
    );
};