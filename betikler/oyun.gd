extends Node2D
## Zombimania yöneticisi: dünya, zaman, oyuncu eylemleri, envanter, craft, zombi doğuşu, kayıt.

const DUNYA := preload("res://betikler/dunya.gd")
const OYUNCU := preload("res://betikler/oyuncu.gd")
const ZOMBI := preload("res://betikler/zombi.gd")
const NESNE := preload("res://betikler/nesne.gd")
const ARAYUZ := preload("res://betikler/arayuz.gd")
const SESLER := preload("res://betikler/sesler.gd")
const KAYIT_YOLU := "user://kayit.json"
const KAYIT_SURUM := 1

var dunya
var oyuncu
var kamera: Camera2D
var gece: CanvasModulate
var arayuz
var sesler
var isik_dokusu: Texture2D

var oynaniyor := false
var bitti := false
var zaman := 0.0
var isik_gucu := 0.0      # 0 = gündüz, 1 = zifiri karanlık
var envanter: Array = []
var el := {}
var govde := {}
var zombiler: Array = []
var oldurulen := 0
var son_carpan = null
var eylem_basili := false
var craft_acik := false
var ipucu := ""

var _eylem_bekleme := 0.0
var _dogma_t := 2.0
var _kayit_t := 0.0
var _yenile_t := 0.0
var _ipucu_t := 0.0
var _karanlik_t := 0.0
var _karanlik_vurus_t := 0.0
var _son_faz := -1
var _son_gun := 0
var _uyari := {}
var _ates_kuruldu := false
var _onizleme_yolu := ""
var _bot := 0             # --bot=N : N gün kendi kendine oynar, denge raporu basar
var _bot_t := 0.0
var _bot_yon := Vector2.ZERO
var _bot_yon_t := 0.0

func _ready() -> void:
	randomize()
	get_tree().set_auto_accept_quit(false)
	isik_dokusu = _isik_dokusu_yap()
	sesler = SESLER.new()
	add_child(sesler)
	gece = CanvasModulate.new()
	add_child(gece)
	dunya = DUNYA.new()
	dunya.oyun = self
	add_child(dunya)
	kamera = Camera2D.new()
	kamera.position_smoothing_enabled = true
	kamera.position_smoothing_speed = 7.0
	add_child(kamera)
	var katman := CanvasLayer.new()
	add_child(katman)
	arayuz = ARAYUZ.new()
	arayuz.oyun = self
	katman.add_child(arayuz)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--onizleme="):
			_onizleme_yolu = a.substr(11)
		elif a.begins_with("--bot="):
			_bot = int(a.substr(6))
	if _bot > 0:
		yeni_oyun(777)
	elif _onizleme_yolu != "":
		_onizleme()
	else:
		arayuz.menu_goster()

func _isik_dokusu_yap() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1), Color(0.62, 0.62, 0.62), Color(0, 0, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

# ---------------------------------------------------------------- oyun başlat / bitir

func _temizle() -> void:
	for z in zombiler:
		z.queue_free()
	zombiler.clear()
	for n in dunya.varliklar.get_children():
		dunya.varliklar.remove_child(n)
		n.queue_free()
	dunya.izgara.clear()
	dunya.yenilenenler.clear()
	dunya.mezarlar.clear()
	dunya.atesler.clear()
	oyuncu = null
	el = {}
	govde = {}
	envanter.clear()
	for i in Veri.ENVANTER:
		envanter.append({})
	bitti = false
	oldurulen = 0
	_son_faz = -1
	_son_gun = 0
	_karanlik_t = 0.0
	_ates_kuruldu = false
	craft_acik = false

func _oyuncu_kur(p: Vector2) -> void:
	oyuncu = OYUNCU.new()
	oyuncu.oyun = self
	oyuncu.position = p
	dunya.varliklar.add_child(oyuncu)
	var b: float = dunya.boyut()
	kamera.limit_left = 0
	kamera.limit_top = 0
	kamera.limit_right = int(b)
	kamera.limit_bottom = int(b)
	kamera.position = p
	kamera.reset_smoothing()

func yeni_oyun(t: int) -> void:
	_temizle()
	dunya.uret(t)
	_oyuncu_kur(dunya.baslangic)
	zaman = Veri.GUN_SURE * 0.03
	oynaniyor = true
	_son_gun = gun()
	_son_faz = faz()
	arayuz.oyun_basladi()
	mesaj("Gün 1 — Hayatta kal!")
	kaydet()

func kayit_var() -> bool:
	return FileAccess.file_exists(KAYIT_YOLU)

func kaydet() -> void:
	if not oynaniyor or bitti or oyuncu == null:
		return
	var v := {
		"surum": KAYIT_SURUM,
		"zaman": zaman,
		"oyuncu": [oyuncu.position.x, oyuncu.position.y, oyuncu.can, oyuncu.aclik, oyuncu.akil],
		"envanter": envanter, "el": el, "govde": govde,
		"oldurulen": oldurulen, "ates_kuruldu": _ates_kuruldu,
		"dunya": dunya.kayit(),
	}
	var f := FileAccess.open(KAYIT_YOLU, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(v))
		f.close()

func devam_et() -> bool:
	var f := FileAccess.open(KAYIT_YOLU, FileAccess.READ)
	if f == null:
		return false
	var v = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(v) != TYPE_DICTIONARY or not v.has("dunya"):
		return false
	_temizle()
	dunya.yukle(v["dunya"])
	var o: Array = v["oyuncu"]
	_oyuncu_kur(Vector2(o[0], o[1]))
	oyuncu.can = float(o[2])
	oyuncu.aclik = float(o[3])
	oyuncu.akil = float(o[4])
	zaman = float(v["zaman"])
	var env: Array = v.get("envanter", [])
	for i in mini(env.size(), Veri.ENVANTER):
		envanter[i] = _yuva_duzelt(env[i])
	el = _yuva_duzelt(v.get("el", {}))
	govde = _yuva_duzelt(v.get("govde", {}))
	oldurulen = int(v.get("oldurulen", 0))
	_ates_kuruldu = bool(v.get("ates_kuruldu", false))
	oynaniyor = true
	_son_gun = gun()
	_son_faz = faz()
	arayuz.oyun_basladi()
	mesaj("Gün %d — kaldığın yerden devam." % gun())
	return true

func _yuva_duzelt(s) -> Dictionary:
	if typeof(s) != TYPE_DICTIONARY or not s.has("id") or not Veri.ESYALAR.has(str(s["id"])):
		return {}
	return {"id": str(s["id"]), "adet": int(s.get("adet", 1)), "dayanim": float(s.get("dayanim", -1))}

func _ol() -> void:
	bitti = true
	if _bot > 0:
		print("BOT: ÖLDÜ gün=%d oran=%.2f zombi_öldürülen=%d" % [gun(), gun_orani(), oldurulen])
		get_tree().quit()
	oyuncu.oto_hedef = null
	craft_acik = false
	if kayit_var():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(KAYIT_YOLU))
	arayuz.olum_goster(gun(), oldurulen)

