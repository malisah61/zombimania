# Zombimania — proje notları

- Don't Starve tarzı 2.5D zombili açık dünya hayatta kalma oyunu (craft'lı). Motor: Godot 4.3, GDScript,
  renderer: GL Compatibility. Android, **yatay ekran** (sensor_landscape), arm64. Kullanıcı geniş (20:9) telefonda oynar.
- Kullanıcıyla ve oyun içinde **Türkçe**. Kod adları da Türkçe (mevcut düzeni koru).
- **Önce oku:** `TASARIM.md` (tasarım, sayılar, yol haritası) ve `GUNLUK.md` (önceki çalışmalar).
- Betikler `betikler/`: `oyun.gd` yönetici (zaman, eylem, envanter, craft, doğuş, kayıt, bot, önizleme),
  `dunya.gd` (ada üretimi, zemin, ızgara), `nesne.gd` (dünya nesneleri), `oyuncu.gd`, `zombi.gd`,
  `arayuz.gd` (tüm arayüz elle çizilir, dokunmalar elle işlenir), `cizim.gd` (bütün görseller kodla çizilir),
  `veri.gd` (eşya, tarif, nesne, zombi tabloları), `sesler.gd` (kodla üretilen sesler).
- Diğer betiklere referanslar bilerek tipsiz (`var oyun`). Başka betiğin sabitine örnek üzerinden değil,
  preload edilmiş betik üzerinden eriş (`OYUNCU.MAKS_CAN`, `NESNE.MAKS_YAKIT`).
- **Görseller Sprite Atölye'den:** `assets/siparis.json` (ad, prompt, boy) → `gorsel_uret.yml` iş akışı
  Sprite Atölye Modal motoruyla (`SPRITE_KEY` repo sırrı) eksikleri çizer → `assets/gorseller/<ad>.png`
  (2× boyda) → APK ve önizlemeyi tetikler. Claude kullanımı harcamaz. Oyun `Cizim.doku(ad)` ile görseli
  kullanır, yoksa kodla çizime düşer (ikisi de çalışır kalmalı). Yeni nesne/eşya eklerken siparişe ve
  `Veri.GORSEL_BOY`'a da ekle; ikonlar `ikon_<eşya_id>`. Beğenilmeyen görsel: iş akışını `yeniden=<ad>` ile çalıştır.
- Başka görsel dosyası eklenirse `assets/` altına, kaynağı/lisansı `assets/KAYNAKLAR.md`'ye.
  Sadece ticari kullanıma izin veren ücretsiz kaynaklar (CC0 / CC-BY atıfla). `assets/sesler/<ad>.ogg` konursa
  `sesler.gd` kodla üretilen sesin yerine onu kullanır.
- Derleme: `main`'e her gönderimde `android.yml` APK derler ve `son-surum` sürümüne yükler:
  https://github.com/malisah61/zombimania/releases/download/son-surum/Zombimania.apk
- Kontrol: `onizleme.yml` oyunu bulutta açıp `onizleme/oyun/*.png` ekran görüntülerini depoya yazar ve
  3 günlük denge botunu çalıştırır. Görüntüleri aç ve bak; kayıtta "SCRIPT ERROR" / "Parse Error" olmamalı.
  Yerelde: `godot --headless --path . --fixed-fps 60 -- --bot=3` ve
  `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --onizleme=/tmp/on`.
  Yeni özellik eklersen `_onizleme()` akışına onu gösteren bir kare ekle.
- Kayıt `user://kayit.json`: dünya (biyom + bütün nesneler) tamamen kaydedilir, üretim koduna bağlı değildir.
  Yeni alan eklerken `.get(alan, varsayılan)` ile oku; eski kayıtları bozma (oyuncunun dünyası gider).
- **Var olan özellikleri eksiltme.** Bir şeyi değiştirirken eskisinin yaptığı her şey çalışmaya devam etmeli.
- Performans: oyun sırasında gereksiz düğüm oluşturma; değişmeyen nesneler `set_process(false)` ile durur;
  dünya nesneleri tek tek değil, ızgara (`dunya.yakin`) üzerinden aranır.
