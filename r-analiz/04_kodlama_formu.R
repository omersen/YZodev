# =============================================================================
# 04_kodlama_formu.R : Kodlayıcılar için Excel kodlama formlarını hazırlar
# -----------------------------------------------------------------------------
# Çıktılar (cikti/kodlama/ altında):
#   kodlayici1_tamamlanabilirlik.xlsx : yönerge + YZ çıktısı yan yana, açılır
#                                       listeden kategori seçimi
#   kodlayici2_tamamlanabilirlik.xlsx : tohumla seçilmiş rastgele alt örneklem
#                                       (varsayılan %25); birinci kodlayıcının
#                                       kodları YOK (körleme)
#   tasarim_nitelikleri.xlsx          : yönergelerdeki tasarım niteliklerinin
#                                       0/1 kodlanması için şablon
# Yeniden çalıştırma:
#   - Kodlanmış formların üzerine yazılmaz; kodlayıcının eklediği sütun ve
#     sayfalar korunur.
#   - Formlar YERİNDE güncellenir: değişen hücreler yazılır, yeni satırlar alta
#     eklenir; kodlayıcının hücre notları, renklendirmeleri ve açılır listeleri
#     korunur. Her değişiklikten önce formun yedeği (_yedek_) alınır.
#   - Bir ödev, ayar ya da yönerge değiştiği için yeniden çağrıldıysa yalnızca o
#     satır yeni çıktıyla değiştirilir (kodu boşaltılır).
#   - Onayı kaldırılan ödevlerin satırları formda kalır; 05 bunları dışarıda bırakır.
#   - Sonradan eklenen ödevler birinci kodlayıcı formuna ve nitelik şablonuna
#     eklenir; ikinci kodlayıcı alt örneklemi hedef orana ulaşacak biçimde,
#     var olan satırlar korunarak tohumla tamamlanır.
# =============================================================================

source("00_ayarlar.R", encoding = "UTF-8")
gerekli_paketler(c("openxlsx", "jsonlite", "digest"))

kodlama_dizini <- file.path(AYAR$cikti_dizini, "kodlama")
dir.create(kodlama_dizini, showWarnings = FALSE, recursive = TRUE)
yonerge_dosyasi <- function(id) file.path(AYAR$veri_dizini, "yonergeler", paste0(id, ".txt"))

# Onaylı ve boş olmayan yönergeler: tasarım nitelikleri analizinin çerçevesi ----
# (API sonucundan bağımsızdır; API'nin reddettiği ödevler de burada yer alır.)
yonergeler <- onayli_yonergeler(AYAR)
if (length(yonergeler) == 0) stop("Onaylı ve boş olmayan yönerge yok.")

# Geçerli API çağrıları: tamamlanabilirlik kodlamasının çerçevesi ------------
kayit <- kayitlari_oku(file.path(AYAR$cikti_dizini, "api_kayitlari"))
if (is.null(kayit)) stop("API çağrı kaydı bulunamadı; önce 03_yz_cagri.R'ı çalıştırın.")
son <- gecerli_cagrilar(kayit, AYAR, yonergeler)
fazla_tekrar <- son$tekrar > AYAR$tekrar_sayisi
if (any(fazla_tekrar)) {
  message(sum(fazla_tekrar), " çağrı, şu anki tekrar_sayisi (", AYAR$tekrar_sayisi,
          ") dışındaki tekrarlara ait; forma alınmadı.")
  son <- son[!fazla_tekrar, ]
}
if (nrow(son) == 0) stop("Şu anki ayarlarla tamamlanmış API çağrısı yok.")

eksik <- setdiff(names(yonergeler), son$odev_id[son$tekrar == 1])
if (length(eksik) > 0) {
  sonuncu <- kayit[kayit$odev_id %in% eksik & kayit$ayar_sha256 %in% ayar_ozeti(AYAR), ]
  sonuncu <- sonuncu[!duplicated(sonuncu$odev_id, fromLast = TRUE), ]
  neden <- sonuncu$durum[match(eksik, sonuncu$odev_id)]
  message(length(eksik), " ödevin şu anki ayarlarla tamamlanmış 1. tekrar çağrısı yok; ",
          "tamamlanabilirlik formuna alınmadı (tasarım nitelikleri şablonunda yer alır): ",
          paste0(eksik, " (", ifelse(is.na(neden), "çağrılmamış", neden), ")", collapse = ", "))
}

