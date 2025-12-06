
import { AgendaDay, HomeworkExample, PolicyTemplate, ChecklistItem, DimensionDetail, ResearchStudy, TrainingSkill, ApplicationStep } from '../types';

export const trainingVision = {
    title: "Eğitimin Amacı ve Kazanımlar",
    description: "Bu eğitim paketi, Türkiye'de görev yapan fen bilgisi öğretmenlerine YZ çağında 'özgün', 'süreç odaklı' ve 'otantik' ödev tasarımının temel ilkelerini kazandırmayı hedeflemektedir. Amaç YZ'yi yasaklamak değil, onu pedagojik bir kaldıraç olarak kullanmaktır.",
    skills: [
        { icon: "fa-pencil-ruler", title: "Özgün Tasarım", desc: "YZ tarafından kolayca kopyalanamayan, yerel bağlamlı ve otantik fen ödevleri tasarlama becerisi." },
        { icon: "fa-robot", title: "YZ Entegrasyonu", desc: "YZ'yi bir 'kopya makinesi' değil, 'düşünce ortağı' ve 'üretkenlik asistanı' olarak derslere entegre etme." },
        { icon: "fa-gavel", title: "Etik & Politika", desc: "Sınıf içi YZ kullanım kuralları (sınırlar/izinler) ve akademik dürüstlük çerçevesi oluşturma." },
        { icon: "fa-chart-line", title: "Süreç Değerlendirme", desc: "Sonuç odaklı notlandırmadan, süreç, performans ve bilişsel iz takibi odaklı değerlendirmeye geçiş." }
    ] as TrainingSkill[]
};

export const applicationSteps: ApplicationStep[] = [
    { id: 1, title: "Başvuru Formu", status: 'current', date: "Bugün" },
    { id: 2, title: "Ön Değerlendirme", status: 'upcoming', date: "3 Gün İçinde" },
    { id: 3, title: "Mülakat", status: 'upcoming', date: "Tarih Belirlenecek" },
    { id: 4, title: "Kabul & Kayıt", status: 'upcoming' }
];

