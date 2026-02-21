extends RefCounted

# Default timing for beats in this sequence (seconds)
var defaults := {
	"pre_delay": 0.0,   # frame is loaded but invisible (alpha 0)
	"fade_in": 0.5,     # bg alpha 0 -> 1
	"hold": 4.0,        # bg stays at alpha 1
	"fade_out": 0.5,    # bg alpha 1 -> 0

	# Text timing (relative to the start of the beat)
	"text_delay": 0.6,
	"text_fade_in": 0.35,
	"text_hold": 3.0,
	"text_fade_out": 0.35
}

# Author your beats here.
# You can reference a frame number (1 => after_ch2_0001.png) OR a filename via "file".
var beats := [
	{
		"frame": 1,
		"text": " There were many who endured the war.\n\n Most endured it loudly.\n\n\n Sir Tigris Factorem did not."
	},
	{
		"frame": 2,
		"text": " He did not curse the river when it ran red.\n\n He did not ask why the bridge had to be held.\n\n He simply placed himself where the breaking would come."
	},
	{
		"frame": 3,
		"text": " I was not sent to him.\n No voice commanded me.\n\n No decree named him worthy.\n\n\n I chose him."
	},
	{
		"frame": 4,
		"hold": 7.0,
		"text_hold": 5.0,
		"text": " I believed this man held the truest heart of mortals—\n\n That rarest thing: resolve without cruelty.\n\n An exemplar for the rest,\n  Not because he would win…\n\n   But because he would not break."
	},
	{
		"frame": 4,
		"hold": 9.0,
		"text_hold": 7.0,
		"text": " I was not to interfere.\n\n But I heard his prayer like a hand reaching through dark water.\n\n Was I to leave it unanswered—\n And call myself pure?\n\n Who gets to choose?"
	}
]
