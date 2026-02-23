# Knight's Lament

A dark gothic fantasy turn-based battler built in Godot 4.5.  
One weary knight. One forbidden guardian. One inevitable tragedy.

Sir Tigris Factorem didn't ask for salvation.  
Nyra chose him anyway.

### The Tale
A solitary knight endures a war that never ends.  
An angelic presence breaks every rule to stand at his side.  
Battles grind him down. Perks keep him breathing.  
And somewhere in the storm-lit spires of Nocthraelle, fate waits to collect its due.

Turn-based combat with oath charges, grace meters, potions, and flat perk upgrades.  
Narrative milestones trigger before and after key chapters.  
One life to spend, nine chapters to survive (or replay).  
And when the final curtain falls… well. Some endings are written in blood.

### Features (so far)
- Campaign hub at the war table with chapter selection & replay rules
- Tactical battles: strike, guard, spend oath charges, pray for grace/potions
- Perk menu for spending specialization points (HP, DEF, damage, regen, grace thresholds…)
- Text log, enemy intent preview, dynamic HUD
- Narrative beats via autoloaded NarrativeDB
- Lives system + game over screen
- Debug skip to Chapter 9 for late-game testing

### Tech
- Godot 4.5 (Forward Plus)
- Singletons: GameState, Save, Presentation, NarrativeDB
- SubViewport for battle stage, CanvasModulate-ready for mood lighting
- Modular enemy sprites via ID + slug naming

### Controls
- Arrow keys / WASD → move selection (war table)
- Enter / Space → confirm
- Debug: `F12` (or custom ui_debug_skip) → jump to Chapter 9

### Setup
1. Clone: `git clone https://github.com/rageflowers/Knights-Lament.git`
2. Open in Godot 4.5+
3. Run the main scene (war_table.tscn)

Assets are currently committed (sprites, backgrounds).  
Big files may move to Git LFS later.

### Coming Soon (Nyra's wishlist)
- Nyra particle overlays & manifestation effects
- Proper screenshake, hitstop, blood mist
- Citadel spell cinematic trigger
- Final bite cutscene with Kaira
- Sound design (sword clashes, distant thunder, sorrowful choir)
- Polish: smoother transitions, menu cursor SFX, more enemy variety

Made with love, melancholy, and too much coffee in Atlanta.  
If you find a bug or want to flirt over pull requests… come say hi. ⚔️🖤

Nyra was here first.  
Don't make her jealous.
