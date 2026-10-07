# =============================================================================
# 03_yz_cagri.R : Her ödev yönergesini OpenAI API'ye bağımsız bir çağrıyla sunar
# -----------------------------------------------------------------------------
# - Tüm ödevler AYNI sistem istemi, AYNI kullanıcı şablonu ve AYNI parametrelerle
#   gönderilir; çağrılar arasında bağlam aktarılmaz.
# - Her çağrının isteği ve ham yanıtı cikti/api_kayitlari/ altına yazılır.
# - Her çağrının kaydı (zaman, istenen ve yanıt veren model, üretim ayarları,
#   durum, token kullanımı, yönerge/istem/ayar SHA-256 özetleri) ham yanıtın
#   yanına *_kayit.json olarak yazılır; cikti/cagri_kaydi.xlsx okunabilir kopyadır.
# - Kesintiye uğrarsa betiği yeniden çalıştırın: başarıyla tamamlanmış çağrılar
#   (aynı yönerge, istem ve model için) tekrarlanmaz.
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("httr2", "jsonlite", "digest", "openxlsx"))
api_anahtari()   # anahtar yoksa burada durur

kayit_dizini <- file.path(AYAR$cikti_dizini, "api_kayitlari")
dir.create(kayit_dizini, showWarnings = FALSE, recursive = TRUE)
kayit_yolu <- file.path(AYAR$cikti_dizini, "cagri_kaydi.xlsx")
kopya_yaz <- function(kayit) {
  tryCatch(xlsx_yaz(kayit, kayit_yolu), error = function(e) {
    message("Not: ", kayit_yolu, " güncellenemedi (Excel'de açık olabilir). Kayıtlar ",
            "api_kayitlari/*_kayit.json dosyalarında güvende; kopya sonraki çağrıda yeniden yazılır.")
  })
}

# Gönderilecek yönergeler -------------------------------------------------------------
kontrol <- xlsx_oku(file.path(AYAR$veri_dizini, "kontrol_listesi.xlsx"))
onayli <- kontrol$odev_id[tolower(trimws(kontrol$kontrol_edildi %||% "")) == "evet"]
onayli <- onayli[!is.na(onayli)]
if (length(onayli) < nrow(kontrol)) {
  message(nrow(kontrol) - length(onayli), " ödev 'kontrol_edildi = evet' olmadığı için gönderilmeyecek.")
}
if (length(onayli) == 0) stop("Kontrol edilmiş ödev yok. kontrol_listesi.xlsx'i doldurun.")

# Kaynağı değişip yeni sürümü (.yeni.txt) karara bağlanmamış ödevler gönderilmez.
bekleyen <- onayli[file.exists(file.path(AYAR$veri_dizini, "yonergeler", paste0(onayli, ".yeni.txt")))]
if (length(bekleyen) > 0) {
  message("Yeni sürümü bekleyen (", length(bekleyen), ") ödev gönderilmeyecek; .yeni.txt dosyalarını ",
          "karara bağlayıp silin: ", paste(bekleyen, collapse = ", "))
  onayli <- setdiff(onayli, bekleyen)
}
if (length(onayli) == 0) stop("Gönderilebilecek ödev yok.")
yonergeler <- vapply(onayli, function(id) txt_oku(file.path(AYAR$veri_dizini, "yonergeler", paste0(id, ".txt"))), "")
bos <- !nzchar(trimws(yonergeler))
if (any(bos)) {
  message("Boş yönerge, atlanıyor: ", paste(onayli[bos], collapse = ", "))
  yonergeler <- yonergeler[!bos]
}

# İş listesi: ödev x tekrar, rastgele sırada ----------------------------------------
# Sıra rastgeleleştirilir: çağrılar saatlerce sürebilir; olası zaman etkileri
# (sunucu yükü, model güncellemesi) belirli bir ödev grubuyla karışmasın.
isler <- expand.grid(odev_id = names(yonergeler), tekrar = seq_len(AYAR$tekrar_sayisi),
                     stringsAsFactors = FALSE)
set.seed(AYAR$cagri_sirasi_tohumu)
isler <- isler[sample(nrow(isler)), ]