func menuye_don() -> void:
	kaydet()
	oynaniyor = false
	craft_acik = false
	arayuz.menu_goster()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kaydet()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		kaydet()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if craft_acik:
			craft_acik = false
		elif oynaniyor and not bitti:
			menuye_don()
		else:
			kaydet()
			get_tree().quit()

# ---------------------------------------------------------------- zaman

func gun_orani() -> float:
	return fmod(zaman, Veri.GUN_SURE) / Veri.GUN_SURE

func gun() -> int:
	return int(zaman / Veri.GUN_SURE) + 1

## 0 = gündüz, 1 = akşam, 2 = gece
func faz() -> int:
	var o := gun_orani()
	if o < Veri.AKSAM_BAS:
		return 0
	if o < Veri.GECE_BAS:
		return 1
	return 2

func _gok_rengi() -> Color:
	var o := gun_orani()
	var gece_r := Color(0.05, 0.06, 0.12)
	var sabah := Color(0.80, 0.74, 0.80)
	var gunduz := Color(1, 1, 1)
	var aksam := Color(0.85, 0.64, 0.52)
	var alaca := Color(0.30, 0.25, 0.36)
	var k := [[0.0, gece_r], [0.035, sabah], [0.09, gunduz], [0.50, gunduz], [0.58, aksam], [0.68, alaca], [0.75, gece_r], [1.0, gece_r]]
	for i in k.size() - 1:
		if o <= k[i + 1][0]:
			var t: float = (o - k[i][0]) / (k[i + 1][0] - k[i][0])
			return (k[i][1] as Color).lerp(k[i + 1][1], t)
	return gece_r

# ---------------------------------------------------------------- ana döngü

func _process(d: float) -> void:
	if not oynaniyor or oyuncu == null:
		return
	if d > 0.1:
		d = 0.1
	var renk := _gok_rengi()
	gece.color = renk
	isik_gucu = clampf(1.0 - (renk.r + renk.g + renk.b) / 3.0, 0.0, 1.0)
	for a in dunya.atesler:
		if a._isik:
			a._isik.energy = 0.25 + 1.1 * isik_gucu
	kamera.position = oyuncu.position
	if bitti:
		for z in zombiler.duplicate():
			z.ilerle(d)
		return
	zaman += d
	_gun_faz_denetle()
	var g := _giris()
	if _bot > 0:
		g = _bot_isle(d)
	if g.length() > 0.15:
		oyuncu.oto_hedef = null
	eylem_basili = arayuz.eylem_basili or Input.is_key_pressed(KEY_SPACE) or _bot > 0
	_eylem(d)
	oyuncu.ilerle(d, g)
	for z in zombiler.duplicate():
		if z.position.distance_to(oyuncu.position) > 1800.0:
			zombiler.erase(z)
			z.queue_free()
			continue
		z.ilerle(d)
	_zombi_ayir()
	_istatistik(d)
	if bitti:
		return
	_dogur(d)
	_yerden_topla()
	_yenile_t -= d
	if _yenile_t <= 0.0:
		_yenile_t = 1.0
		dunya.yenilenmeyi_denetle(zaman)
	_ipucu_t -= d
	if _ipucu_t <= 0.0:
		_ipucu_t = 1.5
		ipucu = _ipucu_bul()
	_kayit_t += d
	if _kayit_t > 20.0:
		_kayit_t = 0.0
		kaydet()

