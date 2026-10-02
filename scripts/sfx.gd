extends Node
## Tiny procedural sound effects, so the prototype needs no audio assets.

const RATE := 22050
const VOICES := 8

var sounds := {}
var players: Array = []
var next := 0


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	sounds = {
		"select": _tone([[880.0, 0.03]], "square", 0.08),
		"step": _tone([[330.0, 0.06, -60.0]], "square", 0.12),
		"jump": _tone([[520.0, 0.11, 260.0]], "sine", 0.45),
		"tick": _tone([[1320.0, 0.05]], "sine", 0.2),
		"score": _tone([[660.0, 0.06], [990.0, 0.12]], "square", 0.12),
		"hit": _tone([[160.0, 0.22, -90.0]], "noise_sine", 0.5),
		"coin": _tone([[1046.0, 0.05], [1568.0, 0.12]], "square", 0.1),
		"win": _tone([[523.0, 0.09], [659.0, 0.09], [784.0, 0.09], [1046.0, 0.25]], "square", 0.12),
		"lose": _tone([[392.0, 0.15], [311.0, 0.15], [233.0, 0.35]], "square", 0.12),
	}


func play(id: String, pitch := 1.0) -> void:
	if not sounds.has(id):
		return
	var p: AudioStreamPlayer = players[next]
	next = (next + 1) % VOICES
	p.stream = sounds[id]
	p.pitch_scale = pitch
	p.play()


## notes: [[freq, seconds, optional slide in Hz]] played back to back.
func _tone(notes: Array, kind: String, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	for note in notes:
		var freq: float = note[0]
		var dur: float = note[1]
		var slide: float = note[2] if note.size() > 2 else 0.0
		var n := int(RATE * dur)
		var start := data.size()
		data.resize(start + n * 2)
		for i in n:
			var k := float(i) / n
			phase += (freq + slide * k) / RATE
			var s := sin(phase * TAU)
			if kind == "square":
				s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			elif kind == "noise_sine":
				s = s * 0.6 + (randf() * 2.0 - 1.0) * 0.4 * (1.0 - k)
			var env := minf(1.0, float(i) / (RATE * 0.004)) * pow(1.0 - k, 1.6)
			data.encode_s16(start + i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w
