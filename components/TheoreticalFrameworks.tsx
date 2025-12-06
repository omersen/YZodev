
import React from 'react';

export const TheoreticalFrameworks: React.FC = () => {
    return (
        <div className="bg-white p-8 rounded-xl border border-stone-200 shadow-sm">
            <div className="mb-8 text-center">
                <h3 className="text-2xl font-bold text-stone-800 mb-3">Çift Şeritli Değerlendirme Modeli</h3>
                <p className="text-stone-600 max-w-2xl mx-auto">
                    Liu & Bridgeman (2023) tarafından önerilen bu model, değerlendirmeyi YZ kullanım düzeyine göre iki ana şeride ayırır.
                </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 relative">
                {/* Connector Line for Desktop */}
                <div className="hidden md:block absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-12 h-12 bg-stone-100 rounded-full border-4 border-white z-10 flex items-center justify-center">
                    <i className="fas fa-exchange-alt text-stone-400"></i>
                </div>

                {/* Lane 1 */}
                <div className="bg-rose-50 rounded-xl p-6 border-2 border-rose-100 relative overflow-hidden group hover:border-rose-300 transition-all">
                    <div className="absolute top-0 right-0 bg-rose-200 text-rose-800 text-xs font-bold px-3 py-1 rounded-bl-lg">
                        ŞERİT 1
                    </div>
                    <div className="mb-4">
                        <div className="w-12 h-12 bg-rose-100 text-rose-600 rounded-full flex items-center justify-center text-xl mb-3">
                            <i className="fas fa-ban"></i>
                        </div>
                        <h4 className="text-lg font-bold text-stone-800">YZ-Kısıtlı (AI-Resistant)</h4>
                        <p className="text-sm text-stone-600 mt-1">Bilişsel temel becerilerin güvence altına alınması.</p>
                    </div>
                    <ul className="space-y-2 text-sm text-stone-700">
                        <li className="flex items-start"><i className="fas fa-check text-rose-500 mt-1 mr-2"></i> Gözetimli sınıf içi sınavlar</li>
                        <li className="flex items-start"><i className="fas fa-check text-rose-500 mt-1 mr-2"></i> Sözlü savunmalar (Vivas)</li>
                        <li className="flex items-start"><i className="fas fa-check text-rose-500 mt-1 mr-2"></i> Kağıt-kalem etkinlikleri</li>
                    </ul>
                </div>

                {/* Lane 2 */}
                <div className="bg-teal-50 rounded-xl p-6 border-2 border-teal-100 relative overflow-hidden group hover:border-teal-300 transition-all">
                    <div className="absolute top-0 right-0 bg-teal-200 text-teal-800 text-xs font-bold px-3 py-1 rounded-bl-lg">
                        ŞERİT 2
                    </div>
                    <div className="mb-4">
                        <div className="w-12 h-12 bg-teal-100 text-teal-600 rounded-full flex items-center justify-center text-xl mb-3">
                            <i className="fas fa-robot"></i>
                        </div>
                        <h4 className="text-lg font-bold text-stone-800">YZ-Dahil (AI-Enabled)</h4>
                        <p className="text-sm text-stone-600 mt-1">YZ ile birlikte üretim ve üst düzey düşünme.</p>
                    </div>
                    <ul className="space-y-2 text-sm text-stone-700">
                        <li className="flex items-start"><i className="fas fa-check text-teal-500 mt-1 mr-2"></i> Süreç odaklı projeler</li>
                        <li className="flex items-start"><i className="fas fa-check text-teal-500 mt-1 mr-2"></i> YZ destekli beyin fırtınası</li>
                        <li className="flex items-start"><i className="fas fa-check text-teal-500 mt-1 mr-2"></i> Eleştirel doğrulama görevleri</li>
                    </ul>
                </div>
            </div>
        </div>
    );
};
