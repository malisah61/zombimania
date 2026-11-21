"""Sprite Atölye motoruyla assets/siparis.json'daki eksik görselleri çizer.

Ortam değişkenleri: MOTOR_URL, SPRITE_KEY, YENIDEN (virgülle ad listesi ya da "hepsi"), SADECE (virgülle ad listesi)
Her görsel: motor (auto=true → arka plan/gölge temizliği) → en büyük figür kırpılır → 'boy' yüksekliğine küçültülür.
"""
import base64, io, json, os, sys, time, urllib.request
from PIL import Image

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIKTI = os.path.join(KOK, "assets", "gorseller")
URL = os.environ.get("MOTOR_URL", "https://malisah61--sprite-atolye-motor-web.us-east.modal.run")
ANAHTAR = os.environ.get("SPRITE_KEY", "")


def liste(ad):
    v = os.environ.get(ad, "").strip()
    return [x.strip() for x in v.split(",") if x.strip()]


def ciz(govde, deneme=3):
    for i in range(deneme):
        try:
            req = urllib.request.Request(URL + "/generate", data=json.dumps(govde).encode(),
                                         headers={"Content-Type": "application/json", "X-Sprite-Key": ANAHTAR})
            return json.load(urllib.request.urlopen(req, timeout=900))
        except Exception as e:  # motor soğuk başlarken ilk istek düşebilir
            print(f"  deneme {i + 1} başarısız: {e}")
            if "401" in str(e):
                sys.exit("SPRITE_KEY yanlış ya da eksik (repo Settings > Secrets > Actions).")
            time.sleep(20)
    return None


VARSAYILAN_NEGATIF = ("text, watermark, blurry, cropped, multiple characters, character sheet, duplicate, multiple views, "
                      "cast shadow, drop shadow, frame, border, patterned background, wallpaper, scenery, landscape")


def doluluk(png_b64):
    """Görselin ne kadarı dolu (0-1). Desen/duvar kâğıdı çıkınca neredeyse 1 olur."""
    im = Image.open(io.BytesIO(base64.b64decode(png_b64))).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v > 24 else 0)
    return sum(a.histogram()[255:]) / (im.width * im.height)


def hazirla(png_b64, boy):
    im = Image.open(io.BytesIO(base64.b64decode(png_b64))).convert("RGBA")
    kutu = im.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
    if kutu:
        im = im.crop(kutu)
    if im.height > boy * 2:  # oyunda 2 kat net görünsün diye 2× boyda sakla
        oran = boy * 2 / im.height
        im = im.resize((max(1, round(im.width * oran)), boy * 2), Image.LANCZOS)
    return im


def main():
    s = json.load(open(os.path.join(KOK, "assets", "siparis.json"), encoding="utf-8"))
    os.makedirs(CIKTI, exist_ok=True)
    yeniden, sadece = liste("YENIDEN"), liste("SADECE")
    yapilan, gpu = [], 0.0
    for i, sp in enumerate(s["siparisler"]):
        ad = sp["ad"]
        yol = os.path.join(CIKTI, ad + ".png")
        if sadece and ad not in sadece:
            continue
        if os.path.exists(yol) and "hepsi" not in yeniden and ad not in yeniden:
            continue
        govde = {
            "prompt": f"{sp['prompt']}, {s['stil']}",
            "style": "other", "n": 1, "seed": int(sp.get("seed", 1000 + i)),
            "width": sp.get("w", 1024), "height": sp.get("h", 1024),
            "auto": True, "lora": sp.get("lora", s.get("lora")),
            "negative": (VARSAYILAN_NEGATIF + ", " + s.get("negatif_ek", ""))[:500],
        }
        if ad in yeniden or "hepsi" in yeniden:
            govde["n"] = 2  # yeniden çizimde 2 aday, en temiz olanı seçilir
        print(f"→ {ad}")
        d = ciz(govde)
        if not d or not d.get("images"):
            print(f"  ✗ {ad} çizilemedi")
            continue
        # desen/sahne gibi her yeri dolu adayları ele: en az dolu (ama boş olmayan) aday seçilir
        adaylar = sorted(((doluluk(b), b) for b in d["images"]), key=lambda x: x[0])
        adaylar = [x for x in adaylar if x[0] > 0.03] or adaylar
        print(f"  doluluk: {[round(x[0], 2) for x in adaylar]}")
        if adaylar[0][0] > 0.85:
            print(f"  ⚠ {ad}: arka plan temizlenememiş görünüyor")
        hazirla(adaylar[0][1], int(sp["boy"])).save(yol, optimize=True)
        gpu += float(d.get("seconds", 0))
        yapilan.append(ad)
        print(f"  ✓ {ad} ({d.get('seconds')} sn)")
    ozet = f"{len(yapilan)} görsel çizildi, toplam GPU ≈ {round(gpu)} sn (≈ {gpu / 3600 * 0.59:.2f} $ T4): {', '.join(yapilan) or '-'}"
    print(ozet)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        open(os.environ["GITHUB_STEP_SUMMARY"], "a").write(ozet + "\n")


if __name__ == "__main__":
    main()
