extends Control
## Bütün arayüz: menü, göstergeler, saat, envanter, joystick, eylem/üret tuşları, craft paneli, ölüm ekranı.
## Dokunmalar elle işlenir (çoklu dokunma: joystick + eylem aynı anda çalışır).

const OYUNCU := preload("res://betikler/oyuncu.gd")

var oyun
var joystick := Vector2.ZERO
var eylem_basili := false
var ekran := "menu"           # menu / oyun / olum

var _mesajlar: Array = []     # [metin, kalan_sure]
var _yazilar: Array = []      # [metin, dunya_konumu, kalan, renk]
var _flas := 0.0
var _joy_parmak := -1
var _joy_merkez := Vector2.ZERO
var _joy_konum := Vector2.ZERO
var _eylem_parmak := -1
var _yuva_basis := {}         # parmak -> [yuva, baslangic_zamani]
var _kat := 0
var _olum_gun := 0
var _olum_zombi := 0
var _vinyet: GradientTexture2D
var _yazi: Font

const YUVA := 58.0
const YUVA_ARA := 5.0
const UZUN_BASIS := 0.55

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yazi = ThemeDB.fallback_font
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.25), Color(0, 0, 0, 1)])
	_vinyet = GradientTexture2D.new()
	_vinyet.gradient = g
	_vinyet.fill = GradientTexture2D.FILL_RADIAL
	_vinyet.fill_from = Vector2(0.5, 0.5)
	_vinyet.fill_to = Vector2(1.05, 0.5)
	_vinyet.width = 256
	_vinyet.height = 256

func menu_goster() -> void:
	ekran = "menu"
	_sifirla()

func oyun_basladi() -> void:
	ekran = "oyun"
	_mesajlar.clear()
	_yazilar.clear()
	_sifirla()

func olum_goster(g: int, z: int) -> void:
	ekran = "olum"
	_olum_gun = g
	_olum_zombi = z
	_sifirla()

func _sifirla() -> void:
	joystick = Vector2.ZERO
	eylem_basili = false
	_joy_parmak = -1
	_eylem_parmak = -1
	_yuva_basis.clear()

func mesaj(m: String) -> void:
	_mesajlar.append([m, 4.0])
	if _mesajlar.size() > 3:
		_mesajlar.pop_front()

func yazi_ekle(m: String, p: Vector2, r: Color) -> void:
	_yazilar.append([m, p, 1.2, r])
	if _yazilar.size() > 14:
		_yazilar.pop_front()

func hasar_flas() -> void:
	_flas = 1.0

func _process(d: float) -> void:
	_flas = maxf(0.0, _flas - d * 2.5)
	for m in _mesajlar:
		m[1] -= d
	while _mesajlar.size() > 0 and _mesajlar[0][1] <= 0.0:
		_mesajlar.pop_front()
	for y in _yazilar:
		y[2] -= d
	while _yazilar.size() > 0 and _yazilar[0][2] <= 0.0:
		_yazilar.pop_front()
	queue_redraw()

# ---------------------------------------------------------------- yerleşim

func _W() -> float:
	return size.x

func _H() -> float:
	return size.y

func _joy_ev() -> Vector2:
	return Vector2(170, _H() - 170)

func _eylem_m() -> Vector2:
	return Vector2(_W() - 130, _H() - 150)

func _uret_m() -> Vector2:
	return Vector2(_W() - 130, _H() - 312)

func _yuva_rect(i: int) -> Rect2:
	var top := Veri.ENVANTER * YUVA + (Veri.ENVANTER - 1) * YUVA_ARA
	var x0 := (_W() - top) / 2.0
	return Rect2(x0 + i * (YUVA + YUVA_ARA), _H() - YUVA - 14, YUVA, YUVA)

func _el_rect() -> Rect2:
	return Rect2(18, 18, 64, 64)

func _govde_rect() -> Rect2:
	return Rect2(90, 18, 64, 64)

