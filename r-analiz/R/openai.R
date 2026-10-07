# =============================================================================
# OpenAI API yardımcıları (httr2)
# -----------------------------------------------------------------------------
# Kaynak: OpenAI OpenAPI tanımı (github.com/openai/openai-openapi), Ekim 2026.
# - Responses API: POST /v1/responses. Sistem istemi "instructions" alanına,
#   kullanıcı istemi "input" alanına yazılır. "seed" parametresi YOKTUR.
# - "store" atlanırsa varsayılan TRUE'dur (yanıt OpenAI'de en az 30 gün saklanır);
#   bu nedenle açıkça FALSE gönderilir.
# - Ham JSON'da "output_text" alanı yoktur (yalnızca Python/JS SDK kolaylığıdır);
#   metin output[] içindeki "message" öğelerinden toplanır.
# - previous_response_id / conversation gönderilmediği için her çağrı bağımsızdır.
# =============================================================================

# NULL elemanları atar (API'ye gönderilmeyecek ayarlar NULL bırakılır) --------
bos_olanlari_at <- function(x) {
  x <- Filter(Negate(is.null), x)
  lapply(x, function(e) if (is.list(e)) bos_olanlari_at(e) else e)
}

# Şablondaki {YONERGE} yer tutucusunu doldurur ----------------------------------
# sub()/gsub() kullanılmıyor: yönergede "\\1" gibi ters eğik çizgiler olursa
# değiştirme metni bozulabilir. Yer tutucu tam olarak bir kez geçmelidir.
sablon_doldur <- function(sablon, yonerge, yer_tutucu = "{YONERGE}") {
  parcalar <- strsplit(sablon, yer_tutucu, fixed = TRUE)[[1]]
  adet <- lengths(regmatches(sablon, gregexpr(yer_tutucu, sablon, fixed = TRUE)))
  if (adet != 1) stop("Kullanıcı şablonunda ", yer_tutucu, " tam olarak bir kez geçmeli (", adet, " kez geçiyor).")
  if (length(parcalar) == 1) parcalar <- c(parcalar, "")   # yer tutucu en sondaysa
  paste0(parcalar[1], yonerge, parcalar[2])
}

# İstek gövdesi ------------------------------------------------------------------
istek_govdesi <- function(yonerge, ayar) {
  kullanici <- sablon_doldur(ayar$kullanici_sablonu, yonerge)
  if (ayar$api_ucu == "responses") {
    govde <- list(
      model = ayar$model,
      instructions = ayar$sistem_istemi,
      input = kullanici,
      reasoning = if (!is.null(ayar$akil_yurutme_duzeyi)) list(effort = ayar$akil_yurutme_duzeyi),
      text = if (!is.null(ayar$ayrintililik)) list(verbosity = ayar$ayrintililik),
      max_output_tokens = ayar$azami_cikti_token,
      temperature = ayar$sicaklik,
      top_p = ayar$top_p,
      store = FALSE
    )
  } else if (ayar$api_ucu == "chat") {
    govde <- list(
      model = ayar$model,
      messages = list(
        list(role = ayar$sistem_rolu %||% "developer", content = ayar$sistem_istemi),
        list(role = "user", content = kullanici)
      ),
      reasoning_effort = ayar$akil_yurutme_duzeyi,
      verbosity = ayar$ayrintililik,
      max_completion_tokens = ayar$azami_cikti_token,
      temperature = ayar$sicaklik,
      top_p = ayar$top_p,
      seed = ayar$seed,
      store = FALSE
    )
  } else {
    stop("ayar$api_ucu 'responses' ya da 'chat' olmalı.")
  }
  bos_olanlari_at(govde)
}

api_anahtari <- function() {
  anahtar <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(anahtar)) {
    stop("OPENAI_API_KEY ortam değişkeni tanımlı değil. Anahtarı koda yazmayın; ",
         "~/.Renviron dosyasına OPENAI_API_KEY=... satırını ekleyip R'ı yeniden başlatın ",
         "(usethis::edit_r_environ() bu dosyayı açar).")
  }
  anahtar
}

# httr2 isteği -------------------------------------------------------------------
openai_istegi <- function(govde, ayar) {
  uc <- if (ayar$api_ucu == "responses") "responses" else "chat/completions"
  req <- httr2::request(ayar$taban_url)
  req <- httr2::req_url_path_append(req, uc)
  req <- httr2::req_auth_bearer_token(req, api_anahtari())
  req <- httr2::req_body_json(req, govde, auto_unbox = TRUE)
  req <- httr2::req_timeout(req, ayar$zaman_asimi_sn)
  # HTTP hatalarında R hatası fırlatılmaz; yanıt gövdesi kayda geçirilir.
  httr2::req_error(req, is_error = function(resp) FALSE)
}