func _giris() -> Vector2:
	var v := Vector2.ZERO
	if not craft_acik:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			v.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			v.x += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			v.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			v.y += 1
		v += arayuz.joystick
	return v

func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo or not oynaniyor or bitti:
		return
	var k: int = e.keycode
	if k == KEY_C or k == KEY_TAB:
		craft_acik = not craft_acik
	elif k >= KEY_1 and k <= KEY_9:
		kullan(k - KEY_1)
	elif k == KEY_0:
		kullan(9)
	elif k == KEY_ESCAPE:
		if craft_acik:
			craft_acik = false
		else:
			menuye_don()

func _gun_faz_denetle() -> void:
	var f := faz()
	var g := gun()
	if g != _son_gun:
		_son_gun = g
		mesaj("Gün %d" % g)
	if f != _son_faz:
		_son_faz = f
		if _bot > 0:
			_bot_rapor()
			if g > _bot:
				get_tree().quit()
		match f:
			1:
				mesaj("Hava kararıyor... gece gelmeden ateş yak!")
			2:
				mesaj("Gece çöktü. Işıkta kal!")
			0:
				mesaj("Güneş doğdu. Açıktaki zombiler yanıyor!")

# ---------------------------------------------------------------- hareket ve çarpışma

## eski -> hedef arası yürür; suya girmez, katı nesnelerden itilir. son_carpan = çarptığı nesne.
func hareket_et(eski: Vector2, hedef: Vector2, r: float) -> Vector2:
	var p := hedef
	if not dunya.kara_mi(p):
		var px := Vector2(hedef.x, eski.y)
		var py := Vector2(eski.x, hedef.y)
		if dunya.kara_mi(px):
			p = px
		elif dunya.kara_mi(py):
			p = py
		else:
			p = eski
	son_carpan = null
	for n in dunya.yakin(p, r + 40.0):
		var yr: float = n.yaricap()
		if yr <= 0.0:
			continue
		var fark: Vector2 = p - n.position
		var fk := Vector2(fark.x, fark.y * 1.7)
		var dl := fk.length()
		var en_az := r + yr
		if dl < en_az:
			son_carpan = n
			if dl < 0.01:
				fk = Vector2(1, 0)
				dl = 1.0
			var it := fk / dl * (en_az - dl)
			p += Vector2(it.x, it.y / 1.7)
	return p

func _zombi_ayir() -> void:
	var n := zombiler.size()
	for i in n:
		var a = zombiler[i]
		for j in range(i + 1, n):
			var b = zombiler[j]
			var f: Vector2 = a.position - b.position
			var dl := f.length()
			if dl < 26.0 and dl > 0.01:
				var it := f / dl * (26.0 - dl) * 0.5
				a.position += it
				b.position -= it

# ---------------------------------------------------------------- ışık

func mesale_yaniyor() -> bool:
	return el.get("id", "") == "mesale" and isik_gucu > 0.35

func ates_isiginda(p: Vector2) -> bool:
	for a in dunya.atesler:
		if a.yaniyor() and a.position.distance_to(p) < a.isik_yaricapi() * 0.85:
			return true
	return false

func isik_icinde(p: Vector2) -> bool:
	if faz() < 2:
		return true
	if mesale_yaniyor() and p.distance_to(oyuncu.position) < 240.0:
		return true
	return ates_isiginda(p)

# ---------------------------------------------------------------- istatistikler

func _istatistik(d: float) -> void:
	oyuncu.aclik = maxf(0.0, oyuncu.aclik - d * OYUNCU.MAKS_ACLIK / (Veri.GUN_SURE * 1.25))
	if oyuncu.aclik <= 0.0:
		oyuncu.can -= d * 1.2
		uyar("aclik", "Açlıktan ölüyorum!")
	elif oyuncu.aclik < 30.0:
		uyar("acikti", "Karnım çok acıktı...")
	var f := faz()
	var aydinlik := isik_icinde(oyuncu.position)
	var da := 0.0
	if f == 0:
		da = 0.05
	elif f == 1:
		da = -0.12
	else:
		da = -0.25 if aydinlik else -1.0
	if ates_isiginda(oyuncu.position):
		da += 0.3
	oyuncu.akil = clampf(oyuncu.akil + da * d, 0.0, OYUNCU.MAKS_AKIL)
	if oyuncu.akil <= 0.0:
		oyuncu.can -= d * 0.5
	elif oyuncu.akil < 50.0:
		uyar("akil", "Kafam karışıyor... gölgeler kıpırdıyor.")
	if f == 2 and not aydinlik:
		_karanlik_t += d
	else:
		_karanlik_t = 0.0
		_karanlik_vurus_t = 0.0
	if _karanlik_t > 1.5:
		uyar("karanlik", "Çok karanlık... bir şey yaklaşıyor!")
	if _karanlik_t > 5.0:
		_karanlik_vurus_t -= d
		if _karanlik_vurus_t <= 0.0:
			_karanlik_vurus_t = 2.5
			mesaj("Karanlıktaki bir şey seni ısırdı!")
			oyuncu_hasar(18.0, "karanlik")
	if mesale_yaniyor():
		el["dayanim"] = float(el.get("dayanim", 0.0)) - d
		if el["dayanim"] <= 0.0:
			el = {}
			mesaj("Meşalen söndü!")
	if oyuncu.can <= 0.0 and not bitti:
		oyuncu.can = 0.0
		_ol()

