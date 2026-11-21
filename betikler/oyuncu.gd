extends Node2D
## Oyuncu karakteri: hareket, animasyon, ışık.

const MAKS_CAN := 150.0
const MAKS_ACLIK := 150.0
const MAKS_AKIL := 200.0
const HIZ := 190.0
const YARICAP := 13.0

var oyun
var can := MAKS_CAN
var aclik := MAKS_ACLIK
var akil := MAKS_AKIL
var yon := Vector2(1, 0.3)
var hareket := false
var adim := 0.0
var saldiri := 0.0
var hasar_t := 0.0
var oto_hedef = null       # eylem tuşu basılıyken yürüyeceği nesne/zombi
var isik: PointLight2D

func _ready() -> void:
	isik = PointLight2D.new()
	isik.texture = oyun.isik_dokusu
	isik.color = Color(1.0, 0.78, 0.50)
	isik.position = Vector2(0, -40)
	add_child(isik)

func ilerle(d: float, giris: Vector2) -> void:
	var v := giris
	if v.length() < 0.15 and oto_hedef != null and is_instance_valid(oto_hedef):
		var f: Vector2 = oto_hedef.position - position
		if f.length() > 4.0:
			v = f.normalized()
	if v.length() > 1.0:
		v = v.normalized()
	hareket = v.length() > 0.15
	if hareket:
		yon = v
		var yeni: Vector2 = oyun.hareket_et(position, position + v * HIZ * d, YARICAP)
		position = yeni
		adim += d * 12.0
	saldiri = maxf(0.0, saldiri - d * 3.5)
	hasar_t = maxf(0.0, hasar_t - d * 3.0)
	# ışık: meşale büyük, yoksa yalnızca kendini gösteren küçük bir parıltı
	var mesale: bool = oyun.mesale_yaniyor()
	if mesale:
		isik.texture_scale = 2.2 + sin(Time.get_ticks_msec() * 0.013) * 0.05
		isik.energy = 1.15 * oyun.isik_gucu
		isik.color = Color(1.0, 0.72, 0.42)
	else:
		isik.texture_scale = 0.55
		isik.energy = 0.55 * oyun.isik_gucu
		isik.color = Color(0.65, 0.70, 0.95)
	queue_redraw()

func _draw() -> void:
	var el: String = oyun.el.get("id", "")
	var zirh: bool = oyun.govde.get("id", "") != ""
	Cizim.oyuncu(self, adim, yon, hareket, el, zirh, saldiri, hasar_t)