export const detailedDimensions: DimensionDetail[] = [
    {
        id: 1,
        title: "Bilişsel Derinlik & Üst Düzey Düşünme",
        icon: "fa-brain",
        color: "text-teal-600",
        border: "border-teal-500",
        desc: "Bloom Taksonomisi'nin analiz, değerlendirme ve yaratma basamaklarına odaklanma.",
        aiRelation: "YZ, bilgi hatırlama (DOK 1) ve uygulama (DOK 2) düzeyinde mükemmeldir. Ancak karmaşık stratejik düşünme ve özgün sentez (DOK 3-4) hala insan denetimi gerektirir.",
        sciExample: "'Fotosentez nedir?' yerine, 'Bitkinin ışık almayan yapraklarındaki gelişim farkını hipotez kurarak test et ve sonuçları yorumla' denilmelidir."
    },
    {
        id: 2,
        title: "Otantiklik & Bağlamsallık",
        icon: "fa-map-marker-alt",
        color: "text-amber-600",
        border: "border-amber-500",
        desc: "Öğrencinin kendi yaşam deneyimini, yerel çevresini ve güncel olayları kullanması.",
        aiRelation: "YZ genel-geçer bilgi üretir. Öğrencinin yaşadığı mahalledeki su kirliliği verisine veya o sabah sınıfta yaşanan bir tartışmaya erişemez.",
        sciExample: "Genel çevre kirliliği raporu yerine, öğrencinin kendi okul bahçesindeki atık türlerini bir hafta boyunca sayması ve yerel çözüm önermesi."
    },
    {
        id: 3,
        title: "Süreç Şeffaflığı (Process over Product)",
        icon: "fa-search-plus",
        color: "text-rose-600",
        border: "border-rose-500",
        desc: "Nihai ürünün değil, o ürüne giden yolun (taslaklar, hatalar, revizyonlar) değerlendirilmesi.",
        aiRelation: "YZ anında nihai sonucu verir ancak 'süreç' yaşayamaz. Düşünme adımlarının belgelenmesi YZ kopyacılığını anlamsızlaştırır.",
        sciExample: "Deney raporunun sadece sonucunu değil; deney sırasındaki gözlem notlarını, başarısız ilk denemeyi ve neden yöntem değiştirdiğini içeren 'Laboratuvar Günlüğü'nü puanlamak."
    },
    {
        id: 4,
        title: "YZ Kullanım Etiği & Şeffaflık",
        icon: "fa-shield-alt",
        color: "text-indigo-600",
        border: "border-indigo-500",
        desc: "YZ kullanımının yasaklanması yerine, nerede ve nasıl kullanıldığının beyan edilmesi.",
        aiRelation: "Gizli kullanım akademik suçtur; beyan edilmiş ve doğrulanmış kullanım ise dijital okuryazarlıktır.",
        sciExample: "Öğrencinin raporunun sonuna 'Bu çalışmada ChatGPT'yi beyin fırtınası için kullandım, ancak verileri TÜBİTAK kaynaklarından doğruladım' notunu düşmesi."
    },
    {
        id: 5,
        title: "Çoklu Kanıt & Performans",
        icon: "fa-layer-group",
        color: "text-emerald-600",
        border: "border-emerald-500",
        desc: "Bilginin sadece metinle değil; sözlü sunum, video, model veya posterle kanıtlanması.",
        aiRelation: "YZ harika metin yazar ama sınıf önünde deney yapamaz veya spontane sorulara (sözlü savunma) tutarlı duygusal yanıtlar veremez.",
        sciExample: "Yazılı bir makale yerine, öğrencinin yaptığı 'Basit Makine' modelini sınıfta çalıştırarak tanıtması ve arkadaşlarına nasıl çalıştığını anlatması."
    },
    {
        id: 6,
        title: "İşbirliği & Sosyal Öğrenme",
        icon: "fa-users",
        color: "text-blue-600",
        border: "border-blue-500",
        desc: "Akran değerlendirmesi, tartışma ve grup projeleriyle öğrenmenin sosyal boyuta taşınması.",
        aiRelation: "YZ bireysel bir araçtır. İnsanlar arası etkileşim, müzakere ve ortak karar alma süreçleri YZ tarafından tam olarak simüle edilemez.",
        sciExample: "Bir grup öğrencinin 'Nükleer Enerji: Evet mi Hayır mı?' münazarasında karşıt görüşleri savunması ve birbirlerinin argümanlarını çürütmesi."
    },
    {
        id: 7,
        title: "Yansıtma (Metacognition)",
        icon: "fa-mirror",
        color: "text-purple-600",
        border: "border-purple-500",
        desc: "Öğrencinin kendi öğrenme sürecini, zorluklarını ve gelişimini analiz etmesi.",
        aiRelation: "YZ kişisel bir 'deneyim' yaşamadığı için, bir görevi yaparken 'nerede zorlandığını' veya 'nasıl hissettiğini' sahici bir şekilde yazamaz.",
        sciExample: "Proje sonunda: 'Bu deneyde en çok veri toplarken zorlandım çünkü... Bir dahaki sefere ölçüm aletini daha dikkatli seçeceğim' şeklinde bir yansıtma yazısı."
    }
];

