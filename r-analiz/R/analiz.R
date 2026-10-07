# =============================================================================
# Analiz yardımcıları: sıklık tabloları, ağırlıklı kappa, Türkçe sayı biçimi
# =============================================================================

# Yuvarlama: yarım değerler yukarı (6,25 -> 6,3) -----------------------------------
# R'ın round() işlevi IEC 60559 gereği yarımları çifte yuvarlar (6,25 -> 6,2);
# Excel, SPSS ve elle hesaplama ise yukarı yuvarlar. 144 tabanında 9, 45, 81 ve
# 117 gibi sayılar bu nedenle 0,1 puan farklı çıkardı.
yuvarla <- function(x, basamak = 1) {
  sign(x) * floor(abs(x) * 10^basamak + 0.5 + 1e-9) / 10^basamak
}

# 42.36 -> "42,4" (Türkçe ondalık virgülü) ---------------------------------------
yuzde_tr <- function(x, basamak = 1) {
  formatC(yuvarla(x, basamak), format = "f", digits = basamak, decimal.mark = ",")
}

# Tasarım nitelikleri kod kitabı ----------------------------------------------------
# Bildirideki dokuz nitelik ve bir koşullu alt kod. 1 = var, 0 = yok.
NITELIKLER <- c(
  ozgu_girdi = "Öğrenciye özgü, kişisel veya yerel girdi",
  girdi_islevsel = "Girdinin izleyen bilişsel işlemlerde işlevsel kullanımı",
  veri_toplama = "Gerçek yaşamdan veri toplama",
  belgeleme = "Belgeleme (fotoğraf, video, fiziksel ürün)",
  belgeleme_yalniz_kanit = "Belgeleme yalnızca görevin yapıldığını kanıtlıyor",
  surece_yayma = "Görevi sürece yayma",
  yansitma = "Yansıtma",
  karar_verme = "Karar verme",
  gerekcelendirme = "Gerekçelendirme",
  dogrulama = "Doğrulama"
)
# Koşullu kodlar: üst kod 0 ise alt kod uygulanamaz ve 0 sayılır.
ALT_KODLAR <- c(girdi_islevsel = "ozgu_girdi", belgeleme_yalniz_kanit = "belgeleme")
# Bildirideki dokuz nitelik arasında olmayan, yalnızca koşullu oran için tutulan kod
YARDIMCI_KODLAR <- "belgeleme_yalniz_kanit"

nitelik_kurali <- function(sutun) {
  ifelse(sutun %in% names(ALT_KODLAR),
         paste0("1 = var, 0 = yok. Yalnızca '", ALT_KODLAR[sutun], "' = 1 ise kodlayın; ",
                "üst kod 0 ise boş bırakılabilir (0 sayılır)."),
         "1 = var, 0 = yok. Boş bırakmayın.")
}

# Koşullu alt kodları tamamlar ve tutarlılığı denetler -------------------------
# Döndürür: tamamlanmış data.frame; tutarsızlık ya da eksik kodda açık hatayla durur.
nitelikleri_denetle <- function(nf, sutunlar) {
  for (alt in intersect(names(ALT_KODLAR), sutunlar)) {
    ust <- ALT_KODLAR[[alt]]
    if (!ust %in% sutunlar) next
    nf[[alt]][is.na(nf[[alt]]) & nf[[ust]] %in% 0] <- 0
    tutarsiz <- nf$odev_id[nf[[alt]] %in% 1 & nf[[ust]] %in% 0]
    if (length(tutarsiz) > 0) {
      stop("Tutarsız kod: '", alt, "' = 1 ama '", ust, "' = 0 olan ödev(ler): ",
           paste(tutarsiz, collapse = ", "), call. = FALSE)
    }
  }
  gecersiz <- unlist(lapply(sutunlar, function(s) {
    hatali <- !(nf[[s]] %in% c(0, 1))
    if (any(hatali)) paste0(nf$odev_id[hatali], ":", s) else NULL
  }))
  if (length(gecersiz) > 0) {
    stop(length(gecersiz), " hücre boş ya da 0/1 dışında (ödev:sütun): ",
         paste(utils::head(gecersiz, 20), collapse = ", "),
         if (length(gecersiz) > 20) " ..." else "", call. = FALSE)
  }
  nf
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
  ifelse(is.na(x), "NA", sub("^(-?)0\\.", "\\1.", formatC(yuvarla(x, basamak), format = "f", digits = basamak)))
}

# Kategori sıklık tablosu (sıralı kategori düzeni korunur) ------------------------
kategori_tablosu <- function(x, kategoriler) {
  bilinmeyen <- setdiff(unique(stats::na.omit(x)), kategoriler)
  if (length(bilinmeyen) > 0) stop("Tanımsız kategori: ", paste(bilinmeyen, collapse = ", "))
  if (anyNA(x)) warning(sum(is.na(x)), " ödev kodlanmamış (NA); tabloya alınmadı.")
  x <- factor(x, levels = kategoriler)
  n <- as.vector(table(x))
  data.frame(kategori = kategoriler, n = n,
             yuzde = yuvarla(100 * n / sum(n), 1), stringsAsFactors = FALSE)
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
      agirlik = names(turler), kappa = yuvarla(deger, 3),
      ga_alt = yuvarla(ga[1, ], 3), ga_ust = yuvarla(ga[2, ], 3),
      stringsAsFactors = FALSE, row.names = NULL
    ),
    yuzde_uyum = yuvarla(100 * mean(a == b), 1),
    capraz_tablo = table(Kodlayici1 = factor(k1[tam], levels = kategoriler),
                         Kodlayici2 = factor(k2[tam], levels = kategoriler))
  )
}

# İkili (0/1) tasarım niteliği sütunları için sıklık tablosu ---------------------
nitelik_tablosu <- function(d, sutunlar, etiketler = sutunlar) {
  data.frame(
    sutun = sutunlar,
    nitelik = etiketler,
    n = vapply(sutunlar, function(s) sum(d[[s]] == 1, na.rm = TRUE), numeric(1)),
    yuzde = vapply(sutunlar, function(s) yuvarla(100 * mean(d[[s]] == 1, na.rm = TRUE), 1), numeric(1)),
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
