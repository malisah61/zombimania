class_name Cizim
extends RefCounted
## Don't Starve havasında el çizimi görünüm: koyu kalın çizgiler, soluk renkler.
## Bütün çizimler kodla yapılır (görsel dosyası gerekmez). Merkez (0,0) = nesnenin yere bastığı nokta.

const CIZGI := Color(0.08, 0.07, 0.06)

# ---------------------------------------------------------------- Sprite Atölye görselleri
## assets/gorseller/<ad>.png varsa o çizilir, yoksa aşağıdaki kodla çizim kullanılır.
## Görseller assets/siparis.json'dan GitHub Actions'ta (gorsel_uret.yml) üretilir.

static var _dokular := {}

static func doku(ad: String) -> Texture2D:
	if _dokular.has(ad):
		return _dokular[ad]
	var yol := "res://assets/gorseller/%s.png" % ad
	var t: Texture2D = null
	if ResourceLoader.exists(yol):
		t = load(yol)
	_dokular[ad] = t
	return t

## Görseli tabanı (0,0)'da ortalı çizer. egim: üst kısmı yana yatırır (sallanma), f: -1 = aynala.
static func resim(ci: CanvasItem, t: Texture2D, boy: float, egim := 0.0, f := 1.0, renk := Color.WHITE, kayma := Vector2.ZERO, olcek := Vector2.ONE) -> void:
	var s := boy / t.get_height()
	var w := t.get_width() * s
	ci.draw_set_transform_matrix(Transform2D(0.0, Vector2(f * olcek.x, olcek.y), egim, kayma))
	ci.draw_texture_rect(t, Rect2(-w / 2.0, -boy, w, boy), false, renk)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)

## Karakter görseli için kâğıt kukla animasyonu: yürürken sekme ve sallanma, saldırıda öne eğilme.
static func karakter_resmi(ci: CanvasItem, t: Texture2D, boy: float, adim: float, yon: Vector2, hareket: bool, saldiri: float, renk: Color) -> float:
	var f := 1.0 if yon.x >= 0.0 else -1.0
	var sek := absf(sin(adim)) * 5.0 if hareket else sin(Time.get_ticks_msec() * 0.003) * 1.0
	var egim := (sin(adim) * 0.07 if hareket else 0.0) * f + saldiri * 0.22 * f
	var ezil := 1.0 + (sin(Time.get_ticks_msec() * 0.003) * 0.012 if not hareket else 0.0) - saldiri * 0.06
	golge(ci, boy * 0.15)
	resim(ci, t, boy, egim, f, renk, Vector2(0, -sek), Vector2(1.0 + (1.0 - ezil) * 0.5, ezil))
	return f

static func sekil(ci: CanvasItem, noktalar: PackedVector2Array, renk: Color, kalin := 2.5) -> void:
	ci.draw_colored_polygon(noktalar, renk)
	var k := noktalar.duplicate()
	k.append(noktalar[0])
	ci.draw_polyline(k, CIZGI, kalin, true)

static func daire(ci: CanvasItem, m: Vector2, r: float, renk: Color, kalin := 2.5) -> void:
	ci.draw_circle(m, r, renk)
	ci.draw_arc(m, r, 0, TAU, 20, CIZGI, kalin, true)

static func elips(m: Vector2, rx: float, ry: float, n := 16) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(m + Vector2(cos(a) * rx, sin(a) * ry))
	return p

static func golge(ci: CanvasItem, rx: float, ry := -1.0) -> void:
	if ry < 0:
		ry = rx * 0.38
	ci.draw_colored_polygon(elips(Vector2.ZERO, rx, ry), Color(0, 0, 0, 0.28))