func oyuncu_hasar(m: float, _kaynak: String) -> void:
	if bitti:
		return
	if not govde.is_empty():
		var k: float = m * Veri.esya(govde["id"]).get("koruma", 0.0)
		govde["dayanim"] = float(govde["dayanim"]) - k
		m -= k
		if govde["dayanim"] <= 0.0:
			mesaj("Zırhın parçalandı!")
			govde = {}
			sesler.cal("kirildi")
	oyuncu.can -= m
	oyuncu.hasar_t = 1.0
	arayuz.hasar_flas()
	sesler.cal("yan")
	if oyuncu.can <= 0.0:
		oyuncu.can = 0.0
		_ol()

# ---------------------------------------------------------------- eylem (topla / kes / saldır)

func _eylem(d: float) -> void:
	_eylem_bekleme -= d
	if not eylem_basili or craft_acik:
		if not eylem_basili:
			oyuncu.oto_hedef = null
		return
	var h = _hedef_sec()
	if h == null:
		oyuncu.oto_hedef = null
		_neden_olmuyor()
		return
	var zombi_mi := zombiler.has(h)
	var menzil: float = 62.0 if zombi_mi else h.yaricap() + 44.0
	if oyuncu.position.distance_to(h.position) > menzil:
		oyuncu.oto_hedef = h
		return
	oyuncu.oto_hedef = null
	if _eylem_bekleme > 0.0:
		return
	var f: Vector2 = h.position - oyuncu.position
	if f.length() > 1.0:
		oyuncu.yon = f.normalized()
	if zombi_mi:
		_saldir(h)
	else:
		_etkiles(h)

func _hedef_sec():
	var en = null
	var en_m := 1e9
	for z in zombiler:
		var m: float = z.position.distance_to(oyuncu.position)
		if m < 200.0 and m < en_m:
			en = z
			en_m = m
	if en != null and en_m < 120.0:
		return en
	var eli: String = el.get("id", "")
	for n in dunya.yakin(oyuncu.position, 210.0):
		if not _etkilesilebilir(n, eli):
			continue
		var m: float = n.position.distance_to(oyuncu.position)
		if m < en_m:
			en = n
			en_m = m
	return en

func _etkilesilebilir(n, eli: String) -> bool:
	match n.tur:
		"agac", "olu_agac":
			return eli == "balta"
		"kaya":
			return eli == "kazma"
		"fidan", "ot", "dut_calisi":
			return n.dolu
		"havuc", "esya":
			return true
		"kamp_atesi":
			return n.yakit < NESNE.MAKS_YAKIT - 15.0 and _yakit_bul() != ""
	return false

func _neden_olmuyor() -> void:
	var eli: String = el.get("id", "")
	for n in dunya.yakin(oyuncu.position, 90.0):
		if n.tur in ["agac", "olu_agac"] and eli != "balta":
			uyar("balta", "Ağaç kesmek için Balta kuşanmalıyım.")
			return
		if n.tur == "kaya" and eli != "kazma":
			uyar("kazma", "Kayayı kırmak için Kazma kuşanmalıyım.")
			return

func _yakit_bul() -> String:
	for id in ["ot", "dal", "odun"]:
		if say(id) > 0:
			return id
	return ""

func _etkiles(n) -> void:
	match n.tur:
		"agac", "olu_agac", "kaya":
			n.vurus -= 1
			n.salla()
			oyuncu.saldiri = 1.0
			_eylem_bekleme = 0.42
			sesler.cal("kes" if n.tur != "kaya" else "vur", 0.7)
			_alet_yipran()
			if n.vurus <= 0:
				var p: Vector2 = n.position
				if n.tur == "agac":
					_ver("odun", randi_range(2, 3), p)
					if randf() < 0.4:
						_ver("dal", 1, p)
				elif n.tur == "olu_agac":
					_ver("odun", randi_range(1, 2), p)
				else:
					_ver("tas", randi_range(2, 3), p)
					if randf() < 0.6:
						_ver("cakmak", 1, p)
				dunya.kaldir(n)
		"fidan", "ot", "dut_calisi":
			var ne: Array = {"fidan": ["dal", 1], "ot": ["ot", 1], "dut_calisi": ["dut", 2]}[n.tur]
			_ver(ne[0], ne[1], n.position)
			n.dolu = false
			n.son_hasat = zaman
			n.salla()
			dunya.yenilenenler.append(n)
			_eylem_bekleme = 0.3
			oyuncu.saldiri = 0.6
		"havuc":
			_ver("havuc", 1, n.position)
			dunya.kaldir(n)
			_eylem_bekleme = 0.3
		"esya":
			_esya_al(n)
		"kamp_atesi":
			var y := _yakit_bul()
			if y != "":
				harca(y, 1)
				n.yakit = minf(NESNE.MAKS_YAKIT, n.yakit + Veri.esya(y).get("yakit", 20.0))
				sesler.cal("topla", 0.6)
				arayuz.yazi_ekle("+ateş", n.position, Color(1, 0.7, 0.3))
				_eylem_bekleme = 0.35

