import React from 'react';
import { detailedDimensions } from '../data/content';

export const ModelDimensions: React.FC = () => {
    return (
        <div className="lg:col-span-2 grid grid-cols-1 gap-6">
            {detailedDimensions.map((dim) => (
                <div key={dim.id} className={`bg-white border-l-4 ${dim.border} p-6 rounded-r-xl shadow-sm hover:shadow-md transition border-y border-r border-stone-100`}>
                    <div className="flex items-center mb-3">
                         <div className={`w-10 h-10 rounded-full bg-stone-50 flex items-center justify-center mr-4 shrink-0 ${dim.color}`}>
                            <i className={`fas ${dim.icon} text-xl`}></i>
                        </div>
                        <h4 className="text-xl font-bold text-stone-800">{dim.id}. {dim.title}</h4>
                    </div>
                    
                    <p className="text-stone-600 mb-4">{dim.desc}</p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="bg-teal-50/50 p-3 rounded-lg border border-teal-100">
                            <h5 className="text-xs font-bold text-teal-700 uppercase mb-1 flex items-center">
                                <i className="fas fa-microscope mr-1.5"></i> Fen Örneği
                            </h5>
                            <p className="text-sm text-stone-700 italic">"{dim.sciExample}"</p>
                        </div>
                        
                        <div className="bg-stone-100/50 p-3 rounded-lg border border-stone-200">
                            <h5 className="text-xs font-bold text-stone-600 uppercase mb-1 flex items-center">
                                <i className="fas fa-robot mr-1.5"></i> YZ Bağlantısı
                            </h5>
                            <p className="text-sm text-stone-600">{dim.aiRelation}</p>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
};