## Pürüzlü daire (çalı, taş) — tohumla hep aynı şekil çıkar.
static func puruzlu(m: Vector2, r: float, tohum: int, n := 12, puruz := 0.18, ybasik := 1.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var h := sin(tohum * 12.9898 + i * 78.233) * 43758.5453
		h = h - floor(h)
		var rr := r * (1.0 - puruz + h * puruz * 2.0)
		p.append(m + Vector2(cos(a) * rr, sin(a) * rr * ybasik))
	return p

# ---------------------------------------------------------------- dünya nesneleri

static func agac(ci: CanvasItem, cesit: int, vurus_orani: float, salinim: float) -> void:
	var boy := 1.0 + (cesit % 5) * 0.08
	golge(ci, 30 * boy)
	var g := Color(0.42, 0.30, 0.20)
	sekil(ci, PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(5, -26 * boy), Vector2(-5, -26 * boy)]), g)
	var yesil := [Color(0.19, 0.29, 0.17), Color(0.23, 0.35, 0.20), Color(0.28, 0.41, 0.23)]
	if cesit % 7 == 0:
		yesil = [Color(0.25, 0.27, 0.15), Color(0.31, 0.33, 0.18), Color(0.37, 0.39, 0.21)]
	var s := salinim * (1.0 - vurus_orani * 0.3)
	for kat in 3:
		var t := float(kat)
		var tab := -18.0 * boy - t * 30.0 * boy
		var gen := (40.0 - t * 9.0) * boy
		var uc := tab - 46.0 * boy
		var x := s * (t + 1.0) * 1.6
		var p := PackedVector2Array([
			Vector2(-gen + x * 0.5, tab), Vector2(-gen * 0.55 + x * 0.6, tab - 8),
			Vector2(-gen * 0.7 + x * 0.7, tab - 10), Vector2(x, uc),
			Vector2(gen * 0.7 + x * 0.7, tab - 10), Vector2(gen * 0.55 + x * 0.6, tab - 8),
			Vector2(gen + x * 0.5, tab)])
		sekil(ci, p, yesil[kat])
		ci.draw_line(Vector2(-gen * 0.35 + x * 0.5, tab - 4), Vector2(x * 0.8, tab - 24 * boy), Color(0, 0, 0, 0.25), 2)

static func olu_agac(ci: CanvasItem, cesit: int) -> void:
	golge(ci, 22)
	var g := Color(0.33, 0.28, 0.24)
	sekil(ci, PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(4, -70), Vector2(-3, -76)]), g)
	var y := 1 if cesit % 2 == 0 else -1
	ci.draw_line(Vector2(0, -40), Vector2(26 * y, -66), CIZGI, 6)
	ci.draw_line(Vector2(0, -40), Vector2(26 * y, -66), g, 3)
	ci.draw_line(Vector2(0, -56), Vector2(-20 * y, -80), CIZGI, 5)
	ci.draw_line(Vector2(0, -56), Vector2(-20 * y, -80), g, 2.5)

static func kaya(ci: CanvasItem, cesit: int, oran: float) -> void:
	var r := 30.0 * (0.55 + 0.45 * oran)
	golge(ci, r * 1.1)
	var p := puruzlu(Vector2(0, -r * 0.6), r, cesit, 10, 0.14, 0.75)
	sekil(ci, p, Color(0.52, 0.50, 0.48))
	ci.draw_colored_polygon(puruzlu(Vector2(-r * 0.25, -r * 0.85), r * 0.38, cesit + 3, 8, 0.2, 0.6), Color(0.66, 0.64, 0.61))
	ci.draw_line(Vector2(r * 0.1, -r * 0.3), Vector2(r * 0.45, -r * 0.7), Color(0, 0, 0, 0.4), 2)
	if cesit % 3 == 0:
		ci.draw_circle(Vector2(r * 0.35, -r * 0.45), 3, Color(0.85, 0.72, 0.35))

static func fidan(ci: CanvasItem, dolu: bool) -> void:
	golge(ci, 12)
	var g := Color(0.45, 0.33, 0.22)
	if dolu:
		ci.draw_line(Vector2(0, 0), Vector2(-3, -38), CIZGI, 5)
		ci.draw_line(Vector2(0, 0), Vector2(-3, -38), g, 2.5)
		ci.draw_line(Vector2(-2, -20), Vector2(-14, -30), CIZGI, 4)
		ci.draw_line(Vector2(-2, -20), Vector2(-14, -30), g, 2)
		ci.draw_line(Vector2(-2, -28), Vector2(9, -40), CIZGI, 4)
		ci.draw_line(Vector2(-2, -28), Vector2(9, -40), g, 2)
		for p in [Vector2(-14, -31), Vector2(9, -41), Vector2(-3, -40)]:
			daire(ci, p, 4, Color(0.35, 0.48, 0.25), 1.5)
	else:
		ci.draw_line(Vector2(0, 0), Vector2(-1, -9), CIZGI, 4)
		ci.draw_line(Vector2(0, 0), Vector2(-1, -9), g, 2)

static func ot(ci: CanvasItem, dolu: bool, cesit: int, salinim: float) -> void:
	golge(ci, 14)
	var renk := Color(0.62, 0.60, 0.30) if dolu else Color(0.45, 0.40, 0.25)
	var n := 7
	var boy := 30.0 if dolu else 8.0
	for i in n:
		var x := (i - n / 2.0) * 3.6
		var h := boy * (0.7 + 0.3 * sin(i * 2.3 + cesit))
		var uc := Vector2(x * 1.8 + salinim * (h / 10.0), -h)
		ci.draw_line(Vector2(x, 0), uc, CIZGI, 4)
		ci.draw_line(Vector2(x, 0), uc, renk, 2)

