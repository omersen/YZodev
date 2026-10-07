# =============================================================================
# 02_metin_cikar.R : İndirilen dosyalardan ödev yönergesi metnini çıkarır
# -----------------------------------------------------------------------------
# Çıktılar (veri/ altında):
#   metin_ham/O001.txt   : makinenin çıkardığı metin (her çalıştırmada yenilenir)
#   yonergeler/O001.txt  : YZ'ye GÖNDERİLECEK metin. İlk çalıştırmada ham metnin
#                          kopyasıdır; araştırmacı bu dosyayı düzeltir (ad-soyad,
#                          öğrenci no, kapak sayfası, ödevle ilgisiz açıklamalar).
#                          Var olan dosyanın üzerine YAZILMAZ; elle yapılan
#                          düzeltmeler korunur.
#   kontrol_listesi.xlsx : her ödev için kalite göstergeleri ve elle doldurulacak
#                          "kontrol_edildi" sütunu (evet/hayır).
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("xml2", "pdftools", "stringi", "openxlsx"))

envanter <- xlsx_oku(file.path(AYAR$veri_dizini, "envanter.xlsx"))
ham_metin_dizini <- file.path(AYAR$veri_dizini, "metin_ham")
yonerge_dizini <- file.path(AYAR$veri_dizini, "yonergeler")
dir.create(ham_metin_dizini, showWarnings = FALSE)
dir.create(yonerge_dizini, showWarnings = FALSE)

if (isTRUE(AYAR$drive_donusturme_izni)) {
  gerekli_paketler("googledrive")
  drive_baglan(AYAR$drive_email, salt_okunur = FALSE)
}

# Olası kişisel veri örüntüleri (yalnızca uyarı amaçlı; elle kontrol şarttır)
kisisel_veri_oruntuleri <- c(
  eposta = "[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}",
  telefon = "(\\+90|0)?\\s?5[0-9]{2}\\s?[0-9]{3}\\s?[0-9]{2}\\s?[0-9]{2}",
  uzun_sayi = "\\b[0-9]{9,11}\\b",   # TC kimlik no / öğrenci no olabilir
  ad_alani = "(?i)(ad[ıi]?\\s*soyad|öğrenci\\s*(no|numaras)|numara\\s*:)"
)

satirlar <- vector("list", nrow(envanter))
for (i in seq_len(nrow(envanter))) {
  id <- envanter$odev_id[i]
  yol <- envanter$yerel_yol[i]
  message(sprintf("[%d/%d] %s", i, nrow(envanter), id))

  r <- if (is.na(yol) || !file.exists(yol)) {
    list(metin = NA_character_, bilgi = list(), yontem = "dosya-yok")
  } else {
    tryCatch(yerel_metin_cikar(yol),
             error = function(e) list(metin = NA_character_, bilgi = list(),
                                      yontem = paste("HATA:", conditionMessage(e))))
  }

  # Yerelde okunamadıysa ya da PDF taranmış görünüyorsa: Drive dönüştürmesi (OCR)
  drive_gerekli <- is.na(r$metin) || isTRUE(r$bilgi$taranmis_olabilir)
  if (drive_gerekli && isTRUE(AYAR$drive_donusturme_izni) && !is.na(envanter$drive_id[i])) {
    r2 <- tryCatch(drive_donusturerek_oku(envanter$drive_id[i]), error = function(e) e)
    if (!inherits(r2, "error") && nzchar(r2$metin)) {
      r <- list(metin = r2$metin, bilgi = c(r2$bilgi, list(taranmis_olabilir = r$bilgi$taranmis_olabilir)),
                yontem = paste0(r$yontem, " -> drive-donusum"))
    }
  }

  metin <- if (is.na(r$metin)) "" else r$metin
  ham_yol <- file.path(ham_metin_dizini, paste0(id, ".txt"))
  eski_ham <- if (file.exists(ham_yol)) txt_oku(ham_yol) else NA_character_
  # Drive'daki dosya güncellendiyse ham metin değişir. Yönerge hiç
  # düzenlenmemişse yeni metinle değiştirilir; elle düzenlenmişse yeni metin
  # <id>.yeni.txt olarak yazılır ve araştırmacının karar vermesi beklenir.
  # Her iki durumda da kontrol işareti sıfırlanır.
  kaynak_degisti <- !is.na(eski_ham) && !identical(metin_temizle(eski_ham), metin_temizle(metin))
  txt_yaz(metin, ham_yol)
  hedef <- file.path(yonerge_dizini, paste0(id, ".txt"))
  yeni_surum <- ""
  if (!file.exists(hedef)) {
    txt_yaz(metin, hedef)
  } else if (kaynak_degisti) {
    if (identical(metin_temizle(txt_oku(hedef)), metin_temizle(eski_ham))) {
      txt_yaz(metin, hedef)
    } else {
      yeni_surum <- file.path(yonerge_dizini, paste0(id, ".yeni.txt"))
      txt_yaz(metin, yeni_surum)
    }
  }

  # Göstergeler, API'ye GÖNDERİLECEK metin (yonergeler/<id>.txt) üzerinden
  # hesaplanır; araştırmacının elle yazdığı ya da yapıştırdığı metin de taranır.
  gonderilecek <- txt_oku(hedef)
  b <- r$bilgi
  kv <- names(kisisel_veri_oruntuleri)[vapply(kisisel_veri_oruntuleri,
                                               function(p) grepl(p, gonderilecek, perl = TRUE), logical(1))]
  satirlar[[i]] <- data.frame(
    odev_id = id,
    uzanti = envanter$uzanti[i],
    yontem = r$yontem,
    karakter = nchar(gonderilecek),
    kelime = if (nzchar(trimws(gonderilecek))) lengths(strsplit(trimws(gonderilecek), "\\s+")) else 0L,
    ham_karakter = nchar(metin),
    taranmis_olabilir = isTRUE(b$taranmis_olabilir),
    gorsel = b$gorsel_sayisi %||% NA,
    tablo = b$tablo_sayisi %||% NA,
    denklem = b$denklem_sayisi %||% NA,
    metin_kutusu = b$metin_kutusu_sayisi %||% NA,
    ust_alt_bilgi = b$ust_alt_bilgi %||% "",
    olasi_kisisel_veri = paste(kv, collapse = ", "),
    yz_ifadesi_geciyor = grepl("(?i)yapay\\s*zek|chatgpt|\\bYZ\\b|\\bÜYZ\\b", gonderilecek, perl = TRUE),
    ayni_icerik = if (is.null(envanter$ayni_icerik) || is.na(envanter$ayni_icerik[i])) "" else envanter$ayni_icerik[i],
    kaynak_degisti = kaynak_degisti,
    yeni_surum = basename(yeni_surum),
    stringsAsFactors = FALSE
  )
}
kontrol <- do.call(rbind, satirlar)

