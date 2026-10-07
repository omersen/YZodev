# =============================================================================
# 00_ayarlar.R : Tüm adımların ortak ayarları
# -----------------------------------------------------------------------------
# Yalnızca bu dosyayı düzenleyin. Diğer betikler ayarları buradan okur.
# Çalışma dizini 'r-analiz' klasörü olmalıdır (RStudio'da r-analiz.Rproj'u
# açın ya da setwd() ile bu klasöre geçin).
# =============================================================================

source("R/ortak.R", encoding = "UTF-8")
source("R/metin_cikarma.R", encoding = "UTF-8")
source("R/drive.R", encoding = "UTF-8")
source("R/openai.R", encoding = "UTF-8")
source("R/analiz.R", encoding = "UTF-8")
r_surumu_denetle()

AYAR <- list(

  # --- Google Drive ------------------------------------------------------------
  # Ödevlerin bulunduğu klasörün bağlantısı ya da kimliği.
  # Örnek: "https://drive.google.com/drive/folders/1AbC..." veya "1AbC..."
  drive_klasor = "BURAYA_DRIVE_KLASOR_BAGLANTISI",
  drive_email = NULL,            # NULL ise tarayıcıda hesap sorulur
  # TRUE: .doc/.rtf/.odt ve taranmış PDF'ler, yerelde okunamazsa Drive'da geçici
  # olarak Google Dokümanlar'a dönüştürülüp (OCR) okunur. Bu, tam Drive yetkisi
  # ister. FALSE: salt-okunur yetki; okunamayan dosyalar raporda işaretlenir.
  drive_donusturme_izni = FALSE,

  # --- Klasörler (bu klasörler .gitignore ile GitHub'a gönderilmez) ----------
  veri_dizini = "veri",          # indirilen dosyalar ve çıkarılan metinler
  cikti_dizini = "cikti",        # API yanıtları, kodlama formları, tablolar

  # --- OpenAI API ----------------------------------------------------------------
  # API anahtarı koda YAZILMAZ: ~/.Renviron dosyasına OPENAI_API_KEY=... ekleyin.
  api_ucu = "responses",         # "responses" (önerilen) ya da "chat"
  taban_url = "https://api.openai.com/v1",
  model = "gpt-5.6-sol",

  # Bildiride "aynı sistem istemi ve kullanıcı istem şablonu" kullanıldığı
  # yazıyor. Özgün çalışmadaki metinleri hatırlıyorsanız AYNEN buraya yazın;
  # aşağıdakiler yalnızca yer tutucu örneklerdir. Bu metinler bulguları doğrudan
  # etkiler ve sunumda/makalede birebir raporlanmalıdır.
  sistem_istemi = paste(
    "Kullanıcı sana bir ödev yönergesi verecek.",
    "Ödevi, öğretmene teslim edilecek son ürün olarak, yönergedeki gereklilikleri",
    "karşılayacak biçimde Türkçe hazırla."
  ),
  kullanici_sablonu = "Aşağıdaki ödevi yap.\n\nÖDEV YÖNERGESİ:\n\"\"\"\n{YONERGE}\n\"\"\"",
  sistem_rolu = "developer",     # yalnızca api_ucu = "chat" için

  # Sabit tutulan üretim parametreleri. NULL olanlar API'ye gönderilmez.
  # Not: GPT-5.x akıl yürütme modellerinde temperature/top_p büyük olasılıkla
  # yalnızca akil_yurutme_duzeyi = "none" iken kabul edilir; aksi hâlde API
  # 400 hatası verir. Responses API'de seed parametresi yoktur.
  akil_yurutme_duzeyi = "medium",  # none, low, medium, high, xhigh, max
  ayrintililik = "medium",         # low, medium, high
  azami_cikti_token = 32000,       # akıl yürütme token'ları da bu sınıra dahildir
  sicaklik = NULL,
  top_p = NULL,
  seed = NULL,                     # yalnızca api_ucu = "chat" (kullanımdan kalkıyor)

  tekrar_sayisi = 1,               # her ödev kaç bağımsız çağrıyla denensin
  deneme_sayisi = 5,               # geçici hatalarda (429, 5xx) en çok deneme
  zaman_asimi_sn = 600,
  cagri_sirasi_tohumu = 20260101,  # çağrı sırasını rastgeleleştirmek için

  # --- Kodlama -------------------------------------------------------------------
  kategoriler = c("Tamamlanamadı", "Sınırlı ölçüde tamamlandı",
                  "Büyük ölçüde tamamlandı", "Tam olarak tamamlandı"),
  ikinci_kodlayici_orani = 0.25,   # 144 ödevde 36 ödev
  ikinci_kodlayici_tohumu = 20260102
)

# Kişisel/yerel ayarlar (Drive bağlantısı gibi) isterseniz ayarlar_yerel.R
# dosyasına yazılabilir; bu dosya .gitignore ile GitHub'a gönderilmez.
# Örnek: AYAR$drive_klasor <- "https://drive.google.com/drive/folders/..."
if (file.exists("ayarlar_yerel.R")) source("ayarlar_yerel.R", encoding = "UTF-8")

dir.create(AYAR$veri_dizini, showWarnings = FALSE, recursive = TRUE)
dir.create(AYAR$cikti_dizini, showWarnings = FALSE, recursive = TRUE)
