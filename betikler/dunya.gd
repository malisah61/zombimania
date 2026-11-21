extends Node2D
## Açık dünya: tohumdan ada üretimi, zemin dokusu, nesneler ve hızlı arama ızgarası.

const NESNE := preload("res://betikler/nesne.gd")
const HUCRE := 128.0

var oyun
var tohum := 0
var biyom := PackedByteArray()
var zemin: Sprite2D
var varliklar: Node2D
var izgara := {}              # Vector2i -> Array[nesne]
var yenilenenler: Array = []  # toplanıp yeniden büyümeyi bekleyenler
var mezarlar: Array = []
var atesler: Array = []
var baslangic := Vector2.ZERO

func _ready() -> void:
	zemin = Sprite2D.new()
	zemin.centered = false
	zemin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	zemin.z_index = -10
	add_child(zemin)
	varliklar = Node2D.new()
	varliklar.y_sort_enabled = true
	add_child(varliklar)

func boyut() -> float:
	return Veri.HARITA * Veri.KAROSU

# ---------------------------------------------------------------- üretim

func uret(t: int) -> void:
	tohum = t
	var H := Veri.HARITA
	var yukseklik := FastNoiseLite.new()
	yukseklik.seed = t
	yukseklik.frequency = 0.03
	yukseklik.fractal_octaves = 4
	var nem := FastNoiseLite.new()
	nem.seed = t + 101
	nem.frequency = 0.045
	nem.fractal_octaves = 3
	var tas := FastNoiseLite.new()
	tas.seed = t + 202
	tas.frequency = 0.06
	biyom.resize(H * H)
	for y in H:
		for x in H:
			var d := Vector2(x - H / 2.0, y - H / 2.0).length() / (H / 2.0)
			var e := (yukseklik.get_noise_2d(x, y) * 0.5 + 0.5) * 0.55 + 0.45 - pow(d, 2.2) * 0.85
			var b := Veri.Biyom.CAYIR
			if e < 0.30:
				b = Veri.Biyom.SU
			elif e < 0.345:
				b = Veri.Biyom.KUMSAL
			elif tas.get_noise_2d(x, y) > 0.30:
				b = Veri.Biyom.KAYALIK
			else:
				var m := nem.get_noise_2d(x, y)
				if m > 0.22:
					b = Veri.Biyom.BATAKLIK
				elif m > 0.0:
					b = Veri.Biyom.ORMAN
			biyom[y * H + x] = b
	# başlangıç: merkeze en yakın çayır karosu
	baslangic = Vector2(H / 2.0, H / 2.0) * Veri.KAROSU
	var en := 1e9
	for y in range(H / 4, H * 3 / 4):
		for x in range(H / 4, H * 3 / 4):
			if biyom[y * H + x] == Veri.Biyom.CAYIR:
				var dd := Vector2(x - H / 2.0, y - H / 2.0).length()
				if dd < en:
					en = dd
					baslangic = (Vector2(x, y) + Vector2(0.5, 0.5)) * Veri.KAROSU
	zemin_ciz()
	nesneleri_dagit()

func nesneleri_dagit() -> void:
	var H := Veri.HARITA
	var rng := RandomNumberGenerator.new()
	rng.seed = tohum + 7
	# biyom -> [[tür, olasılık], ...]
	var tablo := {
		Veri.Biyom.ORMAN: [["agac", 0.34], ["fidan", 0.06], ["ot", 0.03], ["dut_calisi", 0.012], ["mezar", 0.006], ["kaya", 0.006]],
		Veri.Biyom.CAYIR: [["ot", 0.11], ["fidan", 0.035], ["dut_calisi", 0.03], ["havuc", 0.018], ["agac", 0.025], ["cakmak", 0.014], ["kaya", 0.01]],
		Veri.Biyom.KAYALIK: [["kaya", 0.17], ["cakmak", 0.045], ["ot", 0.015], ["olu_agac", 0.01]],
		Veri.Biyom.BATAKLIK: [["olu_agac", 0.06], ["mezar", 0.022], ["ot", 0.05], ["agac", 0.03]],
		Veri.Biyom.KUMSAL: [["cakmak", 0.012], ["ot", 0.01], ["dal", 0.012]],
	}
	for y in H:
		for x in H:
			var b: int = biyom[y * H + x]
			var r := rng.randf()
			var jx := rng.randf_range(0.15, 0.85)
			var jy := rng.randf_range(0.15, 0.85)
			var c := rng.randi_range(0, 999)
			if not tablo.has(b):
				continue
			var sec := ""
			var top := 0.0
			for g in tablo[b]:
				top += g[1]
				if r < top:
					sec = g[0]
					break
			if sec == "":
				continue
			var p := (Vector2(x, y) + Vector2(jx, jy)) * Veri.KAROSU
			if p.distance_to(baslangic) < 110.0:
				continue
			if sec == "cakmak" or sec == "dal":
				esya_ekle(p, sec, 1, -1)
			else:
				nesne_ekle(sec, p, c)