export const researchStudies: ResearchStudy[] = [
    {
        id: "r_duke",
        title: "Creating New Drug Delivery Techniques with AI",
        year: "2025",
        author: "Duke University",
        tag: "Tıp/Bilim",
        summary: "Duke araştırmacıları, YZ kullanarak biyolojik dokulara ilaç taşınması için yeni ve daha etkili yöntemler geliştirdi."
    },
    {
        id: "r_stanford",
        title: "Virtual AI Lab Speeds Discovery",
        year: "2025",
        author: "Stanford Medicine",
        tag: "Tıp/Bilim",
        summary: "Stanford'un geliştirdiği 'Sanal Bilim İnsanı' modelleri, laboratuvar deneylerini simüle ederek keşif süreçlerini hızlandırıyor."
    },
    {
        id: "r_harvard",
        title: "AI Model Speeds Rare Disease Diagnosis",
        year: "2025",
        author: "Harvard Medical School",
        tag: "Tıp/Bilim",
        summary: "Yeni bir YZ modeli, nadir hastalıkların teşhisini hızlandırarak doktorların hata payını düşürüyor ve tedaviye erişimi kolaylaştırıyor."
    },
    {
        id: "r_karpathy",
        title: "Advice for the AI Classroom",
        year: "2024",
        author: "Andrej Karpathy",
        tag: "Eğitim",
        summary: "OpenAI kurucularından Karpathy, YZ'nin eğitimde yasaklanmak yerine, öğrencilerin potansiyelini açığa çıkaran bir araç olarak kullanılmasını savunuyor."
    },
    {
        id: "r1",
        title: "Generative AI and the Future of Education",
        year: "2023",
        author: "UNESCO",
        tag: "Politika",
        summary: "UNESCO'nun küresel raporu, YZ'nin eğitimde yasaklanması yerine 'insan merkezli' bir yaklaşımla entegre edilmesini ve değerlendirme yöntemlerinin 'ürün'den 'süreç'e kaymasını önerir."
    },
    {
        id: "r2",
        title: "AI-Resistant Assessment Strategies",
        year: "2024",
        author: "Awadallah & Khlaif",
        tag: "Strateji",
        summary: "Bu çalışma, YZ'ye 'dirençli' ödevlerin özelliklerini tanımlar: Kişiselleştirme, bağlamsallaştırma ve çok modlu (multimodal) teslimat. Sadece metne dayalı ödevlerin artık geçerli olmadığını savunur."
    },
    {
        id: "r5",
        title: "Contextual Assessment Design",
        year: "2025",
        author: "Gonsalves",
        tag: "Tasarım",
        summary: "GenAI çağında değerlendirme tasarımının yüksek seviyede çözümleme ve gerçek dünya uygulaması içermesi gerektiğini, böylece öğrencilerin ürettikleri çözümlerin yüzeysel kalmayacağını savunur."
    },
    {
        id: "r6",
        title: "Addressing AI-Driven Cheating",
        year: "2023",
        author: "Torrey Trust",
        tag: "Etik",
        summary: "Eğitimcilere yasaklar yerine dürüstlük odaklı bir diyalog kurmayı, ödevlere gerçek dünya uygulamaları kazandırmayı ve öğrenmeyi sosyal bir deneyim haline getirmeyi önerir."
    },
    {
        id: "r3",
        title: "Two-Lane Assessment Approach",
        year: "2023",
        author: "Liu & Bridgeman",
        tag: "Model",
        summary: "Değerlendirmeyi iki şeride ayırır: 1. Şerit (YZ-Kısıtlı) gözetimli sınıf içi sınavlar içindir. 2. Şerit (YZ-Açık) ise öğrencilerin YZ'yi bir asistan olarak kullandığı ve bunu belgelediği projelerdir."
    },
    {
        id: "r4",
        title: "Eğitimde Yapay Zeka Politika Belgesi",
        year: "2024",
        author: "MEB (Türkiye)",
        tag: "Ulusal",
        summary: "Milli Eğitim Bakanlığı'nın vizyon belgesi, öğretmenlerin YZ okuryazarlığının artırılmasını ve YZ'nin bir 'eğitim materyali' olarak müfredata entegrasyonunu hedefler."
    }
];

