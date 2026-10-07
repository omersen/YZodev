# Ödevlerin ÜYZ ile tamamlanabilirliği: R iş akışı

Bu klasör, "Öğretmen adaylarınca hazırlanan ödevlerin üretken yapay zekâ ile tamamlanabilirliği ve direnç odaklı tasarım nitelikleri" bildirisinde (X. EPOD Kongresi, 2026) betimlenen yöntemi R'da yeniden kurar: ödev dosyalarını Google Drive'dan alır, Word ve PDF dosyalarından yönerge metnini çıkarır, her yönergeyi OpenAI API'ye aynı sistem istemi ve aynı kullanıcı şablonuyla bağımsız bir çağrıda sunar, yanıtları kodlama formlarına aktarır ve bulgu tablolarını, kodlayıcılar arası uyuşmayı ve sunum grafiklerini üretir.

> **Önemli.** Özgün betik kaybolduğu için bu kod yöntemi yeniden kurar; özgün çıktıları yeniden üretmez. Aynı ayarlarla yeniden çalıştırmak bile farklı yanıtlar verebilir (aşağıdaki yöntemsel notlara bakın). Bildirideki sayılar özgün çalıştırmanın sonucudur; yeni bir çalıştırmanın sonuçları ayrı bir veri olarak raporlanmalıdır.

## Kurulum

1. R 4.2 veya üstü (Windows'ta UTF-8 desteği için gerekli). RStudio'da `r-analiz.Rproj` dosyasını açın.
2. Paketler:
   ```r
   install.packages(c("googledrive", "httr2", "jsonlite", "digest", "xml2",
                      "pdftools", "stringi", "openxlsx", "ggplot2"))
   # yalnızca testler için:
   install.packages(c("testthat", "webfakes", "officer", "withr", "zip", "irr", "psych"))
   ```
3. OpenAI API anahtarını **koda yazmayın**. `usethis::edit_r_environ()` ile açılan dosyaya `OPENAI_API_KEY=sk-...` satırını ekleyip R'ı yeniden başlatın.
4. `00_ayarlar.R` içinde `drive_klasor` alanına ödev klasörünün bağlantısını yazın. Bağlantıyı Git'e göndermemek isterseniz aynı satırı `ayarlar_yerel.R` dosyasına yazın (bu dosya `.gitignore` içindedir).
5. `.doc` (eski Word), `.odt` ve `.rtf` dosyaları için bilgisayarda LibreOffice kuruluysa otomatik olarak kullanılır. Kurulu değilse iki seçenek vardır: bu dosyaları Word'de `.docx` olarak kaydetmek ya da `drive_donusturme_izni = TRUE` yapmak (Drive dosyayı geçici olarak Google Dokümanlar'a çevirir; taranmış PDF'lerde OCR uygular; bu seçenek tam Drive yetkisi ister ve geçici kopyayı sonra siler).

## Adımlar

| Betik | Yaptığı | Başlıca çıktı |
|---|---|---|
| `01_drive_indir.R` | Klasörü alt klasörleriyle tarar, kısayolları çözer, dosyaları anonim adlarla (O001, O002...) indirir; aynı içerikli dosyaları işaretler | `veri/envanter.xlsx`, `veri/kimlik_eslestirme.xlsx` |
| `02_metin_cikar.R` | docx, Google Dokümanlar, pdf, doc/odt/rtf dosyalarından metin çıkarır; tabloları satır satır, metin kutularını bir kez, dipnotları ve Word denklemlerini okur; taranmış PDF, görsel, olası kişisel veri gibi durumları işaretler | `veri/yonergeler/*.txt`, `veri/kontrol_listesi.xlsx` |
| (elle) | `veri/yonergeler/*.txt` dosyalarını okuyun; ad-soyad, numara, kapak sayfası gibi yönerge dışı metni silin; `kontrol_listesi.xlsx` içinde `kontrol_edildi = evet` yapın | |
| `03_yz_cagri.R` | Onaylanan her yönergeyi bağımsız bir API çağrısıyla gönderir; istek ve ham yanıtı saklar; kesintide kaldığı yerden devam eder | `cikti/api_kayitlari/` (istek, ham yanıt, çıktı ve kayıt dosyaları), `cikti/cagri_kaydi.xlsx`, `cikti/oturum_*.json` |
| `04_kodlama_formu.R` | Yönerge ve YZ çıktısını yan yana koyan Excel kodlama formları; ikinci kodlayıcı için tohumla seçilmiş %25'lik kör alt örneklem; tasarım nitelikleri şablonu | `cikti/kodlama/*.xlsx` |
| `05_analiz.R` | Kategori dağılımı, ağırlıklı kappa (doğrusal ve karesel, bootstrap %95 GA), tasarım nitelikleri sıklıkları, keşfedici çapraz tablo, sunum grafikleri ve bildiri biçiminde Türkçe özet cümleleri | `cikti/analiz/` |

Her betik `source("01_drive_indir.R")` biçiminde sırayla çalıştırılır. `veri/` ve `cikti/` klasörleri öğrenci verisi içerdiği için Git'e gönderilmez.

**Özgün kodlarınız duruyorsa.** Sunumdaki sayıların özgün çalışmayla birebir aynı olması için API'yi yeniden çalıştırmanız gerekmez. Özgün kodlamaları `cikti/kodlama/` altına şu sütunlarla koymanız yeterlidir: `kodlayici1_tamamlanabilirlik.xlsx` ve `kodlayici2_tamamlanabilirlik.xlsx` için `odev_id`, `tekrar` (hep 1) ve `kategori` (dört kategori adı `00_ayarlar.R`'deki yazımla); `tasarim_nitelikleri.xlsx` için `nitelikler` sayfasında `odev_id` ve 0/1 nitelik sütunları, `kod_kitabi` sayfasında `sutun` ve `nitelik`. Ardından yalnızca `05_analiz.R` çalıştırılır.

