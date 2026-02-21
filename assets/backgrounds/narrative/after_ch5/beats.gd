extends RefCounted

var defaults := {
	# BG timing
	"pre_delay": 0.0,
	"fade_in": 0.5,
	"hold": 6.0,
	"fade_out": 0.5,

	# Text timing
	"text_delay": 0.6,
	"text_fade_in": 0.35,
	"text_hold": 5.0,
	"text_fade_out": 0.35,
}

var beats := [
	{
		"frame": 1,
		"text": " [b]Nyra:[/b]\n \"That the night held such surprises for us should not have been unexpected…\"\n \"And yet—\""
	},
	{
		"frame": 2,
		"hold": 5.0,
		"text_hold": 4.0,
		"text": " \"You did not fail me, Tigris.\""
	},
	{
		"frame": 3,
		"text": " [b]Tigris:[/b]\n \"Well. We’ve come this far-\"\n \"Am I really going to drop the ball to some scrawny vamp?\"\n\n \"-My ego wouldn’t survive.\""
	},
	{
		"frame": 4,
		"hold": 5.0,
		"text_hold": 4.0,
		"text": " [b]Nyra:[/b]\n\n \"Your ego…?\""
	},
	{
		"frame": 5,
		"text": " \"...Really, Nyra?\"\n\n \"I wouldn’t have gotten this far without you.\""
	},
	{
		"frame": 6,
		"hold": 5.0,
		"text_hold": 4.0,
		"text": " \"Sure you would.\"\n \"I… barely did anything.\""
	},
	{
		"frame": 7,
		"hold": 7.5,
		"text_hold": 6.5,
		"text": " [b]Nyra:[/b]\n \"Tigris…\"\n\n [b]Tigris:[/b]\n “You don’t have to say it.”\n “I can feel something burning in your mind.”"
	},
	{
		"frame": 8,
		# Let the landing breathe a little
		"hold": 6.75,
		"text_hold": 5.5,
		"text": " [b]Tigris:[/b]\n\n “We still have a ways to go-”\n\n “Watch my back, would you?”"
	}
]
