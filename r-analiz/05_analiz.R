# =============================================================================
# 05_analiz.R : Bulgu tabloları, kodlayıcılar arası uyuşma ve sunum grafikleri
# -----------------------------------------------------------------------------
# Girdiler : cikti/kodlama/ altındaki doldurulmuş Excel formları
# Çıktılar : cikti/analiz/ altında tablolar (xlsx), grafikler (png) ve
#            bildirideki biçimde Türkçe özet cümleleri (ozet.txt)
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler("openxlsx")

kodlama_dizini <- file.path(AYAR$cikti_dizini, "kodlama")
analiz_dizini <- file.path(AYAR$cikti_dizini, "analiz")
dir.create(analiz_dizini, showWarnings = FALSE, recursive = TRUE)
kat <- AYAR$kategoriler
ozet <- character(0)
# Kategoriler en düşükten en yükseğe sıralı olmalıdır: ağırlıklı kappa ve özet
# cümleleri bu sıraya dayanır. Bildirideki dört kategori ters ya da karışık
# sırayla yazılmışsa durulur.
VARSAYILAN_KATEGORILER <- c("Tamamlanamadı", "Sınırlı ölçüde tamamlandı",
                            "Büyük ölçüde tamamlandı", "Tam olarak tamamlandı")
if (setequal(kat, VARSAYILAN_KATEGORILER) && !identical(kat, VARSAYILAN_KATEGORILER)) {
  stop("00_ayarlar.R'deki kategoriler en düşükten en yükseğe sıralanmalı: ",
       paste(VARSAYILAN_KATEGORILER, collapse = " < "), call. = FALSE)
}
bildiri_kategorileri <- identical(kat, VARSAYILAN_KATEGORILER)
if (!bildiri_kategorileri) message("Not: kategoriler bildiridekinden farklı; en düşükten en yükseğe sıralı oldukları ",
                                    "varsayılıyor (kappa ağırlıkları ve 'en üst iki kategori' buna göre hesaplanır).")

# Kodlama formunu okur: "kodlama" sayfası ada göre (kodlayıcı önüne yedek sayfa
# eklemiş olabilir), boş "tekrar" hücreleri çağrı dosyası adından tamamlanır,
# yinelenen ödev x tekrar satırlarında durulur.
form_oku <- function(yol) {
  sayfa <- if ("kodlama" %in% openxlsx::getSheetNames(yol)) "kodlama" else 1
  d <- xlsx_oku(yol, sayfa)
  if (is.null(d$odev_id) || is.null(d$kategori)) stop(yol, ": 'odev_id' ve 'kategori' sütunları gerekli.", call. = FALSE)
  d <- d[!is.na(d$odev_id), ]
  if (is.null(d$tekrar)) d$tekrar <- 1   # elle hazırlanmış özgün kod dosyası için
  t <- suppressWarnings(as.integer(d$tekrar))
  bos <- is.na(t)
  if (any(bos) && !is.null(d$cagri_dosyasi)) {
    t[bos] <- suppressWarnings(as.integer(sub("^.*_t([0-9]+)_.*$", "\\1", d$cagri_dosyasi[bos])))
  } else if (any(bos) && all(t %in% c(1L, NA))) {
    message(yol, ": ", sum(bos), " satırda 'tekrar' boş; 1 kabul edildi.")
    t[bos] <- 1L
  }
  if (anyNA(t)) stop(yol, ": 'tekrar' değeri boş ya da geçersiz: ", paste(d$odev_id[is.na(t)], collapse = ", "), call. = FALSE)
  d$tekrar <- t
  yineleme <- duplicated(d[, c("odev_id", "tekrar")])
  if (any(yineleme)) {
    stop(yol, ": aynı ödev ve tekrar için birden çok satır var: ",
         paste(unique(d$odev_id[yineleme]), collapse = ", "), ". Fazla satırları silin.", call. = FALSE)
  }
  d
}

