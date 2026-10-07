# =============================================================================
# Ortak yardımcılar
# =============================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# R >= 4.2 gerekir: Windows'ta UTF-8 yerel ayarı bu sürümle geldi; daha eski
# sürümlerde Türkçe karakterler ve bazı simgeler dosyaya yazılırken bozulabilir.
r_surumu_denetle <- function() {
  if (getRversion() < "4.2.0") stop("Bu betikler R >= 4.2.0 gerektirir. Kurulu sürüm: ", getRversion())
  invisible(TRUE)
}

gerekli_paketler <- function(paketler) {
  eksik <- paketler[!vapply(paketler, requireNamespace, logical(1), quietly = TRUE)]
  if (length(eksik) > 0) {
    stop("Eksik paket(ler): ", paste(eksik, collapse = ", "),
         "\nKurmak için: install.packages(c(", paste0('"', eksik, '"', collapse = ", "), "))")
  }
  invisible(TRUE)
}

# CSV: UTF-8 + BOM (Excel Türkçe karakterleri doğru göstersin diye) ----------
csv_yaz <- function(x, yol) {
  gecici <- tempfile(fileext = ".csv")
  utils::write.csv(x, gecici, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  icerik <- readBin(gecici, "raw", file.size(gecici))
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), icerik), yol)
  unlink(gecici)
  invisible(yol)
}

csv_oku <- function(yol) {
  utils::read.csv(yol, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE,
                  check.names = FALSE, na.strings = c("", "NA"))
}

# Elle düzenlenen tablolar Excel'de tutulur (Türkçe Excel CSV'yi ";" ile ve
# farklı kodlamayla kaydettiği için CSV yerine xlsx). Boş sütunlar korunur.
# Boş ya da yalnızca boşluk içeren hücreler NA olarak okunur.
xlsx_oku <- function(yol, sayfa = 1) {
  x <- openxlsx::read.xlsx(yol, sheet = sayfa, skipEmptyCols = FALSE, skipEmptyRows = TRUE)
  x[] <- lapply(x, function(v) {
    if (is.character(v)) { v <- trimws(v); v[!is.na(v) & !nzchar(v)] <- NA }
    v
  })
  x
}

# UTF-8 metin dosyası okuma/yazma ---------------------------------------------
txt_oku <- function(yol) {
  x <- paste(readLines(yol, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  sub("^\ufeff", "", x)   # Not Defteri'nin eklediği BOM'u at
}
txt_yaz <- function(x, yol) {
  con <- file(yol, open = "wb")
  on.exit(close(con))
  writeBin(charToRaw(enc2utf8(x)), con)
  invisible(yol)
}

zaman_damgasi <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