static func dut_calisi(ci: CanvasItem, dolu: bool, cesit: int) -> void:
	golge(ci, 24)
	sekil(ci, puruzlu(Vector2(0, -18), 22, cesit, 14, 0.15, 0.8), Color(0.21, 0.32, 0.20))
	ci.draw_colored_polygon(puruzlu(Vector2(-6, -24), 11, cesit + 1, 10, 0.2, 0.8), Color(0.28, 0.40, 0.24))
	if dolu:
		for i in 6:
			var a := i * 1.7 + cesit
			var p := Vector2(cos(a) * 13, -18 + sin(a) * 9)
			daire(ci, p, 3.5, Color(0.75, 0.15, 0.20), 1.2)

static func havuc(ci: CanvasItem) -> void:
	golge(ci, 10)
	sekil(ci, PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(0, 4)]), Color(0.90, 0.48, 0.15), 1.5)
	for x in [-5, 0, 5]:
		ci.draw_line(Vector2(0, -1), Vector2(x, -16), CIZGI, 4)
		ci.draw_line(Vector2(0, -1), Vector2(x, -16), Color(0.35, 0.58, 0.25), 2)

static func mezar(ci: CanvasItem, cesit: int) -> void:
	golge(ci, 22)
	sekil(ci, elips(Vector2(0, 2), 22, 8), Color(0.30, 0.25, 0.20))
	if cesit % 2 == 0:
		sekil(ci, PackedVector2Array([Vector2(-12, -2), Vector2(12, -2), Vector2(12, -30), Vector2(8, -38), Vector2(-8, -38), Vector2(-12, -30)]), Color(0.50, 0.50, 0.50))
		ci.draw_line(Vector2(0, -32), Vector2(0, -12), Color(0, 0, 0, 0.5), 2)
		ci.draw_line(Vector2(-6, -26), Vector2(6, -26), Color(0, 0, 0, 0.5), 2)
	else:
		sekil(ci, PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(3, -44), Vector2(-3, -44)]), Color(0.40, 0.32, 0.24))
		sekil(ci, PackedVector2Array([Vector2(-12, -34), Vector2(12, -34), Vector2(12, -28), Vector2(-12, -28)]), Color(0.40, 0.32, 0.24))

static func alev(ci: CanvasItem, yakit_orani: float, t: float, y := -4.0) -> void:
	if yakit_orani <= 0.0:
		return
	var h := 18.0 + 30.0 * yakit_orani
	var titre := sin(t * 13.0) * 3.0 + sin(t * 7.3) * 2.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-13, y), Vector2(-9, y - h * 0.5), Vector2(-4 + titre * 0.5, y - h * 0.75), Vector2(titre, y - h), Vector2(6, y - h * 0.6), Vector2(11, y - h * 0.4), Vector2(13, y)]), Color(0.95, 0.45, 0.10))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-7, y), Vector2(-3, y - h * 0.45), Vector2(titre * 0.6, y - h * 0.7), Vector2(5, y - h * 0.35), Vector2(7, y)]), Color(1.0, 0.85, 0.35))

static func kamp_atesi(ci: CanvasItem, yakit_orani: float, t: float) -> void:
	golge(ci, 28)
	for i in 8:
		var a := TAU * i / 8.0
		daire(ci, Vector2(cos(a) * 22, sin(a) * 9 - 2), 6, Color(0.48, 0.47, 0.45), 1.8)
	var g := Color(0.35, 0.24, 0.15)
	sekil(ci, PackedVector2Array([Vector2(-16, -2), Vector2(14, -10), Vector2(16, -5), Vector2(-14, 3)]), g, 2)
	sekil(ci, PackedVector2Array([Vector2(-14, -10), Vector2(16, -2), Vector2(14, 3), Vector2(-16, -5)]), g, 2)
	if yakit_orani <= 0.0:
		ci.draw_colored_polygon(elips(Vector2(0, -3), 10, 4), Color(0.25, 0.25, 0.25))
		return
	var h := 18.0 + 30.0 * yakit_orani
	var titre := sin(t * 13.0) * 3.0 + sin(t * 7.3) * 2.0
	var dis := PackedVector2Array([Vector2(-13, -4), Vector2(-9, -h * 0.5), Vector2(-4 + titre * 0.5, -h * 0.75), Vector2(titre, -h), Vector2(6, -h * 0.6), Vector2(11, -h * 0.4), Vector2(13, -4)])
	ci.draw_colored_polygon(dis, Color(0.95, 0.45, 0.10))
	var ic := PackedVector2Array([Vector2(-7, -4), Vector2(-3, -h * 0.45), Vector2(titre * 0.6, -h * 0.7), Vector2(5, -h * 0.35), Vector2(7, -4)])
	ci.draw_colored_polygon(ic, Color(1.0, 0.85, 0.35))

