# =============================================================================
# 02_metin_cikar.R : İndirilen dosyalardan ödev yönergesi metnini çıkarır
# -----------------------------------------------------------------------------
# Çıktılar (veri/ altında):
#   metin_ham/O001.txt   : makinenin çıkardığı metin
#   yonergeler/O001.txt  : YZ'ye GÖNDERİLECEK metin. İlk çalıştırmada ham metnin
#                          kopyasıdır; araştırmacı bu dosyayı düzeltir (ad-soyad,
#                          öğrenci no, kapak sayfası, ödevle ilgisiz açıklamalar).
#                          Elle yapılan düzeltmelerin üzerine yazılmaz.
#   kontrol_listesi.xlsx : her ödev için kalite göstergeleri ve elle doldurulacak
#                          "kontrol_edildi" sütunu (evet/hayır).
# Drive'daki kaynak dosya değişirse (ham metnin özeti kontrol listesinde tutulur):
#   - yönerge hiç düzenlenmemişse yeni metinle değiştirilir;
#   - elle düzenlenmişse yeni metin <id>.yeni.txt olarak yazılır. Bu dosya
#     durdukça uyarı sürer ve 03 o ödevi göndermez; yönergeyi güncelleyip
#     .yeni.txt dosyasını silin;
#   - her iki durumda kontrol işareti sıfırlanır.
# Dosyalar, kontrol listesi başarıyla kaydedildikten SONRA yazılır; liste Excel'de
# açık olduğu için kayıt başarısız olursa hiçbir şey değişmez ve değişiklik bir
# sonraki çalıştırmada yine algılanır. Okunamayan dosya "değişti" sayılmaz.
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("xml2", "pdftools", "stringi", "openxlsx", "digest"))

envanter <- xlsx_oku(file.path(AYAR$veri_dizini, "envanter.xlsx"))
ham_metin_dizini <- file.path(AYAR$veri_dizini, "metin_ham")
yonerge_dizini <- file.path(AYAR$veri_dizini, "yonergeler")
dir.create(ham_metin_dizini, showWarnings = FALSE)
dir.create(yonerge_dizini, showWarnings = FALSE)

if (isTRUE(AYAR$drive_donusturme_izni)) {
  gerekli_paketler("googledrive")
  drive_baglan(AYAR$drive_email, salt_okunur = FALSE)
}

kontrol_yolu <- file.path(AYAR$veri_dizini, "kontrol_listesi.xlsx")
eski <- if (file.exists(kontrol_yolu)) xlsx_oku(kontrol_yolu) else NULL
eski_deger <- function(id, sutun) {
  if (is.null(eski) || is.null(eski[[sutun]])) return(NA)
  eski[[sutun]][match(id, eski$odev_id)]
}

# Olası kişisel veri örüntüleri (yalnızca uyarı amaçlı; elle kontrol şarttır)
kisisel_veri_oruntuleri <- c(
  eposta = "[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}",
  telefon = "(\\+90|0)?\\s?5[0-9]{2}\\s?[0-9]{3}\\s?[0-9]{2}\\s?[0-9]{2}",
  uzun_sayi = "\\b[0-9]{9,11}\\b",   # TC kimlik no / öğrenci no olabilir
  ad_alani = "(?i)(ad[ıi]?\\s*soyad|öğrenci\\s*(no|numaras)|numara\\s*:)"
)