export const agendaData: Record<string, AgendaDay> = {
    day1: {
        id: 'day1',
        title: "1. Gün: Paradigma Değişimi",
        icon: "fa-bolt",
        color: "text-amber-600",
        goal: "YZ'nin eğitime etkisini anlama, 7 boyutlu modeli kavrama ve etik ilkeleri benimseme.",
        sessions: [
            { time: "09:30 - 11:00", title: "Açılış ve YZ'ye Giriş", desc: "Şok Testi: ChatGPT'ye canlı fen sorusu sorma. YZ'nin yapabildikleri ve yapamadıkları. MEB 2025 Politika Belgesi özeti." },
            { time: "11:15 - 12:30", title: "Model Tanıtımı ve Etik Çerçeve", desc: "7 Boyutlu Nitelikli Ödev Tasarımı Çerçevesi'nin tanıtımı. 'Bu Ödev YZ-Dirençli mi?' vaka analizi." },
            { time: "13:30 - 15:00", title: "YZ Politikası Oluşturma Atölyesi", desc: "Grup çalışması: Sınıf içi YZ kullanım kurallarını belirleme. 'Kopya vs Destek' ayrımı." },
            { time: "15:15 - 16:30", title: "Ödev Analizi ve Yeniden Tasarım", desc: "Katılımcıların kendi eski ödevlerini 7 boyuta göre puanlaması ve iyileştirme beyin fırtınası." }
        ]
    },
    day2: {
        id: 'day2',
        title: "2. Gün: Tasarım Atölyesi",
        icon: "fa-pencil-ruler",
        color: "text-blue-600",
        goal: "Bilişsel Derinlik, Otantiklik ve Süreç Şeffaflığı boyutlarına göre özgün ödev tasarlamak.",
        sessions: [
            { time: "09:30 - 11:00", title: "Bilişsel Derinlik ve Otantiklik", desc: "Bloom ve Webb'in DOK çerçevesi. 'Googlelanamaz Soru' yazma teknikleri. Yerel veri kullanımı." },
            { time: "11:15 - 12:30", title: "Süreç Şeffaflığı ve İzlenebilirlik", desc: "'Process over Product' yaklaşımı. Düşünme günlüğü ve taslak takibi şablonları tasarlama." },
            { time: "13:30 - 15:00", title: "Ödev Tasarımı Atölyesi", desc: "Bireysel çalışma: Seçilen bir fen kazanımı için detaylı ödev yönergesi yazımı." },
            { time: "15:15 - 16:30", title: "Ödev Sunumları", desc: "Hızlı sunumlar (3 dk) ve 'Bir Yıldız, Bir İstek' geri bildirim tekniği." }
        ]
    },
    day3: {
        id: 'day3',
        title: "3. Gün: Ölçme ve Rubrikler",
        icon: "fa-ruler-combined",
        color: "text-emerald-600",
        goal: "Analitik rubrik geliştirme ve çoklu kanıt (sözlü savunma) stratejilerini uygulama.",
        sessions: [
            { time: "09:30 - 11:00", title: "Analitik Rubrik Geliştirme", desc: "Fen içeriği, süreç becerileri ve YZ kullanımı için 4 düzeyli kriter yazımı." },
            { time: "11:15 - 12:30", title: "YZ ile Rubrik Tasarımı", desc: "ChatGPT kullanarak rubrik taslağı oluşturma ve insan gözüyle iyileştirme." },
            { time: "13:30 - 15:00", title: "Çoklu Kanıt ve Sözlü Savunma", desc: "Rol yapma: Sözlü savunma simülasyonu. Bilişsel izi takip etmek için soru teknikleri." },
            { time: "15:15 - 16:30", title: "Akran Değerlendirmesi (Boyut 6)", desc: "İşbirliği ve argümantasyon. Akran değerlendirme formu oluşturma pratiği." }
        ]
    },
    day4: {
        id: 'day4',
        title: "4. Gün: Uygulama ve Gelecek",
        icon: "fa-rocket",
        color: "text-purple-600",
        goal: "Kapsayıcı uygulama planı oluşturma, prompt mühendisliği ve yansıtma.",
        sessions: [
            { time: "09:30 - 11:00", title: "Yansıtma ve Öz-Düzenleme (Boyut 7)", desc: "Metacognition (Bilişötesi) soruları geliştirme. Öğrencinin kendi öğrenmesini değerlendirmesi." },
            { time: "11:15 - 12:30", title: "Prompt Yazımı Atölyesi", desc: "Rol-Bağlam-Görev-Format formülü. Öğretmenler için örnek yanıt üretme ve dönüt promptları." },
            { time: "13:30 - 15:00", title: "Uygulama Planı Geliştirme", desc: "4-5 haftalık ders akışı planlama. Materyal hazırlığı ve zaman yönetimi." },
            { time: "15:15 - 16:00", title: "Ödev Paketi Paylaşımı", desc: "Galeri yürüyüşü: Nihai ödev paketlerinin sergilenmesi ve sertifika töreni." }
        ]
    }
};

