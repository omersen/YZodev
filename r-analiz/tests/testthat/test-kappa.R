kat <- c("Tamamlanamadı", "Sınırlı ölçüde tamamlandı", "Büyük ölçüde tamamlandı", "Tam olarak tamamlandı")

test_that("tüm kategoriler kullanıldığında irr::kappa2 ile aynı sonucu verir", {
  skip_if_not_installed("irr")
  set.seed(3)
  a <- sample(1:4, 60, replace = TRUE)
  b <- ifelse(runif(60) < 0.75, a, sample(1:4, 60, replace = TRUE))
  expect_equal(agirlikli_kappa(a, b, 4, NULL), irr::kappa2(cbind(a, b), "unweighted")$value)
  expect_equal(agirlikli_kappa(a, b, 4, 1), irr::kappa2(cbind(a, b), "equal")$value)
  expect_equal(agirlikli_kappa(a, b, 4, 2), irr::kappa2(cbind(a, b), "squared")$value)
})

test_that("psych::cohen.kappa (karesel ağırlık, sabit düzeyler) ile aynı sonucu verir", {
  skip_if_not_installed("psych")
  a <- c(1, 1, 3, 3, 4, 4, 4, 3, 1, 4, 3, 4)
  b <- c(1, 3, 3, 4, 4, 4, 3, 3, 1, 4, 4, 4)   # 2. kategori hiç kullanılmıyor
  ck <- psych::cohen.kappa(cbind(a, b), levels = 1:4)
  expect_equal(agirlikli_kappa(a, b, 4, 2), ck$weighted.kappa, tolerance = 1e-8)
  expect_equal(agirlikli_kappa(a, b, 4, NULL), ck$kappa, tolerance = 1e-8)
})

test_that("kullanılmayan ara kategori irr::kappa2'yi kaydırır, bizim işlevi değil", {
  skip_if_not_installed("irr")
  a <- c(1, 1, 3, 3, 4, 4, 4, 3, 1, 4, 3, 4)
  b <- c(1, 3, 3, 4, 4, 4, 3, 3, 1, 4, 4, 4)
  # irr yalnızca gözlenen 3 düzeyle ağırlık kurar: 1 ile 3 arası "1 basamak" sayılır
  expect_false(isTRUE(all.equal(agirlikli_kappa(a, b, 4, 1), irr::kappa2(cbind(a, b), "equal")$value)))
})

test_that("kappa_hesapla etiketleri doğru sıraya çevirir ve tanımsız etikette durur", {
  k1 <- kat[c(1, 2, 3, 4, 4, 3, 2, 1, 4, 4)]
  k2 <- kat[c(1, 2, 3, 4, 3, 3, 2, 2, 4, 4)]
  s <- kappa_hesapla(k1, k2, kat, B = 200)
  expect_equal(s$n, 10)
  expect_equal(s$yuzde_uyum, 80)
  expect_equal(s$tablo$kappa[s$tablo$agirlik == "karesel"],
               round(agirlikli_kappa(match(k1, kat), match(k2, kat), 4, 2), 3))
  expect_true(all(s$tablo$ga_alt <= s$tablo$kappa & s$tablo$kappa <= s$tablo$ga_ust))
  expect_error(kappa_hesapla(c(k1[-1], "Yarım"), k2, kat), "Tanımsız")
})