# Excel hücresi en çok 32.767 karakter alır; daha uzun metinler kısaltılır ve
# tam metnin bulunduğu dosya belirtilir.
EXCEL_SINIR <- 32000
hucreye_sigdir <- function(x, dosya) {
  x <- xml_guvenli(x)
  if (nchar(x) <= EXCEL_SINIR) return(x)
  paste0(substr(x, 1, EXCEL_SINIR), "\n[... METİN KISALTILDI. Tamamı: ", dosya, "]")
}

form <- data.frame(
  odev_id = son$odev_id,
  tekrar = son$tekrar,
  yonerge = vapply(son$odev_id, function(id) hucreye_sigdir(yonergeler[[id]], yonerge_dosyasi(id)), "",
                   USE.NAMES = FALSE),
  # Çıktı, seçilen çağrının kendi dosyasından okunur.
  yz_ciktisi = vapply(paste0(son$dosya_koku, "_cikti.txt"),
                      function(f) hucreye_sigdir(txt_oku(f), f), "", USE.NAMES = FALSE),
  model_reddi = ifelse(is.na(son$ret), "", son$ret),
  kategori = NA_character_,
  gerekce = NA_character_,
  # Denetim için: çıktının hangi çağrıdan ve hangi ayarlarla geldiği (düzenlemeyin)
  cagri_dosyasi = basename(son$dosya_koku),
  ayar_sha256 = son$ayar_sha256,
  stringsAsFactors = FALSE
)
# Birden çok tekrar varsa satırlar rastgele sıralanır: aynı yönergenin
# tekrarları art arda gelirse kodlayıcı bir önceki kodundan etkilenebilir.
if (length(unique(form$tekrar)) > 1) {
  set.seed(AYAR$ikinci_kodlayici_tohumu + 1)
  form <- form[sample(nrow(form)), ]
} else {
  form <- form[order(form$odev_id), ]
}

# "kodlama" sayfasını yazar; açılır liste "kategori" başlığının bulunduğu sütuna konur.
kodlama_sayfasi_yaz <- function(wb, d) {
  openxlsx::writeData(wb, "kodlama", d)
  liste_dogrulama(wb, "kodlama", which(names(d) == "kategori"), 2:(nrow(d) + 1), AYAR$kategoriler)
  openxlsx::addStyle(wb, "kodlama", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                     rows = 1:(nrow(d) + 1), cols = 1:7, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "kodlama", cols = seq_along(d),
                         widths = c(9, 7, 60, 80, 20, 26, 40, 30, 12, rep(15, max(0, ncol(d) - 9)))[seq_along(d)])
  openxlsx::freezePane(wb, "kodlama", firstRow = TRUE)
  invisible(wb)
}

form_kitabi <- function(d) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "kodlama")
  kodlama_sayfasi_yaz(wb, d)
  openxlsx::addWorksheet(wb, "kategori_tanimlari")
  openxlsx::writeData(wb, "kategori_tanimlari", data.frame(
    sira = seq_along(AYAR$kategoriler), kategori = AYAR$kategoriler,
    tanim = "Kod kitabındaki tanımı buraya yazın"
  ))
  wb
}

