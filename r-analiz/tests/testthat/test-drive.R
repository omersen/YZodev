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
                   kaynak("s3", "üst klasöre kısayol", MIME_KISAYOL))
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

test_that("paylaşım bağlantısındaki sorgu kısmı atılır", {
  skip_if_not_installed("googledrive")
  expect_equal(as.character(drive_kimligi("https://drive.google.com/drive/folders/1AbC_d-9?usp=sharing")), "1AbC_d-9")
  expect_equal(as.character(drive_kimligi(" 1AbC_d-9 ")), "1AbC_d-9")
})