static func tezgah(ci: CanvasItem) -> void:
	golge(ci, 34)
	var g := Color(0.50, 0.36, 0.22)
	sekil(ci, PackedVector2Array([Vector2(-28, 0), Vector2(-22, 0), Vector2(-22, -26), Vector2(-28, -26)]), g, 2)
	sekil(ci, PackedVector2Array([Vector2(22, 0), Vector2(28, 0), Vector2(28, -26), Vector2(22, -26)]), g, 2)
	sekil(ci, PackedVector2Array([Vector2(-34, -24), Vector2(34, -24), Vector2(30, -36), Vector2(-30, -36)]), Color(0.60, 0.44, 0.27))
	# testere
	sekil(ci, PackedVector2Array([Vector2(-18, -36), Vector2(8, -36), Vector2(4, -46), Vector2(-18, -44)]), Color(0.70, 0.72, 0.74), 2)
	sekil(ci, PackedVector2Array([Vector2(8, -40), Vector2(18, -40), Vector2(18, -46), Vector2(8, -46)]), Color(0.45, 0.25, 0.15), 2)
	# çekiç
	ci.draw_line(Vector2(20, -36), Vector2(26, -52), CIZGI, 5)
	ci.draw_line(Vector2(20, -36), Vector2(26, -52), g, 2.5)
	sekil(ci, PackedVector2Array([Vector2(19, -50), Vector2(33, -55), Vector2(34, -50), Vector2(20, -46)]), Color(0.4, 0.4, 0.42), 2)

static func duvar(ci: CanvasItem, oran: float, cesit: int) -> void:
	golge(ci, 30, 9)
	var g := Color(0.50, 0.38, 0.24).lerp(Color(0.32, 0.25, 0.18), 1.0 - oran)
	for i in 4:
		var x := -21 + i * 14
		var h := 52.0 + ((i + cesit) % 3) * 6.0
		sekil(ci, PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x + 6, -h), Vector2(x, -h - 9), Vector2(x - 6, -h)]), g, 2)
	ci.draw_line(Vector2(-28, -18), Vector2(28, -18), CIZGI, 5)
	ci.draw_line(Vector2(-28, -18), Vector2(28, -18), Color(0.40, 0.30, 0.18), 3)
	ci.draw_line(Vector2(-28, -38), Vector2(28, -38), CIZGI, 5)
	ci.draw_line(Vector2(-28, -38), Vector2(28, -38), Color(0.40, 0.30, 0.18), 3)

# ---------------------------------------------------------------- karakterler

