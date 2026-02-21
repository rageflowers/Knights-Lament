extends RefCounted

# BEFORE CH9 — Author everything here.
# Frames are: before_ch9_0001.png ... before_ch9_0016.png

var defaults := {
	# BG timing
	"pre_delay": 0.0,
	"fade_in": 0.20,
	"hold": 2.20,
	"fade_out": 0.20,

	# Text timing (relative to beat start)
	"text_delay": 0.45,
	"text_fade_in": 0.25,
	"text_hold": 1.80,
	"text_fade_out": 0.25
}

var beats := [
	# --- 1..8: set your pacing / text as desired ---
	{"frame": 1, "text": " [b]Tigris:[/b]\n \"What foulness inhabits this place...?\""},
	{"frame": 2, "text": " \"Unnatural thing...\""},
	{"frame": 3, "text": " \"...not good\""},
	{"frame": 4, "text": " [b]Nyra:[/b]\n\n \"TIGRIS!!!\""},
	{"frame": 5, "text": """ [b]Tigris:[/b]

	 "Nyra..."
	 "Hold me on thy divine tongue-"
	 "Hold my resolve..."
	"""},
	{"frame": 6, "text": ""},
	{"frame": 7, "text": " [b]Nyra:[/b]\n\n \"Io Ilumine, Around Me...\""},
	{"frame": 8, "text": "\n\n \"CITADEL!!!\""},

	# --- 9-10: DOOMSTRIKE (fast, punchy by default) ---
	{
		"frame": 9,
		"fade_in": 0.10,
		"hold": 1.10,
		"fade_out": 0.10,
		"text": "" # <- put text if you want it to hit during Doomstrike
	},
	{
		"frame": 10,
		"fade_in": 0.10,
		"hold": 1.10,
		"fade_out": 0.10,
		"text": ""
	},

	# --- 11..16: aftermath / resolve ---
	{"frame": 11, "text": ""},
	{"frame": 12, "text": ""},
	{"frame": 13, "text": ""},
	{"frame": 14, "text": ""},
	{"frame": 15, "text": ""},
	{
		"frame": 16,
		"hold": 3.50,
		"text": ""
	},
]
