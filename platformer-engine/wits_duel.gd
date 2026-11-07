extends Control
## Wits Duel with 5 switchable looks.
## Run this scene (F6) and press P to cycle through the looks.
## When you pick one, set "Preset" in the Inspector and turn off "Show Preview Hint".

static var preset_override := -1   # remembers the look when P reloads the scene

@export_enum("Deep Space", "Alien Temple", "Neon Synth", "Terminal", "Nebula Glass") var preset := 0
@export var show_preview_hint := true

@export_group("Gameplay")
@export_file("*.tscn") var return_scene := "res://level_1.tscn"
@export var duel_id := "guardian_1"
@export var points_to_win := 5
@export var time_limit := 10.0
@export_range(0.0, 1.0) var boss_accuracy := 0.6
@export var boss_min_time := 3.5
@export var boss_max_time := 8.0

@export_group("Look")
@export var guardian_name := ""           # leave empty to use the preset's name
@export var ui_font: Font                 # optional font (see notes)
@export var font_size := 22
@export var guardian_texture: Texture2D   # optional portrait; replaces the animated symbol

# ---------- The five looks ----------
var PRESETS: Array = [
	{
		"name": "Deep Space", "bg": "stars", "scan": false,
		"bg_top": "0a0f26", "bg_bottom": "261656", "bg_a": "3a2a7a", "bg_b": "ffffff",
		"panel": "11183a", "panel2": "1a2250", "edge": "3b4a8f",
		"ca": "4fd8ff", "cb": "ffc857", "good": "5cf2a0", "bad": "ff5c7a",
		"text": "e8f1ff", "dim": "8a96c4",
		"radius": 4, "border": 3, "glow": false, "alpha": 1.0,
		"pips": "diamond", "sides": 4, "offset": 0.0, "key_fmt": "%d   %s",
		"title": "WITS DUEL", "guardian": "THE GUARDIAN",
	},
	{
		"name": "Alien Temple", "bg": "temple", "scan": false,
		"bg_top": "140c08", "bg_bottom": "3d2410", "bg_a": "f2b84b", "bg_b": "f2b84b",
		"panel": "2a1a10", "panel2": "3a2516", "edge": "8a5f2e",
		"ca": "6fe0c8", "cb": "f2b84b", "good": "8be28b", "bad": "e0583c",
		"text": "f5e6c8", "dim": "a8906a",
		"radius": 2, "border": 4, "glow": false, "alpha": 1.0,
		"pips": "square", "sides": 6, "offset": 0.0, "key_fmt": "%d   %s",
		"title": "THE TRIAL", "guardian": "THE KEEPER",
	},
	{
		"name": "Neon Synth", "bg": "synth", "scan": false,
		"bg_top": "0d0221", "bg_bottom": "7a1a6e", "bg_a": "ff3fb4", "bg_b": "ff9e5e",
		"panel": "140a2e", "panel2": "1e1045", "edge": "5a2a9a",
		"ca": "2de2ff", "cb": "ff3fb4", "good": "7dffb0", "bad": "ff4d6d",
		"text": "f3e9ff", "dim": "9a86c9",
		"radius": 0, "border": 2, "glow": true, "alpha": 0.88,
		"pips": "circle", "sides": 3, "offset": 0.0, "key_fmt": "%d   %s",
		"title": "WITS DUEL", "guardian": "THE ORACLE",
	},
	{
		"name": "Terminal", "bg": "crt", "scan": true,
		"bg_top": "020a04", "bg_bottom": "04140a", "bg_a": "43ff7a", "bg_b": "43ff7a",
		"panel": "03100a", "panel2": "072014", "edge": "1f6b3a",
		"ca": "43ff7a", "cb": "ffb000", "good": "b8ff5c", "bad": "ff4a3d",
		"text": "b8ffcb", "dim": "4f9a6a",
		"radius": 0, "border": 2, "glow": true, "alpha": 1.0,
		"pips": "square", "sides": 4, "offset": PI / 4.0, "key_fmt": "[%d] %s",
		"title": "> WITS_DUEL.EXE", "guardian": "GUARDIAN.SYS",
	},
	{
		"name": "Nebula Glass", "bg": "nebula", "scan": false,
		"bg_top": "0c0a24", "bg_bottom": "1d1040", "bg_a": "6a4cff", "bg_b": "ff6ac8",
		"panel": "1b1640", "panel2": "2a2260", "edge": "8c7bff",
		"ca": "7fd6ff", "cb": "ff9ed8", "good": "8ff0c8", "bad": "ff7a9a",
		"text": "f4f0ff", "dim": "a9a3d6",
		"radius": 18, "border": 2, "glow": true, "alpha": 0.55,
		"pips": "circle", "sides": 0, "offset": 0.0, "key_fmt": "%d   %s",
		"title": "Wits Duel", "guardian": "The Weaver",
	},
]

