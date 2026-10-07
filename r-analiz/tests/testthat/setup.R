# testthat çalışma dizini tests/testthat olduğundan proje kökü iki üst klasördür.
kok <- normalizePath(file.path("..", ".."))
for (f in c("ortak.R", "metin_cikarma.R", "drive.R", "openai.R", "analiz.R")) {
  source(file.path(kok, "R", f), encoding = "UTF-8", local = FALSE)
}