## Oyuncu: kendi tasarımımız — turuncu bereli, yeşil montlu, sırt çantalı hayatta kalan.
static func oyuncu(ci: CanvasItem, adim: float, yon: Vector2, hareket: bool, el: String, zirh: bool, saldiri: float, hasar_t: float) -> void:
	var gt := doku("oyuncu")
	if gt != null:
		var renk := Color.WHITE.lerp(Color(1, 0.35, 0.35), hasar_t)
		var boy: float = Veri.GORSEL_BOY.get("oyuncu", 140.0)
		var f := karakter_resmi(ci, gt, boy, adim, yon, hareket, saldiri, renk)
		if el != "":
			var it := doku("ikon_" + el)
			var aci := -0.5 + (saldiri * 2.2 if saldiri > 0.0 else 0.0)
			var el_n := Vector2(16 * f, -boy * 0.42 - (absf(sin(adim)) * 5.0 if hareket else 0.0))
			if it != null:
				ci.draw_set_transform(el_n, aci * f, Vector2(f, 1) * 0.75)
				ci.draw_texture_rect(it, Rect2(-it.get_width() * 0.5 * 0.55, -it.get_height() * 0.55, it.get_width() * 0.55, it.get_height() * 0.55), false)
				ci.draw_set_transform_matrix(Transform2D.IDENTITY)
			else:
				alet(ci, el, el_n, aci * f, f)
		return
	golge(ci, 18)
	var sag := yon.x >= 0.0
	var arka := yon.y < -0.5
	var f := 1.0 if sag else -1.0
	var bacak := sin(adim) * 7.0 if hareket else 0.0
	var zip := absf(sin(adim)) * 2.5 if hareket else 0.0
	var ten := Color(0.93, 0.80, 0.66)
	if hasar_t > 0.0:
		ten = ten.lerp(Color(1, 0.3, 0.3), hasar_t)
	var pantolon := Color(0.27, 0.27, 0.33)
	# bacaklar
	ci.draw_line(Vector2(-4, -20), Vector2(-4 + bacak, -1), CIZGI, 7)
	ci.draw_line(Vector2(-4, -20), Vector2(-4 + bacak, -1), pantolon, 4)
	ci.draw_line(Vector2(4, -20), Vector2(4 - bacak, -1), CIZGI, 7)
	ci.draw_line(Vector2(4, -20), Vector2(4 - bacak, -1), pantolon, 4)
	var y := -zip
	# çanta (önde görünüyorsa arkada çiz)
	var canta := PackedVector2Array([Vector2(-12, -46 + y), Vector2(-2, -46 + y), Vector2(-2, -24 + y), Vector2(-12, -24 + y)])
	if not arka:
		for i in canta.size():
			canta[i].x = canta[i].x * f - 4 * f
		sekil(ci, canta, Color(0.55, 0.38, 0.22), 2)
	# gövde
	var mont := Color(0.30, 0.42, 0.28)
	if zirh:
		mont = Color(0.55, 0.40, 0.24)
	sekil(ci, PackedVector2Array([Vector2(-10, -18 + y), Vector2(10, -18 + y), Vector2(9, -44 + y), Vector2(-9, -44 + y)]), mont)
	if zirh:
		for i in 3:
			ci.draw_line(Vector2(-9, -24 - i * 8 + y), Vector2(9, -24 - i * 8 + y), Color(0, 0, 0, 0.45), 2)
	if arka:
		sekil(ci, PackedVector2Array([Vector2(-9, -44 + y), Vector2(9, -44 + y), Vector2(9, -22 + y), Vector2(-9, -22 + y)]), Color(0.55, 0.38, 0.22), 2)
	# kol + elindeki eşya
	var kol_aci := -0.3
	if saldiri > 0.0:
		kol_aci = -2.2 + (1.0 - saldiri) * 3.0
	elif hareket:
		kol_aci = sin(adim) * 0.5
	var omuz := Vector2(6 * f, -40 + y)
	var el_noktasi := omuz + Vector2(sin(kol_aci) * 16 * f, cos(kol_aci) * 16)
	if el != "":
		alet(ci, el, el_noktasi, kol_aci * f + (0.0 if sag else PI), f)
	ci.draw_line(omuz, el_noktasi, CIZGI, 7)
	ci.draw_line(omuz, el_noktasi, mont.darkened(0.1), 4)
	daire(ci, el_noktasi, 3.5, ten, 1.5)
	# kafa
	var kafa := Vector2(0, -58 + y)
	daire(ci, kafa, 15, ten)
	# bere
	sekil(ci, PackedVector2Array([Vector2(-16, -60 + y), Vector2(16, -60 + y), Vector2(13, -71 + y), Vector2(4, -76 + y), Vector2(-6, -76 + y), Vector2(-13, -71 + y)]), Color(0.88, 0.45, 0.14))
	ci.draw_line(Vector2(-16, -61 + y), Vector2(16, -61 + y), CIZGI, 5)
	ci.draw_line(Vector2(-16, -61 + y), Vector2(16, -61 + y), Color(0.72, 0.33, 0.10), 3)
	daire(ci, Vector2(-3, -78 + y), 4, Color(0.95, 0.90, 0.80), 1.5)
	if not arka:
		# yüz
		var g := 5.0 * f
		ci.draw_circle(kafa + Vector2(g - 3, 0), 2.6, CIZGI)
		ci.draw_circle(kafa + Vector2(g + 5, 0), 2.6, CIZGI)
		ci.draw_line(kafa + Vector2(g - 2, 7), kafa + Vector2(g + 4, 7), CIZGI, 2)
		# sakal gölgesi
		ci.draw_arc(kafa + Vector2(0, 3), 11, 0.4, PI - 0.4, 8, Color(0.45, 0.32, 0.22, 0.6), 3)

