# docx içine ham WordprocessingML ekleyerek zor durumları üretir.
docx_ekle <- function(xml_parcasi, dipnot = NULL) {
  skip_if_not_installed("officer")
  skip_if_not_installed("zip")
  temel <- tempfile(fileext = ".docx")
  d <- officer::read_docx()
  d <- officer::body_add_par(d, "Başlangıç paragrafı.")
  print(d, target = temel)
  dizin <- tempfile("docx_")
  utils::unzip(temel, exdir = dizin)
  yol <- file.path(dizin, "word", "document.xml")
  x <- paste(readLines(yol, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  gerekli <- c(m = "http://schemas.openxmlformats.org/officeDocument/2006/math",
               mc = "http://schemas.openxmlformats.org/markup-compatibility/2006",
               wps = "http://schemas.microsoft.com/office/word/2010/wordprocessingShape")
  eksik <- gerekli[!vapply(names(gerekli), function(p) grepl(paste0("xmlns:", p, "="), x, fixed = TRUE), logical(1))]
  if (length(eksik) > 0) {
    x <- sub("<w:document ", paste0("<w:document ", paste0("xmlns:", names(eksik), '="', eksik, '" ', collapse = "")),
             x, fixed = TRUE)
  }
  x <- sub("<w:sectPr", paste0(xml_parcasi, "<w:sectPr"), x, fixed = TRUE)
  txt_yaz(x, yol)
  if (!is.null(dipnot)) {
    txt_yaz(paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
                   '<w:footnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">',
                   '<w:footnote w:type="separator" w:id="-1"><w:p><w:r><w:t>AYIRICI</w:t></w:r></w:p></w:footnote>',
                   '<w:footnote w:id="1"><w:p><w:r><w:t>', dipnot, '</w:t></w:r></w:p></w:footnote>',
                   '</w:footnotes>'), file.path(dizin, "word", "footnotes.xml"))
  }
  cikti <- tempfile(fileext = ".docx")
  zip::zipr(cikti, list.files(dizin, full.names = TRUE, all.files = TRUE, no.. = TRUE))
  cikti
}

test_that("metin kutusu bir kez ve DrawingML yedeği olmadan okunur", {
  f <- docx_ekle(paste0(
    '<w:p><w:r><w:t>Ana paragraf.</w:t></w:r><w:r><mc:AlternateContent>',
    '<mc:Choice Requires="wps"><w:drawing><wps:wsp><wps:txbx><w:txbxContent>',
    '<w:p><w:r><w:t>KUTU İÇİ METİN</w:t></w:r></w:p></w:txbxContent></wps:txbx></wps:wsp></w:drawing></mc:Choice>',
    '<mc:Fallback><w:pict><w:txbxContent><w:p><w:r><w:t>KUTU İÇİ METİN</w:t></w:r></w:p></w:txbxContent></w:pict></mc:Fallback>',
    '</mc:AlternateContent></w:r></w:p>'))
  r <- docx_metin_cikar(f)
  expect_equal(lengths(regmatches(r$metin, gregexpr("KUTU İÇİ METİN", r$metin))), 1)
  expect_match(r$metin, "Ana paragraf.\n[Metin kutusu] KUTU İÇİ METİN", fixed = TRUE)
  expect_equal(r$bilgi$metin_kutusu_sayisi, 1)
})

test_that("tablo satır satır, hücreler ' | ' ile ayrılarak okunur", {
  f <- docx_ekle(paste0(
    '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Gün</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>Ölçüm</w:t></w:r></w:p></w:tc></w:tr>',
    '<w:tr><w:tc><w:p><w:r><w:t>Pazartesi</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>12 L</w:t></w:r></w:p></w:tc></w:tr></w:tbl>'))
  expect_match(docx_metin_cikar(f)$metin, "Gün | Ölçüm\nPazartesi | 12 L", fixed = TRUE)
})

test_that("denklem doğrusal yazılır; kesir bitişik okunmaz", {
  f <- docx_ekle(paste0(
    '<w:p><w:r><w:t xml:space="preserve">Hesapla: </w:t></w:r><m:oMath>',
    '<m:f><m:num><m:r><m:t>1</m:t></m:r></m:num><m:den><m:r><m:t>2</m:t></m:r></m:den></m:f>',
    '<m:r><m:t>+</m:t></m:r><m:sSup><m:e><m:r><m:t>x</m:t></m:r></m:e><m:sup><m:r><m:t>2</m:t></m:r></m:sup></m:sSup>',
    '</m:oMath></w:p>'))
  r <- docx_metin_cikar(f)
  expect_match(r$metin, "Hesapla: (1)/(2)+x^(2)", fixed = TRUE)
  expect_equal(r$bilgi$denklem_sayisi, 1)
})

test_that("izlenen değişikliklerde silinen metin alınmaz, eklenen alınır; içerik denetimi okunur", {
  f <- docx_ekle(paste0(
    '<w:p><w:r><w:t>Kalan</w:t></w:r><w:del><w:r><w:delText> SİLİNEN</w:delText></w:r></w:del>',
    '<w:ins><w:r><w:t xml:space="preserve"> eklenen</w:t></w:r></w:ins></w:p>',
    '<w:sdt><w:sdtContent><w:p><w:r><w:t>Denetim içi</w:t></w:r></w:p></w:sdtContent></w:sdt>'))
  r <- docx_metin_cikar(f)
  expect_match(r$metin, "Kalan eklenen", fixed = TRUE)
  expect_false(grepl("SİLİNEN", r$metin))
  expect_match(r$metin, "Denetim içi", fixed = TRUE)
})

test_that("dipnot eklenir, ayırıcı not eklenmez", {
  f <- docx_ekle('<w:p><w:r><w:t>Metin</w:t></w:r></w:p>', dipnot = "Kaynak: TÜİK")
  r <- docx_metin_cikar(f)
  expect_match(r$metin, "[Dipnot] Kaynak: TÜİK", fixed = TRUE)
  expect_false(grepl("AYIRICI", r$metin))
})

test_that("metin_temizle NFC uygular ve görünmez karakterleri atar", {
  ayrisik <- "öğrenci"         # ö ve ğ birleşik olmayan biçimde
  expect_equal(metin_temizle(ayrisik), "öğrenci")
  expect_equal(metin_temizle("a b​c  d\n\n\n\ne"), "a bc d\n\ne")
})

test_that("metin katmanı olmayan PDF taranmış olarak işaretlenir", {
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f); graphics::plot.new(); graphics::rasterImage(matrix(runif(100), 10), 0, 0, 1, 1); grDevices::dev.off()
  r <- pdf_metin_cikar(f)
  expect_true(r$bilgi$taranmis_olabilir)
  expect_equal(r$metin, "")
})

test_that("desteklenmeyen uzantı açıkça bildirilir", {
  f <- tempfile(fileext = ".pages"); writeLines("x", f)
  expect_match(yerel_metin_cikar(f)$yontem, "desteklenmeyen-uzanti:pages")
})