func _saldir(z) -> void:
	var m := 8.0
	if not el.is_empty():
		m = Veri.esya(el["id"]).get("hasar", 8.0)
	z.vurul(m, oyuncu.position)
	oyuncu.saldiri = 1.0
	_eylem_bekleme = 0.5
	sesler.cal("vur" if not el.is_empty() else "yumruk")
	arayuz.yazi_ekle("-%d" % int(m), z.position + Vector2(0, -70), Color(1, 0.85, 0.4))
	_alet_yipran()

func _alet_yipran() -> void:
	if el.is_empty() or el["id"] == "mesale":
		return
	el["dayanim"] = float(el["dayanim"]) - 1.0
	if el["dayanim"] <= 0.0:
		mesaj("%s kırıldı!" % Veri.ad(el["id"]))
		el = {}
		sesler.cal("kirildi")

func zombi_oldu(z, oldurdu: bool) -> void:
	if oldurdu:
		oldurulen += 1
		var p: Vector2 = z.position
		if randf() < 0.7:
			dunya.esya_ekle(p + Vector2(randf_range(-14, 14), randf_range(-6, 6)), "curuk_et", 1, -1)
		if randf() < 0.15:
			dunya.esya_ekle(p + Vector2(randf_range(-14, 14), randf_range(-6, 6)), "ip", 1, -1)
		if z.tur == "iri":
			dunya.esya_ekle(p + Vector2(10, 4), "curuk_et", 2, -1)
	zombiler.erase(z)
	z.queue_free()

func duvara_vur(n, m: float) -> void:
	n.dayanim -= m
	n.salla()
	sesler.cal("vur", 0.35)
	if n.dayanim <= 0.0:
		dunya.kaldir(n)
		sesler.cal("kirildi", 0.6)

func zombi_ekle(p: Vector2, t: String):
	var z = ZOMBI.new()
	z.position = p
	dunya.varliklar.add_child(z)
	z.kur(self, t)
	zombiler.append(z)
	return z

func _zombi_turu() -> String:
	var g := gun()
	var r := randf()
	if g >= 5 and r < 0.10:
		return "iri"
	if g >= 3 and r < 0.32:
		return "kosucu"
	return "yuruyen"

func _dogur(d: float) -> void:
	_dogma_t -= d
	if _dogma_t > 0.0:
		return
	var f := faz()
	var g := gun()
	var hedef := 0
	match f:
		0:
			hedef = int(1 + g * 0.3)
		1:
			hedef = int(2 + g * 0.6)
		_:
			hedef = int(2 + g * 1.4)
	if oyuncu.akil < 50.0:
		hedef = int(hedef * 1.5) + 1
	hedef = mini(hedef, 28)
	_dogma_t = 3.0 if f == 2 else 6.0
	if zombiler.size() >= hedef:
		return
	var yakin_mezar: Array = []
	if f == 2:
		for m in dunya.mezarlar:
			var dm: float = m.position.distance_to(oyuncu.position)
			if dm > 500.0 and dm < 1200.0:
				yakin_mezar.append(m)
	for deneme in 12:
		var p: Vector2
		if yakin_mezar.size() > 0 and randf() < 0.45:
			p = yakin_mezar.pick_random().position + Vector2(randf_range(-30, 30), randf_range(14, 30))
		else:
			p = oyuncu.position + Vector2.from_angle(randf() * TAU) * randf_range(720.0, 1000.0)
		if not dunya.kara_mi(p) or ates_isiginda(p) or p.distance_to(oyuncu.position) < 450.0:
			continue
		if f == 0:
			var b: int = dunya.biyom_at(p)
			if b != Veri.Biyom.ORMAN and b != Veri.Biyom.BATAKLIK:
				continue
		zombi_ekle(p, _zombi_turu())
		return

func _yerden_topla() -> void:
	for n in dunya.yakin(oyuncu.position, 34.0):
		if n.tur == "esya":
			_esya_al(n)