# active look (filled in by _apply_preset)
var P: Dictionary
var preset_index := 0
var C_BG_TOP: Color
var C_BG_BOTTOM: Color
var C_PANEL: Color
var C_PANEL_2: Color
var C_EDGE: Color
var C_CA: Color      # player accent
var C_CB: Color      # guardian accent
var C_GOOD: Color
var C_BAD: Color
var C_TEXT: Color
var C_DIM: Color

# ---------- Content ----------
var questions: Array = [
	{"cat": "Science", "q": "Which planet is known as the Red Planet?", "a": "Mars", "wrong": ["Venus", "Jupiter", "Neptune"]},
	{"cat": "Science", "q": "What force keeps planets in orbit around the Sun?", "a": "Gravity", "wrong": ["Magnetism", "Friction", "Static"]},
	{"cat": "Science", "q": "About how long does sunlight take to reach Earth?", "a": "8 minutes", "wrong": ["8 seconds", "8 hours", "8 days"]},
	{"cat": "Science", "q": "Which is the largest planet in our solar system?", "a": "Jupiter", "wrong": ["Saturn", "Earth", "Neptune"]},
	{"cat": "Science", "q": "Which planet is famous for its bright rings?", "a": "Saturn", "wrong": ["Mars", "Mercury", "Venus"]},
	{"cat": "Science", "q": "Which is the hottest planet in our solar system?", "a": "Venus", "wrong": ["Mercury", "Mars", "Jupiter"]},
	{"cat": "Math", "q": "What is 7 x 8?", "a": "56", "wrong": ["54", "48", "63"]},
	{"cat": "Math", "q": "What comes next: 2, 4, 8, 16, ?", "a": "32", "wrong": ["24", "30", "36"]},
	{"cat": "Math", "q": "What is 15% of 200?", "a": "30", "wrong": ["15", "20", "25"]},
	{"cat": "Math", "q": "What comes next: 1, 1, 2, 3, 5, ?", "a": "8", "wrong": ["6", "7", "9"]},
	{"cat": "Math", "q": "What is 144 divided by 12?", "a": "12", "wrong": ["14", "11", "13"]},
	{"cat": "Math", "q": "What comes next: 3, 6, 11, 18, ?", "a": "27", "wrong": ["25", "26", "28"]},
	{"cat": "Math", "q": "Solve for x: 3x + 4 = 19", "a": "5", "wrong": ["4", "6", "7"]},
	{"cat": "Logic", "q": "Which is the odd one out: Mars, Venus, Moon, Jupiter?", "a": "Moon", "wrong": ["Mars", "Venus", "Jupiter"]},
	{"cat": "Logic", "q": "All Zorbs are Glims. All Glims are Plox. Are all Zorbs Plox?", "a": "Yes", "wrong": ["No", "Only some", "Can't tell"]},
	{"cat": "Logic", "q": "A rocket burns 3 fuel per minute. How much does it burn in 7 minutes?", "a": "21", "wrong": ["10", "18", "24"]},
	{"cat": "Logic", "q": "If today is Monday, what day will it be in 10 days?", "a": "Thursday", "wrong": ["Tuesday", "Wednesday", "Friday"]},
	{"cat": "Logic", "q": "Which number does not belong: 2, 5, 9, 11?", "a": "9", "wrong": ["2", "5", "11"]},
	{"cat": "Riddle", "q": "I have cities but no houses, mountains but no trees, and water but no fish. What am I?", "a": "A map", "wrong": ["A dream", "A planet", "A painting"]},
	{"cat": "Riddle", "q": "The more you take, the more you leave behind. What am I?", "a": "Footsteps", "wrong": ["Time", "Shadows", "Memories"]},
	{"cat": "Riddle", "q": "What can you catch but not throw?", "a": "A cold", "wrong": ["A ball", "A shadow", "A star"]},
]

var quips_start := ["Prove your wits, traveler.", "Few pass. Fewer still return.", "Let us see how sharp you are."]
var quips_correct := ["Hmm. Correct.", "The ancients smile... briefly.", "Lucky guess, traveler.", "You surprise me."]
var quips_boss := ["Too slow.", "Knowledge favors the swift.", "I have waited eons for better.", "Try harder."]
var quips_wrong := ["Wrong. Disappointing.", "Is that your final answer?", "Even the dust knows this."]
var quips_timeout := ["Time slips away...", "Silence is not an answer."]

