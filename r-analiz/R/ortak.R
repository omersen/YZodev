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

# Excel dosyası yazma -------------------------------------------------------------
# openxlsx::saveWorkbook(), hedef dosya Excel'de açıkken (Windows yazma kilidi)
# hata vermeden başarısız olur; burada açık bir hatayla durulur.
xlsx_kaydet <- function(wb, yol) {
  ok <- suppressWarnings(openxlsx::saveWorkbook(wb, yol, overwrite = TRUE, returnValue = TRUE))
  if (!isTRUE(ok)) {
    stop(yol, " yazılamadı. Dosya Excel'de açık olabilir; kapatıp betiği yeniden çalıştırın.", call. = FALSE)
  }
  invisible(yol)
}

# Tek sayfalık tablo. İnsanların açıp bakacağı tablolar CSV yerine xlsx olarak
# tutulur: Türkçe bölgesel ayarlı Excel, virgülle ayrılmış CSV'yi tek sütunda
# açar ve kaydederken ayırıcıyı ve karakter kodlamasını değiştirir.
xlsx_yaz <- function(x, yol, sayfa = "veri") {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, sayfa)
  openxlsx::writeData(wb, sayfa, x, withFilter = TRUE)
  openxlsx::freezePane(wb, sayfa, firstRow = TRUE)
  xlsx_kaydet(wb, yol)
}

# Sütunları farklı olabilen data.frame'leri eksik sütunları NA ile doldurarak birleştirir
rbind_doldur <- function(liste) {
  liste <- Filter(function(d) !is.null(d) && nrow(d) > 0, liste)
  if (length(liste) == 0) return(NULL)
  sutunlar <- unique(unlist(lapply(liste, names)))
  do.call(rbind, lapply(liste, function(d) {
    for (s in setdiff(sutunlar, names(d))) d[[s]] <- NA
    d[, sutunlar, drop = FALSE]
  }))
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