func _esya_al(n) -> void:
	var kalan := ekle(n.esya_id, n.adet, n.esya_dayanim)
	if kalan < n.adet:
		sesler.cal("topla", 0.5)
		arayuz.yazi_ekle("+%d %s" % [n.adet - kalan, Veri.ad(n.esya_id)], n.position, Color(0.9, 1, 0.8))
	if kalan == 0:
		dunya.kaldir(n)
	else:
		n.adet = kalan
		n.queue_redraw()
		uyar("dolu", "Envanterim dolu!")

# ---------------------------------------------------------------- envanter

## Eşya ekler, sığmayan miktarı döndürür.
func ekle(id: String, adet: int, dayanim := -1.0) -> int:
	var e := Veri.esya(id)
	var yigin: int = e.get("yigin", 20)
	if yigin > 1:
		for s in envanter:
			if s.get("id", "") == id and s["adet"] < yigin:
				var k := mini(adet, yigin - s["adet"])
				s["adet"] += k
				adet -= k
				if adet <= 0:
					return 0
	for i in envanter.size():
		if envanter[i].is_empty():
			var k := mini(adet, yigin)
			var dd := dayanim if dayanim >= 0.0 else float(e.get("dayanim", -1))
			envanter[i] = {"id": id, "adet": k, "dayanim": dd}
			adet -= k
			if adet <= 0:
				return 0
	return adet

func _ver(id: String, adet: int, p: Vector2) -> void:
	var kalan := ekle(id, adet)
	if adet - kalan > 0:
		arayuz.yazi_ekle("+%d %s" % [adet - kalan, Veri.ad(id)], p + Vector2(0, -40), Color(0.9, 1, 0.8))
		sesler.cal("topla", 0.5)
	if kalan > 0:
		dunya.esya_ekle(oyuncu.position + Vector2(randf_range(-20, 20), 18), id, kalan, -1)
		uyar("dolu", "Envanterim dolu!")

func say(id: String) -> int:
	var t := 0
	for s in envanter:
		if s.get("id", "") == id:
			t += int(s["adet"])
	return t

func harca(id: String, adet: int) -> void:
	for i in range(envanter.size() - 1, -1, -1):
		var s: Dictionary = envanter[i]
		if s.get("id", "") == id:
			var k := mini(adet, int(s["adet"]))
			s["adet"] -= k
			adet -= k
			if s["adet"] <= 0:
				envanter[i] = {}
			if adet <= 0:
				return

func kullan(i: int) -> void:
	if i < 0 or i >= envanter.size() or bitti:
		return
	var s: Dictionary = envanter[i]
	if s.is_empty():
		return
	var e := Veri.esya(s["id"])
	match e.get("tur", ""):
		"yemek":
			_ye(i)
		"arac":
			var eski := el
			el = {"id": s["id"], "adet": 1, "dayanim": s["dayanim"]}
			envanter[i] = eski
			sesler.cal("topla", 0.5)
		"zirh":
			var eski := govde
			govde = {"id": s["id"], "adet": 1, "dayanim": s["dayanim"]}
			envanter[i] = eski
			sesler.cal("topla", 0.5)
		"yapi":
			_yerlestir(i)
		_:
			mesaj("%s — craft malzemesi." % e.get("ad", ""))

func birak(i: int) -> void:
	if i < 0 or i >= envanter.size() or bitti:
		return
	var s: Dictionary = envanter[i]
	if s.is_empty():
		return
	dunya.esya_ekle(oyuncu.position + oyuncu.yon.normalized() * 40.0, s["id"], s["adet"], int(s["dayanim"]))
	envanter[i] = {}
	mesaj("%s bırakıldı." % Veri.ad(s["id"]))

func el_cikar() -> void:
	if el.is_empty():
		return
	if ekle(el["id"], 1, el["dayanim"]) == 0:
		el = {}
	else:
		uyar("dolu", "Envanterim dolu!")

func govde_cikar() -> void:
	if govde.is_empty():
		return
	if ekle(govde["id"], 1, govde["dayanim"]) == 0:
		govde = {}
	else:
		uyar("dolu", "Envanterim dolu!")

func _ye(i: int) -> void:
	var s: Dictionary = envanter[i]
	var e := Veri.esya(s["id"])
	oyuncu.aclik = clampf(oyuncu.aclik + e.get("aclik", 0.0), 0.0, OYUNCU.MAKS_ACLIK)
	oyuncu.can = clampf(oyuncu.can + e.get("can", 0.0), 0.0, OYUNCU.MAKS_CAN)
	oyuncu.akil = clampf(oyuncu.akil + e.get("akil", 0.0), 0.0, OYUNCU.MAKS_AKIL)
	s["adet"] -= 1
	if s["adet"] <= 0:
		envanter[i] = {}
	sesler.cal("ye")
	if s["id"] == "curuk_et":
		mesaj("Iyy... midem bulandı.")
	if oyuncu.can <= 0.0:
		_ol()

