# googledrive işlevleri sahte yanıtlarla değiştirilir; ağa bağlanılmaz.
kaynak <- function(id, ad, mime, md5 = NULL)
  list(kind = "drive#file", id = id, name = ad, mimeType = mime, md5Checksum = md5,
       size = "100", modifiedTime = "2026-03-01T10:00:00.000Z")
dribble_yap <- function(...) googledrive::as_dribble(list(...))

agac <- list(
  kok = dribble_yap(kaynak("f1", "Ali - odev.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "aaa"),
                    kaynak("d1", "Soru 1 (File responses)", MIME_KLASOR),
                    kaynak("s1", "kısayol", MIME_KISAYOL),
                    kaynak("s2", "kopuk kısayol", MIME_KISAYOL)),
  d1 = dribble_yap(kaynak("f2", "Ayşe - ödev.pdf", "application/pdf", "bbb"),
                   kaynak("g1", "Veli ödev", MIME_GDOC),
                   kaynak("d2", "İç klasör", MIME_KLASOR)),
  d2 = dribble_yap(kaynak("f3", "ek.doc", "application/msword", "aaa"),
                   kaynak("s3", "üst klasöre kısayol", MIME_KISAYOL),
                   kaynak("t1", "gecici_donusum_f9", MIME_GDOC))
)

test_that("klasör ağacı dolaşılır, alt klasör yolu kaydedilir, kısayollar çözülür", {
  skip_if_not_installed("googledrive")
  local_mocked_bindings(
    drive_ls = function(path, ...) {
      id <- googledrive::as_dribble(path)$id
      if (id %in% names(agac)) agac[[id]] else googledrive::as_dribble(list())
    },
    shortcut_resolve = function(file) {
      hedef <- list(s1 = kaynak("f2", "Ayşe - ödev.pdf", "application/pdf", "bbb"),   # zaten listelenen dosya
                    s2 = list(kind = "drive#file", id = "yok", name = NA_character_, mimeType = NA_character_),
                    s3 = kaynak("d1", "Soru 1 (File responses)", MIME_KLASOR))          # döngü
      out <- googledrive::as_dribble(unname(hedef[file$id]))
      out$name_shortcut <- file$name; out$id_shortcut <- file$id
      out$name[file$id == "s2"] <- NA
      out
    },
    .package = "googledrive"
  )
  expect_message(e <- drive_klasor_tara(dribble_yap(kaynak("kok", "Ödevler", MIME_KLASOR))), "kopuk kısayol")
  expect_setequal(e$drive_id, c("f1", "f2", "g1", "f3"))
  expect_equal(e$alt_klasor[e$drive_id == "f3"], "Soru 1 (File responses)/İç klasör")
  expect_equal(e$alt_klasor[e$drive_id == "f1"], "")
  expect_equal(dosya_uzantisi(e$ad, e$mime_turu)[e$drive_id == "g1"], "gdoc")
  expect_equal(sum(e$md5 == "aaa", na.rm = TRUE), 2)   # yinelenen içerik sonradan işaretlenebilir
})

test_that("Drive bağlantı biçimlerinden kimlik ayıklanır", {
  skip_if_not_installed("googledrive")
  expect_equal(as.character(drive_kimligi("https://drive.google.com/drive/folders/1AbC_d-9xyz?usp=sharing")), "1AbC_d-9xyz")
  expect_equal(as.character(drive_kimligi("https://drive.google.com/drive/u/0/folders/1AbC_d-9xyz")), "1AbC_d-9xyz")
  expect_equal(as.character(drive_kimligi("https://drive.google.com/open?id=1AbC_d-9xyz")), "1AbC_d-9xyz")
  expect_equal(as.character(drive_kimligi(" 1AbC_d-9xyz ")), "1AbC_d-9xyz")
  expect_error(drive_kimligi("https://drive.google.com/drive/my-drive"), "tanınmadı")
})

test_that("uzantı addan, tanınmazsa MIME türünden çıkarılır", {
  expect_equal(dosya_uzantisi(c("Ahmet Yılmaz ödev", "Ödev 1.5", "a.DOCX", "Veli ödev", "x.doc"),
                              c("application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                "application/vnd.openxmlformats-officedocument.wordprocessingml.document", MIME_GDOC,
                                "application/msword")),
               c("pdf", "docx", "docx", "gdoc", "doc"))
})

test_that("başarısız indirmede hata gövdesi asıl dosya adıyla kalmaz", {
  skip_if_not_installed("googledrive")
  hedef <- file.path(tempfile("ham_"), "O002.docx"); dir.create(dirname(hedef))
  local_mocked_bindings(
    drive_download = function(file, path, type = NULL, overwrite = FALSE, ...) {
      writeLines('{"error":{"code":403}}', path); stop("Download failed.")
    }, .package = "googledrive")
  expect_error(drive_dosya_indir("x", hedef, "application/pdf"), "Download failed")
  expect_false(file.exists(hedef))
  expect_length(list.files(dirname(hedef)), 0)
})

test_that("Google Dokümanı docx olarak indirilir ve asıl adına taşınır", {
  skip_if_not_installed("googledrive")
  hedef <- file.path(tempfile("ham_"), "O003.docx"); dir.create(dirname(hedef))
  local_mocked_bindings(
    drive_download = function(file, path, type = NULL, overwrite = FALSE, ...) {
      yol <- paste0(path, ".", type)          # googledrive'ın uzantı ekleme davranışı
      writeLines("docx", yol); invisible(data.frame(local_path = yol))
    }, .package = "googledrive")
  drive_dosya_indir("x", hedef, MIME_GDOC)
  expect_true(file.exists(hedef))
  expect_equal(list.files(dirname(hedef)), "O003.docx")
  expect_error(drive_dosya_indir("x", hedef, "application/vnd.google-apps.spreadsheet"), "desteklenmiyor")
})