static func alet(ci: CanvasItem, id: String, el: Vector2, aci: float, f: float) -> void:
	var yonu := Vector2(sin(aci + PI * 0.5 * f), -cos(aci + PI * 0.5 * f)).normalized()
	yonu = Vector2(f * 0.35, -1).rotated(aci * 0.6).normalized()
	var uc := el + yonu * 30
	var sap := Color(0.50, 0.36, 0.22)
	ci.draw_line(el - yonu * 6, uc, CIZGI, 6)
	ci.draw_line(el - yonu * 6, uc, sap, 3)
	var dik := Vector2(-yonu.y, yonu.x)
	match id:
		"balta":
			sekil(ci, PackedVector2Array([uc - yonu * 2, uc - yonu * 12, uc - yonu * 14 + dik * 12 * f, uc + yonu * 2 + dik * 12 * f]), Color(0.68, 0.68, 0.70), 2)
		"kazma":
			sekil(ci, PackedVector2Array([uc + dik * 16, uc + dik * 6 + yonu * 4, uc - dik * 6 + yonu * 4, uc - dik * 16, uc - dik * 6 - yonu * 2, uc + dik * 6 - yonu * 2]), Color(0.55, 0.55, 0.58), 2)
		"mizrak":
			sekil(ci, PackedVector2Array([uc + yonu * 18, uc + dik * 5, uc - dik * 5]), Color(0.40, 0.38, 0.40), 2)
			ci.draw_line(uc - yonu * 2 + dik * 4, uc - yonu * 2 - dik * 4, Color(0.75, 0.70, 0.55), 3)
		"mesale":
			daire(ci, uc, 5, Color(0.40, 0.30, 0.18), 2)
			var t := Time.get_ticks_msec() / 1000.0
			var h := 16.0 + sin(t * 14.0) * 3.0
			ci.draw_colored_polygon(PackedVector2Array([uc + Vector2(-6, 0), uc + Vector2(0, -h), uc + Vector2(6, 0)]), Color(0.98, 0.55, 0.15))
			ci.draw_colored_polygon(PackedVector2Array([uc + Vector2(-3, 0), uc + Vector2(0, -h * 0.6), uc + Vector2(3, 0)]), Color(1, 0.9, 0.45))

static func zombi(ci: CanvasItem, tur: String, adim: float, yon: Vector2, saldiri: float, hasar_t: float, yaniyor: bool) -> void:
	var z: Dictionary = Veri.ZOMBILER.get(tur, Veri.ZOMBILER["yuruyen"])
	var b: float = z["boy"]
	var gt := doku("zombi_" + tur)
	if gt != null:
		var renk := Color.WHITE
		if yaniyor:
			renk = Color(1.0, 0.6, 0.4)
		renk = renk.lerp(Color(2.0, 2.0, 2.0), hasar_t * 0.6)
		karakter_resmi(ci, gt, Veri.GORSEL_BOY.get("zombi_" + tur, 140.0), adim, yon, true, saldiri, renk)
		if yaniyor:
			var t := Time.get_ticks_msec() / 1000.0
			for i in 3:
				var x := (i - 1) * 12.0 * b
				var h := 18.0 + sin(t * 12.0 + i) * 5.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, -50 * b), Vector2(x, -50 * b - h), Vector2(x + 7, -50 * b)]), Color(1.0, 0.55, 0.1, 0.85))
		return
	golge(ci, 18 * b)
	var f := 1.0 if yon.x >= 0.0 else -1.0
	var ten: Color = z["renk"]
	if hasar_t > 0.0:
		ten = ten.lerp(Color(1, 1, 1), hasar_t * 0.7)
	if yaniyor:
		ten = ten.lerp(Color(0.3, 0.15, 0.05), 0.4)
	var bacak := sin(adim) * 6.0
	var gomlek := Color(0.30, 0.34, 0.45) if tur != "kosucu" else Color(0.45, 0.25, 0.22)
	if tur == "iri":
		gomlek = Color(0.35, 0.30, 0.26)
	var pantolon := Color(0.25, 0.22, 0.20)
	ci.draw_line(Vector2(-4, -18) * b, Vector2(-4 + bacak, -1) * b, CIZGI, 7 * b)
	ci.draw_line(Vector2(-4, -18) * b, Vector2(-4 + bacak, -1) * b, pantolon, 4 * b)
	ci.draw_line(Vector2(4, -18) * b, Vector2(4 - bacak, -1) * b, CIZGI, 7 * b)
	ci.draw_line(Vector2(4, -18) * b, Vector2(4 - bacak, -1) * b, pantolon, 4 * b)
	var egik := 5.0 * f
	sekil(ci, PackedVector2Array([Vector2(-11, -16) * b, Vector2(11, -16) * b, Vector2(11 + egik, -42) * b, Vector2(-9 + egik, -42) * b]), gomlek)
	# yırtıklar
	ci.draw_line(Vector2(-6, -16) * b, Vector2(-3, -23) * b, CIZGI, 2)
	ci.draw_line(Vector2(-3, -23) * b, Vector2(0, -16) * b, CIZGI, 2)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, -17) * b, Vector2(-3, -22) * b, Vector2(-1, -17) * b]), ten)
	# öne uzanmış kollar
	var kol := sin(adim * 0.5) * 3.0
	if saldiri > 0.0:
		kol = -8.0 * saldiri
	for k in [-1, 1]:
		var o := Vector2((4 + k * 3 + egik), -38 + k * 2) * b
		var e := o + Vector2(f * (22 - saldiri * -6.0), 4 + kol + k * 2) * b
		ci.draw_line(o, e, CIZGI, 7 * b)
		ci.draw_line(o, e, ten.darkened(0.08), 4 * b)
	var kafa := Vector2(egik + 3 * f, -54) * b
	daire(ci, kafa, 13 * b, ten)
	# saç tutamları
	ci.draw_line(kafa + Vector2(-6, -11) * b, kafa + Vector2(-10, -17) * b, CIZGI, 2)
	ci.draw_line(kafa + Vector2(1, -13) * b, kafa + Vector2(2, -19) * b, CIZGI, 2)
	# ağız
	ci.draw_line(kafa + Vector2(2 * f, 7) * b, kafa + Vector2(9 * f, 6) * b, CIZGI, 2.5)
	ci.draw_circle(kafa + Vector2(-5 * f, -2) * b, 2.5 * b, Color(0.25, 0.30, 0.22))
	if yaniyor:
		var t := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var x := (i - 1) * 9.0
			var h := 14.0 + sin(t * 12.0 + i) * 4.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, -34) * b, Vector2(x, -34 - h) * b, Vector2(x + 5, -34) * b]), Color(1.0, 0.55, 0.1, 0.85))

