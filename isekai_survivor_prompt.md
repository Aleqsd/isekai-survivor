# ISEKAI SURVIVOR — Godot 4 Project Specification

## 🎮 Summary
Create a 2D top-down Vampire Survivors-like game called **Isekai Survivor** using Godot 4 and GDScript.

The game loop:
- Player controls a character who automatically attacks and targets enemies.
- Enemies spawn continuously and become stronger as time passes.
- Player gains XP (as collectible gems) and levels up to pick one of 3 random stat upgrades.
- Bosses appear at regular intervals, drop rare equipment that persists between runs.
- Each equipment item has a rarity (white/green/blue/purple/orange) that affects its power and sometimes adds effects.
- Game session duration: 1–15 minutes depending on progression.

---

## ⚙️ Technical setup
- Engine: Godot 4.x
- Language: GDScript
- Top-down 2D
- One map (forest style)
- Menu screen to select character
- Fallback shapes (circle/square) for visuals if no sprite assets are found
- Assets folder path: `res://assets/`
- Persist meta-progression (equipments) in JSON file at `user://save_data.json`

---

## 🧍 Characters
Three playable characters:
1. **Archer** – shoots arrows (projectiles)
2. **Mage** – casts magic bolts (slower, area effect)
3. **Warrior** – melee slash in short range

Each has:
- unique base attack pattern and attack cooldown
- base stats: HP, ATK, SPD, LootRadius

Create a `Character.gd` base class and three subclasses for these heroes.

Add a **Character Selection Menu Scene** with buttons to choose which hero to spawn in the main scene.

---

## 👾 Enemies
- 4 normal enemy types (different sprites/colors and behaviors)
- 1 boss enemy every X minutes (start at 2min, then 5min, 10min)
- Progressive spawn rate: frequency and difficulty increase gradually
- Slight randomness in spawn timing and position

Implement an **EnemySpawner** node with parameters:
- spawn_rate
- elapsed_time
- spawn_randomness

---

## 💎 XP & Level-Up System
- Enemies drop XP gems with random XP value.
- Player auto-collects XP when within LootRadius.
- Level-up opens a popup with 3 random stat-up choices (out of a pool of 20).

### Example stat-ups (20 total):
- +ATK %
- +HP %
- +SPD %
- +LootRadius %
- +XP Gain %
- +Attack Speed %
- +Critical Chance
- +Critical Damage
- +Projectile Size
- +Projectile Speed
- +Cooldown Reduction
- +AOE Radius
- +Life Regen
- +Damage Reduction
- +Pickup Magnet Range
- +Move Speed %
- +Gold Drop Chance
- +Bonus XP on Boss Kill
- +Chance to duplicate projectiles
- +Flat damage bonus

When the player levels up, show a popup UI with 3 random upgrades and let them pick one.

---

## ⚔️ Combat
- Auto-target nearest enemy within range.
- Auto-attack at intervals depending on attack speed.
- Enemies move toward player.
- Collision deals damage to player.
- Player dies when HP ≤ 0 → “Game Over” screen.

---

## 🧩 Equipment System
- Bosses drop 1 equipment item (JSON object with `name`, `rarity`, `stats`, `effects`).
- Rarity colors: white, green, blue, purple, orange.
- Higher rarity = more stats / chance for special effects.
- Persist equipment in `user://save_data.json` and load it when the game starts.
- Allow equipping one item before a new run (simple menu for that).

---

## 🗺️ Level / Scene Structure
Scenes to create:
1. **MainMenu.tscn**
2. **CharacterSelect.tscn**
3. **GameScene.tscn**
4. **GameOver.tscn**

---

## 💾 Save System (JSON)
Example:
```json
{
  "owned_items": [
    {"name": "Hunter Bow", "rarity": "blue", "stats": {"atk": 10}, "effects": ["+5% crit chance"]},
    {"name": "Mage Robe", "rarity": "purple", "stats": {"regen": 2}, "effects": ["-5% cooldown"]}
  ],
  "equipped_item": "Hunter Bow"
}
```

---

## 🎨 Graphics
Use placeholder shapes if sprites are missing:
- Player: circle (blue)
- Enemies: red squares
- XP gems: small green circles
- Boss: large purple square

---

## 🎵 Audio (optional placeholder)
- Background music node
- Sound effects for hits and level-ups

---

## 🧠 Implementation Notes
- Use signals for events.
- Separate logic cleanly into scripts.
- Prioritize clean structure.

---

## ✅ Deliverables
- Fully working Godot 4 project
- Playable prototype

---

# FILE STRUCTURE

res://
├── main.tscn
├── MainMenu.tscn
├── CharacterSelect.tscn
├── GameScene.tscn
├── GameOver.tscn
│
├── scripts/
│   ├── GameManager.gd
│   ├── Player.gd
│   ├── Archer.gd
│   ├── Mage.gd
│   ├── Warrior.gd
│   ├── Enemy.gd
│   ├── EnemySpawner.gd
│   ├── Boss.gd
│   ├── XPGem.gd
│   ├── LevelUpUI.gd
│   ├── EquipmentManager.gd
│   ├── UIManager.gd
│   └── Utils.gd
│
├── ui/
│   ├── HUD.tscn
│   ├── LevelUpPopup.tscn
│   ├── EquipmentMenu.tscn
│   └── GameOverUI.tscn
│
├── data/
│   ├── save_data.json
│   └── stat_upgrades.json
│
├── assets/
│   ├── player/
│   ├── enemies/
│   ├── ui/
│   ├── sounds/
│   └── music/
│
└── project.godot

---

## 🧩 Core Script Responsibilities

**GameManager.gd** – game flow, XP system  
**Player.gd** – movement, attack, XP gain  
**EnemySpawner.gd** – spawn logic  
**Enemy.gd** – AI, XP drop  
**LevelUpUI.gd** – upgrade choice popup  
**EquipmentManager.gd** – JSON persistence  
**Boss.gd** – special enemy + loot drop

---

# ✨ STYLE & UX INSTRUCTIONS (PART 3)

Make all code:
- Fully commented in **English only**
- Structured cleanly with clear indentation
- Include visual log output in the Godot console with emoji and color, e.g.:
  ```gdscript
  print("[color=green]✅ Enemy spawned at position:[/color]", position)
  print("[color=yellow]⚔️ Level Up! Choose your upgrade![/color]")
  print("[color=purple]💎 Equipment Saved![/color]")
  ```
- Prefix important debug sections with emojis (🔥, ⚙️, 💥, 💾, 🎯)
- For UI, include clear labels and feedback (XP bar updates, level up popup transitions)

UI design:
- Dark fantasy tone
- Fonts readable (fallback to default if missing)
- Rare items colored text: white/green/blue/purple/orange

All scenes and scripts must run out of the box in a fresh Godot 4 install.
