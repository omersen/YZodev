# =============================================================================
# 04_kodlama_formu.R : Kodlayıcılar için Excel kodlama formlarını hazırlar
# -----------------------------------------------------------------------------
# Çıktılar (cikti/kodlama/ altında):
#   kodlayici1_tamamlanabilirlik.xlsx : tüm ödevler, yönerge + YZ çıktısı yan yana,
#                                       açılır listeden kategori seçimi
#   kodlayici2_tamamlanabilirlik.xlsx : rastgele alt örneklem (varsayılan %25);
#                                       birinci kodlayıcının kodları YOK (körleme)
#   tasarim_nitelikleri.xlsx          : yönergelerdeki tasarım niteliklerinin
#                                       0/1 kodlanması için şablon
# Var olan formların üzerine yazılmaz (kodlamalar kaybolmasın diye).
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler("openxlsx")

kodlama_dizini <- file.path(AYAR$cikti_dizini, "kodlama")
dir.create(kodlama_dizini, showWarnings = FALSE, recursive = TRUE)

kayit <- csv_oku(file.path(AYAR$cikti_dizini, "cagri_kaydi.csv"))
yonerge_dosyasi <- function(id) file.path(AYAR$veri_dizini, "yonergeler", paste0(id, ".txt"))
ids <- unique(kayit$odev_id)
yonergeler <- vapply(ids, function(id) txt_oku(yonerge_dosyasi(id)), "")
son <- gecerli_cagrilar(kayit, AYAR, yonergeler)
son <- son[order(son$odev_id, son$tekrar), ]
if (nrow(son) == 0) stop("Şu anki ayarlarla tamamlanmış API çağrısı yok.")
eksik <- setdiff(ids, son$odev_id)
if (length(eksik) > 0) {
  message("Şu anki ayarlarla tamamlanmış çağrısı olmayan ödev(ler) forma alınmadı: ",
          paste(eksik, collapse = ", "), "\n(kesik/hatalı yanıt ya da çağrıdan sonra değiştirilmiş yönerge).")
}

# Excel hücresi en çok 32.767 karakter alır; daha uzun çıktılar kısaltılır ve
# tam metnin bulunduğu dosya belirtilir.
EXCEL_SINIR <- 32000
hucreye_sigdir <- function(x, dosya) {
  if (nchar(x) <= EXCEL_SINIR) return(x)
  paste0(substr(x, 1, EXCEL_SINIR), "\n[... METİN KISALTILDI. Tamamı: ", dosya, "]")
}
cikti_dosyasi <- function(id, t) file.path(AYAR$cikti_dizini, "api_kayitlari", sprintf("%s_t%d_cikti.txt", id, t))

form <- data.frame(
  odev_id = son$odev_id,
  tekrar = son$tekrar,
  yonerge = mapply(function(id) hucreye_sigdir(txt_oku(yonerge_dosyasi(id)), yonerge_dosyasi(id)), son$odev_id),
  yz_ciktisi = mapply(function(id, t) hucreye_sigdir(txt_oku(cikti_dosyasi(id, t)), cikti_dosyasi(id, t)),
                      son$odev_id, son$tekrar),
  model_reddi = ifelse(is.na(son$ret), "", son$ret),
  kategori = NA_character_,
  gerekce = NA_character_,
  stringsAsFactors = FALSE
)

