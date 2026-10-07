test_that("sayılara Türkçe ek doğru seçilir (bildirideki örnekler)", {
  expect_equal(sayi_eki(61), "61'i")
  expect_equal(sayi_eki(34), "34'ü")
  expect_equal(sayi_eki(26), "26'sı")
  expect_equal(sayi_eki(23), "23'ü")
  expect_equal(sayi_eki(95), "95'i")
  expect_equal(sayi_eki(49, "iyelik_bulunma"), "49'unda")
  expect_equal(sayi_eki(16, "iyelik_bulunma"), "16'sında")
  expect_equal(sayi_eki("59,0", "iyelik_bulunma"), "59,0'ında")
  expect_equal(sayi_eki("34,0", "iyelik_bulunma"), "34,0'ında")
  expect_equal(sayi_eki(40, "bulunma"), "40'ta")
  expect_equal(sayi_eki(9, "bulunma"), "9'da")
  expect_equal(sayi_eki(100), "100'ü")
  expect_equal(sayi_eki(7), "7'si")
})

test_that("yüzdeler ondalık virgülle yazılır", {
  expect_equal(yuzde_tr(42.36), "42,4")
  expect_equal(yuzde_tr(16), "16,0")
  expect_equal(yuzde_tr(0.8166, 2), "0,82")
})

test_that("yarım değerler yukarı yuvarlanır (Excel/SPSS ile aynı)", {
  expect_equal(yuzde_tr(100 * 9 / 144), "6,3")
  expect_equal(yuzde_tr(100 * 45 / 144), "31,3")
  expect_equal(yuzde_tr(100 * 27 / 144), "18,8")
  expect_equal(yuvarla(-0.125, 2), -0.13)
  expect_equal(kategori_tablosu(rep(c("A", "B"), c(9, 135)), c("A", "B"))$yuzde, c(6.3, 93.8))
})

test_that("koşullu alt kodlar tamamlanır, tutarsız ya da eksik kod durdurur", {
  nf <- data.frame(odev_id = c("O1", "O2", "O3"), ozgu_girdi = c(1, 0, 1), girdi_islevsel = c(1, NA, 0),
                   belgeleme = c(0, 0, 1), belgeleme_yalniz_kanit = c(NA, NA, 1))
  s <- c("ozgu_girdi", "girdi_islevsel", "belgeleme", "belgeleme_yalniz_kanit")
  d <- nitelikleri_denetle(nf, s)
  expect_equal(d$girdi_islevsel, c(1, 0, 0))
  expect_equal(d$belgeleme_yalniz_kanit, c(0, 0, 1))
  nf2 <- nf; nf2$belgeleme_yalniz_kanit[1] <- 1
  expect_error(nitelikleri_denetle(nf2, s), "Tutarsız")
  nf3 <- nf; nf3$belgeleme[2] <- NA
  expect_error(nitelikleri_denetle(nf3, s), "O2:belgeleme")
  nf4 <- nf; nf4$ozgu_girdi[3] <- 2
  expect_error(nitelikleri_denetle(nf4, s), "0/1 dışında")
})

test_that("katsayılar APA biçiminde yazılır", {
  expect_equal(katsayi_bicim(0.8166), ".82")
  expect_equal(katsayi_bicim(1), "1.00")
  expect_equal(katsayi_bicim(-0.051), "-.05")
})

test_that("kategori tablosu sırayı korur ve tanımsız etikette durur", {
  kat <- c("A", "B", "C")
  expect_warning(t <- kategori_tablosu(c("C", "A", "C", NA), kat), "kodlanmamış")
  expect_equal(t$n, c(1, 0, 2))
  expect_error(kategori_tablosu(c("A", "D"), kat), "Tanımsız")
})