# ---------- State ----------
var deck: Array = []
var answer_buttons: Array[Button] = []
var correct_answer := ""
var last_pick := ""
var player_score := 0
var boss_score := 0
var round_num := 0
var hints_left := 0
var elapsed := 0.0
var time_left := 0.0
var boss_time := 0.0
var boss_correct := false
var round_active := false

# ---------- UI references ----------
var margin: MarginContainer
var fade: ColorRect
var player_pips: Pips
var boss_pips: Pips
var round_label: Label
var category_label: Label
var prompt: Label
var answers: GridContainer
var message: Label
var speech: Label
var sigil: GuardianSigil
var boss_bar: ProgressBar
var timer_bar: ProgressBar
var timer_fill: StyleBoxFlat
var hint_button: Button
var prompt_tween: Tween
var speech_tween: Tween


# =====================================================
#  Inner classes: custom-drawn visuals
# =====================================================

class Backdrop extends Control:
	var kind := "stars"
	var top := Color("0a0f26")
	var bottom := Color("261656")
	var a := Color("3a2a7a")
	var b := Color("ffffff")
	var stars: Array = []
	var t := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 90:
			stars.append({
				"p": Vector2(rng.randf(), rng.randf()),
				"ph": rng.randf() * TAU,
				"sp": rng.randf_range(0.5, 2.0),
				"s": rng.randi_range(1, 3),
			})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _gradient(h: float) -> void:
		var bands := 28
		for i in bands:
			var f := float(i) / float(bands - 1)
			var y := h * float(i) / float(bands)
			draw_rect(Rect2(0.0, y, size.x, h / float(bands) + 1.0), top.lerp(bottom, f))

	func _stars(limit_y: float, strength: float) -> void:
		for s in stars:
			var tw := 0.3 + 0.7 * (0.5 + 0.5 * sin(t * float(s["sp"]) + float(s["ph"])))
			var sz: int = s["s"]
			var p: Vector2 = s["p"]
			draw_rect(Rect2(Vector2(floorf(p.x * size.x), floorf(p.y * limit_y)), Vector2(sz, sz)), Color(1, 1, 1, tw * strength))

	func _draw() -> void:
		match kind:
			"temple":
				_draw_temple()
			"synth":
				_draw_synth()
			"crt":
				_draw_crt()
			"nebula":
				_draw_nebula()
			_:
				_draw_stars()

	func _draw_stars() -> void:
		_gradient(size.y)
		var pc := Vector2(size.x * 0.86, size.y * 0.82)
		draw_circle(pc, 200.0, Color(a, 0.6))
		draw_circle(pc + Vector2(-20.0, -20.0), 165.0, Color(a.lightened(0.15), 0.5))
		draw_arc(pc, 270.0, PI * 1.08, PI * 1.92, 48, Color(0.55, 0.5, 0.95, 0.22), 6.0)
		_stars(size.y, 1.0)

	func _draw_temple() -> void:
		_gradient(size.y)
		# slanted shafts of light
		for i in 3:
			var bx := size.x * (0.25 + 0.25 * float(i))
			var w := 70.0 + 30.0 * sin(t * 0.3 + float(i))
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx - 8.0, 0.0), Vector2(bx + 8.0, 0.0),
				Vector2(bx + w, size.y), Vector2(bx - w, size.y)]), Color(a, 0.045))
		# giant carved sun-glyph ring
		var c := Vector2(size.x * 0.5, size.y * 0.52)
		var r := minf(size.x, size.y) * 0.46
		draw_arc(c, r, 0.0, TAU, 96, Color(b, 0.10), 3.0)
		draw_arc(c, r * 0.82, 0.0, TAU, 96, Color(b, 0.08), 2.0)
		for i in 24:
			var ang := t * 0.05 + float(i) * TAU / 24.0
			var d := Vector2(cos(ang), sin(ang))
			draw_line(c + d * r * 0.86, c + d * r * 0.98, Color(b, 0.10), 3.0)
		# stone pillars at both edges
		for side in 2:
			var px := 0.0 if side == 0 else size.x - 56.0
			draw_rect(Rect2(px, 0.0, 56.0, size.y), Color(0, 0, 0, 0.28))
			for k in 3:
				draw_rect(Rect2(px + 10.0 + float(k) * 16.0, 0.0, 3.0, size.y), Color(b, 0.05))
		# drifting dust
		for s in stars:
			var p: Vector2 = s["p"]
			var y := fposmod(p.y - t * float(s["sp"]) * 0.02, 1.0) * size.y
			var x := p.x * size.x + sin(t * float(s["sp"]) + float(s["ph"])) * 6.0
			var tw := 0.5 + 0.5 * sin(t * 1.5 + float(s["ph"]))
			draw_rect(Rect2(Vector2(floorf(x), floorf(y)), Vector2(2, 2)), Color(b, 0.45 * tw))

	func _draw_synth() -> void:
		var hz := size.y * 0.58
		_gradient(hz)
		_stars(hz, 0.7)
		# striped sun
		var sr := size.y * 0.24
		var sc := Vector2(size.x * 0.5, hz - sr * 0.55)
		draw_circle(sc, sr, Color(b, 0.95))
		for i in 6:
			var y := sc.y - sr * 0.1 + float(i) * sr * 0.17
			var th := 2.0 + float(i) * 1.6
			var sky := top.lerp(bottom, clampf(y / hz, 0.0, 1.0))
			draw_rect(Rect2(sc.x - sr - 2.0, y, sr * 2.0 + 4.0, th), sky)
		# ground
		draw_rect(Rect2(0.0, hz, size.x, size.y - hz), top.darkened(0.25))
		# scrolling perspective grid
		for k in 10:
			var depth := fposmod(float(k) + t * 0.7, 10.0) / 10.0
			var y := hz + (size.y - hz) * depth * depth
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(a, 0.15 + 0.5 * depth), 2.0)
		var vp := Vector2(size.x * 0.5, hz)
		for i in range(-14, 15):
			draw_line(vp, Vector2(size.x * 0.5 + float(i) * size.x * 0.1, size.y), Color(a, 0.35), 1.5)
		draw_rect(Rect2(0.0, hz - 2.0, size.x, 3.0), Color(a, 0.85))

	func _draw_crt() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), top.lerp(bottom, 0.5))
		var step := 32.0
		for gx in int(size.x / step) + 1:
			for gy in int(size.y / step) + 1:
				draw_rect(Rect2(float(gx) * step, float(gy) * step, 2.0, 2.0), Color(a, 0.12))
		var c := size / 2.0
		for i in 4:
			draw_arc(c, 120.0 * float(i + 1), 0.0, TAU, 64, Color(a, 0.05), 2.0)
		var ang := t * 0.6
		var reach := size.length() * 0.6
		draw_colored_polygon(PackedVector2Array([
			c,
			c + Vector2(cos(ang), sin(ang)) * reach,
			c + Vector2(cos(ang - 0.35), sin(ang - 0.35)) * reach]), Color(a, 0.04))
		draw_line(c, c + Vector2(cos(ang), sin(ang)) * reach, Color(a, 0.10), 2.0)
		# corner brackets
		var m := 14.0
		var l := 34.0
		var col := Color(a, 0.5)
		draw_polyline(PackedVector2Array([Vector2(m, m + l), Vector2(m, m), Vector2(m + l, m)]), col, 3.0)
		draw_polyline(PackedVector2Array([Vector2(size.x - m - l, m), Vector2(size.x - m, m), Vector2(size.x - m, m + l)]), col, 3.0)
		draw_polyline(PackedVector2Array([Vector2(m, size.y - m - l), Vector2(m, size.y - m), Vector2(m + l, size.y - m)]), col, 3.0)
		draw_polyline(PackedVector2Array([Vector2(size.x - m - l, size.y - m), Vector2(size.x - m, size.y - m), Vector2(size.x - m, size.y - m - l)]), col, 3.0)

	func _draw_nebula() -> void:
		_gradient(size.y)
		var mid := a.lerp(b, 0.5)
		var blobs := [
			[0.18, 0.30, a, 0.0],
			[0.82, 0.28, b, 1.7],
			[0.55, 0.85, mid, 3.1],
		]
		for bl in blobs:
			var ph := float(bl[3])
			var ctr := Vector2(
				size.x * (float(bl[0]) + 0.04 * sin(t * 0.2 + ph)),
				size.y * (float(bl[1]) + 0.04 * cos(t * 0.17 + ph)))
			var col: Color = bl[2]
			for k in 16:
				draw_circle(ctr, 360.0 - float(k) * 20.0, Color(col, 0.02))
		_stars(size.y, 0.7)


