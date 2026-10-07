# =============================================================================
# Google Drive yardımcıları (googledrive paketi)
# =============================================================================

MIME_KLASOR <- "application/vnd.google-apps.folder"
MIME_KISAYOL <- "application/vnd.google-apps.shortcut"
MIME_GDOC <- "application/vnd.google-apps.document"

# Kimlik doğrulama -------------------------------------------------------------
# salt_okunur = TRUE  -> "drive.readonly" kapsamı (en az yetki ilkesi).
# salt_okunur = FALSE -> tam "drive" kapsamı. Yalnızca .doc/taranmış PDF gibi
#   dosyaları Google Dokümanlar'a dönüştürerek okumak gerektiğinde gerekir;
#   bu işlem Drive'da geçici bir kopya oluşturup sonra siler.
drive_baglan <- function(email = NULL, salt_okunur = TRUE) {
  googledrive::drive_auth(
    email = email %||% gargle::gargle_oauth_email(),
    scopes = if (salt_okunur) "drive.readonly" else "drive"
  )
  invisible(TRUE)
}

# Drive bağlantısından kimlik ------------------------------------------------------
# googledrive 2.1.1'deki as_id(), "?usp=sharing" ile biten bağlantıları
# tanımıyor (2.1.2'de düzeltildi); sorgu kısmı burada önceden atılır.
drive_kimligi <- function(baglanti) {
  googledrive::as_id(sub("[?#].*$", "", trimws(baglanti)))
}

mime_turleri <- function(dribble) {
  vapply(dribble$drive_resource, function(r) r$mimeType %||% NA_character_, "")
}

# Klasörü alt klasörleriyle birlikte dolaşır ve göreli yolu kaydeder ----------
# drive_ls(recursive = TRUE) dosyanın hangi alt klasörde olduğunu döndürmediği
# ve klasör kısayollarını izlemediği için (Google Formlar ve Classroom her
# soru/öğrenci için alt klasör açabilir) dolaşma burada elle yapılır.
# Kısayollar hedef dosyaya çözülür; erişilemeyen hedefler bildirilir.
drive_klasor_tara <- function(klasor, goreli_yol = "", ziyaret = new.env()) {
  klasor <- googledrive::as_dribble(klasor)
  if (!is.null(ziyaret[[klasor$id]])) return(NULL)   # döngüsel kısayol koruması
  ziyaret[[klasor$id]] <- TRUE

  icerik <- googledrive::drive_ls(klasor)
  if (nrow(icerik) == 0) return(NULL)
  icerik <- icerik[, c("name", "id", "drive_resource")]

  kisayol <- mime_turleri(icerik) == MIME_KISAYOL
  if (any(kisayol)) {
    cozulmus <- googledrive::shortcut_resolve(icerik[kisayol, ])
    erisilemeyen <- is.na(cozulmus$name)
    if (any(erisilemeyen)) {
      message("Erişilemeyen kısayol(lar) atlandı: ",
              paste(cozulmus$name_shortcut[erisilemeyen], collapse = ", "))
    }
    icerik <- rbind(icerik[!kisayol, ],
                    cozulmus[!erisilemeyen, c("name", "id", "drive_resource")])
  }
  mime <- mime_turleri(icerik)

  dosyalar <- icerik[mime != MIME_KLASOR, ]
  sonuc <- NULL
  if (nrow(dosyalar) > 0) {
    kaynak <- dosyalar$drive_resource
    sonuc <- data.frame(
      drive_id = dosyalar$id,
      ad = dosyalar$name,
      alt_klasor = goreli_yol,
      mime_turu = mime[mime != MIME_KLASOR],
      md5 = vapply(kaynak, function(r) r$md5Checksum %||% NA_character_, ""),
      boyut_bayt = vapply(kaynak, function(r) as.numeric(r$size %||% NA), 0),
      degistirilme = vapply(kaynak, function(r) r$modifiedTime %||% NA_character_, ""),
      stringsAsFactors = FALSE
    )
  }

  alt <- icerik[mime == MIME_KLASOR, ]
  for (i in seq_len(nrow(alt))) {
    yeni_yol <- if (nzchar(goreli_yol)) paste(goreli_yol, alt$name[i], sep = "/") else alt$name[i]
    sonuc <- rbind(sonuc, drive_klasor_tara(alt[i, ], yeni_yol, ziyaret))
  }
  # Aynı dosyaya hem kendisi hem kısayolu ile ulaşılmış olabilir
  if (!is.null(sonuc)) sonuc <- sonuc[!duplicated(sonuc$drive_id), ]
  sonuc
}

# Uzantı tahmini (Google Dokümanlar dosyalarının uzantısı yoktur) -------------
dosya_uzantisi <- function(ad, mime) {
  ifelse(mime == MIME_GDOC, "gdoc", tolower(tools::file_ext(ad)))
}

# Tek dosya indirme --------------------------------------------------------------
# Google Dokümanlar dosyaları docx olarak dışa aktarılır; böylece Word dosyaları
# ile aynı çıkarma işlevinden geçer.
drive_dosya_indir <- function(drive_id, hedef_yol, mime) {
  if (mime == MIME_GDOC) {
    googledrive::drive_download(googledrive::as_id(drive_id), path = hedef_yol,
                                type = "docx", overwrite = TRUE)
  } else if (grepl("^application/vnd\\.google-apps\\.", mime)) {
    stop("Bu Google dosya türü desteklenmiyor: ", mime)
  } else {
    googledrive::drive_download(googledrive::as_id(drive_id), path = hedef_yol,
                                overwrite = TRUE)
  }
  invisible(hedef_yol)
}

# Drive üzerinde Google Dokümanlar'a dönüştürüp metin olarak okuma -----------
# .doc/.rtf/.odt dosyaları ile metin katmanı olmayan (taranmış) PDF ve
# görüntülerde son çare olarak kullanılır. PDF ve görüntülerde Drive OCR uygular.
# Geçici kopya, okunduktan sonra kalıcı olarak silinir (drive_rm).
# Gerektirdiği yetki: drive_baglan(salt_okunur = FALSE).
drive_donusturerek_oku <- function(drive_id, ocr_dili = "tr") {
  kopya <- googledrive::drive_cp(
    googledrive::as_id(drive_id),
    name = paste0("gecici_donusum_", drive_id),
    mime_type = MIME_GDOC,
    ocr_language = ocr_dili,
    overwrite = FALSE
  )
  on.exit(try(googledrive::drive_rm(kopya), silent = TRUE), add = TRUE)
  gecici <- tempfile(fileext = ".docx")
  googledrive::drive_download(kopya, path = gecici, type = "docx", overwrite = TRUE)
  docx_metin_cikar(gecici)
}
