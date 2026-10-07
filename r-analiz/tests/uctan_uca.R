# =============================================================================
# Uçtan uca test: 02 -> 03 -> 04 -> 05 adımlarını yapay veriyle çalıştırır.
# -----------------------------------------------------------------------------
# - Google Drive'a ve OpenAI'ye BAĞLANMAZ; ücret oluşmaz. 01. adım (Drive)
#   tests/testthat/test-drive.R içinde sahte Drive yanıtlarıyla sınanır.
# - OpenAI yerine yerel sahte sunucu (tests/sahte_openai_sunucusu.R) kullanılır.
# - Yapay kodlamalar bildirideki dağılımla (61/34/26/23; 83/49 ...) üretilir ve
#   05_analiz.R'nin bildirideki sayıları ve cümleleri yeniden üretip üretmediği
#   denetlenir.
# Çalıştırma (r-analiz klasöründe):  Rscript tests/uctan_uca.R
# Gerekli ek paketler: webfakes, officer (sahte veri üretimi için)
# =============================================================================

kok <- normalizePath(".")
stopifnot(file.exists(file.path(kok, "00_ayarlar.R")))
source(file.path(kok, "R", "ortak.R"), encoding = "UTF-8")
source(file.path(kok, "R", "openai.R"), encoding = "UTF-8")
source(file.path(kok, "tests", "sahte_openai_sunucusu.R"), encoding = "UTF-8")
gerekli_paketler(c("webfakes", "officer", "openxlsx", "httr2", "pdftools", "xml2", "digest"))

hatalar <- 0
denetle <- function(kosul, aciklama) {
  if (isTRUE(kosul)) cat("  GEÇTİ :", aciklama, "\n") else { cat("  KALDI :", aciklama, "\n"); hatalar <<- hatalar + 1 }
}
rscript <- file.path(R.home("bin"), "Rscript")
# Ortam değişkenleri system2(env =) ile değil, bu süreçte ayarlanarak aktarılır:
# Windows'ta system2(env =) değişkenleri komut satırına yazar ve Rscript bunları
# betik adı sanar.
adim <- function(betik, dizin, beklenen_cikis = 0) {
  eski <- Sys.getenv(c("R_LIBS", "OPENAI_API_KEY"), unset = NA)
  Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), OPENAI_API_KEY = "test-anahtari")
  on.exit({
    for (ad in names(eski)) if (is.na(eski[[ad]])) Sys.unsetenv(ad) else do.call(Sys.setenv, as.list(eski[ad]))
  }, add = TRUE)
  cikti <- suppressWarnings(system2(rscript, c("--vanilla", betik), stdout = TRUE, stderr = TRUE))
  durum <- attr(cikti, "status") %||% 0
  if (durum != beklenen_cikis) { cat(cikti, sep = "\n") }
  list(durum = durum, cikti = cikti)
}

# --- Geçici proje klasörü ---------------------------------------------------------
proje <- tempfile("proje_")
dir.create(file.path(proje, "R"), recursive = TRUE)
file.copy(list.files(kok, pattern = "^0[0-5]_.*\\.R$", full.names = TRUE), proje)
file.copy(list.files(file.path(kok, "R"), full.names = TRUE), file.path(proje, "R"))
eski_wd <- setwd(proje)
on.exit(setwd(eski_wd), add = TRUE)
dir.create("veri/ham", recursive = TRUE)

