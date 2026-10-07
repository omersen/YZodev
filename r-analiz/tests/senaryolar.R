# =============================================================================
# Senaryo testleri: gerçek kullanımda karşılaşılabilecek yeniden çalıştırma
# durumları (kaynak dosyanın değişmesi, onayın kaldırılması, sonradan eklenen
# ödevler, kodlayıcının eklediği sütunlar, eksik nitelik kodlaması...).
# Drive'a ve OpenAI'ye BAĞLANMAZ. Çalıştırma (r-analiz klasöründe):
#   Rscript tests/senaryolar.R
# =============================================================================

kok <- normalizePath(".")
stopifnot(file.exists(file.path(kok, "00_ayarlar.R")))
for (f in c("ortak.R", "metin_cikarma.R", "drive.R", "openai.R", "analiz.R")) {
  source(file.path(kok, "R", f), encoding = "UTF-8")
}
source(file.path(kok, "tests", "sahte_openai_sunucusu.R"), encoding = "UTF-8")
gerekli_paketler(c("webfakes", "officer", "openxlsx", "httr2", "pdftools", "xml2", "digest"))

hatalar <- 0
denetle <- function(kosul, aciklama) {
  if (isTRUE(kosul)) cat("  GEÇTİ :", aciklama, "\n") else { cat("  KALDI :", aciklama, "\n"); hatalar <<- hatalar + 1 }
}
rscript <- file.path(R.home("bin"), "Rscript")
adim <- function(betik, beklenen_cikis = 0) {
  eski <- Sys.getenv(c("R_LIBS", "OPENAI_API_KEY"), unset = NA)
  Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), OPENAI_API_KEY = "test-anahtari")
  on.exit(for (ad in names(eski)) if (is.na(eski[[ad]])) Sys.unsetenv(ad) else do.call(Sys.setenv, as.list(eski[ad])), add = TRUE)
  cikti <- suppressWarnings(system2(rscript, c("--vanilla", betik), stdout = TRUE, stderr = TRUE))
  durum <- attr(cikti, "status") %||% 0
  if (durum != beklenen_cikis) cat(cikti, sep = "\n")
  list(durum = durum, cikti = cikti)
}
docx_yaz <- function(yol, metin) {
  d <- officer::body_add_par(officer::read_docx(), metin)
  print(d, target = yol)
}
onayla <- function(ids, deger = "evet") {
  k <- xlsx_oku("veri/kontrol_listesi.xlsx")
  k$kontrol_edildi[k$odev_id %in% ids] <- deger
  openxlsx::write.xlsx(k, "veri/kontrol_listesi.xlsx", overwrite = TRUE)
}
kodla <- function(yol, sayfa = "kodlama", kategori = "Tam olarak tamamlandı") {
  wb <- openxlsx::loadWorkbook(yol)
  d <- openxlsx::read.xlsx(wb, sayfa, skipEmptyCols = FALSE)
  d$kategori[is.na(d$kategori)] <- kategori
  openxlsx::writeData(wb, sayfa, d)
  openxlsx::saveWorkbook(wb, yol, overwrite = TRUE)
}

proje <- tempfile("senaryo_", tmpdir = Sys.getenv("TEST_DIZINI", tempdir()))
dir.create(file.path(proje, "R"), recursive = TRUE)
file.copy(list.files(kok, pattern = "^0[0-5]_.*\\.R$", full.names = TRUE), proje)
file.copy(list.files(file.path(kok, "R"), full.names = TRUE), file.path(proje, "R"))
eski_wd <- setwd(proje)
on.exit(setwd(eski_wd), add = TRUE)
dir.create("veri/ham", recursive = TRUE)

n <- 12
envanter <- data.frame(odev_id = sprintf("O%03d", 1:n), drive_id = sprintf("d%03d", 1:n), uzanti = "docx",
                       mime_turu = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                       stringsAsFactors = FALSE)
envanter$yerel_yol <- file.path("veri/ham", paste0(envanter$odev_id, ".docx"))
envanter$indirme <- "indirildi"
for (i in 1:n) docx_yaz(envanter$yerel_yol[i], sprintf("Ödev %d: mahallendeki parkları gözlemle ve raporla. SÜRÜM1", i))
xlsx_yaz(envanter, "veri/envanter.xlsx")

sunucu <- webfakes::new_app_process(sahte_openai_uygulamasi(tempfile("sayac_")))
on.exit(sunucu$stop(), add = TRUE)
writeLines(c(sprintf('AYAR$taban_url <- "%s"', sub("/$", "", sunucu$url("/v1"))),
             "AYAR$ikinci_kodlayici_orani <- 0.5"), "ayarlar_yerel.R")