# Her satırın, ödevin ŞU ANKİ geçerli çağrısına ait olduğunu denetler: kodlayıcıdan
# dönen eski bir kopya (ödev sonradan yeniden çağrıldıysa) analize girmesin.
cagri_denetle <- function(d, etiket) {
  if (is.null(gecerli) || is.null(d$cagri_dosyasi)) return(invisible(TRUE))
  beklenen <- basename(gecerli$dosya_koku)[match(paste(d$odev_id, d$tekrar), paste(gecerli$odev_id, gecerli$tekrar))]
  uyumsuz <- unique(d$odev_id[is.na(beklenen) | d$cagri_dosyasi != beklenen])
  if (length(uyumsuz) > 0) {
    stop(etiket, " formundaki şu ödevlerin satırları güncel API çağrısına ait değil (eski bir form kopyası ",
         "olabilir; ödev sonradan yeniden çağrılmış): ", paste(uyumsuz, collapse = ", "),
         ". cikti/kodlama altındaki güncel formu kullanın ya da 04'ü çalıştırıp bu satırları yeniden kodlayın.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# Kodlanan çıktıların şu anki ayarlarla üretildiğini denetler (yalnızca 04'ün ürettiği formlar).
ayar_denetle <- function(d, etiket) {
  if (is.null(d$ayar_sha256)) return(invisible(TRUE))
  gerekli_paketler(c("jsonlite", "digest"))
  eski_ayar <- unique(d$odev_id[!d$ayar_sha256 %in% ayar_ozeti(AYAR)])
  if (length(eski_ayar) > 0) {
    stop(etiket, " formundaki şu ödevlerin çıktıları şu anki 00_ayarlar.R ayarlarıyla üretilmemiş ",
         "(model, istem ya da parametre değişmiş): ", paste(eski_ayar, collapse = ", "),
         ". Ayarları kodlanan çalıştırmadakine döndürün ya da 04'ü yeniden çalıştırıp yeni çıktıları kodlayın.",
         call. = FALSE)
  }
  invisible(TRUE)
}

# 1. Tamamlanabilirlik dağılımı ------------------------------------------------------
k1_tum <- form_oku(file.path(kodlama_dizini, "kodlayici1_tamamlanabilirlik.xlsx"))
# Onay filtresi: formlar bu iş akışıyla (04) üretildiyse, kontrol listesinde
# onayı kaldırılan ödevler ÜÇ analizden de (dağılım, kappa, nitelikler) aynı
# biçimde çıkarılır. Elle hazırlanmış özgün kod dosyalarına uygulanmaz.
# Ayar denetimi filtreden SONRA yapılır: 04 onaysız satırları güncellemez.
onayli <- NULL
gecerli <- NULL
kontrol_yolu <- file.path(AYAR$veri_dizini, "kontrol_listesi.xlsx")
if (!is.null(k1_tum$cagri_dosyasi) && file.exists(kontrol_yolu)) {
  guncel_yonergeler <- onayli_yonergeler(AYAR)   # 04 ile aynı çerçeve: onaylı ve yönergesi boş olmayan
  onayli <- names(guncel_yonergeler)
  kayit <- kayitlari_oku(file.path(AYAR$cikti_dizini, "api_kayitlari"))
  if (!is.null(kayit)) {
    gerekli_paketler(c("jsonlite", "digest"))
    gecerli <- gecerli_cagrilar(kayit, AYAR, guncel_yonergeler)
  }
  cikan <- setdiff(unique(k1_tum$odev_id), onayli)
  if (length(cikan) > 0) message("Onayı kaldırıldığı için analiz dışı bırakılan ödev(ler): ", paste(cikan, collapse = ", "))
  k1_tum <- k1_tum[k1_tum$odev_id %in% onayli, ]
  if (nrow(k1_tum) == 0) stop("Kodlama formundaki ödevlerin hiçbiri kontrol listesinde onaylı değil.", call. = FALSE)
}
ayar_denetle(k1_tum, "Birinci kodlayıcı")
cagri_denetle(k1_tum, "Birinci kodlayıcı")
k1 <- k1_tum[k1_tum$tekrar %in% 1, ]   # bildirideki analiz: ödev başına bir çağrı
if (all(is.na(k1$kategori))) stop("Birinci kodlayıcı formunda kodlanmış ödev yok.", call. = FALSE)
dagilim <- kategori_tablosu(k1$kategori, kat)
print(dagilim)
N <- sum(dagilim$n)
ust_iki <- utils::tail(kat, 2)          # "büyük ölçüde veya tam olarak"
yuksek_n <- sum(dagilim$n[dagilim$kategori %in% ust_iki])
if (bildiri_kategorileri) {
  ozet <- c(ozet, paste0(
    "Ödevlerin ÜYZ ile tamamlanabilirlik sınamasında, ", N, " ödevin ",
    sayi_eki(dagilim$n[4]), " (%", yuzde_tr(dagilim$yuzde[4]), ") kullanılan ÜYZ modeli tarafından tam olarak, ",
    sayi_eki(dagilim$n[3]), " (%", yuzde_tr(dagilim$yuzde[3]), ") büyük ölçüde ve ",
    sayi_eki(dagilim$n[2]), " (%", yuzde_tr(dagilim$yuzde[2]), ") sınırlı ölçüde tamamlanmış; ",
    sayi_eki(dagilim$n[1]), " (%", yuzde_tr(dagilim$yuzde[1]), ") ise tamamlanamamıştır. ",
    "Buna göre ödevlerin ", sayi_eki(yuksek_n), " (%", yuzde_tr(100 * yuksek_n / N),
    "), kullanılan model tarafından büyük ölçüde veya tam olarak tamamlanabilmiştir."
  ))
} else {
  ters <- rev(seq_len(nrow(dagilim)))
  ozet <- c(ozet, paste0(
    N, " ödevin dağılımı: ",
    paste0(dagilim$kategori[ters], " ", dagilim$n[ters], " (%", yuzde_tr(dagilim$yuzde[ters]), ")", collapse = "; "),
    ". En üst iki kategoride: ", yuksek_n, " (%", yuzde_tr(100 * yuksek_n / N), ")."
  ))
}

# Birden çok tekrar varsa: aynı ödevin tekrarları arasında kategori tutarlılığı
# Yalnızca TÜM tekrarları kodlanmış ödevler sayılır; tek tekrarı olan ödev "tutarlı" sayılmaz.
R_tekrar <- max(k1_tum$tekrar, na.rm = TRUE)
if (R_tekrar > 1) {
  kodlu <- k1_tum[!is.na(k1_tum$kategori), ]
  tam <- names(which(tapply(kodlu$tekrar, kodlu$odev_id, function(t) all(seq_len(R_tekrar) %in% t))))
  tutarlilik <- tapply(kodlu$kategori[kodlu$odev_id %in% tam], kodlu$odev_id[kodlu$odev_id %in% tam],
                       function(x) length(unique(x)) == 1)
  dislanan <- length(unique(k1_tum$odev_id)) - length(tam)
  ozet <- c(ozet, sprintf(paste0("Tüm %d tekrarı kodlanmış %d ödevde, tekrarlar arasında aynı kategoriye giren ",
                                 "ödev oranı %%%s (%d/%d); eksik tekrarı olan %d ödev bu orana alınmadı."),
                          R_tekrar, length(tam), yuzde_tr(100 * mean(tutarlilik)), sum(tutarlilik),
                          length(tutarlilik), dislanan))
}

# 2. Kodlayıcılar arası uyuşma ----------------------------------------------------------
k2_yolu <- file.path(kodlama_dizini, "kodlayici2_tamamlanabilirlik.xlsx")
uyusma <- NULL
if (file.exists(k2_yolu)) {
  k2 <- form_oku(k2_yolu)
  if (!is.null(onayli)) k2 <- k2[k2$odev_id %in% onayli, ]
  k2 <- k2[k2$tekrar %in% 1, ]
  ayar_denetle(k2, "İkinci kodlayıcı")
  cagri_denetle(k2, "İkinci kodlayıcı")
  ortak_sutun <- if (!is.null(k1$cagri_dosyasi) && !is.null(k2$cagri_dosyasi)) c("odev_id", "kategori", "cagri_dosyasi") else c("odev_id", "kategori")
  ortak <- merge(k1[, ortak_sutun], k2[, ortak_sutun], by = "odev_id", suffixes = c("_1", "_2"))
  # İki kodlayıcı aynı çağrının çıktısını kodlamış olmalı
  if ("cagri_dosyasi_1" %in% names(ortak)) {
    farkli <- ortak$odev_id[ortak$cagri_dosyasi_1 != ortak$cagri_dosyasi_2]
    if (length(farkli) > 0) {
      stop("İki kodlayıcı şu ödevlerde farklı çağrıların çıktısını kodlamış: ", paste(farkli, collapse = ", "),
           ". İkinci kodlayıcıya güncel formu gönderip bu satırları yeniden kodlatın.", call. = FALSE)
    }
  }
  if (sum(stats::complete.cases(ortak)) >= 2) {
    uyusma <- kappa_hesapla(ortak$kategori_1, ortak$kategori_2, kat)
    print(uyusma$tablo)
    print(uyusma$capraz_tablo)
    # Biçimlendirme yuvarlanmamış değerlerden yapılır (iki kez yuvarlama .xx45 değerlerini kaydırır).
    kq <- uyusma$tablo_ham[uyusma$tablo_ham$agirlik == "karesel", ]
    kd <- uyusma$tablo_ham[uyusma$tablo_ham$agirlik == "dogrusal", ]
    ozet <- c(ozet, sprintf(
      "Rastgele seçilen %d ödev ikinci bir kodlayıcı tarafından bağımsız olarak sınıflandırılmış; ağırlıklı Cohen kappa (karesel ağırlık) %s [%%95 GA: %s, %s], (doğrusal ağırlık) %s [%s, %s]; yüzde uyum %%%s.",
      uyusma$n, katsayi_bicim(kq$kappa), katsayi_bicim(kq$ga_alt), katsayi_bicim(kq$ga_ust),
      katsayi_bicim(kd$kappa), katsayi_bicim(kd$ga_alt), katsayi_bicim(kd$ga_ust),
      yuzde_tr(uyusma$yuzde_uyum)))
  }
}

# 3. Tasarım nitelikleri ---------------------------------------------------------------
nitelik_yolu <- file.path(kodlama_dizini, "tasarim_nitelikleri.xlsx")
nitelikler <- NULL
if (file.exists(nitelik_yolu)) {
  nf <- xlsx_oku(nitelik_yolu, "nitelikler")
  if (is.null(nf$odev_id)) stop(nitelik_yolu, ": 'nitelikler' sayfasında 'odev_id' sütunu yok.", call. = FALSE)
  nf <- nf[!is.na(nf$odev_id), ]
  if (anyDuplicated(nf$odev_id)) {
    stop(nitelik_yolu, ": aynı ödev için birden çok satır var: ",
         paste(unique(nf$odev_id[duplicated(nf$odev_id)]), collapse = ", "), ". Fazla satırları silin.", call. = FALSE)
  }
  # Yönergesi değiştiği hâlde işaretsiz satır: kodlayıcıdan dönen eski bir kopya olabilir.
  if (!is.null(nf$yonerge_sha256) && exists("guncel_yonergeler")) {
    guncel_ozet <- vapply(guncel_yonergeler, sha256, "")[nf$odev_id]
    eski_kopya <- nf$odev_id[!is.na(guncel_ozet) & !is.na(nf$yonerge_sha256) &
                               nf$yonerge_sha256 != guncel_ozet & is.na(nf$yonerge_degisti %||% NA)]
    if (length(eski_kopya) > 0) {
      stop(nitelik_yolu, ": şu ödevlerin yönergesi değişmiş ama satırları güncellenmemiş (eski bir kopya olabilir): ",
           paste(eski_kopya, collapse = ", "), ". 04'ü çalıştırın; satırlar işaretlenince kodları gözden geçirin.",
           call. = FALSE)
    }
  }
  if (!is.null(nf$yonerge_degisti) && any(!is.na(nf$yonerge_degisti))) {
    message("UYARI: yönergesi değiştiği hâlde nitelik kodları gözden geçirilmemiş ödev(ler): ",
            paste(nf$odev_id[!is.na(nf$yonerge_degisti)], collapse = ", "),
            " ('yonerge_degisti' hücresini gözden geçirdikten sonra silin).")
  }
  kk <- xlsx_oku(nitelik_yolu, "kod_kitabi")
  sutunlar <- intersect(kk$sutun, names(nf))
  kayip <- setdiff(kk$sutun, names(nf))
  if (length(kayip) > 0) {
    message("UYARI: kod kitabındaki şu nitelik sütunları 'nitelikler' sayfasında bulunamadı ve analize ",
            "alınmadı (başlık yazımını denetleyin): ", paste(kayip, collapse = ", "))
  }
  if (!is.null(onayli)) {
    cikan <- setdiff(nf$odev_id, onayli)
    if (length(cikan) > 0) message("Onaylı olmadığı için nitelik analizine alınmayan ödev(ler): ", paste(cikan, collapse = ", "))
    nf <- nf[nf$odev_id %in% onayli, ]
  }
  # Koşullu alt kodlar (üst kod 0 ise boş = 0) tamamlanır. Tutarsız ya da eksik
  # kod varsa nitelik çıktıları üretilmez (ödevler sessizce düşürülmez); bu
  # durumda tamamlanabilirlik çıktıları yine de yazılır.
  hic_kodlanmamis <- nrow(nf) > 0 && all(is.na(as.matrix(nf[, sutunlar, drop = FALSE])))
  if (hic_kodlanmamis) {
    message("Tasarım nitelikleri henüz kodlanmamış; nitelik çıktıları atlandı.")
    nf <- nf[0, ]
  } else {
    nf <- tryCatch(nitelikleri_denetle(nf, sutunlar), error = function(e) {
      message("UYARI: tasarım nitelikleri çıktıları üretilmedi: ", conditionMessage(e))
      nf[0, ]
    })
  }
  if (nrow(nf) > 0) {
    nitelikler <- nitelik_tablosu(nf, sutunlar, kk$nitelik[match(sutunlar, kk$sutun)])
    print(nitelikler)
    disarida <- setdiff(nf$odev_id, k1$odev_id[!is.na(k1$kategori)])
    if (length(disarida) > 0) {
      ozet <- c(ozet, sprintf(paste0("Tasarım nitelikleri %d ödevde kodlanmıştır; bunların %s ",
                                     "tamamlanabilirlik analizine girmemiştir (API reddi, kesik yanıt ya da kodlanmamış): %s."),
                              nrow(nf), sayi_eki(length(disarida)), paste(disarida, collapse = ", ")))
    }

    # Koşullu oranlar: bildirideki "83 ödevin 49'unda" türü ifadeler
    if (all(c("ozgu_girdi", "girdi_islevsel") %in% sutunlar)) {
      a <- sum(nf$ozgu_girdi == 1); b <- sum(nf$ozgu_girdi == 1 & nf$girdi_islevsel == 1)
      if (a > 0) ozet <- c(ozet, sprintf(
        "Öğrenciye özgü, kişisel veya yerel girdi isteyen %d ödevin yalnızca %s, yani bu ödevlerin %%%s ve tüm ödevlerin %%%s, söz konusu girdinin izleyen analiz veya yorumlama işlemlerinde kullanılması zorunlu tutulmuştur.",
        a, sayi_eki(b, "iyelik_bulunma"), sayi_eki(yuzde_tr(100 * b / a), "iyelik_bulunma"),
        sayi_eki(yuzde_tr(100 * b / nrow(nf)), "iyelik_bulunma")))
    }
    if (all(c("belgeleme", "belgeleme_yalniz_kanit") %in% sutunlar)) {
      a <- sum(nf$belgeleme == 1); b <- sum(nf$belgeleme == 1 & nf$belgeleme_yalniz_kanit == 1)
      if (a > 0) ozet <- c(ozet, sprintf("Belgeleme şartı içeren %d ödevin %s (%%%s) sunulan kanıtlar yalnızca görevin gerçekleştirildiğini belgelemektedir.",
                              a, sayi_eki(b, "iyelik_bulunma"), yuzde_tr(100 * b / a)))
    }

    # Keşfedici çapraz tablo: nitelik var/yok x "büyük ölçüde veya tam tamamlandı"
    # Betimseldir; nitelikler birbirleriyle ilişkili olduğundan nedensel yorum yapılamaz.
    # Kodlanmamış (NA) tamamlanabilirlik dışarıda bırakılır; taban ana tabloyla aynıdır.
    ortak_n <- merge(nf, k1[!is.na(k1$kategori), c("odev_id", "kategori")], by = "odev_id")
    ortak_n$yuksek <- ortak_n$kategori %in% ust_iki
    capraz <- do.call(rbind, lapply(sutunlar, function(s) {
      var_ <- ortak_n[[s]] == 1
      data.frame(nitelik = kk$nitelik[kk$sutun == s],
                 n_var = sum(var_), yuksek_tamamlanma_var = yuvarla(100 * mean(ortak_n$yuksek[var_]), 1),
                 n_yok = sum(!var_), yuksek_tamamlanma_yok = yuvarla(100 * mean(ortak_n$yuksek[!var_]), 1))
    }))
    capraz$n_toplam <- nrow(ortak_n)
  }
}

# 4. Kaydet: tablolar ve grafikler ---------------------------------------------------
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "tamamlanabilirlik"); openxlsx::writeData(wb, "tamamlanabilirlik", dagilim)
if (!is.null(uyusma)) {
  openxlsx::addWorksheet(wb, "kappa"); openxlsx::writeData(wb, "kappa", uyusma$tablo)
  openxlsx::addWorksheet(wb, "capraz_tablo")
  openxlsx::writeData(wb, "capraz_tablo", as.data.frame.matrix(uyusma$capraz_tablo), rowNames = TRUE)
}
if (!is.null(nitelikler)) {
  openxlsx::addWorksheet(wb, "nitelikler"); openxlsx::writeData(wb, "nitelikler", nitelikler)
  openxlsx::addWorksheet(wb, "nitelik_x_tamamlanma"); openxlsx::writeData(wb, "nitelik_x_tamamlanma", capraz)
}
xlsx_kaydet(wb, file.path(analiz_dizini, "tablolar.xlsx"))

cubuk_grafik(dagilim, "kategori",
             sprintf("Ödevlerin ÜYZ ile tamamlanabilirliği (n = %d)", N),
             file.path(analiz_dizini, "sekil1_tamamlanabilirlik.png"))
if (!is.null(nitelikler)) {
  cubuk_grafik(nitelikler[!nitelikler$sutun %in% YARDIMCI_KODLAR, ], "nitelik",
               sprintf("Ödevlerde görülen tasarım nitelikleri (n = %d)", nrow(nf)),
               file.path(analiz_dizini, "sekil2_tasarim_nitelikleri.png"),
               sirala = TRUE, genislik = 11, yukseklik = 5.5)
}

txt_yaz(paste(ozet, collapse = "\n\n"), file.path(analiz_dizini, "ozet.txt"))
cat("\n", paste(ozet, collapse = "\n\n"), "\n")
message("Çıktılar: ", analiz_dizini)