# --- Yapay ödev dosyaları ------------------------------------------------------------
# 144 analiz edilecek ödev + kesik yanıt + API reddi + zaman aşımı + 1 taranmış PDF = 148
cat("\n[1] Yapay ödev dosyaları oluşturuluyor\n")
isaretler <- c(rep("", 140), "TEST429", "TEST500", "TESTRET", "TESTFAZ", "TESTKESIK", "TESTFILTRE", "TESTYAVAS")
docx_yaz <- function(yol, metin) {
  d <- officer::read_docx()
  d <- officer::body_add_par(d, "Ödev Yönergesi", style = "heading 1")
  d <- officer::body_add_par(d, metin)
  d <- officer::body_add_table(d, data.frame(Adım = c("1", "2"), Görev = c("Veri topla", "Yorumla")))
  print(d, target = yol)
}
# Türkçe karakterli metin katmanı için cairo_pdf; cairo yoksa ASCII'ye çevrilir.
pdf_yaz <- function(yol, metin) {
  if (capabilities("cairo")) {
    grDevices::cairo_pdf(yol, width = 8, height = 4)
  } else {
    grDevices::pdf(yol, width = 8, height = 4)
    metin <- iconv(metin, "UTF-8", "ASCII//TRANSLIT")
  }
  graphics::plot.new()
  graphics::text(0, 0.8, "Ödev Yönergesi", adj = 0)
  graphics::text(0, 0.5, metin, adj = 0, cex = 0.7)
  grDevices::dev.off()
}
envanter <- data.frame(odev_id = sprintf("O%03d", 1:148), drive_id = sprintf("drv%03d", 1:148),
                       stringsAsFactors = FALSE)