class Overlay extends Control:
	var scan := false
	var tint := Color("43ff7a")
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		if scan:
			queue_redraw()

	func _draw() -> void:
		# soft vignette
		for i in 10:
			var inset := float(i) * 9.0 + 5.0
			var al := 0.10 * (1.0 - float(i) / 10.0)
			draw_rect(Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0), Color(0, 0, 0, al), false, 10.0)
		if scan:
			var y := 0.0
			while y < size.y:
				draw_rect(Rect2(0.0, y, size.x, 1.0), Color(0, 0, 0, 0.22))
				y += 3.0
			var band := fposmod(t * 80.0, size.y + 60.0) - 60.0
			draw_rect(Rect2(0.0, band, size.x, 60.0), Color(tint, 0.035))


class GuardianSigil extends Control:
	var mood := "idle"   # idle, thinking, smug, beaten
	var think := 0.0     # 0..1, progress of the Guardian's "thinking"
	var t := 0.0
	var sides := 4       # 0 = circles, 3 = triangle, 4 = square/diamond, 6 = hexagon
	var offset := 0.0
	var c_idle := Color("4fd8ff")
	var c_think := Color("ffc857")
	var c_smug := Color("ff5c7a")
	var c_beaten := Color("5cf2a0")
	var dark := Color("0a0f26")

	func set_mood(m: String) -> void:
		mood = m

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _ring(r: float, col: Color, w: float) -> void:
		if sides < 3:
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, col, w)
		else:
			var pts := PackedVector2Array()
			for i in sides + 1:
				var ang := -PI / 2.0 + offset + float(i) * TAU / float(sides)
				pts.append(Vector2(cos(ang), sin(ang)) * r)
			draw_polyline(pts, col, w)

	func _draw() -> void:
		var col := c_idle
		var speed := 2.0
		var sc := 1.0
		match mood:
			"thinking":
				col = c_think
				speed = 2.0 + think * 7.0
			"smug":
				col = c_smug
				speed = 9.0
				sc = 1.08
			"beaten":
				col = c_beaten
				speed = 1.2
				sc = 0.92
		var pulse := 0.5 + 0.5 * sin(t * speed)
		var c := size / 2.0
		var m := minf(size.x, size.y) / 2.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(c, m * 0.95, Color(col, 0.06 + pulse * 0.06))
		draw_set_transform(c, t * 0.25, Vector2(sc, sc))
		_ring(m * 0.82, Color(col, 0.9), 3.0)
		draw_set_transform(c, -t * 0.4, Vector2(sc, sc))
		_ring(m * 0.62, Color(col, 0.6), 2.0)
		draw_set_transform(c, t * 0.7, Vector2(sc, sc))
		_ring(m * 0.42, Color(col, 0.9), 2.0)
		# the eye
		draw_set_transform(c, 0.0, Vector2(sc, sc))
		var eye_r := m * 0.2 + pulse * 3.0
		draw_circle(Vector2.ZERO, eye_r, col)
		var look := Vector2(sin(t * 0.9), cos(t * 0.6)) * eye_r * 0.35
		draw_circle(look, eye_r * 0.45, dark)
		draw_rect(Rect2(look + Vector2(-3, -5), Vector2(3, 3)), Color(1, 1, 1, 0.8))
		# orbiting specks
		for i in 6:
			var ang := t * 0.8 + float(i) * TAU / 6.0
			var p := Vector2(cos(ang), sin(ang)) * m * 0.95
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(col, 0.8))


