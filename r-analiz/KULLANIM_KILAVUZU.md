# Kullanım Kılavuzu

Bu betikler ödevleri Google Drive'dan alır, her ödev yönergesini yapay zekâya (OpenAI API) bir kez sorar, yanıtları Excel kodlama formlarına koyar ve sonunda sunum için tabloları, grafikleri ve özet cümleleri üretir. Her adım RStudio'da tek bir komutla çalışır.

## Bir kez yapılacaklar

1. **R ve RStudio kurun.** R sürümü en az 4.2 olmalı.
2. **Paketleri kurun.** RStudio konsoluna yapıştırın:
   ```r
   install.packages(c("googledrive", "httr2", "jsonlite", "digest", "xml2",
                      "pdftools", "stringi", "openxlsx", "ggplot2", "usethis"))
   ```
3. **Projeyi açın.** `r-analiz` klasöründeki `r-analiz.Rproj` dosyasına çift tıklayın.
4. **API anahtarını girin.** Konsolda `usethis::edit_r_environ()` yazın. Açılan dosyaya şu satırı ekleyip kaydedin ve RStudio'yu yeniden başlatın:
   ```
   OPENAI_API_KEY=sk-...anahtarınız...
   ```
   Anahtarı hiçbir betiğe yazmayın.
5. **Drive klasörünü gösterin.** `00_ayarlar.R` dosyasında `drive_klasor` satırına ödev klasörünün bağlantısını yapıştırın (tarayıcıda klasörü açıp adres çubuğundan kopyalayın).
6. **İstemleri kontrol edin.** Aynı dosyada `sistem_istemi` ve `kullanici_sablonu` örnek metinlerdir. Önceki çalışmada kullandığınız metinleri hatırlıyorsanız onları aynen yazın.

## Adım adım çalıştırma

Her komutu RStudio konsolunda sırayla çalıştırın.

**Adım 1: Ödevleri indirin**
```r
source("01_drive_indir.R")
```
İlk seferde tarayıcı açılır ve Google hesabınız için izin ister. Dosyalar `veri/ham/` klasörüne O001, O002… adlarıyla iner. Öğrenci adları yalnızca `veri/kimlik_eslestirme.xlsx` dosyasında kalır.

**Adım 2: Metinleri çıkarın ve kontrol edin**
```r
source("02_metin_cikar.R")
```
Ardından:
- `veri/yonergeler/` klasöründeki her `.txt` dosyasını açın. Ad-soyad, öğrenci numarası, kapak sayfası gibi yönergeye ait olmayan kısımları silip kaydedin. Yapay zekâya bu metin gidecek.
- `veri/kontrol_listesi.xlsx` dosyasını açın. `dikkat` sütunu sorunlu dosyaları gösterir (taranmış PDF, görsel, olası kişisel veri gibi). Kontrol ettiğiniz her ödevin `kontrol_edildi` hücresinde açılır listeden **evet** seçin. Dosyayı kaydedip kapatın.

**Adım 3: Yapay zekâya gönderin (ücretlidir)**
```r
source("03_yz_cagri.R")
```
Betik önce tahmini büyüklüğü gösterir ve "başlatılsın mı?" diye sorar; **e** yazıp Enter'a basın. 144 ödev birkaç saat sürebilir. İşlem yarıda kesilirse aynı komutu yeniden çalıştırın; tamamlanan ödevler tekrar gönderilmez ve tekrar ücretlendirilmez.

**Adım 4: Kodlama formlarını oluşturun**
```r
source("04_kodlama_formu.R")
```
`cikti/kodlama/` klasöründe üç dosya oluşur:
- `kodlayici1_tamamlanabilirlik.xlsx`: Sizin formunuz. Yönergeyi ve yapay zekâ çıktısını okuyun, `kategori` sütununda açılır listeden seçim yapın.
- `kodlayici2_tamamlanabilirlik.xlsx`: Rastgele seçilmiş %25'lik bölüm. İkinci kodlayıcıya gönderin; sizin kodlarınızı içermez.
- `tasarim_nitelikleri.xlsx`: Her ödev için tasarım niteliklerini 1 (var) ya da 0 (yok) olarak girin. Kurallar `kod_kitabi` sayfasındadır.