func _yerlestir(i: int) -> void:
	var s: Dictionary = envanter[i]
	var id: String = s["id"]
	var p: Vector2 = oyuncu.position + oyuncu.yon.normalized() * 66.0
	if id == "duvar":
		p = (p / 48.0).round() * 48.0
	if not dunya.kara_mi(p):
		mesaj("Buraya kurulamaz.")
		sesler.cal("hata")
		return
	var benim: float = Veri.NESNELER[id]["yaricap"] if id != "kamp_atesi" else 26.0
	for n in dunya.yakin(p, 80.0):
		var yr: float = n.yaricap()
		if n.tur == "kamp_atesi":
			yr = 26.0
		if yr <= 0.0:
			continue
		if n.position.distance_to(p) < (yr + benim) * 0.9:
			mesaj("Burası dolu, biraz yer aç.")
			sesler.cal("hata")
			return
	var n = dunya.nesne_ekle(id, p, randi() % 1000)
	if id == "kamp_atesi":
		n.yakit = 120.0
		_ates_kuruldu = true
	s["adet"] -= 1
	if s["adet"] <= 0:
		envanter[i] = {}
	sesler.cal("craft", 0.6)

# ---------------------------------------------------------------- craft

func yakininda(gerek: String) -> bool:
	match gerek:
		"ates":
			for a in dunya.atesler:
				if a.yaniyor() and a.position.distance_to(oyuncu.position) < 220.0:
					return true
			return false
		"tezgah":
			for n in dunya.yakin(oyuncu.position, 230.0):
				if n.tur == "tezgah":
					return true
			return false
	return true

func malzeme_yeter(t: Dictionary) -> bool:
	for id in t["gerek"]:
		if say(id) < t["gerek"][id]:
			return false
	return true

func tarif_uret(t: Dictionary) -> void:
	if not yakininda(t["yakin"]):
		mesaj("Bunun için %s yanında olmalıyım." % ("yanan bir ateşin" if t["yakin"] == "ates" else "Çalışma Tezgâhı'nın"))
		sesler.cal("hata")
		return
	if not malzeme_yeter(t):
		var eksik: Array = []
		for id in t["gerek"]:
			var e: int = t["gerek"][id] - say(id)
			if e > 0:
				eksik.append("%d %s" % [e, Veri.ad(id)])
		mesaj("Eksik: " + ", ".join(eksik))
		sesler.cal("hata")
		return
	for id in t["gerek"]:
		harca(id, t["gerek"][id])
	_ver(t["id"], t["adet"], oyuncu.position)
	sesler.cal("craft")
	mesaj("%s yapıldı!" % Veri.ad(t["id"]))

# ---------------------------------------------------------------- mesajlar ve ipuçları

func mesaj(m: String) -> void:
	arayuz.mesaj(m)

## Aynı uyarıyı sık sık tekrarlamaz.
func uyar(anahtar: String, m: String, ara := 12.0) -> void:
	var simdi := Time.get_ticks_msec() / 1000.0
	if simdi - float(_uyari.get(anahtar, -999.0)) < ara:
		return
	_uyari[anahtar] = simdi
	mesaj(m)

func _var_mi(id: String) -> bool:
	return say(id) > 0 or el.get("id", "") == id

func _ipucu_bul() -> String:
	if gun() > 3:
		return ""
	if not _var_mi("balta"):
		if say("dal") < 1 or say("cakmak") < 1:
			return "İpucu: Eylem tuşunu basılı tut — dal (fidan), ot ve yerdeki çakmaktaşlarını topla."
		return "İpucu: Çekiç tuşuyla craft menüsünü aç ve Balta yap."
	if el.get("id", "") != "balta" and say("odun") < 2 and not _ates_kuruldu:
		return "İpucu: Baltayı kuşanmak için envanterde ona dokun, sonra ağaç kes."
	if not _ates_kuruldu and not _var_mi("kamp_atesi"):
		return "İpucu: Gece zifiri karanlık olur. Gün bitmeden Kamp Ateşi yap (3 ot + 2 odun)."
	if not _ates_kuruldu:
		return "İpucu: Kamp Ateşi'ne envanterde dokunarak önüne kur."
	if not _var_mi("mesale") and faz() >= 1:
		return "İpucu: Meşale yanında taşınan bir ışıktır (2 dal + 2 ot)."
	return ""

# ---------------------------------------------------------------- denge botu

