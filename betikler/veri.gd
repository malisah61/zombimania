class_name Veri
extends RefCounted
## İçerik tabloları: eşyalar, tarifler, zombi türleri, biyomlar.

const KAROSU := 64            # bir karonun piksel boyu
const HARITA := 128           # harita kenarı (karo)
const GUN_SURE := 480.0       # bir gün kaç saniye
const AKSAM_BAS := 0.55       # gün içindeki oran: akşam başlangıcı
const GECE_BAS := 0.72        # gece başlangıcı
const ENVANTER := 12          # envanter yuvası

enum Biyom { SU, KUMSAL, CAYIR, ORMAN, KAYALIK, BATAKLIK }

const BIYOM_AD := ["Deniz", "Kumsal", "Çayır", "Orman", "Kayalık", "Bataklık"]

## tur: malzeme / arac / yemek / yapi / zirh
## yigin: bir yuvada en fazla kaç tane
const ESYALAR := {
	"odun": {"ad": "Odun", "tur": "malzeme", "yigin": 20, "yakit": 60.0},
	"dal": {"ad": "Dal", "tur": "malzeme", "yigin": 20, "yakit": 25.0},
	"ot": {"ad": "Ot", "tur": "malzeme", "yigin": 20, "yakit": 20.0},
	"tas": {"ad": "Taş", "tur": "malzeme", "yigin": 20},
	"cakmak": {"ad": "Çakmaktaşı", "tur": "malzeme", "yigin": 20},
	"ip": {"ad": "İp", "tur": "malzeme", "yigin": 20},
	"dut": {"ad": "Dut", "tur": "yemek", "yigin": 20, "aclik": 9.0, "can": 0.0, "akil": 0.0},
	"havuc": {"ad": "Havuç", "tur": "yemek", "yigin": 20, "aclik": 12.0, "can": 1.0, "akil": 0.0},
	"curuk_et": {"ad": "Çürük Et", "tur": "yemek", "yigin": 20, "aclik": 18.0, "can": -5.0, "akil": -12.0},
	"pismis_dut": {"ad": "Pişmiş Dut", "tur": "yemek", "yigin": 20, "aclik": 14.0, "can": 1.0, "akil": 2.0},
	"pismis_havuc": {"ad": "Pişmiş Havuç", "tur": "yemek", "yigin": 20, "aclik": 16.0, "can": 4.0, "akil": 2.0},
	"kizarmis_et": {"ad": "Kızarmış Et", "tur": "yemek", "yigin": 20, "aclik": 28.0, "can": 0.0, "akil": -4.0},
	"lapa": {"ad": "Şifalı Lapa", "tur": "yemek", "yigin": 10, "aclik": 0.0, "can": 30.0, "akil": 0.0},
	"balta": {"ad": "Balta", "tur": "arac", "yigin": 1, "dayanim": 50, "hasar": 22.0},
	"kazma": {"ad": "Kazma", "tur": "arac", "yigin": 1, "dayanim": 40, "hasar": 20.0},
	"mesale": {"ad": "Meşale", "tur": "arac", "yigin": 1, "dayanim": 90, "hasar": 14.0},
	"mizrak": {"ad": "Mızrak", "tur": "arac", "yigin": 1, "dayanim": 80, "hasar": 36.0},
	"tahta_zirh": {"ad": "Tahta Zırh", "tur": "zirh", "yigin": 1, "dayanim": 200, "koruma": 0.6},
	"kamp_atesi": {"ad": "Kamp Ateşi", "tur": "yapi", "yigin": 5},
	"tezgah": {"ad": "Çalışma Tezgâhı", "tur": "yapi", "yigin": 1},
	"duvar": {"ad": "Tahta Duvar", "tur": "yapi", "yigin": 20},
}

