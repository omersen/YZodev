import React, { useState } from 'react';
import { homeworkData } from '../data/content';
import { HomeworkExample } from '../types';

export const HomeworkGallery: React.FC = () => {
    const [selectedHw, setSelectedHw] = useState<HomeworkExample | null>(null);

    return (
        <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {homeworkData.map((hw) => (
                    <div key={hw.id} className="bg-white border border-stone-200 rounded-xl p-6 hover:shadow-lg transition duration-300 group hover:border-teal-200 flex flex-col h-full">
                        <div className="flex justify-between items-start mb-4">
                            <div className="flex items-center">
                                <div className="w-12 h-12 rounded-lg bg-teal-50 flex items-center justify-center mr-3 group-hover:bg-teal-100 transition shrink-0">
                                    <i className={`fas ${hw.icon} text-teal-600 text-xl`}></i>
                                </div>
                                <div>
                                    <h4 className="font-bold text-stone-800 leading-tight">{hw.title}</h4>
                                    <span className="text-xs bg-stone-100 text-stone-600 px-2 py-0.5 rounded border border-stone-200 inline-block mt-1">{hw.classLevel}</span>
                                </div>
                            </div>
                        </div>
                        <p className="text-sm text-stone-600 mb-4 grow">{hw.desc}</p>
                        
                        <div className="bg-stone-50 p-3 rounded text-xs space-y-2 border border-stone-100 mb-4">
                            <div className="flex items-start">
                                <i className="fas fa-bullseye text-teal-500 mt-0.5 mr-2 w-4"></i>
                                <span className="text-stone-600">{hw.aim}</span>
                            </div>
                        </div>

                        <button 
                            onClick={() => setSelectedHw(hw)}
                            className="w-full mt-auto bg-white border border-teal-600 text-teal-700 py-2 rounded-lg hover:bg-teal-50 transition text-sm font-semibold"
                        >
                            Detayları İncele
                        </button>
                    </div>
                ))}
            </div>

            {/* Detail Modal */}
            {selectedHw && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-stone-900/50 backdrop-blur-sm animate-fade-in" onClick={() => setSelectedHw(null)}>
                    <div className="bg-white rounded-xl shadow-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
                        {/* Header */}
                        <div className="sticky top-0 bg-white border-b border-stone-200 px-6 py-4 flex justify-between items-center z-10">
                            <div className="flex items-center">
                                <div className="w-10 h-10 rounded-full bg-teal-100 flex items-center justify-center mr-3 text-teal-700">
                                    <i className={`fas ${selectedHw.icon}`}></i>
                                </div>
                                <div>
                                    <h3 className="text-xl font-bold text-stone-800">{selectedHw.title}</h3>
                                    <p className="text-xs text-stone-500">{selectedHw.classLevel} • Süre: {selectedHw.duration}</p>
                                </div>
                            </div>
                            <button onClick={() => setSelectedHw(null)} className="text-stone-400 hover:text-stone-700">
                                <i className="fas fa-times text-xl"></i>
                            </button>
                        </div>

                        {/* Content */}
                        <div className="p-6 space-y-6">
                            {/* Section 1: Instructions */}
                            <div>
                                <h4 className="text-sm font-bold text-teal-600 uppercase tracking-wide mb-2">Öğrenci Yönergesi</h4>
                                <div className="bg-stone-50 p-4 rounded-lg border border-stone-200 text-stone-700 text-sm">
                                    {selectedHw.instructions}
                                </div>
                            </div>

                            {/* Section 2: Steps */}
                            <div>
                                <h4 className="text-sm font-bold text-teal-600 uppercase tracking-wide mb-2">Adımlar</h4>
                                <ul className="space-y-2">
                                    {selectedHw.steps.map((step, idx) => (
                                        <li key={idx} className="flex items-start text-sm text-stone-700">
                                            <span className="bg-teal-600 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs mr-3 shrink-0 mt-0.5">{idx + 1}</span>
                                            {step}
                                        </li>
                                    ))}
                                </ul>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                {/* Section 3: Policy */}
                                <div>
                                    <h4 className="text-sm font-bold text-amber-600 uppercase tracking-wide mb-2"><i className="fas fa-shield-alt mr-1"></i> YZ Politikası</h4>
                                    <p className="text-sm text-stone-600 bg-amber-50 p-3 rounded border border-amber-100">
                                        {selectedHw.policy}
                                    </p>
                                </div>
                                {/* Section 4: Deliverable */}
                                <div>
                                    <h4 className="text-sm font-bold text-indigo-600 uppercase tracking-wide mb-2"><i className="fas fa-box-open mr-1"></i> Beklenen Ürün</h4>
                                    <p className="text-sm text-stone-600 bg-indigo-50 p-3 rounded border border-indigo-100">
                                        {selectedHw.deliverable}
                                    </p>
                                </div>
                            </div>

                            {/* Section 5: Rubric */}
                            <div>
                                <h4 className="text-sm font-bold text-teal-600 uppercase tracking-wide mb-3">Değerlendirme Rubriği (Özet)</h4>
                                <div className="overflow-x-auto">
                                    <table className="w-full text-sm text-left text-stone-600 border border-stone-200 rounded-lg">
                                        <thead className="text-xs text-stone-700 uppercase bg-stone-100">
                                            <tr>
                                                <th className="px-4 py-2 w-1/4">Kriter</th>
                                                <th className="px-4 py-2 w-3/4">4 Puan (Mükemmel) Tanımı</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {selectedHw.rubric.map((item, idx) => (
                                                <tr key={idx} className="border-b border-stone-200 hover:bg-stone-50">
                                                    <td className="px-4 py-3 font-medium text-stone-800">{item.criteria}</td>
                                                    <td className="px-4 py-3 text-stone-600">{item.levels[4]}</td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                        {/* Footer */}
                        <div className="sticky bottom-0 bg-stone-50 border-t border-stone-200 px-6 py-4 flex justify-end">
                            <button onClick={() => setSelectedHw(null)} className="bg-stone-800 text-white px-6 py-2 rounded-lg hover:bg-stone-900 transition">
                                Kapat
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
};