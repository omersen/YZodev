
import React, { useState } from 'react';
import { ModelRadarChart } from './components/Charts';
import { Agenda } from './components/Agenda';
import { HomeworkGallery } from './components/HomeworkGallery';
import { PromptBuilder } from './components/PromptBuilder';
import { DesignChecklist } from './components/DesignChecklist';
import { exportCurriculum } from './services/exportService';
import { policyTemplates, trainingVision } from './data/content';
import { ResearchLibrary } from './components/ResearchLibrary';
import { AssignmentAnalyzer } from './components/AssignmentAnalyzer';
import { TrainingApplication } from './components/TrainingApplication';
import { ModelDimensions } from './components/ModelDimensions';
import { TheoreticalFrameworks } from './components/TheoreticalFrameworks';

const App: React.FC = () => {
  const [activeHeroTab, setActiveHeroTab] = useState('harvard');

  return (
    <div className="min-h-screen bg-stone-50 font-sans text-stone-900">
      
      {/* Navigation */}
      <nav className="bg-white shadow-sm border-b border-stone-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <div className="bg-teal-600 text-white p-1.5 rounded mr-3">
                <i className="fas fa-dna text-lg"></i>
              </div>
              <span className="font-bold text-xl tracking-tight text-stone-800 hidden md:block">Fen & YZ Eğitim Portalı</span>
              <span className="font-bold text-xl tracking-tight text-stone-800 md:hidden">F&YZ</span>
            </div>
            <div className="hidden md:flex space-x-6 items-center text-sm font-medium">
              <a href="#felsefe" className="text-stone-600 hover:text-teal-600 transition">Kuramsal Çerçeve</a>
              <a href="#analiz" className="text-stone-600 hover:text-teal-600 transition">Analiz</a>
              <a href="#model" className="text-stone-600 hover:text-teal-600 transition">Model</a>
              <a href="#program" className="text-stone-600 hover:text-teal-600 transition">Program</a>
              <a href="#basvuru" className="text-stone-600 hover:text-teal-600 transition">Başvuru</a>
              <button onClick={() => document.getElementById('araclar')?.scrollIntoView({behavior: 'smooth'})} className="bg-teal-600 text-white px-4 py-2 rounded-md hover:bg-teal-700 transition shadow-sm">
                Araç Kutusu
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <header className="bg-gradient-to-b from-stone-50 to-white py-16 md:py-24 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-1/3 h-full bg-teal-50/50 -skew-x-12 translate-x-20 z-0"></div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="flex flex-col lg:flex-row items-center gap-12">
            
            {/* Left Content */}
            <div className="lg:w-1/2">
              <div className="inline-block bg-white text-teal-800 text-xs font-bold px-3 py-1 rounded-full mb-6 border border-teal-200 shadow-sm uppercase tracking-wide">
                TÜBİTAK 4004
              </div>
              <h1 className="text-3xl md:text-4xl lg:text-5xl font-extrabold text-stone-900 leading-tight mb-6">
                Dijital Pedagoji ve Ölçmenin Yeni Vizyonu: <span className="text-transparent bg-clip-text bg-gradient-to-r from-teal-600 to-teal-400">Yapay Zeka Dirençli</span> Ödev Tasarımı Eğitimi
              </h1>
              <p className="text-lg text-stone-600 mb-8 leading-relaxed max-w-2xl">
                Öğretmen yetkinliklerini güçlendirmeyi amaçlayan bu proje; yasaklama yerine yönetme, ürün yerine süreç ve tekil doğruluk yerine çoklu kanıt ilkelerine dayalı <strong>7 boyutlu</strong> bilimsel bir çerçeve sunar.
              </p>
              <div className="flex flex-wrap gap-4">
                <button onClick={() => document.getElementById('analiz')?.scrollIntoView({behavior: 'smooth'})} className="bg-stone-800 text-white px-8 py-3.5 rounded-xl hover:bg-stone-900 transition shadow-lg font-semibold flex items-center">
                  <i className="fas fa-microscope mr-2"></i> Ödev Tasarımı Analiz Modülü
                </button>
                <button onClick={exportCurriculum} className="bg-white text-stone-700 border border-stone-300 px-8 py-3.5 rounded-xl hover:bg-stone-50 transition font-semibold flex items-center">
                  <i className="fas fa-file-download mr-2"></i> Eğitim Kılavuzunu İndir
                </button>
              </div>
            </div>

            {/* Right Content: Scientific Vision Panel */}
            <div className="lg:w-1/2 w-full">
              <div className="bg-white rounded-2xl shadow-xl border border-stone-200 overflow-hidden relative">
                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-teal-500 to-emerald-500"></div>
                
                {/* Tabs */}
                <div className="flex border-b border-stone-100">
                  <button 
                    onClick={() => setActiveHeroTab('harvard')}
                    className={`flex-1 py-3 text-sm font-bold transition-colors ${activeHeroTab === 'harvard' ? 'bg-stone-50 text-rose-600 border-b-2 border-rose-500' : 'text-stone-400 hover:text-stone-600'}`}
                  >
                    <i className="fas fa-heartbeat mr-2"></i> Harvard Tıp
                  </button>
                  <button 
                    onClick={() => setActiveHeroTab('stanford')}
                    className={`flex-1 py-3 text-sm font-bold transition-colors ${activeHeroTab === 'stanford' ? 'bg-stone-50 text-indigo-600 border-b-2 border-indigo-500' : 'text-stone-400 hover:text-stone-600'}`}
                  >
                    <i className="fas fa-dna mr-2"></i> Stanford & Duke
                  </button>
                  <button 
                    onClick={() => setActiveHeroTab('edu')}
                    className={`flex-1 py-3 text-sm font-bold transition-colors ${activeHeroTab === 'edu' ? 'bg-stone-50 text-teal-600 border-b-2 border-teal-500' : 'text-stone-400 hover:text-stone-600'}`}
                  >
                    <i className="fas fa-graduation-cap mr-2"></i> Eğitim Vizyonu
                  </button>
                </div>

                {/* Content */}
                <div className="p-8 min-h-[280px] flex flex-col justify-center">
                  {activeHeroTab === 'harvard' && (
                    <div className="animate-fade-in">
                      <h3 className="text-xl font-bold text-stone-800 mb-3">Nadir Hastalık ve Kanser Teşhisi</h3>
                      <p className="text-stone-600 text-sm leading-relaxed mb-4">
                        Harvard Tıp Fakültesi araştırmacıları tarafından geliştirilen yapay zeka modelleri, nadir hastalıkların teşhis sürecini yıllardan günlere indirmeyi başarmıştır. Ayrıca, YZ destekli mamografi analizleri, meme kanseri teşhisindeki yanlış pozitif oranlarını düşürerek radyologların tanısal doğruluğunu (diagnostic accuracy) artırmaktadır.
                      </p>
                      <div className="bg-rose-50 border border-rose-100 p-3 rounded-lg flex items-center">
                        <i className="fas fa-quote-left text-rose-400 mr-3 text-lg"></i>
                        <p className="text-rose-800 text-xs font-semibold italic">Sonuç: YZ, doktorun yerini almıyor; doktorun uzmanlığını güçlendiren bir 'karar destek sistemi' olarak işlev görüyor.</p>
                      </div>
                    </div>
                  )}

                  {activeHeroTab === 'stanford' && (
                    <div className="animate-fade-in">
                      <h3 className="text-xl font-bold text-stone-800 mb-3">Sanal Laboratuvarlar ve İlaç Keşfi</h3>
                      <p className="text-stone-600 text-sm leading-relaxed mb-4">
                        Stanford ve Duke Üniversitesi'ndeki bilim insanları, yeni ilaç moleküllerini test etmek için "Sanal YZ Laboratuvarları" kullanmaktadır. Bu teknoloji, laboratuvar ortamında yıllar süren deneme-yanılma süreçlerini simülasyonlarla aylara indirerek tıbbi inovasyonu hızlandırmaktadır.
                      </p>
                      <div className="bg-indigo-50 border border-indigo-100 p-3 rounded-lg flex items-center">
                        <i className="fas fa-atom text-indigo-400 mr-3 text-lg"></i>
                        <p className="text-indigo-800 text-xs font-semibold italic">Etki: Bilimsel süreçlerde YZ, araştırmacının bilişsel kapasitesini artıran bir hızlandırıcıdır.</p>
                      </div>
                    </div>
                  )}

                  {activeHeroTab === 'edu' && (
                    <div className="animate-fade-in">
                      <h3 className="text-xl font-bold text-stone-800 mb-3">Bilişsel Kaldıraç Olarak YZ</h3>
                      <p className="text-stone-600 text-sm leading-relaxed mb-4">
                        Tıpta bir "Teşhis Aracı" olan YZ, eğitimde de öğrencinin zihnini açan bir "Bilişsel Kaldıraç" (Cognitive Lever) olmalıdır. Andrej Karpathy'nin vurguladığı gibi, amaç YZ ile rekabet etmek değil, onu yöneterek insan potansiyelini maksimize etmektir.
                      </p>
                      <div className="bg-teal-50 border border-teal-100 p-3 rounded-lg flex items-center">
                        <i className="fas fa-lightbulb text-teal-400 mr-3 text-lg"></i>
                        <p className="text-teal-800 text-xs font-semibold italic">Vizyon: "Yapay zeka ile savaşmayın, onu yönetin ve dönüştürün."</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Philosophy / Rationale Section */}
      <section id="felsefe" className="py-16 bg-stone-900 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <span className="text-teal-400 font-bold tracking-wider text-sm uppercase">Gerçeklik Kontrolü</span>
            <h2 className="text-3xl md:text-4xl font-bold mt-2">Neden YZ ile Savaşmamalıyız?</h2>
            <p className="text-stone-400 mt-4 max-w-2xl mx-auto">
              Yapay zeka tespiti ve yasaklaması, eğitimde sürdürülebilir bir strateji değildir. Çözüm, pedagojik dönüşümdedir.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Card 1 */}
            <div className="bg-stone-800 p-8 rounded-xl border border-stone-700 hover:border-red-500/50 transition duration-300 group">
              <div className="w-14 h-14 bg-stone-700 rounded-full flex items-center justify-center mb-6 group-hover:bg-red-900/30 transition">
                <i className="fas fa-ban text-red-400 text-2xl"></i>
              </div>
              <h3 className="text-xl font-bold mb-3 text-stone-100">Yasaklama Çıkmazı</h3>
              <p className="text-stone-400 text-sm leading-relaxed">
                Turnitin ve OpenAI verilerine göre, YZ tespit araçları %4-9 oranında "yanlış pozitif" hatası vermektedir. Masum bir öğrenciyi haksız yere suçlamak, eğitimci-öğrenci güvenini onarılamaz şekilde zedeler.
              </p>
            </div>

            {/* Card 2 */}
            <div className="bg-stone-800 p-8 rounded-xl border border-stone-700 hover:border-amber-500/50 transition duration-300 group">
              <div className="w-14 h-14 bg-stone-700 rounded-full flex items-center justify-center mb-6 group-hover:bg-amber-900/30 transition">
                <i className="fas fa-level-up-alt text-amber-400 text-2xl"></i>
              </div>
              <h3 className="text-xl font-bold mb-3 text-stone-100">Bilişsel Kaldıraç</h3>
              <p className="text-stone-400 text-sm leading-relaxed">
                YZ, bir "Koltuk Değneği" değil, zihinsel bir "Trambolin" olarak konumlandırılmalıdır. Tıpkı hesap makinesinin matematiği yok etmeyip daha ileri taşıması gibi, YZ de düşünme süreçlerini derinleştirebilir.
              </p>
            </div>

            {/* Card 3 */}
            <div className="bg-stone-800 p-8 rounded-xl border border-stone-700 hover:border-teal-500/50 transition duration-300 group">
              <div className="w-14 h-14 bg-stone-700 rounded-full flex items-center justify-center mb-6 group-hover:bg-teal-900/30 transition">
                <i className="fas fa-sync-alt text-teal-400 text-2xl"></i>
              </div>
              <h3 className="text-xl font-bold mb-3 text-stone-100">Fırsat Dönüşümü</h3>
              <p className="text-stone-400 text-sm leading-relaxed">
                Geleneksel "Sonuç Odaklı" (C Seviyesi) işleri YZ yapabilir. Bu durum, eğitimcileri öğrenciden "İnsan Odaklı" (A Seviyesi) işler (yaratıcılık, etik karar, sentez) beklemeye zorlayan bir fırsattır.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Vision & Skills Section */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row gap-12 items-center">
            <div className="md:w-1/2">
              <h2 className="text-3xl font-bold text-stone-800 mb-6">{trainingVision.title}</h2>
              <p className="text-stone-600 mb-6 leading-relaxed">
                {trainingVision.description}
              </p>
              <div className="bg-stone-50 p-6 rounded-xl border-l-4 border-teal-500 italic text-stone-700">
                "Amacımız YZ'yi alt etmek değil, onun omuzlarında yükselerek onu aşmaktır."
              </div>
            </div>
            <div className="md:w-1/2 grid grid-cols-1 sm:grid-cols-2 gap-4">
              {trainingVision.skills.map((skill, idx) => (
                <div key={idx} className="p-5 rounded-lg border border-stone-200 hover:shadow-md transition bg-stone-50/50">
                  <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shadow-sm mb-3 text-teal-600">
                    <i className={`fas ${skill.icon}`}></i>
                  </div>
                  <h4 className="font-bold text-stone-800 mb-1">{skill.title}</h4>
                  <p className="text-xs text-stone-500">{skill.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Assignment Analyzer */}
      <section id="analiz" className="py-16 bg-stone-50 border-t border-stone-200">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <AssignmentAnalyzer />
        </div>
      </section>

      {/* Theoretical Frameworks */}
      <section className="py-16 bg-white">
        <div className="max-w-5xl mx-auto px-4">
          <TheoreticalFrameworks />
        </div>
      </section>

      {/* Model Section */}
      <section id="model" className="py-16 bg-stone-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-stone-800">7 Boyutlu Tasarım Çerçevesi</h2>
            <p className="mt-4 text-stone-600 max-w-2xl mx-auto">
              Literatür temelli (Bloom, Webb, Toulmin) bu model, nitelikli bir fen ödevinin yapıtaşlarını tanımlar.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-1 bg-white p-6 rounded-xl border border-stone-200 shadow-sm h-fit">
              <h3 className="text-lg font-bold text-stone-700 mb-4 text-center">İdeal Ödev Profili</h3>
              <ModelRadarChart />
              <div className="mt-6 text-center">
                <span className="inline-block w-3 h-3 bg-teal-600 rounded-full mr-2"></span>
                <span className="text-xs text-stone-500">Nitelikli Ödev</span>
                <span className="inline-block w-3 h-3 bg-stone-300 rounded-full ml-4 mr-2"></span>
                <span className="text-xs text-stone-500">Geleneksel</span>
              </div>
            </div>
            <ModelDimensions />
          </div>
        </div>
      </section>

      {/* Agenda Section */}
      <section id="program" className="py-16 bg-white border-t border-stone-200">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="mb-10 text-center">
            <h2 className="text-3xl font-bold text-stone-800">4 Günlük Eğitim Programı</h2>
            <p className="mt-3 text-stone-600">Öğretmenlerin dönüşüm yolculuğu için yapılandırılmış müfredat.</p>
          </div>
          <Agenda />
        </div>
      </section>

      {/* Homework Examples */}
      <section id="ornekler" className="py-16 bg-stone-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="mb-10 text-center">
            <h2 className="text-3xl font-bold text-stone-800">Örnek Ödev Senaryoları</h2>
            <p className="mt-4 text-stone-600">
              7 boyutlu modele uygun olarak tasarlanmış fen bilimleri ödev örnekleri.
            </p>
          </div>
          <HomeworkGallery />
        </div>
      </section>

      {/* Research Library */}
      <section className="py-16 bg-white border-t border-stone-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-2xl font-bold text-stone-800 mb-8 flex items-center">
            <i className="fas fa-book-reader text-teal-600 mr-3"></i> İlgili Araştırmalar ve Literatür
          </h2>
          <ResearchLibrary />
        </div>
      </section>

      {/* Teacher's Toolkit */}
      <section id="araclar" className="py-16 bg-stone-900 text-stone-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="mb-12">
            <h2 className="text-3xl font-bold text-white">Öğretmen Araç Kutusu</h2>
            <p className="mt-4 text-stone-400">
              Sınıf içi uygulama için interaktif dijital araçlar.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12">
            {/* Tool 1: Prompt Builder */}
            <div className="h-full">
              <PromptBuilder />
            </div>

            {/* Right Column: Policies & Checklist */}
            <div className="flex flex-col gap-8">
              {/* Tool 2: Checklist */}
              <div className="h-[400px]">
                <DesignChecklist />
              </div>

              {/* Tool 3: Policy Templates */}
              <div className="bg-stone-800 p-6 rounded-xl border border-stone-700">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-lg font-bold text-amber-400">YZ Etik Beyan Şablonları</h3>
                  <i className="fas fa-shield-alt text-stone-500"></i>
                </div>
                <div className="space-y-3 overflow-y-auto max-h-60 custom-scrollbar pr-2">
                  {policyTemplates.map((policy, idx) => (
                    <div key={idx} className={`bg-stone-700/50 p-3 rounded-lg border-l-4 ${policy.border} hover:bg-stone-700 transition`}>
                      <h4 className="font-bold text-white text-xs mb-1">{policy.title}</h4>
                      <p className="text-stone-300 text-xs italic mb-2">"{policy.text}"</p>
                      <button onClick={() => {navigator.clipboard.writeText(policy.text); alert('Kopyalandı!');}} className="text-[10px] text-teal-400 hover:text-teal-300 flex items-center">
                        <i className="far fa-copy mr-1"></i> Kopyala
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Application Section */}
      <section id="basvuru" className="py-16 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <TrainingApplication />
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-stone-100 border-t border-stone-200 py-10 text-center">
        <div className="max-w-7xl mx-auto px-4">
          <p className="text-stone-600 text-sm font-semibold">© 2025 Fen & YZ Eğitim Portalı</p>
          <p className="text-stone-500 text-xs mt-2">Bu proje, TÜBİTAK 4004 Doğa Eğitimi ve Bilim Okulları Destekleme Programı kapsamında hazırlanmıştır.</p>
          <div className="mt-6 flex justify-center space-x-6 text-stone-400">
            <span className="text-xs">Chiu et al. (2024)</span>
            <span className="text-xs">•</span>
            <span className="text-xs">MEB YZ Politikası (2025)</span>
            <span className="text-xs">•</span>
            <span className="text-xs">UNESCO (2023)</span>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default App;