form_yaz <- function(d, yol) {
  if (file.exists(yol)) {
    message("Var olan form korunuyor (üzerine yazılmadı): ", yol)
    return(invisible(FALSE))
  }
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "kodlama")
  openxlsx::writeData(wb, "kodlama", d)
  k <- which(names(d) == "kategori")
  openxlsx::dataValidation(wb, "kodlama", cols = k, rows = 2:(nrow(d) + 1), type = "list",
                           value = paste0('"', paste(AYAR$kategoriler, collapse = ","), '"'))
  sar <- openxlsx::createStyle(wrapText = TRUE, valign = "top")
  openxlsx::addStyle(wb, "kodlama", sar, rows = 1:(nrow(d) + 1), cols = seq_along(d), gridExpand = TRUE)
  openxlsx::setColWidths(wb, "kodlama", cols = seq_along(d),
                         widths = c(9, 7, 60, 80, 20, 26, 40)[seq_along(d)])
  openxlsx::freezePane(wb, "kodlama", firstRow = TRUE)
  openxlsx::addWorksheet(wb, "kategori_tanimlari")
  openxlsx::writeData(wb, "kategori_tanimlari", data.frame(
    sira = seq_along(AYAR$kategoriler), kategori = AYAR$kategoriler,
    tanim = "Kod kitabındaki tanımı buraya yazın"
  ))
  openxlsx::saveWorkbook(wb, yol)
  message("Yazıldı: ", yol)
  invisible(TRUE)
}

form_yaz(form, file.path(kodlama_dizini, "kodlayici1_tamamlanabilirlik.xlsx"))

# İkinci kodlayıcı: ödev düzeyinde rastgele alt örneklem (yalnızca 1. tekrar) --
odevler <- unique(form$odev_id)
n2 <- round(length(odevler) * AYAR$ikinci_kodlayici_orani)
set.seed(AYAR$ikinci_kodlayici_tohumu)
secilen <- sort(sample(odevler, n2))
form2 <- form[form$odev_id %in% secilen & form$tekrar == 1, ]
form_yaz(form2, file.path(kodlama_dizini, "kodlayici2_tamamlanabilirlik.xlsx"))
message("İkinci kodlayıcı için ", n2, " ödev seçildi (tohum = ", AYAR$ikinci_kodlayici_tohumu, ").")

# Tasarım nitelikleri şablonu ---------------------------------------------------------
# Bildirideki dokuz nitelik + iki koşullu alt kod. 1 = var, 0 = yok.
NITELIKLER <- c(
  ozgu_girdi = "Öğrenciye özgü, kişisel veya yerel girdi",
  girdi_islevsel = "Girdinin izleyen bilişsel işlemlerde işlevsel kullanımı",
  veri_toplama = "Gerçek yaşamdan veri toplama",
  belgeleme = "Belgeleme (fotoğraf, video, fiziksel ürün)",
  belgeleme_yalniz_kanit = "Belgeleme yalnızca görevin yapıldığını kanıtlıyor",
  surece_yayma = "Görevi sürece yayma",
  yansitma = "Yansıtma",
  karar_verme = "Karar verme",
  gerekcelendirme = "Gerekçelendirme",
  dogrulama = "Doğrulama"
)
nitelik_formu <- data.frame(odev_id = odevler,
                            yonerge = vapply(odevler, function(id) hucreye_sigdir(txt_oku(yonerge_dosyasi(id)), yonerge_dosyasi(id)), ""),
                            stringsAsFactors = FALSE)
for (s in names(NITELIKLER)) nitelik_formu[[s]] <- NA_integer_
nitelik_yolu <- file.path(kodlama_dizini, "tasarim_nitelikleri.xlsx")
if (!file.exists(nitelik_yolu)) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "nitelikler")
  openxlsx::writeData(wb, "nitelikler", nitelik_formu)
  openxlsx::dataValidation(wb, "nitelikler", cols = 3:ncol(nitelik_formu),
                           rows = 2:(nrow(nitelik_formu) + 1), type = "whole",
                           operator = "between", value = c(0, 1))
  openxlsx::addStyle(wb, "nitelikler", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                     rows = 1:(nrow(nitelik_formu) + 1), cols = 2, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "nitelikler", cols = 1:2, widths = c(9, 80))
  openxlsx::freezePane(wb, "nitelikler", firstRow = TRUE, firstCol = TRUE)
  openxlsx::addWorksheet(wb, "kod_kitabi")
  openxlsx::writeData(wb, "kod_kitabi", data.frame(sutun = names(NITELIKLER), nitelik = unname(NITELIKLER)))
  openxlsx::saveWorkbook(wb, nitelik_yolu)
  message("Yazıldı: ", nitelik_yolu)
}
message("Kodlama bittiğinde: 05_analiz.R")