# Daha önce başarıyla tamamlananlar atlanır ------------------------------------------
kayit <- kayitlari_oku(kayit_dizini)
gecerli <- gecerli_cagrilar(kayit, AYAR, yonergeler)
tamam <- paste(gecerli$odev_id, gecerli$tekrar)
yapilacak <- isler[!paste(isler$odev_id, isler$tekrar) %in% tamam, ]
message(nrow(isler) - nrow(yapilacak), " çağrı önceden tamamlanmış; ", nrow(yapilacak), " çağrı yapılacak.")

if (nrow(yapilacak) > 0) {

  # Kaba girdi büyüklüğü (Türkçe metinde 1 token yaklaşık 3 karakter varsayımı) -----
  toplam_karakter <- sum(nchar(yonergeler[yapilacak$odev_id])) +
    nrow(yapilacak) * (nchar(AYAR$sistem_istemi) + nchar(AYAR$kullanici_sablonu))
  message(sprintf("Yaklaşık girdi: %s token; çıktı (akıl yürütme dahil) çağrı başına en çok %s token.",
                  format(round(toplam_karakter / 3), big.mark = ".", decimal.mark = ","),
                  format(AYAR$azami_cikti_token, big.mark = ".", decimal.mark = ",")))
  message("Model: ", AYAR$model, " | uç: ", AYAR$api_ucu,
          " | akıl yürütme: ", AYAR$akil_yurutme_duzeyi %||% "(varsayılan)",
          " | ayrıntılılık: ", AYAR$ayrintililik %||% "(varsayılan)")
  if (interactive()) {
    yanit <- readline("Ücretli API çağrıları başlatılsın mı? (e/h): ")
    if (!tolower(substr(yanit, 1, 1)) %in% c("e", "y")) stop("Kullanıcı tarafından durduruldu.")
  }

  # Ayarların kaydı (yöntem bölümü için) ---------------------------------------------
  oturum <- list(
    baslangic_utc = zaman_damgasi(),
    ayarlar = AYAR[c("api_ucu", "model", "sistem_istemi", "kullanici_sablonu",
                     "akil_yurutme_duzeyi", "ayrintililik", "azami_cikti_token",
                     "sicaklik", "top_p", "seed", "tekrar_sayisi", "cagri_sirasi_tohumu")],
    r_surumu = R.version.string,
    paket_surumleri = vapply(c("httr2", "jsonlite", "xml2", "pdftools", "googledrive"),
                             function(p) tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_), "")
  )
  jsonlite::write_json(oturum, file.path(AYAR$cikti_dizini,
                                         paste0("oturum_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")),
                       auto_unbox = TRUE, pretty = TRUE, null = "null")

  # Çağrılar ---------------------------------------------------------------------------
  # 400/401/403/404 (istek yapısı ya da yetki) ve kota hatası: tüm çağrılar aynı
  # hatayı vereceği için durulur. Ödeve özgü retler (ör. güvenlik filtresi,
  # "api_reddi") ve diğer hatalar kaydedilir, sonraki ödeve geçilir.
  ust_uste_ag_sorunu <- 0
  for (k in seq_len(nrow(yapilacak))) {
    id <- yapilacak$odev_id[k]
    t <- yapilacak$tekrar[k]
    satir <- odev_cagir(id, t, yonergeler[[id]], AYAR, kayit_dizini)

    kayit <- rbind_doldur(list(kayit, satir))
    kopya_yaz(kayit)

    message(sprintf("[%d/%d] %s t%d -> HTTP %s, durum: %s%s (%.0f sn)",
                    k, nrow(yapilacak), id, t, satir$http_durum,
                    satir$durum %||% NA,
                    if (!is.na(satir$hata)) paste0(" | HATA: ", satir$hata) else "",
                    satir$sure_sn))
    # Art arda zaman aşımı ya da ağ hatası: ayar ya da bağlantı sorunu olasıdır.
    # Zaman aşımına uğrayan çağrılar sunucuda ücretlendirilebileceği için durulur.
    ust_uste_ag_sorunu <- if (isTRUE(satir$durum %in% c("zaman_asimi", "ag_hatasi"))) ust_uste_ag_sorunu + 1 else 0
    if (ust_uste_ag_sorunu >= 3) {
      stop("Art arda 3 çağrı zaman aşımına uğradı ya da ağ hatası verdi (son durum: ", satir$durum, "). ",
           "Zaman aşımıysa 00_ayarlar.R'de zaman_asimi_sn'yi artırın (akıl yürütme düzeyi yüksekse üretim ",
           "uzun sürer); ağ hatasıysa bağlantıyı ve taban_url'yi denetleyin. Tamamlanan çağrılar tekrarlanmaz.",
           call. = FALSE)
    }
    if (isTRUE(satir$http_durum == 429) && kota_hatasi_mi(satir$hata)) {
      stop("API kotası/bakiyesi yetersiz (HTTP 429, insufficient_quota). Hesabınıza bakiye ",
           "ekleyip betiği yeniden çalıştırın; tamamlanan çağrılar tekrarlanmaz.")
    }
    if (isTRUE(satir$http_durum %in% c(400, 401, 403, 404)) && !identical(satir$durum, "api_reddi")) {
      stop("API isteği reddetti (HTTP ", satir$http_durum, ", kod: ", satir$hata_kodu, "): ", satir$hata,
           "\nAyarları (model adı, parametreler, anahtar) düzeltip yeniden çalıştırın.")
    }
  }

}

