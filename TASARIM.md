# Zombimania — Tasarım

**Tür:** Don't Starve tarzı 2.5D hayatta kalma + Minecraft gibi toplanıp üretilen açık dünya + zombiler.
**Hedef:** Her gece biraz daha zor; oyuncu topla → üret → kamp kur → geceyi atlat döngüsünde ilerler.

## Çekirdek döngü (v0.1)
- **Dünya:** tohumdan üretilen 128×128 karoluk ada (8192 px). Biyomlar: Çayır, Orman, Kayalık, Bataklık, Kumsal, Deniz.
- **Gün döngüsü:** 1 gün = 8 dk. Gündüz %55, akşam %17, gece %28. Gece zifiri karanlık (Don't Starve gibi);
  ışıksız kalınca 5 sn sonra "karanlıktaki şey" ısırır (18 hasar / 2.5 sn).
- **Göstergeler:** Can 150, Açlık 150 (≈1.25 günde biter, bitince can gider), Akıl 200
  (gece karanlıkta hızlı düşer, ateş başında artar; 50 altında daha çok zombi, 0'da can gider).
- **Zombiler:** Yürüyen, Koşucu (3. günden), İri (5. günden). Gece sayısı ≈ 2 + gün×1.4 (en fazla 28),
  mezarlardan da çıkarlar. Güneş doğunca açık arazidekiler yanar; orman/bataklık gölgesinde yaşarlar.
  Duvarlara takılırsa duvarı döverler. Ateş ışığında yavaşlarlar.
- **Toplama:** Eylem tuşu basılı tutulunca en yakın hedefe yürür ve toplar/keser/saldırır.
  Ağaç = Balta, Kaya = Kazma, ot/fidan/dut/havuç elle. Ot, fidan ve dut zamanla yeniden büyür.
- **Craft (ÜRET):** Araç (Balta, Kazma), Işık (Meşale, Kamp Ateşi), Malzeme (İp), Hayatta Kal (Şifalı Lapa),
  Yapı (Çalışma Tezgâhı, Tahta Duvar*), Savaş (Mızrak*, Tahta Zırh*), Yemek (ateşte pişirme). *Tezgâh yanında.
- **Kayıt:** 20 sn'de bir ve uygulama arka plana geçince otomatik. Ölünce kayıt silinir (Don't Starve gibi).

## Kontroller
- Mobil: sol yarıda serbest joystick, sağ altta EYLEM (basılı tut), üstünde ÜRET. Envanterde dokun = kullan/kuşan/ye/kur,
  basılı tut = yere bırak. Sol üstte El/Gövde yuvası (dokun = çıkar), menü tuşu.
- PC: WASD/oklar, Boşluk = eylem, C/Tab = üretim, 1-0 = yuvalar, Esc = menü.

## Fikir havuzu / yol haritası
1. Harita ekranı (gezilen yerler açılır), pusula.
2. Sandık (depolama), çadır (geceyi uyuyarak geçirme, açlık bedeli).
3. Mevsimler (kış: soğuk göstergesi, kürk giysi), yağmur.
4. Yeni yaratıklar: tavşan (et), kurt sürüsü, gece örümcekleri; zombi türleri: tükürükçü, patlayan, sürü lideri.
5. 2. seviye tezgâh → demir aletler, tuzaklar, okçu kule.
6. Tarım: tohum ekme, çiftlik.
7. Mağaralar / yeraltı (Minecraft havası), maden: demir, altın.
8. Kodla çizilen görsellerin yerine Sprite Atölye'den üretilen çizimler.
9. Sonsuz dünya için parça (chunk) yükleme.
10. Müzik ve ortam sesleri (cırcır böceği, rüzgâr, gece gerilim müziği).