## Zombi gözleri: karanlıkta parlar (ayrı düğümde, ışıktan etkilenmez).
static func zombi_gozu(ci: CanvasItem, tur: String, yon: Vector2) -> void:
	if doku("zombi_" + tur) != null:
		return
	var b: float = Veri.ZOMBILER.get(tur, Veri.ZOMBILER["yuruyen"])["boy"]
	var f := 1.0 if yon.x >= 0.0 else -1.0
	var kafa := Vector2(5.0 * f + 3 * f, -54) * b
	ci.draw_circle(kafa + Vector2(3 * f, -2) * b, 2.6 * b, Color(1.0, 0.25, 0.15))
	ci.draw_circle(kafa + Vector2(3 * f, -2) * b, 5.0 * b, Color(1.0, 0.2, 0.1, 0.25))

# ---------------------------------------------------------------- eşya simgeleri (yaklaşık 48x48 kutuya)

static func simge(ci: CanvasItem, id: String, m: Vector2, s := 1.0) -> void:
	var t := doku("ikon_" + id)
	if t == null and id in ["kamp_atesi", "tezgah", "duvar"]:
		t = doku(id)
	if t != null:
		var kutu := 50.0 * s
		var o := minf(kutu / t.get_width(), kutu / t.get_height())
		var boyut := Vector2(t.get_width(), t.get_height()) * o
		ci.draw_texture_rect(t, Rect2(m - boyut / 2.0, boyut), false)
		return
	var tr := Transform2D(0, Vector2(s, s), 0, m)
	ci.draw_set_transform_matrix(tr)
	match id:
		"odun":
			for i in 2:
				var y := -4.0 + i * 9.0
				sekil(ci, PackedVector2Array([Vector2(-16, y - 4), Vector2(14, y - 7), Vector2(16, y + 1), Vector2(-14, y + 4)]), Color(0.52, 0.36, 0.22), 2)
				daire(ci, Vector2(15, y - 3), 4.5, Color(0.80, 0.65, 0.42), 1.5)
		"dal":
			ci.draw_line(Vector2(-14, 14), Vector2(14, -14), CIZGI, 6)
			ci.draw_line(Vector2(-14, 14), Vector2(14, -14), Color(0.50, 0.36, 0.22), 3)
			ci.draw_line(Vector2(0, 0), Vector2(-4, -14), CIZGI, 5)
			ci.draw_line(Vector2(0, 0), Vector2(-4, -14), Color(0.50, 0.36, 0.22), 2.5)
		"ot":
			for i in 5:
				var x := (i - 2) * 4.0
				ci.draw_line(Vector2(x * 0.5, 14), Vector2(x * 2.2, -14), CIZGI, 4)
				ci.draw_line(Vector2(x * 0.5, 14), Vector2(x * 2.2, -14), Color(0.70, 0.66, 0.32), 2)
			ci.draw_line(Vector2(-6, 6), Vector2(6, 6), Color(0.45, 0.32, 0.18), 3)
		"tas":
			sekil(ci, puruzlu(Vector2(0, 2), 14, 3, 9, 0.15, 0.8), Color(0.55, 0.53, 0.50))
			ci.draw_colored_polygon(puruzlu(Vector2(-4, -2), 5, 5, 6, 0.2, 0.8), Color(0.70, 0.68, 0.65))
		"cakmak":
			sekil(ci, PackedVector2Array([Vector2(-10, 10), Vector2(-12, -2), Vector2(-2, -14), Vector2(10, -8), Vector2(12, 6), Vector2(2, 12)]), Color(0.30, 0.32, 0.38))
			ci.draw_line(Vector2(-6, -4), Vector2(4, -8), Color(0.6, 0.65, 0.75), 2)
		"ip":
			for i in 3:
				ci.draw_arc(Vector2(0, -6 + i * 6), 10, 0.2, PI * 2 - 0.2, 14, CIZGI, 5)
				ci.draw_arc(Vector2(0, -6 + i * 6), 10, 0.2, PI * 2 - 0.2, 14, Color(0.78, 0.68, 0.45), 2.5)
		"dut", "pismis_dut":
			var r := Color(0.75, 0.15, 0.20) if id == "dut" else Color(0.45, 0.12, 0.15)
			for p in [Vector2(-6, 4), Vector2(6, 4), Vector2(0, -5)]:
				daire(ci, p, 7, r, 2)
				ci.draw_circle(p + Vector2(-2, -2), 1.8, Color(1, 1, 1, 0.5))
		"havuc", "pismis_havuc":
			var r := Color(0.92, 0.50, 0.15) if id == "havuc" else Color(0.70, 0.35, 0.12)
			sekil(ci, PackedVector2Array([Vector2(-7, -8), Vector2(7, -8), Vector2(1, 16)]), r, 2)
			for x in [-6, 0, 6]:
				ci.draw_line(Vector2(0, -8), Vector2(x, -18), CIZGI, 4)
				ci.draw_line(Vector2(0, -8), Vector2(x, -18), Color(0.35, 0.58, 0.25), 2)
		"curuk_et", "kizarmis_et":
			var r := Color(0.55, 0.45, 0.42) if id == "curuk_et" else Color(0.55, 0.30, 0.18)
			sekil(ci, puruzlu(Vector2(-2, 0), 13, 9, 10, 0.18, 0.75), r)
			daire(ci, Vector2(11, -8), 4, Color(0.92, 0.88, 0.80), 1.5)
			if id == "curuk_et":
				ci.draw_circle(Vector2(-5, -2), 3, Color(0.45, 0.55, 0.30))
				ci.draw_circle(Vector2(3, 4), 2, Color(0.45, 0.55, 0.30))
		"lapa":
			sekil(ci, elips(Vector2(0, 4), 15, 9), Color(0.55, 0.42, 0.30))
			ci.draw_colored_polygon(elips(Vector2(0, 0), 12, 5), Color(0.45, 0.62, 0.32))
			ci.draw_circle(Vector2(-3, -1), 2, Color(0.75, 0.15, 0.2))
		"balta", "kazma", "mizrak", "mesale":
			ci.draw_set_transform_matrix(tr * Transform2D(0, Vector2(0.9, 0.9), 0, Vector2(-4, 14)))
			alet(ci, id, Vector2.ZERO, 0.0, 1.0)
		"tahta_zirh":
			sekil(ci, PackedVector2Array([Vector2(-14, -14), Vector2(-6, -16), Vector2(0, -12), Vector2(6, -16), Vector2(14, -14), Vector2(12, 14), Vector2(-12, 14)]), Color(0.58, 0.42, 0.26))
			for i in 3:
				ci.draw_line(Vector2(-12, -6 + i * 7), Vector2(12, -6 + i * 7), Color(0, 0, 0, 0.45), 2)
		"kamp_atesi":
			ci.draw_set_transform_matrix(tr * Transform2D(0, Vector2(0.7, 0.7), 0, Vector2(0, 12)))
			kamp_atesi(ci, 0.6, 1.0)
		"tezgah":
			ci.draw_set_transform_matrix(tr * Transform2D(0, Vector2(0.55, 0.55), 0, Vector2(0, 14)))
			tezgah(ci)
		"duvar":
			ci.draw_set_transform_matrix(tr * Transform2D(0, Vector2(0.55, 0.55), 0, Vector2(0, 16)))
			duvar(ci, 1.0, 0)
		_:
			daire(ci, Vector2.ZERO, 12, Color(0.6, 0.6, 0.6))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