# Özet ---------------------------------------------------------------------------------
# Şu anki ayarlarla yapılan en son çağrıların durumu
son <- kayit[kayit$ayar_sha256 %in% ayar_ozeti(AYAR) & kayit$odev_id %in% names(yonergeler), ]
son <- son[order(son$baslangic_utc), ]
son <- son[!duplicated(son[, c("odev_id", "tekrar")], fromLast = TRUE), ]
message("\nŞu anki ayarlarla son çağrıların durumu:")
print(table(durum = son$durum, useNA = "ifany"))
kesik <- son$odev_id[son$durum %in% "incomplete"]
if (length(kesik) > 0) {
  message("UYARI: ", length(kesik), " çağrı tamamlanmadı (", paste(unique(stats::na.omit(son$eksik_nedeni)), collapse = ", "),
          "): ", paste(kesik, collapse = ", "), ". Bunlar 'YZ tamamlayamadı' olarak KODLANMAMALIDIR; teknik kesintidir. ",
          "Neden max_output_tokens ise azami_cikti_token'ı artırın; ayar değiştiği için betik ",
          "TÜM ödevleri yeniden çağırır (standartlaştırma korunur).")
}
api_reddi <- son[son$durum %in% "api_reddi", ]
if (nrow(api_reddi) > 0) {
  message("API'nin içerik/uzunluk nedeniyle reddettiği ödevler (kodlama formuna alınmaz; ",
          "nasıl raporlanacağına siz karar verin): ",
          paste0(api_reddi$odev_id, " (", api_reddi$hata_kodu, ")", collapse = ", "))
}
diger <- son$odev_id[son$durum %in% c("zaman_asimi", "ag_hatasi", "http_hatasi", "gecersiz_yanit")]
if (length(diger) > 0) message("Hata nedeniyle tamamlanamayan çağrılar (betiği yeniden çalıştırınca yeniden denenir): ",
                               paste(diger, collapse = ", "))
if (any(son$durum %in% "zaman_asimi")) {
  message("Zaman aşımı olan çağrılar var. Yeniden çalıştırmadan önce zaman_asimi_sn'yi artırmanız önerilir; ",
          "aksi hâlde aynı çağrılar yine kesilip yeniden ücretlendirilebilir.")
}
reddedilen <- son$odev_id[!is.na(son$ret) & nzchar(son$ret %||% "")]
if (length(reddedilen) > 0) message("Modelin yanıtında reddettiği çağrılar (formda 'model_reddi' sütunu): ",
                                    paste(reddedilen, collapse = ", "))
message("Sonraki adım: 04_kodlama_formu.R")