# Yerinde güncelleme yardımcıları ---------------------------------------------------
# Sayfa, boş satırlar dahil okunur; tablo satırı i, Excel'de i + 1. satırdır.
sayfa_oku_tam <- function(wb, sayfa) {
  openxlsx::read.xlsx(wb, sayfa, skipEmptyRows = FALSE, skipEmptyCols = FALSE, sep.names = " ")
}
hucre_yaz <- function(wb, sayfa, deger, satir, sutun) {
  openxlsx::writeData(wb, sayfa, xml_guvenli(deger), startCol = sutun, startRow = satir, colNames = FALSE)
}
yedekle <- function(yol) {
  yedek <- sub("\\.xlsx$", paste0("_yedek_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx"), yol)
  file.copy(yol, yedek, overwrite = TRUE)
  basename(yedek)
}
# Yeni satırları tablonun altına, sayfadaki başlık sırasına göre ekler.
satir_ekle <- function(wb, sayfa, tum, yeni) {
  if (nrow(yeni) == 0) return(integer(0))
  for (s in setdiff(names(tum), names(yeni))) yeni[[s]] <- NA
  yeni <- yeni[, names(tum), drop = FALSE]
  yeni[] <- lapply(yeni, xml_guvenli)
  baslangic <- nrow(tum) + 2
  openxlsx::writeData(wb, sayfa, yeni, startRow = baslangic, colNames = FALSE)
  baslangic:(baslangic + nrow(yeni) - 1)
}

# Boş bırakılmış "tekrar" hücrelerini çağrı dosyası adından (O001_t2_...) geri yükler.
tekrar_tamamla <- function(d) {
  t <- suppressWarnings(as.integer(d$tekrar))
  bos <- is.na(t) & !is.na(d$cagri_dosyasi)
  t[bos] <- suppressWarnings(as.integer(sub("^.*_t([0-9]+)_.*$", "\\1", d$cagri_dosyasi[bos])))
  t
}