func _menu_rect() -> Rect2:
	return Rect2(166, 24, 52, 52)

func _panel() -> Rect2:
	return Rect2(_W() / 2 - 430, 58, 860, _H() - 150)

func _kat_rect(k: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 14, p.position.y + 62 + k * 62, 156, 54)

func _kart_rect(i: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + 186 + (i % 3) * 222, p.position.y + 62 + (i / 3) * 162, 212, 152)

func _kapat_m() -> Vector2:
	var p := _panel()
	return Vector2(p.end.x - 30, p.position.y + 30)

func _kat_tarifleri() -> Array:
	var k: String = Veri.KATEGORILER[_kat]
	var l: Array = []
	for t in Veri.TARIFLER:
		if t["kat"] == k:
			l.append(t)
	return l

func _menu_dugmeleri() -> Array:
	var l: Array = []
	var x := _W() / 2 - 170
	var y := _H() * 0.56
	if oyun.kayit_var():
		l.append(["devam", Rect2(x, y, 340, 74), "Devam Et"])
		y += 92
	l.append(["yeni", Rect2(x, y, 340, 74), "Yeni Dünya"])
	return l

func _olum_dugmeleri() -> Array:
	var x := _W() / 2 - 170
	return [["yeni", Rect2(x, _H() * 0.58, 340, 74), "Yeni Dünya"], ["menu", Rect2(x, _H() * 0.58 + 92, 340, 74), "Ana Menü"]]

# ---------------------------------------------------------------- dokunma

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_bas(e.index, e.position)
		else:
			_birak(e.index, e.position)
	elif e is InputEventScreenDrag:
		if e.index == _joy_parmak:
			_joy_konum = e.position
			_joy_guncelle()

func _joy_guncelle() -> void:
	var v := (_joy_konum - _joy_merkez) / 85.0
	if v.length() > 1.0:
		v = v.normalized()
	joystick = v if v.length() > 0.12 else Vector2.ZERO

func _yuva_at(p: Vector2) -> int:
	for i in Veri.ENVANTER:
		if _yuva_rect(i).grow(2).has_point(p):
			return i
	return -1

func _bas(i: int, p: Vector2) -> void:
	match ekran:
		"menu":
			for d in _menu_dugmeleri():
				if d[1].has_point(p):
					if d[0] == "devam":
						if not oyun.devam_et():
							oyun.yeni_oyun(randi())
					else:
						oyun.yeni_oyun(randi())
			return
		"olum":
			for d in _olum_dugmeleri():
				if d[1].has_point(p):
					if d[0] == "yeni":
						oyun.yeni_oyun(randi())
					else:
						oyun.oynaniyor = false
						menu_goster()
			return
	var y := _yuva_at(p)
	if y >= 0:
		_yuva_basis[i] = [y, Time.get_ticks_msec() / 1000.0]
		return
	if oyun.craft_acik:
		_panel_dokun(p)
		return
	if _el_rect().has_point(p):
		oyun.el_cikar()
		return
	if _govde_rect().has_point(p):
		oyun.govde_cikar()
		return
	if _menu_rect().has_point(p):
		oyun.menuye_don()
		return
	if p.distance_to(_uret_m()) < 58.0:
		oyun.craft_acik = true
		return
	if p.distance_to(_eylem_m()) < 95.0 or (p.x > _W() * 0.6 and p.y > _H() * 0.45 and _eylem_parmak == -1):
		_eylem_parmak = i
		eylem_basili = true
		return
	if p.x < _W() * 0.5 and _joy_parmak == -1:
		_joy_parmak = i
		_joy_merkez = Vector2(maxf(p.x, 100.0), minf(p.y, _H() - 100.0))
		_joy_konum = p
		_joy_guncelle()

