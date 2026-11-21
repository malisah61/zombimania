extends Node
## Kodla üretilen kısa sesler. assets/sesler/<ad>.ogg varsa onu kullanır.

const ORNEK := 22050
var _sesler := {}
var _calarlar: Array = []
var _sira := 0

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_calarlar.append(p)
	_sesler["kes"] = _gurultu(0.09, 900.0, 0.9, 140.0)
	_sesler["vur"] = _gurultu(0.12, 500.0, 0.8, 90.0)
	_sesler["yumruk"] = _gurultu(0.07, 300.0, 0.7, 70.0)
	_sesler["topla"] = _ton([660.0, 990.0], 0.06, 0.35)
	_sesler["craft"] = _ton([520.0, 780.0, 1040.0], 0.07, 0.35)
	_sesler["ye"] = _gurultu(0.15, 1800.0, 0.35, 0.0)
	_sesler["yan"] = _ton([220.0, 150.0], 0.09, 0.5)
	_sesler["inilti"] = _inilti()
	_sesler["kirildi"] = _gurultu(0.25, 700.0, 0.8, 60.0)
	_sesler["hata"] = _ton([200.0, 170.0], 0.07, 0.3)
	for ad in _sesler.keys():
		var yol := "res://assets/sesler/%s.ogg" % ad
		if ResourceLoader.exists(yol):
			_sesler[ad] = load(yol)

func cal(ad: String, ses := 1.0) -> void:
	if not _sesler.has(ad):
		return
	var p: AudioStreamPlayer = _calarlar[_sira]
	_sira = (_sira + 1) % _calarlar.size()
	p.stream = _sesler[ad]
	p.volume_db = linear_to_db(clampf(ses, 0.01, 1.0))
	p.pitch_scale = randf_range(0.92, 1.08)
	p.play()

func _wav(veri: PackedFloat32Array) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(veri.size() * 2)
	for i in veri.size():
		b.encode_s16(i * 2, int(clampf(veri[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = ORNEK
	w.data = b
	return w

func _gurultu(sure: float, kesim: float, guc: float, ton: float) -> AudioStreamWAV:
	var n := int(sure * ORNEK)
	var v := PackedFloat32Array()
	v.resize(n)
	var onceki := 0.0
	var a := clampf(kesim / ORNEK * 6.28, 0.01, 1.0)
	for i in n:
		var t := float(i) / ORNEK
		var zarf := pow(1.0 - float(i) / n, 2.0)
		onceki += (randf_range(-1, 1) - onceki) * a
		var s := onceki
		if ton > 0.0:
			s = s * 0.6 + sin(TAU * ton * t * (1.0 - t * 3.0)) * 0.6
		v[i] = s * zarf * guc
	return _wav(v)

func _ton(frekanslar: Array, parca: float, guc: float) -> AudioStreamWAV:
	var v := PackedFloat32Array()
	for f in frekanslar:
		var n := int(parca * ORNEK)
		for i in n:
			var t := float(i) / ORNEK
			var zarf := minf(1.0, i / 200.0) * (1.0 - float(i) / n)
			v.append(sin(TAU * f * t) * zarf * guc)
	return _wav(v)

func _inilti() -> AudioStreamWAV:
	var n := int(0.9 * ORNEK)
	var v := PackedFloat32Array()
	v.resize(n)
	var faz := 0.0
	for i in n:
		var t := float(i) / ORNEK
		var f := 95.0 + sin(t * 7.0) * 18.0 - t * 25.0
		faz += TAU * f / ORNEK
		var zarf := sin(PI * float(i) / n)
		var s := sin(faz) * 0.5 + sin(faz * 2.01) * 0.25 + randf_range(-0.15, 0.15)
		v[i] = s * zarf * 0.55
	return _wav(v)