class Pips extends Control:
	var total := 5
	var filled := 0
	var color := Color("4fd8ff")
	var shape := "diamond"   # diamond, square, circle
	var pop := 0.0

	func set_filled(n: int) -> void:
		if n > filled:
			pop = 1.0
		filled = n
		queue_redraw()

	func _process(delta: float) -> void:
		if pop > 0.0:
			pop = maxf(0.0, pop - delta * 3.0)
			queue_redraw()

	func _draw() -> void:
		for i in total:
			var c := Vector2(14.0 + float(i) * 28.0, size.y / 2.0)
			var r := 9.0
			if i == filled - 1:
				r += pop * 5.0
			var on := i < filled
			var col := color if on else Color(color, 0.35)
			match shape:
				"square":
					var rc := Rect2(c - Vector2(r, r) * 0.85, Vector2(r, r) * 1.7)
					if on:
						draw_rect(rc, col)
					else:
						draw_rect(rc, col, false, 2.0)
				"circle":
					if on:
						draw_circle(c, r, col)
					else:
						draw_arc(c, r, 0.0, TAU, 24, col, 2.0)
				_:
					var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
					if on:
						draw_colored_polygon(pts, col)
					else:
						pts.append(pts[0])
						draw_polyline(pts, col, 2.0)


# =====================================================
#  Look + UI construction
# =====================================================

