ayar <- list(api_ucu = "responses", model = "gpt-5.6-sol", sistem_istemi = "SİSTEM",
             kullanici_sablonu = "Ödevi yap:\n{YONERGE}\nSON", akil_yurutme_duzeyi = "medium",
             ayrintililik = NULL, azami_cikti_token = 1000, sicaklik = NULL, top_p = NULL, seed = NULL)

test_that("Responses gövdesi: NULL ayarlar gönderilmez, store = FALSE", {
  g <- istek_govdesi("Yönerge", ayar)
  expect_equal(g$instructions, "SİSTEM")
  expect_equal(g$input, "Ödevi yap:\nYönerge\nSON")
  expect_equal(g$reasoning$effort, "medium")
  expect_false(g$store)
  expect_null(g$text); expect_null(g$temperature); expect_null(g$seed)
  j <- jsonlite::toJSON(g, auto_unbox = TRUE)
  expect_false(grepl("null", j))
})

test_that("Chat gövdesi: developer rolü, max_completion_tokens", {
  a <- modifyList(ayar, list(api_ucu = "chat", sicaklik = 0, seed = 42))
  g <- istek_govdesi("Y", a)
  expect_equal(g$messages[[1]]$role, "developer")
  expect_equal(g$messages[[2]]$content, "Ödevi yap:\nY\nSON")
  expect_equal(g$max_completion_tokens, 1000)
  expect_equal(g$temperature, 0); expect_equal(g$seed, 42)
})

test_that("şablon doldurma ters eğik çizgi ve özel karakterleri bozmaz", {
  y <- "Formül: \\1 ve $x$ ve \\\\n {başka}"
  expect_equal(sablon_doldur("A {YONERGE} B", y), paste0("A ", y, " B"))
  expect_equal(sablon_doldur("{YONERGE}", y), y)
  expect_error(sablon_doldur("A", y), "tam olarak bir kez")
  expect_error(sablon_doldur("{YONERGE}{YONERGE}", y), "tam olarak bir kez")
})

test_that("Responses yanıtı: reasoning öğesi atlanır, final_answer seçilir, ret ayrı tutulur", {
  j <- list(id = "resp_1", model = "gpt-5.6-sol-2026-07-09", status = "completed",
            output = list(
              list(type = "reasoning", summary = list()),
              list(type = "message", phase = "commentary", content = list(list(type = "output_text", text = "ara"))),
              list(type = "message", phase = "final_answer", content = list(list(type = "output_text", text = "SON METİN")))),
            usage = list(input_tokens = 10, output_tokens = 20, output_tokens_details = list(reasoning_tokens = 5),
                         input_tokens_details = list(cached_tokens = 0)))
  a <- yanit_ayristir(j, "responses")
  expect_equal(a$cikti, "SON METİN")
  expect_equal(a$akil_yurutme_token, 5)
  expect_true(is.na(a$eksik_nedeni))
  j2 <- list(status = "completed", output = list(list(type = "message",
             content = list(list(type = "refusal", refusal = "Yapamam")))))
  a2 <- yanit_ayristir(j2, "responses")
  expect_equal(a2$cikti, ""); expect_equal(a2$ret, "Yapamam")
  j3 <- list(status = "incomplete", incomplete_details = list(reason = "max_output_tokens"), output = list())
  expect_equal(yanit_ayristir(j3, "responses")$eksik_nedeni, "max_output_tokens")
})

test_that("Chat yanıtı: finish_reason = length kesik sayılır", {
  j <- list(id = "c1", model = "m", choices = list(list(finish_reason = "length",
            message = list(content = "yarım"))), usage = list(prompt_tokens = 1, completion_tokens = 2))
  a <- yanit_ayristir(j, "chat")
  expect_equal(a$durum, "incomplete"); expect_equal(a$eksik_nedeni, "length"); expect_equal(a$cikti, "yarım")
})

test_that("geçerli çağrı seçimi: farklı model, değişen yönerge ve başarısız deneme elenir", {
  y <- c(O1 = "bir", O2 = "iki", O3 = "üç")
  satir <- function(id, zaman, model = "gpt-5.6-sol", yon = y[[id]], http = 200, durum = "completed")
    data.frame(odev_id = id, tekrar = 1, baslangic_utc = zaman, model_istenen = model,
               yonerge_sha256 = sha256(yon), sistem_istemi_sha256 = sha256(ayar$sistem_istemi),
               sablon_sha256 = sha256(ayar$kullanici_sablonu), http_durum = http, durum = durum)
  kayit <- rbind(satir("O1", "2026-10-01T10:00"), satir("O1", "2026-10-01T11:00", model = "x", http = 400, durum = NA),
                 satir("O2", "2026-10-01T10:00", yon = "eski metin"),
                 satir("O3", "2026-10-01T09:00"), satir("O3", "2026-10-01T12:00"))
  g <- gecerli_cagrilar(kayit, ayar, y)
  expect_equal(sort(g$odev_id), c("O1", "O3"))
  expect_equal(g$baslangic_utc[g$odev_id == "O3"], "2026-10-01T12:00")
})

test_that("anahtar yoksa açık hata verilir", {
  withr::local_envvar(OPENAI_API_KEY = "")
  expect_error(api_anahtari(), "Renviron")
})
