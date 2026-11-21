# Geliştirme günlüğü

## 2026-11-21 — v0.1 ilk sürüm
- Godot 4.3 projesi, Android APK iş akışı (son-surum), bulut önizleme + 3 günlük denge botu.
- Tohumdan ada üretimi (6 biyom), ağaç/kaya/ot/fidan/dut/havuç/mezar, yeniden büyüme.
- Oyuncu (kodla çizilmiş, bereli hayatta kalan), Can/Açlık/Akıl, gece-gündüz, ateş ve meşale ışığı, karanlık saldırısı.
- 3 zombi türü, mezardan doğma, güneşte yanma, duvar dövme.
- 13 tarifli üretim paneli, 12 yuvalı envanter, El/Gövde kuşanma, yapı kurma (ateş, tezgâh, duvar).
- Otomatik kayıt, ana menü, ölüm ekranı, başlangıç ipuçları, kodla üretilen sesler.
- Bot (3 gün): 3. gecenin sonunda öldü → gece zombi sayısı 3+1.6g'den 2+1.4g'ye indirildi.

## 2026-11-21 — Sprite Atölye görselleri
- `assets/siparis.json` (38 görsel: oyuncu, 3 zombi, 14 dünya nesnesi, 18 ikon) + `gorsel_uret.yml` + `araclar/gorsel_uret.py`.
- Oyun görsel varsa onu çizer (karakterlerde kâğıt kukla animasyonu: sekme, sallanma, saldırıda eğilme, yöne göre aynalama),
  yoksa kodla çizer. Kamp ateşinde alev kodla üstte çizilir. Yer tutucu görsellerle önizlemede denendi.
- İlk çizim (36 görsel, GPU ≈ 709 sn ≈ 0,12 $): karakterler, ölü ağaç, kaya, mezarlar, ot, tezgâh çok iyi.
  Desen/duvar kâğıdı ya da sahne çıkanlar (çoğu ikon, dut çalısı, duvar), karlı ağaç tabanı ve alevli kamp ateşi
  için tarifler "tek nesne" olacak şekilde yeniden yazıldı; betik artık yeniden çizimde 2 aday üretip en az
  dolu (desen olmayan) olanı seçiyor, ek negatif kelimeler gönderiyor.
