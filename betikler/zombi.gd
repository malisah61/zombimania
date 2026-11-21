extends Node2D
## Zombi: gece çoğalır, oyuncuyu kovalar, duvarlara saldırır; açık alanda güneşte yanar.

var oyun
var tur := "yuruyen"
var can := 60.0
var maks_can := 60.0
var hiz := 70.0
var hasar := 10.0
var yon := Vector2.RIGHT
var adim := 0.0
var saldiri := 0.0
var bekleme := 0.0
var hasar_t := 0.0
var yaniyor := false
var itme := Vector2.ZERO
var kovaliyor := false
var _gez_hedef := Vector2.ZERO
var _gez_t := 0.0
var _inilti_t := 0.0
var gozler: Node2D

class Gozler extends Node2D:
	var z
	func _draw() -> void:
		Cizim.zombi_gozu(self, z.tur, z.yon)

func kur(o, t: String) -> void:
	oyun = o
	tur = t
	var v: Dictionary = Veri.ZOMBILER[t]
	maks_can = v["can"] * (1.0 + 0.06 * (oyun.gun() - 1))
	can = maks_can
	hiz = v["hiz"] * randf_range(0.9, 1.1)
	hasar = v["hasar"]
	_gez_hedef = position
	_inilti_t = randf_range(2.0, 8.0)
	gozler = Gozler.new()
	gozler.z = self
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	gozler.material = m
	add_child(gozler)

func ilerle(d: float) -> void:
	var o = oyun.oyuncu
	var fark: Vector2 = o.position - position
	var mesafe := fark.length()
	var gorus := 420.0 if oyun.faz() == 0 else 680.0
	var git := Vector2.ZERO
	kovaliyor = not oyun.bitti and mesafe < gorus
	if kovaliyor:
		git = fark / maxf(mesafe, 0.01)
	else:
		_gez_t -= d
		if _gez_t <= 0.0:
			_gez_t = randf_range(2.0, 5.0)
			_gez_hedef = position + Vector2(randf_range(-160, 160), randf_range(-160, 160))
		var g := _gez_hedef - position
		if g.length() > 8.0:
			git = g.normalized() * 0.45
	var h := hiz
	# ateş ışığında ürker ve yavaşlar
	if oyun.ates_isiginda(position):
		h *= 0.55
	var yeni: Vector2 = oyun.hareket_et(position, position + git * h * d + itme * d, 14.0)
	var carpan = oyun.son_carpan
	position = yeni
	itme = itme.move_toward(Vector2.ZERO, 900.0 * d)
	if git.length() > 0.05:
		yon = git
		adim += d * h * 0.09
	bekleme -= d
	saldiri = maxf(0.0, saldiri - d * 3.0)
	hasar_t = maxf(0.0, hasar_t - d * 4.0)
	if kovaliyor and bekleme <= 0.0:
		if mesafe < 44.0:
			bekleme = 1.15
			saldiri = 1.0
			oyun.oyuncu_hasar(hasar, "zombi")
		elif carpan != null and is_instance_valid(carpan) and carpan.tur == "duvar":
			bekleme = 1.3
			saldiri = 1.0
			oyun.duvara_vur(carpan, hasar)
	_inilti_t -= d
	if _inilti_t <= 0.0:
		_inilti_t = randf_range(5.0, 12.0)
		if mesafe < 600.0:
			oyun.sesler.cal("inilti", clampf(1.0 - mesafe / 600.0, 0.15, 0.8))
	# sabah güneşi: açık arazideki zombiler yanar (orman ve bataklıkta gölge var)
	yaniyor = false
	if oyun.faz() == 0 and oyun.gun_orani() > 0.02:
		var b: int = oyun.dunya.biyom_at(position)
		if b != Veri.Biyom.ORMAN and b != Veri.Biyom.BATAKLIK:
			yaniyor = true
			can -= 14.0 * d
			if can <= 0.0:
				oyun.zombi_oldu(self, false)
				return
	queue_redraw()
	gozler.queue_redraw()

func vurul(m: float, kaynak: Vector2) -> void:
	can -= m
	hasar_t = 1.0
	itme = (position - kaynak).normalized() * 520.0
	if can <= 0.0:
		oyun.zombi_oldu(self, true)

func _draw() -> void:
	Cizim.zombi(self, tur, adim, yon, saldiri, hasar_t, yaniyor)
	if can < maks_can:
		var w := 34.0
		draw_rect(Rect2(-w / 2, -92, w, 5), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, -92, w * can / maks_can, 5), Color(0.8, 0.15, 0.1))