func _c(key: String) -> Color:
	return Color(String(P[key]))

func _apply_preset() -> void:
	var idx := preset if preset_override < 0 else preset_override
	preset_index = clampi(idx, 0, PRESETS.size() - 1)
	P = PRESETS[preset_index]
	C_BG_TOP = _c("bg_top")
	C_BG_BOTTOM = _c("bg_bottom")
	C_PANEL = _c("panel")
	C_PANEL_2 = _c("panel2")
	C_EDGE = _c("edge")
	C_CA = _c("ca")
	C_CB = _c("cb")
	C_GOOD = _c("good")
	C_BAD = _c("bad")
	C_TEXT = _c("text")
	C_DIM = _c("dim")

func _fs(mult: float) -> int:
	return int(round(font_size * mult))

func _panel_box(bg: Color, border: Color, margin_px := 12, drop := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg, bg.a * float(P["alpha"]))
	s.border_color = border
	s.set_border_width_all(int(P["border"]))
	s.set_corner_radius_all(int(P["radius"]))
	s.content_margin_left = margin_px
	s.content_margin_right = margin_px
	s.content_margin_top = margin_px
	s.content_margin_bottom = margin_px
	if drop:
		if bool(P["glow"]):
			s.shadow_color = Color(border, 0.45)
			s.shadow_size = 10
			s.shadow_offset = Vector2.ZERO
		else:
			s.shadow_color = Color(0, 0, 0, 0.4)
			s.shadow_size = 6
			s.shadow_offset = Vector2(0, 4)
	return s

