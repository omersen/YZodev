import React, { useState } from 'react';
import { applicationSteps } from '../data/content';

export const TrainingApplication: React.FC = () => {
    const [submitted, setSubmitted] = useState(false);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitted(true);
    };

    return (
        <div className="bg-white rounded-xl shadow-lg border border-stone-200 overflow-hidden flex flex-col md:flex-row">
            {/* Left: Process Tracker */}
            <div className="bg-stone-50 p-8 md:w-1/3 border-r border-stone-200">
                <h3 className="text-xl font-bold text-stone-800 mb-6">Başvuru Süreci</h3>
                <div className="space-y-8 relative">
                    {/* Vertical Line */}
                    <div className="absolute left-3.5 top-2 bottom-2 w-0.5 bg-stone-200"></div>
                    
                    {applicationSteps.map((step) => (
                        <div key={step.id} className="relative flex items-start">
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center relative z-10 border-2 ${
                                step.status === 'completed' ? 'bg-teal-600 border-teal-600 text-white' :
                                step.status === 'current' ? 'bg-white border-teal-600 text-teal-600 animate-pulse' :
                                'bg-white border-stone-300 text-stone-300'
                            }`}>
                                {step.status === 'completed' ? <i className="fas fa-check text-xs"></i> : <span className="text-xs font-bold">{step.id}</span>}
                            </div>
                            <div className="ml-4">
                                <h4 className={`text-sm font-bold ${step.status === 'current' ? 'text-teal-700' : 'text-stone-700'}`}>{step.title}</h4>
                                {step.date && <p className="text-xs text-stone-500 mt-0.5">{step.date}</p>}
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Right: Application Form */}
            <div className="p-8 md:w-2/3 bg-white">
                {!submitted ? (
                    <form onSubmit={handleSubmit} className="space-y-5">
                        <div className="mb-2">
                            <h3 className="text-2xl font-bold text-stone-800">Eğitime Başvurun</h3>
                            <p className="text-sm text-stone-500">4 Günlük "Nitelikli Fen Ödevi Tasarımı" sertifika programı için ön başvuru formu.</p>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                            <div>
                                <label className="block text-xs font-bold text-stone-600 uppercase mb-1">Ad Soyad</label>
                                <input type="text" required className="w-full bg-stone-50 border border-stone-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-teal-500 transition" placeholder="Adınız Soyadınız" />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-stone-600 uppercase mb-1">E-posta</label>
                                <input type="email" required className="w-full bg-stone-50 border border-stone-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-teal-500 transition" placeholder="ornek@okul.com" />
                            </div>
                        </div>

                        <div>
                            <label className="block text-xs font-bold text-stone-600 uppercase mb-1">Okul / Kurum</label>
                            <input type="text" required className="w-full bg-stone-50 border border-stone-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-teal-500 transition" placeholder="Kurumunuzun adı" />
                        </div>

                        <div>
                            <label className="block text-xs font-bold text-stone-600 uppercase mb-1">Motivasyon Mektubu (Kısa)</label>
                            <textarea required className="w-full bg-stone-50 border border-stone-200 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-teal-500 transition h-24 resize-none" placeholder="Bu eğitime neden katılmak istiyorsunuz?"></textarea>
                        </div>

                        <div className="pt-2">
                            <button type="submit" className="w-full bg-teal-600 text-white font-bold py-3 rounded-lg hover:bg-teal-700 transition shadow-lg flex justify-center items-center">
                                <i className="fas fa-paper-plane mr-2"></i> Başvuruyu Gönder
                            </button>
                        </div>
                    </form>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-center p-6 animate-fade-in">
                        <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mb-6">
                            <i className="fas fa-check text-4xl"></i>
                        </div>
                        <h3 className="text-2xl font-bold text-stone-800 mb-2">Başvurunuz Alındı!</h3>
                        <p className="text-stone-600 max-w-sm mx-auto">
                            Ön başvurunuz başarıyla sistemimize kaydedilmiştir. Değerlendirme sonucu e-posta adresinize 3 gün içinde iletilecektir.
                        </p>
                    </div>
                )}
            </div>
        </div>
    );
};