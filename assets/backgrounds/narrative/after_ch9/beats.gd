extends RefCounted

var defaults := {
	"pre_delay": 0.0,
	"fade_in": 0.5,
	"hold": 4.0,
	"fade_out": 0.5,

	"text_delay": 0.6,
	"text_fade_in": 0.35,
	"text_hold": 3.0,
	"text_fade_out": 0.35
}

var beats := [
	{"frame": 1, "text": ""},

	{"frame": 2, "text":
		" [b]Kaira:[/b]\n" +
		" \"Well now... what have we here?\""
	},
	{"frame": 3, "text":
		" \"Angel. Your name.\""
	},
	{
		"frame": 4,
		"hold": 5.0,
		"text_hold": 4.0,
		"text":
		" [b]Nyra:[/b]\n" +
		" \"...Nyra.\"\n" +
		" [b]Kaira:[/b]\n" +
		" \"And you're dying... in my courtyard. How fortunate.\""
	},
	{
		"frame": 5,
		"hold": 7.0,
		"text_hold": 6.0,
		"text":
		" [b]Kaira:[/b]\n" +
		" \"Tell me, Sir Knight... if I said I could save her... what would you give me?\"\n" +
		" [b]Tigris:[/b]\n" +
		" \"I don't bargain with souls.\"\n" +
		" [b]Kaira:[/b]\n" +
		" \"Mm. Principled. How rare.\""
	},
	{"frame": 6, "text":
		" [b]Nyra:[/b]\n" +
		" \"Tigris... save me...\"\n" +
		" [b]Tigris:[/b]\n" +
		" \"Nyra...\""
	},
	{"frame": 7, "text":
		" [b]Kaira:[/b]\n" +
		" \"So shall it be.\""
	},
	{
		"frame": 8,
		"hold": 5.0,
		"text_hold": 4.0,
		"text":
		" \"Cheer up, Sir Knight. She won't be going anywhere.\"\n" +
		" \"Consider it payment. You killed my dear Kellon.\""
	},
	{"frame": 9, "text":
		" \"And tonight, Nocthraelle welcomes new blood.\""
	},

	{
		"frame": 10,
		"hold": 6.0,
		"text_hold": 5.0,
		"text":
		" \"You'll thank me later.\"\n" +
		" \"Hush now. Heroes need monsters.\""
	},
]
