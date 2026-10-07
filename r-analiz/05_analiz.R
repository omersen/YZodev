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

# 1. Tamamlanabilirlik dağılımı ------------------------------------------------------
k1_tum <- xlsx_oku(file.path(kodlama_dizini, "kodlayici1_tamamlanabilirlik.xlsx"))
if (is.null(k1_tum$tekrar)) k1_tum$tekrar <- 1   # elle hazırlanmış özgün kod dosyası için
k1 <- k1_tum[k1_tum$tekrar %in% 1, ]   # bildirideki analiz: ödev başına bir çağrı
dagilim <- kategori_tablosu(k1$kategori, kat)
print(dagilim)
N <- sum(dagilim$n)
yuksek_n <- dagilim$n[3] + dagilim$n[4]
ozet <- c(ozet, paste0(
  "Ödevlerin ÜYZ ile tamamlanabilirlik sınamasında, ", N, " ödevin ",
  sayi_eki(dagilim$n[4]), " (%", yuzde_tr(dagilim$yuzde[4]), ") kullanılan ÜYZ modeli tarafından tam olarak, ",
  sayi_eki(dagilim$n[3]), " (%", yuzde_tr(dagilim$yuzde[3]), ") büyük ölçüde ve ",
  sayi_eki(dagilim$n[2]), " (%", yuzde_tr(dagilim$yuzde[2]), ") sınırlı ölçüde tamamlanmış; ",
  sayi_eki(dagilim$n[1]), " (%", yuzde_tr(dagilim$yuzde[1]), ") ise tamamlanamamıştır. ",
  "Buna göre ödevlerin ", sayi_eki(yuksek_n), " (%", yuzde_tr(100 * yuksek_n / N),
  "), kullanılan model tarafından büyük ölçüde veya tam olarak tamamlanabilmiştir."
))

# Birden çok tekrar varsa: aynı ödevin tekrarları arasında kategori tutarlılığı
if (length(unique(k1_tum$tekrar)) > 1) {
  tutarlilik <- tapply(k1_tum$kategori, k1_tum$odev_id, function(x) length(unique(stats::na.omit(x))) == 1)
  ozet <- c(ozet, sprintf("Tekrarlar arasında aynı kategoriye giren ödev oranı: %%%s (%d/%d).",
                          yuzde_tr(100 * mean(tutarlilik)), sum(tutarlilik), length(tutarlilik)))
}

# 2. Kodlayıcılar arası uyuşma ----------------------------------------------------------
k2_yolu <- file.path(kodlama_dizini, "kodlayici2_tamamlanabilirlik.xlsx")
uyusma <- NULL
if (file.exists(k2_yolu)) {
  k2 <- xlsx_oku(k2_yolu)
  ortak <- merge(k1[, c("odev_id", "kategori")], k2[, c("odev_id", "kategori")],
                 by = "odev_id", suffixes = c("_1", "_2"))
  if (sum(stats::complete.cases(ortak)) >= 2) {
    uyusma <- kappa_hesapla(ortak$kategori_1, ortak$kategori_2, kat)
    print(uyusma$tablo)
    print(uyusma$capraz_tablo)
    kq <- uyusma$tablo[uyusma$tablo$agirlik == "karesel", ]
    kd <- uyusma$tablo[uyusma$tablo$agirlik == "dogrusal", ]
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
  kk <- xlsx_oku(nitelik_yolu, "kod_kitabi")
  sutunlar <- intersect(kk$sutun, names(nf))
  kodlu <- stats::complete.cases(nf[, sutunlar])
  if (any(!kodlu)) message(sum(!kodlu), " ödevde tasarım nitelikleri eksik kodlanmış; analiz dışı bırakıldı.")
  nf <- nf[kodlu, ]
  if (nrow(nf) > 0) {
    nitelikler <- nitelik_tablosu(nf, sutunlar, kk$nitelik[match(sutunlar, kk$sutun)])
    print(nitelikler)

    # Koşullu oranlar: bildirideki "83 ödevin 49'unda" türü ifadeler
    if (all(c("ozgu_girdi", "girdi_islevsel") %in% sutunlar)) {
      a <- sum(nf$ozgu_girdi == 1); b <- sum(nf$ozgu_girdi == 1 & nf$girdi_islevsel == 1)
      ozet <- c(ozet, sprintf(
        "Öğrenciye özgü, kişisel veya yerel girdi isteyen %d ödevin yalnızca %s, yani bu ödevlerin %%%s ve tüm ödevlerin %%%s, söz konusu girdinin izleyen analiz veya yorumlama işlemlerinde kullanılması zorunlu tutulmuştur.",
        a, sayi_eki(b, "iyelik_bulunma"), sayi_eki(yuzde_tr(100 * b / a), "iyelik_bulunma"),
        sayi_eki(yuzde_tr(100 * b / nrow(nf)), "iyelik_bulunma")))
      if (any(nf$girdi_islevsel == 1 & nf$ozgu_girdi == 0)) {
        message("TUTARSIZLIK: girdi_islevsel = 1 olup ozgu_girdi = 0 olan ödev(ler) var: ",
                paste(nf$odev_id[nf$girdi_islevsel == 1 & nf$ozgu_girdi == 0], collapse = ", "))
      }
    }
    if (all(c("belgeleme", "belgeleme_yalniz_kanit") %in% sutunlar)) {
      a <- sum(nf$belgeleme == 1); b <- sum(nf$belgeleme == 1 & nf$belgeleme_yalniz_kanit == 1)
      ozet <- c(ozet, sprintf("Belgeleme şartı içeren %d ödevin %s (%%%s) sunulan kanıtlar yalnızca görevin gerçekleştirildiğini belgelemektedir.",
                              a, sayi_eki(b, "iyelik_bulunma"), yuzde_tr(100 * b / a)))
    }

    # Keşfedici çapraz tablo: nitelik var/yok x "büyük ölçüde veya tam tamamlandı"
    # Betimseldir; nitelikler birbirleriyle ilişkili olduğundan nedensel yorum yapılamaz.
    ortak_n <- merge(nf, k1[, c("odev_id", "kategori")], by = "odev_id")
    ortak_n$yuksek <- ortak_n$kategori %in% kat[3:4]
    capraz <- do.call(rbind, lapply(sutunlar, function(s) {
      var_ <- ortak_n[[s]] == 1
      data.frame(nitelik = kk$nitelik[kk$sutun == s],
                 n_var = sum(var_), yuksek_tamamlanma_var = round(100 * mean(ortak_n$yuksek[var_]), 1),
                 n_yok = sum(!var_), yuksek_tamamlanma_yok = round(100 * mean(ortak_n$yuksek[!var_]), 1))
    }))
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
  cubuk_grafik(nitelikler[!grepl("yalnızca", nitelikler$nitelik), ], "nitelik",
               sprintf("Ödevlerde görülen tasarım nitelikleri (n = %d)", nrow(nf)),
               file.path(analiz_dizini, "sekil2_tasarim_nitelikleri.png"),
               sirala = TRUE, genislik = 11, yukseklik = 5.5)
}

txt_yaz(paste(ozet, collapse = "\n\n"), file.path(analiz_dizini, "ozet.txt"))
cat("\n", paste(ozet, collapse = "\n\n"), "\n")
message("Çıktılar: ", analiz_dizini)