# --- İlk tur: 8 ödev onaylanır, çağrılır, kodlanır -----------------------------------
cat("\n[A] İlk tur (8 ödev)\n")
invisible(adim("02_metin_cikar.R"))
onayla(sprintf("O%03d", 1:8))
denetle(adim("03_yz_cagri.R")$durum == 0, "03 ilk tur")
denetle(adim("04_kodlama_formu.R")$durum == 0, "04 ilk tur")
f2 <- xlsx_oku("cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx")
denetle(nrow(f2) == 4, "ikinci kodlayıcı: 8 ödevin yarısı (4)")

# Kodlayıcı forma kendi sütununu ve sayfasını ekler, ardından kodlar
wb <- openxlsx::loadWorkbook("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
d <- openxlsx::read.xlsx(wb, "kodlama", skipEmptyCols = FALSE)
openxlsx::writeData(wb, "kodlama", data.frame(kodlayici_notu = rep("notum", nrow(d))), startCol = ncol(d) + 1)
openxlsx::addWorksheet(wb, "notlarim"); openxlsx::writeData(wb, "notlarim", "kendi notlarım")
openxlsx::saveWorkbook(wb, "cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx", overwrite = TRUE)
kodla("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
kodla("cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx")

# --- Nitelikler henüz kodlanmadan 05: tamamlanabilirlik çıktıları yine üretilmeli -----
cat("\n[B] Nitelikler kodlanmadan analiz\n")
r <- adim("05_analiz.R")
denetle(r$durum == 0 && any(grepl("henüz kodlanmamış", r$cikti)), "05 nitelik kodlaması olmadan çalıştı")
denetle(file.exists("cikti/analiz/tablolar.xlsx") && file.exists("cikti/analiz/ozet.txt"),
        "tamamlanabilirlik tablosu ve özet yazıldı")

# --- Kaynak dosya değişir: biri düzenlenmemiş, biri elle düzenlenmiş yönerge -------
cat("\n[C] Drive'daki kaynak dosya değişti\n")
txt_yaz("ELLE DÜZENLENDİ O002", "veri/yonergeler/O002.txt")
for (i in 1:2) docx_yaz(envanter$yerel_yol[i], sprintf("Ödev %d: mahallendeki parkları gözlemle ve raporla. SÜRÜM2", i))
r <- adim("02_metin_cikar.R")
k <- xlsx_oku("veri/kontrol_listesi.xlsx")
denetle(any(grepl("kaynak dosyası değişen ödev\\(ler\\): O001, O002", r$cikti)), "değişen kaynaklar bildirildi")
denetle(grepl("SÜRÜM2", txt_oku("veri/yonergeler/O001.txt")), "düzenlenmemiş yönerge yeni metinle güncellendi")
denetle(txt_oku("veri/yonergeler/O002.txt") == "ELLE DÜZENLENDİ O002" && file.exists("veri/yonergeler/O002.yeni.txt"),
        "elle düzenlenmiş yönerge korundu, yeni metin .yeni.txt'ye yazıldı")
denetle(all(is.na(k$kontrol_edildi[k$odev_id %in% c("O001", "O002")])) && all(k$kontrol_edildi[k$odev_id %in% sprintf("O%03d", 3:8)] == "evet"),
        "yalnızca değişen ödevlerin kontrol işareti sıfırlandı")

# --- Kişisel veri, gönderilecek metinde taranır --------------------------------------
cat("\n[D] Elle yazılan yönergede kişisel veri\n")
txt_yaz("Hazırlayan: Ayşe Yılmaz, ayse@ogr.edu.tr, Öğrenci No: 20231234567. Ödev: parkları gözlemle.", "veri/yonergeler/O003.txt")
invisible(adim("02_metin_cikar.R"))
k <- xlsx_oku("veri/kontrol_listesi.xlsx")
denetle(grepl("eposta", k$olasi_kisisel_veri[k$odev_id == "O003"]) && grepl("kişisel", k$dikkat[k$odev_id == "O003"]),
        "elle yazılan metindeki kişisel veri işaretlendi")
txt_yaz("Ödev 3: mahallendeki parkları gözlemle ve raporla.", "veri/yonergeler/O003.txt")

# --- Kodlamadan sonra onay kaldırma + yeni ödevler ------------------------------------
cat("\n[E] Onay kaldırma ve sonradan eklenen ödevler\n")
onayla(c("O001", "O003", sprintf("O%03d", 9:12)))   # O001 yeni metniyle, O003 düzeltilmiş metniyle, 4 yeni ödev
onayla("O005", "hayır")                              # yinelenen dosya olduğu anlaşıldı
denetle(adim("03_yz_cagri.R")$durum == 0, "03 ikinci tur")
r <- adim("04_kodlama_formu.R")
f1 <- xlsx_oku("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
denetle(r$durum == 0, "04 onay kaldırıldığında durmadı")
denetle(any(grepl("onayı kaldırılan ödev satırları formda bırakıldı.*O005", r$cikti)), "onayı kaldırılan satır bildirildi ve korundu")
denetle(any(grepl("YENİDEN KODLAYIN\\): O001, O003", r$cikti)) && all(is.na(f1$kategori[f1$odev_id %in% c("O001", "O003")])),
        "yönergesi değişen ödevlerin satırları yenilendi, kodları boşaltıldı")
denetle(all(f1$kategori[f1$odev_id %in% c("O004", "O006")] == "Tam olarak tamamlandı"), "değişmeyen ödevlerin kodları korundu")
denetle(all(sprintf("O%03d", 9:12) %in% f1$odev_id), "yeni ödevler forma eklendi")
denetle("kodlayici_notu" %in% names(f1) && "notlarim" %in% openxlsx::getSheetNames("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx"),
        "kodlayıcının eklediği sütun ve sayfa korundu")
f2 <- xlsx_oku("cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx")
cerceve <- 10   # onaylı ve 1. tekrarı geçerli: O001, O003, O004, O006-O012 (O002 bekliyor, O005 onaysız)
denetle(sum(f2$odev_id %in% setdiff(f1$odev_id, c("O002", "O005"))) == round(cerceve * 0.5),
        "ikinci kodlayıcı örneklemi hedef orana tamamlandı")

# --- Nitelikler kısmen ve koşullu boşlukla kodlanmış: analiz doğru tabanla yapılmalı --
cat("\n[F] Koşullu alt kodlar ve onay filtresi\n")
kodla("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
kodla("cikti/kodlama/kodlayici2_tamamlanabilirlik.xlsx")
wb <- openxlsx::loadWorkbook("cikti/kodlama/tasarim_nitelikleri.xlsx")
nf <- openxlsx::read.xlsx(wb, "nitelikler", skipEmptyCols = FALSE)
for (s in names(NITELIKLER)) nf[[s]] <- 0
nf$belgeleme[1:3] <- 1; nf$belgeleme_yalniz_kanit <- NA; nf$belgeleme_yalniz_kanit[1:3] <- c(1, 0, 0)
nf$girdi_islevsel <- NA                                   # ozgu_girdi hep 0: alt kod boş bırakıldı
openxlsx::writeData(wb, "nitelikler", nf)
openxlsx::saveWorkbook(wb, "cikti/kodlama/tasarim_nitelikleri.xlsx", overwrite = TRUE)
r <- adim("05_analiz.R")
tb <- openxlsx::read.xlsx("cikti/analiz/tablolar.xlsx", "tamamlanabilirlik")
denetle(r$durum == 0 && sum(tb$n) == 10, "dağılım tabanı: onaylı ve kodlu 10 ödev (O005 çıkarıldı, O002 bekliyor)")
nt <- openxlsx::read.xlsx("cikti/analiz/tablolar.xlsx", "nitelikler")
denetle(nt$n[nt$sutun == "girdi_islevsel"] == 0 && nt$n[nt$sutun == "belgeleme"] == sum(nf$belgeleme[nf$odev_id %in% setdiff(nf$odev_id, c("O002", "O005"))]),
        "boş koşullu alt kodlar 0 sayıldı; ödevler düşürülmedi")

# --- Fazla tekrarlar: tekrar_sayisi düşürüldüğünde forma girmez -----------------------
cat("\n[G] Tekrar sayısı düşürüldü\n")
dir.create("ek"); file.copy("cikti/api_kayitlari", "ek", recursive = TRUE)
kayit <- kayitlari_oku("cikti/api_kayitlari")
s <- kayit[kayit$odev_id == "O004", ][1, ]
s$tekrar <- 2; s$baslangic_utc <- "2099-01-01T00:00:00.000Z"
s$dosya_koku <- sub("_t1_", "_t2_", s$dosya_koku)
file.copy(paste0(kayit$dosya_koku[kayit$odev_id == "O004"][1], "_cikti.txt"), paste0(s$dosya_koku, "_cikti.txt"))
kayit_satiri_yaz(s, s$dosya_koku)
r <- adim("04_kodlama_formu.R")
f1 <- xlsx_oku("cikti/kodlama/kodlayici1_tamamlanabilirlik.xlsx")
denetle(any(grepl("tekrar_sayisi \\(1\\) dışındaki", r$cikti)) && !any(f1$tekrar == 2), "fazla tekrar forma alınmadı")

cat("\nProje klasörü:", proje, "\n")
cat(if (hatalar == 0) "\nTÜM DENETİMLER GEÇTİ\n" else sprintf("\n%d DENETİM KALDI\n", hatalar))
quit(status = if (hatalar == 0) 0 else 1)