# Var olan formu yerinde günceller.
#   eklenecek : formda yoksa eklenecek satırlar
#   gecerli   : şu anki geçerli çağrılardan oluşan satırlar (eskimiş satırların yerine geçer)
#   onayli_id : şu an analiz çerçevesindeki ödevler (diğer satırlara dokunulmaz)
form_guncelle <- function(yol, eklenecek, gecerli, onayli_id) {
  if (!file.exists(yol)) {
    xlsx_kaydet(form_kitabi(eklenecek), yol)
    message("Yazıldı: ", yol, " (", nrow(eklenecek), " satır)")
    return(invisible(eklenecek))
  }
  wb <- openxlsx::loadWorkbook(yol)
  if (!"kodlama" %in% names(wb)) stop(yol, ": 'kodlama' sayfası bulunamadı.", call. = FALSE)
  tum <- sayfa_oku_tam(wb, "kodlama")
  if (is.null(tum$cagri_dosyasi) || is.null(tum$odev_id)) {
    stop(yol, " bu iş akışının eski bir sürümüyle oluşturulmuş ya da başlıkları değiştirilmiş ",
         "('odev_id', 'cagri_dosyasi' sütunları yok). Dosyayı yeniden adlandırıp 04'ü yeniden çalıştırın.", call. = FALSE)
  }
  sutun <- function(ad) match(ad, names(tum))
  dolu <- !is.na(tum$odev_id)
  t <- tekrar_tamamla(tum)
  degisiklik <- character(0)

  geri <- which(dolu & is.na(suppressWarnings(as.integer(tum$tekrar))) & !is.na(t))
  for (i in geri) hucre_yaz(wb, "kodlama", t[i], i + 1, sutun("tekrar"))
  if (length(geri) > 0) degisiklik <- c(degisiklik, paste0(length(geri), " boş 'tekrar' hücresi geri yüklendi"))
  tum$tekrar <- t

  onaysiz <- dolu & !tum$odev_id %in% onayli_id
  if (any(onaysiz)) {
    message(yol, ": analiz çerçevesi dışındaki (onayı kaldırılmış ya da yönergesi boş) ödev satırları formda ",
            "bırakıldı; 05 bunları dışarıda bırakır: ", paste(unique(tum$odev_id[onaysiz]), collapse = ", "))
  }

  anahtar <- function(x) paste(x$odev_id, x$tekrar, x$cagri_dosyasi)
  eskimis <- which(dolu & !onaysiz & !anahtar(tum) %in% anahtar(gecerli))
  if (length(eskimis) > 0) {
    eslesme <- match(paste(tum$odev_id[eskimis], tum$tekrar[eskimis]), paste(gecerli$odev_id, gecerli$tekrar))
    for (j in seq_along(eskimis)) {
      i <- eskimis[j]
      if (!is.na(eslesme[j])) {
        g <- gecerli[eslesme[j], ]
        for (s in c("yonerge", "yz_ciktisi", "model_reddi", "cagri_dosyasi", "ayar_sha256")) {
          if (!is.na(sutun(s))) { hucre_yaz(wb, "kodlama", g[[s]], i + 1, sutun(s)); tum[[s]][i] <- g[[s]] }
        }
        for (s in c("kategori", "gerekce")) {
          if (!is.na(sutun(s))) { hucre_yaz(wb, "kodlama", NA_character_, i + 1, sutun(s)); tum[[s]][i] <- NA }
        }
      } else {   # artık geçerli çağrısı olmayan (ör. kesik) satır temizlenir
        openxlsx::deleteData(wb, "kodlama", cols = seq_along(tum), rows = i + 1, gridExpand = TRUE)
        tum[i, ] <- NA
      }
    }
    yenilenen_id <- unique(tum$odev_id[eskimis[!is.na(eslesme)]])
    silinen_n <- sum(is.na(eslesme))
    message("UYARI: ", yol, " içinde ", length(eskimis), " satırın çıktısı eskimişti (ayar ya da yönerge ",
            "değişti, ödev yeniden çağrıldı).",
            if (length(yenilenen_id) > 0) paste0(" Yeni çıktıyla değiştirilip kodu boşaltılan (YENİDEN KODLAYIN): ",
                                                 paste(yenilenen_id, collapse = ", "), "."),
            if (silinen_n > 0) paste0(" Geçerli çağrısı kalmadığı için ", silinen_n, " satır temizlendi."))
    degisiklik <- c(degisiklik, "eskimiş satırlar güncellendi")
  }

  mevcut_anahtar <- paste(tum$odev_id, tum$tekrar)[!is.na(tum$odev_id)]
  yeni <- eklenecek[!paste(eklenecek$odev_id, eklenecek$tekrar) %in% mevcut_anahtar, ]
  if (nrow(yeni) > 0) {
    satirlar <- satir_ekle(wb, "kodlama", tum, yeni)
    if (!is.na(sutun("kategori"))) liste_dogrulama(wb, "kodlama", sutun("kategori"), satirlar, AYAR$kategoriler)
    openxlsx::addStyle(wb, "kodlama", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                       rows = satirlar, cols = seq_len(min(7, ncol(tum))), gridExpand = TRUE, stack = TRUE)
    message(yol, ": var olan kodlar korunarak ", nrow(yeni), " yeni satır eklendi.")
    degisiklik <- c(degisiklik, "yeni satırlar eklendi")
  }

  if (length(degisiklik) > 0) {
    yedek <- yedekle(yol)
    xlsx_kaydet(wb, yol)
    message(yol, " güncellendi (", paste(degisiklik, collapse = "; "), "). Yedek: ", yedek)
  } else {
    message("Var olan form korunuyor: ", yol)
  }
  invisible(xlsx_oku(yol, "kodlama"))
}

form1 <- form_guncelle(file.path(kodlama_dizini, "kodlayici1_tamamlanabilirlik.xlsx"),
                       eklenecek = form, gecerli = form, onayli_id = names(yonergeler))

