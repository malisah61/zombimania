extends Node2D
## Dünyadaki her şey: ağaç, kaya, ot, mezar, kamp ateşi, duvar, yerdeki eşya...

const MAKS_YAKIT := 180.0
const DUVAR_CAN := 240.0

var oyun
var tur := ""
var cesit := 0
var vurus := 0           # kırılana kadar kalan vuruş
var dolu := true         # toplanabilir mi (ot, fidan, dut)
var son_hasat := -99999.0
var yakit := 0.0         # kamp ateşi
var dayanim := 0.0       # duvar canı
var esya_id := ""        # yerdeki eşya
var adet := 0
var esya_dayanim := -1
var hucre := Vector2i(-99999, -99999)

var _sallanma := 0.0
var _isik: PointLight2D

func kur(o, t: String, c: int) -> void:
	oyun = o
	tur = t
	cesit = c
	var v: Dictionary = Veri.NESNELER.get(tur, {})
	vurus = v.get("vurus", 0)
	if tur == "duvar":
		dayanim = DUVAR_CAN
	if tur == "kamp_atesi":
		_isik = PointLight2D.new()
		_isik.texture = oyun.isik_dokusu
		_isik.color = Color(1.0, 0.72, 0.42)
		_isik.position = Vector2(0, -16)
		add_child(_isik)
	set_process(tur == "kamp_atesi")
	queue_redraw()

func yaricap() -> float:
	return Veri.NESNELER.get(tur, {}).get("yaricap", 0.0)

func yaniyor() -> bool:
	return tur == "kamp_atesi" and yakit > 0.0

## Ateşin aydınlattığı yarıçap (dünya pikseli).
func isik_yaricapi() -> float:
	if not yaniyor():
		return 0.0
	return 140.0 + 200.0 * clampf(yakit / MAKS_YAKIT, 0.0, 1.0)

func salla() -> void:
	_sallanma = 1.0
	set_process(true)

func _process(d: float) -> void:
	if _sallanma > 0.0:
		_sallanma = maxf(0.0, _sallanma - d * 3.0)
	if tur == "kamp_atesi":
		if yakit > 0.0:
			yakit = maxf(0.0, yakit - d)
		var r := isik_yaricapi()
		_isik.enabled = r > 0.0
		if r > 0.0:
			var titre := 1.0 + sin(Time.get_ticks_msec() * 0.011) * 0.03 + sin(Time.get_ticks_msec() * 0.023) * 0.02
			_isik.texture_scale = r * 2.0 / 256.0 * titre
			_isik.energy = 1.25
		queue_redraw()
	elif _sallanma > 0.0:
		queue_redraw()
	else:
		set_process(false)
		queue_redraw()

func _gorsel_ciz(s: float) -> bool:
	var ad := tur
	var boy_carpan := 1.0
	var renk := Color.WHITE
	match tur:
		"agac":
			if cesit % 7 == 0 and Cizim.doku("agac_2") != null:
				ad = "agac_2"
		"mezar":
			if cesit % 2 == 1 and Cizim.doku("mezar_2") != null:
				ad = "mezar_2"
		"kaya":
			boy_carpan = 0.6 + 0.4 * float(vurus) / 5.0
		"ot", "fidan":
			if not dolu:
				boy_carpan = 0.3
				renk = Color(0.75, 0.7, 0.6)
		"dut_calisi":
			if not dolu:
				if Cizim.doku("dut_calisi_bos") != null:
					ad = "dut_calisi_bos"
				else:
					renk = Color(0.7, 0.75, 0.7)
		"duvar":
			renk = Color.WHITE.lerp(Color(0.6, 0.5, 0.45), 1.0 - dayanim / DUVAR_CAN)
		"esya":
			return false
	var t := Cizim.doku(ad)
	if t == null:
		return false
	var boy: float = Veri.GORSEL_BOY.get(ad, 100.0) * boy_carpan
	var gen := boy * t.get_width() / t.get_height()
	Cizim.golge(self, gen * 0.42)
	Cizim.resim(self, t, boy, -s * 0.012 * (2.0 if tur == "agac" else 1.0), 1.0 if cesit % 2 == 0 or tur in ["tezgah", "duvar"] else -1.0, renk)
	if tur == "kamp_atesi":
		Cizim.alev(self, yakit / MAKS_YAKIT, Time.get_ticks_msec() / 1000.0, -boy * 0.35)
	return true

func _draw() -> void:
	var s := sin(_sallanma * 18.0) * _sallanma * 4.0
	if _gorsel_ciz(s):
		return
	match tur:
		"agac":
			Cizim.agac(self, cesit, 1.0 - float(vurus) / 6.0, s)
		"olu_agac":
			draw_set_transform(Vector2(s, 0))
			Cizim.olu_agac(self, cesit)
		"kaya":
			draw_set_transform(Vector2(s * 0.5, 0))
			Cizim.kaya(self, cesit, 0.5 + 0.5 * float(vurus) / 5.0)
		"fidan":
			Cizim.fidan(self, dolu)
		"ot":
			Cizim.ot(self, dolu, cesit, s)
		"dut_calisi":
			Cizim.dut_calisi(self, dolu, cesit)
		"havuc":
			Cizim.havuc(self)
		"mezar":
			Cizim.mezar(self, cesit)
		"kamp_atesi":
			Cizim.kamp_atesi(self, yakit / MAKS_YAKIT, Time.get_ticks_msec() / 1000.0)
		"tezgah":
			Cizim.tezgah(self)
		"duvar":
			draw_set_transform(Vector2(s, 0))
			Cizim.duvar(self, dayanim / DUVAR_CAN, cesit)
		"esya":
			Cizim.golge(self, 12)
			Cizim.simge(self, esya_id, Vector2(0, -12), 0.6)
			if adet > 1:
				draw_string(ThemeDB.fallback_font, Vector2(6, 2), str(adet), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func kayit() -> Array:
	return [tur, roundi(position.x), roundi(position.y), cesit, vurus, dolu, snappedf(son_hasat, 0.1), snappedf(yakit, 0.1), snappedf(dayanim, 0.1), esya_id, adet, esya_dayanim]

func yukle(a: Array) -> void:
	vurus = int(a[4])
	dolu = bool(a[5])
	son_hasat = float(a[6])
	yakit = float(a[7])
	dayanim = float(a[8])
	esya_id = str(a[9])
	adet = int(a[10])
	esya_dayanim = int(a[11])
	queue_redraw()
