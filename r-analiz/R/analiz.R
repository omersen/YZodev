# =============================================================================
# Analiz yardımcıları: sıklık tabloları, ağırlıklı kappa, Türkçe sayı biçimi
# =============================================================================

# 42.36 -> "42,4" (Türkçe ondalık virgülü) ---------------------------------------
yuzde_tr <- function(x, basamak = 1) {
  formatC(round(x, basamak), format = "f", digits = basamak, decimal.mark = ",")
}

# Sayılara Türkçe ek (ünlü uyumu ve ünsüz benzeşmesi) ---------------------------
# Ek, sayının okunuşundaki son sözcüğe göre seçilir: 61 -> "altmış bir" -> "61'i";
# 26 -> "yirmi altı" -> "26'sı"; 49 -> "kırk dokuz" -> "49'unda"; 40 -> "40'ta".
# Ondalıklı yazımda (ör. "59,0") virgülden sonraki kısım okunur ("sıfır").
# tur: "iyelik" (-sI), "iyelik_bulunma" (-sIndA), "bulunma" (-DA)
sayi_eki <- function(sayi, tur = c("iyelik", "iyelik_bulunma", "bulunma")) {
  tur <- match.arg(tur)
  s <- as.character(sayi)
  okunan <- if (grepl(",", s)) sub("^.*,", "", s) else s
  n <- as.numeric(okunan)
  son_sozcuk <- if (n == 0) "sıfır"
    else if (n %% 10 != 0) c("bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz", "dokuz")[n %% 10]
    else if (n %% 100 != 0) c("on", "yirmi", "otuz", "kırk", "elli", "altmış", "yetmiş", "seksen", "doksan")[(n %% 100) / 10]
    else if (n %% 1000 != 0) "yüz"
    else if (n %% 1e6 != 0) "bin"
    else "milyon"
  harfler <- strsplit(son_sozcuk, "")[[1]]
  unluler <- harfler[harfler %in% c("a", "ı", "o", "u", "e", "i", "ö", "ü")]
  son_unlu <- unluler[length(unluler)]
  dar <- c(a = "ı", "ı" = "ı", o = "u", u = "u", e = "i", i = "i", "ö" = "ü", "ü" = "ü")[[son_unlu]]
  genis <- if (son_unlu %in% c("a", "ı", "o", "u")) "a" else "e"
  unluyle_biter <- harfler[length(harfler)] %in% names(c(a = 1, "ı" = 1, o = 1, u = 1, e = 1, i = 1, "ö" = 1, "ü" = 1))
  sert_biter <- harfler[length(harfler)] %in% c("f", "s", "t", "k", "ç", "ş", "h", "p")
  ek <- switch(tur,
    iyelik = paste0(if (unluyle_biter) "s" else "", dar),
    iyelik_bulunma = paste0(if (unluyle_biter) "s" else "", dar, "nd", genis),
    bulunma = paste0(if (sert_biter) "t" else "d", genis)
  )
  paste0(s, "'", ek)
}

# Kappa gibi en çok 1 olabilen katsayılar için APA biçimi: 0.8166 -> ".82"
# (bildiride kappa ".82" biçiminde yazılmış; yüzdeler ise ondalık virgüllü).
katsayi_bicim <- function(x, basamak = 2) {
  ifelse(is.na(x), "NA", sub("^(-?)0\\.", "\\1.", formatC(round(x, basamak), format = "f", digits = basamak)))
}

# Kategori sıklık tablosu (sıralı kategori düzeni korunur) ------------------------
kategori_tablosu <- function(x, kategoriler) {
  bilinmeyen <- setdiff(unique(stats::na.omit(x)), kategoriler)
  if (length(bilinmeyen) > 0) stop("Tanımsız kategori: ", paste(bilinmeyen, collapse = ", "))
  if (anyNA(x)) warning(sum(is.na(x)), " ödev kodlanmamış (NA); tabloya alınmadı.")
  x <- factor(x, levels = kategoriler)
  n <- as.vector(table(x))
  data.frame(kategori = kategoriler, n = n,
             yuzde = round(100 * n / sum(n), 1), stringsAsFactors = FALSE)
}