## Yöntemsel notlar

- **Standartlaştırma ve bağımsızlık.** Bütün yönergeler aynı sistem istemi, aynı şablon ve aynı parametrelerle gönderilir; `previous_response_id` ya da konuşma geçmişi kullanılmadığı için çağrılar arasında bağlam aktarılmaz. Her çağrıda yönerge, sistem istemi ve şablonun SHA-256 özetleri kaydedilir; bu sayede hangi çıktının hangi metinle üretildiği sonradan denetlenebilir.
- **Sistem istemi ve şablon.** `00_ayarlar.R` içindeki metinler yer tutucudur. Özgün çalışmadakileri hatırlıyorsanız aynen yazın. İstem, modelin eksik kişisel veriyi uydurup uydurmayacağını ya da soru sorup sormayacağını etkiler; bu nedenle sunumda ve makalede birebir verilmelidir.
- **"Örnekleme parametreleri sabit tutuldu" ifadesi.** OpenAI'nin Responses API'sinde `seed` parametresi yoktur; Chat Completions'taki `seed` ise "en iyi çaba" düzeyindedir ve belirlenimcilik güvence altında değildir. GPT-5.x akıl yürütme modellerinde `temperature` ve `top_p` büyük olasılıkla yalnızca `reasoning.effort = "none"` iken kabul edilir (bu bilgi ikincil kaynaklardan doğrulandı; OpenAI belgesine bu ortamdan erişilemedi). Raporda hangi parametrelerin sabit tutulduğu (ör. akıl yürütme düzeyi, ayrıntılılık, azami çıktı token sayısı) açıkça yazılmalıdır.
- **Tek çağrı tek örneklemdir.** Sıcaklık 0 ve sabit tohum ile bile barındırılan modeller aynı girdiye farklı çıktılar verebilmektedir (Atıl vd., 2025). Bir ödevin kategorisi yeniden çalıştırmada değişebilir. Sağlamlık için `tekrar_sayisi` 3 ya da 5 yapılabilir; bu durumda `05_analiz.R` tekrarlar arası tutarlılığı da raporlar.
- **API ile ChatGPT arayüzü aynı değildir.** Öğrencilerin kullandığı uygulamada model yönlendirme, bellek, web araması ve dosya yükleme gibi araçlar vardır; bu iş akışında bunlar yoktur ve model tek bir istem alır. Tek denemeli sınama, birden çok deneme ve ek yönlendirme yapan bir öğrencinin ulaşabileceği tamamlanma düzeyini olduğundan düşük gösterebilir (Borges vd., 2024, tek bir istem stratejisinde ortalama %65,8, en az bir stratejide %85,1 doğru yanıt bildirmiştir). Öte yandan API ile arayüz arasındaki farkın yönü her görevde aynı değildir; bu nedenle bulgular, belirtilen model ve koşullar için geçerli kabul edilmeli ve öğrencilerin gerçek kullanımına doğrudan genellenmemelidir.
- **Model sürümü.** Her yanıttaki `model` alanı kaydedilir. `gpt-5.6-sol` için tarihli bir anlık görüntü (snapshot) kimliği OpenAI'nin açık API tanımında bulunamadı; bu nedenle çağrı tarihleri ve yanıtın bildirdiği model adı raporlanmalıdır. Model güncellemeleri davranışı değiştirebilir (Chen vd., 2024).
- **Kesik yanıtlar.** `status = "incomplete"` (ör. `max_output_tokens`) teknik bir kesintidir; "tamamlanamadı" olarak kodlanmamalıdır. Betik bunları ayırır ve kodlama formuna almaz. Böyle bir durumda sınırı artırıp **bütün** ödevleri yeniden çalıştırmak standartlaştırmayı korur.
- **Yalnızca metin gönderilir.** Görsel, çalışma kâğıdı ya da şekil içeren yönergeler `kontrol_listesi.xlsx` içinde işaretlenir; bu ödevlerde YZ'nin görsele erişmediği raporlanmalıdır.
- **Kappa.** Bildiride ağırlık türü belirtilmemiştir. `05_analiz.R` doğrusal ve karesel ağırlıklı kappayı birlikte verir. `irr::kappa2` ağırlıkları yalnızca gözlenen kategorilerden kurduğu için (36 ödevlik alt örneklemde bir kategori hiç kullanılmazsa sonuç kayar) kappa burada dört kategori sabit tutularak hesaplanır; sonuç testlerde `irr` ve `psych` ile karşılaştırılmıştır.
- **Raporlama.** Model adı ve yanıtın bildirdiği sürüm, çağrı tarihleri, API ucu, sistem istemi ve şablon (birebir), tüm parametreler, tekrar sayısı ve kesik/ret sayıları raporlanmalıdır (bkz. TRIPOD-LLM; Gallifant vd., 2025). `cikti/oturum_*.json` bu bilgileri tek dosyada toplar.