# Yeniden deneme -------------------------------------------------------------------
# httr2::req_retry() yerine açık bir döngü kullanılır; davranış httr2 sürümüne
# bağlı kalmasın diye (1.0.0 ile 1.3.0 ağ hatalarında farklı davranıyor).
# - 408, 409, 429, 500, 502, 503, 504: yeniden denenir (OpenAI'nin resmi Python
#   SDK'sıyla aynı küme). Retry-After başlığı varsa ona uyulur, yoksa 2, 4, 8...
#   saniye (en çok 60) beklenir.
# - Kota/bakiye bitti hatası da 429 ile gelir ("insufficient_quota") ama geçici
#   değildir; yeniden denenmez.
# - Zaman aşımı yeniden DENENMEZ: sunucu üretimi bağlantı kopsa da sürdürüp
#   ücretlendirebilir ve store = false olduğundan sonuç geri alınamaz.
# - Bağlantı kopması gibi diğer ağ hataları yeniden denenir.
kota_hatasi_mi <- function(govde_metni) {
  grepl("insufficient_quota|exceeded your current quota", govde_metni %||% "", ignore.case = TRUE)
}

gecici_hata_mi <- function(resp) {
  durum <- httr2::resp_status(resp)
  if (durum == 429) {
    govde <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    if (kota_hatasi_mi(govde)) return(FALSE)
  }
  durum %in% c(408, 409, 429, 500, 502, 503, 504)
}

zaman_asimi_mi <- function(hata) {
  inherits(hata$parent, "curl_error_operation_timedout") ||
    grepl("Timeout was reached|timed out", conditionMessage(hata), ignore.case = TRUE)
}

bekleme_suresi <- function(resp, deneme) {
  ra <- suppressWarnings(as.numeric(httr2::resp_header(resp, "retry-after-ms"))) / 1000
  if (length(ra) == 0 || is.na(ra)) ra <- suppressWarnings(as.numeric(httr2::resp_header(resp, "retry-after")))
  if (length(ra) == 1 && !is.na(ra) && ra >= 0) return(min(ra, 120))
  min(60, 2^deneme)
}

istek_gonder <- function(req, deneme_sayisi, bekle = Sys.sleep) {
  for (deneme in seq_len(deneme_sayisi)) {
    sonuc <- tryCatch(httr2::req_perform(req), error = function(e) e)
    son_deneme <- deneme == deneme_sayisi
    if (inherits(sonuc, "error")) {
      if (zaman_asimi_mi(sonuc) || son_deneme) return(sonuc)
      bekle(min(60, 2^deneme))
      next
    }
    if (!gecici_hata_mi(sonuc) || son_deneme) return(sonuc)
    bekle(bekleme_suresi(sonuc, deneme))
  }
}

# Ödeve özgü (tüm çalışmayı durdurmaması gereken) API ret kodları: güvenlik
# filtresi ya da bu yönergenin aşırı uzunluğu gibi. Diğer 400 hataları (ör.
# geçersiz parametre, bilinmeyen model) bütün çağrılarda yineleneceği için
# 03_yz_cagri.R çalışmayı durdurur.
ODEVE_OZGU_HATA_KODLARI <- c("invalid_prompt", "bio_policy", "misalignment_policy_violation",
                             "content_policy_violation", "content_filter",
                             "context_length_exceeded", "string_above_max_length")

# Tüm üretim ayarlarının özeti ---------------------------------------------------
# Yönerge yerine yer tutucu konarak oluşturulan istek gövdesinin özeti: model,
# sistem istemi, şablon, akıl yürütme düzeyi, ayrıntılılık, token sınırı,
# sıcaklık vb. herhangi biri değişirse özet değişir ve bütün ödevler yeniden
# çağrılır. Böylece farklı ayarlarla üretilmiş çıktılar analizde karışmaz.
ayar_ozeti <- function(ayar) {
  sha256(as.character(jsonlite::toJSON(
    list(api_ucu = ayar$api_ucu, govde = istek_govdesi("{YONERGE}", ayar)),
    auto_unbox = TRUE, digits = NA)))
}