func _birak(i: int, p: Vector2) -> void:
	if i == _joy_parmak:
		_joy_parmak = -1
		joystick = Vector2.ZERO
	if i == _eylem_parmak:
		_eylem_parmak = -1
		eylem_basili = false
	if _yuva_basis.has(i):
		var a: Array = _yuva_basis[i]
		_yuva_basis.erase(i)
		if _yuva_at(p) == a[0] and ekran == "oyun":
			if Time.get_ticks_msec() / 1000.0 - a[1] >= UZUN_BASIS:
				oyun.birak(a[0])
			else:
				oyun.kullan(a[0])

func _panel_dokun(p: Vector2) -> void:
	if p.distance_to(_kapat_m()) < 34.0 or not _panel().has_point(p):
		oyun.craft_acik = false
		return
	for k in Veri.KATEGORILER.size():
		if _kat_rect(k).has_point(p):
			_kat = k
			return
	var l := _kat_tarifleri()
	for j in l.size():
		if _kart_rect(j).has_point(p):
			oyun.tarif_uret(l[j])
			return

# ---------------------------------------------------------------- çizim yardımcıları

func _yaz(p: Vector2, m: String, boy: int, r: Color, hiza := HORIZONTAL_ALIGNMENT_LEFT, gen := -1.0, kontur := 4) -> void:
	if kontur > 0:
		draw_string_outline(_yazi, p, m, hiza, gen, boy, kontur, Color(0, 0, 0, 0.85 * r.a))
	draw_string(_yazi, p, m, hiza, gen, boy, r)

func _kutu(r: Rect2, ic: Color, kenar := Color(0.05, 0.04, 0.03), k := 3.0) -> void:
	draw_rect(r, ic)
	draw_rect(r, kenar, false, k)

func _yuva_ciz(r: Rect2, s: Dictionary, vurgu := false) -> void:
	_kutu(r, Color(0.20, 0.17, 0.13, 0.88) if not vurgu else Color(0.35, 0.28, 0.16, 0.95), Color(0.06, 0.05, 0.04), 2.5)
	draw_rect(r.grow(-4), Color(1, 1, 1, 0.05), false, 1.5)
	if s.is_empty():
		return
	Cizim.simge(self, s["id"], r.get_center() + Vector2(0, -2), 0.82)
	var e := Veri.esya(s["id"])
	if int(s["adet"]) > 1:
		_yaz(Vector2(r.position.x, r.end.y - 6), str(s["adet"]), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 5, 4)
	var en: float = e.get("dayanim", -1)
	if en > 0 and float(s["dayanim"]) >= 0.0:
		var o := clampf(float(s["dayanim"]) / en, 0.0, 1.0)
		draw_rect(Rect2(r.position.x + 6, r.end.y - 9, r.size.x - 12, 4), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(r.position.x + 6, r.end.y - 9, (r.size.x - 12) * o, 4), Color(0.3, 0.85, 0.3).lerp(Color(0.9, 0.2, 0.1), 1.0 - o))

