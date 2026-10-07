# Birim testleri: r-analiz klasöründe  Rscript tests/testthat.R
library(testthat)
test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
