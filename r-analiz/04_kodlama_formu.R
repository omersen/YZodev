# =============================================================================
# 04_kodlama_formu.R : Kodlayıcılar için Excel kodlama formlarını hazırlar
# -----------------------------------------------------------------------------
# Çıktılar (cikti/kodlama/ altında):
#   kodlayici1_tamamlanabilirlik.xlsx : yönerge + YZ çıktısı yan yana, açılır
#                                       listeden kategori seçimi
#   kodlayici2_tamamlanabilirlik.xlsx : tohumla seçilmiş rastgele alt örneklem
#                                       (varsayılan %25); birinci kodlayıcının
#                                       kodları YOK (körleme)
#   tasarim_nitelikleri.xlsx          : yönergelerdeki tasarım niteliklerinin
#                                       0/1 kodlanması için şablon
# Yeniden çalıştırma:
#   - Kodlanmış formların üzerine yazılmaz.
#   - Formdaki bir çıktı artık geçerli değilse (ayar ya da yönerge değiştiği için
#     ödev yeniden çağrıldıysa) betik durur ve ne yapılacağını söyler.
#   - Sonradan eklenen ödevler birinci kodlayıcı formuna ve nitelik şablonuna
#     eklenir; ikinci kodlayıcının alt örneklemi değişmez.
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("openxlsx", "jsonlite", "digest"))

kodlama_dizini <- file.path(AYAR$cikti_dizini, "kodlama")
dir.create(kodlama_dizini, showWarnings = FALSE, recursive = TRUE)
yonerge_dosyasi <- function(id) file.path(AYAR$veri_dizini, "yonergeler", paste0(id, ".txt"))

# Onaylı ve boş olmayan yönergeler: tasarım nitelikleri analizinin çerçevesi ----
# (API sonucundan bağımsızdır; API'nin reddettiği ödevler de burada yer alır.)
kontrol <- xlsx_oku(file.path(AYAR$veri_dizini, "kontrol_listesi.xlsx"))
onayli <- kontrol$odev_id[tolower(trimws(kontrol$kontrol_edildi %||% "")) %in% "evet"]
yonergeler <- vapply(onayli, function(id) {
  if (file.exists(yonerge_dosyasi(id))) txt_oku(yonerge_dosyasi(id)) else ""
}, "")
yonergeler <- yonergeler[nzchar(trimws(yonergeler))]
if (length(yonergeler) == 0) stop("Onaylı ve boş olmayan yönerge yok.")

# Geçerli API çağrıları: tamamlanabilirlik kodlamasının çerçevesi ------------
kayit <- kayitlari_oku(file.path(AYAR$cikti_dizini, "api_kayitlari"))
if (is.null(kayit)) stop("API çağrı kaydı bulunamadı; önce 03_yz_cagri.R'ı çalıştırın.")
son <- gecerli_cagrilar(kayit, AYAR, yonergeler)
if (nrow(son) == 0) stop("Şu anki ayarlarla tamamlanmış API çağrısı yok.")

eksik <- setdiff(names(yonergeler), son$odev_id[son$tekrar == 1])
if (length(eksik) > 0) {
  sonuncu <- kayit[kayit$odev_id %in% eksik & kayit$ayar_sha256 %in% ayar_ozeti(AYAR), ]
  sonuncu <- sonuncu[!duplicated(sonuncu$odev_id, fromLast = TRUE), ]
  neden <- sonuncu$durum[match(eksik, sonuncu$odev_id)]
  message(length(eksik), " ödevin şu anki ayarlarla tamamlanmış 1. tekrar çağrısı yok; ",
          "tamamlanabilirlik formuna alınmadı (tasarım nitelikleri şablonunda yer alır): ",
          paste0(eksik, " (", ifelse(is.na(neden), "çağrılmamış", neden), ")", collapse = ", "))
}

# Excel hücresi en çok 32.767 karakter alır; daha uzun metinler kısaltılır ve
# tam metnin bulunduğu dosya belirtilir.
EXCEL_SINIR <- 32000
hucreye_sigdir <- function(x, dosya) {
  if (nchar(x) <= EXCEL_SINIR) return(x)
  paste0(substr(x, 1, EXCEL_SINIR), "\n[... METİN KISALTILDI. Tamamı: ", dosya, "]")
}