export const homeworkData: HomeworkExample[] = [
    {
        id: 1,
        title: "Fen Mitleri Avcıları",
        classLevel: "7. Sınıf",
        icon: "fa-ghost",
        aim: "Yanlış fen bilgilerini (mitler) bilimsel yöntemle sorgulayıp çürütmek.",
        desc: "Öğrenci çevresindeki bir miti seçer, YZ'den ilk bilgiyi alır ancak bilimsel kaynaklarla doğrusunu kanıtlar.",
        instructions: "Çevrenizdeki (aile, arkadaş, sosyal medya) bir FEN MİTİNİ tespit edip (Örn: 'Şimşek aynı yere iki kez düşmez'), bilimsel yöntemle araştıracaksınız. YZ'yi ilk fikir için kullanabilirsin ancak 3 güvenilir kaynakla doğrulamalısın.",
        steps: [
            "Mit Tespiti: Bir fen miti bul ve not et.",
            "Hipotez: 'Bu mit doğru mu, yanlış mı?' sorusuna hipotez kur.",
            "Araştırma: En az 3 güvenilir kaynak bul.",
            "Kanıt Toplama: Bilimsel kanıtları listele.",
            "Dönüşüm: Miti bilimsel doğru bilgiye çeviren bir infografik hazırla."
        ],
        policy: "YZ, 'hatalı bilgi kaynağı' simülasyonu veya ilk fikir aracı olarak kullanılır. Doğrulama zorunludur.",
        deliverable: "Mit Analiz Raporu + İnfografik + 3 dk Sunum",
        duration: "3 Hafta",
        rubric: [
            { criteria: "Fen İçeriği", levels: { 4: "Mit ve doğru bilgi eksiksiz, 3+ kaynakla açıklanmış.", 3: "Açıklama doğru, 2-3 kaynak var.", 2: "Doğru bilgi yüzeysel, 1-2 kaynak.", 1: "Bilgi yanlış/eksik." } },
            { criteria: "YZ Şeffaflığı", levels: { 4: "Kullanım beyan edilmiş, bilgi doğrulanmış.", 3: "Beyan var, doğrulama yapılmış.", 2: "Beyan belirsiz.", 1: "Beyan yok." } }
        ]
    },
    {
        id: 2,
        title: "Ev Deneyi: Basit Makineler",
        classLevel: "6. Sınıf",
        icon: "fa-flask",
        aim: "Basit makineleri (kaldıraç, makara) evdeki malzemelerle yaparak kuvvet çarpanını test etmek.",
        desc: "Öğrenci deneyi tasarlar, YZ'den fikir alabilir ancak kurulum ve ölçüm tamamen fizikseldir.",
        instructions: "Evdeki malzemelerle bir basit makine yapacak ve kuvvet çarpanını ölçeceksiniz. YZ'den fikir alabilirsiniz ancak deneyi kendi malzemelerinizle kurmalısınız.",
        steps: [
            "Tasarım: Hangi makineyi yapacağını seç ve çiz.",
            "Hipotez: Kuvvet kazancı beklentini yaz.",
            "Uygulama: Makineyi kur, 3 farklı ölçüm yap ve fotoğrafla.",
            "Analiz: Bulgularını 'Deney Günlüğü'ne yaz.",
            "Yansıtma: Hipotezin tuttu mu? Neden?"
        ],
        policy: "YZ'den deney fikri alınabilir, ancak deneyin yapılışı ve veriler öğrenciye ait olmalıdır.",
        deliverable: "Deney Raporu + Fotoğraflar + Sınıf İçi Gösterim",
        duration: "2-3 Hafta",
        rubric: [
            { criteria: "Deney Tasarımı", levels: { 4: "Özgün, değişkenler kontrol edilmiş, 3+ deneme.", 3: "Uygun, standart malzeme, 2-3 deneme.", 2: "Basit, 1-2 deneme.", 1: "Uygunsuz." } },
            { criteria: "Süreç Belgeleme", levels: { 4: "Günlük tam, fotoğraflar net, derin yansıtma.", 3: "Günlük var, fotoğraflar tamam.", 2: "Günlük eksik.", 1: "Belgeleme yok." } }
        ]
    },
    {
        id: 3,
        title: "Yerel Çevre Sorunu Çözümü",
        classLevel: "8. Sınıf",
        icon: "fa-tree",
        aim: "Mahalledeki/okuldaki gerçek bir çevre sorununu tespit edip bilimsel çözüm önermek.",
        desc: "Öğrenci kendi verisini (fotoğraf, anket) toplar. YZ, çözüm önerilerini geliştirmek için kullanılır.",
        instructions: "Çevrenizde (mahalle, park) bir çevre sorunu tespit edin. Kendi verinizi toplayın ve fen bilgisini kullanarak çözüm önerin.",
        steps: [
            "Problem Tespiti: Gözlem yap, fotoğraf çek.",
            "Veri Toplama: Sayım yap veya mini anket uygula.",
            "Çözüm: YZ desteğiyle 2-3 çözüm geliştir, en iyisini seç.",
            "Sunum: Bilimsel gerekçelerle çözümünü sun."
        ],
        policy: "Yerel veriler (fotoğraf, sayı) öğrenciye ait olmalıdır. YZ çözüm fikirleri için kullanılabilir.",
        deliverable: "Proje Raporu + Veri Tabloları + Poster",
        duration: "4 Hafta",
        rubric: [
            { criteria: "Problem Tanımı", levels: { 4: "Yerel bağlam güçlü, verilerle destekli.", 3: "Yerel bağlam var.", 2: "Bağlam zayıf.", 1: "Tanımsız." } },
            { criteria: "Veri Toplama", levels: { 4: "Ölçülebilir veri, 10+ anket/gözlem.", 3: "Bazı veriler var.", 2: "Veri az.", 1: "Veri yok." } }
        ]
    },
    {
        id: 4,
        title: "Argümantasyon: Fen Tartışması",
        classLevel: "8. Sınıf",
        icon: "fa-comments",
        aim: "Tartışmalı bir konuda (GDO, Nükleer) karşıt görüşleri analiz edip kendi argümanını savunmak.",
        desc: "Toulmin modeli kullanılır. YZ, karşıt görüşleri öğrenmek için bir tartışma partneridir.",
        instructions: "GDO, Nükleer Enerji vb. bir konu seçin. İki tarafın argümanlarını araştırın, sonra kendi görüşünüzü 'İddia-Kanıt-Gerekçe' yapısıyla savunun.",
        steps: [
            "Araştırma: İki tarafın (Evet/Hayır) argümanlarını bul.",
            "YZ ile Tartışma: YZ'ye karşıt görüşü savunmasını söyle.",
            "Sentez: Hangi kanıtlar daha güçlü?",
            "Savunma: Kendi argümanını yaz."
        ],
        policy: "YZ tartışma partneridir. Argümanlar YZ'den kopyalanmamalı, sentezlenmelidir.",
        deliverable: "Yazılı Argüman (2 sayfa) + Sözlü Tartışma",
        duration: "3 Hafta",
        rubric: [
            { criteria: "Argümantasyon", levels: { 4: "İddia net, kanıt güçlü, karşı tez çürütülmüş.", 3: "İddia ve kanıt var.", 2: "Kanıt zayıf.", 1: "Argüman yok." } },
            { criteria: "Kaynak Kullanımı", levels: { 4: "Kaynaklar güvenilir ve eleştirel değerlendirilmiş.", 3: "Kaynaklar uygun.", 2: "Kaynak zayıf.", 1: "Kaynak yok." } }
        ]
    },
    {
        id: 5,
        title: "Haber Dedektifi: Doğru mu?",
        classLevel: "7. Sınıf",
        icon: "fa-newspaper",
        aim: "Medyadaki popüler fen haberlerinin bilimsel doğruluğunu orijinal kaynaklarla teyit etmek.",
        desc: "Öğrenci sansasyonel bir haber bulur, bilimsel makaleyi arar ve YZ ile konsensüsü kontrol eder.",
        instructions: "İnternette 'mucize buluş' gibi bir fen haberi bulun. Orijinal bilimsel kaynağına inin ve haberin doğruluğunu analiz edin.",
        steps: [
            "Haber Seçimi: Son 6 aydan bir haber bul.",
            "Analiz: Kaynak var mı? Abartı var mı?",
            "Doğrulama: Orijinal makaleyi veya güvenilir kurumu bul.",
            "YZ Kontrolü: Bilimsel konsensüsü YZ'ye sor.",
            "Yeniden Yazım: Haberi doğru şekilde yeniden yaz."
        ],
        policy: "YZ, bilimsel konsensüsü öğrenmek için kullanılır. Orijinal kaynak insan tarafından bulunmalıdır.",
        deliverable: "Analiz Raporu + Düzeltilmiş Haber Metni",
        duration: "3 Hafta",
        rubric: [
            { criteria: "Haber Analizi", levels: { 4: "Detaylı sorgulama, abartılar tespit edilmiş.", 3: "Analiz var.", 2: "Yüzeysel.", 1: "Yok." } },
            { criteria: "Doğrulama", levels: { 4: "Orijinal kaynak bulunmuş ve karşılaştırılmış.", 3: "Kaynak bulunmuş.", 2: "Karşılaştırma zayıf.", 1: "Kaynak yok." } }
        ]
    }
];

