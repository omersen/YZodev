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

test_that("kategori tablosu sırayı korur ve tanımsız etikette durur", {
  kat <- c("A", "B", "C")
  expect_warning(t <- kategori_tablosu(c("C", "A", "C", NA), kat), "kodlanmamış")
  expect_equal(t$n, c(1, 0, 2))
  expect_error(kategori_tablosu(c("A", "D"), kat), "Tanımsız")
})
