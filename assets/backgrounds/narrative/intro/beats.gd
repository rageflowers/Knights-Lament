extends RefCounted

# Default timing for beats in this sequence (seconds)
var defaults := {
	"pre_delay": 0.0,
	"fade_in": 0.6,
	"hold": 4.5,
	"fade_out": 0.6,

	# No text for intro
	"text_delay": 0.0,
	"text_fade_in": 0.0,
	"text_hold": 0.0,
	"text_fade_out": 0.0,
}

# Pure slideshow: no "text" keys at all => TextPanel stays hidden
var beats := [
	{"frame": 1, "hold": 3.5},
	{"frame": 2},
	{"frame": 3, "hold": 5.0},
	{"frame": 4, "hold": 6.0}, # let the last one breathe a bit longer
]