# İkinci kodlayıcı: 1. tekrarı olan ödevlerden tohumla rastgele alt örneklem ----
# (05_analiz.R tamamlanabilirlik dağılımını da 1. tekrardan hesaplar.) Form
# varsa var olan satırlar korunur; ödevler sonradan eklendiyse örneklem hedef
# orana ulaşacak biçimde henüz seçilmemiş ödevlerden tohumla tamamlanır.
yol2 <- file.path(kodlama_dizini, "kodlayici2_tamamlanabilirlik.xlsx")
cerceve <- sort(unique(form$odev_id[form$tekrar == 1]))
hedef_n <- round(length(cerceve) * AYAR$ikinci_kodlayici_orani)
mevcut2 <- if (file.exists(yol2)) intersect(xlsx_oku(yol2, "kodlama")$odev_id, cerceve) else character(0)
eksik_n <- max(0, hedef_n - length(mevcut2))
set.seed(AYAR$ikinci_kodlayici_tohumu + length(mevcut2))
ek_id <- if (eksik_n > 0) sort(sample(setdiff(cerceve, mevcut2), min(eksik_n, length(setdiff(cerceve, mevcut2))))) else character(0)
ek2 <- form[form$odev_id %in% ek_id & form$tekrar == 1, ]
ek2 <- ek2[order(ek2$odev_id), ]
form2 <- form_guncelle(yol2, eklenecek = ek2, gecerli = form[form$tekrar == 1, ], onayli_id = names(yonergeler))
message("İkinci kodlayıcı alt örneklemi: ", sum(form2$odev_id %in% cerceve), " ödev (hedef: ", hedef_n, " = ",
        length(cerceve), " x ", AYAR$ikinci_kodlayici_orani, "; tohum = ", AYAR$ikinci_kodlayici_tohumu, ")",
        if (length(ek_id) > 0 && length(mevcut2) > 0) paste0("; ", length(ek_id), " ödev eklendi") else "", ".")

# Tasarım nitelikleri şablonu: TÜM onaylı yönergeler ----------------------------
# Yönerge metninin özeti saklanır; metin sonradan değişirse satırın metni
# güncellenir, kodları korunur ama "yonerge_degisti" sütunuyla işaretlenir.
nitelik_yolu <- file.path(kodlama_dizini, "tasarim_nitelikleri.xlsx")
nitelik_formu <- data.frame(
  odev_id = names(yonergeler),
  yonerge = vapply(names(yonergeler), function(id) hucreye_sigdir(yonergeler[[id]], yonerge_dosyasi(id)), "",
                   USE.NAMES = FALSE),
  stringsAsFactors = FALSE
)
for (s in names(NITELIKLER)) nitelik_formu[[s]] <- NA_integer_
nitelik_formu$yonerge_degisti <- NA_character_
nitelik_formu$yonerge_sha256 <- vapply(yonergeler, sha256, "", USE.NAMES = FALSE)

nitelik_sayfasi_yaz <- function(wb, d) {
  openxlsx::writeData(wb, "nitelikler", d)
  # 0/1 doğrulaması yalnızca kod kitabındaki nitelik sütunlarına, her birine ayrı ayrı
  # uygulanır (kodlayıcının eklediği not sütunları kısıtlanmaz).
  for (k in which(names(d) %in% names(NITELIKLER))) {
    openxlsx::dataValidation(wb, "nitelikler", cols = k, rows = 2:(nrow(d) + 1),
                             type = "whole", operator = "between", value = c(0, 1))
  }
  openxlsx::addStyle(wb, "nitelikler", openxlsx::createStyle(wrapText = TRUE, valign = "top"),
                     rows = 1:(nrow(d) + 1), cols = 2, gridExpand = TRUE)
  openxlsx::setColWidths(wb, "nitelikler", cols = 1:2, widths = c(9, 80))
  openxlsx::freezePane(wb, "nitelikler", firstRow = TRUE, firstCol = TRUE)
  invisible(wb)
}