func _flat_box(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	return s

func _label(t: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _make_bar(color: Color) -> ProgressBar:
	var rad := mini(int(P["radius"]), 4)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 14)
	b.add_theme_stylebox_override("background", _flat_box(C_BG_TOP.darkened(0.3), C_EDGE, 2, rad))
	b.add_theme_stylebox_override("fill", _flat_box(color, color, 0, rad))
	return b

func _style_button(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", _panel_box(C_PANEL_2, C_EDGE, 10))
	b.add_theme_stylebox_override("hover", _panel_box(C_PANEL_2.lightened(0.15), accent, 10))
	b.add_theme_stylebox_override("pressed", _panel_box(C_PANEL_2.lightened(0.3), C_CB, 10, false))
	b.add_theme_stylebox_override("disabled", _panel_box(C_PANEL.darkened(0.4), C_EDGE.darkened(0.5), 10, false))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", C_DIM.darkened(0.35))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _make_pips(color: Color) -> Pips:
	var p := Pips.new()
	p.total = points_to_win
	p.color = color
	p.shape = String(P["pips"])
	p.custom_minimum_size = Vector2(points_to_win * 28, 26)
	return p

func _pip_column(title: String, pips: Pips, color: Color) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(_label(title, _fs(0.7), color))
	v.add_child(pips)
	return v

func _build_ui() -> void:
	var th := Theme.new()
	if ui_font:
		th.default_font = ui_font
	th.default_font_size = font_size
	theme = th

	var bg := Backdrop.new()
	bg.kind = String(P["bg"])
	bg.top = C_BG_TOP
	bg.bottom = C_BG_BOTTOM
	bg.a = _c("bg_a")
	bg.b = _c("bg_b")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	margin.add_child(main)

	# ----- top bar -----
	player_pips = _make_pips(C_CA)
	boss_pips = _make_pips(C_CB)
	var top := HBoxContainer.new()
	main.add_child(top)
	top.add_child(_pip_column("YOU", player_pips, C_CA))
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(_label(String(P["title"]), _fs(1.4), C_CB, HORIZONTAL_ALIGNMENT_CENTER))
	round_label = _label("ROUND 1", _fs(0.7), C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	title_box.add_child(round_label)
	top.add_child(title_box)
	top.add_child(_pip_column("GUARDIAN", boss_pips, C_CB))

	# ----- middle -----
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 18)
	main.add_child(middle)

	var gpanel := PanelContainer.new()
	gpanel.add_theme_stylebox_override("panel", _panel_box(C_PANEL, C_EDGE, 14))
	gpanel.custom_minimum_size = Vector2(250, 0)
	middle.add_child(gpanel)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 8)
	gpanel.add_child(gv)

	var portrait := CenterContainer.new()
	gv.add_child(portrait)
	if guardian_texture:
		var tr := TextureRect.new()
		tr.texture = guardian_texture
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(210, 210)
		portrait.add_child(tr)
	else:
		sigil = GuardianSigil.new()
		sigil.sides = int(P["sides"])
		sigil.offset = float(P["offset"])
		sigil.c_idle = C_CA
		sigil.c_think = C_CB
		sigil.c_smug = C_BAD
		sigil.c_beaten = C_GOOD
		sigil.dark = C_BG_TOP
		sigil.custom_minimum_size = Vector2(210, 210)
		portrait.add_child(sigil)

	var gname := guardian_name if guardian_name != "" else String(P["guardian"])
	gv.add_child(_label(gname, _fs(0.9), C_CB, HORIZONTAL_ALIGNMENT_CENTER))
	speech = _label("", _fs(0.8), C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size = Vector2(0, 70)
	speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gv.add_child(speech)
	gv.add_child(_label("THINKING", _fs(0.6), C_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	boss_bar = _make_bar(C_CB)
	gv.add_child(boss_bar)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	middle.add_child(right)

	var qpanel := PanelContainer.new()
	qpanel.add_theme_stylebox_override("panel", _panel_box(C_PANEL, C_CA, 18))
	right.add_child(qpanel)
	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", 8)
	qpanel.add_child(qv)
	category_label = _label("SCIENCE", _fs(0.7), C_CB)
	qv.add_child(category_label)
	prompt = _label("", _fs(1.3), C_TEXT)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.custom_minimum_size = Vector2(0, 96)
	prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qv.add_child(prompt)

	answers = GridContainer.new()
	answers.columns = 2
	answers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	answers.add_theme_constant_override("h_separation", 12)
	answers.add_theme_constant_override("v_separation", 12)
	right.add_child(answers)

	message = _label("", _fs(1.2), C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(message)

	# ----- bottom bar -----
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	main.add_child(bottom)
	bottom.add_child(_label("TIME", _fs(0.7), C_DIM))
	timer_bar = _make_bar(C_CA)
	timer_fill = timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	timer_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(timer_bar)
	hint_button = Button.new()
	hint_button.custom_minimum_size = Vector2(170, 42)
	hint_button.tooltip_text = "Removes two wrong answers"
	_style_button(hint_button, C_CB)
	bottom.add_child(hint_button)

	# vignette (+ scanlines for the Terminal look)
	var ov := Overlay.new()
	ov.scan = bool(P["scan"])
	ov.tint = C_CA
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if show_preview_hint:
		var hint := _label("P: next look   (%d/%d)  %s" % [preset_index + 1, PRESETS.size(), String(P["name"])], _fs(0.55), C_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hint)
		hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		hint.offset_left = -520.0
		hint.offset_top = 6.0
		hint.offset_right = -12.0

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# =====================================================
#  Game flow
# =====================================================

func _ready() -> void:
	_apply_preset()
	_build_ui()
	timer_bar.max_value = time_limit
	boss_bar.max_value = boss_max_time
	hint_button.pressed.connect(_on_hint)
	create_tween().tween_property(fade, "color:a", 0.0, 0.6)
	_start_match()

func _start_match() -> void:
	player_score = 0
	boss_score = 0
	round_num = 0
	hints_left = GameState.insight
	deck.clear()
	if sigil:
		sigil.set_mood("idle")
	_say(quips_start.pick_random())
	_next_round()

func _next_round() -> void:
	round_num += 1
	if deck.is_empty():
		deck = questions.duplicate()
		deck.shuffle()
	var q: Dictionary = deck.pop_back()
	correct_answer = q["a"]
	last_pick = ""
	category_label.text = String(q["cat"]).to_upper()
	prompt.text = q["q"]
	prompt.visible_ratio = 0.0
	if prompt_tween:
		prompt_tween.kill()
	prompt_tween = create_tween()
	prompt_tween.tween_property(prompt, "visible_ratio", 1.0, 0.8)
	message.text = ""
	if sigil:
		sigil.set_mood("thinking")

	for b in answer_buttons:
		answers.remove_child(b)
		b.queue_free()
	answer_buttons.clear()
	var options: Array = q["wrong"].duplicate()
	options.append(q["a"])
	options.shuffle()
	var fmt := String(P["key_fmt"])
	for i in options.size():
		var b := Button.new()
		b.text = fmt % [i + 1, options[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 56)
		_style_button(b, C_CA)
		b.set_meta("opt", options[i])
		b.pressed.connect(_on_answer.bind(options[i]))
		b.modulate.a = 0.0
		answers.add_child(b)
		b.create_tween().tween_property(b, "modulate:a", 1.0, 0.25).set_delay(float(i) * 0.08)
		answer_buttons.append(b)

	boss_correct = randf() < boss_accuracy
	boss_time = randf_range(boss_min_time, boss_max_time)
	elapsed = 0.0
	time_left = time_limit
	round_active = true
	_update_ui()

func _process(delta: float) -> void:
	if not round_active:
		return
	elapsed += delta
	time_left -= delta
	timer_bar.value = time_left
	boss_bar.value = minf(elapsed, boss_max_time)
	if sigil:
		sigil.think = clampf(elapsed / boss_max_time, 0.0, 1.0)
	var low := time_left < 3.0
	timer_fill.bg_color = C_BAD if low else C_CA
	timer_fill.border_color = timer_fill.bg_color
	if boss_correct and elapsed >= boss_time:
		_end_round("boss", "The Guardian answers first!")
	elif time_left <= 0.0:
		_end_round("timeout", "Out of time!")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			preset_override = (preset_index + 1) % PRESETS.size()
			get_tree().reload_current_scene()
			return
		if not round_active:
			return
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < answer_buttons.size() and not answer_buttons[idx].disabled:
			_on_answer(String(answer_buttons[idx].get_meta("opt")))

func _on_answer(choice: String) -> void:
	if not round_active:
		return
	last_pick = choice
	if choice == correct_answer:
		_end_round("correct", "Correct!")
	else:
		_end_round("wrong", "Wrong! It was: " + correct_answer)

func _on_hint() -> void:
	if hints_left <= 0 or not round_active:
		return
	hints_left -= 1
	var removed := 0
	for b in answer_buttons:
		if String(b.get_meta("opt")) != correct_answer and not b.disabled and removed < 2:
			b.disabled = true
			removed += 1
	_update_ui()

func _end_round(kind: String, text: String) -> void:
	round_active = false
	for b in answer_buttons:
		b.disabled = true
		var opt := String(b.get_meta("opt"))
		if opt == correct_answer:
			b.add_theme_stylebox_override("disabled", _panel_box(C_GOOD.darkened(0.7), C_GOOD, 10, false))
			b.add_theme_color_override("font_disabled_color", C_TEXT)
		elif opt == last_pick:
			b.add_theme_stylebox_override("disabled", _panel_box(C_BAD.darkened(0.7), C_BAD, 10, false))
			b.add_theme_color_override("font_disabled_color", C_TEXT)

	if kind == "correct":
		player_score += 1
		message.add_theme_color_override("font_color", C_GOOD)
		_say(quips_correct.pick_random())
		if sigil:
			sigil.set_mood("beaten")
	else:
		message.add_theme_color_override("font_color", C_BAD)
		if boss_correct:
			boss_score += 1  # you only lose a point if the Guardian actually knew the answer
			_shake()
			if sigil:
				sigil.set_mood("smug")
		match kind:
			"boss":
				_say(quips_boss.pick_random())
			"timeout":
				_say(quips_timeout.pick_random())
			_:
				_say(quips_wrong.pick_random())
	message.text = text
	_update_ui()

	await get_tree().create_timer(1.9).timeout
	if player_score >= points_to_win:
		_win()
	elif boss_score >= points_to_win:
		_lose()
	else:
		_next_round()

func _win() -> void:
	message.add_theme_color_override("font_color", C_GOOD)
	message.text = "DUEL WON!"
	_say("...You may pass, traveler.")
	if sigil:
		sigil.set_mood("beaten")
	GameState.solved[duel_id] = true
	await get_tree().create_timer(2.4).timeout
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file(return_scene)

func _lose() -> void:
	message.add_theme_color_override("font_color", C_BAD)
	message.text = "THE GUARDIAN WINS"
	_say("I win. Again.")
	if sigil:
		sigil.set_mood("smug")
	await get_tree().create_timer(2.4).timeout
	_start_match()

func _update_ui() -> void:
	player_pips.set_filled(player_score)
	boss_pips.set_filled(boss_score)
	round_label.text = "ROUND %d" % round_num
	hint_button.text = "HINT  x%d" % hints_left
	hint_button.disabled = hints_left <= 0 or not round_active

func _say(t: String) -> void:
	speech.text = t
	speech.visible_ratio = 0.0
	if speech_tween:
		speech_tween.kill()
	speech_tween = create_tween()
	speech_tween.tween_property(speech, "visible_ratio", 1.0, maxf(0.3, 0.035 * float(t.length())))

func _shake(strength := 8.0) -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(margin, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.04)
	tw.tween_property(margin, "position", Vector2.ZERO, 0.05)