## Veri koruma

Öğrenci adları yalnızca `veri/kimlik_eslestirme.xlsx` dosyasında kalır; indirilen dosyalar, metinler ve formlar anonim kimliklerle adlandırılır. API'ye gönderilen metinden kişisel bilgiler elle çıkarılmalıdır; `02_metin_cikar.R` e-posta, telefon, uzun sayı ve "Ad Soyad" gibi örüntüleri yalnızca uyarı amaçlı işaretler. İstekler `store = false` ile gönderilir (Responses API'de bu alan atlanırsa yanıt OpenAI'de en az 30 gün saklanır). OpenAI'nin API verisini eğitimde kullanmama ve kötüye kullanım denetimi için saklama koşulları kurumunuzun etik kurul ve KVKK değerlendirmesi için güncel belgeden ayrıca doğrulanmalıdır.

## Testler

Gerçek Drive'a ve OpenAI'ye bağlanmadan, ücretsiz çalışır:

```r
# r-analiz klasöründe, terminalde:
Rscript tests/testthat.R    # birim testleri (metin çıkarma, API gövdesi ve yanıtı, Drive dolaşma, kappa, Türkçe ekler)
Rscript tests/uctan_uca.R   # 146 yapay ödevle 02-05 adımları; yerel sahte OpenAI sunucusu
```

Uçtan uca test, yapay kodlamaları bildirideki dağılımla (61/34/26/23 ve 83/49, 38/16...) üretir ve `05_analiz.R`'nin bildirideki cümleleri ("144 ödevin 61'i (%42,4) ...", "83 ödevin yalnızca 49'unda, yani bu ödevlerin %59,0'ında ...") birebir üretip üretmediğini denetler. 429 ve 500 hatalarından sonra yeniden deneme, kesik yanıt, model reddi, 400 hatasında durma ve kaldığı yerden devam etme senaryoları da sınanır.

## Kaynaklar

- Atıl, B., vd. (2025). Non-determinism of "deterministic" LLM system settings in hosted environments. *Proceedings of the 5th Workshop on Evaluation and Comparison of NLP Systems*, 135-148. https://doi.org/10.18653/v1/2025.eval4nlp-1.12
- Borges, B., vd. (2024). Could ChatGPT get an engineering degree? Evaluating higher education vulnerability to AI assistants. *PNAS, 121*(49), e2414955121. https://doi.org/10.1073/pnas.2414955121
- Chen, L., Zaharia, M., & Zou, J. (2024). How is ChatGPT's behavior changing over time? *Harvard Data Science Review, 6*(2). https://doi.org/10.1162/99608f92.5317da47
- Gallifant, J., vd. (2025). The TRIPOD-LLM reporting guideline for studies using large language models. *Nature Medicine, 31*(1), 60-69. https://doi.org/10.1038/s41591-024-03425-5
- OpenAI. OpenAPI tanımı (`openai/openai-openapi`, Ekim 2026): `CreateResponse` (`instructions`, `store`, `reasoning`), `seed` alanının Chat Completions'ta "deprecated" ve "best effort" olarak tanımlanması.