form <- data.frame(
  odev_id = son$odev_id,
  tekrar = son$tekrar,
  yonerge = vapply(son$odev_id, function(id) hucreye_sigdir(yonergeler[[id]], yonerge_dosyasi(id)), "",
                   USE.NAMES = FALSE),
  # Çıktı, seçilen çağrının kendi dosyasından okunur.
  yz_ciktisi = vapply(paste0(son$dosya_koku, "_cikti.txt"),
                      function(f) hucreye_sigdir(txt_oku(f), f), "", USE.NAMES = FALSE),
  model_reddi = ifelse(is.na(son$ret), "", son$ret),
  kategori = NA_character_,
  gerekce = NA_character_,
  # Denetim için: çıktının hangi çağrıdan ve hangi ayarlarla geldiği (düzenlemeyin)
  cagri_dosyasi = basename(son$dosya_koku),
  ayar_sha256 = son$ayar_sha256,
  stringsAsFactors = FALSE
)
# Birden çok tekrar varsa satırlar rastgele sıralanır: aynı yönergenin
# tekrarları art arda gelirse kodlayıcı bir önceki kodundan etkilenebilir.
if (length(unique(form$tekrar)) > 1) {
  set.seed(AYAR$ikinci_kodlayici_tohumu + 1)
  form <- form[sample(nrow(form)), ]
} else {
  form <- form[order(form$odev_id), ]
}

form_kitabi <- function(d) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "kodlama")
  openxlsx::writeData(wb, "kodlama", d)
  k <- which(names(d) == "kategori")
  openxlsx::dataValidation(wb, "kodlama", cols = k, rows = 2:(nrow(d) + 1), type = "list",
                           value = paste0('"', paste(AYAR$kategoriler, collapse = ","), '"'))
  openxlsx::addStyle(wb, "kodlama", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                     rows = 1:(nrow(d) + 1), cols = 1:7, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "kodlama", cols = seq_along(d),
                         widths = c(9, 7, 60, 80, 20, 26, 40, 30, 12)[seq_along(d)])
  openxlsx::freezePane(wb, "kodlama", firstRow = TRUE)
  openxlsx::addWorksheet(wb, "kategori_tanimlari")
  openxlsx::writeData(wb, "kategori_tanimlari", data.frame(
    sira = seq_along(AYAR$kategoriler), kategori = AYAR$kategoriler,
    tanim = "Kod kitabındaki tanımı buraya yazın"
  ))
  wb
}

# Var olan formu denetler: geçersizleşmiş satır varsa durur; ekle = TRUE ise yeni
# satırları (kodları koruyarak) ekler.
form_yaz <- function(d, yol, gecerli, ekle) {
  if (!file.exists(yol)) {
    xlsx_kaydet(form_kitabi(d), yol)
    message("Yazıldı: ", yol, " (", nrow(d), " satır)")
    return(invisible(d))
  }
  mevcut <- xlsx_oku(yol, "kodlama")
  anahtar <- function(x) paste(x$odev_id, x$tekrar, x$cagri_dosyasi)
  eskimis <- if (is.null(mevcut$cagri_dosyasi)) seq_len(nrow(mevcut)) else which(!anahtar(mevcut) %in% anahtar(gecerli))
  if (length(eskimis) > 0) {
    stop(yol, " içindeki ", length(eskimis), " satır şu anki ayarlarla yapılmış çağrılara ait değil ",
         "(ayar ya da yönerge değişti ve ödevler yeniden çağrıldı): ",
         paste(utils::head(mevcut$odev_id[eskimis], 15), collapse = ", "),
         if (length(eskimis) > 15) " ...",
         ".\nBu formdaki kodlar eski çıktılara aittir. Dosyayı yeniden adlandırın (ör. sonuna _eski ekleyin) ",
         "ve 04'ü yeniden çalıştırın; yeni çıktılar yeniden kodlanmalıdır.", call. = FALSE)
  }
  yeni <- d[!paste(d$odev_id, d$tekrar) %in% paste(mevcut$odev_id, mevcut$tekrar), ]
  if (ekle && nrow(yeni) > 0) {
    birlesik <- rbind_doldur(list(mevcut, yeni))[, names(d)]
    xlsx_kaydet(form_kitabi(birlesik), yol)
    message(yol, ": var olan kodlar korunarak ", nrow(yeni), " yeni satır eklendi.")
    return(invisible(birlesik))
  }
  message("Var olan form korunuyor: ", yol, " (", nrow(mevcut), " satır)")
  invisible(mevcut)
}

