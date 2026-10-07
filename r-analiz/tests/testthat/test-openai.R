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

test_that("geçerli çağrı seçimi: farklı ayar, değişen yönerge ve başarısız deneme elenir", {
  y <- c(O1 = "bir", O2 = "iki", O3 = "üç")
  satir <- function(id, zaman, a = ayar, yon = y[[id]], http = 200, durum = "completed")
    data.frame(odev_id = id, tekrar = 1, baslangic_utc = zaman, ayar_sha256 = ayar_ozeti(a),
               yonerge_sha256 = sha256(yon), http_durum = http, durum = durum)
  kayit <- rbind(satir("O1", "2026-10-01T10:00"),
                 satir("O1", "2026-10-01T11:00", a = modifyList(ayar, list(model = "x")), http = 400, durum = "http_hatasi"),
                 satir("O2", "2026-10-01T10:00", yon = "eski metin"),
                 satir("O3", "2026-10-01T09:00"), satir("O3", "2026-10-01T12:00"))
  g <- gecerli_cagrilar(kayit, ayar, y)
  expect_equal(sort(g$odev_id), c("O1", "O3"))
  expect_equal(g$baslangic_utc[g$odev_id == "O3"], "2026-10-01T12:00")
  # Herhangi bir üretim ayarı değişirse hiçbir eski çağrı geçerli sayılmaz
  expect_equal(nrow(gecerli_cagrilar(kayit, modifyList(ayar, list(azami_cikti_token = 64000)), y)), 0)
  expect_equal(nrow(gecerli_cagrilar(kayit, modifyList(ayar, list(akil_yurutme_duzeyi = "high")), y)), 0)
  expect_equal(nrow(gecerli_cagrilar(kayit, modifyList(ayar, list(sistem_istemi = "başka")), y)), 0)
})

test_that("yeniden deneme: geçici hatada bekler, kalıcı hatada ve zaman aşımında durur", {
  sayac <- 0
  yanitlar <- list(httr2::response(429, headers = list(`Retry-After` = "7")), httr2::response(500),
                   httr2::response(200, body = charToRaw("{}")))
  bekleyisler <- c()
  httr2::local_mocked_responses(function(req) { sayac <<- sayac + 1; yanitlar[[sayac]] })
  r <- istek_gonder(httr2::req_error(httr2::request("https://ornek.test"), is_error = function(x) FALSE),
                    5, bekle = function(s) bekleyisler <<- c(bekleyisler, s))
  expect_equal(httr2::resp_status(r), 200)
  expect_equal(bekleyisler, c(7, 4))   # Retry-After'a uyuldu, sonra üstel bekleme
  kota <- httr2::response(429, body = charToRaw('{"error":{"code":"insufficient_quota"}}'))
  expect_false(gecici_hata_mi(kota))
  expect_false(gecici_hata_mi(httr2::response(400)))
  expect_true(zaman_asimi_mi(simpleError("Timeout was reached: Operation timed out after 600001 ms")))
})

test_that("anahtar yoksa açık hata verilir", {
  withr::local_envvar(OPENAI_API_KEY = "")
  expect_error(api_anahtari(), "Renviron")
})

test_that("çağrı kaydı JSON'dan eksiksiz geri okunur (NA, Türkçe metin, farklı sütunlar)", {
  d <- tempfile("kayit_"); dir.create(d)
  s1 <- data.frame(odev_id = "O1", tekrar = 1, baslangic_utc = "2026-10-01T10:00:00.000Z",
                   http_durum = 200L, durum = "completed", ret = "", hata = NA_character_, sure_sn = 12.25)
  s2 <- data.frame(odev_id = "O2", tekrar = 1, baslangic_utc = "2026-10-01T09:00:00.000Z",
                   http_durum = NA_integer_, durum = "zaman_asimi", hata = "Zaman aşımı: ğüşıöç")
  kayit_satiri_yaz(s1, file.path(d, "O1_t1_a")); kayit_satiri_yaz(s2, file.path(d, "O2_t1_b"))
  k <- kayitlari_oku(d)
  expect_equal(k$odev_id, c("O2", "O1"))             # zamana göre sıralı
  expect_equal(k$hata[1], "Zaman aşımı: ğüşıöç")
  expect_true(is.na(k$http_durum[1])); expect_equal(k$http_durum[2], 200)
  expect_equal(k$ret[2], ""); expect_true(is.na(k$ret[1]))
  expect_equal(k$sure_sn[2], 12.25)
  expect_null(kayitlari_oku(tempfile()))
})

test_that("Excel dosyası yazılamazsa sessizce geçmez, açık hata verir", {
  skip_if_not_installed("openxlsx")
  expect_error(xlsx_yaz(data.frame(a = 1), file.path(tempfile(), "yok", "x.xlsx")), "yazılamadı")
})

test_that("boş gövdeli 502 ve bozuk JSON çalışmayı durdurmaz, kayda geçer", {
  withr::local_envvar(OPENAI_API_KEY = "test")
  d <- tempfile("kayit_"); dir.create(d)
  a <- modifyList(ayar, list(taban_url = "https://ornek.test/v1", deneme_sayisi = 1, zaman_asimi_sn = 5))
  httr2::local_mocked_responses(function(req) httr2::response(502))
  s <- odev_cagir("O1", 1, "Yönerge", a, d)
  expect_equal(s$durum, "http_hatasi"); expect_equal(s$http_durum, 502); expect_equal(s$hata, "(boş yanıt)")
  httr2::local_mocked_responses(function(req) httr2::response(200, headers = list(`Content-Type` = "application/json"),
                                                               body = charToRaw("{bozuk")))
  s2 <- odev_cagir("O2", 1, "Yönerge", a, d)
  expect_equal(s2$durum, "gecersiz_yanit")
  expect_equal(nrow(kayitlari_oku(d)), 2)
})

test_that("hata metinlerinden ANSI renk kodları ve XML'de geçersiz karakterler atılır", {
  x <- "Failed.\n\033[1mCaused by\033[22m \033[33m!\033[39m Timeout\x0c ğüş"
  expect_equal(xml_guvenli(x), "Failed.\nCaused by ! Timeout ğüş")
  expect_equal(xml_guvenli(3), 3)
})
