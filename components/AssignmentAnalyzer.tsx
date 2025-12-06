
import React, { useState } from 'react';
import { AnalysisResult } from '../types';

export const AssignmentAnalyzer: React.FC = () => {
    const [activeTab, setActiveTab] = useState<'file' | 'text'>('file');
    const [file, setFile] = useState<File | null>(null);
    const [textInput, setTextInput] = useState('');
    const [isAnalyzing, setIsAnalyzing] = useState(false);
    const [progress, setProgress] = useState(0);
    const [result, setResult] = useState<AnalysisResult[] | null>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            setFile(e.target.files[0]);
            setResult(null);
            setProgress(0);
        }
    };

    const startAnalysis = () => {
        if (activeTab === 'file' && !file) return;
        if (activeTab === 'text' && !textInput.trim()) return;

        setIsAnalyzing(true);
        
        // Simulation of analysis process
        let currentProgress = 0;
        const interval = setInterval(() => {
            currentProgress += 5;
            setProgress(currentProgress);
            if (currentProgress >= 100) {
                clearInterval(interval);
                setIsAnalyzing(false);
                generateMockResult();
            }
        }, 80); // Slightly faster for demo
    };

    const generateMockResult = () => {
        // Mock data based on 7 dimensions
        // In a real app, you would send 'file' or 'textInput' to the backend/LLM here.
        const mockResults: AnalysisResult[] = [
            { dimension: "1. Bilişsel Derinlik", score: 3, status: 'warning', feedback: "Görev analitik düşünmeyi destekliyor ancak daha fazla 'neden' ve 'nasılsın' sorusu eklenebilir." },
            { dimension: "2. Otantiklik", score: 2, status: 'danger', feedback: "Görev genel bir konu üzerine. Öğrencinin yerel çevresiyle veya kendi yaşamıyla bağlantı kurması sağlanmalı." },
            { dimension: "3. Süreç Şeffaflığı", score: 4, status: 'success', feedback: "Taslak teslim aşamaları ve süreç takvimi gayet iyi planlanmış." },
            { dimension: "4. YZ Etiği", score: 5, status: 'success', feedback: "YZ kullanım politikası ve beyan zorunluluğu net ve açık." },
            { dimension: "5. Çoklu Kanıt", score: 2, status: 'danger', feedback: "Sadece yazılı rapor istenmiş. Sunum, video veya sözlü savunma eklenerek çeşitlendirilmeli." },
            { dimension: "6. İşbirliği", score: 3, status: 'warning', feedback: "Bireysel bir ödev olarak kurgulanmış. Akran değerlendirmesi eklenebilir." },
            { dimension: "7. Yansıtma", score: 1, status: 'danger', feedback: "Ödev sonunda öğrencinin sürecini değerlendireceği (metacognition) bir bölüm eksik." }
        ];
        setResult(mockResults);
    };

    const resetAnalyzer = () => {
        setResult(null);
        setFile(null);
        setTextInput('');
        setProgress(0);
    };

    return (
        <div className="bg-white p-8 rounded-xl border border-stone-200 shadow-sm h-full flex flex-col min-h-[600px]">
            <div className="mb-6">
                <h3 className="text-2xl font-bold text-stone-800 flex items-center">
                    <i className="fas fa-microscope text-teal-600 mr-3"></i> Ödev Analiz Laboratuvarı
                </h3>
                <p className="text-stone-600 mt-2">Ödev yönergenizi yükleyin veya yapıştırın, YZ motorumuz 7 boyuta göre analiz etsin.</p>
            </div>

            {/* Input Area (Only visible if not analyzing and no result) */}
            {!result && !isAnalyzing && (
                <div className="flex flex-col grow">
                    {/* Tabs */}
                    <div className="flex space-x-4 mb-6 border-b border-stone-200">
                        <button 
                            onClick={() => setActiveTab('file')}
                            className={`pb-3 px-2 text-sm font-bold transition-colors relative ${activeTab === 'file' ? 'text-teal-600' : 'text-stone-500 hover:text-stone-700'}`}
                        >
                            <i className="fas fa-file-pdf mr-2"></i> PDF Yükle
                            {activeTab === 'file' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-teal-600"></div>}
                        </button>
                        <button 
                            onClick={() => setActiveTab('text')}
                            className={`pb-3 px-2 text-sm font-bold transition-colors relative ${activeTab === 'text' ? 'text-teal-600' : 'text-stone-500 hover:text-stone-700'}`}
                        >
                            <i className="fas fa-align-left mr-2"></i> Metin Gir
                            {activeTab === 'text' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-teal-600"></div>}
                        </button>
                    </div>

                    {/* File Upload Tab */}
                    {activeTab === 'file' && (
                        <div className="grow flex flex-col">
                            <div className="border-2 border-dashed border-stone-300 rounded-xl p-10 text-center hover:border-teal-500 transition-colors bg-stone-50 cursor-pointer group grow flex flex-col justify-center items-center" onClick={() => document.getElementById('file-upload')?.click()}>
                                <input type="file" id="file-upload" className="hidden" accept=".pdf" onChange={handleFileChange} />
                                <div className="w-16 h-16 bg-teal-100 text-teal-600 rounded-full flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                                    <i className="fas fa-cloud-upload-alt text-2xl"></i>
                                </div>
                                <p className="font-bold text-stone-700 text-lg mb-1">{file ? file.name : "PDF Yüklemek İçin Tıklayın"}</p>
                                <p className="text-xs text-stone-500">Maksimum dosya boyutu: 10MB</p>
                            </div>
                            <button 
                                onClick={startAnalysis} 
                                disabled={!file}
                                className={`mt-6 w-full py-3 rounded-lg font-bold transition shadow-lg flex justify-center items-center ${
                                    !file ? 'bg-stone-200 text-stone-400 cursor-not-allowed' : 'bg-teal-600 text-white hover:bg-teal-700'
                                }`}
                            >
                                <i className="fas fa-search mr-2"></i> Analizi Başlat
                            </button>
                        </div>
                    )}

                    {/* Text Input Tab */}
                    {activeTab === 'text' && (
                        <div className="grow flex flex-col">
                            <textarea 
                                className="w-full grow bg-stone-50 border border-stone-300 rounded-xl p-4 text-sm text-stone-800 focus:outline-none focus:border-teal-500 focus:ring-1 focus:ring-teal-500 transition resize-none placeholder-stone-400"
                                placeholder="Ödev yönergesini, sorularını ve değerlendirme kriterlerini buraya yapıştırın..."
                                value={textInput}
                                onChange={(e) => setTextInput(e.target.value)}
                            ></textarea>
                            <button 
                                onClick={startAnalysis} 
                                disabled={!textInput.trim()}
                                className={`mt-6 w-full py-3 rounded-lg font-bold transition shadow-lg flex justify-center items-center ${
                                    !textInput.trim() ? 'bg-stone-200 text-stone-400 cursor-not-allowed' : 'bg-teal-600 text-white hover:bg-teal-700'
                                }`}
                            >
                                <i className="fas fa-search mr-2"></i> Metni Analiz Et
                            </button>
                        </div>
                    )}
                </div>
            )}

            {/* Progress */}
            {isAnalyzing && (
                <div className="py-12 text-center grow flex flex-col justify-center">
                    <div className="w-20 h-20 border-4 border-teal-200 border-t-teal-600 rounded-full animate-spin mx-auto mb-6"></div>
                    <h4 className="text-xl font-bold text-stone-800 mb-2">Ödev Analiz Ediliyor...</h4>
                    <p className="text-stone-500">7 Boyut taranıyor: %{progress}</p>
                </div>
            )}

            {/* Results */}
            {result && (
                <div className="animate-fade-in grow flex flex-col">
                    <div className="flex justify-between items-center mb-6 p-4 bg-teal-50 rounded-lg border border-teal-100">
                        <div>
                            <h4 className="font-bold text-teal-800">Analiz Tamamlandı</h4>
                            <p className="text-sm text-teal-600">
                                {activeTab === 'file' ? file?.name : "Metin Analizi"}
                            </p>
                        </div>
                        <button onClick={resetAnalyzer} className="text-teal-700 hover:text-teal-900 text-sm font-medium bg-white px-3 py-1.5 rounded border border-teal-200 shadow-sm">
                            Yeni Analiz
                        </button>
                    </div>

                    <div className="space-y-4 overflow-y-auto custom-scrollbar pr-2 grow -mr-2">
                        {result.map((res, idx) => (
                            <div key={idx} className="bg-white border border-stone-200 p-4 rounded-lg shadow-sm hover:border-teal-200 transition">
                                <div className="flex justify-between items-center mb-2">
                                    <h5 className="font-bold text-stone-800 text-sm">{res.dimension}</h5>
                                    <span className={`px-2 py-1 rounded text-xs font-bold ${
                                        res.status === 'success' ? 'bg-green-100 text-green-700' :
                                        res.status === 'warning' ? 'bg-amber-100 text-amber-700' :
                                        'bg-red-100 text-red-700'
                                    }`}>
                                        {res.score}/5
                                    </span>
                                </div>
                                <p className="text-xs text-stone-600 leading-relaxed flex items-start">
                                    <i className={`fas ${res.status === 'success' ? 'fa-check-circle text-green-500' : res.status === 'warning' ? 'fa-exclamation-circle text-amber-500' : 'fa-times-circle text-red-500'} mr-2 mt-0.5`}></i>
                                    {res.feedback}
                                </p>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
};
