# =============================================================================
# Metin çıkarma yardımcıları (docx, pdf, doc/odt/rtf, düz metin)
# -----------------------------------------------------------------------------
# Neden officer::docx_summary() kullanılmıyor?
#   Test sırasında görüldü ki docx_summary(): (1) metin kutusu içeriğini iki kez
#   döndürüyor (Word, metin kutularını hem DrawingML hem VML yedeği olarak
#   saklıyor), eski sürümlerde araya biçim kodları ("centertop") karıştırıyor;
#   (2) dipnotları almıyor; (3) tablo hücrelerini sütun sırasıyla veriyor.
#   YZ'ye gönderilecek yönergenin bozulmaması için docx XML'i doğrudan okunuyor.
# =============================================================================

W_NS <- "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
M_NS <- "http://schemas.openxmlformats.org/officeDocument/2006/math"
MC_NS <- "http://schemas.openxmlformats.org/markup-compatibility/2006"
NS <- c(w = W_NS, m = M_NS, mc = MC_NS)

# Unicode NFC normalizasyonu + boşluk temizliği -------------------------------
metin_temizle <- function(x) {
  x <- stringi::stri_trans_nfc(x)
  x <- gsub("\r\n?", "\n", x)
  x <- gsub("[\u00a0\u2007\u202f]", " ", x)           # bölünmez boşluklar
  x <- gsub("[\u200b\u200c\u200d\ufeff\u00ad]", "", x) # görünmez karakterler
  x <- gsub("[ \t]+\n", "\n", x)
  x <- gsub(" {2,}", " ", x)
  x <- gsub("\n{3,}", "\n\n", x)
  trimws(x)
}

# Word denklemini (OMML) okunabilir doğrusal metne çevirir --------------------
# Kesirler "(pay)/(payda)", üsler "taban^(üs)" biçiminde yazılır. Böylece
# "1/2" kesri "12" olarak bitişik okunmaz.
omml_metin <- function(node) {
  ad <- xml2::xml_name(node)
  cocuk <- function(yol) {
    n <- xml2::xml_find_first(node, yol, NS)
    if (inherits(n, "xml_missing")) "" else omml_metin(n)
  }
  if (ad == "t") return(xml2::xml_text(node))
  if (ad == "f") return(paste0("(", cocuk("m:num"), ")/(", cocuk("m:den"), ")"))
  if (ad == "sSup") return(paste0(cocuk("m:e"), "^(", cocuk("m:sup"), ")"))
  if (ad == "sSub") return(paste0(cocuk("m:e"), "_(", cocuk("m:sub"), ")"))
  if (ad == "sSubSup") {
    return(paste0(cocuk("m:e"), "_(", cocuk("m:sub"), ")^(", cocuk("m:sup"), ")"))
  }
  if (ad == "rad") {
    derece <- cocuk("m:deg")
    return(paste0(if (nzchar(derece)) paste0("kök", derece) else "\u221a",
                  "(", cocuk("m:e"), ")"))
  }
  if (ad %in% c("rPr", "ctrlPr", "fPr", "radPr", "sSupPr", "sSubPr",
                "oMathParaPr", "naryPr", "dPr", "accPr")) return("")
  paste(vapply(xml2::xml_children(node), omml_metin, character(1)), collapse = "")
}

# Bir paragrafın (w:p) metni; paragrafın İÇİNE gömülü metin kutuları hariç -----
# (Metin kutusu içindeki bir paragraf okunurken kendi metni alınmalı; bu yüzden
#  paragrafın kendisinin kaç metin kutusu içinde olduğu sayılıp karşılaştırılır.)
paragraf_metin <- function(p) {
  k <- length(xml2::xml_find_all(p, "ancestor::w:txbxContent", NS))
  ayni_duzey <- sprintf("count(ancestor::w:txbxContent) = %d", k)
  parcalar <- xml2::xml_find_all(
    p,
    paste0(".//w:t[", ayni_duzey, " and not(ancestor::m:oMath)]",
           " | .//w:tab[", ayni_duzey, " and not(ancestor::w:tabs)]",
           " | .//w:br[", ayni_duzey, "]",
           " | .//w:cr[", ayni_duzey, "]",
           " | .//m:oMath[", ayni_duzey, " and not(ancestor::m:oMath)]"),
    NS
  )
  if (length(parcalar) == 0) return("")
  out <- vapply(parcalar, function(n) {
    switch(xml2::xml_name(n),
           t = xml2::xml_text(n),
           tab = "\t",
           br = "\n",
           cr = "\n",
           oMath = paste0(" ", omml_metin(n), " "),
           "")
  }, character(1))
  paste(out, collapse = "")
}

