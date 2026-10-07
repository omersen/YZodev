# =============================================================================
# 01_drive_indir.R : Google Drive klasöründeki ödev dosyalarını indirir
# -----------------------------------------------------------------------------
# Çıktılar (veri/ altında, GitHub'a gönderilmez):
#   kimlik_eslestirme.xlsx: Drive dosyası <-> anonim ödev kimliği (O001, O002...)
#                           Özgün dosya adları (öğrenci adı içerebilir) yalnızca
#                           bu dosyada tutulur.
#   envanter.xlsx         : dosya türü, boyut, md5, indirme durumu
#   ham/O001.docx ...     : indirilen dosyalar (anonim adlarla)
# Betik yeniden çalıştırılabilir: Drive'da değişmemiş dosyalar yeniden indirilmez,
# klasöre sonradan eklenen dosyalar yeni kimlik alır, eski kimlikler değişmez.
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("googledrive", "gargle", "openxlsx"))

if (grepl("^BURAYA_", AYAR$drive_klasor)) stop("00_ayarlar.R içinde drive_klasor ayarını doldurun.")

drive_baglan(AYAR$drive_email, salt_okunur = !isTRUE(AYAR$drive_donusturme_izni))
envanter <- drive_klasor_tara(drive_kimligi(AYAR$drive_klasor))
if (is.null(envanter) || nrow(envanter) == 0) stop("Klasörde dosya bulunamadı.")
envanter <- envanter[order(envanter$alt_klasor, envanter$ad), ]

# Kalıcı anonim kimlikler -----------------------------------------------------------
eslestirme_yolu <- file.path(AYAR$veri_dizini, "kimlik_eslestirme.xlsx")
eslestirme <- if (file.exists(eslestirme_yolu)) {
  xlsx_oku(eslestirme_yolu)
} else {
  data.frame(odev_id = character(0), drive_id = character(0), ad = character(0),
             alt_klasor = character(0), stringsAsFactors = FALSE)
}
yeni <- envanter[!envanter$drive_id %in% eslestirme$drive_id, ]
if (nrow(yeni) > 0) {
  son_no <- if (nrow(eslestirme) > 0) max(as.integer(sub("^O", "", eslestirme$odev_id))) else 0
  eslestirme <- rbind(eslestirme, data.frame(
    odev_id = sprintf("O%03d", son_no + seq_len(nrow(yeni))),
    drive_id = yeni$drive_id, ad = yeni$ad, alt_klasor = yeni$alt_klasor,
    stringsAsFactors = FALSE
  ))
  xlsx_yaz(eslestirme, eslestirme_yolu)
}
envanter <- merge(eslestirme[, c("odev_id", "drive_id")], envanter, by = "drive_id")
envanter <- envanter[order(envanter$odev_id), ]

# Klasörden silinmiş dosyalar bildirilir (kimlikleri korunur) ---------------------
kayip <- setdiff(eslestirme$drive_id, envanter$drive_id)
if (length(kayip) > 0) message(length(kayip), " dosya artık Drive klasöründe yok (kimlik_eslestirme.xlsx'te kaldı).")

# Aynı içerikli dosyalar (ör. aynı ödevin iki kez yüklenmesi) --------------------
envanter$uzanti <- dosya_uzantisi(envanter$ad, envanter$mime_turu)
yinelenen_md5 <- envanter$md5[!is.na(envanter$md5) & duplicated(envanter$md5)]
envanter$ayni_icerik <- ifelse(envanter$md5 %in% yinelenen_md5,
                               paste0("md5:", substr(envanter$md5, 1, 8)), "")

# İndirme ---------------------------------------------------------------------------
ham_dizin <- file.path(AYAR$veri_dizini, "ham")
dir.create(ham_dizin, showWarnings = FALSE)
onceki <- file.path(AYAR$veri_dizini, "envanter.xlsx")
onceki <- if (file.exists(onceki)) xlsx_oku(onceki) else NULL

envanter$yerel_yol <- NA_character_
envanter$indirme <- NA_character_
for (i in seq_len(nrow(envanter))) {
  uz <- if (envanter$uzanti[i] == "gdoc") "docx" else envanter$uzanti[i]
  hedef <- file.path(ham_dizin, paste0(envanter$odev_id[i], if (nzchar(uz)) paste0(".", uz)))
  envanter$yerel_yol[i] <- hedef
  # Yalnızca önceki çalıştırmada BAŞARIYLA indirilmiş ve Drive'da değişmemiş
  # dosyalar atlanır; önceki indirme hatalıysa yeniden denenir.
  ayni <- !is.null(onceki) && file.exists(hedef) &&
    any(onceki$drive_id == envanter$drive_id[i] &
          onceki$degistirilme == envanter$degistirilme[i] &
          onceki$indirme %in% c("indirildi", "onceden-indirildi"), na.rm = TRUE)
  if (ayni) { envanter$indirme[i] <- "onceden-indirildi"; next }
  message(sprintf("[%d/%d] %s indiriliyor", i, nrow(envanter), envanter$odev_id[i]))
  sonuc <- tryCatch(drive_dosya_indir(envanter$drive_id[i], hedef, envanter$mime_turu[i]),
                    error = function(e) e)
  envanter$indirme[i] <- if (inherits(sonuc, "error")) paste("HATA:", xml_guvenli(conditionMessage(sonuc))) else "indirildi"
}

xlsx_yaz(envanter[, setdiff(names(envanter), "ad")], file.path(AYAR$veri_dizini, "envanter.xlsx"))

message("\nDosya türleri:")
print(table(uzanti = envanter$uzanti))
if (any(nzchar(envanter$ayni_icerik))) {
  message("Aynı içerikli dosyalar var (ayni_icerik sütununa bakın); hangisinin analize girdiğine siz karar verin.")
}
hatali <- grepl("^HATA", envanter$indirme)
if (any(hatali)) message(sum(hatali), " dosya indirilemedi; envanter.xlsx'teki 'indirme' sütununa bakın.")
message("Tamam. Sonraki adım: 02_metin_cikar.R")