func _bot_isle(d: float) -> Vector2:
	_bot_t -= d
	if _bot_t <= 0.0:
		_bot_t = 2.0
		for id in ["balta", "kazma", "mesale", "tezgah", "kamp_atesi", "mizrak", "tahta_zirh", "duvar", "ip", "pismis_havuc", "pismis_dut", "kizarmis_et", "lapa"]:
			for t in Veri.TARIFLER:
				if t["id"] != id or not malzeme_yeter(t) or not yakininda(t["yakin"]):
					continue
				if id in ["balta", "kazma", "mesale", "mizrak", "tahta_zirh", "tezgah"] and _var_mi(id):
					continue
				if id == "kamp_atesi" and say("kamp_atesi") > 0:
					continue
				if id == "ip" and say("ip") >= 3:
					continue
				if id == "lapa" and say("lapa") >= 2:
					continue
				if id == "tezgah" and say("odun") < 8:
					continue
				tarif_uret(t)
		for i in envanter.size():
			var s: Dictionary = envanter[i]
			if s.is_empty():
				continue
			if s["id"] == "tezgah":
				kullan(i)
			elif s["id"] == "tahta_zirh" and govde.is_empty():
				kullan(i)
			elif s["id"] == "kamp_atesi" and faz() >= 1 and not ates_isiginda(oyuncu.position):
				kullan(i)
			elif Veri.esya(s["id"]).get("tur", "") == "yemek" and oyuncu.aclik < 80.0 and s["id"] != "lapa":
				kullan(i)
			elif s["id"] == "lapa" and oyuncu.can < 90.0:
				kullan(i)
		# alet seçimi: yakında zombi varsa mızrak, gece meşale, yoksa balta/kazma sırayla
		var zombi_yakin := false
		for z in zombiler:
			if z.position.distance_to(oyuncu.position) < 300.0:
				zombi_yakin = true
		var iste := "balta" if randf() < 0.6 else "kazma"
		if faz() == 2 and not ates_isiginda(oyuncu.position):
			iste = "mesale"
		if zombi_yakin:
			iste = "mizrak"
		if el.get("id", "") != iste:
			for i in envanter.size():
				if envanter[i].get("id", "") == iste:
					kullan(i)
					break
	# gece ateş yanındaysa yakında kal
	if faz() == 2:
		for a in dunya.atesler:
			if a.yaniyor() and a.position.distance_to(oyuncu.position) > 120.0 and a.position.distance_to(oyuncu.position) < 900.0:
				if oyuncu.oto_hedef == null:
					return (a.position - oyuncu.position).normalized()
	if oyuncu.oto_hedef != null or _hedef_sec() != null:
		return Vector2.ZERO
	_bot_yon_t -= d
	if _bot_yon_t <= 0.0:
		_bot_yon_t = randf_range(1.5, 4.0)
		_bot_yon = Vector2.from_angle(randf() * TAU)
	return _bot_yon

func _bot_rapor() -> void:
	var env: Array = []
	for s in envanter:
		if not s.is_empty():
			env.append("%s:%d" % [s["id"], s["adet"]])
	print("BOT: gün=%d faz=%d can=%d açlık=%d akıl=%d el=%s zırh=%s zombi=%d öldürülen=%d env=%s" % [gun(), faz(), oyuncu.can, oyuncu.aclik, oyuncu.akil, el.get("id", "-"), govde.get("id", "-"), zombiler.size(), oldurulen, ", ".join(env)])

# ---------------------------------------------------------------- bulut önizleme (ekran görüntüleri)

func _kare(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _cek(ad: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_onizleme_yolu.path_join(ad + ".png"))
	print("ÖNİZLEME: ", ad)

func _onizleme() -> void:
	DirAccess.make_dir_recursive_absolute(_onizleme_yolu)
	await _kare(3)
	await _cek("00_menu")
	yeni_oyun(424242)
	for id in ["balta", "kazma", "mizrak", "mesale", "tahta_zirh"]:
		ekle(id, 1)
	ekle("odun", 12)
	ekle("ot", 10)
	ekle("dal", 8)
	ekle("tas", 6)
	ekle("cakmak", 4)
	ekle("ip", 3)
	ekle("dut", 5)
	kullan(0)
	await _kare(40)
	await _cek("01_gunduz")
	craft_acik = true
	await _kare(5)
	await _cek("02_craft")
	craft_acik = false
	var o: Vector2 = oyuncu.position
	var ates = dunya.nesne_ekle("kamp_atesi", o + Vector2(90, 30), 1)
	ates.yakit = 150.0
	dunya.nesne_ekle("tezgah", o + Vector2(-110, -20), 2)
	for i in 4:
		dunya.nesne_ekle("duvar", o + Vector2(-96 + i * 48, 130), i)
	for i in 3:
		zombi_ekle(o + Vector2(260 + i * 50, -60 + i * 50), ["yuruyen", "kosucu", "iri"][i])
	zaman = Veri.GUN_SURE * 0.62
	await _kare(30)
	await _cek("03_aksam")
	zaman = Veri.GUN_SURE * 0.86
	var mesale_yuvasi := -1
	for i in envanter.size():
		if envanter[i].get("id", "") == "mesale":
			mesale_yuvasi = i
	kullan(mesale_yuvasi)
	oyuncu.position = o + Vector2(400, 200)
	for z in zombiler:
		z.position = oyuncu.position + Vector2(randf_range(-260, 260), randf_range(-160, 160))
	await _kare(40)
	await _cek("04_gece")
	oyuncu.akil = 30.0
	oyuncu.aclik = 20.0
	await _kare(10)
	await _cek("05_dusuk_akil")
	print("ÖNİZLEME: bitti, zombi=", zombiler.size(), " nesne=", dunya.varliklar.get_child_count())
	kaydet()
	var ok := devam_et()
	print("ÖNİZLEME: kayıt yüklendi=", ok, " gün=", gun())
	get_tree().quit()