**Adım 5: Sonuçları alın**
```r
source("05_analiz.R")
```
`cikti/analiz/` klasöründe şunlar oluşur:
- `tablolar.xlsx`: dağılım, kappa, tasarım nitelikleri
- `sekil1_tamamlanabilirlik.png` ve `sekil2_tasarim_nitelikleri.png`: sunum grafikleri
- `ozet.txt`: bildiri biçiminde Türkçe sonuç cümleleri (ör. "144 ödevin 61'i (%42,4)…")

## Özgün kodlarınız varsa (en hızlı yol)

Önceki çalışmanın kodları Excel'de duruyorsa 1-4. adımlara gerek yoktur:

1. `cikti/kodlama/` klasörünü oluşturun.
2. `kodlayici1_tamamlanabilirlik.xlsx` dosyasını hazırlayın. Sütunlar `odev_id`, `tekrar` (hep 1) ve `kategori` olmalı. Kategori adları `00_ayarlar.R`'deki yazımla aynı olmalı: Tamamlanamadı, Sınırlı ölçüde tamamlandı, Büyük ölçüde tamamlandı, Tam olarak tamamlandı.
3. İkinci kodlayıcının kodları için aynı biçimde `kodlayici2_tamamlanabilirlik.xlsx` dosyasını hazırlayın.
4. `tasarim_nitelikleri.xlsx` dosyasını iki sayfayla hazırlayın:
   - `nitelikler` sayfası: `odev_id` ve 0/1 sütunları
   - `kod_kitabi` sayfası: `sutun` ve `nitelik` sütunları

   "83 ödevin 49'unda" gibi koşullu cümleler için sütun adları `ozgu_girdi`, `girdi_islevsel`, `belgeleme` ve `belgeleme_yalniz_kanit` olmalıdır.
5. Yalnızca `source("05_analiz.R")` komutunu çalıştırın.

## Sık görülen mesajlar

| Mesaj | Ne yapmalı |
|---|---|
| "... yazılamadı. Dosya Excel'de açık olabilir" | Excel dosyasını kapatıp komutu yeniden çalıştırın. |
| "OPENAI_API_KEY ortam değişkeni tanımlı değil" | "Bir kez yapılacaklar" bölümünün 4. maddesini yapın, RStudio'yu yeniden başlatın. |
| "API kotası/bakiyesi yetersiz" | OpenAI hesabınıza bakiye ekleyip 3. adımı yeniden çalıştırın. |
| "Art arda 3 çağrı zaman aşımına uğradı" | `00_ayarlar.R`'de `zaman_asimi_sn` değerini artırın (ör. 1200). |
| "YENİ SÜRÜM BEKLİYOR" | Öğrenci Drive'daki dosyayı değiştirmiş. `.yeni.txt` dosyasına bakıp yönergeyi güncelleyin, `.yeni.txt` dosyasını silin. |
| "YENİDEN KODLAYIN" | Bu ödevlerin yapay zekâ çıktısı yenilendi; kodlarını yeniden girin. |
| `kontrol_listesi.xlsx`'te "okunamadı" (.doc dosyası) | Dosyayı Word'de açıp .docx olarak kaydedin ya da LibreOffice kurun, sonra 2. adımı yeniden çalıştırın. |

## Dört altın kural

1. **Ayarları çalışmanın ortasında değiştirmeyin.** Model, istem ya da parametre değişirse bütün ödevler yeniden gönderilir ve yeniden ücretlendirilir.
2. **Betiği çalıştırmadan önce Excel dosyalarını kapatın.**
3. **Formların sütun başlıklarını değiştirmeyin.** Yeni sütun ve not eklemek serbesttir.
4. **`veri/` ve `cikti/` klasörlerini paylaşmayın, GitHub'a yüklemeyin.** Öğrenci verisi içerir. İkinci kodlayıcıya yalnızca kendi formunu gönderin.

Daha ayrıntılı yöntem notları için `README.md` dosyasına bakın.