# Tabloyu satır satır, hücreleri " | " ile ayırarak yazar ----------------------
tablo_metin <- function(tbl) {
  satirlar <- xml2::xml_find_all(tbl, "./w:tr", NS)
  satir_metni <- vapply(satirlar, function(tr) {
    hucreler <- xml2::xml_find_all(tr, "./w:tc", NS)
    h <- vapply(hucreler, function(tc) {
      ps <- xml2::xml_find_all(tc, ".//w:p[not(ancestor::w:txbxContent)]", NS)
      trimws(paste(vapply(ps, paragraf_metin, character(1)), collapse = " "))
    }, character(1))
    paste(h, collapse = " | ")
  }, character(1))
  paste(satir_metni, collapse = "\n")
}

# docx dosyasından düz metin ---------------------------------------------------
# Döndürür: list(metin, bilgi) ; bilgi = kalite kontrol göstergeleri
docx_metin_cikar <- function(yol) {
  dosyalar <- utils::unzip(yol, list = TRUE)$Name
  oku <- function(ic_yol) {
    if (!ic_yol %in% dosyalar) return(NULL)
    gecici <- tempfile()
    on.exit(unlink(gecici, recursive = TRUE), add = TRUE)
    utils::unzip(yol, files = ic_yol, exdir = gecici)
    xml2::read_xml(file.path(gecici, ic_yol))
  }
  doc <- oku("word/document.xml")
  if (is.null(doc)) stop("Geçerli bir docx değil (word/document.xml yok): ", yol)

  # Metin kutularının VML yedeği (mc:Fallback) aynı metni ikinci kez içerir.
  xml2::xml_remove(xml2::xml_find_all(doc, "//mc:Fallback", NS))

  bloklar <- xml2::xml_find_all(
    doc,
    paste0("//w:body//w:p[not(ancestor::w:tbl) and not(ancestor::w:txbxContent)]",
           " | //w:body//w:tbl[not(ancestor::w:tbl) and not(ancestor::w:txbxContent)]",
           " | //w:body//w:txbxContent[not(ancestor::w:txbxContent)]"),
    NS
  )
  parcalar <- vapply(bloklar, function(b) {
    switch(xml2::xml_name(b),
           p = paragraf_metin(b),
           tbl = tablo_metin(b),
           txbxContent = {
             ps <- xml2::xml_find_all(b, ".//w:p", NS)
             paste0("[Metin kutusu] ",
                    paste(vapply(ps, paragraf_metin, character(1)), collapse = "\n"))
           },
           "")
  }, character(1))
  govde <- paste(parcalar, collapse = "\n")

  # Dipnot ve sonnotlar (ayırıcı notlar hariç)
  notlar <- character(0)
  for (tur in c("footnotes", "endnotes")) {
    nx <- oku(sprintf("word/%s.xml", tur))
    if (is.null(nx)) next
    etiket <- if (tur == "footnotes") "footnote" else "endnote"
    ns_not <- xml2::xml_find_all(nx, sprintf("//w:%s[not(@w:type)]", etiket), NS)
    for (n in ns_not) {
      ps <- xml2::xml_find_all(n, ".//w:p", NS)
      tx <- trimws(paste(vapply(ps, paragraf_metin, character(1)), collapse = " "))
      if (nzchar(tx)) notlar <- c(notlar, paste0("[Dipnot] ", tx))
    }
  }
  metin <- metin_temizle(paste(c(govde, notlar), collapse = "\n"))

  # Üst/alt bilgi metni YZ'ye gönderilmez (çoğunlukla ad, okul vb. içerir),
  # ancak araştırmacının görmesi için kalite raporuna yazılır.
  ub <- grep("^word/(header|footer)[0-9]*\\.xml$", dosyalar, value = TRUE)
  ust_alt <- vapply(ub, function(f) {
    x <- oku(f)
    trimws(paste(xml2::xml_text(xml2::xml_find_all(x, "//w:t", NS)), collapse = " "))
  }, character(1))
  ust_alt <- unique(ust_alt[nzchar(ust_alt)])

  bilgi <- list(
    gorsel_sayisi = sum(grepl("^word/media/", dosyalar)),
    denklem_sayisi = length(xml2::xml_find_all(doc, "//m:oMath[not(ancestor::m:oMath)]", NS)),
    metin_kutusu_sayisi = length(xml2::xml_find_all(doc, "//w:txbxContent", NS)),
    tablo_sayisi = length(xml2::xml_find_all(doc, "//w:tbl", NS)),
    dipnot_sayisi = length(notlar),
    ust_alt_bilgi = paste(ust_alt, collapse = " || ")
  )
  list(metin = metin, bilgi = bilgi)
}