form1 <- form_yaz(form, file.path(kodlama_dizini, "kodlayici1_tamamlanabilirlik.xlsx"),
                  gecerli = form, ekle = TRUE)

# İkinci kodlayıcı: 1. tekrarı olan ödevlerden tohumla rastgele alt örneklem ----
# (05_analiz.R tamamlanabilirlik dağılımını da 1. tekrardan hesaplar.)
yol2 <- file.path(kodlama_dizini, "kodlayici2_tamamlanabilirlik.xlsx")
cerceve <- sort(unique(form$odev_id[form$tekrar == 1]))
if (file.exists(yol2)) {
  form_yaz(form[0, ], yol2, gecerli = form, ekle = FALSE)
} else {
  n2 <- round(length(cerceve) * AYAR$ikinci_kodlayici_orani)
  set.seed(AYAR$ikinci_kodlayici_tohumu)
  secilen <- sort(sample(cerceve, n2))
  form2 <- form[form$odev_id %in% secilen & form$tekrar == 1, ]
  form2 <- form2[order(form2$odev_id), ]
  if (nrow(form2) != n2) stop("İkinci kodlayıcı formunda beklenen ", n2, " yerine ", nrow(form2), " satır var.")
  form_yaz(form2, yol2, gecerli = form, ekle = FALSE)
  message("İkinci kodlayıcı için ", nrow(form2), " ödev seçildi (", length(cerceve),
          " ödevden, tohum = ", AYAR$ikinci_kodlayici_tohumu, ").")
}

# Tasarım nitelikleri şablonu: TÜM onaylı yönergeler ----------------------------
nitelik_yolu <- file.path(kodlama_dizini, "tasarim_nitelikleri.xlsx")
nitelik_formu <- data.frame(
  odev_id = names(yonergeler),
  yonerge = vapply(names(yonergeler), function(id) hucreye_sigdir(yonergeler[[id]], yonerge_dosyasi(id)), "",
                   USE.NAMES = FALSE),
  stringsAsFactors = FALSE
)
for (s in names(NITELIKLER)) nitelik_formu[[s]] <- NA_integer_

nitelik_kitabi <- function(d) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "nitelikler")
  openxlsx::writeData(wb, "nitelikler", d)
  openxlsx::dataValidation(wb, "nitelikler", cols = 3:ncol(d), rows = 2:(nrow(d) + 1),
                           type = "whole", operator = "between", value = c(0, 1))
  openxlsx::addStyle(wb, "nitelikler", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                     rows = 1:(nrow(d) + 1), cols = 2, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "nitelikler", cols = 1:2, widths = c(9, 80))
  openxlsx::freezePane(wb, "nitelikler", firstRow = TRUE, firstCol = TRUE)
  openxlsx::addWorksheet(wb, "kod_kitabi")
  openxlsx::writeData(wb, "kod_kitabi", data.frame(
    sutun = names(NITELIKLER), nitelik = unname(NITELIKLER), kural = nitelik_kurali(names(NITELIKLER))))
  openxlsx::setColWidths(wb, "kod_kitabi", cols = 1:3, widths = c(24, 55, 80))
  wb
}

if (!file.exists(nitelik_yolu)) {
  xlsx_kaydet(nitelik_kitabi(nitelik_formu), nitelik_yolu)
  message("Yazıldı: ", nitelik_yolu, " (", nrow(nitelik_formu), " ödev)")
} else {
  mevcut <- xlsx_oku(nitelik_yolu, "nitelikler")
  yeni <- nitelik_formu[!nitelik_formu$odev_id %in% mevcut$odev_id, ]
  fazla <- setdiff(mevcut$odev_id, nitelik_formu$odev_id)
  if (length(fazla) > 0) {
    message("Nitelik şablonunda artık onaylı olmayan ödev(ler) var (silinmedi; 05 bunları dışarıda bırakır): ",
            paste(fazla, collapse = ", "))
  }
  if (nrow(yeni) > 0) {
    birlesik <- rbind_doldur(list(mevcut, yeni))
    xlsx_kaydet(nitelik_kitabi(birlesik[, c("odev_id", "yonerge", intersect(names(NITELIKLER), names(birlesik)))]),
                nitelik_yolu)
    message(nitelik_yolu, ": var olan kodlar korunarak ", nrow(yeni), " yeni ödev eklendi.")
  } else {
    message("Var olan nitelik şablonu korunuyor: ", nitelik_yolu)
  }
}
message("Kodlama bittiğinde: 05_analiz.R")