func zemin_ciz() -> void:
	var H := Veri.HARITA
	var S := 2
	var img := Image.create(H * S, H * S, false, Image.FORMAT_RGB8)
	var doku := FastNoiseLite.new()
	doku.seed = tohum + 303
	doku.frequency = 0.08
	var renk := {
		Veri.Biyom.SU: Color(0.13, 0.22, 0.29),
		Veri.Biyom.KUMSAL: Color(0.70, 0.63, 0.45),
		Veri.Biyom.CAYIR: Color(0.56, 0.54, 0.31),
		Veri.Biyom.ORMAN: Color(0.27, 0.32, 0.19),
		Veri.Biyom.KAYALIK: Color(0.47, 0.45, 0.38),
		Veri.Biyom.BATAKLIK: Color(0.21, 0.25, 0.23),
	}
	for py in H * S:
		for px in H * S:
			var b: int = biyom[(py / S) * H + px / S]
			var c: Color = renk[b]
			var n := doku.get_noise_2d(px, py) * 0.06
			img.set_pixel(px, py, Color(c.r + n, c.g + n, c.b + n * 0.6))
	zemin.texture = ImageTexture.create_from_image(img)
	zemin.scale = Vector2.ONE * (Veri.KAROSU / float(S))

func biyom_at(p: Vector2) -> int:
	var x := int(floor(p.x / Veri.KAROSU))
	var y := int(floor(p.y / Veri.KAROSU))
	if x < 0 or y < 0 or x >= Veri.HARITA or y >= Veri.HARITA:
		return Veri.Biyom.SU
	return biyom[y * Veri.HARITA + x]

func kara_mi(p: Vector2) -> bool:
	return biyom_at(p) != Veri.Biyom.SU

# ---------------------------------------------------------------- nesneler

func nesne_ekle(t: String, p: Vector2, c: int):
	var n = NESNE.new()
	n.position = p
	varliklar.add_child(n)
	n.kur(oyun, t, c)
	izgaraya_koy(n)
	if t == "mezar":
		mezarlar.append(n)
	elif t == "kamp_atesi":
		atesler.append(n)
	return n

func esya_ekle(p: Vector2, id: String, adet: int, dayanim: int):
	var n = nesne_ekle("esya", p, 0)
	n.esya_id = id
	n.adet = adet
	n.esya_dayanim = dayanim
	n.queue_redraw()
	return n

func kaldir(n) -> void:
	var h: Vector2i = n.hucre
	if izgara.has(h):
		izgara[h].erase(n)
	mezarlar.erase(n)
	atesler.erase(n)
	yenilenenler.erase(n)
	n.queue_free()

func izgaraya_koy(n) -> void:
	var h := Vector2i(int(floor(n.position.x / HUCRE)), int(floor(n.position.y / HUCRE)))
	n.hucre = h
	if not izgara.has(h):
		izgara[h] = []
	izgara[h].append(n)

## p çevresinde r içindeki nesneler.
func yakin(p: Vector2, r: float) -> Array:
	var sonuc: Array = []
	var a := Vector2i(int(floor((p.x - r) / HUCRE)), int(floor((p.y - r) / HUCRE)))
	var b := Vector2i(int(floor((p.x + r) / HUCRE)), int(floor((p.y + r) / HUCRE)))
	var r2 := r * r
	for hy in range(a.y, b.y + 1):
		for hx in range(a.x, b.x + 1):
			var h := Vector2i(hx, hy)
			if not izgara.has(h):
				continue
			for n in izgara[h]:
				if n.position.distance_squared_to(p) <= r2:
					sonuc.append(n)
	return sonuc

func yenilenmeyi_denetle(zaman: float) -> void:
	for i in range(yenilenenler.size() - 1, -1, -1):
		var n = yenilenenler[i]
		var sure: float = Veri.NESNELER[n.tur].get("yenilenir", 0.0)
		if zaman - n.son_hasat >= sure:
			n.dolu = true
			n.queue_redraw()
			yenilenenler.remove_at(i)

# ---------------------------------------------------------------- kayıt

func kayit() -> Dictionary:
	var liste: Array = []
	for n in varliklar.get_children():
		if n.has_method("kayit") and n.tur != "":
			liste.append(n.kayit())
	return {"tohum": tohum, "biyom": Marshalls.raw_to_base64(biyom), "baslangic": [baslangic.x, baslangic.y], "nesneler": liste}

func yukle(v: Dictionary) -> void:
	tohum = int(v["tohum"])
	biyom = Marshalls.base64_to_raw(v["biyom"])
	baslangic = Vector2(v["baslangic"][0], v["baslangic"][1])
	zemin_ciz()
	for a in v["nesneler"]:
		var n = nesne_ekle(str(a[0]), Vector2(a[1], a[2]), int(a[3]))
		n.yukle(a)
		if n.tur in ["ot", "fidan", "dut_calisi"] and not n.dolu:
			yenilenenler.append(n)
