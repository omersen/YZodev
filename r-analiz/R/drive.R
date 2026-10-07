# =============================================================================
# Google Drive yardımcıları (googledrive paketi)
# =============================================================================

MIME_KLASOR <- "application/vnd.google-apps.folder"
MIME_KISAYOL <- "application/vnd.google-apps.shortcut"
MIME_GDOC <- "application/vnd.google-apps.document"
GECICI_KOPYA_ONEKI <- "gecici_donusum_"

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
# Desteklenen biçimler: ".../folders/<ID>?usp=sharing", ".../d/<ID>/view",
# ".../open?id=<ID>" ve doğrudan "<ID>". (googledrive 2.1.1'deki as_id()
# "?usp=sharing" ile biten bağlantıları tanımıyor; kimlik burada ayıklanır.)
drive_kimligi <- function(baglanti) {
  x <- trimws(baglanti)
  kimlik <- regmatches(x, regexpr("(?<=/folders/|/d/|[?&]id=)[A-Za-z0-9_-]+", x, perl = TRUE))
  if (length(kimlik) == 0) {
    if (!grepl("^[A-Za-z0-9_-]{10,}$", x)) {
      stop("Drive klasör bağlantısı tanınmadı: ", baglanti,
           "\nKlasörü tarayıcıda açıp adres çubuğundaki bağlantıyı kopyalayın.", call. = FALSE)
    }
    kimlik <- x
  }
  googledrive::as_id(kimlik)
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
  # Önceki bir OCR dönüştürmesinden silinemeden kalmış geçici kopyalar ödev değildir
  icerik <- icerik[!startsWith(icerik$name, GECICI_KOPYA_ONEKI), ]
  if (nrow(icerik) == 0) return(NULL)

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

# Uzantı tahmini -----------------------------------------------------------------------
# Önce dosya adındaki uzantıya, tanınmıyorsa MIME türüne bakılır (ör. Drive'da
# "Ahmet Yılmaz ödev" diye yeniden adlandırılmış bir PDF ya da "Ödev 1.5").
# Google Dokümanlar dosyalarının uzantısı yoktur ("gdoc").
BILINEN_UZANTILAR <- c("docx", "pdf", "doc", "odt", "rtf", "txt", "md", "docm", "dotx",
                       "jpg", "jpeg", "png")
MIME_UZANTI <- c(
  "application/pdf" = "pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "docx",
  "application/msword" = "doc",
  "application/vnd.oasis.opendocument.text" = "odt",
  "application/rtf" = "rtf", "text/rtf" = "rtf",
  "text/plain" = "txt",
  "image/jpeg" = "jpg", "image/png" = "png"
)
dosya_uzantisi <- function(ad, mime) {
  ad_uzantisi <- tolower(tools::file_ext(ad))
  mime_uzantisi <- unname(MIME_UZANTI[mime])
  ifelse(mime == MIME_GDOC, "gdoc",
         ifelse(ad_uzantisi %in% BILINEN_UZANTILAR, ad_uzantisi,
                ifelse(is.na(mime_uzantisi), ad_uzantisi, mime_uzantisi)))
}

# Tek dosya indirme --------------------------------------------------------------
# Google Dokümanlar dosyaları docx olarak dışa aktarılır; böylece Word dosyaları
# ile aynı çıkarma işlevinden geçer. Dosya önce geçici bir adla indirilir ve
# yalnızca indirme başarılıysa asıl adına taşınır: googledrive başarısız bir
# indirmede hata gövdesini de diske yazar; bu, asıl adla kalırsa sonraki
# çalıştırmada "indirilmiş" sanılabilir.
drive_dosya_indir <- function(drive_id, hedef_yol, mime) {
  if (grepl("^application/vnd\\.google-apps\\.", mime) && mime != MIME_GDOC) {
    stop("Bu Google dosya türü desteklenmiyor: ", mime)
  }
  gecici <- paste0(hedef_yol, ".indiriliyor")
  # googledrive, Google Dokümanlar dışa aktarımında yola ".docx" ekleyebilir
  on.exit(unlink(c(gecici, paste0(gecici, ".docx"))), add = TRUE)
  indirilen <- if (mime == MIME_GDOC) {
    googledrive::drive_download(googledrive::as_id(drive_id), path = gecici, type = "docx", overwrite = TRUE)
  } else {
    googledrive::drive_download(googledrive::as_id(drive_id), path = gecici, overwrite = TRUE)
  }
  yerel <- indirilen$local_path %||% gecici
  if (!file.exists(yerel) || !file.rename(yerel, hedef_yol)) stop("İndirilen dosya kaydedilemedi: ", hedef_yol)
  invisible(hedef_yol)
}

# Drive üzerinde Google Dokümanlar'a dönüştürüp metin olarak okuma -----------
# .doc/.rtf/.odt dosyaları ile metin katmanı olmayan (taranmış) PDF ve
# görüntülerde son çare olarak kullanılır. PDF ve görüntülerde Drive OCR uygular.
# Geçici kopya, okunduktan sonra kalıcı olarak silinir (drive_rm).
# Gerektirdiği yetki: drive_baglan(salt_okunur = FALSE).
drive_donusturerek_oku <- function(drive_id, ocr_dili = "tr") {
  # Kopya kullanıcının "Drive'ım" köküne yazılır: ödev klasörüne düşerse ve
  # silinemezse (ör. ortak Drive'da silme yetkisi yoksa) bir sonraki taramada
  # yeni bir ödev gibi görünebilirdi.
  kopya <- googledrive::drive_cp(
    googledrive::as_id(drive_id),
    path = "~/",
    name = paste0(GECICI_KOPYA_ONEKI, drive_id),
    mime_type = MIME_GDOC,
    ocr_language = ocr_dili,
    overwrite = NA
  )
  on.exit({
    silindi <- tryCatch(isTRUE(googledrive::drive_rm(kopya)), error = function(e) FALSE)
    if (!silindi) silindi <- tryCatch({ googledrive::drive_trash(kopya); TRUE }, error = function(e) FALSE)
    if (!silindi) warning("Geçici Drive kopyası silinemedi; elle silin: ", kopya$name, " (", kopya$id, ")", call. = FALSE)
  }, add = TRUE)
  gecici <- tempfile(fileext = ".docx")
  googledrive::drive_download(kopya, path = gecici, type = "docx", overwrite = TRUE)
  docx_metin_cikar(gecici)
}