# Yanıt ayrıştırma ---------------------------------------------------------------
yanit_ayristir <- function(j, api_ucu) {
  bos <- function(x) if (is.null(x)) NA else x
  if (api_ucu == "responses") {
    mesajlar <- Filter(function(o) identical(o$type, "message"), j$output %||% list())
    # GPT-5.x bazı durumlarda ara "commentary" mesajları üretebilir; nihai yanıt
    # "final_answer" olarak etiketliyse yalnızca o alınır.
    nihai <- Filter(function(m) identical(m$phase, "final_answer"), mesajlar)
    if (length(nihai) > 0) mesajlar <- nihai
    metin <- character(0)
    ret <- character(0)
    for (m in mesajlar) for (k in m$content %||% list()) {
      if (identical(k$type, "output_text")) metin <- c(metin, k$text)
      if (identical(k$type, "refusal")) ret <- c(ret, k$refusal)
    }
    list(
      yanit_id = bos(j$id),
      model_yanit = bos(j$model),
      durum = bos(j$status),
      eksik_nedeni = bos(j$incomplete_details$reason),
      cikti = paste(metin, collapse = "\n\n"),
      ret = paste(ret, collapse = "\n"),
      girdi_token = bos(j$usage$input_tokens),
      onbellek_token = bos(j$usage$input_tokens_details$cached_tokens),
      cikti_token = bos(j$usage$output_tokens),
      akil_yurutme_token = bos(j$usage$output_tokens_details$reasoning_tokens),
      sistem_parmak_izi = NA
    )
  } else {
    sec <- (j$choices %||% list(list()))[[1]]
    bitis <- bos(sec$finish_reason)
    list(
      yanit_id = bos(j$id),
      model_yanit = bos(j$model),
      # Chat Completions'ta "completed" karşılığı finish_reason = "stop"tur.
      durum = if (identical(bitis, "stop")) "completed" else "incomplete",
      eksik_nedeni = if (identical(bitis, "stop")) NA else bitis,
      cikti = sec$message$content %||% "",
      ret = sec$message$refusal %||% "",
      girdi_token = bos(j$usage$prompt_tokens),
      onbellek_token = bos(j$usage$prompt_tokens_details$cached_tokens),
      cikti_token = bos(j$usage$completion_tokens),
      akil_yurutme_token = bos(j$usage$completion_tokens_details$reasoning_tokens),
      sistem_parmak_izi = bos(j$system_fingerprint)
    )
  }
}

sha256 <- function(x) digest::digest(enc2utf8(x), algo = "sha256", serialize = FALSE)

# Geçerli çağrılar ---------------------------------------------------------------
# Bir çağrı, ŞU ANKİ ayarlarla (ayar_ozeti) ve ŞU ANKİ yönerge metniyle yapılmış
# ve tamamlanmışsa geçerlidir. Her ödev x tekrar için en son geçerli çağrı
# döndürülür. Farklı ayarla yapılmış ya da başarısız denemeler analize karışmaz.
gecerli_cagrilar <- function(kayit, ayar, yonergeler) {
  if (is.null(kayit) || nrow(kayit) == 0 || is.null(kayit$ayar_sha256)) return(kayit[0, , drop = FALSE])
  yonerge_ozeti <- vapply(yonergeler, sha256, "")
  uygun <- kayit$http_durum %in% 200 & kayit$durum %in% "completed" &
    kayit$ayar_sha256 %in% ayar_ozeti(ayar) &
    kayit$odev_id %in% names(yonergeler)
  uygun[uygun] <- kayit$yonerge_sha256[uygun] == yonerge_ozeti[kayit$odev_id[uygun]]
  g <- kayit[uygun, , drop = FALSE]
  g <- g[order(g$baslangic_utc), , drop = FALSE]
  g[!duplicated(g[, c("odev_id", "tekrar")], fromLast = TRUE), , drop = FALSE]
}

# Çağrı kayıtları -------------------------------------------------------------------
# Her çağrının kayıt satırı, ham yanıtın yanına <dosya_koku>_kayit.json olarak
# yazılır; kaydın asıl kaynağı bu dosyalardır. cagri_kaydi.xlsx yalnızca bunların
# okunabilir bir kopyasıdır; Excel'de açık kalsa bile hiçbir çağrının kaydı kaybolmaz.
kayit_satiri_yaz <- function(satir, dosya_koku) {
  jsonlite::write_json(satir, paste0(dosya_koku, "_kayit.json"), dataframe = "rows",
                       digits = NA, pretty = TRUE)
  invisible(satir)
}

kayitlari_oku <- function(kayit_dizini) {
  dosyalar <- list.files(kayit_dizini, pattern = "_kayit\\.json$", full.names = TRUE)
  if (length(dosyalar) == 0) return(NULL)
  k <- rbind_doldur(lapply(dosyalar, function(f) jsonlite::fromJSON(f, simplifyVector = TRUE)))
  k[order(k$baslangic_utc), , drop = FALSE]
}