## yakin: "" = her yerde, "ates" = yanan kamp ateşi yanında, "tezgah" = tezgâh yanında
const TARIFLER := [
	{"id": "balta", "adet": 1, "gerek": {"dal": 1, "cakmak": 1}, "yakin": "", "kat": "Araç"},
	{"id": "kazma", "adet": 1, "gerek": {"dal": 2, "cakmak": 2}, "yakin": "", "kat": "Araç"},
	{"id": "mesale", "adet": 1, "gerek": {"dal": 2, "ot": 2}, "yakin": "", "kat": "Işık"},
	{"id": "kamp_atesi", "adet": 1, "gerek": {"ot": 3, "odun": 2}, "yakin": "", "kat": "Işık"},
	{"id": "ip", "adet": 1, "gerek": {"ot": 3}, "yakin": "", "kat": "Malzeme"},
	{"id": "lapa", "adet": 1, "gerek": {"ot": 2, "dut": 2}, "yakin": "", "kat": "Hayatta Kal"},
	{"id": "tezgah", "adet": 1, "gerek": {"odun": 4, "tas": 4}, "yakin": "", "kat": "Yapı"},
	{"id": "mizrak", "adet": 1, "gerek": {"dal": 2, "ip": 1, "cakmak": 1}, "yakin": "tezgah", "kat": "Savaş"},
	{"id": "tahta_zirh", "adet": 1, "gerek": {"odun": 6, "ip": 2}, "yakin": "tezgah", "kat": "Savaş"},
	{"id": "duvar", "adet": 2, "gerek": {"odun": 2, "dal": 1}, "yakin": "tezgah", "kat": "Yapı"},
	{"id": "pismis_dut", "adet": 1, "gerek": {"dut": 1}, "yakin": "ates", "kat": "Yemek"},
	{"id": "pismis_havuc", "adet": 1, "gerek": {"havuc": 1}, "yakin": "ates", "kat": "Yemek"},
	{"id": "kizarmis_et", "adet": 1, "gerek": {"curuk_et": 1}, "yakin": "ates", "kat": "Yemek"},
]

const KATEGORILER := ["Araç", "Işık", "Malzeme", "Hayatta Kal", "Savaş", "Yapı", "Yemek"]

## Dünya nesneleri. yaricap > 0 ise içinden geçilmez.
## arac: kırmak için gereken alet ("" = el). vurus: kaç vuruşta biter.
const NESNELER := {
	"agac": {"yaricap": 16.0, "arac": "balta", "vurus": 6},
	"olu_agac": {"yaricap": 14.0, "arac": "balta", "vurus": 4},
	"kaya": {"yaricap": 24.0, "arac": "kazma", "vurus": 5},
	"fidan": {"yaricap": 0.0, "arac": "", "vurus": 1, "yenilenir": 300.0},
	"ot": {"yaricap": 0.0, "arac": "", "vurus": 1, "yenilenir": 260.0},
	"dut_calisi": {"yaricap": 10.0, "arac": "", "vurus": 1, "yenilenir": 600.0},
	"havuc": {"yaricap": 0.0, "arac": "", "vurus": 1},
	"mezar": {"yaricap": 14.0, "arac": "", "vurus": 0},
	"kamp_atesi": {"yaricap": 0.0, "arac": "", "vurus": 0},
	"tezgah": {"yaricap": 22.0, "arac": "", "vurus": 0},
	"duvar": {"yaricap": 24.0, "arac": "", "vurus": 0},
	"esya": {"yaricap": 0.0, "arac": "", "vurus": 0},
}

const ZOMBILER := {
	"yuruyen": {"can": 60.0, "hiz": 70.0, "hasar": 10.0, "boy": 1.0, "renk": Color(0.47, 0.58, 0.42)},
	"kosucu": {"can": 40.0, "hiz": 140.0, "hasar": 7.0, "boy": 0.85, "renk": Color(0.58, 0.55, 0.40)},
	"iri": {"can": 220.0, "hiz": 50.0, "hasar": 25.0, "boy": 1.45, "renk": Color(0.38, 0.47, 0.40)},
}

## Sprite Atölye görsellerinin oyundaki yüksekliği (piksel). assets/siparis.json'daki "boy" ile aynı tutulur.
const GORSEL_BOY := {
	"oyuncu": 140.0, "zombi_yuruyen": 140.0, "zombi_kosucu": 122.0, "zombi_iri": 200.0,
	"agac": 250.0, "agac_2": 230.0, "olu_agac": 210.0, "kaya": 95.0, "fidan": 75.0, "ot": 62.0,
	"dut_calisi": 85.0, "dut_calisi_bos": 85.0, "havuc": 42.0, "mezar": 95.0, "mezar_2": 105.0,
	"kamp_atesi": 52.0, "tezgah": 100.0, "duvar": 100.0,
}

static func esya(id: String) -> Dictionary:
	return ESYALAR.get(id, {"ad": id, "tur": "malzeme", "yigin": 20})

static func ad(id: String) -> String:
	return esya(id).get("ad", id)
