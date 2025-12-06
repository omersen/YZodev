import React, { useState } from 'react';
import { generateEducationalContent } from '../services/geminiService';

export const PromptBuilder: React.FC = () => {
    const [promptText, setPromptText] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [aiResponse, setAiResponse] = useState<string | null>(null);

    const addToPrompt = (text: string) => {
        setPromptText(prev => prev + text + " ");
    };

    const handleGenerate = async () => {
        if (!promptText.trim()) return;
        setIsLoading(true);
        setAiResponse(null);
        
        const response = await generateEducationalContent(promptText);
        setAiResponse(response);
        setIsLoading(false);
    };

    return (
        <div className="bg-stone-800 p-6 rounded-xl border border-stone-700 h-full flex flex-col">
            <div className="flex justify-between items-center mb-6">
                <h3 className="text-xl font-bold text-teal-400">
                    <i className="fas fa-robot mr-2"></i> Prompt Mühendisliği Lab
                </h3>
                <span className="text-xs bg-teal-900 text-teal-200 px-2 py-1 rounded border border-teal-700">YZ Destekli</span>
            </div>

            <p className="text-sm text-stone-400 mb-4">
                Bileşenleri seçerek promptunuzu oluşturun, ardından Gemini ile sonucu görün.
            </p>

            {/* Builder Buttons */}
            <div className="space-y-4 mb-6 grow">
                <div>
                    <span className="text-xs font-bold text-stone-500 uppercase tracking-wide">1. Rol (Kimsin?)</span>
                    <div className="flex flex-wrap gap-2 mt-1">
                        <button onClick={() => addToPrompt('Sen uzman bir fen bilgisi öğretmenisin.')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">Uzman Öğretmen</button>
                        <button onClick={() => addToPrompt('Sen meraklı bir 6. sınıf öğrencisisin.')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">6. Sınıf Öğrencisi</button>
                    </div>
                </div>
                <div>
                    <span className="text-xs font-bold text-stone-500 uppercase tracking-wide">2. Bağlam (Durum Ne?)</span>
                    <div className="flex flex-wrap gap-2 mt-1">
                        <button onClick={() => addToPrompt('7. sınıf "Kuvvet ve Enerji" ünitesi için,')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">Kuvvet ve Enerji</button>
                        <button onClick={() => addToPrompt('Evdeki malzemelerle yapılan bir deney için,')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">Ev Deneyi</button>
                    </div>
                </div>
                <div>
                    <span className="text-xs font-bold text-stone-500 uppercase tracking-wide">3. Görev (Ne Yapsın?)</span>
                    <div className="flex flex-wrap gap-2 mt-1">
                        <button onClick={() => addToPrompt('4 seviyeli analitik bir rubrik hazırla.')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">Rubrik Yaz</button>
                        <button onClick={() => addToPrompt('Konuyu Sokratik sorularla bana öğret.')} className="bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs px-3 py-1 rounded transition">Sokratik Öğretim</button>
                    </div>
                </div>
            </div>

            {/* Input Area */}
            <div className="bg-stone-900 p-4 rounded-lg border border-stone-600 mb-4">
                <textarea 
                    value={promptText}
                    onChange={(e) => setPromptText(e.target.value)}
                    className="w-full bg-transparent text-teal-300 text-sm focus:outline-none font-mono h-20 resize-none placeholder-stone-700" 
                    placeholder="Butonlara tıklayın veya kendi promptunuzu yazın..."
                />
                <div className="flex justify-end mt-2 space-x-2">
                    <button onClick={() => setPromptText('')} className="text-xs text-red-400 hover:text-red-300">Temizle</button>
                    <button onClick={handleGenerate} disabled={isLoading || !promptText} className={`text-xs px-3 py-1 rounded font-bold transition ${isLoading ? 'bg-stone-600 text-stone-400' : 'bg-teal-600 text-white hover:bg-teal-500'}`}>
                        {isLoading ? 'Üretiliyor...' : 'YZ ile Üret'}
                    </button>
                </div>
            </div>

            {/* AI Response Area */}
            {aiResponse && (
                <div className="bg-stone-100 p-4 rounded-lg border border-stone-300 overflow-y-auto max-h-60">
                    <h4 className="text-xs font-bold text-stone-500 uppercase mb-2">YZ Çıktısı:</h4>
                    <pre className="whitespace-pre-wrap text-xs text-stone-800 font-mono">{aiResponse}</pre>
                </div>
            )}
        </div>
    );
};
