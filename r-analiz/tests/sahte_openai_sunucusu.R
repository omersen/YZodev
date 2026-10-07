# =============================================================================
# Test için sahte OpenAI sunucusu (webfakes). Gerçek API'ye istek GİTMEZ, ücret
# oluşmaz. Yönerge metnindeki işaretlere göre farklı durumlar üretir:
#   TEST429   : ilk istekte 429 (Retry-After: 1), sonrakinde başarı
#   TEST500   : ilk istekte 500, sonrakinde başarı
#   TESTKESIK : status = "incomplete", reason = "max_output_tokens"
#   TESTRET   : modelin reddi (content type = "refusal")
#   TESTFAZ   : önce "commentary", sonra "final_answer" aşamalı iki mesaj
#   TESTFILTRE: 400 invalid_prompt (ödeve özgü güvenlik filtresi)
#   TESTYAVAS : yanıtı 5 sn geciktirir (zaman aşımı denemesi); istek sayısı
#               sayac_dizini/yavas_* dosyalarıyla sayılır
#   model = "gecersiz-model" : 400 hatası
#   model = "kota-yok"       : 429 insufficient_quota (kalıcı)
# =============================================================================

sahte_openai_uygulamasi <- function(sayac_dizini = tempfile("sayac_")) {
  dir.create(sayac_dizini, showWarnings = FALSE)
  app <- webfakes::new_app()
  app$use(webfakes::mw_json())
  app$locals$sayac_dizini <- sayac_dizini

  ilk_kez_mi <- function(app, anahtar) {
    f <- file.path(app$locals$sayac_dizini, anahtar)
    if (file.exists(f)) return(FALSE)
    file.create(f)
    TRUE
  }

  mesaj <- function(metin, faz = NULL) {
    m <- list(id = "msg_1", type = "message", role = "assistant", status = "completed",
              content = list(list(type = "output_text", text = metin, annotations = list())))
    if (!is.null(faz)) m$phase <- faz
    m
  }

  yanit <- function(model, cikti, durum = "completed", neden = NULL) {
    list(
      id = paste0("resp_", as.integer(stats::runif(1, 1, 1e8))),
      object = "response", created_at = 1760000000, status = durum,
      incomplete_details = if (!is.null(neden)) list(reason = neden) else NULL,
      model = paste0(model, "-2026-07-09"),
      output = c(list(list(id = "rs_1", type = "reasoning", summary = list())), cikti),
      usage = list(input_tokens = 500, input_tokens_details = list(cached_tokens = 128),
                   output_tokens = 900, output_tokens_details = list(reasoning_tokens = 400),
                   total_tokens = 1400)
    )
  }

  app$post("/v1/responses", function(req, res) {
    b <- req$json
    girdi <- b$input
    if (!identical(b$store, FALSE)) {
      return(res$set_status(400)$send_json(list(error = list(message = "test: store=false bekleniyordu")), auto_unbox = TRUE))
    }
    if (identical(b$model, "gecersiz-model")) {
      return(res$set_status(400)$send_json(
        list(error = list(message = "The requested model 'gecersiz-model' does not exist.",
                          type = "invalid_request_error", code = "model_not_found")), auto_unbox = TRUE))
    }
    if (identical(b$model, "kota-yok")) {
      return(res$set_status(429)$send_json(
        list(error = list(message = "You exceeded your current quota, please check your plan and billing details.",
                          type = "insufficient_quota", code = "insufficient_quota")), auto_unbox = TRUE))
    }
    if (grepl("TESTFILTRE", girdi)) {
      return(res$set_status(400)$send_json(
        list(error = list(message = "Invalid prompt: your prompt was flagged as potentially violating our usage policy.",
                          type = "invalid_request_error", code = "invalid_prompt")), auto_unbox = TRUE))
    }
    if (grepl("TESTYAVAS", girdi)) {
      file.create(file.path(app$locals$sayac_dizini, paste0("yavas_", length(list.files(app$locals$sayac_dizini, "^yavas_")) + 1)))
      Sys.sleep(5)
    }
    anahtar <- substr(digest::digest(girdi), 1, 12)
    if (grepl("TEST429", girdi) && ilk_kez_mi(app, paste0("429_", anahtar))) {
      return(res$set_status(429)$set_header("Retry-After", "1")$send_json(
        list(error = list(message = "Rate limit reached")), auto_unbox = TRUE))
    }
    if (grepl("TEST500", girdi) && ilk_kez_mi(app, paste0("500_", anahtar))) {
      return(res$set_status(500)$send_json(list(error = list(message = "server error")), auto_unbox = TRUE))
    }
    if (grepl("TESTKESIK", girdi)) {
      return(res$send_json(yanit(b$model, list(), "incomplete", "max_output_tokens"), auto_unbox = TRUE, null = "null"))
    }
    if (grepl("TESTRET", girdi)) {
      ret <- list(id = "msg_r", type = "message", role = "assistant", status = "completed",
                  content = list(list(type = "refusal", refusal = "Bu isteğe yardımcı olamam.")))
      return(res$send_json(yanit(b$model, list(ret)), auto_unbox = TRUE, null = "null"))
    }
    if (grepl("TESTFAZ", girdi)) {
      return(res$send_json(yanit(b$model, list(mesaj("Önce bir plan yapıyorum.", "commentary"),
                                                mesaj("NİHAİ ÖDEV ÇIKTISI", "final_answer"))),
                           auto_unbox = TRUE, null = "null"))
    }
    ozet <- substr(gsub("\\s+", " ", girdi), 1, 80)
    res$send_json(yanit(b$model, list(mesaj(paste0("Ödev çıktısı (sahte): ", ozet, " ğüşıöç")))),
                  auto_unbox = TRUE, null = "null")
  })
  app
}