satirlar <- vector("list", nrow(envanter))
yazilacak <- list()   # kontrol listesi kaydedildikten sonra yazılacak dosyalar
for (i in seq_len(nrow(envanter))) {
  id <- envanter$odev_id[i]
  yol <- envanter$yerel_yol[i]
  message(sprintf("[%d/%d] %s", i, nrow(envanter), id))

  r <- if (is.na(yol) || !file.exists(yol)) {
    list(metin = NA_character_, bilgi = list(), yontem = "dosya-yok")
  } else {
    tryCatch(yerel_metin_cikar(yol),
             error = function(e) list(metin = NA_character_, bilgi = list(),
                                      yontem = paste("HATA:", xml_guvenli(conditionMessage(e)))))
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
  okundu <- nzchar(trimws(metin)) && !grepl("HATA|yok|desteklenmeyen", r$yontem)
  ham_yol <- file.path(ham_metin_dizini, paste0(id, ".txt"))
  hedef <- file.path(yonerge_dizini, paste0(id, ".txt"))
  yeni_yol <- file.path(yonerge_dizini, paste0(id, ".yeni.txt"))

  # Değişiklik, kontrol listesinde saklanan son ham metin özetine göre belirlenir.
  onceki_ozet <- eski_deger(id, "ham_sha256")
  yeni_ozet <- sha256(metin_temizle(metin))
  kaynak_degisti <- okundu && !is.na(onceki_ozet) && !identical(onceki_ozet, yeni_ozet)
  ham_ozet <- if (okundu || is.na(onceki_ozet)) yeni_ozet else onceki_ozet   # okunamazsa referans korunur

  gonderilecek <- if (file.exists(hedef)) txt_oku(hedef) else metin
  if (!file.exists(hedef)) {
    yazilacak[[length(yazilacak) + 1]] <- list(hedef, metin)
  } else if (kaynak_degisti) {
    onceki_ham <- if (file.exists(ham_yol)) txt_oku(ham_yol) else NA_character_
    duzenlenmemis <- !is.na(onceki_ham) && identical(metin_temizle(gonderilecek), metin_temizle(onceki_ham))
    if (duzenlenmemis) {
      yazilacak[[length(yazilacak) + 1]] <- list(hedef, metin)
      gonderilecek <- metin
    } else {
      yazilacak[[length(yazilacak) + 1]] <- list(yeni_yol, metin)
    }
  }
  if (okundu || !file.exists(ham_yol)) yazilacak[[length(yazilacak) + 1]] <- list(ham_yol, metin)
  bekleyen_yeni <- file.exists(yeni_yol) || any(vapply(yazilacak, function(y) identical(y[[1]], yeni_yol), logical(1)))

  # Göstergeler, API'ye GÖNDERİLECEK metin üzerinden hesaplanır; araştırmacının
  # elle yazdığı ya da yapıştırdığı metin de taranır.
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
    yeni_surum_bekliyor = bekleyen_yeni,
    ham_sha256 = ham_ozet,
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
  ifelse(kontrol$kaynak_degisti & !kontrol$yeni_surum_bekliyor,
         "KAYNAK DOSYA DEĞİŞTİ: yönerge yeni metinle güncellendi, yeniden kontrol edin;", ""),
  ifelse(kontrol$yeni_surum_bekliyor,
         paste0("YENİ SÜRÜM BEKLİYOR: ", kontrol$odev_id, ".yeni.txt dosyasındaki metne göre yönergeyi ",
                "güncelleyip .yeni.txt dosyasını silin (silinene kadar 03 bu ödevi göndermez);"), "")
))

# Önceki kontrol işaretleri korunur; kaynağı değişen ödevlerinki sıfırlanır.
kontrol$kontrol_edildi <- ""
kontrol$not <- ""
if (!is.null(eski)) {
  for (s in c("kontrol_edildi", "not")) {
    deger <- as.character(eski_deger(kontrol$odev_id, s))
    kontrol[[s]] <- ifelse(is.na(deger), "", deger)
  }
}
kontrol$kontrol_edildi[kontrol$kaynak_degisti] <- ""

wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "kontrol")
openxlsx::writeDataTable(wb, "kontrol", kontrol, withFilter = TRUE)
sutun <- which(names(kontrol) == "kontrol_edildi")
liste_dogrulama(wb, "kontrol", sutun, 2:(nrow(kontrol) + 1), c("evet", "hayır"))
openxlsx::freezePane(wb, "kontrol", firstRow = TRUE, firstCol = TRUE)
openxlsx::setColWidths(wb, "kontrol", cols = seq_along(kontrol), widths = "auto")
xlsx_kaydet(wb, kontrol_yolu)   # başarısız olursa burada durulur; aşağıdaki dosyalar yazılmaz

for (y in yazilacak) txt_yaz(y[[2]], y[[1]])

if (any(kontrol$kaynak_degisti)) {
  message("UYARI: Drive'daki kaynak dosyası değişen ödev(ler): ",
          paste(kontrol$odev_id[kontrol$kaynak_degisti], collapse = ", "),
          ". Kontrol işaretleri sıfırlandı; 'dikkat' sütununa bakın.")
}
if (any(kontrol$yeni_surum_bekliyor)) {
  message("Bekleyen yeni sürüm (.yeni.txt) olan ödev(ler): ",
          paste(kontrol$odev_id[kontrol$yeni_surum_bekliyor], collapse = ", "))
}
message("\nYöntemlere göre dosya sayısı:")
print(table(kontrol$yontem))
message(sum(nzchar(kontrol$dikkat)), " ödev dikkat gerektiriyor (kontrol_listesi.xlsx, 'dikkat' sütunu).")
message("ŞİMDİ: veri/yonergeler/*.txt dosyalarını okuyup gerekirse düzeltin, ",
        "kontrol_listesi.xlsx'te 'kontrol_edildi' = evet yapın. Sonra: 03_yz_cagri.R")