# Tek bir ödev için tek çağrı: isteği ve ham yanıtı diske yazar ---------------
# Her çağrının dosyaları benzersiz adla (ödev, tekrar, UTC zaman damgası) yazılır;
# önceki çağrıların kayıtları silinmez. Dosya kökü çağrı kaydına yazılır ve
# 04_kodlama_formu.R çıktıyı bu kökten okur.
# Döndürür: çağrı kaydının bir satırı (data.frame)
odev_cagir <- function(odev_id, tekrar, yonerge, ayar, kayit_dizini) {
  govde <- istek_govdesi(yonerge, ayar)
  baslangic <- Sys.time()
  dosya_koku <- file.path(kayit_dizini, sprintf("%s_t%d_%s", odev_id, tekrar,
                                                gsub("\\.", "", format(baslangic, "%Y%m%dT%H%M%OS3", tz = "UTC"))))
  jsonlite::write_json(govde, paste0(dosya_koku, "_istek.json"),
                       auto_unbox = TRUE, pretty = TRUE, digits = NA)

  sonuc <- istek_gonder(openai_istegi(govde, ayar), ayar$deneme_sayisi)
  bitis <- Sys.time()

  bos_ise_na <- function(x) if (is.null(x)) NA else x
  satir <- data.frame(
    odev_id = odev_id, tekrar = tekrar,
    baslangic_utc = format(baslangic, "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC"),
    sure_sn = round(as.numeric(difftime(bitis, baslangic, units = "secs")), 2),
    dosya_koku = dosya_koku,
    api_ucu = ayar$api_ucu, model_istenen = ayar$model,
    akil_yurutme_duzeyi = bos_ise_na(ayar$akil_yurutme_duzeyi),
    ayrintililik = bos_ise_na(ayar$ayrintililik),
    azami_cikti_token = bos_ise_na(ayar$azami_cikti_token),
    sicaklik = bos_ise_na(ayar$sicaklik), top_p = bos_ise_na(ayar$top_p),
    ayar_sha256 = ayar_ozeti(ayar),
    yonerge_sha256 = sha256(yonerge),
    sistem_istemi_sha256 = sha256(ayar$sistem_istemi),
    sablon_sha256 = sha256(ayar$kullanici_sablonu),
    http_durum = NA_integer_, hata_kodu = NA_character_, hata = NA_character_,
    stringsAsFactors = FALSE
  )

  if (inherits(sonuc, "error")) {
    satir$durum <- if (zaman_asimi_mi(sonuc)) "zaman_asimi" else "ag_hatasi"
    satir$hata <- xml_guvenli(conditionMessage(sonuc))
    return(kayit_satiri_yaz(satir, dosya_koku))
  }
  satir$http_durum <- httr2::resp_status(sonuc)
  # Ağ geçidi hatalarında (ör. 502) gövde boş olabilir; bu, çalışmayı durdurmamalı.
  ham <- tryCatch(httr2::resp_body_string(sonuc), error = function(e) "")
  txt_yaz(ham, paste0(dosya_koku, "_yanit.json"))
  j <- tryCatch(jsonlite::fromJSON(ham, simplifyVector = FALSE), error = function(e) NULL)

  if (satir$http_durum != 200) {
    satir$hata_kodu <- as.character(j$error$code %||% j$error$type %||% NA)
    satir$hata <- xml_guvenli(j$error$message %||% if (nzchar(ham)) substr(ham, 1, 500) else "(boş yanıt)")
    satir$durum <- if (satir$hata_kodu %in% ODEVE_OZGU_HATA_KODLARI) "api_reddi" else "http_hatasi"
    return(kayit_satiri_yaz(satir, dosya_koku))
  }
  if (is.null(j)) {
    satir$durum <- "gecersiz_yanit"
    satir$hata <- "HTTP 200 ama yanıt gövdesi çözümlenemedi (ham yanıt _yanit.json dosyasında)."
    return(kayit_satiri_yaz(satir, dosya_koku))
  }
  a <- yanit_ayristir(j, ayar$api_ucu)
  txt_yaz(a$cikti, paste0(dosya_koku, "_cikti.txt"))
  satir <- cbind(satir, as.data.frame(a[setdiff(names(a), "cikti")], stringsAsFactors = FALSE),
                 cikti_karakter = nchar(a$cikti))
  kayit_satiri_yaz(satir, dosya_koku)
}