# Dikkat gerektiren durumların özeti
kontrol$dikkat <- trimws(paste(
  ifelse(kontrol$karakter < 200, "kısa/boş metin;", ""),
  ifelse(kontrol$taranmis_olabilir, "taranmış PDF (OCR gerekebilir);", ""),
  ifelse(!is.na(kontrol$gorsel) & kontrol$gorsel > 0, "görsel içeriyor (YZ'ye yalnız metin gider);", ""),
  ifelse(!is.na(kontrol$denklem) & kontrol$denklem > 0, "denklem içeriyor;", ""),
  ifelse(nzchar(kontrol$olasi_kisisel_veri), "olası kişisel veri;", ""),
  ifelse(nzchar(kontrol$ust_alt_bilgi), "üst/alt bilgi var (gönderilmez);", ""),
  ifelse(nzchar(kontrol$ayni_icerik), "yinelenen dosya;", ""),
  ifelse(grepl("HATA|yok|desteklenmeyen", kontrol$yontem), "okunamadı;", ""),
  ifelse(kontrol$kaynak_degisti & nzchar(kontrol$yeni_surum),
         paste0("KAYNAK DOSYA DEĞİŞTİ: yeni metin ", kontrol$yeni_surum, " dosyasında, yönergeyi güncelleyin;"),
         ifelse(kontrol$kaynak_degisti, "KAYNAK DOSYA DEĞİŞTİ: yönerge yeni metinle güncellendi, yeniden kontrol edin;", ""))
))

# Önceki kontrol işaretleri korunur
kontrol_yolu <- file.path(AYAR$veri_dizini, "kontrol_listesi.xlsx")
kontrol$kontrol_edildi <- ""
kontrol$not <- ""
if (file.exists(kontrol_yolu)) {
  eski <- xlsx_oku(kontrol_yolu)
  m <- match(kontrol$odev_id, eski$odev_id)
  var <- !is.na(m)
  for (s in c("kontrol_edildi", "not")) {
    deger <- as.character(eski[[s]] %||% rep(NA, nrow(eski)))[m[var]]
    kontrol[[s]][var] <- ifelse(is.na(deger), "", deger)
  }
}
kontrol$kontrol_edildi[kontrol$kaynak_degisti] <- ""   # değişen ödev yeniden kontrol edilmeli
if (any(kontrol$kaynak_degisti)) {
  message("UYARI: Drive'daki kaynak dosyası değişen ödev(ler): ",
          paste(kontrol$odev_id[kontrol$kaynak_degisti], collapse = ", "),
          ". Kontrol işaretleri sıfırlandı; 'dikkat' sütununa bakın.")
}

wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "kontrol")
openxlsx::writeDataTable(wb, "kontrol", kontrol, withFilter = TRUE)
sutun <- which(names(kontrol) == "kontrol_edildi")
liste_dogrulama(wb, "kontrol", sutun, 2:(nrow(kontrol) + 1), c("evet", "hayır"))
openxlsx::freezePane(wb, "kontrol", firstRow = TRUE, firstCol = TRUE)
openxlsx::setColWidths(wb, "kontrol", cols = seq_along(kontrol), widths = "auto")
xlsx_kaydet(wb, kontrol_yolu)

message("\nYöntemlere göre dosya sayısı:")
print(table(kontrol$yontem))
message(sum(nzchar(kontrol$dikkat)), " ödev dikkat gerektiriyor (kontrol_listesi.xlsx, 'dikkat' sütunu).")
message("ŞİMDİ: veri/yonergeler/*.txt dosyalarını okuyup gerekirse düzeltin, ",
        "kontrol_listesi.xlsx'te 'kontrol_edildi' = evet yapın. Sonra: 03_yz_cagri.R")