export const policyTemplates: PolicyTemplate[] = [
    { 
        title: "Fikir Üretimi İçin", 
        text: "Proje konum için fikir bulurken YZ'den beyin fırtınası desteği aldım, ancak seçtiğim fikri kendim geliştirdim. Prompt: '7. sınıf için deney fikirleri ver'.", 
        border: "border-amber-500" 
    },
    { 
        title: "Düzeltme & Editörlük İçin", 
        text: "Yazdığım metni YZ'ye kontrol ettirdim ve imla hatalarımı düzelttim. İçerik ve fikirler tamamen bana aittir.", 
        border: "border-blue-500" 
    },
    { 
        title: "Veri Görselleştirme İçin", 
        text: "Topladığım yerel verileri YZ'ye vererek bu grafiği çizdirdim. Verilerin doğruluğunu kendim kontrol ettim.", 
        border: "border-emerald-500" 
    },
    {
        title: "Karşıt Görüş/Tartışma İçin",
        text: "Konuyu anlamak için YZ ile tartıştım. Onun sunduğu argümanları [X] ve [Y] kaynaklarından doğrulayarak kendi metnimi yazdım.",
        border: "border-purple-500"
    }
];

export const designChecklist: ChecklistItem[] = [
    { id: "c1", dimension: "1. Bilişsel Derinlik", question: "Ödev, Bloom'un analiz/değerlendirme/yaratma düzeylerinden birini hedefliyor mu?" },
    { id: "c2", dimension: "1. Bilişsel Derinlik", question: "Ödev, tek doğru cevap yerine çoklu çözüm yollarına izin veriyor mu?" },
    { id: "c3", dimension: "2. Otantiklik", question: "Öğrenci kendi yaşam deneyimini veya yerel gözlemlerini kullanıyor mu?" },
    { id: "c4", dimension: "2. Otantiklik", question: "Öğrenci internetten bulduğu değil, kendisinin elde ettiği verileri mi kullanıyor?" },
    { id: "c5", dimension: "3. Süreç Şeffaflığı", question: "Sadece sonuç değil, taslaklar ve süreç adımları da değerlendiriliyor mu?" },
    { id: "c6", dimension: "3. Süreç Şeffaflığı", question: "Öğrenci başarısız denemelerini yansıtma fırsatı buluyor mu?" },
    { id: "c7", dimension: "4. YZ Etiği", question: "YZ'nin hangi aşamada kullanılabileceği açıkça belirtilmiş mi?" },
    { id: "c8", dimension: "4. YZ Etiği", question: "Öğrenciden YZ kullanım beyanı isteniyor mu?" },
    { id: "c9", dimension: "5. Çoklu Kanıt", question: "Ödev, yazılı rapor dışında (sunum, video, model) bir çıktı içeriyor mu?" },
    { id: "c10", dimension: "5. Çoklu Kanıt", question: "Sözlü savunma veya soru-cevap oturumu var mı?" },
    { id: "c11", dimension: "6. İşbirliği", question: "Akran değerlendirmesi veya grup çalışması var mı?" },
    { id: "c12", dimension: "7. Yansıtma", question: "Öğrenci 'Nerede zorlandım?', 'Ne öğrendim?' sorularını yanıtlıyor mu?" }
];