envanter$uzanti <- ifelse(seq_len(148) %% 3 == 0, "pdf", "docx")
envanter$uzanti[148] <- "pdf"
for (i in 1:147) {
  metin <- sprintf("Öğrenciler mahallelerindeki su tüketimini ölçecek ve sonucu yorumlayacak. Ödev %d. %s",
                   i, isaretler[i])
  yol <- file.path("veri/ham", paste0(envanter$odev_id[i], ".", envanter$uzanti[i]))
  if (envanter$uzanti[i] == "pdf") pdf_yaz(yol, metin) else docx_yaz(yol, metin)
}
# 148: metin katmanı olmayan (taranmış gibi) PDF
grDevices::pdf("veri/ham/O148.pdf", width = 8, height = 4)
graphics::plot.new(); graphics::rasterImage(matrix(stats::runif(400), 20), 0, 0, 1, 1)
grDevices::dev.off()
envanter$mime_turu <- ifelse(envanter$uzanti == "pdf", "application/pdf",
                             "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
envanter$yerel_yol <- file.path("veri/ham", paste0(envanter$odev_id, ".", envanter$uzanti))
envanter$ayni_icerik <- ""
envanter$indirme <- "indirildi"
xlsx_yaz(envanter, "veri/envanter.xlsx")

# --- 02: metin çıkarma ----------------------------------------------------------------
cat("\n[2] 02_metin_cikar.R\n")
r <- adim("02_metin_cikar.R", proje)
denetle(r$durum == 0, "02 hatasız tamamlandı")
denetle(length(list.files("veri/yonergeler")) == 148, "148 yönerge dosyası yazıldı")
y1 <- txt_oku("veri/yonergeler/O001.txt")
denetle(grepl("Öğrenciler mahallelerindeki su tüketimini", y1), "docx metni Türkçe karakterleriyle okundu")
denetle(grepl("Adım | Görev", y1, fixed = TRUE) && grepl("1 | Veri topla", y1, fixed = TRUE),
        "docx tablosu satır satır okundu")
y3 <- txt_oku("veri/yonergeler/O003.txt")
denetle(grepl("su t.ketimini", y3), "PDF metni okundu")
kontrol <- xlsx_oku("veri/kontrol_listesi.xlsx")
denetle(isTRUE(kontrol$taranmis_olabilir[kontrol$odev_id == "O148"]), "metin katmanı olmayan PDF işaretlendi")
denetle(is.na(kontrol$dikkat[kontrol$odev_id == "O001"]) || !grepl("yinelenen|okunamadı", kontrol$dikkat[kontrol$odev_id == "O001"]),
        "sorunsuz dosya yanlışlıkla işaretlenmedi")

# Araştırmacının elle düzeltmesi korunuyor mu?
txt_yaz("ELLE DÜZELTİLMİŞ YÖNERGE O002", "veri/yonergeler/O002.txt")
kontrol$kontrol_edildi <- ifelse(kontrol$odev_id == "O148", "hayır", "evet")
kontrol$not[kontrol$odev_id == "O005"] <- "test notu"
openxlsx::write.xlsx(kontrol, "veri/kontrol_listesi.xlsx", overwrite = TRUE)
r <- adim("02_metin_cikar.R", proje)
denetle(txt_oku("veri/yonergeler/O002.txt") == "ELLE DÜZELTİLMİŞ YÖNERGE O002", "yeniden çalıştırmada elle düzeltme korundu")
k2 <- xlsx_oku("veri/kontrol_listesi.xlsx")
denetle(k2$not[k2$odev_id == "O005"] == "test notu" && k2$kontrol_edildi[k2$odev_id == "O001"] == "evet",
        "yeniden çalıştırmada kontrol işaretleri korundu")

# --- 03: API çağrıları (sahte sunucu) --------------------------------------------------
cat("\n[3] 03_yz_cagri.R (sahte sunucu)\n")
sayac <- tempfile("sayac_")
sunucu <- webfakes::new_app_process(sahte_openai_uygulamasi(sayac))
taban <- sub("/$", "", sunucu$url("/v1"))
writeLines(c(sprintf('AYAR$taban_url <- "%s"', taban), "AYAR$deneme_sayisi <- 3",
             "AYAR$zaman_asimi_sn <- 3"), "ayarlar_yerel.R")
r <- adim("03_yz_cagri.R", proje)
denetle(r$durum == 0, "03 hatasız tamamlandı")
kayit <- kayitlari_oku("cikti/api_kayitlari")
denetle(nrow(kayit) == 147, "147 çağrı yapıldı (kontrol edilmemiş 1 ödev gönderilmedi; 400 reddi çalışmayı durdurmadı)")
denetle(kayit$durum[kayit$odev_id == "O146"] == "api_reddi" && kayit$hata_kodu[kayit$odev_id == "O146"] == "invalid_prompt",
        "ödeve özgü 400 (invalid_prompt) 'api_reddi' olarak kaydedildi")
denetle(kayit$durum[kayit$odev_id == "O147"] == "zaman_asimi", "zaman aşımı kaydedildi")
denetle(length(list.files(sayac, "^yavas_")) == 1, "zaman aşımı yeniden denenmedi (ücretli üretim tekrarlanmadı)")
denetle(!any(duplicated(kayit$dosya_koku)) && all(file.exists(paste0(kayit$dosya_koku[kayit$http_durum %in% 200], "_yanit.json"))),
        "her çağrının benzersiz dosyası var")
denetle(file.exists("cikti/cagri_kaydi.xlsx") && nrow(xlsx_oku("cikti/cagri_kaydi.xlsx")) == 147,
        "okunabilir çağrı kaydı kopyası (xlsx) yazıldı")
denetle(sum(kayit$durum == "completed", na.rm = TRUE) == 144, "144 çağrı 'completed'")
denetle(kayit$durum[kayit$odev_id == "O145"] == "incomplete" &&
          kayit$eksik_nedeni[kayit$odev_id == "O145"] == "max_output_tokens", "kesik yanıt ayırt edildi")
denetle(kayit$http_durum[kayit$odev_id == "O141"] == 200, "429 sonrası yeniden deneme başarılı")
denetle(kayit$http_durum[kayit$odev_id == "O142"] == 200, "500 sonrası yeniden deneme başarılı")
denetle(grepl("yardımcı olamam", kayit$ret[kayit$odev_id == "O143"]), "model reddi kaydedildi")
cikti_yolu <- function(id) paste0(kayit$dosya_koku[kayit$odev_id == id][1], "_cikti.txt")
denetle(txt_oku(cikti_yolu("O144")) == "NİHAİ ÖDEV ÇIKTISI",
        "yalnızca final_answer aşaması çıktı olarak alındı")
denetle(grepl("ğüşıöç", txt_oku(cikti_yolu("O001"))), "çıktı UTF-8 olarak kaydedildi")
istek_yolu <- function(id) paste0(kayit$dosya_koku[kayit$odev_id == id][1], "_istek.json")
istek <- jsonlite::fromJSON(istek_yolu("O001"))
denetle(identical(istek$store, FALSE) && is.null(istek$temperature) && istek$reasoning$effort == "medium" &&
          grepl("{YONERGE}", istek$input, fixed = TRUE) == FALSE, "istek gövdesi doğru (store=false, temperature yok)")
denetle(grepl("ELLE DÜZELTİLMİŞ", jsonlite::fromJSON(istek_yolu("O002"))$input),
        "düzeltilmiş yönerge gönderildi")
denetle(all(kayit$model_yanit[kayit$http_durum %in% 200] == "gpt-5.6-sol-2026-07-09"),
        "yanıtı veren model sürümü kaydedildi")
denetle(length(unique(kayit$sistem_istemi_sha256)) == 1 && length(unique(kayit$ayar_sha256)) == 1,
        "tüm çağrılarda aynı sistem istemi ve aynı üretim ayarları")

# Yeniden çalıştırma: yalnızca tamamlanmamış 3 çağrı (kesik, ret, zaman aşımı) tekrarlanmalı
r <- adim("03_yz_cagri.R", proje)
denetle(any(grepl("144 çağrı önceden tamamlanmış; 3 çağrı yapılacak", r$cikti)),
        "yeniden çalıştırmada tamamlananlar atlandı")

# Geçersiz model: ilk 400 hatasında durmalı
writeLines(c(sprintf('AYAR$taban_url <- "%s"', taban), 'AYAR$model <- "gecersiz-model"'), "ayarlar_yerel.R")
r <- adim("03_yz_cagri.R", proje, beklenen_cikis = 1)
denetle(r$durum != 0 && any(grepl("does not exist", r$cikti)), "400 hatasında betik açık mesajla durdu")
denetle(nrow(kayitlari_oku("cikti/api_kayitlari")) == 151, "400 hatasında yalnızca bir çağrı denendi")
# Kota bitti (429 insufficient_quota): yeniden denemeden hemen durmalı
writeLines(c(sprintf('AYAR$taban_url <- "%s"', taban), 'AYAR$model <- "kota-yok"'), "ayarlar_yerel.R")
bas <- Sys.time()
r <- adim("03_yz_cagri.R", proje, beklenen_cikis = 1)
denetle(r$durum != 0 && any(grepl("insufficient_quota", r$cikti)) &&
          as.numeric(difftime(Sys.time(), bas, units = "secs")) < 20,
        "kota hatasında yeniden denemeden hemen durdu")
denetle(nrow(kayitlari_oku("cikti/api_kayitlari")) == 152, "kota hatasında yalnızca bir çağrı denendi")
writeLines(sprintf('AYAR$taban_url <- "%s"', taban), "ayarlar_yerel.R")
sunucu$stop()

# --- 04: kodlama formları ------------------------------------------------------------
cat("\n[4] 04_kodlama_formu.R\n")
r <- adim("04_kodlama_formu.R", proje)
denetle(r$durum == 0, "04 hatasız tamamlandı")
denetle(nrow(xlsx_oku("cikti/kodlama/tasarim_nitelikleri.xlsx", "nitelikler")) == 147,
        "nitelik şablonu API sonucundan bağımsız: onaylı 147 yönergenin hepsi var")
# Araştırmacı teknik olarak tamamlanamayan 3 ödevi (kesik, API reddi, zaman aşımı)
# analiz dışı bırakmaya karar verir:
kontrol <- xlsx_oku("veri/kontrol_listesi.xlsx")
kontrol$kontrol_edildi[kontrol$odev_id %in% c("O145", "O146", "O147")] <- "hayır"
openxlsx::write.xlsx(kontrol, "veri/kontrol_listesi.xlsx", overwrite = TRUE)
r <- adim("04_kodlama_formu.R", proje)
denetle(r$durum == 0 && any(grepl("artık onaylı olmayan", r$cikti)), "04 yeniden çalıştı; onayı kaldırılan ödevler bildirildi")
f1 <- xlsx_oku("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
f2 <- xlsx_oku("cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx")
denetle(nrow(f1) == 144, "birinci kodlayıcı formunda 144 ödev (kesik, ret, zaman aşımı dışarıda)")
denetle(f1$yz_ciktisi[f1$odev_id == "O144"] == "NİHAİ ÖDEV ÇIKTISI", "form çıktıyı seçilen çağrının dosyasından aldı")
denetle(nrow(f2) == 36 && all(is.na(f2$kategori)), "ikinci kodlayıcı formunda 36 ödev, kodlar boş (körleme)")

# Bildirideki dağılımla yapay kodlama
kat <- c("Tamamlanamadı", "Sınırlı ölçüde tamamlandı", "Büyük ölçüde tamamlandı", "Tam olarak tamamlandı")
set.seed(7)
f1$kategori <- sample(rep(kat, c(23, 26, 34, 61)))
openxlsx::write.xlsx(list(kodlama = f1), "cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx", overwrite = TRUE)
f2$kategori <- f1$kategori[match(f2$odev_id, f1$odev_id)]
degis <- c(2, 9, 17, 30)   # dört ödevde bir basamak fark
f2$kategori[degis] <- kat[pmin(4, pmax(1, match(f2$kategori[degis], kat) + c(1, -1, 1, -1)))]
openxlsx::write.xlsx(list(kodlama = f2), "cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx", overwrite = TRUE)

nf_tum <- xlsx_oku("cikti/kodlama/tasarim_nitelikleri.xlsx", "nitelikler")
kk <- xlsx_oku("cikti/kodlama/tasarim_nitelikleri.xlsx", "kod_kitabi")
nf <- nf_tum[!nf_tum$odev_id %in% c("O145", "O146", "O147"), ]
n <- nrow(nf)
ata <- function(k, havuz = seq_len(n)) { x <- integer(n); x[sample(havuz, k)] <- 1L; x }
nf$ozgu_girdi <- ata(83)
nf$girdi_islevsel <- ata(49, which(nf$ozgu_girdi == 1))
nf$girdi_islevsel[nf$ozgu_girdi == 0] <- NA        # koşullu alt kod: kodlayıcı boş bırakır
nf$veri_toplama <- ata(53); nf$belgeleme <- ata(38)
nf$belgeleme_yalniz_kanit <- ata(16, which(nf$belgeleme == 1))
nf$belgeleme_yalniz_kanit[nf$belgeleme == 0] <- NA
nf$surece_yayma <- ata(27); nf$yansitma <- ata(26); nf$karar_verme <- ata(19)
nf$gerekcelendirme <- ata(7); nf$dogrulama <- ata(7)
nf <- rbind(nf, nf_tum[nf_tum$odev_id %in% c("O145", "O146", "O147"), ])   # onaysız, kodlanmamış
openxlsx::write.xlsx(list(nitelikler = nf, kod_kitabi = kk), "cikti/kodlama/tasarim_nitelikleri.xlsx", overwrite = TRUE)

# --- 05: analiz ------------------------------------------------------------------------
cat("\n[5] 05_analiz.R\n")
r <- adim("05_analiz.R", proje)
denetle(r$durum == 0, "05 hatasız tamamlandı")
ozet <- txt_oku("cikti/analiz/ozet.txt")
beklenen <- c(
  "144 ödevin 61'i (%42,4) kullanılan ÜYZ modeli tarafından tam olarak, 34'ü (%23,6) büyük ölçüde ve 26'sı (%18,1) sınırlı ölçüde tamamlanmış; 23'ü (%16,0) ise tamamlanamamıştır",
  "ödevlerin 95'i (%66,0)",
  "isteyen 83 ödevin yalnızca 49'unda, yani bu ödevlerin %59,0'ında ve tüm ödevlerin %34,0'ında",
  "38 ödevin 16'sında (%42,1)"
)
for (b in beklenen) denetle(grepl(b, ozet, fixed = TRUE), paste0("özet cümlesi: \"", substr(b, 1, 60), "...\""))
denetle(any(grepl("nitelik analizine alınmayan ödev\\(ler\\): O145, O146, O147", r$cikti)),
        "onaysız ödevler nitelik analizinden çıkarıldı")
tb <- openxlsx::read.xlsx("cikti/analiz/tablolar.xlsx", "nitelikler")
denetle(identical(as.numeric(tb$n), c(83, 49, 53, 38, 16, 27, 26, 19, 7, 7)), "nitelik sıklıkları bildiriyle aynı")
denetle(all(abs(tb$yuzde - c(57.6, 34.0, 36.8, 26.4, 11.1, 18.8, 18.1, 13.2, 4.9, 4.9)) < 0.05), "nitelik yüzdeleri bildiriyle aynı")
kp <- openxlsx::read.xlsx("cikti/analiz/tablolar.xlsx", "kappa")
denetle(nrow(kp) == 3 && all(kp$ga_alt <= kp$kappa & kp$kappa <= kp$ga_ust), "kappa ve güven aralıkları hesaplandı")
if (requireNamespace("ggplot2", quietly = TRUE)) {
  denetle(file.exists("cikti/analiz/sekil1_tamamlanabilirlik.png"), "şekil 1 üretildi")
}
# --- Ayar değişikliği sonrası eski formlar sessizce kullanılmamalı ---------------
cat("\n[6] Ayar değişikliği: eski kodlar korunmalı ama yeni çıktılarla karıştırılmamalı\n")
sunucu <- webfakes::new_app_process(sahte_openai_uygulamasi(tempfile("sayac_")))
writeLines(c(sprintf('AYAR$taban_url <- "%s"', sub("/$", "", sunucu$url("/v1"))),
             "AYAR$azami_cikti_token <- 64000"), "ayarlar_yerel.R")
r <- adim("03_yz_cagri.R", proje)
denetle(any(grepl("0 çağrı önceden tamamlanmış; 144 çağrı yapılacak", r$cikti)),
        "token sınırı değişince bütün ödevler yeniden çağrıldı")
r <- adim("05_analiz.R", proje, beklenen_cikis = 1)
denetle(r$durum != 0 && any(grepl("üretilmemiş", r$cikti)), "05 eski ayarlarla kodlanmış formu fark edip durdu")
r <- adim("04_kodlama_formu.R", proje)
denetle(r$durum == 0 && any(grepl("YENİDEN KODLAYIN", r$cikti)), "04 eskimiş satırları yeni çıktılarla değiştirdi")
denetle(length(list.files("cikti/kodlama", "kodlayici1_tamamlanabilirlik_yedek_")) == 1, "değiştirmeden önce yedek alındı")
f1y <- xlsx_oku("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
denetle(nrow(f1y) == 144 && all(is.na(f1y$kategori)) && all(grepl("_t1_", f1y$cagri_dosyasi)) &&
          !any(f1y$cagri_dosyasi %in% f1$cagri_dosyasi), "yenilenen satırların kodu boşaltıldı, çağrı dosyası güncellendi")
r <- adim("05_analiz.R", proje, beklenen_cikis = 1)
denetle(r$durum != 0 && any(grepl("kodlanmış ödev yok", r$cikti)), "kodsuz formda 05 açık hatayla durdu")
sunucu$stop()

cat("\nKappa tablosu:\n"); print(kp)
cat("\nÇıktı klasörü:", proje, "\n")
cat(if (hatalar == 0) "\nTÜM DENETİMLER GEÇTİ\n" else sprintf("\n%d DENETİM KALDI\n", hatalar))
quit(status = if (hatalar == 0) 0 else 1)
