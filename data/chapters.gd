extends Node

# Central campaign definition (Forge I.x)
# War Table reads this. Battles pull enemy config + XP from this.

static func all() -> Array[Dictionary]:
	return [
		{
			"id": 0,
			"title": "I — Border Skirmish",
			"enemy_name": "Cogan Footman",
			"enemy_hp": 45,
			"xp": 20,
		},
		{
			"id": 1,
			"title": "II — Bridge at Blackmere",
			"enemy_name": "Shielded Guard",
			"enemy_hp": 55,
			"xp": 28,
		},
		{
			"id": 2,
			"title": "III — Siege Scouts",
			"enemy_name": "Scout Captain",
			"enemy_hp": 60,
			"xp": 32,
		},
		{
			"id": 3,
			"title": "IV — The Ash Fields",
			"enemy_name": "War-Scarred Veteran",
			"enemy_hp": 70,
			"xp": 36,
		},
		{
			"id": 4,
			"title": "V — Broken Banner",
			"enemy_name": "Lesser Vampire Scout",
			"enemy_hp": 85,
			"xp": 45,
		},
		{
			"id": 5,
			"title": "VI — The Long Night Watch",
			"enemy_name": "Knight-Commander",
			"enemy_hp": 95,
			"xp": 55,
		},
		{
			"id": 6,
			"title": "VII — Scars of Victory",
			"enemy_name": "Altered Human",
			"enemy_hp": 105,
			"xp": 65,
		},
		{
			"id": 7,
			"title": "VIII — Approach to Nocthraelle",
			"enemy_name": "Dark Throne Acolytes",
			"enemy_hp": 115,
			"xp": 75,
		},
		{
			"id": 8,
			"title": "IX — At the Gates of Nocthraelle",
			"enemy_name": "Kellon, Thronebound Sentinel",
			"enemy_hp": 140,
			"xp": 100,
		},
	]

static func get_chapter(i: int) -> Dictionary:
	var chapters := all()
	if i < 0 or i >= chapters.size():
		return chapters[0]
	return chapters[i]