if (!file.exists(nitelik_yolu)) {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "nitelikler")
  nitelik_sayfasi_yaz(wb, nitelik_formu)
  openxlsx::addWorksheet(wb, "kod_kitabi")
  openxlsx::writeData(wb, "kod_kitabi", data.frame(
    sutun = names(NITELIKLER), nitelik = unname(NITELIKLER), kural = nitelik_kurali(names(NITELIKLER))))
  openxlsx::setColWidths(wb, "kod_kitabi", cols = 1:3, widths = c(24, 55, 80))
  xlsx_kaydet(wb, nitelik_yolu)
  message("Yazıldı: ", nitelik_yolu, " (", nrow(nitelik_formu), " ödev)")
} else {
  # Yerinde güncelleme: kod kitabına, diğer sayfalara, eklenen sütunlara, hücre
  # notlarına ve biçimlendirmeye dokunulmaz.
  wb <- openxlsx::loadWorkbook(nitelik_yolu)
  tum <- sayfa_oku_tam(wb, "nitelikler")
  if (is.null(tum$odev_id)) stop(nitelik_yolu, ": 'odev_id' sütunu bulunamadı.", call. = FALSE)
  degisiklik <- character(0)
  for (ek in c("yonerge_degisti", "yonerge_sha256")) {   # eski şablonlarda yoksa başlık eklenir
    if (is.null(tum[[ek]])) {
      hucre_yaz(wb, "nitelikler", ek, 1, ncol(tum) + 1)
      tum[[ek]] <- NA_character_
    }
  }
  sutun <- function(ad) match(ad, names(tum))
  dolu <- !is.na(tum$odev_id)
  fazla <- setdiff(tum$odev_id[dolu], nitelik_formu$odev_id)
  if (length(fazla) > 0) {
    message("Nitelik şablonunda analiz çerçevesi dışındaki ödev(ler) var (silinmedi; 05 bunları dışarıda bırakır): ",
            paste(fazla, collapse = ", "))
  }
  m <- match(tum$odev_id, nitelik_formu$odev_id)
  guncel_ozet <- nitelik_formu$yonerge_sha256[m]
  ilk_kez <- which(dolu & !is.na(m) & is.na(tum$yonerge_sha256))
  for (i in ilk_kez) hucre_yaz(wb, "nitelikler", guncel_ozet[i], i + 1, sutun("yonerge_sha256"))
  if (length(ilk_kez) > 0) degisiklik <- c(degisiklik, "yönerge özetleri eklendi")
  farkli <- which(dolu & !is.na(m) & !is.na(tum$yonerge_sha256) & tum$yonerge_sha256 != guncel_ozet)
  for (i in farkli) {
    hucre_yaz(wb, "nitelikler", nitelik_formu$yonerge[m[i]], i + 1, sutun("yonerge"))
    hucre_yaz(wb, "nitelikler", guncel_ozet[i], i + 1, sutun("yonerge_sha256"))
    hucre_yaz(wb, "nitelikler", "EVET: kodları yeni metne göre gözden geçirin, sonra bu hücreyi silin",
              i + 1, sutun("yonerge_degisti"))
  }
  if (length(farkli) > 0) {
    message("UYARI: nitelik şablonunda yönergesi değişen ödev(ler) (kodlar korundu, gözden geçirin): ",
            paste(tum$odev_id[farkli], collapse = ", "))
    degisiklik <- c(degisiklik, "değişen yönergeler işaretlendi")
  }
  yeni <- nitelik_formu[!nitelik_formu$odev_id %in% tum$odev_id[dolu], ]
  if (nrow(yeni) > 0) {
    satirlar <- satir_ekle(wb, "nitelikler", tum, yeni)
    for (k in which(names(tum) %in% names(NITELIKLER))) {
      openxlsx::dataValidation(wb, "nitelikler", cols = k, rows = satirlar,
                               type = "whole", operator = "between", value = c(0, 1))
    }
    message(nitelik_yolu, ": var olan kodlar korunarak ", nrow(yeni), " yeni ödev eklendi.")
    degisiklik <- c(degisiklik, "yeni ödevler eklendi")
  }
  if (length(degisiklik) > 0) {
    yedek <- yedekle(nitelik_yolu)
    xlsx_kaydet(wb, nitelik_yolu)
    message("Nitelik şablonu güncellendi (", paste(degisiklik, collapse = "; "), "). Yedek: ", yedek)
  } else {
    message("Var olan nitelik şablonu korunuyor: ", nitelik_yolu)
  }
}
message("Kodlama bittiğinde: 05_analiz.R")