# PDF'ten düz metin -------------------------------------------------------------
pdf_metin_cikar <- function(yol, sayfa_basina_esik = 40) {
  sayfalar <- pdftools::pdf_text(yol)
  sayfa_karakter <- nchar(gsub("\\s", "", sayfalar))
  metin <- metin_temizle(paste(sayfalar, collapse = "\n\n"))
  list(
    metin = metin,
    bilgi = list(
      sayfa_sayisi = length(sayfalar),
      bos_sayfa_sayisi = sum(sayfa_karakter < sayfa_basina_esik),
      # Sayfaların çoğunda metin katmanı yoksa belge büyük olasılıkla taranmıştır.
      taranmis_olabilir = length(sayfalar) > 0 &&
        mean(sayfa_karakter < sayfa_basina_esik) >= 0.5
    )
  )
}

# LibreOffice ile .doc/.odt/.rtf -> .docx --------------------------------------
soffice_bul <- function() {
  adaylar <- c(
    Sys.which("soffice"), Sys.which("libreoffice"),
    "C:/Program Files/LibreOffice/program/soffice.exe",
    "C:/Program Files (x86)/LibreOffice/program/soffice.exe",
    "/Applications/LibreOffice.app/Contents/MacOS/soffice"
  )
  adaylar <- adaylar[nzchar(adaylar) & file.exists(adaylar)]
  if (length(adaylar) == 0) NA_character_ else unname(adaylar[1])
}

libreoffice_docx_yap <- function(yol, soffice = soffice_bul()) {
  if (is.na(soffice)) return(NA_character_)
  cikti_dizini <- tempfile("lo_")
  dir.create(cikti_dizini)
  # Ayrı bir kullanıcı profili, açık bir LibreOffice penceresiyle çakışmayı önler.
  profil_yolu <- gsub("\\\\", "/", normalizePath(tempfile("lo_profil_"), mustWork = FALSE))
  # Kullanıcı adında boşluk ya da "Ö" gibi karakterler olabileceği için yol URL
  # biçiminde kodlanır (ör. "Ömer Faruk" -> "%C3%96mer%20Faruk") ve tırnaklanır.
  profil <- shQuote(paste0("-env:UserInstallation=file:///",
                           utils::URLencode(enc2utf8(sub("^/+", "", profil_yolu)))))
  # Linux'ta R'nin LD_LIBRARY_PATH değeri LibreOffice'in kendi kütüphaneleriyle
  # çakışıyor (test ortamında "libreglo.so bulunamadı" hatası). Çağrı süresince
  # kaldırılıp sonra geri yüklenir. Windows/macOS'ta etkisizdir.
  eski_ld <- Sys.getenv("LD_LIBRARY_PATH", unset = NA)
  if (!is.na(eski_ld)) {
    Sys.unsetenv("LD_LIBRARY_PATH")
    on.exit(Sys.setenv(LD_LIBRARY_PATH = eski_ld), add = TRUE)
  }
  suppressWarnings(system2(
    soffice,
    c(profil, "--headless", "--convert-to", "docx", "--outdir",
      shQuote(cikti_dizini), shQuote(normalizePath(yol))),
    stdout = TRUE, stderr = TRUE
  ))
  cikti <- list.files(cikti_dizini, pattern = "\\.docx$", full.names = TRUE)
  if (length(cikti) == 0) NA_character_ else cikti[1]
}

# Uzantıya göre yerel çıkarma ---------------------------------------------------
# Yerel olarak okunamayan biçimlerde metin = NA döner ve 'yontem' alanı nedeni
# belirtir; 02_metin_cikar.R bu durumda (izin verildiyse) Drive dönüştürmesini dener.
yerel_metin_cikar <- function(yol) {
  uzanti <- tolower(tools::file_ext(yol))
  bos <- list(metin = NA_character_, bilgi = list(), yontem = NA_character_)
  if (uzanti == "docx") {
    r <- docx_metin_cikar(yol)
    return(c(r, yontem = "docx-xml"))
  }
  if (uzanti == "pdf") {
    r <- pdf_metin_cikar(yol)
    return(c(r, yontem = "pdftools"))
  }
  if (uzanti %in% c("doc", "odt", "rtf", "docm", "dotx", "wps")) {
    donusmus <- libreoffice_docx_yap(yol)
    if (!is.na(donusmus)) {
      r <- docx_metin_cikar(donusmus)
      return(c(r, yontem = "libreoffice->docx-xml"))
    }
    bos$yontem <- "yerel-arac-yok"
    return(bos)
  }
  if (uzanti %in% c("txt", "md")) {
    tx <- paste(readLines(yol, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    return(list(metin = metin_temizle(tx), bilgi = list(), yontem = "duz-metin"))
  }
  bos$yontem <- paste0("desteklenmeyen-uzanti:", uzanti)
  bos
}
