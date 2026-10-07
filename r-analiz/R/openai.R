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
# Yeniden deneme: OpenAI'nin resmi Python SDK'sı 408, 409, 429 ve 5xx kodlarını
# yeniden dener; httr2 varsayılan olarak yalnızca 429 ve 503'ü dener. Aynı küme
# burada açıkça verilir. Retry-After başlığı httr2 tarafından dikkate alınır.
# Kota/bakiye bitti hatası da 429 ile gelir ("insufficient_quota") ama geçici
# değildir; yeniden denemek yalnızca zaman kaybettirir.
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

openai_istegi <- function(govde, ayar) {
  uc <- if (ayar$api_ucu == "responses") "responses" else "chat/completions"
  retry_args <- list(max_tries = ayar$deneme_sayisi, is_transient = gecici_hata_mi)
  # retry_on_failure bağımsız değişkeni httr2 1.1.0 ile geldi; eski sürümde atlanır.
  if ("retry_on_failure" %in% names(formals(httr2::req_retry))) {
    retry_args$retry_on_failure <- TRUE
  }
  req <- httr2::request(ayar$taban_url)
  req <- httr2::req_url_path_append(req, uc)
  req <- httr2::req_auth_bearer_token(req, api_anahtari())
  req <- httr2::req_body_json(req, govde, auto_unbox = TRUE)
  req <- httr2::req_timeout(req, ayar$zaman_asimi_sn)
  req <- do.call(httr2::req_retry, c(list(req), retry_args))
  # HTTP hatalarında R hatası fırlatılmaz; yanıt gövdesi kayda geçirilir.
  httr2::req_error(req, is_error = function(resp) FALSE)
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
# Bir çağrı, ŞU ANKİ ayarlarla (model, sistem istemi, şablon) ve ŞU ANKİ yönerge
# metniyle yapılmış ve tamamlanmışsa geçerlidir. Her ödev x tekrar için en son
# geçerli çağrı döndürülür. Böylece farklı ayarla yapılmış eski ya da başarısız
# denemeler analize karışmaz.
gecerli_cagrilar <- function(kayit, ayar, yonergeler) {
  if (is.null(kayit) || nrow(kayit) == 0) return(kayit)
  yonerge_ozeti <- vapply(yonergeler, sha256, "")
  uygun <- kayit$http_durum %in% 200 & kayit$durum %in% "completed" &
    kayit$model_istenen %in% ayar$model &
    kayit$sistem_istemi_sha256 %in% sha256(ayar$sistem_istemi) &
    kayit$sablon_sha256 %in% sha256(ayar$kullanici_sablonu) &
    kayit$odev_id %in% names(yonergeler)
  uygun[uygun] <- kayit$yonerge_sha256[uygun] == yonerge_ozeti[kayit$odev_id[uygun]]
  g <- kayit[uygun, , drop = FALSE]
  g <- g[order(g$baslangic_utc), , drop = FALSE]
  g[!duplicated(g[, c("odev_id", "tekrar")], fromLast = TRUE), , drop = FALSE]
}

# Tek bir ödev için tek çağrı: isteği ve ham yanıtı diske yazar ---------------
# Döndürür: çağrı kaydının bir satırı (data.frame)
odev_cagir <- function(odev_id, tekrar, yonerge, ayar, kayit_dizini) {
  govde <- istek_govdesi(yonerge, ayar)
  dosya_koku <- file.path(kayit_dizini, sprintf("%s_t%d", odev_id, tekrar))
  jsonlite::write_json(govde, paste0(dosya_koku, "_istek.json"),
                       auto_unbox = TRUE, pretty = TRUE)

  baslangic <- Sys.time()
  sonuc <- tryCatch(httr2::req_perform(openai_istegi(govde, ayar)),
                    error = function(e) e)
  bitis <- Sys.time()

  satir <- data.frame(
    odev_id = odev_id, tekrar = tekrar,
    baslangic_utc = format(baslangic, "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC"),
    sure_sn = round(as.numeric(difftime(bitis, baslangic, units = "secs")), 2),
    api_ucu = ayar$api_ucu, model_istenen = ayar$model,
    yonerge_sha256 = sha256(yonerge),
    sistem_istemi_sha256 = sha256(ayar$sistem_istemi),
    sablon_sha256 = sha256(ayar$kullanici_sablonu),
    http_durum = NA_integer_, hata = NA_character_,
    stringsAsFactors = FALSE
  )

  if (inherits(sonuc, "error")) {
    satir$hata <- conditionMessage(sonuc)
    return(satir)
  }
  satir$http_durum <- httr2::resp_status(sonuc)
  ham <- httr2::resp_body_string(sonuc)
  txt_yaz(ham, paste0(dosya_koku, "_yanit.json"))

  if (satir$http_durum != 200) {
    j <- tryCatch(jsonlite::fromJSON(ham, simplifyVector = FALSE), error = function(e) NULL)
    satir$hata <- j$error$message %||% substr(ham, 1, 500)
    return(satir)
  }
  j <- jsonlite::fromJSON(ham, simplifyVector = FALSE)
  a <- yanit_ayristir(j, ayar$api_ucu)
  txt_yaz(a$cikti, paste0(dosya_koku, "_cikti.txt"))
  cbind(satir, as.data.frame(a[setdiff(names(a), "cikti")], stringsAsFactors = FALSE),
        cikti_karakter = nchar(a$cikti))
}
