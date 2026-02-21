extends Node
class_name Backgrounds

enum BattleBG {
	CHAPTER_0,
	CHAPTER_1,
	CHAPTER_2,
	CHAPTER_3,
	CHAPTER_4,
	CHAPTER_5,
	CHAPTER_6,
	CHAPTER_7,
	CHAPTER_8
}
const WAR_TABLE_BG_PATH := "res://assets/backgrounds/menus/war_table.png"

const BATTLE_PATHS := {
	BattleBG.CHAPTER_0: "res://assets/backgrounds/battle/background_00.png",
	BattleBG.CHAPTER_1: "res://assets/backgrounds/battle/background_01.png",
	BattleBG.CHAPTER_2: "res://assets/backgrounds/battle/background_02.png",
	BattleBG.CHAPTER_3: "res://assets/backgrounds/battle/background_03.png",
	BattleBG.CHAPTER_4: "res://assets/backgrounds/battle/background_04.png",
	BattleBG.CHAPTER_5: "res://assets/backgrounds/battle/background_05.png",
	BattleBG.CHAPTER_6: "res://assets/backgrounds/battle/background_06.png",
	BattleBG.CHAPTER_7: "res://assets/backgrounds/battle/background_07.png",
	BattleBG.CHAPTER_8: "res://assets/backgrounds/battle/background_08.png"
}

static func get_battle_bg(chapter_index: int) -> Texture2D:
	var key: int = clampi(chapter_index, 0, 8)
	var path: String = BATTLE_PATHS.get(key)
	return load(path) as Texture2D if path != "" else null

static func get_war_table_bg() -> Texture2D:
	return load(WAR_TABLE_BG_PATH) as Texture2D