# Ağırlıklı Cohen kappa ------------------------------------------------------------
# Bildiride "ağırlıklı Cohen kappa" deniyor ancak ağırlıklandırma türü (doğrusal
# / karesel) belirtilmiyor. İkisi de hesaplanır; raporda hangisinin
# kullanıldığı açıkça yazılmalıdır.
# Neden irr::kappa2 değil? kappa2 ağırlık matrisini yalnızca GÖZLENEN
# kategorilerden kurar: 36 ödevlik alt örneklemde bir kategori hiç
# kullanılmazsa (ör. "Sınırlı ölçüde" yoksa) kategoriler arası uzaklıklar
# kayar ve ağırlıklı kappa yanlış çıkar. Burada K kategori sabittir.
#   a, b : 1..K tamsayı kodları ; us = NULL ağırlıksız, 1 doğrusal, 2 karesel
agirlikli_kappa <- function(a, b, K, us = NULL) {
  O <- table(factor(a, levels = seq_len(K)), factor(b, levels = seq_len(K))) / length(a)
  E <- outer(rowSums(O), colSums(O))
  W <- if (is.null(us)) diag(K) else 1 - (abs(outer(seq_len(K), seq_len(K), "-")) / (K - 1))^us
  po <- sum(W * O)
  pe <- sum(W * E)
  if (isTRUE(all.equal(pe, 1))) return(NA_real_)   # tek kategori: kappa tanımsız
  (po - pe) / (1 - pe)
}

kappa_hesapla <- function(k1, k2, kategoriler, B = 2000, tohum = 1) {
  bilinmeyen <- setdiff(stats::na.omit(unique(c(k1, k2))), kategoriler)
  if (length(bilinmeyen) > 0) stop("Tanımsız kategori: ", paste(bilinmeyen, collapse = ", "))
  tam <- !is.na(k1) & !is.na(k2)
  a <- match(k1[tam], kategoriler)
  b <- match(k2[tam], kategoriler)
  K <- length(kategoriler)
  turler <- list(agirliksiz = NULL, dogrusal = 1, karesel = 2)
  hesapla <- function(i) vapply(turler, function(us) agirlikli_kappa(a[i], b[i], K, us), numeric(1))
  deger <- hesapla(seq_along(a))

  # Yüzdelik bootstrap güven aralığı (n = 36 gibi küçük örneklemlerde aralık
  # geniştir; nokta kestirimiyle birlikte raporlanması önerilir).
  set.seed(tohum)
  boot <- replicate(B, hesapla(sample.int(length(a), replace = TRUE)))
  ga <- apply(boot, 1, stats::quantile, probs = c(0.025, 0.975), na.rm = TRUE)

  list(
    n = length(a),
    tablo = data.frame(
      agirlik = names(turler), kappa = round(deger, 3),
      ga_alt = round(ga[1, ], 3), ga_ust = round(ga[2, ], 3),
      stringsAsFactors = FALSE, row.names = NULL
    ),
    yuzde_uyum = round(100 * mean(a == b), 1),
    capraz_tablo = table(Kodlayici1 = factor(k1[tam], levels = kategoriler),
                         Kodlayici2 = factor(k2[tam], levels = kategoriler))
  )
}

# İkili (0/1) tasarım niteliği sütunları için sıklık tablosu ---------------------
nitelik_tablosu <- function(d, sutunlar, etiketler = sutunlar) {
  data.frame(
    nitelik = etiketler,
    n = vapply(sutunlar, function(s) sum(d[[s]] == 1, na.rm = TRUE), numeric(1)),
    yuzde = vapply(sutunlar, function(s) round(100 * mean(d[[s]] == 1, na.rm = TRUE), 1), numeric(1)),
    stringsAsFactors = FALSE, row.names = NULL
  )
}

# Sunum grafiği: yatay çubuk, tek renk, doğrudan etiket (ggplot2 varsa) ---------
cubuk_grafik <- function(tablo, etiket_sutunu, baslik, dosya, sirala = FALSE,
                         genislik = 9, yukseklik = 4.5) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    message("ggplot2 kurulu değil; grafik atlandı (", dosya, ").")
    return(invisible(NULL))
  }
  d <- tablo
  d$etiket <- d[[etiket_sutunu]]
  sira <- if (sirala) d$etiket[order(d$n)] else rev(d$etiket)
  d$etiket <- factor(d$etiket, levels = sira)
  d$deger_etiketi <- sprintf("%d (%%%s)", d$n, yuzde_tr(d$yuzde))
  ust <- max(d$n) * 1.25
  g <- ggplot2::ggplot(d, ggplot2::aes(x = n, y = etiket)) +
    ggplot2::geom_col(fill = "#2a78d6", width = 0.6) +
    ggplot2::geom_text(ggplot2::aes(label = deger_etiketi), hjust = -0.12,
                       size = 4.2, colour = "#0b0b0b") +
    ggplot2::scale_x_continuous(limits = c(0, ust), expand = c(0, 0)) +
    ggplot2::labs(title = baslik, x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#fcfcfb", colour = NA),
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(colour = "#0b0b0b"),
      plot.title = ggplot2::element_text(colour = "#0b0b0b", face = "bold", size = 15),
      plot.title.position = "plot"
    )
  ggplot2::ggsave(dosya, g, width = genislik, height = yukseklik, dpi = 300, bg = "#fcfcfb")
  invisible(g)
}