func _dugme(r: Rect2, m: String, aktif := true) -> void:
	_kutu(r, Color(0.45, 0.20, 0.12) if aktif else Color(0.25, 0.22, 0.2), Color(0.06, 0.04, 0.03), 4)
	draw_rect(Rect2(r.position + Vector2(6, 6), Vector2(r.size.x - 12, 6)), Color(1, 1, 1, 0.12))
	_yaz(Vector2(r.position.x, r.get_center().y + 11), m, 32, Color(1, 0.93, 0.80), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

# ---------------------------------------------------------------- çizim

func _draw() -> void:
	match ekran:
		"menu":
			_menu_ciz()
			return
		"oyun", "olum":
			_oyun_ciz()
	if ekran == "olum":
		_olum_ciz()

func _menu_ciz() -> void:
	var W := _W()
	var H := _H()
	draw_rect(Rect2(0, 0, W, H), Color(0.09, 0.08, 0.08))
	draw_rect(Rect2(0, H * 0.72, W, H * 0.28), Color(0.16, 0.17, 0.12))
	var t := Time.get_ticks_msec() / 1000.0
	draw_circle(Vector2(W * 0.8, H * 0.2), 60, Color(0.85, 0.85, 0.75, 0.9))
	draw_circle(Vector2(W * 0.8 + 18, H * 0.2 - 10), 54, Color(0.09, 0.08, 0.08))
	draw_set_transform(Vector2(W * 0.18, H * 0.86), 0, Vector2(3.2, 3.2))
	Cizim.zombi(self, "yuruyen", t * 3.0, Vector2(1, 0), 0.0, 0.0, false)
	draw_set_transform(Vector2(W * 0.86, H * 0.88), 0, Vector2(2.6, 2.6))
	Cizim.olu_agac(self, 1)
	draw_set_transform(Vector2(W * 0.68, H * 0.86), 0, Vector2(2.0, 2.0))
	Cizim.kamp_atesi(self, 0.8, t)
	draw_set_transform(Vector2.ZERO)
	_yaz(Vector2(0, H * 0.30), "ZOMBİMANİA", 96, Color(0.92, 0.42, 0.18), HORIZONTAL_ALIGNMENT_CENTER, W, 14)
	_yaz(Vector2(0, H * 0.30 + 52), "Topla · Üret · Hayatta kal · Sabaha çık", 28, Color(0.88, 0.84, 0.74), HORIZONTAL_ALIGNMENT_CENTER, W, 6)
	for d in _menu_dugmeleri():
		_dugme(d[1], d[2])
	_yaz(Vector2(12, H - 12), "v0.1", 16, Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_LEFT, -1, 0)

func _oyun_ciz() -> void:
	var W := _W()
	var H := _H()
	var o = oyun.oyuncu
	if o == null:
		return
	# akıl düştükçe ekran kenarları kararır, hasar alınca kızarır
	var vin: float = clampf((70.0 - o.akil) / 70.0, 0.0, 1.0) * 0.85
	if vin > 0.0:
		var nab := 0.85 + sin(Time.get_ticks_msec() * 0.004) * 0.15
		draw_texture_rect(_vinyet, Rect2(-W * 0.1, -H * 0.1, W * 1.2, H * 1.2), false, Color(0.25, 0.05, 0.15, vin * nab))
	if _flas > 0.0:
		draw_texture_rect(_vinyet, Rect2(-W * 0.1, -H * 0.1, W * 1.2, H * 1.2), false, Color(0.9, 0.05, 0.05, _flas * 0.8))
	# uçan yazılar (dünya konumundan ekrana)
	var ct := get_viewport().get_canvas_transform()
	for y in _yazilar:
		var k: float = 1.2 - y[2]
		var p: Vector2 = ct * (y[1] as Vector2) + Vector2(0, -k * 45.0)
		var r: Color = y[3]
		r.a = clampf(y[2] / 0.4, 0.0, 1.0)
		_yaz(p - Vector2(100, 0), y[0], 20, r, HORIZONTAL_ALIGNMENT_CENTER, 200, 4)
	_saat_ciz(Vector2(W - 70, 72), 52)
	_gosterge(Vector2(W - 178, 56), o.can / OYUNCU.MAKS_CAN, "can", int(ceil(o.can)))
	_gosterge(Vector2(W - 254, 56), o.aclik / OYUNCU.MAKS_ACLIK, "aclik", int(ceil(o.aclik)))
	_gosterge(Vector2(W - 330, 56), o.akil / OYUNCU.MAKS_AKIL, "akil", int(ceil(o.akil)))
	# biyom adı
	_yaz(Vector2(W - 380, 150), Veri.BIYOM_AD[oyun.dunya.biyom_at(o.position)], 17, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_RIGHT, 340, 3)
	# kuşanılanlar
	_yuva_ciz(_el_rect(), oyun.el)
	_yaz(_el_rect().position + Vector2(0, 80), "El", 15, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 64, 3)
	_yuva_ciz(_govde_rect(), oyun.govde)
	_yaz(_govde_rect().position + Vector2(0, 80), "Gövde", 15, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 64, 3)
	var mr := _menu_rect()
	_kutu(mr, Color(0.2, 0.17, 0.13, 0.85))
	draw_rect(Rect2(mr.position + Vector2(16, 14), Vector2(7, 24)), Color(0.95, 0.9, 0.8))
	draw_rect(Rect2(mr.position + Vector2(29, 14), Vector2(7, 24)), Color(0.95, 0.9, 0.8))
	# mesajlar
	var my := 120.0
	for m in _mesajlar:
		var r := Color(1, 0.95, 0.85, clampf(m[1] / 0.6, 0.0, 1.0))
		_yaz(Vector2(0, my), m[0], 26, r, HORIZONTAL_ALIGNMENT_CENTER, W, 6)
		my += 34
	if oyun.ipucu != "" and not oyun.craft_acik:
		_yaz(Vector2(W * 0.2, H - 98), oyun.ipucu, 18, Color(1, 0.92, 0.55, 0.95), HORIZONTAL_ALIGNMENT_CENTER, W * 0.6, 4)
	# envanter
	var simdi := Time.get_ticks_msec() / 1000.0
	var basili := {}
	for k in _yuva_basis:
		basili[_yuva_basis[k][0]] = simdi - float(_yuva_basis[k][1])
	for i in Veri.ENVANTER:
		var r := _yuva_rect(i)
		_yuva_ciz(r, oyun.envanter[i], basili.has(i))
		if i < 10:
			_yaz(r.position + Vector2(4, 14), str((i + 1) % 10), 12, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_LEFT, -1, 0)
		if basili.has(i) and not oyun.envanter[i].is_empty():
			var o2 := clampf(basili[i] / UZUN_BASIS, 0.0, 1.0)
			draw_arc(r.get_center(), 32, -PI / 2, -PI / 2 + TAU * o2, 24, Color(1, 0.6, 0.2), 4)
			if o2 >= 1.0:
				_yaz(r.position + Vector2(-20, -10), "Bırak", 16, Color(1, 0.7, 0.4), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, 3)
	if oyun.craft_acik:
		_panel_ciz()
		return
	# joystick
	var jm := _joy_merkez if _joy_parmak != -1 else _joy_ev()
	draw_circle(jm, 85, Color(0, 0, 0, 0.22))
	draw_arc(jm, 85, 0, TAU, 32, Color(1, 1, 1, 0.25), 3)
	draw_circle(jm + joystick * 85.0, 36, Color(1, 1, 1, 0.28 if _joy_parmak != -1 else 0.15))
	# eylem tuşu
	var em := _eylem_m()
	draw_circle(em, 72, Color(0.55, 0.22, 0.12, 0.85) if eylem_basili else Color(0.35, 0.15, 0.10, 0.75))
	draw_arc(em, 72, 0, TAU, 40, Color(0.06, 0.04, 0.03), 4)
	var el_id: String = oyun.el.get("id", "")
	if el_id != "":
		Cizim.simge(self, el_id, em + Vector2(0, -14), 1.1)
	else:
		Cizim.daire(self, em + Vector2(0, -14), 14, Color(0.93, 0.80, 0.66))
	_yaz(Vector2(em.x - 72, em.y + 40), "EYLEM", 20, Color(1, 0.93, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 144, 4)
	# üret tuşu
	var um := _uret_m()
	draw_circle(um, 50, Color(0.22, 0.30, 0.18, 0.85))
	draw_arc(um, 50, 0, TAU, 32, Color(0.06, 0.04, 0.03), 4)
	draw_set_transform(um + Vector2(-2, 6), 0.0, Vector2(0.6, 0.6))
	Cizim.tezgah(self)
	draw_set_transform(Vector2.ZERO)
	_yaz(Vector2(um.x - 50, um.y + 36), "ÜRET", 18, Color(1, 0.93, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 100, 4)

func _saat_ciz(m: Vector2, r: float) -> void:
	draw_circle(m, r + 5, Color(0.06, 0.05, 0.04))
	var bolum := [[0.0, Veri.AKSAM_BAS, Color(0.86, 0.74, 0.36)], [Veri.AKSAM_BAS, Veri.GECE_BAS, Color(0.78, 0.36, 0.24)], [Veri.GECE_BAS, 1.0, Color(0.20, 0.22, 0.40)]]
	for b in bolum:
		var a0: float = -PI / 2 + TAU * b[0]
		var a1: float = -PI / 2 + TAU * b[1]
		var p := PackedVector2Array([m])
		for i in 17:
			p.append(m + Vector2.from_angle(lerpf(a0, a1, i / 16.0)) * r)
		draw_colored_polygon(p, b[2])
	var ao: float = -PI / 2 + TAU * oyun.gun_orani()
	draw_line(m, m + Vector2.from_angle(ao) * (r - 4), Color(0.06, 0.05, 0.04), 5)
	draw_circle(m, r * 0.55, Color(0.13, 0.11, 0.09))
	_yaz(Vector2(m.x - 40, m.y - 4), "Gün", 15, Color(0.9, 0.85, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 80, 0)
	_yaz(Vector2(m.x - 40, m.y + 18), str(oyun.gun()), 24, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 80, 0)

func _gosterge(m: Vector2, o: float, tur: String, deger: int) -> void:
	o = clampf(o, 0.0, 1.0)
	var renk := {"can": Color(0.80, 0.18, 0.18), "aclik": Color(0.90, 0.60, 0.18), "akil": Color(0.85, 0.50, 0.70)}[tur] as Color
	var r := 32.0
	if o < 0.25:
		r += sin(Time.get_ticks_msec() * 0.012) * 2.5
	draw_circle(m, r + 4, Color(0.06, 0.05, 0.04))
	draw_circle(m, r, Color(0.17, 0.14, 0.12))
	# alttan dolan sıvı
	var h := r * 2.0 * o
	var ust := m.y + r - h
	var dol := PackedVector2Array()
	for q in Cizim.elips(m, r, r, 32):
		if q.y >= ust:
			dol.append(q)
	if dol.size() >= 3:
		draw_colored_polygon(dol, renk.darkened(0.25))
	match tur:
		"can":
			draw_circle(m + Vector2(-6, -5), 7, renk.lightened(0.2))
			draw_circle(m + Vector2(6, -5), 7, renk.lightened(0.2))
			draw_colored_polygon(PackedVector2Array([m + Vector2(-13, -2), m + Vector2(13, -2), m + Vector2(0, 12)]), renk.lightened(0.2))
		"aclik":
			Cizim.sekil(self, Cizim.puruzlu(m + Vector2(0, 0), 12, 4, 10, 0.12, 0.85), renk.lightened(0.15), 2)
		"akil":
			Cizim.sekil(self, Cizim.puruzlu(m + Vector2(0, -1), 13, 8, 12, 0.14, 0.8), renk.lightened(0.15), 2)
			draw_line(m + Vector2(0, -11), m + Vector2(0, 9), Color(0, 0, 0, 0.45), 2)
	_yaz(Vector2(m.x - 40, m.y + r + 22), str(deger), 18, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, 80, 4)

func _panel_ciz() -> void:
	var P := _panel()
	_kutu(P, Color(0.16, 0.13, 0.10, 0.96), Color(0.05, 0.04, 0.03), 5)
	draw_rect(Rect2(P.position + Vector2(8, 8), Vector2(P.size.x - 16, 40)), Color(0.28, 0.20, 0.13))
	_yaz(P.position + Vector2(0, 38), "ÜRETİM", 28, Color(1, 0.9, 0.7), HORIZONTAL_ALIGNMENT_CENTER, P.size.x, 4)
	var km := _kapat_m()
	draw_circle(km, 20, Color(0.55, 0.15, 0.1))
	draw_line(km + Vector2(-8, -8), km + Vector2(8, 8), Color.WHITE, 4)
	draw_line(km + Vector2(8, -8), km + Vector2(-8, 8), Color.WHITE, 4)
	for k in Veri.KATEGORILER.size():
		var r := _kat_rect(k)
		_kutu(r, Color(0.42, 0.26, 0.14) if k == _kat else Color(0.24, 0.19, 0.14), Color(0.05, 0.04, 0.03), 3)
		_yaz(Vector2(r.position.x, r.get_center().y + 8), Veri.KATEGORILER[k], 21, Color(1, 0.93, 0.8), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 3)
	var l := _kat_tarifleri()
	for j in l.size():
		var t: Dictionary = l[j]
		var r := _kart_rect(j)
		var yakin: bool = oyun.yakininda(t["yakin"])
		var yeter: bool = oyun.malzeme_yeter(t)
		var hazir := yakin and yeter
		_kutu(r, Color(0.24, 0.34, 0.18) if hazir else Color(0.22, 0.19, 0.16), Color(0.05, 0.04, 0.03), 3)
		Cizim.simge(self, t["id"], r.position + Vector2(38, 44), 1.15)
		var ad := Veri.ad(t["id"]) + (" x%d" % t["adet"] if t["adet"] > 1 else "")
		_yaz(r.position + Vector2(72, 34), ad, 19, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 76, 3)
		var ex := Veri.esya(t["id"])
		var bilgi := ""
		match ex.get("tur", ""):
			"arac":
				bilgi = "Hasar %d" % int(ex.get("hasar", 0))
			"yemek":
				bilgi = "Açlık +%d" % int(ex.get("aclik", 0))
				if ex.get("can", 0.0) > 0.0:
					bilgi = "Can +%d" % int(ex.get("can", 0))
			"zirh":
				bilgi = "%%%d koruma" % int(ex.get("koruma", 0) * 100)
			"yapi":
				bilgi = "Kurulur"
		_yaz(r.position + Vector2(72, 58), bilgi, 15, Color(0.85, 0.85, 0.75), HORIZONTAL_ALIGNMENT_LEFT, -1, 0)
		var x := r.position.x + 22
		for id in t["gerek"]:
			var var_olan: int = oyun.say(id)
			var gerek: int = t["gerek"][id]
			Cizim.simge(self, id, Vector2(x, r.position.y + 100), 0.55)
			_yaz(Vector2(x - 26, r.position.y + 132), "%d/%d" % [var_olan, gerek], 15, Color(0.6, 1, 0.5) if var_olan >= gerek else Color(1, 0.45, 0.4), HORIZONTAL_ALIGNMENT_CENTER, 52, 3)
			x += 58
		if t["yakin"] != "":
			var y_ad := "Ateş yanında" if t["yakin"] == "ates" else "Tezgâh yanında"
			_yaz(Vector2(r.position.x + 72, r.position.y + 78), y_ad, 14, Color(0.6, 1, 0.5) if yakin else Color(1, 0.6, 0.3), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	_yaz(Vector2(P.position.x, P.end.y - 14), "Karta dokun: üret  ·  Envanterde dokun: kullan / kuşan / kur  ·  Basılı tut: bırak", 15, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, P.size.x, 0)

func _olum_ciz() -> void:
	var W := _W()
	var H := _H()
	draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.0, 0.0, 0.72))
	_yaz(Vector2(0, H * 0.32), "ÖLDÜN", 90, Color(0.85, 0.15, 0.1), HORIZONTAL_ALIGNMENT_CENTER, W, 12)
	_yaz(Vector2(0, H * 0.32 + 60), "%d gün hayatta kaldın  ·  %d zombi öldürdün" % [_olum_gun, _olum_zombi], 30, Color(1, 0.9, 0.8), HORIZONTAL_ALIGNMENT_CENTER, W, 6)
	for d in _olum_dugmeleri():
		_dugme(d[1], d[2])
