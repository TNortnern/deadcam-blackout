extends CharacterBody3D
class_name PlayerBodycam

const WEAPONS := [
	{
		"name": "G17 TACTICAL",
		"key": "1",
		"glb": "res://assets/models/weapon_pistol.glb",
		"audio": "res://assets/audio/gun_pistol.wav",
		"audio_b": "res://assets/audio/gun_pistol_b.wav",
		"mag_size": 15,
		"reserve_max": 90,
		"damage": 38.0,
		"fire_rate": 0.18,
		"auto": false,
		"pellets": 1,
		"spread": 0.012,
		"recoil_pitch": 0.055,
		"recoil_kick": 0.045,
		"flash_scale": 0.72,
		"hip_pos": Vector3(0.077, -0.180, -0.221),
		"hip_rot": Vector3(-0.13, 0.06, -0.062),
		"ads_pos": Vector3(0.0, -0.095, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.05, -0.28),
		"ejection": Vector3(0.025, 0.055, -0.08),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.072, -0.12),
	},
	{
		"name": "M16A2 REFLEX",
		"key": "2",
		"glb": "res://assets/models/weapon_rifle.glb",
		"audio": "res://assets/audio/gun_rifle.wav",
		"audio_b": "res://assets/audio/gun_rifle_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 34.0,
		"fire_rate": 0.095,
		"auto": true,
		"pellets": 1,
		"spread": 0.010,
		"recoil_pitch": 0.038,
		"recoil_kick": 0.032,
		"flash_scale": 1.0,
		"hip_pos": Vector3(0.116, -0.229, -0.249),
		"hip_rot": Vector3(0.02, 0.11, -0.05),
		"ads_pos": Vector3(0.0, -0.091, -0.273),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.03, -0.62),
		"ejection": Vector3(0.055, 0.045, -0.06),
		"has_holo": true,
		"holo_pos": Vector3(0.0, 0.091, -0.096),
	},
	{
		"name": "M870 BREACHER",
		"key": "3",
		"glb": "res://assets/models/weapon_shotgun.glb",
		"audio": "res://assets/audio/gun_shotgun.wav",
		"audio_b": "res://assets/audio/gun_shotgun_b.wav",
		"mag_size": 8,
		"reserve_max": 48,
		"damage": 24.0,
		"fire_rate": 0.72,
		"auto": false,
		"pellets": 7,
		"spread": 0.055,
		"recoil_pitch": 0.11,
		"recoil_kick": 0.085,
		"flash_scale": 1.35,
		"hip_pos": Vector3(0.112, -0.205, -0.245),
		"hip_rot": Vector3(0.02, 0.10, -0.05),
		"ads_pos": Vector3(0.0, -0.036, -0.270),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.015, -0.695),
		"ejection": Vector3(0.024, 0.014, -0.150),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.048, -0.12),
	},
	{
		"name": "COMBAT KNIFE",
		"key": "V",
		"glb": "",
		"audio": "res://assets/audio/melee_swing.wav",
		"is_melee": true,
		"mag_size": 1,
		"reserve_max": 0,
		"damage": 55.0,
		"fire_rate": 0.44,
		"auto": false,
		"pellets": 1,
		"spread": 0.0,
		"recoil_pitch": 0.02,
		"recoil_kick": 0.02,
		"flash_scale": 0.0,
		"hip_pos": Vector3(0.24, -0.155, -0.29),
		"hip_rot": Vector3(-0.04, -0.14, 0.10),
		"ads_pos": Vector3(0.20, -0.145, -0.27),
		"ads_rot": Vector3(-0.02, -0.10, 0.12),
		"muzzle": Vector3(0.0, 0.0, -0.35),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "COMPOUND BOW",
		"key": "4",
		"glb": "res://assets/models/weapon_bow.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/bow_release.wav",
		"is_bow": true,
		"is_special": true,
		"mag_size": 1,
		"reserve_max": 24,
		"damage": 165.0,
		"fire_rate": 0.38,
		"auto": false,
		"pellets": 1,
		"spread": 0.002,
		"recoil_pitch": 0.024,
		"recoil_kick": 0.020,
		"flash_scale": 0.0,
		"ads_fov": 72.0,
		"hip_pos": Vector3(0.30, -0.140, -0.50),
		"hip_rot": Vector3(0.02, 0.05, 0.48),
		"ads_pos": Vector3(0.044, -0.068, -0.44),
		"ads_rot": Vector3(0.0, 0.0, 0.20),
		"muzzle": Vector3(0.0, 0.03, -0.45),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "MP5A3 9MM",
		"key": "6",
		"glb": "res://assets/models/weapon_mp5.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_pistol.wav",
		"audio_b": "res://assets/audio/gun_pistol_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 24.0,
		"fire_rate": 0.068,
		"auto": true,
		"pellets": 1,
		"spread": 0.014,
		"recoil_pitch": 0.022,
		"recoil_kick": 0.020,
		"flash_scale": 0.78,
		"hip_pos": Vector3(0.125, -0.175, -0.30),
		"hip_rot": Vector3(0.02, 0.09, -0.05),
		"ads_pos": Vector3(0.0, -0.020, -0.22),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.016, -0.40),
		"ejection": Vector3(0.036, 0.032, -0.09),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.036, -0.10),
	},
	{
		"name": ".44 MAGNUM",
		"key": "7",
		"glb": "res://assets/models/weapon_magnum.glb",
		"arm_src": 0,
		"audio": "res://assets/audio/gun_magnum.wav",
		"audio_b": "res://assets/audio/gun_magnum_b.wav",
		"mag_size": 6,
		"reserve_max": 42,
		"damage": 115.0,
		"fire_rate": 0.42,
		"auto": false,
		"pellets": 1,
		"spread": 0.009,
		"recoil_pitch": 0.135,
		"recoil_kick": 0.075,
		"flash_scale": 1.25,
		"hip_pos": Vector3(0.105, -0.160, -0.28),
		"hip_rot": Vector3(-0.04, 0.06, -0.05),
		"ads_pos": Vector3(0.0, -0.072, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.042, -0.38),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.075, -0.14),
	},
	{
		"name": "SPRINGFIELD M1903",
		"key": "4",
		"glb": "res://assets/models/weapon_springfield.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_hunting.wav",
		"audio_b": "res://assets/audio/gun_hunting_b.wav",
		"mag_size": 5,
		"reserve_max": 35,
		"damage": 175.0,
		"fire_rate": 1.05,
		"auto": false,
		"pellets": 1,
		"spread": 0.002,
		"recoil_pitch": 0.120,
		"recoil_kick": 0.080,
		"flash_scale": 1.30,
		"ads_fov": 26.0,
		"hip_pos": Vector3(0.132, -0.185, -0.32),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.088, -0.032),
		"ads_rot": Vector3(0.0, 0.0, 0.042),
		"muzzle": Vector3(0.0, 0.030, -0.82),
		"ejection": Vector3(0.040, 0.036, -0.10),
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "AK-74M",
		"key": "8",
		"glb": "res://assets/models/weapon_ak74.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_ak74.wav",
		"audio_b": "res://assets/audio/gun_ak74_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 38.0,
		"fire_rate": 0.102,
		"auto": true,
		"pellets": 1,
		"spread": 0.013,
		"recoil_pitch": 0.044,
		"recoil_kick": 0.036,
		"flash_scale": 1.08,
		"hip_pos": Vector3(0.122, -0.188, -0.29),
		"hip_rot": Vector3(0.02, 0.10, -0.05),
		"ads_pos": Vector3(0.0, -0.068, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.024, -0.74),
		"ejection": Vector3(0.042, 0.034, -0.14),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.082, -0.12),
	},
	{
		"name": "BENELLI M4",
		"key": "9",
		"glb": "res://assets/models/weapon_benelli.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_benelli.wav",
		"audio_b": "res://assets/audio/gun_benelli_b.wav",
		"mag_size": 7,
		"reserve_max": 42,
		"damage": 22.0,
		"fire_rate": 0.28,
		"auto": false,
		"pellets": 7,
		"spread": 0.052,
		"recoil_pitch": 0.095,
		"recoil_kick": 0.072,
		"flash_scale": 1.25,
		"hip_pos": Vector3(0.120, -0.185, -0.29),
		"hip_rot": Vector3(0.02, 0.09, -0.05),
		"ads_pos": Vector3(0.0, -0.064, -0.25),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.032, -0.72),
		"ejection": Vector3(0.040, 0.028, -0.14),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.076, -0.12),
	},
	{
		"name": "M249 SAW",
		"key": "0",
		"glb": "res://assets/models/weapon_m249.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_m249.wav",
		"audio_b": "res://assets/audio/gun_m249_b.wav",
		"mag_size": 100,
		"reserve_max": 300,
		"damage": 30.0,
		"fire_rate": 0.082,
		"auto": true,
		"pellets": 1,
		"spread": 0.018,
		"recoil_pitch": 0.036,
		"recoil_kick": 0.030,
		"flash_scale": 1.15,
		"hip_pos": Vector3(0.135, -0.205, -0.32),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.105, -0.25),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.034, -0.78),
		"ejection": Vector3(0.048, 0.026, -0.16),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.104, -0.09),
	},
	{
		"name": "SAWED-OFF DB 12GA",
		"key": "1",
		"glb": "res://assets/models/weapon_sawed_off.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_shotgun.wav",
		"audio_b": "res://assets/audio/gun_shotgun_b.wav",
		"mag_size": 2,
		"reserve_max": 32,
		"damage": 22.0,
		"fire_rate": 0.28,
		"auto": false,
		"pellets": 12,
		"spread": 0.095,
		"recoil_pitch": 0.165,
		"recoil_kick": 0.105,
		"flash_scale": 1.65,
		"hip_pos": Vector3(0.115, -0.165, -0.27),
		"hip_rot": Vector3(0.01, 0.07, -0.04),
		"ads_pos": Vector3(0.0, -0.062, -0.22),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.022, -0.40),
		"ejection": Vector3(0.0, 0.020, -0.06),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.062, -0.10),
	},
	{
		"name": "FAMAS F1 5.56",
		"key": "2",
		"glb": "res://assets/models/weapon_famas.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_rifle.wav",
		"audio_b": "res://assets/audio/gun_rifle_b.wav",
		"mag_size": 30,
		"reserve_max": 180,
		"damage": 34.0,
		"fire_rate": 0.24,
		"burst_count": 3,
		"burst_interval": 0.058,
		"auto": false,
		"pellets": 1,
		"spread": 0.008,
		"recoil_pitch": 0.024,
		"recoil_kick": 0.024,
		"flash_scale": 0.92,
		"hip_pos": Vector3(0.125, -0.175, -0.29),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.106, -0.22),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.018, -0.48),
		"ejection": Vector3(0.036, 0.025, -0.14),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.091, -0.12),
	},
	{
		"name": "M1 GARAND .30-06",
		"key": "3",
		"glb": "res://assets/models/weapon_garand.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_hunting.wav",
		"audio_b": "res://assets/audio/gun_hunting_b.wav",
		"mag_size": 8,
		"reserve_max": 64,
		"damage": 88.0,
		"fire_rate": 0.22,
		"auto": false,
		"pellets": 1,
		"spread": 0.006,
		"recoil_pitch": 0.068,
		"recoil_kick": 0.056,
		"flash_scale": 1.15,
		"hip_pos": Vector3(0.120, -0.180, -0.29),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.056, -0.22),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.018, -0.72),
		"ejection": Vector3(0.032, 0.032, -0.08),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.072, -0.12),
	},
	{
		"name": "KAR98K MAUSER",
		"key": "3",
		"glb": "res://assets/models/weapon_kar98k.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_hunting.wav",
		"audio_b": "res://assets/audio/gun_hunting_b.wav",
		"mag_size": 5,
		"reserve_max": 40,
		"damage": 195.0,
		"fire_rate": 0.96,
		"auto": false,
		"pellets": 1,
		"spread": 0.003,
		"recoil_pitch": 0.115,
		"recoil_kick": 0.082,
		"flash_scale": 1.25,
		"ads_fov": 52.0,
		"hip_pos": Vector3(0.122, -0.182, -0.29),
		"hip_rot": Vector3(0.02, 0.08, -0.04),
		"ads_pos": Vector3(0.0, -0.056, -0.22),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.016, -0.74),
		"ejection": Vector3(0.036, 0.026, -0.08),
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.072, -0.12),
	},
	{
		"name": "HEAVY CROSSBOW",
		"key": "3",
		"glb": "res://assets/models/weapon_crossbow.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/bow_release.wav",
		"is_crossbow": true,
		"mag_size": 1,
		"reserve_max": 24,
		"damage": 188.0,
		"fire_rate": 0.42,
		"auto": false,
		"pellets": 1,
		"spread": 0.002,
		"recoil_pitch": 0.032,
		"recoil_kick": 0.028,
		"flash_scale": 0.0,
		"ads_fov": 64.0,
		"hip_pos": Vector3(0.125, -0.185, -0.32),
		"hip_rot": Vector3(0.01, 0.06, -0.03),
		"ads_pos": Vector3(0.0, -0.072, -0.26),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.020, -0.52),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3(0.0, 0.019, -0.11),
	},
	{
		"name": "M2 FLAMETHROWER",
		"key": "4",
		"glb": "res://assets/models/weapon_flamethrower.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/flamethrower_jet.wav",
		"is_special": true,
		"is_flamethrower": true,
		"no_ammo_refill": true,
		"mag_size": 90,
		"reserve_max": 0,
		"damage": 16.0,
		"fire_rate": 0.075,
		"auto": true,
		"pellets": 1,
		"spread": 0.055,
		"recoil_pitch": 0.008,
		"recoil_kick": 0.010,
		"flash_scale": 0.65,
		"hip_pos": Vector3(0.140, -0.205, -0.30),
		"hip_rot": Vector3(0.01, 0.06, -0.03),
		"ads_pos": Vector3(0.060, -0.135, -0.26),
		"ads_rot": Vector3(0.0, 0.03, 0.0),
		"muzzle": Vector3(0.0, 0.028, -0.68),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	},
	{
		"name": "RPG-7 LAUNCHER",
		"key": "4",
		"glb": "res://assets/models/weapon_rpg7.glb",
		"arm_src": 1,
		"audio": "res://assets/audio/gun_shotgun.wav",
		"is_special": true,
		"is_rpg": true,
		"no_ammo_refill": true,
		"mag_size": 1,
		"reserve_max": 4,
		"damage": 420.0,
		"fire_rate": 0.85,
		"auto": false,
		"pellets": 1,
		"spread": 0.004,
		"recoil_pitch": 0.185,
		"recoil_kick": 0.140,
		"flash_scale": 1.85,
		"ads_fov": 68.0,
		"hip_pos": Vector3(0.145, -0.185, -0.14),
		"hip_rot": Vector3(0.01, 0.05, -0.02),
		"ads_pos": Vector3(0.026, -0.094, -0.14),
		"ads_rot": Vector3(0.0, 0.0, 0.0),
		"muzzle": Vector3(0.0, 0.040, -0.78),
		"ejection": Vector3.ZERO,
		"has_holo": false,
		"holo_pos": Vector3.ZERO,
	}
]

# Per-weapon melee identity. "class" drives impact audio and gore: blades and axes sever, blunt weapons break poise and
# knock down. "cleave" is how many bodies one swing can pass through, "weight" scales hit-stop and camera heft, "heavy" is the
# charged RMB move and "charge" the seconds of hold needed for full power.
const MELEE_CATALOG := {
	"knife": {"name": "COMBAT KNIFE", "class": "blade", "damage": 55.0, "reach": 2.15, "dur": 0.38, "poise": 35.0, "kb": 3.6,
		"cleave": 1, "weight": 0.6, "sever": 0.8, "heavy": "lunge", "heavy_mult": 2.1, "charge": 0.30, "backstab": 2.0,
		"trait": "FAST · 2x BACKSTAB · LUNGE STAB"},
	"fire_axe": {"name": "FIRE AXE", "class": "axe", "damage": 94.0, "reach": 2.48, "dur": 0.60, "poise": 72.0, "kb": 6.4,
		"cleave": 2, "weight": 1.3, "sever": 1.7, "heavy": "overhead", "heavy_mult": 1.9, "charge": 0.55, "knockdown": true,
		"trait": "SEVERS LIMBS · OVERHEAD CLEAVE"},
	"machete": {"name": "TACTICAL MACHETE", "class": "blade", "damage": 78.0, "reach": 2.34, "dur": 0.46, "poise": 48.0, "kb": 5.0,
		"cleave": 3, "weight": 0.85, "sever": 1.4, "heavy": "sweep", "heavy_mult": 1.5, "charge": 0.40,
		"trait": "CLEAVES 3 · WIDE SWEEP"},
	"bat": {"name": "BASEBALL BAT", "class": "blunt", "damage": 76.0, "reach": 2.42, "dur": 0.52, "poise": 78.0, "kb": 7.6,
		"cleave": 2, "weight": 1.05, "sever": 0.0, "heavy": "homerun", "heavy_mult": 1.6, "charge": 0.50, "knockdown": true,
		"trait": "STAGGERS · KNOCKDOWN SWING"},
	"bat_spiked": {"name": "SPIKED BASEBALL BAT", "class": "blunt", "damage": 108.0, "reach": 2.46, "dur": 0.54, "poise": 88.0, "kb": 8.2,
		"cleave": 2, "weight": 1.15, "sever": 0.6, "heavy": "homerun", "heavy_mult": 1.6, "charge": 0.50, "knockdown": true,
		"bleed_dps": 24.0, "bleed_dur": 4.5, "trait": "BLEED · KNOCKDOWN SWING"},
	"crowbar": {"name": "STEEL CROWBAR", "class": "bar", "damage": 84.0, "reach": 2.30, "dur": 0.46, "poise": 68.0, "kb": 6.0,
		"cleave": 2, "weight": 1.0, "sever": 0.4, "heavy": "overhead", "heavy_mult": 1.7, "charge": 0.45, "armor_pierce": 1.45,
		"armor_break": true, "trait": "ARMOR PIERCE · BREAKS PLATES"},
}

# Viewmodel swing poses as offsets from the weapon's hip pose: "w" is the wound-up pose, "t" the follow-through.
# "arc" tells the swept hit test which way the edge travels: yaw sweep (+1 = right-to-left), pitch sweep, or a thrust.
const MELEE_MOVES := {
	# The viewmodel is one rigid forearm entering from the bottom-right of frame. Swings therefore read through hand
	# travel across the view plus a modest roll (about -0.95..+0.66 rad); larger roll or yaw swings the elbow into shot.
	"slash_rl": {"wp": Vector3(0.05, 0.09, 0.06), "wr": Vector3(0.30, -0.28, -0.55), "tp": Vector3(-0.30, -0.14, -0.16), "tr": Vector3(-0.45, -0.15, 0.62), "arc": "yaw", "sign": 1.0, "span": 46.0},
	"slash_lr": {"wp": Vector3(-0.30, 0.03, 0.02), "wr": Vector3(0.12, 0.32, 1.05), "tp": Vector3(0.05, -0.07, -0.14), "tr": Vector3(-0.38, -0.32, -0.95), "arc": "yaw", "sign": -1.0, "span": 46.0},
	"stab": {"wp": Vector3(0.02, -0.02, 0.14), "wr": Vector3(-0.22, -0.05, -0.10), "tp": Vector3(-0.14, 0.03, -0.30), "tr": Vector3(0.05, -0.28, 0.42), "arc": "thrust", "sign": 1.0, "span": 10.0},
	"lunge": {"wp": Vector3(0.04, -0.02, 0.18), "wr": Vector3(-0.15, -0.10, -0.20), "tp": Vector3(-0.18, 0.03, -0.36), "tr": Vector3(0.05, -0.30, 0.50), "arc": "thrust", "sign": 1.0, "span": 12.0},
	"overhead": {"wp": Vector3(-0.02, 0.15, 0.10), "wr": Vector3(0.50, -0.10, -0.25), "tp": Vector3(-0.24, -0.16, -0.20), "tr": Vector3(-0.42, -0.10, 0.55), "arc": "pitch", "sign": 1.0, "span": 52.0},
	"sweep": {"wp": Vector3(0.10, 0.02, 0.06), "wr": Vector3(0.10, -0.25, -0.95), "tp": Vector3(-0.40, -0.12, -0.16), "tr": Vector3(-0.30, -0.15, 0.62), "arc": "yaw", "sign": 1.0, "span": 78.0},
	"homerun": {"wp": Vector3(0.10, 0.06, 0.08), "wr": Vector3(0.20, -0.30, -0.85), "tp": Vector3(-0.40, -0.10, -0.18), "tr": Vector3(-0.25, -0.18, 0.66), "arc": "yaw", "sign": 1.0, "span": 70.0},
	"shove": {"wp": Vector3(-0.04, 0.00, 0.10), "wr": Vector3(0.10, 0.20, 0.40), "tp": Vector3(-0.17, -0.04, -0.30), "tr": Vector3(-0.20, -0.15, 0.55), "arc": "thrust", "sign": 1.0, "span": 50.0},
	"bash_pistol": {"wp": Vector3(0.08, 0.06, 0.05), "wr": Vector3(0.24, -0.35, -0.40), "tp": Vector3(-0.18, -0.04, -0.16), "tr": Vector3(-0.48, 0.85, 0.78), "arc": "yaw", "sign": 1.0, "span": 30.0},
	"bash_rifle": {"wp": Vector3(-0.04, -0.03, 0.09), "wr": Vector3(-0.18, 0.45, 0.52), "tp": Vector3(0.03, 0.04, -0.22), "tr": Vector3(0.26, -0.55, 0.32), "arc": "thrust", "sign": 1.0, "span": 24.0},
}

var head: Node3D
var camera: Camera3D
var cam_attrs: CameraAttributesPractical
var weapon_clearance: Node3D
var weapon_pivot: Node3D
var weapon_rig_holder: Node3D
var holo_quad: MeshInstance3D
var optic_hood: Node3D
var _optic_rest_pos: Vector3 = Vector3(0.0, 0.072, -0.12)
var vm_rim: OmniLight3D
var flashlight: SpotLight3D
var flashlight_spill: SpotLight3D
var flashlight_bounce: OmniLight3D
var flashlight_cone: MeshInstance3D
var dust_motes: GPUParticles3D
var muzzle_light: OmniLight3D
var muzzle_vm_light: OmniLight3D
var muzzle_flash_rig: Node3D
var _flash_mats: Array[ShaderMaterial] = []
var muzzle_smoke: GPUParticles3D
var interact_ray: RayCast3D

var sfx_gun: AudioStreamPlayer
var _sfx_gun_pool: Array[AudioStreamPlayer] = []
var _sfx_gun_pool_idx: int = 0
var sfx_misc: AudioStreamPlayer
var sfx_reload: AudioStreamPlayer
var _sfx_reload_pool: Array[AudioStreamPlayer] = []
var _sfx_reload_pool_idx: int = 0
var sfx_step: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_hit_tick: AudioStreamPlayer
var sfx_casing: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer
var sfx_slash: AudioStreamPlayer
var sfx_bow_draw: AudioStreamPlayer

var health: float = 100.0
var max_health: float = 100.0
var dead: bool = false
var flashlight_on: bool = true
var is_ads: bool = false
var is_crouching: bool = false
var is_sprinting: bool = false
var is_reloading: bool = false

# Multi-stage reload sequencer state (authoritative physics clock + timestamp-crossing events!)
var reload_elapsed: float = 0.0
var _reload_prev_t: float = 0.0
var reload_dur: float = 1.85
var reload_was_empty: bool = false
var reload_flags: int = 0
var reload_shell_timer: float = 0.0
var reload_shell_phase: int = 0 # 0=enter, 1=loop, 2=exit
var reload_cancel_req: bool = false
var _shotgun_fire_on_cancel: bool = false
var _shotgun_exit_arm_p: Vector3 = Vector3.ZERO
var _shotgun_exit_arm_r: Vector3 = Vector3.ZERO
var _magnum_spent_count: int = 0
var _sniper_pending_eject: bool = false
var _fire_buffer_timer: float = 0.0
var _base_head_roll: float = 0.0
var _last_near_focus: float = -1.0
var reload_pos_off: Vector3 = Vector3.ZERO
var reload_rot_off: Vector3 = Vector3.ZERO
var _rl_layer_p: Vector3 = Vector3.ZERO
var _rl_layer_r: Vector3 = Vector3.ZERO

var fire_cd: float = 0.0
var muzzle_elapsed: float = 9.0
var muzzle_peak_e: float = 0.0
var muzzle_flash_timer: float = 0.0
var damage_flash: float = 0.0
var damage_invuln: float = 0.0
var ads_lockout: float = 0.0
var hit_glitch: float = 0.0
var hit_ca_boost: float = 0.0
var hit_dir_screen: Vector2 = Vector2.ZERO
var _ads_blend: float = 0.0
var _sprint_blend: float = 0.0
var _sprint_out_timer: float = 0.0
var _iris_wall_dim: float = 1.0
var _was_on_floor: bool = true
var _pre_land_vy: float = 0.0
var _land_dip: float = 0.0

const MAX_FIREARM_SLOTS := 3
const GRENADE_ORDER := ["frag", "molotov", "shock"]
const GRENADE_LABELS := {"frag": "FRAG", "molotov": "MOLOTOV", "shock": "SHOCK"}

var current_weapon: int = 0
# Dynamic pickup-order loadout cap: 3 firearms [1-3], 1 special [4], 1 active melee [5 / V], + throwables [G/Q]!
var firearm_slots: Array[int] = [0]
var special_slot: int = -1
var owned_melee: Array[String] = ["knife"]
var god_mode: bool = false
var unlocked_weapons: Array[bool] = [true, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
var upgraded_weapons: Array[bool] = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
var weapon_chambered: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
var ammo_in_mag: Array[int] = [15, 30, 8, 1, 1, 30, 6, 5, 30, 7, 100, 2, 30, 8, 5, 1, 60, 1]
var ammo_reserve: Array[int] = [90, 180, 48, 0, 24, 180, 42, 35, 180, 42, 300, 32, 180, 64, 40, 24, 0, 4]
var weapon_attachments: Dictionary = {} # weapon_idx -> {"optic": bool, "suppressor": bool, "ext_mag": bool}
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _rockets: Array[Dictionary] = []
var _flame_jets: Array[Dictionary] = []
var _flame_embers: Array[Dictionary] = []
var _flame_pool_cd: float = 0.0
var _flame_firing_timer: float = 0.0
var _flame_emit_window: float = 0.0
var _flame_emit_accum: float = 0.0
var _flame_emit_w: Dictionary = {}
var _flame_hit_tick_cd: float = 0.0
var _flamer_pilot_node: MeshInstance3D = null
var _flamer_pilot_mat: ShaderMaterial = null
var sfx_flame_loop: AudioStreamPlayer = null
static var _fire_shader: Shader = null
static var _char_shader: Shader = null
static var _smoke_wisp_tex: Texture2D = null
static var _fire_plume_tex: Texture2D = null
static var _napalm_puff_tex: Texture2D = null
static var _ember_mat: StandardMaterial3D = null
static var _ember_mesh: QuadMesh = null
static var _sfx_flame_jet_loop: AudioStream = null
static var _sfx_fire_crackle_loop: AudioStream = null
var _flamer_flare: float = 0.0
var equipped_melee_id: String = "knife"
var _melee_timer: float = 0.0
var _melee_dur: float = 0.42
var _melee_hit_done: bool = false
var _quick_melee_active: bool = false
var _melee_is_heavy: bool = false
var _melee_is_gun_bash: bool = false
var _melee_combo_idx: int = 0
var _melee_combo_reset: float = 0.0
var _melee_hitstop_timer: float = 0.0
var _melee_nodes: Dictionary = {} # melee_id -> Node3D
var _melee_move: String = "slash_rl"
var _melee_win0: float = 0.10 # seconds into the swing when the edge becomes live
var _melee_win1: float = 0.24 # seconds into the swing when the edge stops being live
var _melee_prev_u: float = 0.0
var _melee_swing_hits: Dictionary = {} # ZombieAI -> true (one hit per body per swing)
var _melee_hits_left: int = 1
var _melee_any_hit: bool = false
var _melee_wall_done: bool = false
var _melee_power: float = 1.0 # damage multiplier of the swing in flight
var _melee_charging: bool = false
var _melee_charge: float = 0.0 # 0..1 held heavy-attack charge
var _melee_charge_pose: float = 0.0
var _melee_lunge_vel: Vector3 = Vector3.ZERO
var _melee_lunge_timer: float = 0.0
var _shove_cd: float = 0.0

# Survival state: regenerating health, zombie grabs, external shoves and score-relevant stats
var regen_delay: float = 0.0
var grabbed_by: Node3D = null
var grab_struggle: float = 0.0
var grab_immunity: float = 0.0
var slow_timer: float = 0.0
var slow_mult: float = 1.0
var _ext_vel: Vector3 = Vector3.ZERO
var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _spread_bloom: float = 0.0
var shots_fired: int = 0
var shots_hit: int = 0
var damage_taken_total: float = 0.0
var last_damage_dir: Vector3 = Vector3.ZERO # world-space point the last hit came from (HUD direction arc)
var last_damage_time: float = -99.0
var last_hit_by: String = "" # label of whatever last hurt the player (shown on the debrief screen)
var base_fov: float = 94.0
var perks: Dictionary = {} # perk id -> true, bought from dispensary cabinets, lost when the run ends
var ads_sens_mult: float = 0.62
var invert_y: bool = false
static var _sfx_melee_blunt: AudioStream = null
static var _sfx_melee_wall: AudioStream = null
static var _sfx_shove: AudioStream = null
static var _sfx_heartbeat: AudioStream = null
var sfx_heart: AudioStreamPlayer

signal score_event(kind: String, amount: int)
signal feed_message(msg: String)

# Throwables state (Frag, Molotov, Shock)
var grenade_counts: Dictionary = {"frag": 2, "molotov": 1, "shock": 1}
var equipped_grenade: String = "frag"
var _grenade_cd: float = 0.0
var _grenades: Array[Dictionary] = []
var _hazards: Array[Dictionary] = []

# Bow, Revolver & CoD-Style Sniper Scope Transition state
const BOW_NOCK_DUR := 0.78
var _bow_drawing: bool = false
var _bow_draw: float = 0.0
var _bow_hold_time: float = 0.0
var _bow_nock_timer: float = 0.0
var _bow_nock_sfx_played: bool = false
var _bow_release_timer: float = 0.0
var _bow_release_from_draw: float = 0.0
var _bow_require_repull: bool = false
var _bow_parts: Dictionary = {}
var _bow_charge_mats: Array[StandardMaterial3D] = []
var _arrows: Array[Dictionary] = []
var _benelli_shell_rig: Node3D = null
var _revolver_cyl_angle: float = 0.0
var _revolver_hammer: float = 0.0
var _hunting_bolt_timer: float = 0.0
var _hunting_bolt_did_sfx: bool = false
var _sniper_ads_raw: float = 0.0
var sniper_scope_alpha: float = 0.0
var sniper_iris_scale: float = 1.0

var yaw: float = 0.0
var pitch: float = 0.0
var yaw_vel: float = 0.0
var _last_yaw: float = 0.0
var sway_offset: Vector2 = Vector2.ZERO
var recoil_vel: Vector2 = Vector2.ZERO
var recoil_z: float = 0.0
var recoil_roll: float = 0.0
var recoil_fov: float = 0.0
var hit_roll_kick: float = 0.0
var hit_pitch_kick: float = 0.0
var trauma: float = 0.0
var _noise: FastNoiseLite
var bob_phase: float = 0.0
var step_dist: float = 0.0
var step_side: float = 1.0
var step_roll_impulse: float = 0.0
var bolt_blowback: float = 0.0
var shotgun_pump_timer: float = 0.0
var shotgun_pump_did_sfx: bool = false
var _barrel_heat_timer: float = 0.0
var _barrel_heat_step: float = 0.0
var _flash_shadow_boost: float = 0.0
var mouse_sens: float = 0.0022
var input_enabled: bool = true
var deterministic_camera: bool = false
var skip_initial_weapon_prebuild: bool = false

var game_manager: Node = null
var _glb_cache: Dictionary = {}
var _casings: Array[Dictionary] = []
var _weapon_rigs: Array[Node3D] = []
var _weapon_audio: Array[AudioStream] = []
var _weapon_audio_vars: Array = []
var _gun_alt_flip: int = 0
var _m16_dust_open: bool = false
var _shotgun_shell_rig: Node3D = null
var _w_parts_by_idx: Array[Dictionary] = []
var _w_parts: Dictionary = {} # group_name -> Array[Node3D]
var _w_rest_pos: Dictionary = {} # instance_id -> Vector3
var _w_rest_rot: Dictionary = {} # instance_id -> Vector3

const EJECT_G17 := Vector3(0.0, -0.9336, 0.3583)
const PIVOT_G17_SLIDESTOP := Vector3(-0.010, 0.025, -0.162)
const PIVOT_G17_TRIGGER := Vector3(0.0, 0.022, -0.155)
const EJECT_AR := Vector3(0.012, -0.9758, -0.2183)
const PIVOT_AR_MAG := Vector3(0.0, -0.135, -0.135)
const PIVOT_AR_HAND := Vector3(-0.010, -0.055, -0.310)
const PIVOT_AR_LATCH := Vector3(-0.028, 0.0066, 0.038)
const PIVOT_AR_DUST := Vector3(0.0185, -0.0275, -0.119)
const PIVOT_AR_CATCH := Vector3(-0.0185, -0.039, -0.081)
const AXIS_AR_ASSIST := Vector3(-0.38, 0.0, -0.92)
const PORT_M870 := Vector3(0.001, -0.058, -0.124)
const SHELL_M870_START := Vector3(0.001, -0.165, -0.105)
const SHELL_M870_ENTER := Vector3(0.001, -0.038, -0.158)
const SHELL_M870_SEAT := Vector3(0.001, -0.029, -0.198)
const PIVOT_M870_LIFTER := Vector3(0.001, -0.036, -0.184)

static var _casing_mesh: CylinderMesh = null
static var _hull_mesh: CylinderMesh = null
static var _mag_mesh_g17: BoxMesh = null
static var _mag_mesh_ar: Mesh = null
static var _mag_mat_ar: Material = null
static var _mag_mat_dark: StandardMaterial3D = null
static var _sfx_flashlight_click: AudioStream = null
static var _sfx_reload_mech: AudioStream = null
static var _sfx_mag_out: AudioStream = null
static var _sfx_mag_in: AudioStream = null
static var _sfx_bolt: AudioStream = null
static var _sfx_shell_in: AudioStream = null
static var _sfx_hit_flesh: Array[AudioStream] = []
static var _sfx_hit_head: Array[AudioStream] = []
static var _sfx_hit_confirm: AudioStream = null
static var _sfx_shell_clink: Array[AudioStream] = []
static var _sfx_impact_hard: AudioStream = null
static var _sfx_player_slash: Array[AudioStream] = []
static var _sfx_player_hurt: AudioStream = null
static var _sfx_melee_swing: AudioStream = null
static var _sfx_melee_cleave: AudioStream = null
static var _sfx_bow_draw: AudioStream = null
static var _sfx_bow_release: AudioStream = null
static var _sfx_bow_nock: AudioStream = null
static var _sfx_arrow_impact: AudioStream = null
static var _sfx_flamethrower_jet: AudioStream = null
static var _sfx_fire_crackle: AudioStream = null
static var _sfx_garand_ping: AudioStream = null

signal player_died
signal weapon_changed(index: int, name: String)
signal hit_confirmed(is_headshot: bool, killed: bool)
signal status_message(msg: String)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	# Stairs are ramp colliders: keep the capsule glued to them on the way down and hold walking speed constant on slopes.
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	_noise = FastNoiseLite.new()
	_noise.seed = 4077
	_noise.frequency = 1.8
	_preload_combat_fx()
	_build_rig()
	if not skip_initial_weapon_prebuild:
		_equip_weapon(0)


func _preload_combat_fx() -> void:
	for p in ["res://assets/audio/hit_flesh_a.wav", "res://assets/audio/hit_flesh_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_hit_flesh.append(load(p))
	for p in ["res://assets/audio/hit_headshot_a.wav", "res://assets/audio/hit_headshot_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_hit_head.append(load(p))
	for p in ["res://assets/audio/shell_clink_a.wav", "res://assets/audio/shell_clink_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_shell_clink.append(load(p))
	for p in ["res://assets/audio/player_hit_slash_a.wav", "res://assets/audio/player_hit_slash_b.wav"]:
		if ResourceLoader.exists(p):
			_sfx_player_slash.append(load(p))
	if ResourceLoader.exists("res://assets/audio/player_hurt.wav"):
		_sfx_player_hurt = load("res://assets/audio/player_hurt.wav")
	if ResourceLoader.exists("res://assets/audio/reload_mag_out.wav"):
		_sfx_mag_out = load("res://assets/audio/reload_mag_out.wav")
	if ResourceLoader.exists("res://assets/audio/reload_mag_in.wav"):
		_sfx_mag_in = load("res://assets/audio/reload_mag_in.wav")
	if ResourceLoader.exists("res://assets/audio/reload_bolt.wav"):
		_sfx_bolt = load("res://assets/audio/reload_bolt.wav")
	if ResourceLoader.exists("res://assets/audio/reload_shell_in.wav"):
		_sfx_shell_in = load("res://assets/audio/reload_shell_in.wav")
	if ResourceLoader.exists("res://assets/audio/hit_confirm.wav"):
		_sfx_hit_confirm = load("res://assets/audio/hit_confirm.wav")
	if ResourceLoader.exists("res://assets/audio/impact_hard.wav"):
		_sfx_impact_hard = load("res://assets/audio/impact_hard.wav")
	if ResourceLoader.exists("res://assets/audio/melee_swing.wav"):
		_sfx_melee_swing = load("res://assets/audio/melee_swing.wav")
	if ResourceLoader.exists("res://assets/audio/melee_cleave.wav"):
		_sfx_melee_cleave = load("res://assets/audio/melee_cleave.wav")
	if ResourceLoader.exists("res://assets/audio/bow_draw.wav"):
		_sfx_bow_draw = load("res://assets/audio/bow_draw.wav")
	if ResourceLoader.exists("res://assets/audio/bow_release.wav"):
		_sfx_bow_release = load("res://assets/audio/bow_release.wav")
	if ResourceLoader.exists("res://assets/audio/bow_nock.wav"):
		_sfx_bow_nock = load("res://assets/audio/bow_nock.wav")
	if ResourceLoader.exists("res://assets/audio/arrow_impact.wav"):
		_sfx_arrow_impact = load("res://assets/audio/arrow_impact.wav")
	if ResourceLoader.exists("res://assets/audio/flamethrower_jet.wav"):
		_sfx_flamethrower_jet = load("res://assets/audio/flamethrower_jet.wav")
	if ResourceLoader.exists("res://assets/audio/fire_crackle.wav"):
		_sfx_fire_crackle = load("res://assets/audio/fire_crackle.wav")
	if ResourceLoader.exists("res://assets/audio/garand_ping.wav"):
		_sfx_garand_ping = load("res://assets/audio/garand_ping.wav")
	if ResourceLoader.exists("res://assets/audio/melee_blunt.wav"):
		_sfx_melee_blunt = load("res://assets/audio/melee_blunt.wav")
	if ResourceLoader.exists("res://assets/audio/melee_wall.wav"):
		_sfx_melee_wall = load("res://assets/audio/melee_wall.wav")
	if ResourceLoader.exists("res://assets/audio/shove.wav"):
		_sfx_shove = load("res://assets/audio/shove.wav")
	if ResourceLoader.exists("res://assets/audio/heartbeat.wav"):
		_sfx_heartbeat = load("res://assets/audio/heartbeat.wav")

	if _casing_mesh == null:
		_casing_mesh = CylinderMesh.new()
		_casing_mesh.top_radius = 0.0045
		_casing_mesh.bottom_radius = 0.0052
		_casing_mesh.height = 0.026
		_casing_mesh.radial_segments = 8
		_casing_mesh.rings = 1
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.92, 0.72, 0.30)
		cmat.metallic = 0.94
		cmat.roughness = 0.22
		_casing_mesh.material = cmat
	if _hull_mesh == null:
		_hull_mesh = CylinderMesh.new()
		_hull_mesh.top_radius = 0.0090
		_hull_mesh.bottom_radius = 0.0094
		_hull_mesh.height = 0.062
		_hull_mesh.radial_segments = 8
		_hull_mesh.rings = 1
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(0.68, 0.06, 0.04)
		hmat.metallic = 0.14
		hmat.roughness = 0.34
		_hull_mesh.material = hmat


func _build_rig() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.72
	col.shape = cap
	col.position = Vector3(0, 0.86, 0)
	add_child(col)

	head = Node3D.new()
	head.position = Vector3(0, 1.56, 0)
	add_child(head)

	camera = Camera3D.new()
	camera.fov = 94.0
	camera.near = 0.03
	camera.far = 150.0
	camera.current = true
	camera.cull_mask = 0xFFFFF
	cam_attrs = CameraAttributesPractical.new()
	cam_attrs.dof_blur_far_enabled = false
	cam_attrs.dof_blur_near_enabled = false
	cam_attrs.dof_blur_amount = 0.075
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		cam_attrs.auto_exposure_enabled = true
		cam_attrs.auto_exposure_scale = 0.68
		cam_attrs.auto_exposure_speed = 1.8
		cam_attrs.auto_exposure_min_sensitivity = 320.0
		cam_attrs.auto_exposure_max_sensitivity = 960.0
	camera.attributes = cam_attrs
	head.add_child(camera)

	interact_ray = RayCast3D.new()
	interact_ray.target_position = Vector3(0, 0, -3.2)
	interact_ray.collision_mask = 1 | 16
	camera.add_child(interact_ray)

	weapon_clearance = Node3D.new()
	camera.add_child(weapon_clearance)
	weapon_pivot = Node3D.new()
	weapon_clearance.add_child(weapon_pivot)

	weapon_rig_holder = Node3D.new()
	weapon_pivot.add_child(weapon_rig_holder)

	vm_rim = OmniLight3D.new()
	vm_rim.light_color = Color(0.86, 0.90, 0.96)
	vm_rim.light_energy = 0.16
	vm_rim.light_volumetric_fog_energy = 0.0
	vm_rim.omni_range = 1.8
	vm_rim.omni_attenuation = 1.6
	vm_rim.light_cull_mask = 2
	vm_rim.shadow_enabled = false
	vm_rim.light_bake_mode = Light3D.BAKE_DISABLED
	vm_rim.position = Vector3(-0.24, 0.15, -0.04)
	camera.add_child(vm_rim)

	holo_quad = MeshInstance3D.new()
	var hqm := QuadMesh.new()
	hqm.size = Vector2(0.014, 0.014)
	holo_quad.mesh = hqm
	var hmat := ShaderMaterial.new()
	hmat.render_priority = 8
	hmat.shader = load("res://shaders/holographic_sight.gdshader")
	holo_quad.material_override = hmat
	holo_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holo_quad.layers = 2
	weapon_pivot.add_child(holo_quad)

	# Modular Tactical Red-Dot Sight slim machined aluminum housing (direct sibling on weapon_pivot so it NEVER vanishes on reload and tracks hinged/reciprocating parts!)
	optic_hood = Node3D.new()
	optic_hood.name = "ModularOpticHood"
	optic_hood.visible = false
	var h_metal := _make_vm_mat(Color(0.11, 0.12, 0.13), 0.34, 0.84, 0.62, Color.BLACK, "metal_tactical")
	var h_lens := StandardMaterial3D.new()
	h_lens.albedo_color = Color(0.10, 0.24, 0.22, 0.16)
	h_lens.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	h_lens.roughness = 0.08
	h_lens.metallic = 0.15
	h_lens.cull_mode = BaseMaterial3D.CULL_DISABLED
	var base_b := BoxMesh.new(); base_b.size = Vector3(0.024, 0.007, 0.048); base_b.material = h_metal
	var riser_b := BoxMesh.new(); riser_b.size = Vector3(0.020, 0.005, 0.036); riser_b.material = h_metal
	var side_b := BoxMesh.new(); side_b.size = Vector3(0.0024, 0.020, 0.032); side_b.material = h_metal
	var top_b := BoxMesh.new(); top_b.size = Vector3(0.025, 0.0024, 0.032); top_b.material = h_metal
	var lens_q := QuadMesh.new(); lens_q.size = Vector2(0.021, 0.018); lens_q.material = h_lens
	_add_vm_mesh(optic_hood, base_b, Vector3(0.0, -0.0155, 0.0))
	_add_vm_mesh(optic_hood, riser_b, Vector3(0.0, -0.0110, 0.0))
	_add_vm_mesh(optic_hood, side_b, Vector3(-0.0118, 0.0005, 0.0))
	_add_vm_mesh(optic_hood, side_b, Vector3(0.0118, 0.0005, 0.0))
	_add_vm_mesh(optic_hood, top_b, Vector3(0.0, 0.0112, 0.0))
	_add_vm_mesh(optic_hood, lens_q, Vector3(0.0, 0.0005, -0.012))
	weapon_pivot.add_child(optic_hood)

	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(0.96, 0.98, 1.0)
	flashlight.light_energy = 28.0
	flashlight.light_size = 0.0
	flashlight.light_indirect_energy = 1.0
	flashlight.light_volumetric_fog_energy = 0.72
	flashlight.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight.spot_range = 26.0
	flashlight.spot_attenuation = 1.12
	flashlight.spot_angle = 55.0
	flashlight.spot_angle_attenuation = 0.68
	flashlight.shadow_enabled = true
	var is_compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	flashlight.shadow_bias = 0.055 if is_compat else 0.025
	flashlight.shadow_normal_bias = 1.35 if is_compat else 0.45
	flashlight.shadow_caster_mask = 1 | 8
	flashlight.light_cull_mask = 0xFFFFD
	flashlight.light_projector = load("res://assets/textures/flashlight_cookie.png")
	flashlight.position = Vector3(0.09, -0.07, -0.44)
	camera.add_child(flashlight)

	# Compatibility stub kept disabled (outer spill is baked into the 1024px TIR optical cookie)
	flashlight_spill = SpotLight3D.new()
	flashlight_spill.light_energy = 0.0
	flashlight_spill.spot_range = 0.01
	flashlight_spill.shadow_enabled = false
	flashlight_spill.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight_spill.visible = false
	camera.add_child(flashlight_spill)

	# Single unshadowed dynamic bounce light driven by the flashlight hit ray (zero GI grid relight)
	flashlight_bounce = OmniLight3D.new()
	flashlight_bounce.top_level = true
	flashlight_bounce.light_color = Color(0.92, 0.88, 0.82)
	flashlight_bounce.light_energy = 0.0
	flashlight_bounce.light_specular = 0.0
	flashlight_bounce.light_volumetric_fog_energy = 0.0
	flashlight_bounce.light_bake_mode = Light3D.BAKE_DISABLED
	flashlight_bounce.shadow_enabled = false
	flashlight_bounce.omni_range = 4.5
	flashlight_bounce.omni_attenuation = 2.0
	flashlight_bounce.light_cull_mask = 0xFFFFD
	flashlight_bounce.visible = false
	camera.add_child(flashlight_bounce)

	# Corrected cone orientation: narrow tip at emitter (-0.45) expanding outward toward -Z!
	flashlight_cone = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.15
	cm.bottom_radius = 0.025
	cm.height = 5.0
	cm.radial_segments = 24
	cm.rings = 4
	cm.cap_top = false
	cm.cap_bottom = false
	flashlight_cone.mesh = cm
	var cmat := ShaderMaterial.new()
	cmat.shader = load("res://shaders/flashlight_vol.gdshader")
	cmat.set_shader_parameter("intensity", 0.009)
	flashlight_cone.material_override = cmat
	flashlight_cone.position = Vector3(0.09, -0.07, -2.95)
	flashlight_cone.rotation.x = -PI * 0.5
	flashlight_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(flashlight_cone)

	# Camera-following ambient floating dust motes (lit strictly by real flashlight/lamps!)
	_build_dust_motes()

	# World muzzle flash light + dedicated viewmodel flash light (both off until firing -> zero idle tunnel overhead!)
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.78, 0.44)
	muzzle_light.light_energy = 0.0
	muzzle_light.light_volumetric_fog_energy = 0.0
	muzzle_light.omni_range = 5.5
	muzzle_light.omni_attenuation = 1.65
	muzzle_light.shadow_enabled = false
	muzzle_light.light_bake_mode = Light3D.BAKE_DISABLED
	muzzle_light.light_cull_mask = 0xFFFFD
	muzzle_light.visible = false
	weapon_pivot.add_child(muzzle_light)

	muzzle_vm_light = OmniLight3D.new()
	muzzle_vm_light.light_color = Color(1.0, 0.72, 0.36)
	muzzle_vm_light.light_energy = 0.0
	muzzle_vm_light.light_volumetric_fog_energy = 0.0
	muzzle_vm_light.omni_range = 1.4
	muzzle_vm_light.omni_attenuation = 1.8
	muzzle_vm_light.shadow_enabled = false
	muzzle_vm_light.light_bake_mode = Light3D.BAKE_DISABLED
	muzzle_vm_light.light_cull_mask = 2
	muzzle_vm_light.visible = false
	weapon_pivot.add_child(muzzle_vm_light)

	_build_muzzle_flash_rig()
	_build_muzzle_smoke()

	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var has_limiter := false
		for bi in range(AudioServer.get_bus_effect_count(master_idx)):
			if AudioServer.get_bus_effect(master_idx, bi) is AudioEffectLimiter:
				has_limiter = true
				break
		if not has_limiter:
			var lim := AudioEffectLimiter.new()
			lim.ceiling_db = -0.3
			lim.threshold_db = -1.5
			lim.soft_clip_db = 0.0
			AudioServer.add_bus_effect(master_idx, lim)

	sfx_gun = AudioStreamPlayer.new()
	sfx_gun.volume_db = -1.0
	sfx_gun.max_polyphony = 6
	add_child(sfx_gun)
	_sfx_gun_pool.clear()
	for _gi in range(6):
		var gp := AudioStreamPlayer.new()
		gp.volume_db = -1.0
		add_child(gp)
		_sfx_gun_pool.append(gp)

	sfx_misc = AudioStreamPlayer.new()
	sfx_misc.volume_db = -5.0
	add_child(sfx_misc)

	sfx_reload = AudioStreamPlayer.new()
	sfx_reload.volume_db = -3.0
	add_child(sfx_reload)
	_sfx_reload_pool.clear()
	for _ri in range(4):
		var rp := AudioStreamPlayer.new()
		rp.volume_db = -3.0
		add_child(rp)
		_sfx_reload_pool.append(rp)

	sfx_bow_draw = AudioStreamPlayer.new()
	sfx_bow_draw.volume_db = -3.5
	add_child(sfx_bow_draw)

	sfx_flame_loop = AudioStreamPlayer.new()
	sfx_flame_loop.volume_db = -28.0
	add_child(sfx_flame_loop)

	sfx_step = AudioStreamPlayer.new()
	sfx_step.stream = load("res://assets/audio/footstep.wav")
	sfx_step.volume_db = -10.5
	add_child(sfx_step)

	sfx_hit = AudioStreamPlayer.new()
	sfx_hit.volume_db = -1.5
	add_child(sfx_hit)

	sfx_hit_tick = AudioStreamPlayer.new()
	sfx_hit_tick.volume_db = -5.5
	add_child(sfx_hit_tick)

	sfx_casing = AudioStreamPlayer.new()
	sfx_casing.volume_db = -9.0
	add_child(sfx_casing)

	sfx_hurt = AudioStreamPlayer.new()
	sfx_hurt.volume_db = -1.5
	add_child(sfx_hurt)

	sfx_slash = AudioStreamPlayer.new()
	sfx_slash.volume_db = -1.0
	add_child(sfx_slash)

	sfx_heart = AudioStreamPlayer.new()
	sfx_heart.volume_db = -60.0
	if _sfx_heartbeat:
		if _sfx_heartbeat is AudioStreamWAV:
			(_sfx_heartbeat as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			(_sfx_heartbeat as AudioStreamWAV).loop_end = int(round(_sfx_heartbeat.get_length() * float((_sfx_heartbeat as AudioStreamWAV).mix_rate)))
		sfx_heart.stream = _sfx_heartbeat
	add_child(sfx_heart)

	if not skip_initial_weapon_prebuild:
		_prebuild_weapon_rigs()


func _build_dust_motes() -> void:
	dust_motes = GPUParticles3D.new()
	dust_motes.amount = 140
	dust_motes.lifetime = 5.0
	dust_motes.preprocess = 0.0 if OS.has_feature("web") else 2.0
	dust_motes.local_coords = false
	dust_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust_motes.visibility_aabb = AABB(Vector3(-8, -5, -10), Vector3(16, 10, 14))
	dust_motes.position = Vector3(0.0, 0.0, -5.8)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.2, 2.2, 3.0)
	pm.direction = Vector3(0.15, 0.4, 0.1).normalized()
	pm.spread = 180.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.10
	pm.gravity = Vector3(0.0, 0.015, 0.0)
	pm.scale_min = 0.45
	pm.scale_max = 1.0
	pm.color = Color(0.68, 0.72, 0.78, 0.11)
	dust_motes.process_material = pm

	var qm := QuadMesh.new()
	qm.size = Vector2(0.013, 0.013)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	sm.albedo_texture = load("res://assets/textures/gunsmoke_wisp.png")
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = sm
	dust_motes.draw_pass_1 = qm
	camera.add_child(dust_motes)


func _build_muzzle_flash_rig() -> void:
	muzzle_flash_rig = Node3D.new()
	muzzle_flash_rig.visible = false
	weapon_pivot.add_child(muzzle_flash_rig)

	var flash_shader := load("res://shaders/muzzle_flash.gdshader") as Shader
	var front_tex := load("res://assets/textures/muzzle_flash_front.png")
	var side_tex := load("res://assets/textures/muzzle_flash_side.png")

	var f_mat := ShaderMaterial.new()
	f_mat.shader = flash_shader
	f_mat.set_shader_parameter("shape_tex", front_tex)
	f_mat.set_shader_parameter("is_side", 0.0)
	f_mat.set_shader_parameter("intensity", 3.1)
	f_mat.set_shader_parameter("cool_t", 0.0)
	_flash_mats.append(f_mat)

	var front_mi := MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(0.24, 0.24)
	front_mi.mesh = fq
	front_mi.material_override = f_mat
	front_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	front_mi.layers = 2
	muzzle_flash_rig.add_child(front_mi)

	var s_mat := ShaderMaterial.new()
	s_mat.shader = flash_shader
	s_mat.set_shader_parameter("shape_tex", side_tex)
	s_mat.set_shader_parameter("is_side", 1.0)
	s_mat.set_shader_parameter("intensity", 2.8)
	s_mat.set_shader_parameter("cool_t", 0.0)
	_flash_mats.append(s_mat)

	for roll_z: float in [0.0, PI * 0.5]:
		var holder := Node3D.new()
		holder.rotation.z = roll_z
		var side_mi := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(0.35, 0.16)
		side_mi.mesh = sq
		side_mi.material_override = s_mat
		side_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		side_mi.layers = 2
		side_mi.rotation.y = PI * 0.5
		side_mi.position = Vector3(0.0, 0.0, -0.15)
		holder.add_child(side_mi)
		muzzle_flash_rig.add_child(holder)


func _build_muzzle_smoke() -> void:
	muzzle_smoke = GPUParticles3D.new()
	muzzle_smoke.emitting = false
	if OS.has_feature("web"):
		muzzle_smoke.one_shot = true
		muzzle_smoke.explosiveness = 0.90
		muzzle_smoke.amount = 6
	else:
		muzzle_smoke.amount = 24
	muzzle_smoke.lifetime = 1.05
	muzzle_smoke.local_coords = false
	muzzle_smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.85, -0.35)
	pm.spread = 24.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.80
	pm.gravity = Vector3(0.0, 0.45, 0.0)
	pm.damping_min = 0.9
	pm.damping_max = 1.6
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.scale_min = 0.45
	pm.scale_max = 1.25
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pm.color_ramp = grad_tex
	muzzle_smoke.process_material = pm

	var qm := QuadMesh.new()
	qm.size = Vector2(0.14, 0.14)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/soft_lit_particle.gdshader")
	sm.set_shader_parameter("albedo_tex", load("res://assets/textures/gunsmoke_wisp.png"))
	sm.set_shader_parameter("tint_color", Color(0.72, 0.74, 0.78, 0.16))
	sm.set_shader_parameter("soft_fade_dist", 0.24)
	sm.set_shader_parameter("near_fade_start", 0.10)
	sm.set_shader_parameter("near_fade_end", 0.38)
	sm.set_shader_parameter("wrap_lighting", 0.72)
	sm.set_shader_parameter("max_lit", 0.85)
	qm.material = sm
	muzzle_smoke.draw_pass_1 = qm
	weapon_pivot.add_child(muzzle_smoke)


func _prep_viewmodel_node(n: Node) -> void:
	if n is GeometryInstance3D:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.layers = 2
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var source := n.get_active_material(i) as StandardMaterial3D
			if source == null:
				continue
			var mname := str(source.resource_name).to_lower()
			if mname.begins_with("aaa_"):
				# Preserve Blender 5.3 authored PBR materials intact!
				continue
			if mname.begins_with("arms"):
				var cloth := source.duplicate() as StandardMaterial3D
				cloth.albedo_texture = preload("res://assets/textures/field_glove_albedo.jpg")
				cloth.albedo_color = Color(0.56, 0.56, 0.54)
				cloth.normal_scale = 1.35
				cloth.roughness = 0.92
				cloth.metallic = 0.0
				cloth.metallic_specular = 0.05
				cloth.rim_enabled = false
				n.set_surface_override_material(i, cloth)
			elif (source.roughness_texture != null or source.metallic_texture != null) and not ("m16" in mname or "remington" in mname or "shotgun" in mname or "glock" in mname or mname == "material" or "magazine_m16a2" in n.name.to_lower()):
				# Preserve real Objaverse PBR textures & metallic/roughness maps (MP5A3, Melee, Grenades, new firearms)!
				continue
			else:
				var gun := source.duplicate() as StandardMaterial3D
				var nname := n.name.to_lower()
				if "magazine_m16a2" in nname:
					gun.albedo_color = Color(2.35, 2.40, 2.24)
					gun.metallic = 0.48
					gun.roughness = 0.36
					gun.metallic_specular = 0.62
					gun.anisotropy_enabled = false
				elif "m16" in mname or "slide" in mname or "barrel" in mname or "reflex" in mname or "frame" in mname or "bolt" in mname or "mag" in mname or "charge" in mname or gun.metallic > 0.20:
					gun.metallic = 0.56
					gun.roughness = 0.44
					gun.metallic_specular = 0.56
					gun.anisotropy_enabled = false
				elif mname == "material" or "remington" in mname or "shotgun" in mname:
					gun.metallic = clampf(maxf(gun.metallic, 0.38), 0.35, 0.66)
					gun.roughness = clampf(gun.roughness, 0.38, 0.58)
					gun.metallic_specular = 0.48
					gun.anisotropy_enabled = false
				else:
					gun.metallic = 0.04
					gun.roughness = clampf(gun.roughness, 0.48, 0.65)
				n.set_surface_override_material(i, gun)
	for c in n.get_children():
		_prep_viewmodel_node(c)


func _find_mesh_islands(verts: PackedVector3Array, indices: PackedInt32Array) -> Array:
	var nv := verts.size()
	var parent := PackedInt32Array()
	parent.resize(nv)
	for i in nv:
		parent[i] = i
	var tri_count := int(indices.size() / 3)
	for ti in tri_count:
		var a := indices[ti * 3]
		var b := indices[ti * 3 + 1]
		var c := indices[ti * 3 + 2]
		var ra := a
		while parent[ra] != ra:
			parent[ra] = parent[parent[ra]]
			ra = parent[ra]
		var rb := b
		while parent[rb] != rb:
			parent[rb] = parent[parent[rb]]
			rb = parent[rb]
		if ra != rb:
			parent[rb] = ra
		var rc := c
		while parent[rc] != rc:
			parent[rc] = parent[parent[rc]]
			rc = parent[rc]
		if ra != rc:
			parent[rc] = ra

	var comp_tris: Dictionary = {}
	var comp_vset: Dictionary = {}
	for ti in tri_count:
		var a := indices[ti * 3]
		var b := indices[ti * 3 + 1]
		var c := indices[ti * 3 + 2]
		var r := a
		while parent[r] != r:
			parent[r] = parent[parent[r]]
			r = parent[r]
		if not comp_tris.has(r):
			comp_tris[r] = PackedInt32Array()
			comp_vset[r] = {}
		var ta: PackedInt32Array = comp_tris[r]
		ta.append(a)
		ta.append(b)
		ta.append(c)
		comp_tris[r] = ta
		var vs: Dictionary = comp_vset[r]
		vs[a] = true
		vs[b] = true
		vs[c] = true

	var islands: Array = []
	for r in comp_tris.keys():
		var vs: Dictionary = comp_vset[r]
		var sum := Vector3.ZERO
		var min_z_v := Vector3(0.0, 0.0, 1e9)
		var max_z_v := Vector3(0.0, 0.0, -1e9)
		for vi: int in vs.keys():
			var v := verts[vi]
			sum += v
			if v.z < min_z_v.z:
				min_z_v = v
			if v.z > max_z_v.z:
				max_z_v = v
		var cnt := vs.size()
		islands.append({
			"tris": comp_tris[r],
			"count": cnt,
			"avg": sum / float(maxi(cnt, 1)),
			"min_z_v": min_z_v,
			"max_z_v": max_z_v,
		})
	return islands


func _build_submesh_from_tris(src_arrays: Array, tri_indices: PackedInt32Array, mat: Material) -> ArrayMesh:
	var am := ArrayMesh.new()
	if tri_indices.is_empty():
		return am
	var src_v: PackedVector3Array = src_arrays[Mesh.ARRAY_VERTEX]
	var has_n: bool = src_arrays[Mesh.ARRAY_NORMAL] != null
	var has_t: bool = src_arrays[Mesh.ARRAY_TANGENT] != null
	var has_uv: bool = src_arrays[Mesh.ARRAY_TEX_UV] != null
	var has_uv2: bool = src_arrays[Mesh.ARRAY_TEX_UV2] != null
	var has_col: bool = src_arrays[Mesh.ARRAY_COLOR] != null
	var src_n: PackedVector3Array = src_arrays[Mesh.ARRAY_NORMAL] if has_n else PackedVector3Array()
	var src_t: PackedFloat32Array = src_arrays[Mesh.ARRAY_TANGENT] if has_t else PackedFloat32Array()
	var src_uv: PackedVector2Array = src_arrays[Mesh.ARRAY_TEX_UV] if has_uv else PackedVector2Array()
	var src_uv2: PackedVector2Array = src_arrays[Mesh.ARRAY_TEX_UV2] if has_uv2 else PackedVector2Array()
	var src_col: PackedColorArray = src_arrays[Mesh.ARRAY_COLOR] if has_col else PackedColorArray()

	var remap := PackedInt32Array()
	remap.resize(src_v.size())
	remap.fill(-1)
	var dst_v := PackedVector3Array()
	var dst_n := PackedVector3Array()
	var dst_t := PackedFloat32Array()
	var dst_uv := PackedVector2Array()
	var dst_uv2 := PackedVector2Array()
	var dst_col := PackedColorArray()
	var dst_idx := PackedInt32Array()
	dst_idx.resize(tri_indices.size())

	for k in tri_indices.size():
		var oi := tri_indices[k]
		var ni := remap[oi]
		if ni < 0:
			ni = dst_v.size()
			remap[oi] = ni
			dst_v.append(src_v[oi])
			if has_n:
				dst_n.append(src_n[oi])
			if has_t:
				var ti4 := oi * 4
				dst_t.append(src_t[ti4])
				dst_t.append(src_t[ti4 + 1])
				dst_t.append(src_t[ti4 + 2])
				dst_t.append(src_t[ti4 + 3])
			if has_uv:
				dst_uv.append(src_uv[oi])
			if has_uv2:
				dst_uv2.append(src_uv2[oi])
			if has_col:
				dst_col.append(src_col[oi])
		dst_idx[k] = ni

	var out_arr := []
	out_arr.resize(Mesh.ARRAY_MAX)
	out_arr[Mesh.ARRAY_VERTEX] = dst_v
	if has_n:
		out_arr[Mesh.ARRAY_NORMAL] = dst_n
	if has_t:
		out_arr[Mesh.ARRAY_TANGENT] = dst_t
	if has_uv:
		out_arr[Mesh.ARRAY_TEX_UV] = dst_uv
	if has_uv2:
		out_arr[Mesh.ARRAY_TEX_UV2] = dst_uv2
	if has_col:
		out_arr[Mesh.ARRAY_COLOR] = dst_col
	out_arr[Mesh.ARRAY_INDEX] = dst_idx
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arr)
	if mat != null:
		am.surface_set_material(0, mat)
	return am


func _find_mesh_by_name(n: Node, target_lower: String) -> MeshInstance3D:
	if n is MeshInstance3D and n.name.to_lower() == target_lower:
		return n as MeshInstance3D
	for c in n.get_children():
		var found := _find_mesh_by_name(c, target_lower)
		if found != null:
			return found
	return null


func _split_weapon_rig_meshes(inst: Node3D, weapon_idx: int) -> void:
	# 1. Split combined arms mesh into independent ArmLeft and ArmRight siblings
	var arm_target := "object_86_hero" if weapon_idx == 0 else ("object_67_hero" if weapon_idx == 1 else "shotgunarms")
	var arm_mi := _find_mesh_by_name(inst, arm_target)
	if arm_mi != null and arm_mi.mesh != null and arm_mi.mesh.get_surface_count() > 0:
		var arrays := arm_mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if not verts.is_empty() and not indices.is_empty():
			var islands := _find_mesh_islands(verts, indices)
			islands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) > int(b["count"]))
			if islands.size() >= 2:
				var s0: Dictionary = islands[0]
				var s1: Dictionary = islands[1]
				var left_sleeve: Dictionary = s0 if (s0["avg"] as Vector3).x < (s1["avg"] as Vector3).x else s1
				var right_sleeve: Dictionary = s1 if left_sleeve == s0 else s0
				var left_cuff: Vector3 = left_sleeve["min_z_v"]
				var right_cuff: Vector3 = right_sleeve["min_z_v"]
				var left_tris := PackedInt32Array()
				var right_tris := PackedInt32Array()
				left_tris.append_array(left_sleeve["tris"])
				right_tris.append_array(right_sleeve["tris"])
				for ii in range(2, islands.size()):
					var isl: Dictionary = islands[ii]
					var cuff: Vector3 = isl["max_z_v"]
					if cuff.distance_to(left_cuff) <= cuff.distance_to(right_cuff):
						left_tris.append_array(isl["tris"])
					else:
						right_tris.append_array(isl["tris"])
				var base_mat := arm_mi.mesh.surface_get_material(0)
				var ovr_mat := arm_mi.get_surface_override_material(0)
				var pnode := arm_mi.get_parent()
				for pair in [["ArmLeft", left_tris], ["ArmRight", right_tris]]:
					var smi := MeshInstance3D.new()
					smi.name = pair[0]
					smi.mesh = _build_submesh_from_tris(arrays, pair[1], base_mat)
					smi.transform = arm_mi.transform
					smi.layers = 2
					smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					if ovr_mat != null:
						smi.set_surface_override_material(0, ovr_mat)
					pnode.add_child(smi)
				pnode.remove_child(arm_mi)
				arm_mi.queue_free()

	# 2. For M870, split loading-gate lifter island out of ShotgunReceiver
	if weapon_idx == 2:
		var recv_mi := _find_mesh_by_name(inst, "shotgunreceiver")
		if recv_mi != null and recv_mi.mesh != null and recv_mi.mesh.get_surface_count() > 0:
			var arrays := recv_mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if not verts.is_empty() and not indices.is_empty():
				var islands := _find_mesh_islands(verts, indices)
				var lifter_tris := PackedInt32Array()
				var body_tris := PackedInt32Array()
				for isl: Dictionary in islands:
					var avg: Vector3 = isl["avg"]
					var cnt: int = isl["count"]
					if cnt < 400 and absf(avg.x) < 0.015 and avg.y >= -0.050 and avg.y <= -0.025 and avg.z >= -0.195 and avg.z <= -0.095:
						lifter_tris.append_array(isl["tris"])
					else:
						body_tris.append_array(isl["tris"])
				if not lifter_tris.is_empty() and not body_tris.is_empty():
					var base_mat := recv_mi.mesh.surface_get_material(0)
					var ovr_mat := recv_mi.get_surface_override_material(0)
					recv_mi.mesh = _build_submesh_from_tris(arrays, body_tris, base_mat)
					if ovr_mat != null:
						recv_mi.set_surface_override_material(0, ovr_mat)
					var lmi := MeshInstance3D.new()
					lmi.name = "ShotgunLifter"
					lmi.mesh = _build_submesh_from_tris(arrays, lifter_tris, base_mat)
					lmi.transform = recv_mi.transform
					lmi.layers = 2
					lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					if ovr_mat != null:
						lmi.set_surface_override_material(0, ovr_mat)
					recv_mi.get_parent().add_child(lmi)


func _collect_weapon_parts(n: Node, target_parts: Dictionary = _w_parts) -> void:
	if n is Node3D:
		var nl := n.name.to_lower()
		var grp := ""
		if "g17_magazine_03" in nl or "magazine_m16a2" in nl or "g17_base_03" in nl:
			grp = "mag"
		elif "g17_bullet" in nl:
			grp = "mag_bullet"
		elif "g17_slidestopper" in nl:
			grp = "slidestop"
		elif "g17_trigger" in nl:
			grp = "trigger"
		elif "m16a2_bolt_m16a2" in nl or "g17_slide_" in nl:
			grp = "slide"
		elif "m16a2_chargehandle2" in nl:
			grp = "charge_latch"
		elif "chargehandle" in nl:
			grp = "charge"
		elif "m16a2_ejection_port_cover" in nl:
			grp = "dust_cover"
		elif "m16a2_release" in nl:
			grp = "bolt_catch"
		elif "m16a2_boltcatch" in nl:
			grp = "fwd_assist"
		elif "pump" in nl or "forend" in nl:
			grp = "pump"
		elif nl == "armleft":
			grp = "arm_left"
		elif nl == "armright":
			grp = "arm_right"
		elif nl == "shotgunlifter":
			grp = "lifter"
		elif nl == "mag":
			grp = "mag"
		elif nl == "magbullet":
			grp = "mag_bullet"
		elif nl == "charge":
			grp = "charge"
		elif nl == "bolt":
			grp = "bolt"
		elif nl == "crane":
			grp = "crane"
		elif nl == "cylinder":
			grp = "cylinder"
		elif nl == "hammer":
			grp = "hammer"
		elif nl == "topcover":
			grp = "top_cover"
		elif nl == "ammobelt":
			grp = "ammo_belt"
		elif nl == "limbtop":
			grp = "limb_top"
		elif nl == "limbbot":
			grp = "limb_bot"
		elif nl == "camtop":
			grp = "cam_top"
		elif nl == "cambot":
			grp = "cam_bot"
		elif nl == "stringtop":
			grp = "str_top"
		elif nl == "stringbot":
			grp = "str_bot"
		elif nl == "busscable_0":
			grp = "buss_0"
		elif nl == "busscable_1":
			grp = "buss_1"
		elif nl == "arrow":
			grp = "bow_arrow"
		elif nl == "speedloader":
			grp = "speed_loader"
		elif nl == "feedround":
			grp = "feed_round"
		elif nl == "lifter":
			grp = "lifter"
		elif nl == "quiver":
			grp = "quiver"
		elif nl == "barrel":
			grp = "barrel"
		elif nl == "warhead":
			grp = "warhead"
		elif nl.begins_with("chargebar_"):
			grp = "charge_bars"
		if grp != "":
			if not target_parts.has(grp):
				target_parts[grp] = []
			(target_parts[grp] as Array).append(n)
			var iid := n.get_instance_id()
			_w_rest_pos[iid] = (n as Node3D).position
			_w_rest_rot[iid] = (n as Node3D).rotation
	for c in n.get_children():
		_collect_weapon_parts(c, target_parts)


func _build_shotgun_shell_rig() -> Node3D:
	var rig := Node3D.new()
	rig.name = "ShotgunReloadShell"
	rig.visible = false
	var hull := MeshInstance3D.new()
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = 0.0084
	hmesh.bottom_radius = 0.0084
	hmesh.height = 0.042
	hmesh.radial_segments = 16
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.66, 0.07, 0.06)
	hmat.roughness = 0.52
	hmat.metallic = 0.04
	hmesh.material = hmat
	hull.mesh = hmesh
	hull.rotation.x = PI * 0.5
	hull.layers = 2
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.add_child(hull)

	var brass := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.0088
	bmesh.bottom_radius = 0.0088
	bmesh.height = 0.014
	bmesh.radial_segments = 16
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.88, 0.70, 0.30)
	bmat.metallic = 0.88
	bmat.roughness = 0.24
	bmesh.material = bmat
	brass.mesh = bmesh
	brass.position = Vector3(0.0, 0.0, 0.022)
	brass.rotation.x = PI * 0.5
	brass.layers = 2
	brass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.add_child(brass)
	return rig


func _attach_ar_top_cartridge(inst: Node3D, parts: Dictionary) -> void:
	var mag_mi := _find_mesh_by_name(inst, "magazine_m16a2_0_hero")
	if mag_mi == null:
		return
	if mag_mi.mesh != null:
		_mag_mesh_ar = mag_mi.mesh
		_mag_mat_ar = mag_mi.get_surface_override_material(0)
	var round_rig := Node3D.new()
	round_rig.name = "ARTopCartridge"
	round_rig.position = Vector3(0.0, -0.036, -0.122)
	round_rig.rotation = Vector3(PI * 0.5 - 0.14, 0.0, 0.0)
	var brass := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.0046
	bmesh.bottom_radius = 0.0046
	bmesh.height = 0.044
	bmesh.radial_segments = 12
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.92, 0.74, 0.32)
	bmat.metallic = 0.90
	bmat.roughness = 0.22
	bmesh.material = bmat
	brass.mesh = bmesh
	brass.layers = 2
	brass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	round_rig.add_child(brass)
	var tip := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.0010
	tmesh.bottom_radius = 0.0044
	tmesh.height = 0.013
	tmesh.radial_segments = 12
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.82, 0.44, 0.24)
	tmat.metallic = 0.86
	tmat.roughness = 0.26
	tmesh.material = tmat
	tip.mesh = tmesh
	tip.position = Vector3(0.0, 0.028, 0.0)
	tip.layers = 2
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	round_rig.add_child(tip)
	mag_mi.add_child(round_rig)
	if not parts.has("mag_bullet"):
		parts["mag_bullet"] = []
	(parts["mag_bullet"] as Array).append(round_rig)
	var iid := round_rig.get_instance_id()
	_w_rest_pos[iid] = round_rig.position
	_w_rest_rot[iid] = round_rig.rotation


func _build_melee_viewmodel_rig(holder: Node3D) -> void:
	_melee_nodes.clear()
	# Right-third AAA tactical melee ready stance: every handle sits snugly inside M16A2 ArmRight's clenched palm (~(0.005, -0.068, 0.035))
	# with blades/heads yawed ~28-36 deg so the flat bevel/head gleams clearly on the right side without ever blocking the center crosshair!
	var specs := [
		["knife", "res://assets/models/weapon_melee_knife.glb", true, Vector3(0.002, -0.056, 0.012), Vector3(-0.34, 0.65, 0.18), Vector3.ONE * 1.15],
		["fire_axe", "res://assets/models/weapon_melee_axe.glb", false, Vector3(0.010, -0.072, 0.016), Vector3(-0.38, 0.50, -0.34), Vector3.ONE * 0.90],
		["machete", "res://assets/models/weapon_melee_machete.glb", false, Vector3(0.006, -0.068, 0.014), Vector3(-0.36, 0.58, -0.24), Vector3.ONE * 0.95],
		["bat", "res://assets/models/weapon_melee_bat.glb", false, Vector3(0.012, -0.064, 0.018), Vector3(-0.40, 0.36, -0.38), Vector3.ONE * 0.88],
		["bat_spiked", "res://assets/models/weapon_melee_bat_spiked.glb", false, Vector3(0.012, -0.064, 0.018), Vector3(-0.40, 0.36, -0.38), Vector3.ONE * 0.88],
		["crowbar", "res://assets/models/weapon_melee_crowbar.glb", false, Vector3(0.008, -0.102, 0.016), Vector3(-0.38, 0.54, -0.30), Vector3.ONE * 0.92],
	]
	for sp in specs:
		var mid: String = sp[0]
		var glb_path: String = sp[1]
		var vis: bool = sp[2]
		var root_n := Node3D.new()
		root_n.name = "Melee_%s" % mid
		root_n.visible = vis
		root_n.position = sp[3]
		root_n.rotation = sp[4]
		root_n.scale = sp[5]
		if ResourceLoader.exists(glb_path):
			if not _glb_cache.has(glb_path):
				_glb_cache[glb_path] = load(glb_path)
			var pk: PackedScene = _glb_cache[glb_path]
			if pk:
				var inst := pk.instantiate()
				_prep_viewmodel_node(inst)
				if mid == "bat":
					# Clamp wooden baseball bat metallic <= 0.05 so ash wood isn't metallic!
					for mn in inst.find_children("*", "MeshInstance3D", true, false):
						var mi := mn as MeshInstance3D
						if mi.mesh:
							for si in mi.mesh.get_surface_count():
								var sm := mi.get_active_material(si) as StandardMaterial3D
								if sm:
									var wm := sm.duplicate() as StandardMaterial3D
									wm.metallic = 0.04
									wm.roughness = maxf(wm.roughness, 0.62)
									mi.set_surface_override_material(si, wm)
				root_n.add_child(inst)
		holder.add_child(root_n)
		_melee_nodes[mid] = root_n


func _make_vm_mat(col: Color, rough: float, metal: float = 0.0, spec: float = 0.45, emit := Color.BLACK, pbr_prefix := "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = spec
	if pbr_prefix != "":
		var ap := "res://assets/textures/%s_albedo.jpg" % pbr_prefix
		var np := "res://assets/textures/%s_normal.jpg" % pbr_prefix
		var rp := "res://assets/textures/%s_rough.jpg" % pbr_prefix
		if ResourceLoader.exists(ap):
			m.albedo_texture = load(ap)
		if ResourceLoader.exists(np):
			m.normal_enabled = true
			m.normal_texture = load(np)
			m.normal_scale = 0.85
		if ResourceLoader.exists(rp):
			m.roughness_texture = load(rp)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(4.0, 4.0, 4.0)
	if emit != Color.BLACK:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = 2.4
	return m


func _add_vm_mesh(parent: Node3D, m: Mesh, pos: Vector3, rot := Vector3.ZERO, n_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if n_name != "":
		mi.name = n_name
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	mi.layers = 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _clone_tactical_arms(src_idx: int, holder: Node3D, parts: Dictionary,
		left_off := Vector3.ZERO, left_rot := Vector3.ZERO,
		right_off := Vector3.ZERO, right_rot := Vector3.ZERO,
		include_left := true, include_right := true) -> void:
	if src_idx < 0 or src_idx >= _w_parts_by_idx.size():
		return
	var src_parts: Dictionary = _w_parts_by_idx[src_idx]
	for spec in [
		["arm_left", include_left, left_off, left_rot, "ArmLeftPivot"],
		["arm_right", include_right, right_off, right_rot, "ArmRightPivot"],
	]:
		var grp: String = spec[0]
		if not bool(spec[1]) or not src_parts.has(grp):
			continue
		var arr: Array = src_parts[grp]
		if arr.is_empty():
			continue
		var src_mi := arr[0] as MeshInstance3D
		if src_mi == null or src_mi.mesh == null:
			continue
		var piv := Node3D.new()
		piv.name = spec[4]
		piv.position = spec[2]
		piv.rotation = spec[3]
		var dup := MeshInstance3D.new()
		dup.name = src_mi.name
		dup.mesh = src_mi.mesh
		# Strip stray inner-seam/cuff islands (< 900 verts) on cloned ArmRight so NO white cuff shard juts into camera FOV!
		if (src_idx == 0 or src_idx == 1) and grp == "arm_right" and src_mi.mesh.get_surface_count() > 0:
			var arr0 := src_mi.mesh.surface_get_arrays(0)
			var sv0: PackedVector3Array = arr0[Mesh.ARRAY_VERTEX]
			var si0: PackedInt32Array = arr0[Mesh.ARRAY_INDEX]
			if not sv0.is_empty() and not si0.is_empty():
				var islands := _find_mesh_islands(sv0, si0)
				var keep_tris := PackedInt32Array()
				for isl: Dictionary in islands:
					if int(isl["count"]) >= 900:
						keep_tris.append_array(isl["tris"] as PackedInt32Array)
				if not keep_tris.is_empty():
					dup.mesh = _build_submesh_from_tris(arr0, keep_tris, src_mi.get_active_material(0))
		dup.transform = src_mi.transform
		dup.layers = 2
		dup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ovr := src_mi.get_surface_override_material(0)
		if ovr != null:
			dup.set_surface_override_material(0, ovr)
		piv.add_child(dup)
		holder.add_child(piv)
		if not parts.has(grp):
			parts[grp] = []
		(parts[grp] as Array).append(piv)
		_w_rest_pos[piv.get_instance_id()] = piv.position
		_w_rest_rot[piv.get_instance_id()] = piv.rotation


func _setup_bow_rig_refs(parts: Dictionary) -> void:
	_bow_parts.clear()
	_bow_charge_mats.clear()
	for k in ["limb_top", "limb_bot", "cam_top", "cam_bot", "str_top", "str_bot", "buss_0", "buss_1", "quiver"]:
		if parts.has(k) and not (parts[k] as Array).is_empty():
			_bow_parts[k] = parts[k][0]
	if parts.has("bow_arrow") and not (parts["bow_arrow"] as Array).is_empty():
		_bow_parts["arrow"] = parts["bow_arrow"][0]
	if parts.has("arm_right") and not (parts["arm_right"] as Array).is_empty():
		_bow_parts["arm_draw"] = parts["arm_right"][0]
	if parts.has("charge_bars"):
		var bars: Array = parts["charge_bars"]
		bars.sort_custom(func(a: Node, b: Node): return a.name < b.name)
		for b_node in bars:
			var mi := b_node as MeshInstance3D
			if mi and mi.mesh and mi.mesh.get_surface_count() > 0:
				var src_m := mi.get_active_material(0) as StandardMaterial3D
				if src_m:
					var dup_m := src_m.duplicate() as StandardMaterial3D
					dup_m.emission_energy_multiplier = 0.0
					mi.set_surface_override_material(0, dup_m)
					_bow_charge_mats.append(dup_m)
	_pose_bow_rig()


func _build_bow_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	_bow_parts.clear()
	var riser_mat := _make_vm_mat(Color(0.18, 0.20, 0.19), 0.42, 0.72, 0.56, Color.BLACK, "metal_tactical")
	var limb_mat := _make_vm_mat(Color(0.12, 0.13, 0.12), 0.46, 0.30, 0.44, Color.BLACK, "metal_tactical")
	var cam_mat := _make_vm_mat(Color(0.24, 0.25, 0.27), 0.28, 0.88, 0.68, Color.BLACK, "metal_tactical")
	var cam_accent := _make_vm_mat(Color(0.38, 0.10, 0.08), 0.36, 0.72, 0.55)
	var string_mat := _make_vm_mat(Color(0.22, 0.22, 0.21), 0.82, 0.0, 0.12)
	var grip_mat := _make_vm_mat(Color(0.28, 0.18, 0.12), 0.85, 0.0, 0.14, Color.BLACK, "wood_carved")
	var shaft_mat := _make_vm_mat(Color(0.10, 0.11, 0.12), 0.34, 0.38, 0.48)
	var tip_mat := _make_vm_mat(Color(0.76, 0.78, 0.82), 0.22, 0.92, 0.75)
	var fletch_mat := _make_vm_mat(Color(0.58, 0.11, 0.09), 0.56, 0.0, 0.22)
	var pin_g := _make_vm_mat(Color(0.2, 1.0, 0.3), 0.2, 0.0, 0.2, Color(0.2, 1.0, 0.35))
	var pin_y := _make_vm_mat(Color(1.0, 0.8, 0.15), 0.2, 0.0, 0.2, Color(1.0, 0.75, 0.15))

	# Compact sculpted tactical compound bow riser (twin machined truss bars + grip + sight cage)
	var r_front := BoxMesh.new(); r_front.size = Vector3(0.015, 0.24, 0.014); r_front.material = riser_mat
	_add_vm_mesh(holder, r_front, Vector3(-0.022, 0.01, -0.175))
	var r_back := BoxMesh.new(); r_back.size = Vector3(0.013, 0.20, 0.011); r_back.material = riser_mat
	_add_vm_mesh(holder, r_back, Vector3(-0.022, 0.01, -0.148))
	var r_bridge := BoxMesh.new(); r_bridge.size = Vector3(0.015, 0.014, 0.036); r_bridge.material = riser_mat
	_add_vm_mesh(holder, r_bridge, Vector3(-0.022, 0.11, -0.162))
	_add_vm_mesh(holder, r_bridge, Vector3(-0.022, -0.09, -0.162))
	_add_vm_mesh(holder, r_bridge, Vector3(-0.022, 0.025, -0.162))
	# Contoured grip + tactical stabilizer + arrow rest
	var r_grip := CylinderMesh.new(); r_grip.top_radius = 0.012; r_grip.bottom_radius = 0.014; r_grip.height = 0.095; r_grip.material = grip_mat
	_add_vm_mesh(holder, r_grip, Vector3(-0.022, -0.038, -0.145), Vector3(0.14, 0, 0))
	var stab := CylinderMesh.new(); stab.top_radius = 0.0065; stab.bottom_radius = 0.008; stab.height = 0.14; stab.material = riser_mat
	_add_vm_mesh(holder, stab, Vector3(-0.022, -0.082, -0.245), Vector3(PI * 0.5, 0, 0))
	var stab_cap := CylinderMesh.new(); stab_cap.top_radius = 0.011; stab_cap.bottom_radius = 0.011; stab_cap.height = 0.022; stab_cap.material = cam_mat
	_add_vm_mesh(holder, stab_cap, Vector3(-0.022, -0.082, -0.318), Vector3(PI * 0.5, 0, 0))
	# Fiber-optic sight ring + glowing aiming pins
	var s_arm := BoxMesh.new(); s_arm.size = Vector3(0.022, 0.008, 0.010); s_arm.material = riser_mat
	_add_vm_mesh(holder, s_arm, Vector3(-0.012, 0.048, -0.188))
	var s_ring := CylinderMesh.new(); s_ring.top_radius = 0.017; s_ring.bottom_radius = 0.017; s_ring.height = 0.010; s_ring.material = cam_mat
	_add_vm_mesh(holder, s_ring, Vector3(0.002, 0.048, -0.192), Vector3(PI * 0.5, 0, 0))
	var p1 := BoxMesh.new(); p1.size = Vector3(0.010, 0.0020, 0.0020); p1.material = pin_g
	_add_vm_mesh(holder, p1, Vector3(-0.001, 0.051, -0.192))
	var p2 := BoxMesh.new(); p2.size = Vector3(0.009, 0.0018, 0.0018); p2.material = pin_y
	_add_vm_mesh(holder, p2, Vector3(-0.002, 0.045, -0.192))

	# Compact split-limb recurve arms + dark gunmetal cams (NOT giant red discs!)
	var limb_top := Node3D.new(); limb_top.name = "BowLimbTop"; limb_top.position = Vector3(-0.022, 0.115, -0.165)
	var lt_m := BoxMesh.new(); lt_m.size = Vector3(0.006, 0.165, 0.010); lt_m.material = limb_mat
	_add_vm_mesh(limb_top, lt_m, Vector3(-0.006, 0.074, 0.028), Vector3(0.36, 0, 0))
	_add_vm_mesh(limb_top, lt_m, Vector3(0.006, 0.074, 0.028), Vector3(0.36, 0, 0))
	var cam_t := CylinderMesh.new(); cam_t.top_radius = 0.017; cam_t.bottom_radius = 0.017; cam_t.height = 0.008; cam_t.material = cam_mat
	_add_vm_mesh(limb_top, cam_t, Vector3(0.0, 0.155, 0.058), Vector3(0, 0, PI * 0.5))
	var cam_ta := CylinderMesh.new(); cam_ta.top_radius = 0.008; cam_ta.bottom_radius = 0.008; cam_ta.height = 0.010; cam_ta.material = cam_accent
	_add_vm_mesh(limb_top, cam_ta, Vector3(0.0, 0.155, 0.058), Vector3(0, 0, PI * 0.5))
	holder.add_child(limb_top)

	var limb_bot := Node3D.new(); limb_bot.name = "BowLimbBot"; limb_bot.position = Vector3(-0.022, -0.095, -0.165)
	var lb_m := BoxMesh.new(); lb_m.size = Vector3(0.006, 0.165, 0.010); lb_m.material = limb_mat
	_add_vm_mesh(limb_bot, lb_m, Vector3(-0.006, -0.074, 0.028), Vector3(-0.36, 0, 0))
	_add_vm_mesh(limb_bot, lb_m, Vector3(0.006, -0.074, 0.028), Vector3(-0.36, 0, 0))
	var cam_b := CylinderMesh.new(); cam_b.top_radius = 0.017; cam_b.bottom_radius = 0.017; cam_b.height = 0.008; cam_b.material = cam_mat
	_add_vm_mesh(limb_bot, cam_b, Vector3(0.0, -0.155, 0.058), Vector3(0, 0, PI * 0.5))
	var cam_ba := CylinderMesh.new(); cam_ba.top_radius = 0.008; cam_ba.bottom_radius = 0.008; cam_ba.height = 0.010; cam_ba.material = cam_accent
	_add_vm_mesh(limb_bot, cam_ba, Vector3(0.0, -0.155, 0.058), Vector3(0, 0, PI * 0.5))
	holder.add_child(limb_bot)

	# Dark braided dynamic bowstring halves (unit height = 1.0, scaled locally from cam to nock)
	var st_m := CylinderMesh.new(); st_m.top_radius = 0.0014; st_m.bottom_radius = 0.0014; st_m.height = 1.0; st_m.material = string_mat
	var str_top := _add_vm_mesh(holder, st_m, Vector3(-0.020, 0.14, -0.105), Vector3.ZERO, "BowStringTop")
	var str_bot := _add_vm_mesh(holder, st_m, Vector3(-0.020, -0.12, -0.105), Vector3.ZERO, "BowStringBot")

	# Nocked carbon arrow with steel broadhead & dark crimson fletching
	var arrow := Node3D.new(); arrow.name = "BowNockedArrow"; arrow.position = Vector3(-0.008, 0.032, -0.22)
	var sh := CylinderMesh.new(); sh.top_radius = 0.0030; sh.bottom_radius = 0.0030; sh.height = 0.42; sh.material = shaft_mat
	_add_vm_mesh(arrow, sh, Vector3(0, 0, -0.10), Vector3(PI * 0.5, 0, 0))
	var bh := CylinderMesh.new(); bh.top_radius = 0.0005; bh.bottom_radius = 0.0085; bh.height = 0.038; bh.radial_segments = 4; bh.material = tip_mat
	_add_vm_mesh(arrow, bh, Vector3(0, 0, -0.325), Vector3(-PI * 0.5, 0, 0))
	var fl := BoxMesh.new(); fl.size = Vector3(0.0018, 0.013, 0.056); fl.material = fletch_mat
	_add_vm_mesh(arrow, fl, Vector3(0, 0.007, 0.072))
	_add_vm_mesh(arrow, fl, Vector3(0.006, -0.004, 0.072), Vector3(0, 0, 2.09))
	_add_vm_mesh(arrow, fl, Vector3(-0.006, -0.004, 0.072), Vector3(0, 0, -2.09))
	holder.add_child(arrow)

	# Attach real gloved tactical arms: ArmLeft grips bow riser, ArmRight pulls bowstring!
	_clone_tactical_arms(1, holder, parts,
		Vector3(0.02, -0.01, 0.12), Vector3(0.08, -0.10, 0.20),
		Vector3(0.03, 0.02, 0.08), Vector3(0.10, 0.18, -0.15),
		true, true)

	_bow_parts = {
		"limb_top": limb_top,
		"limb_bot": limb_bot,
		"str_top": str_top,
		"str_bot": str_bot,
		"arrow": arrow,
		"arm_draw": (parts["arm_right"][0] if (parts.has("arm_right") and not (parts["arm_right"] as Array).is_empty()) else null),
	}
	parts["bow_arrow"] = [arrow]
	_pose_bow_rig()


func _build_mp5_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var steel := _make_vm_mat(Color(0.32, 0.34, 0.36), 0.38, 0.78, 0.58, Color.BLACK, "metal_tactical")
	var poly := _make_vm_mat(Color(0.14, 0.15, 0.16), 0.74, 0.08, 0.24, Color.BLACK, "metal_tactical")
	var sd_mat := _make_vm_mat(Color(0.28, 0.29, 0.30), 0.60, 0.48, 0.38, Color.BLACK, "metal_tactical")
	var optic_m := _make_vm_mat(Color(0.24, 0.24, 0.26), 0.36, 0.65, 0.55, Color.BLACK, "metal_tactical")

	# Upper stamped steel receiver + lower polymer trigger housing
	var rec := BoxMesh.new(); rec.size = Vector3(0.038, 0.052, 0.28); rec.material = steel
	_add_vm_mesh(holder, rec, Vector3(0.0, 0.022, -0.14))
	var low := BoxMesh.new(); low.size = Vector3(0.032, 0.038, 0.16); low.material = poly
	_add_vm_mesh(holder, low, Vector3(0.0, -0.018, -0.09))
	var grip := BoxMesh.new(); grip.size = Vector3(0.028, 0.095, 0.040); grip.material = poly
	_add_vm_mesh(holder, grip, Vector3(0.0, -0.068, -0.032), Vector3(-0.26, 0, 0))
	# Integrated MP5SD ribbed cylindrical suppressor & forend
	var fore := CylinderMesh.new(); fore.top_radius = 0.024; fore.bottom_radius = 0.025; fore.height = 0.16; fore.material = poly
	_add_vm_mesh(holder, fore, Vector3(0.0, 0.020, -0.34), Vector3(PI * 0.5, 0, 0))
	var supp := CylinderMesh.new(); supp.top_radius = 0.019; supp.bottom_radius = 0.019; supp.height = 0.22; supp.material = sd_mat
	_add_vm_mesh(holder, supp, Vector3(0.0, 0.024, -0.49), Vector3(PI * 0.5, 0, 0))
	# Cocking tube + animated HK charging handle
	var tube := CylinderMesh.new(); tube.top_radius = 0.011; tube.bottom_radius = 0.011; tube.height = 0.18; tube.material = steel
	_add_vm_mesh(holder, tube, Vector3(0.0, 0.044, -0.31), Vector3(PI * 0.5, 0, 0))
	var ch_m := CylinderMesh.new(); ch_m.top_radius = 0.0055; ch_m.bottom_radius = 0.0055; ch_m.height = 0.036; ch_m.material = steel
	var ch_node := _add_vm_mesh(holder, ch_m, Vector3(-0.026, 0.046, -0.34), Vector3(0, 0, PI * 0.42), "MP5_Charge")
	# Curved 30-rd magazine
	var mag_root := Node3D.new(); mag_root.name = "MP5_Mag"; mag_root.position = Vector3(0.0, -0.045, -0.185)
	var m1 := BoxMesh.new(); m1.size = Vector3(0.022, 0.105, 0.036); m1.material = steel
	_add_vm_mesh(mag_root, m1, Vector3(0.0, -0.045, 0.0), Vector3(0.14, 0, 0))
	var m2 := BoxMesh.new(); m2.size = Vector3(0.021, 0.090, 0.035); m2.material = steel
	_add_vm_mesh(mag_root, m2, Vector3(0.0, -0.130, -0.020), Vector3(0.28, 0, 0))
	holder.add_child(mag_root)
	# Compact red-dot sight frame
	var rail := BoxMesh.new(); rail.size = Vector3(0.024, 0.010, 0.10); rail.material = optic_m
	_add_vm_mesh(holder, rail, Vector3(0.0, 0.052, -0.095))
	var opt_l := BoxMesh.new(); opt_l.size = Vector3(0.005, 0.032, 0.044); opt_l.material = optic_m
	_add_vm_mesh(holder, opt_l, Vector3(-0.017, 0.074, -0.088))
	_add_vm_mesh(holder, opt_l, Vector3(0.017, 0.074, -0.088))
	var opt_t := BoxMesh.new(); opt_t.size = Vector3(0.038, 0.005, 0.044); opt_t.material = optic_m
	_add_vm_mesh(holder, opt_t, Vector3(0.0, 0.091, -0.088))
	# Collapsible stock rails
	var sr := BoxMesh.new(); sr.size = Vector3(0.006, 0.012, 0.14); sr.material = steel
	_add_vm_mesh(holder, sr, Vector3(-0.021, 0.016, 0.04))
	_add_vm_mesh(holder, sr, Vector3(0.021, 0.016, 0.04))

	parts["mag"] = [mag_root]
	parts["charge"] = [ch_node]
	for n: Node3D in [mag_root, ch_node]:
		_w_rest_pos[n.get_instance_id()] = n.position
		_w_rest_rot[n.get_instance_id()] = n.rotation
	_clone_tactical_arms(1, holder, parts, Vector3(0.0, 0.025, 0.02), Vector3.ZERO, Vector3(0.0, 0.025, 0.02), Vector3.ZERO)


func _build_magnum_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var chrome := _make_vm_mat(Color(0.86, 0.88, 0.90), 0.26, 0.88, 0.72, Color.BLACK, "metal_tactical")
	var dark_st := _make_vm_mat(Color(0.24, 0.25, 0.27), 0.38, 0.82, 0.55, Color.BLACK, "metal_tactical")
	var walnut := _make_vm_mat(Color(0.58, 0.36, 0.22), 0.62, 0.02, 0.22, Color.BLACK, "wood_carved")
	var ramp := _make_vm_mat(Color(0.95, 0.24, 0.08), 0.35, 0.0, 0.3, Color(0.85, 0.18, 0.04))

	# Frame, top strap, trigger guard
	var frame := BoxMesh.new(); frame.size = Vector3(0.026, 0.056, 0.115); frame.material = chrome
	_add_vm_mesh(holder, frame, Vector3(0.0, 0.012, -0.105))
	var strap := BoxMesh.new(); strap.size = Vector3(0.022, 0.012, 0.095); strap.material = chrome
	_add_vm_mesh(holder, strap, Vector3(0.0, 0.050, -0.125))
	# Heavy 6.5" ventilated-rib barrel + full underlug
	var bbl := CylinderMesh.new(); bbl.top_radius = 0.012; bbl.bottom_radius = 0.012; bbl.height = 0.20; bbl.material = chrome
	_add_vm_mesh(holder, bbl, Vector3(0.0, 0.040, -0.265), Vector3(PI * 0.5, 0, 0))
	var lug := BoxMesh.new(); lug.size = Vector3(0.018, 0.026, 0.195); lug.material = chrome
	_add_vm_mesh(holder, lug, Vector3(0.0, 0.024, -0.262))
	var rib := BoxMesh.new(); rib.size = Vector3(0.012, 0.010, 0.195); rib.material = chrome
	_add_vm_mesh(holder, rib, Vector3(0.0, 0.054, -0.262))
	var fs := BoxMesh.new(); fs.size = Vector3(0.004, 0.011, 0.016); fs.material = ramp
	_add_vm_mesh(holder, fs, Vector3(0.0, 0.062, -0.350))
	# Checkered walnut grip
	var grip := BoxMesh.new(); grip.size = Vector3(0.030, 0.105, 0.046); grip.material = walnut
	_add_vm_mesh(holder, grip, Vector3(0.0, -0.055, -0.052), Vector3(-0.32, 0, 0))
	# Swing-out crane + 6-shot fluted cylinder
	var crane := Node3D.new(); crane.name = "Magnum_Crane"; crane.position = Vector3(-0.014, 0.002, -0.130)
	var cyl := Node3D.new(); cyl.name = "Magnum_Cyl"; cyl.position = Vector3(0.014, 0.022, 0.0)
	var cm := CylinderMesh.new(); cm.top_radius = 0.023; cm.bottom_radius = 0.023; cm.height = 0.056; cm.radial_segments = 18; cm.material = chrome
	_add_vm_mesh(cyl, cm, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	var fl_m := CylinderMesh.new(); fl_m.top_radius = 0.006; fl_m.bottom_radius = 0.006; fl_m.height = 0.058; fl_m.material = dark_st
	for k in range(6):
		var a := float(k) * TAU / 6.0
		_add_vm_mesh(cyl, fl_m, Vector3(cos(a) * 0.013, sin(a) * 0.013, 0.0), Vector3(PI * 0.5, 0, 0))
	crane.add_child(cyl)
	holder.add_child(crane)
	# External hammer
	var hm_m := BoxMesh.new(); hm_m.size = Vector3(0.009, 0.024, 0.020); hm_m.material = dark_st
	var hammer := _add_vm_mesh(holder, hm_m, Vector3(0.0, 0.044, -0.062), Vector3(-0.35, 0, 0), "Magnum_Hammer")

	parts["crane"] = [crane]
	parts["cylinder"] = [cyl]
	parts["hammer"] = [hammer]
	for n: Node3D in [crane, cyl, hammer]:
		_w_rest_pos[n.get_instance_id()] = n.position
		_w_rest_rot[n.get_instance_id()] = n.rotation
	_clone_tactical_arms(0, holder, parts, Vector3(0.0, -0.02, 0.08), Vector3.ZERO, Vector3(0.0, -0.02, 0.08), Vector3.ZERO)


func _build_hunting_rifle_viewmodel_rig(holder: Node3D, parts: Dictionary) -> void:
	var blued := _make_vm_mat(Color(0.26, 0.28, 0.32), 0.30, 0.86, 0.65, Color.BLACK, "metal_tactical")
	var walnut := _make_vm_mat(Color(0.56, 0.36, 0.22), 0.56, 0.02, 0.26, Color.BLACK, "wood_carved")
	var ebony := _make_vm_mat(Color(0.14, 0.12, 0.12), 0.45, 0.05, 0.25)
	var brass := _make_vm_mat(Color(0.78, 0.62, 0.26), 0.30, 0.88, 0.66)
	var bolt_st := _make_vm_mat(Color(0.80, 0.82, 0.84), 0.22, 0.92, 0.72, Color.BLACK, "metal_tactical")

	# Walnut stock, forend, ebony tip & cheek piece
	var stock := BoxMesh.new(); stock.size = Vector3(0.036, 0.056, 0.44); stock.material = walnut
	_add_vm_mesh(holder, stock, Vector3(0.0, -0.005, -0.18))
	var butt := BoxMesh.new(); butt.size = Vector3(0.038, 0.095, 0.20); butt.material = walnut
	_add_vm_mesh(holder, butt, Vector3(0.0, -0.024, 0.12))
	var tip := BoxMesh.new(); tip.size = Vector3(0.035, 0.040, 0.042); tip.material = ebony
	_add_vm_mesh(holder, tip, Vector3(0.0, -0.002, -0.415))
	# Steel receiver + 24" free-floating barrel
	var rec := CylinderMesh.new(); rec.top_radius = 0.017; rec.bottom_radius = 0.017; rec.height = 0.22; rec.material = blued
	_add_vm_mesh(holder, rec, Vector3(0.0, 0.028, -0.15), Vector3(PI * 0.5, 0, 0))
	var bbl := CylinderMesh.new(); bbl.top_radius = 0.0085; bbl.bottom_radius = 0.0125; bbl.height = 0.56; bbl.material = blued
	_add_vm_mesh(holder, bbl, Vector3(0.0, 0.030, -0.53), Vector3(PI * 0.5, 0, 0))
	# Animated bolt assembly + swept bolt knob
	var bolt_root := Node3D.new(); bolt_root.name = "M700_Bolt"; bolt_root.position = Vector3(0.0, 0.028, -0.085)
	var bbody := CylinderMesh.new(); bbody.top_radius = 0.011; bbody.bottom_radius = 0.011; bbody.height = 0.11; bbody.material = bolt_st
	_add_vm_mesh(bolt_root, bbody, Vector3(0.0, 0.0, -0.02), Vector3(PI * 0.5, 0, 0))
	var bstem := CylinderMesh.new(); bstem.top_radius = 0.004; bstem.bottom_radius = 0.004; bstem.height = 0.042; bstem.material = bolt_st
	_add_vm_mesh(bolt_root, bstem, Vector3(0.026, -0.008, 0.018), Vector3(0, 0, -1.25))
	var bknob := SphereMesh.new(); bknob.radius = 0.0095; bknob.height = 0.019; bknob.material = bolt_st
	_add_vm_mesh(bolt_root, bknob, Vector3(0.046, -0.016, 0.018))
	holder.add_child(bolt_root)
	# 4x Telescopic hunting scope with brass rings
	var sc_tube := CylinderMesh.new(); sc_tube.top_radius = 0.015; sc_tube.bottom_radius = 0.015; sc_tube.height = 0.24; sc_tube.material = blued
	_add_vm_mesh(holder, sc_tube, Vector3(0.0, 0.088, -0.17), Vector3(PI * 0.5, 0, 0))
	var sc_obj := CylinderMesh.new(); sc_obj.top_radius = 0.023; sc_obj.bottom_radius = 0.015; sc_obj.height = 0.075; sc_obj.material = blued
	_add_vm_mesh(holder, sc_obj, Vector3(0.0, 0.088, -0.32), Vector3(PI * 0.5, 0, 0))
	var sc_eye := CylinderMesh.new(); sc_eye.top_radius = 0.015; sc_eye.bottom_radius = 0.020; sc_eye.height = 0.055; sc_eye.material = blued
	_add_vm_mesh(holder, sc_eye, Vector3(0.0, 0.088, -0.03), Vector3(PI * 0.5, 0, 0))
	var ring := CylinderMesh.new(); ring.top_radius = 0.0185; ring.bottom_radius = 0.0185; ring.height = 0.014; ring.material = brass
	_add_vm_mesh(holder, ring, Vector3(0.0, 0.088, -0.11), Vector3(PI * 0.5, 0, 0))
	_add_vm_mesh(holder, ring, Vector3(0.0, 0.088, -0.23), Vector3(PI * 0.5, 0, 0))

	parts["bolt"] = [bolt_root]
	_w_rest_pos[bolt_root.get_instance_id()] = bolt_root.position
	_w_rest_rot[bolt_root.get_instance_id()] = bolt_root.rotation
	_clone_tactical_arms(1, holder, parts, Vector3(0.0, 0.015, 0.01), Vector3.ZERO, Vector3(0.0, 0.015, 0.01), Vector3.ZERO)


func _build_single_weapon_rig(i: int) -> void:
	var w: Dictionary = WEAPONS[i]
	var glb_path: String = w["glb"]
	var holder := Node3D.new()
	holder.name = "WeaponRig_%d" % i
	holder.visible = false
	weapon_rig_holder.add_child(holder)
	var parts := {}
	if bool(w.get("is_melee", false)):
		_build_melee_viewmodel_rig(holder)
		_clone_tactical_arms(1, holder, parts, Vector3.ZERO, Vector3.ZERO, Vector3(0.026, 0.040, 0.026), Vector3(0.32, 0.40, -0.04), false, true)
	elif glb_path != "":
		if not _glb_cache.has(glb_path):
			_glb_cache[glb_path] = load(glb_path)
		var packed: PackedScene = _glb_cache[glb_path]
		if packed:
			var inst := packed.instantiate()
			_prep_viewmodel_node(inst)
			if i <= 2:
				_split_weapon_rig_meshes(inst, i)
			holder.add_child(inst)
			_collect_weapon_parts(inst, parts)
			if i == 1:
				_attach_ar_top_cartridge(inst, parts)
			var arm_src := int(w.get("arm_src", -1))
			if arm_src >= 0:
				if i == 4:
					# Compound Bow: Left hand grips riser throat (0,0,0), Right hand pinches nock & pulls string!
					_clone_tactical_arms(1, holder, parts,
						Vector3(0.015, 0.02, 0.25), Vector3(0.05, -0.08, 0.12),
						Vector3(0.055, -0.01, 0.18), Vector3(0.06, 0.16, -0.12),
						true, true)
					_setup_bow_rig_refs(parts)
				elif i == 6:
					_clone_tactical_arms(0, holder, parts, Vector3(0.0, -0.02, 0.08), Vector3.ZERO, Vector3(0.0, -0.02, 0.08), Vector3.ZERO)
				elif i == 11:
					_clone_tactical_arms(1, holder, parts, Vector3(0.01, -0.028, 0.05), Vector3.ZERO, Vector3(0.0, -0.010, 0.04), Vector3.ZERO)
				elif i == 12:
					_clone_tactical_arms(1, holder, parts, Vector3(0.01, -0.036, 0.02), Vector3.ZERO, Vector3(0.0, -0.010, 0.02), Vector3.ZERO)
				elif i == 13:
					_clone_tactical_arms(1, holder, parts, Vector3(0.01, -0.040, 0.03), Vector3.ZERO, Vector3(0.0, -0.014, 0.03), Vector3.ZERO)
				elif i == 14:
					_clone_tactical_arms(1, holder, parts, Vector3(0.015, -0.064, 0.04), Vector3.ZERO, Vector3(0.0, -0.016, 0.03), Vector3.ZERO)
				elif i == 15:
					_clone_tactical_arms(1, holder, parts, Vector3(0.01, -0.052, 0.04), Vector3.ZERO, Vector3(0.0, -0.018, 0.04), Vector3.ZERO)
				elif i == 16:
					_clone_tactical_arms(1, holder, parts, Vector3(0.02, -0.036, 0.02), Vector3.ZERO, Vector3(0.0, -0.014, 0.02), Vector3.ZERO)
				elif i == 17:
					_clone_tactical_arms(1, holder, parts, Vector3(0.01, -0.046, 0.06), Vector3.ZERO, Vector3(0.0, -0.020, 0.06), Vector3.ZERO)
				else:
					_clone_tactical_arms(1, holder, parts, Vector3(0.0, 0.02, 0.02), Vector3.ZERO, Vector3(0.0, 0.02, 0.02), Vector3.ZERO)
	if i == 2:
		_shotgun_shell_rig = _build_shotgun_shell_rig()
		holder.add_child(_shotgun_shell_rig)
	elif i == 9:
		_benelli_shell_rig = _build_shotgun_shell_rig()
		holder.add_child(_benelli_shell_rig)
	_weapon_rigs.append(holder)
	_w_parts_by_idx.append(parts)
	var s_a: AudioStream = load(w["audio"]) if ResourceLoader.exists(w["audio"]) else null
	var s_b_path := str(w.get("audio_b", ""))
	var s_b: AudioStream = load(s_b_path) if (s_b_path != "" and ResourceLoader.exists(s_b_path)) else null
	_weapon_audio.append(s_a)
	var v_arr: Array[AudioStream] = []
	if s_a: v_arr.append(s_a)
	if s_b: v_arr.append(s_b)
	_weapon_audio_vars.append(v_arr)


func _prebuild_weapon_rigs() -> void:
	_weapon_rigs.clear()
	_w_parts_by_idx.clear()
	_weapon_audio.clear()
	_weapon_audio_vars.clear()
	_shotgun_shell_rig = null
	for i in range(WEAPONS.size()):
		_build_single_weapon_rig(i)


func prebuild_weapon_rigs_web_async(hud: BodycamHUD = null) -> void:
	_weapon_rigs.clear()
	_w_parts_by_idx.clear()
	_weapon_audio.clear()
	_weapon_audio_vars.clear()
	_shotgun_shell_rig = null
	var tree := get_tree()
	for i in range(WEAPONS.size()):
		if hud:
			hud.set_loading_status("BODYCAM-04 // PREPARING WEAPON RIGS (%d/%d)..." % [i + 1, WEAPONS.size()])
		_build_single_weapon_rig(i)
		await tree.process_frame
	_equip_weapon(0)


func _pose_part(grp: String, delta_pos: Vector3, delta_rot := Vector3.ZERO, pivot := Vector3.ZERO, is_vis := true) -> void:
	if not _w_parts.has(grp):
		return
	var rot_off := Vector3.ZERO
	if delta_rot != Vector3.ZERO and pivot != Vector3.ZERO:
		rot_off = pivot - Basis.from_euler(delta_rot) * pivot
	for p: Node3D in _w_parts[grp]:
		if is_instance_valid(p):
			var iid := p.get_instance_id()
			p.position = _w_rest_pos.get(iid, Vector3.ZERO) + delta_pos + rot_off
			p.rotation = _w_rest_rot.get(iid, Vector3.ZERO) + delta_rot
			p.visible = is_vis


func _move_part_group(grp: String, delta_pos: Vector3, delta_rot := Vector3.ZERO, is_vis := true) -> void:
	_pose_part(grp, delta_pos, delta_rot, Vector3.ZERO, is_vis)


func _pose_optic_hood(delta_pos: Vector3, delta_rot := Vector3.ZERO, pivot := Vector3.ZERO) -> void:
	if not is_instance_valid(optic_hood) or not optic_hood.visible:
		return
	if delta_rot != Vector3.ZERO and pivot != Vector3.ZERO:
		optic_hood.position = pivot + Basis.from_euler(delta_rot) * (_optic_rest_pos - pivot) + delta_pos
	else:
		optic_hood.position = _optic_rest_pos + delta_pos
	optic_hood.rotation = delta_rot


func _apply_idle_bolt_and_cover() -> void:
	if current_weapon == 0:
		var empty_g17 := ammo_in_mag[0] <= 0 or not weapon_chambered[0]
		var locked_back := 1.0 if empty_g17 else 0.0
		var slide_z := maxf(bolt_blowback, locked_back) * 0.034
		_pose_part("slide", Vector3(0.0, 0.0, slide_z))
		_pose_optic_hood(Vector3(0.0, 0.0, slide_z))
		_pose_part("slidestop", Vector3.ZERO, Vector3(-0.22 * locked_back, 0.0, 0.0), PIVOT_G17_SLIDESTOP)
		_pose_part("trigger", Vector3.ZERO, Vector3(-0.22 * clampf(bolt_blowback, 0.0, 1.0), 0.0, 0.0), PIVOT_G17_TRIGGER)
		_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, ammo_in_mag[0] > 0)
	elif current_weapon == 1:
		var locked_ar := 1.0 if (ammo_in_mag[1] <= 0 or not weapon_chambered[1]) else 0.0
		_pose_part("slide", Vector3(0.0, 0.0, maxf(bolt_blowback, locked_ar) * 0.052))
		_pose_part("dust_cover", Vector3.ZERO, Vector3.ZERO if (_m16_dust_open or locked_ar > 0.5) else Vector3(0.0, 0.0, 1.48), PIVOT_AR_DUST)
	elif current_weapon == 5:
		var locked_mp5 := 1.0 if (ammo_in_mag[5] <= 0 or not weapon_chambered[5]) else 0.0
		_pose_part("charge", Vector3(0.0, 0.0, locked_mp5 * 0.068), Vector3(0.0, 0.0, -locked_mp5 * 0.52))
	elif current_weapon == 6:
		_pose_part("speed_loader", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
	elif current_weapon == 7 or current_weapon == 14:
		_pose_part("feed_round", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
	elif current_weapon == 13:
		_pose_part("mag", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
	elif current_weapon == 15:
		_pose_part("bow_arrow", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, ammo_in_mag[15] > 0)
	elif current_weapon == 17:
		_pose_part("warhead", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, ammo_in_mag[17] > 0)


func _reset_weapon_parts() -> void:
	if is_instance_valid(_shotgun_shell_rig):
		_shotgun_shell_rig.visible = false
	if is_instance_valid(_benelli_shell_rig):
		_benelli_shell_rig.visible = false
	for grp in _w_parts.keys():
		var gs := str(grp)
		var hide_rest: bool = (gs == "speed_loader" or gs == "feed_round")
		for p: Node3D in _w_parts[grp]:
			if is_instance_valid(p):
				var iid := p.get_instance_id()
				p.position = _w_rest_pos.get(iid, Vector3.ZERO)
				p.rotation = _w_rest_rot.get(iid, Vector3.ZERO)
				p.visible = not hide_rest
	_pose_optic_hood(Vector3.ZERO)
	_apply_idle_bolt_and_cover()


func _equip_weapon(idx: int, force_preview: bool = false) -> void:
	if idx < 0 or idx >= WEAPONS.size():
		return
	if not force_preview and not unlocked_weapons[idx]:
		return
	# Pressing the already-equipped weapon's key never cancels an active reload or quick-melee!
	if not force_preview and idx == current_weapon and not _weapon_rigs.is_empty() and is_instance_valid(_weapon_rigs[idx]) and (_weapon_rigs[idx].visible or _quick_melee_active):
		return
	if current_weapon == 4:
		cancel_bow_draw(false)
	current_weapon = idx
	is_reloading = false
	_burst_remaining = 0
	_burst_timer = 0.0
	_quick_melee_active = false
	_melee_timer = 0.0
	_melee_hitstop_timer = 0.0
	_melee_charging = false
	_melee_charge = 0.0
	reload_cancel_req = false
	_shotgun_fire_on_cancel = false
	_fire_buffer_timer = 0.0
	reload_pos_off = Vector3.ZERO
	reload_rot_off = Vector3.ZERO
	shotgun_pump_timer = 0.0
	bolt_blowback = 0.0
	_bow_drawing = false
	_bow_draw = 0.0
	_bow_hold_time = 0.0
	_bow_release_timer = 0.0
	_bow_release_from_draw = 0.0
	if idx == 4 and ammo_in_mag[4] <= 0 and ammo_reserve[4] > 0:
		_bow_nock_timer = BOW_NOCK_DUR
		_bow_nock_sfx_played = false
	else:
		_bow_nock_timer = 0.0
		_bow_nock_sfx_played = false
	if idx != 16:
		_flame_firing_timer = 0.0
		_flame_emit_window = 0.0
		if sfx_flame_loop and sfx_flame_loop.playing:
			sfx_flame_loop.stop()
	if idx == 16:
		_ensure_flamer_pilot()
	_hunting_bolt_timer = 0.0
	_hunting_bolt_did_sfx = false
	_sniper_ads_raw = 0.0
	sniper_scope_alpha = 0.0
	sniper_iris_scale = 1.0
	if weapon_rig_holder:
		weapon_rig_holder.visible = true

	var w: Dictionary = WEAPONS[idx]
	for i in range(_weapon_rigs.size()):
		if is_instance_valid(_weapon_rigs[i]):
			_weapon_rigs[i].visible = (i == idx)
	_w_parts = _w_parts_by_idx[idx] if idx < _w_parts_by_idx.size() else {}
	_reset_weapon_parts()
	if idx == 4:
		_pose_bow_rig()

	var use_holo := bool(w["has_holo"]) or has_attachment(idx, "optic")
	var show_hood := has_attachment(idx, "optic") and not bool(w["has_holo"])
	var hpos: Vector3 = w.get("holo_pos", Vector3.ZERO)
	if hpos == Vector3.ZERO:
		hpos = Vector3(0.0, 0.072, -0.12)
	_optic_rest_pos = hpos
	holo_quad.visible = use_holo
	holo_quad.position = hpos
	if is_instance_valid(optic_hood):
		optic_hood.visible = show_hood
		optic_hood.position = hpos
		optic_hood.rotation = Vector3.ZERO
	if is_instance_valid(weapon_pivot) and get_tree() and get_tree().paused:
		weapon_pivot.position = w["hip_pos"]
		weapon_pivot.rotation = w["hip_rot"]
		is_ads = false
		_ads_blend = 0.0
		if camera:
			camera.fov = base_fov
	muzzle_light.position = w["muzzle"]
	muzzle_vm_light.position = w["muzzle"]
	muzzle_flash_rig.position = w["muzzle"]
	muzzle_smoke.position = w["muzzle"]
	if idx < _weapon_audio.size() and _weapon_audio[idx]:
		sfx_gun.stream = _weapon_audio[idx]
	emit_signal("weapon_changed", idx, w["name"])


func _fx_parent() -> Node:
	if game_manager and game_manager.zombies_root and game_manager.zombies_root.get_parent():
		return game_manager.zombies_root.get_parent()
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root


func _apply_deterministic_auto_iris() -> void:
	var flash_rim := 0.14 if muzzle_flash_timer > 0.0 else 0.0
	vm_rim.light_energy = (0.28 if is_ads else 0.22) + flash_rim
	camera.position.y = 0.065 if is_ads else 0.0
	camera.rotation.z = (-0.045 if is_ads else -0.061) + recoil_roll
	flashlight.light_volumetric_fog_energy = 0.18 if is_ads else 0.84
	var in_lit_lobby := global_position.z > -8.5
	var base_e := (145.0 if in_lit_lobby else 204.0) if is_ads else (26.0 if in_lit_lobby else 63.0)
	var on_snow := global_position.z < -28.3
	if on_snow and not is_ads:
		base_e = 8.6
	flashlight.spot_angle = 30.0 if is_ads else 58.0
	flashlight.spot_angle_attenuation = 0.52 if is_ads else 0.72
	flashlight.position = Vector3(0.09, -0.07, -0.44)
	flashlight.rotation.y = -0.043 if is_ads else 0.0
	flashlight.rotation.x = 0.063 if is_ads else (-0.74 if on_snow else -0.11)

	flashlight.light_color = Color(0.94, 0.96, 1.0)
	var nearest := 99.0
	var subject := Vector3.ZERO
	if game_manager and game_manager.zombies_root:
		var cam_pos := camera.global_position
		var fwd := -camera.global_transform.basis.z
		for z in game_manager.zombies_root.get_children():
			if z is ZombieAI and not z.dead:
				var v: Vector3 = (z.global_position + Vector3(0, 1.5, 0)) - cam_pos
				var d := v.length()
				if d < 4.5 and d > 0.2 and v.normalized().dot(fwd) > 0.35 and d < nearest:
					nearest = d
					subject = z.face_focus_position()

	var crowding := 0.0 if is_ads else (1.0 - smoothstep(1.1, 1.75, nearest))
	weapon_clearance.position = Vector3(0.022, -0.20, 0.05) * crowding
	weapon_clearance.rotation.x = -0.26 * crowding
	if nearest < 4.2:
		var t: float = clampf((nearest - 0.85) / 3.35, 0.0, 1.0)
		flashlight.light_energy = lerpf(0.24, base_e, t * t)
		flashlight.spot_angle = 57.0
		flashlight.rotation.x = 0.042
		if nearest < 2.2:
			flashlight.position = Vector3(-0.38, 0.25, -0.11)
			flashlight.look_at(subject, Vector3.UP)
			flashlight.light_color = Color(0.96, 0.96, 1.0)
			flashlight.light_energy *= 1.45
	else:
		flashlight.light_energy = base_e

	if game_manager and game_manager.hud and game_manager.hud.post_mat:
		if nearest < 2.4:
			var screen_point := camera.unproject_position(subject) / camera.get_viewport().get_visible_rect().size
			game_manager.hud.post_mat.set_shader_parameter("focus_uv", screen_point)
		game_manager.hud.post_mat.set_shader_parameter("near_focus", 1.0 - smoothstep(1.1, 2.4, nearest))
	if cam_attrs:
		cam_attrs.auto_exposure_enabled = false
		cam_attrs.exposure_multiplier = 1.0
		if nearest < 2.0:
			cam_attrs.dof_blur_far_enabled = true
			cam_attrs.dof_blur_far_distance = camera.global_position.distance_to(subject) + 0.16
			cam_attrs.dof_blur_far_transition = 1.0
			cam_attrs.dof_blur_amount = 0.014
		else:
			cam_attrs.dof_blur_far_enabled = false


func _update_flashlight_and_iris(delta: float) -> void:
	if deterministic_camera:
		_apply_deterministic_auto_iris()
		return

	var k := 1.0 - exp(-delta * 10.0)
	_ads_blend = lerpf(_ads_blend, 1.0 if is_ads else 0.0, 1.0 - exp(-delta * 14.0))
	camera.position.y = lerpf(0.0, 0.065, _ads_blend)

	var flash_rim := 0.14 if muzzle_elapsed < 0.05 else 0.0
	var base_rim := 0.46 if is_reloading else lerpf(0.22, 0.28, _ads_blend)
	vm_rim.light_energy = lerpf(vm_rim.light_energy, base_rim + flash_rim, k)
	var rim_pos_tgt := Vector3(-0.22, -0.06, -0.02) if is_reloading else Vector3(-0.24, 0.15, -0.04)
	vm_rim.position = vm_rim.position.lerp(rim_pos_tgt, k)
	if dust_motes:
		dust_motes.emitting = (global_position.z > -26.5)

	# Smooth zone transition weights (zero hard snaps at Z thresholds!)
	var tunnel_w := smoothstep(-6.5, -10.5, global_position.z) * (1.0 - smoothstep(-26.5, -30.5, global_position.z))
	var snow_w := smoothstep(-26.5, -30.5, global_position.z)
	var hip_e := lerpf(28.0, 52.0, tunnel_w)
	hip_e = lerpf(hip_e, 34.0, snow_w)
	var ads_e := lerpf(72.0, 118.0, tunnel_w)
	ads_e = lerpf(ads_e, 78.0, snow_w)
	var target_e := lerpf(hip_e, ads_e, _ads_blend)

	# Forward beam raycast for subtle bodycam exposure pump + physical wall bounce light
	var space := get_world_3d().direct_space_state
	var hit_dim := 1.0
	var beam_hit := {}
	if space and flashlight_on:
		var orig := camera.global_position
		var fwd := -camera.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(orig, orig + fwd * 12.0, 1 | 4)
		q.exclude = [get_rid()]
		beam_hit = space.intersect_ray(q)
		if beam_hit:
			var dist := orig.distance_to(beam_hit["position"])
			if dist < 2.8:
				hit_dim = lerpf(0.55, 1.0, smoothstep(0.65, 2.8, dist))

	_iris_wall_dim = lerpf(_iris_wall_dim, hit_dim, 1.0 - exp(-delta * 8.0))
	if cam_attrs:
		var exp_tgt := lerpf(0.84, 1.06, _iris_wall_dim)
		cam_attrs.exposure_multiplier = lerpf(cam_attrs.exposure_multiplier, exp_tgt, 1.0 - exp(-delta * 6.5))
	if flashlight.position.distance_squared_to(Vector3(0.09, -0.07, -0.44)) > 1e-6:
		flashlight.position = Vector3(0.09, -0.07, -0.44)
	var frot := Vector3(lerpf(-0.10, 0.04, _ads_blend), lerpf(0.0, -0.025, _ads_blend), 0.0)
	if flashlight.rotation.distance_squared_to(frot) > 1e-6:
		flashlight.rotation = frot
	var sang := lerpf(55.0, 32.0, _ads_blend)
	if absf(flashlight.spot_angle - sang) > 0.02:
		flashlight.spot_angle = sang
	var satt := lerpf(0.68, 0.52, _ads_blend)
	if absf(flashlight.spot_angle_attenuation - satt) > 0.002:
		flashlight.spot_angle_attenuation = satt
	var vfog_e := lerpf(0.72, 0.28, _ads_blend)
	if absf(flashlight.light_volumetric_fog_energy - vfog_e) > 0.002:
		flashlight.light_volumetric_fog_energy = vfog_e
	var fcol := Color(0.95, 0.97, 1.0).lerp(Color(1.0, 0.72, 0.40), _flash_shadow_boost * 0.75)
	if not flashlight.light_color.is_equal_approx(fcol):
		flashlight.light_color = fcol
	var fe := target_e * _iris_wall_dim * (1.0 + 0.28 * _flash_shadow_boost)
	if absf(flashlight.light_energy - fe) > 0.02:
		flashlight.light_energy = fe
	_update_flashlight_bounce(beam_hit, fe, k)
	var show_cone := _should_show_flashlight_cone()
	if flashlight_cone.visible != show_cone:
		flashlight_cone.visible = show_cone

	# Keep live zombies' crowding subtle weapon clearance without teleporting flashlight!
	var nearest := 99.0
	if game_manager and game_manager.zombies_root:
		var cam_pos := camera.global_position
		var fwd := -camera.global_transform.basis.z
		for z in game_manager.zombies_root.get_children():
			var zb := z as ZombieAI
			if zb and not zb.dead and zb.state != ZombieAI.State.SPAWNING:
				var d: float = zb.global_position.distance_to(cam_pos)
				if d < 2.2 and v_dot(zb.global_position - cam_pos, fwd) > 0.35:
					nearest = minf(nearest, d)
	var crowding := 0.0 if is_ads else (1.0 - smoothstep(0.95, 1.45, nearest))
	var cp := Vector3(0.015, -0.14, 0.06) * crowding
	if weapon_clearance.position.distance_squared_to(cp) > 1e-6:
		weapon_clearance.position = weapon_clearance.position.lerp(cp, k)
	var crx := -0.18 * crowding
	if absf(weapon_clearance.rotation.x - crx) > 0.001:
		weapon_clearance.rotation.x = lerpf(weapon_clearance.rotation.x, crx, k)

	if game_manager and game_manager.hud and game_manager.hud.post_mat and absf(_last_near_focus) > 0.001:
		_last_near_focus = 0.0
		game_manager.hud.post_mat.set_shader_parameter("near_focus", 0.0)
	if cam_attrs:
		if not cam_attrs.auto_exposure_enabled and RenderingServer.get_current_rendering_method() != "gl_compatibility":
			cam_attrs.auto_exposure_enabled = true
		if cam_attrs.dof_blur_far_enabled:
			cam_attrs.dof_blur_far_enabled = false


func v_dot(v: Vector3, fwd: Vector3) -> float:
	return v.normalized().dot(fwd) if v.length_squared() > 0.001 else 0.0


func get_current_weapon_name() -> String:
	if current_weapon == 3:
		var m: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
		return str(m["name"])
	var base := str(WEAPONS[current_weapon]["name"])
	var tags: Array[String] = []
	if is_weapon_upgraded(current_weapon):
		tags.append("MK-II")
	if has_attachment(current_weapon, "optic"):
		tags.append("RDS")
	if has_attachment(current_weapon, "suppressor"):
		tags.append("SD")
	if has_attachment(current_weapon, "ext_mag") and not is_weapon_upgraded(current_weapon):
		tags.append("EXT")
	return base if tags.is_empty() else ("%s [%s]" % [base, "+".join(tags)])


func has_attachment(idx: int, mod_key: String) -> bool:
	if not weapon_attachments.has(idx):
		return false
	return bool((weapon_attachments[idx] as Dictionary).get(mod_key, false))


func add_attachment(idx: int, mod_key: String) -> void:
	if idx < 0 or idx >= WEAPONS.size():
		return
	if not weapon_attachments.has(idx):
		weapon_attachments[idx] = {}
	(weapon_attachments[idx] as Dictionary)[mod_key] = true
	if mod_key == "ext_mag":
		ammo_in_mag[idx] = get_weapon_mag_size(idx)
	if idx == current_weapon:
		var w: Dictionary = WEAPONS[idx]
		var use_holo := bool(w["has_holo"]) or has_attachment(idx, "optic")
		var show_hood := has_attachment(idx, "optic") and not bool(w["has_holo"])
		var hpos: Vector3 = w.get("holo_pos", Vector3.ZERO)
		if hpos == Vector3.ZERO:
			hpos = Vector3(0.0, 0.072, -0.12)
		_optic_rest_pos = hpos
		holo_quad.visible = use_holo
		holo_quad.position = hpos
		if is_instance_valid(optic_hood):
			optic_hood.visible = show_hood
			optic_hood.position = hpos
			optic_hood.rotation = Vector3.ZERO


func is_no_refill_weapon(idx: int) -> bool:
	if idx < 0 or idx >= WEAPONS.size():
		return false
	return bool(WEAPONS[idx].get("no_ammo_refill", false))


func get_weapon_mag_size(idx: int) -> int:
	if idx < 0 or idx >= WEAPONS.size():
		return 1
	var base := int(WEAPONS[idx]["mag_size"])
	if bool(WEAPONS[idx].get("is_bow", false)) or bool(WEAPONS[idx].get("is_melee", false)) or bool(WEAPONS[idx].get("is_crossbow", false)) or bool(WEAPONS[idx].get("is_rpg", false)) or bool(WEAPONS[idx].get("is_flamethrower", false)) or idx == 6 or idx == 11:
		return base
	if is_weapon_upgraded(idx) or has_attachment(idx, "ext_mag"):
		return maxi(base + 2, int(round(float(base) * 1.45)))
	return base


func is_weapon_upgraded(idx: int) -> bool:
	return idx >= 0 and idx < upgraded_weapons.size() and upgraded_weapons[idx]


func upgrade_weapon(idx: int) -> void:
	if idx < 0 or idx >= WEAPONS.size():
		return
	upgraded_weapons[idx] = true
	if not is_no_refill_weapon(idx):
		ammo_in_mag[idx] = get_weapon_mag_size(idx)
		ammo_reserve[idx] = int(WEAPONS[idx]["reserve_max"])
		weapon_chambered[idx] = true


func _sync_unlocked_from_loadout() -> void:
	for i in range(unlocked_weapons.size()):
		unlocked_weapons[i] = false
	for idx: int in firearm_slots:
		if idx >= 0 and idx < unlocked_weapons.size():
			unlocked_weapons[idx] = true
	if special_slot >= 0 and special_slot < unlocked_weapons.size():
		unlocked_weapons[special_slot] = true
	unlocked_weapons[3] = (equipped_melee_id != "")


func get_slot_key_for_weapon(idx: int) -> String:
	if idx == 3:
		return "5"
	if idx == special_slot and special_slot >= 0:
		return "4"
	var pos := firearm_slots.find(idx)
	if pos >= 0:
		return str(pos + 1)
	return str(WEAPONS[idx].get("key", "?"))


func get_claim_prompt_label(idx: int) -> String:
	if idx < 0 or idx >= WEAPONS.size():
		return "[E] CLAIM WEAPON"
	var wname := str(WEAPONS[idx]["name"])
	if bool(WEAPONS[idx].get("is_special", false)):
		if special_slot >= 0 and special_slot != idx:
			return "[E] SWAP [4] %s -> %s" % [WEAPONS[special_slot]["name"], wname]
		return "[E] CLAIM [4] %s (SPECIAL)" % wname
	if firearm_slots.has(idx):
		return "[E] REFILL [%d] %s" % [firearm_slots.find(idx) + 1, wname]
	if firearm_slots.size() < MAX_FIREARM_SLOTS:
		return "[E] CLAIM [%d] %s" % [firearm_slots.size() + 1, wname]
	var rep_slot := firearm_slots.find(current_weapon)
	if rep_slot < 0:
		rep_slot = MAX_FIREARM_SLOTS - 1
	var old_idx := firearm_slots[rep_slot]
	return "[E] SWAP [%d] %s -> %s" % [rep_slot + 1, WEAPONS[old_idx]["name"], wname]


func acquire_weapon(idx: int, equip_now: bool = true) -> Dictionary:
	if idx < 0 or idx >= WEAPONS.size() or idx == 3:
		return {"ok": false}
	var is_spec := bool(WEAPONS[idx].get("is_special", false))
	var slot_key := ""
	var replaced := -1
	if is_spec:
		if special_slot >= 0 and special_slot != idx:
			replaced = special_slot
		special_slot = idx
		slot_key = "4"
	else:
		var existing := firearm_slots.find(idx)
		if existing >= 0:
			slot_key = str(existing + 1)
		elif firearm_slots.size() < MAX_FIREARM_SLOTS:
			firearm_slots.append(idx)
			slot_key = str(firearm_slots.size())
		else:
			var rep_slot := firearm_slots.find(current_weapon)
			if rep_slot < 0:
				rep_slot = MAX_FIREARM_SLOTS - 1
			replaced = firearm_slots[rep_slot]
			firearm_slots[rep_slot] = idx
			slot_key = str(rep_slot + 1)
	if replaced >= 0 and replaced < upgraded_weapons.size():
		upgraded_weapons[replaced] = false
		weapon_attachments.erase(replaced)
	_sync_unlocked_from_loadout()
	ammo_in_mag[idx] = get_weapon_mag_size(idx)
	ammo_reserve[idx] = int(WEAPONS[idx]["reserve_max"])
	weapon_chambered[idx] = true
	if equip_now or replaced == current_weapon:
		_equip_weapon(idx, true)
	return {"ok": true, "slot_key": slot_key, "replaced": replaced}


func swap_firearm_slots(a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= firearm_slots.size() or b >= firearm_slots.size() or a == b:
		return false
	var tmp := firearm_slots[a]
	firearm_slots[a] = firearm_slots[b]
	firearm_slots[b] = tmp
	return true


func drop_firearm_slot(slot_idx: int) -> bool:
	if firearm_slots.size() <= 1 or slot_idx < 0 or slot_idx >= firearm_slots.size():
		return false
	var removed := firearm_slots[slot_idx]
	firearm_slots.remove_at(slot_idx)
	if removed >= 0 and removed < upgraded_weapons.size():
		upgraded_weapons[removed] = false
		weapon_attachments.erase(removed)
	_sync_unlocked_from_loadout()
	if current_weapon == removed and not firearm_slots.is_empty():
		_equip_weapon(firearm_slots[0], true)
	return true


func equip_firearm_slot(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < firearm_slots.size():
		_equip_weapon(firearm_slots[slot_idx], false)


func equip_special_slot() -> void:
	if special_slot >= 0:
		_equip_weapon(special_slot, false)


func equip_melee_slot() -> void:
	if equipped_melee_id != "":
		_equip_weapon(3, false)


func unlock_weapon_silent(idx: int) -> void:
	acquire_weapon(idx, false)


func acquire_melee_weapon(m_id: String) -> void:
	if not MELEE_CATALOG.has(m_id):
		return
	# Never downgrade Spiked Baseball Bat back to plain Bat, and replace plain Bat in owned_melee when upgrading!
	if m_id == "bat" and owned_melee.has("bat_spiked"):
		select_melee_weapon("bat_spiked")
		return
	if m_id == "bat_spiked":
		var bi := owned_melee.find("bat")
		if bi >= 0:
			owned_melee[bi] = "bat_spiked"
		elif not owned_melee.has("bat_spiked"):
			owned_melee.append("bat_spiked")
	elif not owned_melee.has(m_id):
		owned_melee.append(m_id)
	select_melee_weapon(m_id)


func select_melee_weapon(m_id: String) -> void:
	if m_id == "":
		equipped_melee_id = ""
		_sync_unlocked_from_loadout()
		if current_weapon == 3 and not firearm_slots.is_empty():
			_equip_weapon(firearm_slots[0], true)
		return
	if not MELEE_CATALOG.has(m_id):
		return
	if not owned_melee.has(m_id):
		owned_melee.append(m_id)
	equipped_melee_id = m_id
	for k in _melee_nodes.keys():
		if is_instance_valid(_melee_nodes[k]):
			(_melee_nodes[k] as Node3D).visible = (str(k) == m_id)
	_sync_unlocked_from_loadout()


func unlock_and_equip(idx: int) -> void:
	acquire_weapon(idx, true)


func dev_give_all_ammo_and_grenades() -> void:
	for idx: int in firearm_slots:
		ammo_in_mag[idx] = get_weapon_mag_size(idx)
		ammo_reserve[idx] = int(WEAPONS[idx]["reserve_max"])
		weapon_chambered[idx] = true
	if special_slot >= 0:
		ammo_in_mag[special_slot] = get_weapon_mag_size(special_slot)
		ammo_reserve[special_slot] = int(WEAPONS[special_slot]["reserve_max"])
		weapon_chambered[special_slot] = true
	grenade_counts["frag"] = maxi(int(grenade_counts.get("frag", 0)), 4)
	grenade_counts["molotov"] = maxi(int(grenade_counts.get("molotov", 0)), 3)
	grenade_counts["shock"] = maxi(int(grenade_counts.get("shock", 0)), 3)


func _weapon_short_label(wi: int) -> String:
	const SHORT_MAP := {
		0: "G17", 1: "M16A2", 2: "M870", 3: "MELEE", 4: "BOW", 5: "MP5",
		6: ".44", 7: "M1903", 8: "AK-74", 9: "BENELLI", 10: "M249",
		11: "SAWED", 12: "FAMAS", 13: "GARAND", 14: "KAR98K", 15: "XBOW", 16: "FLAMER", 17: "RPG-7",
	}
	return str(SHORT_MAP.get(wi, str(WEAPONS[wi]["name"]).split(" ")[0]))


func get_hotbar_summary() -> String:
	var parts: Array[String] = []
	for i in range(MAX_FIREARM_SLOTS):
		if i < firearm_slots.size():
			var wi := firearm_slots[i]
			var short_nm := _weapon_short_label(wi)
			var mark := "*" if wi == current_weapon else ""
			parts.append("[%d]%s%s" % [i + 1, mark, short_nm])
		else:
			parts.append("[%d]---" % (i + 1))
	if special_slot >= 0:
		var snm := _weapon_short_label(special_slot)
		parts.append("[4]%s%s" % ["*" if special_slot == current_weapon else "", snm])
	var m_lbl := "SPIKED" if equipped_melee_id == "bat_spiked" else (str(MELEE_CATALOG[equipped_melee_id]["name"]).split(" ")[-1] if (equipped_melee_id != "" and MELEE_CATALOG.has(equipped_melee_id)) else "BASH")
	parts.append("[V]%s" % m_lbl)
	var g_lbl: String = str(GRENADE_LABELS.get(equipped_grenade, "FRAG"))
	var g_cnt: int = int(grenade_counts.get(equipped_grenade, 0))
	parts.append("[G]%s:%d" % [g_lbl, g_cnt])
	return "  ".join(parts)


func cycle_grenade() -> void:
	var idx := GRENADE_ORDER.find(equipped_grenade)
	for step in range(1, GRENADE_ORDER.size() + 1):
		var cand: String = GRENADE_ORDER[(idx + step) % GRENADE_ORDER.size()]
		if int(grenade_counts.get(cand, 0)) > 0 or step == GRENADE_ORDER.size():
			equipped_grenade = cand
			emit_signal("status_message", "THROWABLE: %s (%d) [G TO THROW]" % [GRENADE_LABELS[cand], int(grenade_counts.get(cand, 0))])
			return


func select_grenade(g_type: String) -> void:
	if GRENADE_LABELS.has(g_type):
		equipped_grenade = g_type


func add_grenade(g_type: String, count: int = 1) -> void:
	if GRENADE_LABELS.has(g_type):
		grenade_counts[g_type] = mini(6, int(grenade_counts.get(g_type, 0)) + count)


func cancel_bow_draw(require_repull: bool = false) -> void:
	if _bow_drawing:
		_bow_drawing = false
		_bow_draw = 0.0
		_bow_hold_time = 0.0
		if sfx_bow_draw and sfx_bow_draw.playing:
			sfx_bow_draw.stop()
	if require_repull:
		_bow_require_repull = true


func _finish_reload() -> void:
	if not is_reloading:
		return
	_commit_mag_ammo()
	weapon_chambered[current_weapon] = true
	is_reloading = false
	reload_cancel_req = false
	_shotgun_fire_on_cancel = false
	reload_pos_off = Vector3.ZERO
	reload_rot_off = Vector3.ZERO
	_reset_weapon_parts()


func _cycle_owned_weapon(dir: int) -> void:
	var owned: Array[int] = []
	for idx: int in firearm_slots:
		owned.append(idx)
	if special_slot >= 0:
		owned.append(special_slot)
	if equipped_melee_id != "":
		owned.append(3)
	if owned.size() <= 1:
		return
	var pos := owned.find(current_weapon)
	if pos < 0:
		_equip_weapon(owned[0])
		return
	_equip_weapon(owned[(pos + dir + owned.size()) % owned.size()])


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or dead or deterministic_camera:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sens * (0.35 if (current_weapon == 7 and sniper_scope_alpha > 0.5) else (ads_sens_mult if is_ads else 1.0))
		if grabbed_by != null:
			sens *= 0.55
		var dx: float = -event.relative.x * sens
		var dy: float = -event.relative.y * sens * (-1.0 if invert_y else 1.0)
		yaw += dx
		pitch = clamp(pitch + dy, -1.35, 1.35)
		sway_offset.x = clamp(sway_offset.x + dx * 2.5, -0.065, 0.065)
		sway_offset.y = clamp(sway_offset.y + dy * 2.5, -0.055, 0.055)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: equip_firearm_slot(0)
			KEY_2: equip_firearm_slot(1)
			KEY_3: equip_firearm_slot(2)
			KEY_4: equip_special_slot()
			KEY_5: equip_melee_slot()
			KEY_G: throw_grenade()
			KEY_Q: cycle_grenade()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_owned_weapon(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_owned_weapon(-1)


func _should_show_flashlight_cone() -> bool:
	if not flashlight_on:
		return false
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return true
	if game_manager and game_manager.world:
		return not game_manager.world.user_vol_fog_enabled
	return false


func _surface_bounce_color(surf: String) -> Color:
	match surf:
		"brick":
			return Color(1.0, 0.68, 0.48)
		"snow":
			return Color(0.76, 0.86, 1.0)
		"wood":
			return Color(0.98, 0.80, 0.56)
		"mud":
			return Color(0.68, 0.62, 0.54)
		_:
			return Color(0.92, 0.88, 0.82)


func _update_flashlight_bounce(hit: Dictionary, flash_e: float, k: float) -> void:
	if flashlight_bounce == null:
		return
	if not flashlight_on or RenderingServer.get_current_rendering_method() == "gl_compatibility" or hit.is_empty():
		flashlight_bounce.light_energy = lerpf(flashlight_bounce.light_energy, 0.0, k)
		if flashlight_bounce.light_energy < 0.01:
			flashlight_bounce.visible = false
		return
	var hpos := hit["position"] as Vector3
	var hnrm := hit["normal"] as Vector3
	var dist := camera.global_position.distance_to(hpos)
	var pos := hpos + hnrm * 0.34
	var col_node = hit.get("collider")
	var surf := str(col_node.get_meta(&"surface", "")) if (col_node != null and col_node is Object and (col_node as Object).has_meta(&"surface")) else ""
	var tgt_col := _surface_bounce_color(surf)
	var tgt_e := clampf(flash_e / (1.0 + dist * dist * 0.42), 0.0, 2.4) * 0.34
	if not flashlight_bounce.visible:
		flashlight_bounce.global_position = pos
		flashlight_bounce.light_color = tgt_col
		flashlight_bounce.light_energy = tgt_e * 0.5
		flashlight_bounce.visible = true
	else:
		flashlight_bounce.global_position = flashlight_bounce.global_position.lerp(pos, k)
		flashlight_bounce.light_color = flashlight_bounce.light_color.lerp(tgt_col, k)
		flashlight_bounce.light_energy = lerpf(flashlight_bounce.light_energy, tgt_e, k)


func set_deterministic_view(pos: Vector3, look_yaw: float, look_pitch: float, weapon_idx: int,
		ads_state: bool, light_state: bool, flash_energy := 0.0) -> void:
	deterministic_camera = true
	global_position = pos
	yaw = look_yaw
	pitch = look_pitch
	rotation.y = yaw
	head.rotation = Vector3(pitch, 0.0, 0.0)
	_equip_weapon(weapon_idx, true)
	is_ads = ads_state
	_ads_blend = 1.0 if ads_state else 0.0
	_sniper_ads_raw = 1.0 if (ads_state and current_weapon == 7) else 0.0
	sniper_scope_alpha = 1.0 if (ads_state and current_weapon == 7) else 0.0
	sniper_iris_scale = 1.0
	if weapon_rig_holder:
		weapon_rig_holder.visible = not (current_weapon == 7 and sniper_scope_alpha >= 0.92)
	flashlight_on = light_state
	flashlight.visible = flashlight_on
	flashlight_spill.visible = false
	flashlight_cone.visible = _should_show_flashlight_cone()
	if flashlight_bounce and not flashlight_on:
		flashlight_bounce.visible = false
		flashlight_bounce.light_energy = 0.0
	var w: Dictionary = WEAPONS[current_weapon]
	var ads_p_eff: Vector3 = w["ads_pos"] as Vector3
	var has_added_optic := has_attachment(current_weapon, "optic") and not bool(w["has_holo"])
	if has_added_optic and is_instance_valid(holo_quad):
		ads_p_eff = Vector3(-holo_quad.position.x, -holo_quad.position.y, ads_p_eff.z)
	weapon_pivot.position = ads_p_eff if is_ads else w["hip_pos"]
	weapon_pivot.rotation = w["ads_rot"] if is_ads else w["hip_rot"]
	camera.fov = float(w.get("ads_fov", 60.5)) if is_ads else base_fov
	muzzle_light.light_energy = flash_energy
	muzzle_light.visible = flash_energy > 0.05
	muzzle_vm_light.light_energy = minf(flash_energy * 0.45, 1.4)
	muzzle_vm_light.visible = flash_energy > 0.05
	muzzle_flash_timer = 0.025 if flash_energy > 0.1 else 0.0
	muzzle_flash_rig.visible = flash_energy > 0.1
	for fm in _flash_mats:
		fm.set_shader_parameter("cool_t", 0.0)
	if flash_energy > 0.1:
		var fs: float = w["flash_scale"]
		muzzle_flash_rig.scale = Vector3.ONE * fs
	damage_flash = 0.0
	_apply_deterministic_auto_iris()
	if game_manager and game_manager.world:
		game_manager.world.update_zone_culling(camera)


func _update_casings(delta: float) -> void:
	var i := _casings.size() - 1
	while i >= 0:
		var c: Dictionary = _casings[i]
		c["age"] += delta
		var mi: MeshInstance3D = c["node"]
		var max_age := 3.2 if bool(c.get("is_mag", false)) else 2.4
		if c["age"] > max_age or not is_instance_valid(mi):
			if is_instance_valid(mi):
				mi.queue_free()
			_casings.remove_at(i)
			i -= 1
			continue
		var vel: Vector3 = c["vel"]
		vel.y -= 13.5 * delta
		mi.global_position += vel * delta
		mi.rotation += (c["ang"] as Vector3) * delta
		var floor_y: float = float(c.get("floor_y", global_position.y + 0.012))
		if mi.global_position.y <= floor_y:
			mi.global_position.y = floor_y
			if not c["bounced"]:
				c["bounced"] = true
				vel.y = absf(vel.y) * (0.24 if bool(c.get("is_mag", false)) else 0.34)
				vel.x *= 0.55
				vel.z *= 0.55
				c["ang"] = (c["ang"] as Vector3) * 0.35
				if sfx_casing and not _sfx_shell_clink.is_empty():
					sfx_casing.stream = _sfx_shell_clink[randi() % _sfx_shell_clink.size()]
					if bool(c.get("is_mag", false)):
						sfx_casing.pitch_scale = randf_range(0.54, 0.68)
					else:
						sfx_casing.pitch_scale = randf_range(0.76, 0.92) if bool(c.get("is_hull", false)) else randf_range(0.92, 1.16)
					sfx_casing.play()
			else:
				vel = Vector3.ZERO
				c["ang"] = Vector3.ZERO
		c["vel"] = vel
		i -= 1


func _play_surface_footstep(is_land := false) -> void:
	if sfx_step == null or sfx_step.stream == null:
		return
	var surf := "wood"
	if global_position.z < -28.0:
		surf = "snow"
	elif global_position.z < -8.0:
		surf = "stone"
	var space := get_world_3d().direct_space_state
	if space:
		var fq := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.25, 0), global_position + Vector3(0, -0.55, 0), 1)
		fq.exclude = [get_rid()]
		var fhit := space.intersect_ray(fq)
		if fhit and fhit.has("collider"):
			var c = fhit["collider"]
			if c is Object and (c as Object).has_meta(&"surface"):
				surf = str((c as Object).get_meta(&"surface"))
	var base_pitch := 1.0
	var base_vol := -10.5
	match surf:
		"snow":
			base_pitch = 0.78
			base_vol = -12.0
		"stone", "brick", "tile":
			base_pitch = 1.14
			base_vol = -9.5
		"metal":
			base_pitch = 1.28
			base_vol = -9.0
		_:
			base_pitch = 0.96
			base_vol = -10.5
	if is_land:
		base_pitch *= 0.84
		base_vol += 2.5
	elif is_crouching:
		base_pitch *= 0.88
		base_vol -= 3.5
	sfx_step.volume_db = base_vol
	sfx_step.pitch_scale = base_pitch * randf_range(0.90, 1.10)
	sfx_step.play()


func _physics_process(delta: float) -> void:
	_update_casings(delta)
	_update_arrows(delta)
	_update_grenades(delta)
	_update_hazards(delta)
	_update_flame_jets(delta)
	_update_flame_embers(delta)
	_update_flamethrower_audio_and_pilot(delta)
	_update_rockets(delta)
	if _flame_pool_cd > 0.0:
		_flame_pool_cd = maxf(0.0, _flame_pool_cd - delta)
	if _flame_hit_tick_cd > 0.0:
		_flame_hit_tick_cd = maxf(0.0, _flame_hit_tick_cd - delta)
	if _grenade_cd > 0.0:
		_grenade_cd = maxf(0.0, _grenade_cd - delta)
	if _melee_combo_reset > 0.0:
		_melee_combo_reset = maxf(0.0, _melee_combo_reset - delta)
		if _melee_combo_reset <= 0.0:
			_melee_combo_idx = 0
	if _shove_cd > 0.0:
		_shove_cd = maxf(0.0, _shove_cd - delta)
	if grab_immunity > 0.0:
		grab_immunity = maxf(0.0, grab_immunity - delta)
	if slow_timer > 0.0:
		slow_timer = maxf(0.0, slow_timer - delta)
		if slow_timer <= 0.0:
			slow_mult = 1.0
	_spread_bloom = maxf(0.0, _spread_bloom - delta * 2.6)
	if deterministic_camera or dead or not input_enabled:
		return

	# Regenerating health: 5 s after the last hit, recover steadily (never while a zombie has hold of you)
	if regen_delay > 0.0:
		regen_delay = maxf(0.0, regen_delay - delta)
	elif health < max_health and grabbed_by == null:
		health = minf(max_health, health + (18.0 if perks.has("adrenal") else 13.0) * delta)
	_update_grab(delta)

	is_crouching = Input.is_action_pressed("crouch")
	if ads_lockout > 0.0:
		ads_lockout -= delta
	var holding_melee := bool(WEAPONS[current_weapon].get("is_melee", false))
	var can_ads := not holding_melee and not _quick_melee_active
	is_ads = can_ads and Input.is_action_pressed("aim") and not is_reloading and ads_lockout <= 0.0
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and not is_ads and not is_reloading and _burst_remaining <= 0 and iv.length() > 0.1 and iv.y < 0.35 and grabbed_by == null and not _melee_charging
	if is_sprinting and _bow_drawing:
		cancel_bow_draw(true)

	var basis_fwd := -global_transform.basis.z
	var basis_right := global_transform.basis.x
	var move_dir := (basis_right * iv.x - basis_fwd * iv.y).normalized()
	var spd := 2.4 if is_crouching else (6.2 if is_sprinting else (2.7 if is_ads else 4.1))
	if holding_melee and not is_crouching:
		spd *= 1.06
	if is_sprinting and perks.has("adrenal"):
		spd *= 1.10
	if _melee_charging:
		spd *= 0.62
	if grabbed_by != null:
		spd *= 0.16
	spd *= slow_mult

	var accel := 10.5 if is_on_floor() else 3.2
	velocity.x = lerp(velocity.x, move_dir.x * spd, delta * accel)
	velocity.z = lerp(velocity.z, move_dir.z * spd, delta * accel)
	if _melee_lunge_timer > 0.0:
		_melee_lunge_timer = maxf(0.0, _melee_lunge_timer - delta)
		velocity.x += _melee_lunge_vel.x
		velocity.z += _melee_lunge_vel.z
	if _ext_vel.length_squared() > 0.01:
		velocity.x += _ext_vel.x
		velocity.z += _ext_vel.z
		_ext_vel = _ext_vel.lerp(Vector3.ZERO, minf(1.0, delta * 7.5))
	else:
		_ext_vel = Vector3.ZERO

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = 0.12
	elif _jump_buffer > 0.0:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
		_pre_land_vy = minf(_pre_land_vy, velocity.y)
		_was_on_floor = false
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
	else:
		if not _was_on_floor and _pre_land_vy < -2.2:
			var imp := clampf(-_pre_land_vy / 9.5, 0.08, 0.42)
			trauma = minf(1.0, trauma + imp * 0.45)
			_land_dip = minf(0.11, imp * 0.16)
			_play_surface_footstep(true)
		_was_on_floor = true
		_pre_land_vy = 0.0
		velocity.y = 0.0
		_coyote_timer = 0.11
	# Buffered jump with coyote time: a press slightly early or slightly late still jumps
	if _jump_buffer > 0.0 and _coyote_timer > 0.0 and grabbed_by == null:
		_jump_buffer = 0.0
		_coyote_timer = 0.0
		velocity.y = 5.4
		floor_snap_length = 0.0
	elif is_on_floor() and velocity.y <= 0.0:
		floor_snap_length = 0.45

	move_and_slide()

	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()
	if Input.is_action_just_pressed("reload"):
		start_reload()
	if Input.is_action_just_pressed("melee"):
		if grabbed_by != null:
			struggle_against_grab()
		elif holding_melee:
			trigger_shove()
		else:
			trigger_melee()

	_update_melee_swing(delta)

	# Single authoritative simulation clock for reloads + firing + shell-cancel!
	if is_reloading:
		_update_reload(delta)

	if _burst_remaining > 0 and not is_reloading and not dead and _melee_timer <= 0.0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_remaining -= 1
			if ammo_in_mag[current_weapon] > 0:
				fire_weapon(true)
				if _burst_remaining > 0:
					_burst_timer = float(WEAPONS[current_weapon].get("burst_interval", 0.058))
			else:
				_burst_remaining = 0
	if fire_cd > 0.0:
		fire_cd -= delta
	if _fire_buffer_timer > 0.0:
		_fire_buffer_timer = maxf(0.0, _fire_buffer_timer - delta)

	var w: Dictionary = WEAPONS[current_weapon]
	var is_auto := bool(w["auto"])
	var just_fire := Input.is_action_just_pressed("fire")
	if just_fire and not is_auto and not bool(w.get("is_bow", false)):
		_fire_buffer_timer = 0.22
	var wants_fire := Input.is_action_pressed("fire") if is_auto else (just_fire or _fire_buffer_timer > 0.0)
	if bool(w.get("is_melee", false)):
		# LMB (held) chains the light combo; RMB is hold-to-charge, release-to-swing for the heavy move
		if _melee_charging:
			var m_ch: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
			_melee_charge = minf(1.0, _melee_charge + delta / maxf(float(m_ch.get("charge", 0.45)), 0.05))
			if not Input.is_action_pressed("aim"):
				_melee_charging = false
				trigger_melee(true)
		elif Input.is_action_just_pressed("aim") and _melee_timer <= 0.10 and grabbed_by == null:
			_melee_charging = true
			_melee_charge = 0.0
		elif wants_fire or Input.is_action_pressed("fire"):
			if grabbed_by != null:
				if just_fire:
					struggle_against_grab()
			else:
				trigger_melee(false)
			_fire_buffer_timer = 0.0
		wants_fire = false
	elif _melee_charging:
		_melee_charging = false
		_melee_charge = 0.0
	if bool(w.get("is_bow", false)):
		_update_bow_input(delta)
		wants_fire = false
	# Interruptible shell/round-by-round reload cancel for M870 (2), Benelli M4 (9), and Springfield (7)!
	var is_shell_gun := (current_weapon == 2 or current_weapon == 9 or current_weapon == 7)
	if is_reloading and is_shell_gun and ammo_in_mag[current_weapon] > 0 and wants_fire:
		reload_cancel_req = true
		_shotgun_fire_on_cancel = true
		_fire_buffer_timer = 0.30
	if wants_fire and fire_cd <= 0.0 and not is_reloading and _melee_timer <= 0.0:
		# If weapon had an interrupted empty reload and is still unchambered, finish reload/chambering instead of firing!
		if not weapon_chambered[current_weapon] and ammo_in_mag[current_weapon] > 0:
			start_reload()
			_fire_buffer_timer = 0.0
		else:
			if _sprint_blend > 0.25 and _sprint_out_timer <= 0.0:
				_sprint_out_timer = 0.14 if current_weapon == 0 else (0.18 if current_weapon == 1 else 0.22)
				if not is_auto:
					_fire_buffer_timer = maxf(_fire_buffer_timer, _sprint_out_timer + 0.08)
			if _sprint_out_timer <= 0.0:
				_fire_buffer_timer = 0.0
				fire_weapon()
	elif not wants_fire and fire_cd < 0.0:
		fire_cd = 0.0
	if _sprint_out_timer > 0.0:
		_sprint_out_timer = maxf(0.0, _sprint_out_timer - delta)

	if Input.is_action_just_pressed("interact"):
		try_interact()


func _process(delta: float) -> void:
	if deterministic_camera:
		_update_flashlight_and_iris(delta)
		return

	# Smooth muzzle exponential decay & 2-frame flash cooling
	_flash_shadow_boost = maxf(0.0, _flash_shadow_boost - delta * 24.0)
	if muzzle_elapsed < 0.065:
		muzzle_elapsed += delta
		var e := muzzle_peak_e * exp(-muzzle_elapsed / 0.017) if muzzle_elapsed < 0.060 else 0.0
		var active := e > 0.01
		muzzle_light.visible = active
		muzzle_light.light_energy = e
		muzzle_vm_light.visible = active
		muzzle_vm_light.light_energy = minf(e * 0.38, 1.25)
	else:
		muzzle_light.light_energy = 0.0
		muzzle_light.visible = false
		muzzle_vm_light.light_energy = 0.0
		muzzle_vm_light.visible = false

	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		var cool := clampf(1.0 - muzzle_flash_timer / 0.036, 0.0, 1.0)
		for fm in _flash_mats:
			fm.set_shader_parameter("cool_t", cool)
		if muzzle_flash_timer <= 0.0:
			muzzle_flash_rig.visible = false

	if _barrel_heat_timer > 0.0 and muzzle_smoke and not OS.has_feature("web"):
		_barrel_heat_timer -= delta
		_barrel_heat_step -= delta
		if _barrel_heat_step <= 0.0:
			_barrel_heat_step = 0.16
			var hxf := muzzle_smoke.global_transform
			var hv := Vector3(randf_range(-0.08, 0.08), randf_range(0.28, 0.45), randf_range(-0.08, 0.08))
			muzzle_smoke.emit_particle(hxf, hv, Color.WHITE, Color.WHITE, GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)

	damage_flash = maxf(0.0, damage_flash - delta * 1.4)
	damage_invuln = maxf(0.0, damage_invuln - delta)
	hit_glitch = maxf(0.0, hit_glitch - delta * 1.9)
	hit_ca_boost = maxf(0.0, hit_ca_boost - delta * 0.08)

	if dead:
		head.position.y = lerp(head.position.y, 0.28, delta * 4.0)
		head.rotation.z = lerp(head.rotation.z, 0.65, delta * 3.0)
		return

	# Compute yaw angular speed for subtle CMOS rolling shutter
	var d_yaw := yaw - _last_yaw
	_last_yaw = yaw
	yaw_vel = lerpf(yaw_vel, d_yaw / maxf(delta, 0.001), 1.0 - exp(-delta * 18.0))

	if not input_enabled:
		_update_flashlight_and_iris(delta)
		return

	rotation.y = yaw

	# Trauma noise shake
	trauma = maxf(0.0, trauma - delta * 2.1)
	var shake := trauma * trauma
	var t_now := Time.get_ticks_msec() * 0.001
	var shake_p := _noise.get_noise_1d(t_now * 19.0) * 0.042 * shake
	var shake_y := _noise.get_noise_1d(t_now * 23.0 + 40.0) * 0.036 * shake
	var shake_r := _noise.get_noise_1d(t_now * 29.0 + 90.0) * 0.055 * shake

	# Distance-based footstep cadence & head dip
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var horiz_spd := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_spd > 0.35:
		var stride := 1.65 if is_crouching else (2.65 if is_sprinting else 2.15)
		bob_phase += (horiz_spd * delta / stride) * PI
		step_dist += horiz_spd * delta
		if step_dist >= stride:
			step_dist -= stride
			step_side *= -1.0
			step_roll_impulse = step_side * (0.015 if is_sprinting else 0.007)
			_land_dip = maxf(_land_dip, 0.026 if is_sprinting else 0.012)
			trauma = minf(1.0, trauma + (0.055 if is_sprinting else 0.02))
			_play_surface_footstep(false)
	else:
		bob_phase += delta * 1.3

	step_roll_impulse = lerpf(step_roll_impulse, 0.0, 1.0 - exp(-delta * 12.0))
	hit_roll_kick = lerpf(hit_roll_kick, 0.0, 1.0 - exp(-delta * 10.0))
	hit_pitch_kick = lerpf(hit_pitch_kick, 0.0, 1.0 - exp(-delta * 10.0))
	_land_dip = lerpf(_land_dip, 0.0, 1.0 - exp(-delta * 14.0))
	recoil_roll = lerpf(recoil_roll, 0.0, 1.0 - exp(-delta * 18.0))
	recoil_fov = lerpf(recoil_fov, 0.0, 1.0 - exp(-delta * 18.0))

	# ADS subtle breathing micro-sway
	var ads_sway_amp := (0.5 if is_crouching else 1.0) * (1.8 if horiz_spd > 0.4 else 1.0)
	var breath_x := (sin(t_now * 1.37) * 0.0022 + sin(t_now * 2.41) * 0.0011) * ads_sway_amp * _ads_blend
	var breath_y := (cos(t_now * 1.73) * 0.0018 + sin(t_now * 2.91) * 0.0009) * ads_sway_amp * _ads_blend

	var bob_amp := (0.042 if is_sprinting else 0.022) if horiz_spd > 0.35 else 0.005
	var target_h := (1.05 if is_crouching else 1.56) - _land_dip
	head.position.y = lerpf(head.position.y, target_h + sin(bob_phase * 2.0) * bob_amp, 1.0 - exp(-delta * 15.0))
	head.rotation.x = clampf(pitch + recoil_vel.y + hit_pitch_kick + shake_p + breath_y, -1.42, 1.42)
	head.rotation.y = shake_y + breath_x
	# Smooth base roll separately so hit_roll_kick NEVER accumulates across render frames!
	_base_head_roll = lerpf(_base_head_roll, -iv.x * 0.048 + sin(bob_phase) * bob_amp * 0.72 + step_roll_impulse, 1.0 - exp(-delta * 12.0))
	head.rotation.z = _base_head_roll + hit_roll_kick + shake_r
	camera.rotation.z = lerpf(-0.061, -0.042, _ads_blend) + recoil_roll

	# Reloads & Bow re-nock advance in _physics_process; smoothly relax offsets when idle
	if not is_reloading and not (current_weapon == 4 and _bow_nock_timer > 0.0):
		reload_pos_off = reload_pos_off.lerp(Vector3.ZERO, 1.0 - exp(-delta * 14.0))
		reload_rot_off = reload_rot_off.lerp(Vector3.ZERO, 1.0 - exp(-delta * 14.0))

	_update_weapon_mechanics(delta)

	var want_sprint := is_sprinting and not is_reloading and _burst_remaining <= 0 and _sprint_out_timer <= 0.0
	_sprint_blend = lerpf(_sprint_blend, 1.0 if want_sprint else 0.0, 1.0 - exp(-delta * 11.0))

	sway_offset = sway_offset.lerp(Vector2.ZERO, 1.0 - exp(-delta * 9.0))
	recoil_vel = recoil_vel.lerp(Vector2.ZERO, 1.0 - exp(-delta * 12.0))
	recoil_z = lerpf(recoil_z, 0.0, 1.0 - exp(-delta * 15.0))

	var w: Dictionary = WEAPONS[current_weapon]
	var ads_p_eff: Vector3 = w["ads_pos"] as Vector3
	var has_added_optic := has_attachment(current_weapon, "optic") and not bool(w["has_holo"])
	if has_added_optic and is_instance_valid(holo_quad):
		# Zero aftermarket Red-Dot Optic dead-center to camera aim ray (ads_pos.y + holo_pos.y == 0.0)!
		ads_p_eff = Vector3(-holo_quad.position.x, -holo_quad.position.y, ads_p_eff.z)
	var base_pos: Vector3 = (w["hip_pos"] as Vector3).lerp(ads_p_eff, _ads_blend)
	var base_rot: Vector3 = (w["hip_rot"] as Vector3).lerp(w["ads_rot"] as Vector3, _ads_blend)
	if is_instance_valid(holo_quad):
		var want_holo := (bool(w["has_holo"]) or has_attachment(current_weapon, "optic")) and not bool(w.get("is_melee", false)) and not _quick_melee_active and not is_reloading and sniper_scope_alpha < 0.92
		holo_quad.visible = want_holo
	if is_instance_valid(optic_hood):
		var want_hood := has_attachment(current_weapon, "optic") and not bool(w["has_holo"]) and not bool(w.get("is_melee", false)) and not _quick_melee_active and sniper_scope_alpha < 0.92
		optic_hood.visible = want_hood

	var sway_scale := lerpf(1.0, 0.18, _ads_blend)
	var low_ready_pos := Vector3(-0.048, -0.062, 0.038) * _sprint_blend
	var low_ready_rot := Vector3(-0.36, 0.34, 0.24) * _sprint_blend

	var pump_off_p := Vector3.ZERO
	var pump_off_r := Vector3.ZERO
	if shotgun_pump_timer > 0.0 and current_weapon == 2 and not is_reloading:
		var pt := clampf(1.0 - shotgun_pump_timer / 0.36, 0.0, 1.0)
		var pulse := sin(pt * PI)
		pump_off_p = Vector3(0.014, -0.026, 0.036) * pulse
		pump_off_r = Vector3(-0.14, 0.08, 0.24) * pulse

	var target_pos := base_pos + reload_pos_off + low_ready_pos + pump_off_p + Vector3(
		-sway_offset.x * 0.72 * sway_scale + cos(bob_phase) * bob_amp * 0.45 * sway_scale,
		-sway_offset.y * 0.58 * sway_scale + absf(sin(bob_phase)) * -bob_amp * 0.65 * sway_scale - _land_dip * 0.35,
		recoil_z
	)
	var target_rot := base_rot + reload_rot_off + low_ready_rot + pump_off_r + Vector3(
		recoil_vel.y * 1.65,
		-sway_offset.x * 2.8 * sway_scale,
		sway_offset.x * 2.2 * sway_scale + (-iv.x * 0.06)
	)
	var melee_p := Vector3.ZERO
	var melee_r := Vector3.ZERO
	if _melee_timer > 0.0:
		# Wind-up eases back, the strike snaps through, the follow-through hangs for a beat, then recovers
		var mu := clampf(1.0 - _melee_timer / maxf(_melee_dur, 0.01), 0.0, 1.0)
		var wu_f := clampf(_melee_win0 / maxf(_melee_dur, 0.01), 0.05, 0.6)
		var wind := smoothstep(0.0, wu_f * 0.85, mu) * (1.0 - smoothstep(wu_f, wu_f + 0.10, mu))
		var slash := pow(smoothstep(wu_f, wu_f + 0.17, mu), 0.75) * (1.0 - smoothstep(0.62, 1.0, mu))
		if _melee_is_heavy:
			wind = 1.0 - smoothstep(wu_f * 0.5, wu_f + 0.10, mu)
			slash *= 1.08
		var mvp: Dictionary = MELEE_MOVES.get(_melee_move, MELEE_MOVES["slash_rl"])
		melee_p = (mvp["wp"] as Vector3) * wind + (mvp["tp"] as Vector3) * slash
		melee_r = (mvp["wr"] as Vector3) * wind + (mvp["tr"] as Vector3) * slash
	elif _melee_charge_pose > 0.01 and current_weapon == 3:
		# Held heavy attack: the weapon draws back into its wound-up pose and trembles at full charge
		var mh: Dictionary = MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])
		var mvh: Dictionary = MELEE_MOVES.get(str(mh.get("heavy", "overhead")), MELEE_MOVES["overhead"])
		var cp := _melee_charge_pose
		var shake_c := (sin(t_now * 61.0) * 0.004 + sin(t_now * 43.0) * 0.003) * smoothstep(0.85, 1.0, cp)
		melee_p = (mvh["wp"] as Vector3) * cp + Vector3(shake_c, shake_c * 0.6, 0.0)
		melee_r = (mvh["wr"] as Vector3) * cp
	if _quick_melee_active and _melee_timer > 0.0:
		# Anchor quick-melee knife rig neatly to melee hip pose during slash!
		var mw: Dictionary = WEAPONS[3]
		target_pos = (mw["hip_pos"] as Vector3)
		target_rot = (mw["hip_rot"] as Vector3)
	weapon_pivot.position = weapon_pivot.position.lerp(target_pos + melee_p, 1.0 - exp(-delta * (28.0 if _melee_timer > 0.0 else 18.0)))
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target_rot + melee_r, 1.0 - exp(-delta * (26.0 if _melee_timer > 0.0 else 16.0)))

	var ads_fov_val := float(w.get("ads_fov", 60.5))
	if current_weapon == 7:
		# CoD-style reversible sniper scope-in transition (0.34s in / 0.24s out, drops out during bolt throw or quick-melee!)
		var want_scope := is_ads and not is_reloading and not dead and _hunting_bolt_timer <= 0.15 and not _quick_melee_active
		var spd_s := (1.0 / 0.34) if want_scope else (1.0 / 0.24)
		_sniper_ads_raw = move_toward(_sniper_ads_raw, 1.0 if want_scope else 0.0, delta * spd_s)
		var s := _sniper_ads_raw * _sniper_ads_raw * (3.0 - 2.0 * _sniper_ads_raw)
		var fov_s := pow(s, 1.55)
		camera.fov = lerpf(base_fov, ads_fov_val, fov_s) + _sprint_blend * 5.5 + recoil_fov
		if not (_quick_melee_active and _melee_timer > 0.0):
			# Snap weapon_pivot cleanly along exact eye-relief path into ocular center
			weapon_pivot.position = (w["hip_pos"] as Vector3).lerp(w["ads_pos"] as Vector3, s) + reload_pos_off + melee_p + Vector3(0.0, 0.0, recoil_z)
			weapon_pivot.rotation = (w["hip_rot"] as Vector3).lerp(w["ads_rot"] as Vector3, s) + reload_rot_off + melee_r + Vector3(recoil_vel.y * 1.4, 0.0, 0.0)
		sniper_scope_alpha = 0.0 if _quick_melee_active else smoothstep(0.74, 0.88, s)
		sniper_iris_scale = lerpf(0.76, 1.0, smoothstep(0.72, 0.94, s))
		if weapon_rig_holder:
			weapon_rig_holder.visible = _quick_melee_active or sniper_scope_alpha < 0.92
	else:
		_sniper_ads_raw = 0.0
		sniper_scope_alpha = 0.0
		sniper_iris_scale = 1.0
		var target_fov := lerpf(base_fov, ads_fov_val, _ads_blend) + _sprint_blend * 5.5 + recoil_fov
		camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-delta * 14.0))
		if weapon_rig_holder and not weapon_rig_holder.visible:
			weapon_rig_holder.visible = true

	_update_flashlight_and_iris(delta)


func _spawn_dropped_mag(weapon_idx: int) -> void:
	if _casings.size() >= 18:
		var old: Dictionary = _casings.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	# Hand off the ACTUAL visible magazine mesh, material, and current world transform!
	var src_mi: MeshInstance3D = null
	if _w_parts.has("mag"):
		for pn in _w_parts["mag"]:
			if pn is MeshInstance3D and (pn as MeshInstance3D).mesh != null:
				src_mi = pn as MeshInstance3D
				break
			elif pn is Node:
				var found := (pn as Node).find_children("*", "MeshInstance3D", true, false)
				if not found.is_empty():
					src_mi = found[0] as MeshInstance3D
					break
	if src_mi != null and src_mi.mesh != null:
		mi.mesh = src_mi.mesh
		for si in range(src_mi.mesh.get_surface_count()):
			var sm := src_mi.get_active_material(si)
			if sm != null:
				mi.set_surface_override_material(si, sm)
	else:
		if _mag_mat_dark == null:
			_mag_mat_dark = StandardMaterial3D.new()
			_mag_mat_dark.albedo_color = Color(0.11, 0.12, 0.13)
			_mag_mat_dark.metallic = 0.28
			_mag_mat_dark.roughness = 0.54
		if _mag_mesh_g17 == null:
			_mag_mesh_g17 = BoxMesh.new()
			_mag_mesh_g17.size = Vector3(0.024, 0.112, 0.036)
			_mag_mesh_g17.material = _mag_mat_dark
		if _mag_mesh_ar == null:
			var ar_box := BoxMesh.new()
			ar_box.size = Vector3(0.026, 0.162, 0.066)
			ar_box.material = _mag_mat_dark
			_mag_mesh_ar = ar_box
		mi.mesh = _mag_mesh_g17 if weapon_idx == 0 else _mag_mesh_ar
		if weapon_idx == 1 and _mag_mat_ar != null:
			mi.set_surface_override_material(0, _mag_mat_ar)
	mi.layers = 1 | 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	var spawn_p: Vector3
	if src_mi != null and src_mi.is_inside_tree():
		mi.global_transform = src_mi.global_transform
		spawn_p = src_mi.global_position
	else:
		var local_spawn := (Vector3(0.0, -0.04, -0.145) + EJECT_G17 * 0.20) if weapon_idx == 0 else (Vector3(0.0, -0.11, -0.135) + EJECT_AR * 0.20)
		spawn_p = weapon_pivot.to_global(local_spawn)
		mi.global_position = spawn_p
		mi.global_rotation = weapon_pivot.global_rotation + Vector3(-0.36 if weapon_idx == 0 else -0.17, 0.0, 0.0)
	var local_eject := (EJECT_G17 if weapon_idx == 0 else EJECT_AR).normalized()
	var world_dir := (weapon_pivot.global_transform.basis * local_eject).normalized()
	var ej_vel := world_dir * randf_range(1.15, 1.65) + velocity * 0.35
	var floor_y := global_position.y + 0.020
	var space := get_world_3d().direct_space_state
	if space:
		var land_xz := spawn_p + Vector3(ej_vel.x, 0.0, ej_vel.z) * 0.25
		var fq := PhysicsRayQueryParameters3D.create(Vector3(land_xz.x, spawn_p.y + 0.2, land_xz.z), Vector3(land_xz.x, spawn_p.y - 4.0, land_xz.z), 1)
		var fhit := space.intersect_ray(fq)
		if fhit:
			floor_y = float(fhit["position"].y) + 0.018
	_casings.append({
		"node": mi,
		"vel": ej_vel,
		"ang": Vector3(randf_range(4.0, 9.0), randf_range(-6.0, 6.0), randf_range(-8.0, 8.0)),
		"age": 0.0,
		"bounced": false,
		"floor_y": floor_y,
		"is_hull": false,
		"is_mag": true,
	})


static var _enbloc_clip_mesh: ArrayMesh = null
static var _enbloc_clip_mat: StandardMaterial3D = null


static func _st_add_plate(st: SurfaceTool, c: Vector3, h: Vector3) -> void:
	# Thin stamped plate (box with half-extents h) with per-face normals and size-proportional UVs
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
		[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var tu: Vector3 = f[1]
		var tv: Vector3 = f[2]
		var o := c + n * absf(n.dot(h))
		var su := absf(tu.dot(h))
		var sv := absf(tv.dot(h))
		var corners := [o - tu * su - tv * sv, o + tu * su - tv * sv, o + tu * su + tv * sv, o - tu * su + tv * sv]
		var uvs := [Vector2(0, sv * 2.0), Vector2(su * 2.0, sv * 2.0), Vector2(su * 2.0, 0), Vector2(0, 0)]
		# Both windings with the outward normal: exactly one survives back-face culling from outside, whatever the convention
		for idx: int in [0, 2, 1, 0, 3, 2, 0, 1, 2, 0, 2, 3]:
			st.set_normal(n)
			st.set_uv((uvs[idx] as Vector2) * 9.0)
			st.add_vertex(corners[idx])


static func _get_enbloc_clip_mesh() -> ArrayMesh:
	# M1 en-bloc clip: stamped spring-steel U-channel (spine + two side walls with in-rolled rim lips)
	if _enbloc_clip_mesh != null:
		return _enbloc_clip_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := 0.0108
	var hh := 0.0295
	var hd := 0.0062
	var tk := 0.00055
	_st_add_plate(st, Vector3(0.0, 0.0, hd), Vector3(hw, hh, tk))
	_st_add_plate(st, Vector3(hw, 0.0, 0.0), Vector3(tk, hh, hd))
	_st_add_plate(st, Vector3(-hw, 0.0, 0.0), Vector3(tk, hh, hd))
	_st_add_plate(st, Vector3(hw - 0.0018, 0.0, -hd), Vector3(0.0018, hh * 0.92, tk))
	_st_add_plate(st, Vector3(-hw + 0.0018, 0.0, -hd), Vector3(0.0018, hh * 0.92, tk))
	# Pressed stiffening rib down the spine
	_st_add_plate(st, Vector3(0.0, 0.0, hd + tk * 1.6), Vector3(0.0022, hh * 0.78, tk))
	st.generate_tangents()
	_enbloc_clip_mesh = st.commit()
	return _enbloc_clip_mesh


func _spawn_garand_clip_eject() -> void:
	# Iconic M1 Garand empty steel en-bloc clip spinning upward-right out of the open top breech!
	if _casings.size() >= 18:
		var old: Dictionary = _casings.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = _get_enbloc_clip_mesh()
	# Tileable Parkerized-steel PBR (albedo + normal), triplanar so the stamped plates never sample a UV atlas
	if _enbloc_clip_mat == null:
		_enbloc_clip_mat = _make_vm_mat(Color(0.58, 0.60, 0.56), 0.50, 0.80, 0.55, Color.BLACK, "metal_tactical")
		_enbloc_clip_mat.uv1_scale = Vector3(14.0, 14.0, 14.0)
	mi.material_override = _enbloc_clip_mat
	mi.layers = 1 | 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	var spawn_p := weapon_pivot.to_global(Vector3(0.008, 0.048, -0.10))
	mi.global_position = spawn_p
	mi.global_rotation = weapon_pivot.global_rotation
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var fwd := -camera.global_transform.basis.z
	var ej_vel := up * randf_range(2.6, 3.2) + right * randf_range(1.1, 1.6) - fwd * randf_range(0.35, 0.70) + velocity * 0.45
	var floor_y := global_position.y + 0.02
	var space := get_world_3d().direct_space_state
	if space:
		var fq := PhysicsRayQueryParameters3D.create(spawn_p, spawn_p - Vector3(0.0, 4.0, 0.0), 1)
		var fhit := space.intersect_ray(fq)
		if fhit:
			floor_y = float(fhit["position"].y) + 0.02
	_casings.append({
		"node": mi,
		"vel": ej_vel,
		"ang": Vector3(randf_range(14.0, 22.0), randf_range(-10.0, 10.0), randf_range(12.0, 20.0)),
		"age": 0.0,
		"bounced": false,
		"floor_y": floor_y,
		"is_hull": false,
		"is_mag": true,
	})


func _update_weapon_mechanics(delta: float) -> void:
	bolt_blowback = maxf(0.0, bolt_blowback - delta * (14.0 if current_weapon == 0 else 18.0))
	if shotgun_pump_timer > 0.0:
		shotgun_pump_timer = maxf(0.0, shotgun_pump_timer - delta)
		if not shotgun_pump_did_sfx and shotgun_pump_timer < 0.26:
			shotgun_pump_did_sfx = true
			_eject_brass_casing(WEAPONS[2], true)
			if sfx_reload and _sfx_bolt:
				sfx_reload.stream = _sfx_bolt
				sfx_reload.pitch_scale = 0.85
				sfx_reload.play()

	if _hunting_bolt_timer > 0.0:
		_hunting_bolt_timer = maxf(0.0, _hunting_bolt_timer - delta)
		if not _hunting_bolt_did_sfx and _hunting_bolt_timer < 0.50:
			_hunting_bolt_did_sfx = true
			_eject_brass_casing(WEAPONS[current_weapon], false)
			if sfx_reload and _sfx_bolt:
				sfx_reload.stream = _sfx_bolt
				sfx_reload.pitch_scale = 0.76
				sfx_reload.play()
	_revolver_hammer = maxf(0.0, _revolver_hammer - delta * 8.0)

	if is_reloading:
		return

	if current_weapon == 0 or current_weapon == 1 or current_weapon == 5 or current_weapon == 13 or current_weapon == 17:
		_apply_idle_bolt_and_cover()
	elif current_weapon == 2:
		var pump_pull := 0.0
		if shotgun_pump_timer > 0.0:
			var pt := clampf(1.0 - shotgun_pump_timer / 0.36, 0.0, 1.0)
			pump_pull = sin(pt * PI) * 0.068
		_pose_part("pump", Vector3(0, 0, pump_pull))
		_pose_part("arm_left", Vector3(0, 0, pump_pull))
		_pose_part("slide", Vector3(0, 0, maxf(bolt_blowback * 0.04, pump_pull)))
		_pose_part("charge", Vector3(0, 0, pump_pull))
		_pose_part("lifter", Vector3.ZERO)
	elif current_weapon == 4:
		_pose_bow_rig()
	elif current_weapon == 6:
		_pose_part("crane", Vector3.ZERO)
		_pose_part("cylinder", Vector3.ZERO, Vector3(0.0, 0.0, _revolver_cyl_angle))
		_pose_part("hammer", Vector3.ZERO, Vector3(0.55 * _revolver_hammer, 0.0, 0.0))
	elif current_weapon == 7 or current_weapon == 14:
		if _hunting_bolt_timer > 0.0:
			var u := clampf(1.0 - _hunting_bolt_timer / 0.78, 0.0, 1.0)
			var lift := sin(smoothstep(0.0, 0.25, u) * PI * 0.5) * (1.0 - smoothstep(0.75, 1.0, u))
			var pull := sin(smoothstep(0.18, 0.82, u) * PI)
			_pose_part("bolt", Vector3(0.0, 0.0, pull * 0.082), Vector3(0.0, 0.0, lift * 1.05))
			var hand_reach := smoothstep(0.0, 0.18, u) * (1.0 - smoothstep(0.80, 1.0, u))
			_pose_part("arm_right", Vector3(0.056, 0.076, -0.015) * hand_reach + Vector3(0.0, 0.0, pull * 0.082), Vector3(0.16, -0.18, -0.30) * hand_reach)
		else:
			_pose_part("bolt", Vector3.ZERO)
			_pose_part("arm_right", Vector3.ZERO)
	elif current_weapon == 8 or current_weapon == 9:
		_pose_part("bolt", Vector3(0.0, 0.0, bolt_blowback * 0.055))
	elif current_weapon == 10:
		_pose_part("charge", Vector3(0.0, 0.0, bolt_blowback * 0.048))
		_pose_part("top_cover", Vector3.ZERO)


func _play_reload_sfx(stream: AudioStream, pitch_sc := 1.0) -> void:
	if stream == null:
		return
	if not _sfx_reload_pool.is_empty():
		var p: AudioStreamPlayer = _sfx_reload_pool[_sfx_reload_pool_idx]
		_sfx_reload_pool_idx = (_sfx_reload_pool_idx + 1) % _sfx_reload_pool.size()
		p.stream = stream
		p.pitch_scale = pitch_sc
		p.play()
	elif sfx_reload:
		sfx_reload.stream = stream
		sfx_reload.pitch_scale = pitch_sc
		sfx_reload.play()


func _play_gun_sfx(stream: AudioStream, pitch_sc := 1.0) -> void:
	if stream == null:
		return
	if not _sfx_gun_pool.is_empty():
		var p: AudioStreamPlayer = _sfx_gun_pool[_sfx_gun_pool_idx]
		_sfx_gun_pool_idx = (_sfx_gun_pool_idx + 1) % _sfx_gun_pool.size()
		p.stream = stream
		p.pitch_scale = pitch_sc
		p.play()
	elif sfx_gun:
		sfx_gun.stream = stream
		sfx_gun.pitch_scale = pitch_sc
		sfx_gun.play()


func _reload_event(ts: float, bit: int) -> bool:
	if (reload_flags & bit) == 0 and reload_elapsed >= ts:
		reload_flags |= bit
		return true
	return false


func _commit_mag_ammo() -> void:
	var mag_cap := get_weapon_mag_size(current_weapon)
	var need: int = mag_cap - ammo_in_mag[current_weapon]
	var take: int = mini(need, ammo_reserve[current_weapon])
	ammo_in_mag[current_weapon] += take
	ammo_reserve[current_weapon] -= take


# --- Call of Duty-grade reload motion & impulse helpers ---
func _cod_ease_out(u: float) -> float:
	# Energetic start, cushioned deceleration (cubic ease-out)
	var x := clampf(u, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


func _cod_punch(t: float, t0: float, dur: float) -> float:
	# Sharp mechanical impact rise (peaks ~12% into the window) followed by a spring-damped rebound
	if dur <= 0.0 or t <= t0 or t >= t0 + dur:
		return 0.0
	var x := (t - t0) / dur
	var rise := smoothstep(0.0, 0.12, x)
	return rise * exp(-3.6 * x) * cos((x - 0.12) * 11.0) * 1.54 * (1.0 - smoothstep(0.85, 1.0, x))


func _reload_cam_kick(pitch_k: float, roll_k: float, z_k: float, tr: float) -> void:
	# Subtle authentic camera/viewmodel impulse on mag clicks, seat slaps, bolt slams, lid slams & cylinder flicks
	hit_pitch_kick += pitch_k
	hit_roll_kick += roll_k
	recoil_z += z_k
	if tr > 0.0:
		trauma = minf(1.0, trauma + tr)


func _reload_settle(t: float) -> void:
	# Weapon lands back on the shoulder at the end of the reload with a small damped bob
	var pk := _cod_punch(t, reload_dur - 0.28, 0.28)
	reload_pos_off += Vector3(0.0, -0.008, 0.004) * pk
	reload_rot_off += Vector3(-0.025, 0.0, 0.012) * pk


func start_reload() -> bool:
	if _melee_timer > 0.0 or _quick_melee_active:
		return false
	var w: Dictionary = WEAPONS[current_weapon]
	if bool(w.get("is_melee", false)) or bool(w.get("is_bow", false)) or bool(w.get("is_flamethrower", false)):
		return false
	var mag_cap := get_weapon_mag_size(current_weapon)
	var needs_chamber_only := (not weapon_chambered[current_weapon] and ammo_in_mag[current_weapon] > 0)
	if is_reloading:
		return false
	if not needs_chamber_only and (ammo_in_mag[current_weapon] >= mag_cap or ammo_reserve[current_weapon] <= 0):
		return false
	is_reloading = true
	_burst_remaining = 0
	_burst_timer = 0.0
	reload_elapsed = 0.0
	_reload_prev_t = -0.001
	reload_flags = 0
	reload_was_empty = (ammo_in_mag[current_weapon] <= 0) or not weapon_chambered[current_weapon]
	if ammo_in_mag[current_weapon] <= 0:
		weapon_chambered[current_weapon] = false
	reload_shell_timer = 0.0
	reload_shell_phase = 0
	reload_cancel_req = false
	_shotgun_fire_on_cancel = false
	_shotgun_exit_arm_p = Vector3.ZERO
	_shotgun_exit_arm_r = Vector3.ZERO
	shotgun_pump_timer = 0.0
	_sniper_pending_eject = ((current_weapon == 7 or current_weapon == 14) and _hunting_bolt_timer > 0.0 and not _hunting_bolt_did_sfx)
	_hunting_bolt_timer = 0.0
	_magnum_spent_count = clampi(mag_cap - ammo_in_mag[6], 1, 6) if current_weapon == 6 else (clampi(2 - ammo_in_mag[11], 1, 2) if current_weapon == 11 else 0)
	_rl_layer_p = Vector3.ZERO
	_rl_layer_r = Vector3.ZERO

	if current_weapon == 0:
		reload_dur = 1.66 if reload_was_empty else 1.28
	elif current_weapon == 1:
		reload_dur = 2.28 if reload_was_empty else 1.88
	elif current_weapon == 5:
		reload_dur = 2.12 if reload_was_empty else 1.60
	elif current_weapon == 6:
		reload_dur = 2.24
	elif current_weapon == 7:
		reload_dur = 1.2 # Managed by per-round feed loop phases
	elif current_weapon == 8:
		reload_dur = 2.40 if reload_was_empty else 1.88
	elif current_weapon == 9:
		reload_dur = 1.2 # Managed by interruptible shell loop phases
	elif current_weapon == 10:
		reload_dur = 3.40
	elif current_weapon == 11:
		reload_dur = 1.95
	elif current_weapon == 12:
		reload_dur = 2.25 if reload_was_empty else 1.78
	elif current_weapon == 13:
		reload_dur = 1.90 if reload_was_empty else 2.14
	elif current_weapon == 14:
		reload_dur = 2.20
	elif current_weapon == 15:
		reload_dur = 1.52
	elif current_weapon == 17:
		reload_dur = 2.35
	else:
		reload_dur = 1.2 # Managed by shell loop phases
	return true


func _update_reload(delta: float) -> void:
	if perks.has("quickhands"):
		delta *= 1.35
	_reload_prev_t = reload_elapsed
	reload_elapsed += delta
	# Remove last frame's shared motion layer so branches that don't re-assign the offsets never accumulate it
	reload_pos_off -= _rl_layer_p
	reload_rot_off -= _rl_layer_r
	_rl_layer_p = Vector3.ZERO
	_rl_layer_r = Vector3.ZERO
	_dispatch_reload(delta)
	if is_reloading and current_weapon != 0 and current_weapon != 2:
		# Shared CoD layer for every non-pistol/non-M870 reload: a quick anticipation dip on the first beat,
		# then a living shoulder sway that scales with how far the weapon is canted (never frozen still)
		var tt := reload_elapsed
		var antic := sin(clampf(tt / 0.16, 0.0, 1.0) * PI) if tt < 0.16 else 0.0
		var cant_mag := clampf(reload_rot_off.length() / 0.55, 0.0, 1.0)
		_rl_layer_p = Vector3(-0.004, -0.014, 0.008) * antic + Vector3(sin(tt * 4.6) * 0.0035, sin(tt * 3.3 + 0.8) * 0.0042, sin(tt * 2.6) * 0.002) * cant_mag
		_rl_layer_r = Vector3(-0.055, 0.0, 0.045) * antic + Vector3(sin(tt * 3.9 + 0.3) * 0.015, sin(tt * 2.7 + 1.1) * 0.011, sin(tt * 3.1 + 2.0) * 0.018) * cant_mag
		reload_pos_off += _rl_layer_p
		reload_rot_off += _rl_layer_r


func _dispatch_reload(delta: float) -> void:
	if current_weapon == 0:
		_update_reload_pistol()
	elif current_weapon == 1:
		_update_reload_rifle()
	elif current_weapon == 5:
		_update_reload_mp5()
	elif current_weapon == 6:
		_update_reload_magnum()
	elif current_weapon == 7:
		_update_reload_hunting(delta)
	elif current_weapon == 8:
		_update_reload_ak74()
	elif current_weapon == 9:
		_update_reload_benelli(delta)
	elif current_weapon == 10:
		_update_reload_m249()
	elif current_weapon == 11:
		_update_reload_sawed_off()
	elif current_weapon == 12:
		_update_reload_famas()
	elif current_weapon == 13:
		_update_reload_garand()
	elif current_weapon == 14:
		_update_reload_kar98k()
	elif current_weapon == 15:
		_update_reload_crossbow()
	elif current_weapon == 17:
		_update_reload_rpg7()
	else:
		_update_reload_shotgun(delta)


func _update_reload_sawed_off() -> void:
	# Break-action DB: sharp downward break flick -> hulls kicked out -> two staggered thumb shoves -> upward wrist-whip snap shut
	var t := reload_elapsed
	var cant_p := Vector3(-0.045, 0.085, -0.045)
	var cant_r := Vector3(0.24, 0.36, -0.34)
	if _reload_event(0.24, 1):
		weapon_chambered[11] = false
		_play_reload_sfx(_sfx_bolt, 0.84)
		_reload_cam_kick(-0.014, 0.008, 0.006, 0.0)
		for _hi in range(maxi(1, _magnum_spent_count)):
			_eject_brass_casing(WEAPONS[11], true)
	if _reload_event(0.98, 2):
		_play_reload_sfx(_sfx_shell_in, 0.96)
		_reload_cam_kick(0.006, -0.004, 0.004, 0.0)
	if _reload_event(1.26, 4):
		_play_reload_sfx(_sfx_shell_in, 1.04)
		_reload_cam_kick(0.006, 0.004, 0.004, 0.0)
		_commit_mag_ammo()
	if _reload_event(1.60, 8):
		weapon_chambered[11] = true
		_play_reload_sfx(_sfx_bolt, 1.12)
		_reload_cam_kick(0.018, -0.012, 0.010, 0.14)
	# Break open is a quick flick (eased-out), the shut is an accelerating whip (eased-in)
	var open_u := _cod_ease_out((t - 0.16) / 0.13)
	var shut_u := pow(smoothstep(1.48, 1.60, t), 2.0)
	var hinge := open_u * (1.0 - shut_u)
	var env_u := _cod_ease_out(t / 0.22) * (1.0 - smoothstep(1.70, reload_dur, t))
	reload_pos_off = cant_p * env_u
	reload_rot_off = cant_r * env_u
	var hinge_piv := Vector3(0.0, 0.004, -0.032)
	var hinge_rot := Vector3(-0.62 * hinge, 0.0, 0.0)
	_pose_part("barrel", Vector3.ZERO, hinge_rot, hinge_piv)
	_pose_optic_hood(Vector3.ZERO, hinge_rot, hinge_piv)
	# Staggered dual-shell feed: first thumb shove seats shell #1 halfway, second shove drives both home
	var shell_vis := t < 0.42 or t >= 0.85
	var shell_slide := 0.0
	if t >= 0.85:
		var s1 := _cod_ease_out((t - 0.90) / 0.10)
		var s2 := _cod_ease_out((t - 1.18) / 0.10)
		shell_slide = lerpf(lerpf(0.09, 0.042, s1), 0.0, s2)
	else:
		shell_slide = 0.11 * smoothstep(0.24, 0.42, t)
	var aligned_slide := Basis.from_euler(hinge_rot) * Vector3(0.0, 0.0, shell_slide)
	_pose_part("mag", aligned_slide, hinge_rot, hinge_piv, shell_vis)
	var lh_in := sin(smoothstep(0.75, 1.45, t) * PI)
	var thumb := maxf(0.0, _cod_punch(t, 0.92, 0.18)) + maxf(0.0, _cod_punch(t, 1.20, 0.18))
	_pose_part("arm_left", Vector3(0.02 * lh_in, -0.04 * lh_in, 0.10 * lh_in - 0.012 * thumb), Vector3(-0.35 * lh_in, 0.25 * lh_in, 0.22 * lh_in), PIVOT_AR_HAND)
	# Impulses: muzzle-down break flick, two thumb-shove bumps, upward wrist-whip on shut
	var pk_break := _cod_punch(t, 0.20, 0.30)
	var pk_s1 := _cod_punch(t, 0.94, 0.22)
	var pk_s2 := _cod_punch(t, 1.22, 0.22)
	var pk_shut := _cod_punch(t, 1.58, 0.34)
	reload_pos_off += Vector3(0.0, -0.020, 0.006) * pk_break + Vector3(0.0, 0.008, -0.004) * (pk_s1 + pk_s2) + Vector3(0.0, 0.022, 0.006) * pk_shut
	reload_rot_off += Vector3(-0.10, 0.0, 0.03) * pk_break + Vector3(0.03, 0.0, 0.02) * (pk_s1 + pk_s2) + Vector3(0.14, 0.0, -0.05) * pk_shut
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_famas() -> void:
	# Bullpup rear magazine swap -> on empty a visible sweep up to the carry-handle charging lever & sharp pull
	var t := reload_elapsed
	var cant_p := Vector3(-0.045, 0.068, -0.18)
	var cant_r := Vector3(0.22, 0.62, -0.42)
	var eject_dir := Vector3(0.0, -0.95, 0.30).normalized()
	# Charging lever sits under the carry handle: roll the rifle back toward upright so the pull stays in frame
	var rack_p := Vector3(-0.060, 0.072, -0.120)
	var rack_r := Vector3(0.20, 0.30, -0.18)
	var hand_ch_p := Vector3(0.020, 0.085, -0.035)
	var hand_ch_r := Vector3(-0.30, 0.20, 0.30)
	if _reload_event(0.24, 1):
		_play_reload_sfx(_sfx_mag_out, 1.06)
		_reload_cam_kick(-0.008, 0.006, 0.0, 0.0)
	if _reload_event(0.56, 32):
		_spawn_dropped_mag(12)
	if _reload_event(1.18, 2):
		_play_reload_sfx(_sfx_mag_in, 1.06)
		_reload_cam_kick(0.014, -0.008, 0.008, 0.0)
	if _reload_event(1.26, 4):
		_commit_mag_ammo()
		if not reload_was_empty:
			weapon_chambered[12] = true
		trauma = minf(1.0, trauma + 0.09)
	if reload_was_empty and _reload_event(1.72, 8):
		weapon_chambered[12] = true
		_play_reload_sfx(_sfx_bolt, 1.08)
		_reload_cam_kick(-0.012, 0.012, 0.008, 0.11)
	var tail0 := 1.86 if reload_was_empty else reload_dur - 0.35
	var env_u := _cod_ease_out(t / 0.22) * (1.0 - smoothstep(tail0, reload_dur, t))
	var rack_u := 0.0
	if reload_was_empty:
		rack_u = smoothstep(1.36, 1.54, t) * (1.0 - smoothstep(1.80, 2.05, t))
	reload_pos_off = cant_p.lerp(rack_p, rack_u) * env_u if rack_u > 0.0 else cant_p * env_u
	reload_rot_off = cant_r.lerp(rack_r, rack_u) * env_u if rack_u > 0.0 else cant_r * env_u
	if not reload_was_empty or t < 1.36:
		# Lively shoulder drift during the pouch fetch
		var fdip := sin(smoothstep(0.60, 0.92, t) * PI)
		reload_pos_off += Vector3(-0.008, -0.022, 0.006) * fdip
		reload_rot_off += Vector3(-0.04, 0.03, 0.05) * fdip
	var hand_mag_p := Vector3(0.015, -0.085, 0.14)
	var hand_mag_r := Vector3(-0.46, 0.24, 0.36)
	if t < 0.62:
		var u := 0.12 * smoothstep(0.24, 0.29, t) + 0.88 * _cod_ease_out((t - 0.29) / 0.27)
		var mp := eject_dir * (0.24 * u)
		_pose_part("mag", mp, Vector3(0.18 * u, 0.0, 0.0), Vector3.ZERO, t < 0.56)
		_pose_part("arm_left", hand_mag_p * _cod_ease_out(t / 0.22) + mp, hand_mag_r * _cod_ease_out(t / 0.22), PIVOT_AR_HAND)
	elif t < 0.90:
		_pose_part("mag", eject_dir * 0.24, Vector3.ZERO, Vector3.ZERO, false)
		var fu := sin(smoothstep(0.62, 0.90, t) * PI)
		_pose_part("arm_left", hand_mag_p + eject_dir * (0.28 + 0.04 * fu), hand_mag_r + Vector3(-0.12, 0.06, 0.08) * fu, PIVOT_AR_HAND)
	elif t < 1.30:
		# Two-stage: align the lip to the rear magwell, then a crisp punch-up seat
		var u_al := _cod_ease_out((t - 0.90) / 0.16)
		var u_seat := smoothstep(1.08, 1.19, t)
		var dist := lerpf(lerpf(0.24, 0.07, u_al), 0.0, u_seat)
		var mp := eject_dir * dist
		_pose_part("mag", mp, Vector3(lerpf(lerpf(0.18, 0.07, u_al), 0.0, u_seat), 0.0, 0.0), Vector3.ZERO, true)
		var hs := maxf(0.0, sin(smoothstep(1.14, 1.28, t) * PI))
		_pose_part("arm_left", hand_mag_p + mp + Vector3(0.0, 0.016 * hs, 0.0), hand_mag_r, PIVOT_AR_HAND)
	elif reload_was_empty and t < 2.05:
		_pose_part("mag", Vector3.ZERO)
		# Support hand sweeps up the receiver to the charging lever, rips it back, lets it fly home at 1.72s
		var reach := _cod_ease_out((t - 1.30) / 0.22)
		var pull := 0.0
		if t < 1.70:
			pull = _cod_ease_out((t - 1.58) / 0.10)
		else:
			pull = 1.0 - smoothstep(1.70, 1.74, t)
		var back := smoothstep(1.82, 2.05, t)
		var ap := hand_mag_p.lerp(hand_ch_p, reach).lerp(Vector3.ZERO, back) + Vector3(0.0, 0.0, 0.060 * pull)
		var ar := hand_mag_r.lerp(hand_ch_r, reach).lerp(Vector3.ZERO, back)
		_pose_part("arm_left", ap, ar, PIVOT_AR_HAND)
	else:
		_pose_part("mag", Vector3.ZERO)
		if reload_was_empty:
			_pose_part("arm_left", Vector3.ZERO, Vector3.ZERO, PIVOT_AR_HAND)
		else:
			var ret := _cod_ease_out((t - 1.30) / maxf(reload_dur - 1.30, 0.05))
			_pose_part("arm_left", hand_mag_p.lerp(Vector3.ZERO, ret), hand_mag_r.lerp(Vector3.ZERO, ret), PIVOT_AR_HAND)
	var pk_seat := _cod_punch(t, 1.17, 0.36)
	reload_pos_off += Vector3(0.0, 0.026, -0.010) * pk_seat
	reload_rot_off += Vector3(0.09, 0.0, 0.06) * pk_seat
	if reload_was_empty:
		var pk_ch := _cod_punch(t, 1.71, 0.34)
		reload_pos_off += Vector3(0.0, -0.010, 0.016) * pk_ch
		reload_rot_off += Vector3(-0.05, 0.0, -0.06) * pk_ch
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_garand() -> void:
	# M1 Garand: (tactical) yank op-rod & PING the part-spent clip free -> top en-bloc 8-round clip,
	# two-stage thumb press -> quick thumb-pull clear -> violent op-rod/bolt slam home
	var t := reload_elapsed
	var o := 0.0 if reload_was_empty else 0.24
	var cant_p := Vector3(-0.042, 0.095, -0.055)
	var cant_r := Vector3(0.24, 0.34, -0.32)
	if not reload_was_empty and _reload_event(0.20, 16):
		# Tactical top-off: rounds still in the ejected clip go back to the bandolier
		ammo_reserve[13] += ammo_in_mag[13]
		ammo_in_mag[13] = 0
		weapon_chambered[13] = false
		if sfx_casing and _sfx_garand_ping:
			sfx_casing.stream = _sfx_garand_ping
			sfx_casing.pitch_scale = randf_range(0.98, 1.04)
			sfx_casing.play()
		_spawn_garand_clip_eject()
		_reload_cam_kick(-0.010, 0.010, 0.006, 0.04)
	if _reload_event(0.22 + o, 1):
		weapon_chambered[13] = false
		_play_reload_sfx(_sfx_bolt, 0.95)
	if _reload_event(0.80 + o, 2):
		_play_reload_sfx(_sfx_mag_in, 1.10)
		_reload_cam_kick(0.006, -0.004, 0.004, 0.0)
	if _reload_event(1.06 + o, 32):
		_play_reload_sfx(_sfx_mag_in, 1.22)
		_reload_cam_kick(0.010, -0.006, 0.006, 0.0)
	if _reload_event(1.20 + o, 4):
		_commit_mag_ammo()
		weapon_chambered[13] = true
		_play_reload_sfx(_sfx_bolt, 1.06)
		_reload_cam_kick(-0.022, 0.014, 0.012, 0.14)
	var env_u := _cod_ease_out(t / 0.24) * (1.0 - smoothstep(1.50 + o, reload_dur, t))
	reload_pos_off = cant_p * env_u
	reload_rot_off = cant_r * env_u
	var tt := t - o
	# Two-stage press: thumb drives the clip halfway, re-sets, then drives it fully home under the bolt
	var clip_vis := tt >= 0.42 and tt < 1.22
	var p1 := _cod_ease_out((tt - 0.46) / 0.30)
	var p2 := _cod_ease_out((tt - 0.92) / 0.14)
	var press_u := lerpf(0.0, 0.55, p1) + 0.45 * p2
	var clip_drop := lerpf(0.085, -0.015, press_u)
	_pose_part("mag", Vector3(0.0, clip_drop, 0.0), Vector3.ZERO, Vector3.ZERO, clip_vis)
	# Right hand fetches the clip and is already holding it over the breech when it appears (never floats)
	var rh := _cod_ease_out((tt - 0.16) / 0.26) * (1.0 - smoothstep(1.30, 1.50, tt))
	# Thumb lifts for the re-set between presses, then snaps up & right clear of the bolt face
	var reset_lift := sin(smoothstep(0.78, 0.92, tt) * PI) * 0.018
	var clear := _cod_ease_out((tt - 1.10) / 0.09) * (1.0 - smoothstep(1.30, 1.50, tt))
	var rh_p := Vector3(0.025 * rh, (0.145 - 0.085 * press_u) * rh + reset_lift + 0.045 * clear, -0.075 * rh)
	rh_p += Vector3(0.030, 0.0, 0.020) * clear
	if not reload_was_empty and t < o + 0.26:
		# Tactical: right hand yanks the op-rod handle rearward to pop the clip
		var yank := sin(smoothstep(0.04, o + 0.22, t) * PI)
		rh_p = Vector3(0.030, 0.030, 0.060) * yank
	_pose_part("arm_right", rh_p, Vector3(0.28 * rh, -0.22 * rh, -0.32 * rh) + Vector3(0.0, 0.0, -0.20) * clear)
	var pk_p1 := _cod_punch(tt, 0.74, 0.24)
	var pk_p2 := _cod_punch(tt, 1.04, 0.22)
	var pk_slam := _cod_punch(tt, 1.19, 0.38)
	reload_pos_off += Vector3(0.0, -0.010, 0.0) * (pk_p1 + pk_p2) + Vector3(0.0, -0.016, 0.022) * pk_slam
	reload_rot_off += Vector3(-0.04, 0.0, 0.0) * (pk_p1 + pk_p2) + Vector3(-0.08, 0.02, 0.09) * pk_slam
	if not reload_was_empty:
		var pk_pop := _cod_punch(t, 0.18, 0.32)
		reload_pos_off += Vector3(0.0, 0.012, 0.014) * pk_pop
		reload_rot_off += Vector3(0.05, 0.0, -0.04) * pk_pop
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_kar98k() -> void:
	# Kar98k Mauser: crisp bolt lift & pull -> stripper clip aligned in the charger guide -> five stepped
	# thumb-strip pulses -> clip flicked clear -> authoritative bolt slam & lock
	var t := reload_elapsed
	var cant_p := Vector3(-0.046, 0.105, -0.058)
	var cant_r := Vector3(0.26, 0.38, -0.36)
	if _reload_event(0.24, 1):
		weapon_chambered[14] = false
		if _sniper_pending_eject:
			_sniper_pending_eject = false
			_eject_brass_casing(WEAPONS[14], false)
		_play_reload_sfx(_sfx_bolt, 0.80)
		_reload_cam_kick(-0.008, 0.008, 0.006, 0.0)
	var step_t0 := 0.66
	var step_len := 0.13
	for k in range(5):
		if _reload_event(step_t0 + step_len * float(k) + 0.07, 64 << k):
			_play_reload_sfx(_sfx_shell_in, 1.02 + 0.04 * float(k))
			_reload_cam_kick(0.004, -0.002, 0.002, 0.0)
	if _reload_event(1.32, 4):
		_commit_mag_ammo()
	if _reload_event(1.64, 8):
		weapon_chambered[14] = true
		_play_reload_sfx(_sfx_bolt, 0.92)
		_reload_cam_kick(-0.020, 0.014, 0.012, 0.11)
	var env_u := _cod_ease_out(t / 0.25) * (1.0 - smoothstep(1.80, reload_dur, t))
	reload_pos_off = cant_p * env_u
	reload_rot_off = cant_r * env_u
	# Bolt: snappy lift then pull open; on close it is thrown forward and slammed down into lock
	var lift := _cod_ease_out((t - 0.14) / 0.10)
	var pullb := _cod_ease_out((t - 0.22) / 0.14)
	var fwd_u := pow(smoothstep(1.50, 1.60, t), 1.6)
	var lock_u := smoothstep(1.60, 1.67, t)
	var bolt_open := pullb * (1.0 - fwd_u)
	var bolt_lift := lift * (1.0 - lock_u)
	_pose_part("bolt", Vector3(0.0, 0.0, 0.082 * bolt_open), Vector3(0.0, 0.0, 1.05 * bolt_lift))
	# Stripper clip: aligned into the charger guide, then stepped down one round per thumb pulse
	var fr_vis := t >= 0.46 and t < 1.38
	var align_u := _cod_ease_out((t - 0.46) / 0.16)
	var steps := 0.0
	for k in range(5):
		steps += smoothstep(step_t0 + step_len * float(k) + 0.02, step_t0 + step_len * float(k) + 0.08, t)
	var press_u := steps / 5.0
	var fr_drop := lerpf(0.12, 0.085, align_u) - 0.11 * press_u
	_pose_part("feed_round", Vector3(0.0, fr_drop, 0.0), Vector3(0.10 * (1.0 - align_u), 0.0, 0.0), Vector3.ZERO, fr_vis)
	# Right hand is already on the clip when it appears in the charger guide (never a floating clip)
	var rh := _cod_ease_out((t - 0.12) / 0.30) * (1.0 - smoothstep(1.62, 1.80, t))
	var pulse := 0.0
	for k in range(5):
		pulse += maxf(0.0, sin(clampf((t - (step_t0 + step_len * float(k))) / step_len, 0.0, 1.0) * PI))
	pulse = clampf(pulse, 0.0, 1.0) if (t >= step_t0 and t < step_t0 + step_len * 5.0) else 0.0
	var flick := sin(smoothstep(1.30, 1.44, t) * PI)
	_pose_part("arm_right", Vector3(0.032 * rh + 0.02 * flick, (0.135 - 0.075 * press_u) * rh - 0.010 * pulse + 0.03 * flick, -0.055 * rh), Vector3(0.22 * rh, -0.22 * rh, -0.30 * rh - 0.12 * flick))
	var pk_open := _cod_punch(t, 0.33, 0.26)
	var pk_slam := _cod_punch(t, 1.60, 0.36)
	reload_pos_off += Vector3(0.0, 0.0, 0.008) * pk_open + Vector3(0.0, -0.012, -0.016) * pk_slam
	reload_rot_off += Vector3(0.02, 0.0, 0.03) * pk_open + Vector3(-0.07, 0.0, 0.08) * pk_slam
	if t >= step_t0 and t < step_t0 + step_len * 5.0:
		var ph := fmod(t - step_t0, step_len) / step_len
		var bump := sin(ph * PI) * (1.0 - ph)
		reload_pos_off += Vector3(0.0, -0.006, 0.0) * bump
		reload_rot_off += Vector3(-0.022, 0.0, 0.0) * bump
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_crossbow() -> void:
	# Heavy Crossbow: straining bowstring pull into the trigger latch (click) -> cant to a 3/4 view of the rail
	# -> fresh broadhead bolt dropped onto the rail and slid home under the retention spring (nock)
	var t := reload_elapsed
	if _reload_event(0.10, 1):
		if _sfx_bow_draw:
			_play_reload_sfx(_sfx_bow_draw, 1.15)
	if _reload_event(0.50, 2):
		_play_reload_sfx(_sfx_bolt, 1.36)
		_reload_cam_kick(-0.016, 0.010, 0.010, 0.08)
	if _reload_event(1.04, 4):
		if _sfx_bow_nock:
			_play_reload_sfx(_sfx_bow_nock, randf_range(0.97, 1.04))
		else:
			_play_reload_sfx(_sfx_shell_in, 1.2)
		_commit_mag_ammo()
		weapon_chambered[15] = true
		_reload_cam_kick(0.006, -0.004, 0.004, 0.0)
	# Phase A (0.06..0.52): strain. Muzzle tips down & stock comes in while the right hand hauls the string
	var strain := _cod_ease_out((t - 0.04) / 0.20) * (1.0 - smoothstep(0.50, 0.66, t))
	var effort := smoothstep(0.16, 0.48, t) * (1.0 - smoothstep(0.48, 0.52, t))
	var tremble := (sin(t * 57.0) * 0.6 + sin(t * 83.0) * 0.4) * effort
	var pull := smoothstep(0.08, 0.50, t) * (1.0 - smoothstep(0.52, 0.64, t))
	# Phase B (0.52..1.20): 3/4 cant so the rail, latch and bolt are read clearly
	var cant := _cod_ease_out((t - 0.52) / 0.18) * (1.0 - smoothstep(1.16, reload_dur, t))
	var strain_p := Vector3(-0.03, -0.025, 0.04)
	var strain_r := Vector3(-0.15, 0.18, -0.14)
	var cant_p := Vector3(-0.060, 0.060, -0.020)
	var cant_r := Vector3(0.30, 0.52, -0.40)
	reload_pos_off = strain_p * strain + cant_p * cant + Vector3(0.0015, 0.0012, 0.0) * tremble
	reload_rot_off = strain_r * strain + cant_r * cant + Vector3(0.006, 0.0, 0.008) * tremble
	_pose_part("arm_right", Vector3(0.0, 0.06 * pull, 0.14 * pull) + Vector3(0.0008, 0.0008, 0.0) * tremble, Vector3(-0.22 * pull, 0.0, 0.0))
	# Bolt: drops onto the rail from above, then slides rearward to seat
	var bolt_vis := t >= 0.70
	var drop_u := _cod_ease_out((t - 0.70) / 0.16)
	var slide_u := smoothstep(0.88, 1.05, t)
	var by := lerpf(0.055, 0.0, drop_u)
	var bz := lerpf(-0.12, 0.0, slide_u)
	_pose_part("bow_arrow", Vector3(0.0, by, bz), Vector3(lerpf(0.12, 0.0, drop_u), 0.0, 0.0), Vector3.ZERO, bolt_vis)
	var pk_latch := _cod_punch(t, 0.49, 0.30)
	var pk_drop := _cod_punch(t, 0.85, 0.22)
	var pk_seat := _cod_punch(t, 1.03, 0.28)
	reload_pos_off += Vector3(0.0, 0.018, 0.014) * pk_latch + Vector3(0.0, -0.006, 0.0) * pk_drop + Vector3(0.0, 0.0, 0.010) * pk_seat
	reload_rot_off += Vector3(0.07, 0.0, 0.03) * pk_latch + Vector3(-0.02, 0.0, 0.0) * pk_drop + Vector3(0.02, 0.0, 0.03) * pk_seat
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_rpg7() -> void:
	# RPG-7: weighty launcher cant -> heavy PG-7V heave up from the pack -> nose-first insertion
	# down the muzzle -> firm palm twist & shove until the locating lug clicks home
	var t := reload_elapsed
	# Launcher comes off the shoulder, muzzle swung in toward screen centre so the warhead insertion reads clearly
	var cant_p := Vector3(0.050, -0.020, -0.150)
	var cant_r := Vector3(0.25, 0.90, 0.10)
	if _reload_event(0.32, 1):
		_play_reload_sfx(_sfx_mag_out, 0.72)
	if _reload_event(1.40, 2):
		_play_reload_sfx(_sfx_mag_in, 0.68)
		_commit_mag_ammo()
		weapon_chambered[17] = true
		_reload_cam_kick(0.012, -0.012, 0.014, 0.14)
	# Heavy tube: slower ease-in with an inertial overshoot as it settles onto the shoulder
	var env_u := smoothstep(0.0, 0.40, t) * (1.0 - smoothstep(1.82, reload_dur, t))
	reload_pos_off = cant_p * env_u
	reload_rot_off = cant_r * env_u
	var wh_vis := t >= 0.62
	var heave := _cod_ease_out((t - 0.62) / 0.26)
	var ins := smoothstep(0.88, 1.28, t)
	var shove := _cod_ease_out((t - 1.30) / 0.10)
	var wh_y := lerpf(-0.10, 0.0, heave)
	var wh_z := lerpf(-0.24, lerpf(-0.045, 0.0, shove), ins)
	var twist := sin(smoothstep(1.26, 1.42, t) * PI) * 0.42
	_pose_part("warhead", Vector3(0.0, wh_y, wh_z), Vector3(0.10 * (1.0 - heave), 0.0, twist), Vector3.ZERO, wh_vis)
	var lh := sin(smoothstep(0.45, 1.65, t) * PI)
	_pose_part("arm_left", Vector3(0.02 * lh, -0.02 * lh + wh_y * 0.55 * lh, (-0.12 + wh_z * 0.45) * lh), Vector3(-0.42 * lh, 0.24 * lh, 0.32 * lh + twist * 0.6), PIVOT_AR_HAND)
	# Weight: the launcher dips as the warhead's mass comes onto it, then jolts with the lock-in shove
	var weight := sin(smoothstep(0.62, 1.10, t) * PI)
	var pk_settle := _cod_punch(t, 0.36, 0.40)
	var pk_lock := _cod_punch(t, 1.39, 0.40)
	reload_pos_off += Vector3(0.0, -0.014, 0.0) * weight + Vector3(0.0, -0.010, 0.0) * pk_settle + Vector3(0.0, 0.006, 0.024) * pk_lock
	reload_rot_off += Vector3(-0.05, 0.0, 0.0) * weight + Vector3(-0.03, 0.0, 0.02) * pk_settle + Vector3(0.04, 0.0, -0.06) * pk_lock
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_mp5() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.056, 0.148, -0.068)
	var cant_r := Vector3(0.30, 0.46, -0.52)
	var eject_dir := Vector3(-0.04, -0.94, -0.33).normalized()
	# Exact palm-to-mag wrap using PIVOT_AR_HAND (+0.034 X hugs curved 9mm mag with zero daylight!)
	var hand_mag_p := Vector3(0.034, -0.098, 0.088)
	var hand_mag_r := Vector3(-0.46, 0.24, 0.36)
	var hand_drop_r := Vector3(-0.58, 0.30, 0.44)
	var hand_extract_end := hand_mag_p + eject_dir * 0.24
	var hand_pouch_p := hand_extract_end + Vector3(-0.035, -0.055, 0.025)
	# Keep forearm rolled +Z and pitched -X like M16 bolt-catch slap -> ZERO sleeve bloat in camera!
	var slap_gun_p := Vector3(-0.040, 0.050, -0.135)
	var slap_gun_r := Vector3(0.22, 0.20, -0.36)
	var hand_slap_hi := Vector3(-0.036, 0.050, 0.012)
	var hand_slap_hit := Vector3(-0.016, 0.004, 0.016)
	# Positive pitch about the palm keeps the elbow DOWN out of the lens while the palm strikes
	var hand_slap_r := Vector3(0.10, 0.22, 0.32)

	if _reload_event(0.24, 1):
		_play_reload_sfx(_sfx_mag_out, 1.12)
		_reload_cam_kick(-0.008, 0.006, 0.0, 0.0)
	if _reload_event(0.56, 32):
		_spawn_dropped_mag(5)
	if _reload_event(1.14, 2):
		_play_reload_sfx(_sfx_mag_in, 1.14)
		_reload_cam_kick(0.014, -0.008, 0.008, 0.0)
	if _reload_event(1.22, 4):
		_commit_mag_ammo()
		if not reload_was_empty:
			weapon_chambered[5] = true
		trauma = minf(1.0, trauma + 0.08)
	if reload_was_empty and _reload_event(1.56, 8):
		# The iconic HK slap: palm strikes the cocking handle down out of its notch at 1.56s
		weapon_chambered[5] = true
		_play_reload_sfx(_sfx_bolt, 1.18)
		_reload_cam_kick(-0.018, 0.022, 0.012, 0.14)

	if reload_was_empty:
		var ch_u := 1.0 if t < 1.56 else (1.0 - smoothstep(1.56, 1.60, t))
		_pose_part("charge", Vector3(0.0, 0.0, 0.068 * ch_u), Vector3(0.0, 0.0, -0.52 * ch_u))
	else:
		_pose_part("charge", Vector3.ZERO)

	if t < 0.22:
		var u := _cod_ease_out(t / 0.22)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("arm_left", hand_mag_p * u, hand_mag_r * u, PIVOT_AR_HAND)
	elif t < 0.64:
		# Paddle release pops the mag a few mm, then the hand strips it out
		var u := 0.12 * smoothstep(0.24, 0.29, t) + 0.88 * _cod_ease_out((t - 0.29) / 0.27)
		var sw := sin(smoothstep(0.22, 0.62, t) * PI)
		reload_pos_off = cant_p + Vector3(0, -0.020 * sw, 0)
		reload_rot_off = cant_r + Vector3(0.05 * sw, 0, -0.06 * sw)
		var mp := eject_dir * (0.24 * u)
		_pose_part("mag", mp, Vector3(0.24 * u, 0.0, -0.08 * u), Vector3.ZERO, t < 0.56)
		_pose_part("arm_left", hand_mag_p + mp, hand_mag_r.lerp(hand_drop_r, u), PIVOT_AR_HAND)
	elif t < 0.94:
		# Empty magwell beat while the support hand dips to the pouch; the shoulder rolls with it
		var u := smoothstep(0.64, 0.94, t)
		var dip := sin(u * PI)
		reload_pos_off = cant_p + Vector3(-0.010 * dip, -0.026 * dip, 0.010 * dip)
		reload_rot_off = cant_r + Vector3(-0.04 * dip, 0.03 * dip, 0.06 * dip)
		_pose_part("mag", eject_dir * 0.24, Vector3.ZERO, Vector3.ZERO, false)
		var arm_p := hand_extract_end.lerp(hand_pouch_p, smoothstep(0.0, 0.45, u)) if u < 0.5 else hand_pouch_p.lerp(hand_mag_p + eject_dir * 0.22, smoothstep(0.5, 1.0, u))
		_pose_part("arm_left", arm_p, hand_drop_r.lerp(hand_mag_r, smoothstep(0.5, 1.0, u)), PIVOT_AR_HAND)
	elif t < 1.30:
		# Two-stage: angle the mag into the well, then a hard punch-up seat
		var u_al := _cod_ease_out((t - 0.94) / 0.14)
		var u_seat := smoothstep(1.06, 1.16, t)
		var dist := lerpf(lerpf(0.22, 0.06, u_al), 0.0, u_seat)
		reload_pos_off = cant_p
		reload_rot_off = cant_r
		var mp := eject_dir * dist
		_pose_part("mag", mp, Vector3(lerpf(lerpf(0.22, 0.08, u_al), 0.0, u_seat), 0.0, 0.0), Vector3.ZERO, true)
		var hs := maxf(0.0, sin(smoothstep(1.12, 1.26, t) * PI))
		_pose_part("arm_left", hand_mag_p + mp + Vector3(0.0, 0.018 * hs, 0.0), hand_mag_r, PIVOT_AR_HAND)
	elif reload_was_empty and t < 1.80:
		# Palm winds up high over the cocking tube, then strikes DOWN hard at 1.56s
		var u := smoothstep(1.30, 1.80, t)
		var wind := _cod_ease_out((t - 1.30) / 0.16)
		var strike := pow(smoothstep(1.47, 1.56, t), 1.8)
		reload_pos_off = cant_p.lerp(slap_gun_p, u)
		reload_rot_off = cant_r.lerp(slap_gun_r, u)
		_pose_part("mag", Vector3.ZERO)
		var arm_p := hand_mag_p.lerp(hand_slap_hi, wind) if t < 1.47 else hand_slap_hi.lerp(hand_slap_hit, strike)
		_pose_part("arm_left", arm_p, hand_mag_r.lerp(hand_slap_r, wind), PIVOT_AR_HAND)
	else:
		var s0 := 1.80 if reload_was_empty else 1.30
		var u := _cod_ease_out((t - s0) / maxf(reload_dur - s0, 0.05))
		var prev_p := slap_gun_p if reload_was_empty else cant_p
		var prev_r := slap_gun_r if reload_was_empty else cant_r
		reload_pos_off = prev_p.lerp(Vector3.ZERO, u)
		reload_rot_off = prev_r.lerp(Vector3.ZERO, u)
		_pose_part("mag", Vector3.ZERO)
		var prev_arm := hand_slap_hit if reload_was_empty else hand_mag_p
		var prev_ar := hand_slap_r if reload_was_empty else hand_mag_r
		_pose_part("arm_left", prev_arm.lerp(Vector3.ZERO, u), prev_ar.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)
	var pk_seat := _cod_punch(t, 1.14, 0.36)
	reload_pos_off += Vector3(0.0, 0.028, -0.012) * pk_seat
	reload_rot_off += Vector3(0.09, 0.0, 0.06) * pk_seat
	if reload_was_empty:
		var pk_slap := _cod_punch(t, 1.555, 0.36)
		reload_pos_off += Vector3(0.018, -0.028, 0.006) * pk_slap
		reload_rot_off += Vector3(0.02, 0.0, -0.17) * pk_slap
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_ak74() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.058, 0.150, -0.072)
	var cant_r := Vector3(0.30, 0.46, -0.50)
	# Exact palm contact wrapping AK-74M curved plum mag using PIVOT_AR_HAND!
	var hand_mag_p := Vector3(0.040, -0.088, 0.078)
	var hand_mag_r := Vector3(-0.48, 0.24, 0.36)
	var hand_drop_r := Vector3(-0.62, 0.32, 0.46)
	var extract_end_mp := Vector3(-0.015, -0.25, -0.055)
	var hand_extract_end := hand_mag_p + extract_end_mp
	var hand_pouch_p := hand_extract_end + Vector3(-0.04, -0.06, 0.025)
	# 3/4 view exposing right-side AK charging handle so gloved hand pulling bolt back is unmistakable!
	var rack_pos := Vector3(-0.090, 0.102, -0.055)
	var rack_rot := Vector3(0.24, -0.56, 0.56)
	var hand_bolt_p := Vector3(0.042, 0.046, 0.095)
	var hand_bolt_r := Vector3(-0.40, 0.30, 0.48)

	if _reload_event(0.24, 1):
		_play_reload_sfx(_sfx_mag_out, 0.94)
		_reload_cam_kick(-0.008, 0.006, 0.0, 0.0)
	if _reload_event(0.66, 32):
		_spawn_dropped_mag(8)
	if _reload_event(1.26, 16):
		# Front lug hooks into the magwell: a dull metal tick before the rock
		_play_reload_sfx(_sfx_shell_in, 0.80)
		_reload_cam_kick(0.004, 0.0, 0.002, 0.0)
	if _reload_event(1.42, 2):
		_play_reload_sfx(_sfx_mag_in, 0.92)
		_reload_cam_kick(0.014, -0.010, 0.008, 0.0)
	if _reload_event(1.44, 4):
		_commit_mag_ammo()
		if not reload_was_empty:
			weapon_chambered[8] = true
		trauma = minf(1.0, trauma + 0.10)
	if reload_was_empty and _reload_event(1.82, 8):
		weapon_chambered[8] = true
		_play_reload_sfx(_sfx_bolt, 0.92)
		_reload_cam_kick(-0.016, 0.016, 0.010, 0.12)

	if t < 0.24:
		var u := _cod_ease_out(t / 0.24)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("bolt", Vector3.ZERO)
		_pose_part("arm_left", hand_mag_p * u, hand_mag_r * u, PIVOT_AR_HAND)
	elif t < 0.72:
		# Thumb on the paddle, mag rocked FORWARD off the rear latch, then stripped down & out
		var u_rock := _cod_ease_out((t - 0.24) / 0.14)
		var u_pull := _cod_ease_out((t - 0.36) / 0.28)
		var sw := sin(smoothstep(0.24, 0.66, t) * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.022 * sw, 0.010 * sw)
		reload_rot_off = cant_r + Vector3(0.07 * sw, 0.0, -0.07 * sw)
		var mp := extract_end_mp * u_pull
		var mr := Vector3(0.52 * u_rock, 0.0, 0.0)
		_pose_part("mag", mp, mr, Vector3.ZERO, t < 0.66)
		_pose_part("bolt", Vector3.ZERO)
		_pose_part("arm_left", hand_mag_p + mp, hand_mag_r.lerp(hand_drop_r, u_pull), PIVOT_AR_HAND)
	elif t < 1.04:
		# EMPTY MAGWELL beat; the shoulder rolls toward the pouch and never freezes
		var u := smoothstep(0.72, 1.04, t)
		var dip := sin(u * PI)
		reload_pos_off = cant_p + Vector3(-0.010 * dip, -0.026 * dip, 0.010 * dip)
		reload_rot_off = cant_r + Vector3(-0.05 * dip, 0.03 * dip, 0.06 * dip)
		_pose_part("mag", extract_end_mp, Vector3(0.52, 0.0, 0.0), Vector3.ZERO, false)
		_pose_part("bolt", Vector3.ZERO)
		var arm_p := hand_extract_end.lerp(hand_pouch_p, smoothstep(0.0, 0.45, u)) if u < 0.5 else hand_pouch_p.lerp(hand_mag_p + extract_end_mp, smoothstep(0.5, 1.0, u))
		_pose_part("arm_left", arm_p, hand_drop_r.lerp(hand_mag_r, smoothstep(0.5, 1.0, u)), PIVOT_AR_HAND)
	elif t < 1.52:
		# ROCK-AND-LOCK: mag comes up nose-tilted, front lug HOOKS (beat), then rocks back into the latch CLICK
		var u_up := _cod_ease_out((t - 1.04) / 0.20)
		var u_rock := _cod_ease_out((t - 1.32) / 0.10)
		var hook_hold := smoothstep(1.22, 1.26, t) * (1.0 - smoothstep(1.32, 1.36, t))
		reload_pos_off = cant_p + Vector3(0.0, 0.004 * hook_hold, 0.0)
		reload_rot_off = cant_r + Vector3(0.012 * hook_hold, 0.0, 0.0)
		var mp := extract_end_mp.lerp(Vector3.ZERO, u_up)
		var mr := Vector3(lerpf(0.52, 0.0, u_rock), 0.0, 0.0)
		_pose_part("mag", mp, mr, Vector3.ZERO, true)
		_pose_part("bolt", Vector3.ZERO)
		var hs := maxf(0.0, sin(smoothstep(1.38, 1.52, t) * PI))
		_pose_part("arm_left", hand_mag_p + mp + Vector3(0.0, 0.016 * hs, 0.0), hand_mag_r, PIVOT_AR_HAND)
	elif reload_was_empty and t < 2.06:
		# Roll the rifle onto its left side; overhand grab of the right-side charging handle, rip it back, let it slam
		var reach := _cod_ease_out((t - 1.52) / 0.16)
		var pull := 0.0
		if t < 1.80:
			pull = _cod_ease_out((t - 1.69) / 0.09)
		else:
			pull = 1.0 - smoothstep(1.80, 1.84, t)
		var hold := smoothstep(1.86, 2.06, t)
		reload_pos_off = cant_p.lerp(rack_pos, reach)
		reload_rot_off = cant_r.lerp(rack_rot, reach)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("bolt", Vector3(0.0, 0.0, 0.078 * pull))
		_pose_part("arm_left", hand_mag_p.lerp(hand_bolt_p, reach) + Vector3(0.0, 0.0, 0.072 * pull) + Vector3(0.0, 0.006, 0.0) * hold, hand_mag_r.lerp(hand_bolt_r, reach), PIVOT_AR_HAND)
	else:
		var s0 := 2.06 if reload_was_empty else 1.52
		var u := _cod_ease_out((t - s0) / maxf(reload_dur - s0, 0.05))
		var prev_p := rack_pos if reload_was_empty else cant_p
		var prev_r := rack_rot if reload_was_empty else cant_r
		var prev_ap := (hand_bolt_p + Vector3(0.0, 0.006, 0.0)) if reload_was_empty else hand_mag_p
		var prev_ar := hand_bolt_r if reload_was_empty else hand_mag_r
		reload_pos_off = prev_p.lerp(Vector3.ZERO, u)
		reload_rot_off = prev_r.lerp(Vector3.ZERO, u)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("bolt", Vector3.ZERO)
		_pose_part("arm_left", prev_ap.lerp(Vector3.ZERO, u), prev_ar.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)
	var pk_lock := _cod_punch(t, 1.42, 0.38)
	reload_pos_off += Vector3(0.0, 0.026, -0.012) * pk_lock
	reload_rot_off += Vector3(0.10, 0.0, 0.07) * pk_lock
	if reload_was_empty:
		var pk_bolt := _cod_punch(t, 1.81, 0.36)
		reload_pos_off += Vector3(0.012, -0.012, 0.008) * pk_bolt
		reload_rot_off += Vector3(-0.04, 0.0, 0.09) * pk_bolt
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_benelli(delta: float) -> void:
	# Interruptible shell-by-shell: brisk rhythmic thumb shoves with an upward receiver bump; empty = fast side-bolt rack
	reload_shell_timer += delta
	# Push Benelli forward (-0.088 Z) & counter-roll arm_left (+0.85 Z) so elbow stays tucked down-left (ZERO sleeve bloat!)
	var cant_p := Vector3(-0.044, 0.118, -0.088)
	var cant_r := Vector3(0.22, 0.34, -0.82)
	var hand_caddy_p := Vector3(-0.025, -0.140, 0.045)
	var hand_caddy_r := Vector3(-0.26, 0.14, 0.88)
	var hand_port_p := Vector3(0.012, -0.052, 0.040)
	var hand_port_r := Vector3(-0.22, 0.12, 0.85)
	var hand_push_p := Vector3(0.016, -0.020, 0.018)
	var hand_push_r := Vector3(-0.18, 0.10, 0.82)
	var rack_p := Vector3(-0.080, 0.088, -0.055)
	var rack_r := Vector3(0.18, -0.52, 0.48)
	var hand_bolt_p := Vector3(0.036, 0.036, 0.075)
	var hand_bolt_r := Vector3(-0.38, 0.30, 0.46)
	var mag_cap := get_weapon_mag_size(9)

	var p_start := Vector3(0.0, -0.145, -0.105)
	var p_port := Vector3(0.0, -0.042, -0.128)
	var p_enter := Vector3(0.0, -0.016, -0.158)
	var p_seat := Vector3(0.0, -0.008, -0.195)

	if reload_shell_phase == 0:
		if is_instance_valid(_benelli_shell_rig):
			_benelli_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		if reload_cancel_req and ammo_in_mag[9] > 0:
			reload_shell_phase = 2
			reload_shell_timer = 0.0
			reload_flags = 0
			_shotgun_exit_arm_p = hand_caddy_p * smoothstep(0.0, 0.24, reload_shell_timer)
			_shotgun_exit_arm_r = hand_caddy_r * smoothstep(0.0, 0.24, reload_shell_timer)
			return
		var u := _cod_ease_out(reload_shell_timer / 0.24)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("arm_left", hand_caddy_p * u, hand_caddy_r * u, PIVOT_AR_HAND)
		if reload_shell_timer >= 0.24:
			reload_shell_phase = 1
			reload_shell_timer = 0.0
			reload_flags = 0
	elif reload_shell_phase == 1:
		var st := reload_shell_timer
		# Upward receiver bump on every thumb shove (spring-damped), plus a light rhythmic shoulder bob
		var bump := _cod_punch(st, 0.25, 0.14) if st < 0.39 else 0.0
		var bob := sin(clampf(st / 0.38, 0.0, 1.0) * PI)
		reload_pos_off = cant_p + Vector3(0.0, 0.020 * bump - 0.004 * bob, -0.010 * bump)
		reload_rot_off = cant_r + Vector3(-0.06 * bump, 0.0, 0.08 * bump + 0.02 * bob)
		var lift_u := sin(smoothstep(0.13, 0.31, st) * PI) if (st >= 0.13 and st < 0.31) else 0.0
		_pose_part("lifter", Vector3(0.0, 0.012 * lift_u, 0.0), Vector3(0.24 * lift_u, 0.0, 0.0))

		var cur_ap := hand_caddy_p
		var cur_ar := hand_caddy_r
		if st < 0.14:
			var a := _cod_ease_out(st / 0.14)
			cur_ap = hand_caddy_p.lerp(hand_port_p, a)
			cur_ar = hand_caddy_r.lerp(hand_port_r, a)
			if is_instance_valid(_benelli_shell_rig):
				_benelli_shell_rig.visible = true
				_benelli_shell_rig.position = p_start.lerp(p_port, a)
				_benelli_shell_rig.rotation = Vector3(0.38, 0.18, 0.14).lerp(Vector3(0.22, 0.0, 0.0), a)
		elif st < 0.22:
			var b := smoothstep(0.14, 0.22, st)
			cur_ap = hand_port_p.lerp(hand_push_p, b * 0.55)
			cur_ar = hand_port_r.lerp(hand_push_r, b * 0.55)
			if is_instance_valid(_benelli_shell_rig):
				_benelli_shell_rig.visible = true
				_benelli_shell_rig.position = p_port.lerp(p_enter, b)
				_benelli_shell_rig.rotation = Vector3(lerpf(0.22, 0.08, b), 0.0, 0.0)
		elif st < 0.30:
			# Hard thumb shove: accelerates into the tube
			var c := pow(smoothstep(0.22, 0.29, st), 1.5)
			cur_ap = hand_port_p.lerp(hand_push_p, lerpf(0.55, 1.0, c))
			cur_ar = hand_port_r.lerp(hand_push_r, lerpf(0.55, 1.0, c))
			if is_instance_valid(_benelli_shell_rig):
				_benelli_shell_rig.visible = c < 0.90
				_benelli_shell_rig.position = p_enter.lerp(p_seat, c)
				_benelli_shell_rig.rotation = Vector3(lerpf(0.08, 0.0, c), 0.0, 0.0)
		else:
			var d := _cod_ease_out((st - 0.30) / 0.08)
			cur_ap = hand_push_p.lerp(hand_caddy_p, d)
			cur_ar = hand_push_r.lerp(hand_caddy_r, d)
			if is_instance_valid(_benelli_shell_rig):
				_benelli_shell_rig.visible = false
		_pose_part("arm_left", cur_ap, cur_ar, PIVOT_AR_HAND)

		# Single unified shell-commit event at seating (0.28s) so sound, visual vanish, and ammo count match 100%!
		if st >= 0.28 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_shell_in, randf_range(1.00, 1.08))
			_reload_cam_kick(0.006, -0.004, 0.004, 0.0)
			if ammo_in_mag[9] < mag_cap and ammo_reserve[9] > 0:
				ammo_in_mag[9] += 1
				ammo_reserve[9] -= 1
				trauma = minf(1.0, trauma + 0.05)

		if st >= 0.38 or (reload_cancel_req and ammo_in_mag[9] > 0 and (st >= 0.30 or (st < 0.14 and not reload_was_empty))):
			if reload_cancel_req or ammo_in_mag[9] >= mag_cap or ammo_reserve[9] <= 0:
				_shotgun_exit_arm_p = cur_ap
				_shotgun_exit_arm_r = cur_ar
				reload_shell_phase = 2
				reload_shell_timer = 0.0
				reload_flags = 0
				_pose_part("lifter", Vector3.ZERO)
				if is_instance_valid(_benelli_shell_rig):
					_benelli_shell_rig.visible = false
			else:
				reload_shell_timer = 0.0
				reload_flags = 0
	elif reload_shell_phase == 2:
		if is_instance_valid(_benelli_shell_rig):
			_benelli_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		var et := reload_shell_timer
		var exit_dur := 0.50 if reload_was_empty else (0.14 if reload_cancel_req else 0.24)
		var u := _cod_ease_out(et / exit_dur)
		if reload_was_empty:
			var roll_in := _cod_ease_out(et / 0.14)
			var roll_out := smoothstep(0.34, exit_dur, et)
			# Fast side-bolt rack: snatch back (0.14..0.21), release slams forward (0.23..0.26)
			var rack := 0.0
			if et < 0.23:
				rack = _cod_ease_out((et - 0.14) / 0.07)
			else:
				rack = 1.0 - smoothstep(0.23, 0.26, et)
			var pk_r := _cod_punch(et, 0.245, 0.26)
			reload_pos_off = cant_p.lerp(rack_p, roll_in).lerp(Vector3.ZERO, roll_out) + Vector3(0.010, -0.010, 0.008) * pk_r
			reload_rot_off = cant_r.lerp(rack_r, roll_in).lerp(Vector3.ZERO, roll_out) + Vector3(-0.03, 0.0, 0.08) * pk_r
			_pose_part("bolt", Vector3(0.0, 0.0, 0.068 * rack))
			var arm_p := _shotgun_exit_arm_p.lerp(hand_bolt_p, roll_in).lerp(Vector3.ZERO, roll_out) + Vector3(0.0, 0.0, 0.064 * rack)
			var arm_r := _shotgun_exit_arm_r.lerp(hand_bolt_r, roll_in).lerp(Vector3.ZERO, roll_out)
			_pose_part("arm_left", arm_p, arm_r, PIVOT_AR_HAND)
			if et >= 0.24 and not (reload_flags & 4):
				reload_flags |= 4
				weapon_chambered[9] = true
				_play_reload_sfx(_sfx_bolt, 0.96)
				_reload_cam_kick(-0.014, 0.014, 0.010, 0.10)
		else:
			reload_pos_off = cant_p.lerp(Vector3.ZERO, u)
			reload_rot_off = cant_r.lerp(Vector3.ZERO, u)
			_pose_part("arm_left", _shotgun_exit_arm_p.lerp(Vector3.ZERO, u), _shotgun_exit_arm_r.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)
		if reload_shell_timer >= exit_dur:
			weapon_chambered[9] = true
			is_reloading = false
			reload_cancel_req = false
			_reset_weapon_parts()


func _update_reload_m249() -> void:
	# Weighty LMG: TopCover pops up (optic rides with it) -> heavy box swap -> belt draped & patted onto the tray
	# -> brutal downward TopCover slam -> heavy charging-handle pull
	var t := reload_elapsed
	var cant_p := Vector3(-0.048, 0.095, -0.055)
	var cant_r := Vector3(0.20, 0.30, -0.26)
	var hand_lid_p := Vector3(-0.024, 0.022, 0.012)
	var hand_lid_r := Vector3(-0.28, 0.16, 0.26)
	var hand_box_p := Vector3(0.006, -0.092, 0.078)
	var hand_box_r := Vector3(-0.50, 0.22, 0.34)
	var hand_belt_p := Vector3(-0.020, 0.044, 0.068)
	var hand_belt_r := Vector3(-0.40, 0.18, 0.28)
	var rack_p := Vector3(-0.082, 0.088, -0.055)
	var rack_r := Vector3(0.18, -0.52, 0.50)
	var hand_charge_p := Vector3(0.045, 0.032, 0.068)
	var hand_charge_r := Vector3(-0.36, 0.30, 0.48)

	if _reload_event(0.24, 1):
		_play_reload_sfx(_sfx_bolt, 0.72)
		_reload_cam_kick(0.008, -0.006, 0.0, 0.0)
	if _reload_event(0.62, 2):
		_play_reload_sfx(_sfx_mag_out, 0.78)
	if _reload_event(1.02, 32):
		_spawn_dropped_mag(10)
		_reload_cam_kick(0.006, 0.006, 0.0, 0.0)
	if _reload_event(1.94, 4):
		_play_reload_sfx(_sfx_mag_in, 0.76)
		_reload_cam_kick(0.014, -0.010, 0.008, 0.10)
	if _reload_event(2.26, 16):
		_play_reload_sfx(_sfx_shell_in, 0.84)
	if _reload_event(2.60, 8):
		_commit_mag_ammo()
		_play_reload_sfx(_sfx_bolt, 0.76)
		_reload_cam_kick(-0.024, 0.008, 0.012, 0.16)
	if _reload_event(3.07, 64):
		weapon_chambered[10] = true
		_play_reload_sfx(_sfx_bolt, 0.88)
		_reload_cam_kick(-0.016, 0.016, 0.012, 0.10)

	var lid_piv := Vector3(0.0, 0.0371, -0.3087)
	if t < 0.48:
		# Heavy gun: slower ease into the cant; TopCover springs UP off its latch at 0.24s
		var u := smoothstep(0.0, 0.48, t)
		var lid_u := _cod_ease_out((t - 0.20) / 0.14)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		var lid_rot := Vector3(-1.15 * lid_u, 0.0, 0.0)
		_pose_part("top_cover", Vector3.ZERO, lid_rot)
		_pose_optic_hood(Vector3.ZERO, lid_rot, lid_piv)
		_pose_part("ammo_belt", Vector3.ZERO)
		_pose_part("arm_left", hand_lid_p * _cod_ease_out(t / 0.22) + Vector3(0.0, 0.032 * lid_u, -0.016 * lid_u), hand_lid_r * _cod_ease_out(t / 0.22), PIVOT_AR_HAND)
	elif t < 1.15:
		# Sweep old belt off tray and pull 100-rd box down & drop it
		var u := _cod_ease_out((t - 0.55) / 0.50)
		var sw := sin(smoothstep(0.50, 1.15, t) * PI)
		reload_pos_off = cant_p + Vector3(-0.006, -0.016, 0.004) * sw
		reload_rot_off = cant_r + Vector3(-0.03, 0.02, 0.04) * sw
		_pose_part("top_cover", Vector3.ZERO, Vector3(-1.15, 0.0, 0.0))
		_pose_optic_hood(Vector3.ZERO, Vector3(-1.15, 0.0, 0.0), lid_piv)
		var mp := Vector3(-0.04 * u, -0.24 * u, 0.0)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, t < 1.02)
		_pose_part("ammo_belt", Vector3(-0.08 * u, -0.14 * u, 0.0), Vector3(0.0, 0.0, 0.45 * u), Vector3.ZERO, t < 0.92)
		var to_box := smoothstep(0.48, 0.62, t)
		var arm_to_box := (hand_lid_p + Vector3(0.0, 0.032, -0.016)).lerp(hand_box_p, to_box)
		_pose_part("arm_left", arm_to_box + mp, hand_lid_r.lerp(hand_box_r, to_box), PIVOT_AR_HAND)
	elif t < 2.08:
		# Heavy fresh 200-rd box hauled up: gun sags under the load, then locks with a jolt at 1.94s
		var u := smoothstep(1.32, 1.96, t)
		var haul := sin(smoothstep(1.15, 1.94, t) * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.018, 0.006) * haul
		reload_rot_off = cant_r + Vector3(-0.05, 0.02, 0.03) * haul
		_pose_part("top_cover", Vector3.ZERO, Vector3(-1.15, 0.0, 0.0))
		_pose_optic_hood(Vector3.ZERO, Vector3(-1.15, 0.0, 0.0), lid_piv)
		var mp := Vector3(lerpf(-0.04, 0.0, u), lerpf(-0.24, 0.0, u), 0.0)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, t >= 1.28)
		_pose_part("ammo_belt", Vector3(-0.06, -0.12, 0.0), Vector3(0.0, 0.0, 0.55), Vector3.ZERO, false)
		_pose_part("arm_left", hand_box_p + mp, hand_box_r, PIVOT_AR_HAND)
	elif t < 2.46:
		# Belt drawn up and draped across the steel FeedTray, then patted flat twice
		var u := _cod_ease_out((t - 2.08) / 0.18)
		reload_pos_off = cant_p
		reload_rot_off = cant_r
		_pose_part("top_cover", Vector3.ZERO, Vector3(-1.15, 0.0, 0.0))
		_pose_optic_hood(Vector3.ZERO, Vector3(-1.15, 0.0, 0.0), lid_piv)
		_pose_part("mag", Vector3.ZERO)
		var bp := Vector3(lerpf(-0.06, 0.0, u), lerpf(-0.08, 0.0, u), 0.0)
		_pose_part("ammo_belt", bp, Vector3(0.0, 0.0, lerpf(0.48, 0.0, u)), Vector3.ZERO, true)
		var pat := maxf(0.0, sin(clampf((t - 2.26) / 0.08, 0.0, 1.0) * PI)) + maxf(0.0, sin(clampf((t - 2.36) / 0.08, 0.0, 1.0) * PI))
		_pose_part("arm_left", hand_box_p.lerp(hand_belt_p, u) + Vector3(0.0, -0.010 * pat, 0.0), hand_box_r.lerp(hand_belt_r, u), PIVOT_AR_HAND)
	elif t < 2.76:
		# BRUTAL slam: the cover accelerates down (eased-in) and hits at 2.60s
		var close_u := pow(smoothstep(2.48, 2.60, t), 2.2)
		reload_pos_off = cant_p
		reload_rot_off = cant_r
		var close_rot := Vector3(-1.15 * (1.0 - close_u), 0.0, 0.0)
		_pose_part("top_cover", Vector3.ZERO, close_rot)
		_pose_optic_hood(Vector3.ZERO, close_rot, lid_piv)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("ammo_belt", Vector3.ZERO)
		var raise := sin(smoothstep(2.46, 2.52, t) * PI) * 0.012
		_pose_part("arm_left", hand_belt_p.lerp(hand_lid_p + Vector3(0.0, 0.015, 0.0), close_u) + Vector3(0.0, raise, 0.0), hand_belt_r.lerp(hand_lid_r, close_u), PIVOT_AR_HAND)
	elif t < 3.16:
		# Roll 3/4 right-side-up: heavy two-stage charge pull, release lets the bolt slam forward at 3.07s
		var reach := _cod_ease_out((t - 2.76) / 0.16)
		var pull := 0.0
		if t < 3.05:
			pull = smoothstep(2.90, 3.04, t)
		else:
			pull = 1.0 - smoothstep(3.05, 3.09, t)
		reload_pos_off = cant_p.lerp(rack_p, reach) + Vector3(0.0, -0.006, 0.006) * pull
		reload_rot_off = cant_r.lerp(rack_r, reach)
		_pose_part("top_cover", Vector3.ZERO)
		_pose_optic_hood(Vector3.ZERO)
		_pose_part("charge", Vector3(0.0, 0.0, 0.072 * pull))
		_pose_part("arm_left", hand_lid_p.lerp(hand_charge_p, reach) + Vector3(0.0, 0.0, 0.068 * pull), hand_lid_r.lerp(hand_charge_r, reach), PIVOT_AR_HAND)
	else:
		var u := smoothstep(3.16, reload_dur, t)
		reload_pos_off = rack_p.lerp(Vector3.ZERO, u)
		reload_rot_off = rack_r.lerp(Vector3.ZERO, u)
		_pose_part("top_cover", Vector3.ZERO)
		_pose_optic_hood(Vector3.ZERO)
		_pose_part("charge", Vector3.ZERO)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("ammo_belt", Vector3.ZERO)
		_pose_part("arm_left", hand_charge_p.lerp(Vector3.ZERO, u), hand_charge_r.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)
	var pk_pop := _cod_punch(t, 0.24, 0.34)
	var pk_drop := _cod_punch(t, 1.02, 0.36)
	var pk_lock := _cod_punch(t, 1.94, 0.40)
	var pk_slam := _cod_punch(t, 2.59, 0.42)
	var pk_bolt := _cod_punch(t, 3.07, 0.32)
	reload_pos_off += Vector3(0.0, -0.008, 0.0) * pk_pop + Vector3(0.0, 0.014, 0.0) * pk_drop + Vector3(0.0, 0.024, -0.008) * pk_lock
	reload_pos_off += Vector3(0.0, -0.034, 0.006) * pk_slam + Vector3(0.012, -0.012, 0.010) * pk_bolt
	reload_rot_off += Vector3(-0.03, 0.0, 0.0) * pk_pop + Vector3(0.04, 0.0, 0.0) * pk_drop + Vector3(0.07, 0.0, 0.05) * pk_lock
	reload_rot_off += Vector3(-0.10, 0.0, 0.03) * pk_slam + Vector3(-0.04, 0.0, 0.08) * pk_bolt
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_magnum() -> void:
	# .44: thumb the latch, crane swings out -> sharp upward wrist-whip with a double ejector-rod tap dumping brass
	# -> SpeedLoader pressed home & twisted to release -> classic wrist-flick snaps the cylinder shut
	var t := reload_elapsed
	# Held forward & high with modest yaw so the shooting forearm drops below the lens instead of sweeping across it
	var cant_p := Vector3(-0.048, 0.128, -0.075)
	var cant_r := Vector3(0.34, 0.30, -0.44)
	var load_p := Vector3(-0.050, 0.045, 0.070)
	# Load muzzle-UP (muzzle-down would pivot the forearm up into the lens); loader comes in from below-rear
	var load_r := Vector3(0.20, 0.30, -0.46)
	var hand_clear_p := Vector3(-0.10, -0.32, 0.16)
	var hand_clear_r := Vector3(-0.30, 0.25, 0.22)
	# Fingers support the SpeedLoader from below-left so all 6 gleaming brass .44 rounds & chrome cylinder stay 100% unobstructed!
	var hand_load_p := Vector3(-0.034, 0.028, -0.070)
	var hand_load_r := Vector3(-0.18, 0.20, 0.18)

	if _reload_event(0.14, 1):
		_play_reload_sfx(_sfx_mag_out, 0.90)
		_reload_cam_kick(-0.006, 0.010, 0.0, 0.0)
	if _reload_event(0.44, 2):
		var cyl_w := weapon_pivot.to_global(Vector3(-0.045, 0.015, -0.130))
		if _w_parts.has("cylinder") and not (_w_parts["cylinder"] as Array).is_empty():
			var cn := _w_parts["cylinder"][0] as Node3D
			if is_instance_valid(cn) and cn.is_inside_tree():
				cyl_w = cn.global_position
		for _c in range(maxi(1, _magnum_spent_count)):
			_eject_brass_casing(WEAPONS[6], false, cyl_w)
		_reload_cam_kick(0.010, 0.0, 0.004, 0.0)
	if _reload_event(0.56, 16):
		_play_reload_sfx(_sfx_shell_in, 0.70)
		_reload_cam_kick(0.006, 0.0, 0.002, 0.0)
	if _reload_event(1.20, 4):
		_play_reload_sfx(_sfx_shell_in, 0.88)
		_reload_cam_kick(0.008, -0.004, 0.004, 0.0)
	if _reload_event(1.66, 8):
		_commit_mag_ammo()
		weapon_chambered[6] = true
		_play_reload_sfx(_sfx_mag_in, 0.92)
		_reload_cam_kick(0.004, 0.024, 0.008, 0.12)

	if t < 0.28:
		var u := _cod_ease_out(t / 0.24)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, 1.32 * _cod_ease_out((t - 0.10) / 0.12)))
		_pose_part("speed_loader", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		_pose_part("arm_left", hand_clear_p * u, hand_clear_r * u)
	elif t < 0.74:
		# Sharp whip UP (fast attack, held), two ejector taps punch the brass out, then a cushioned drop
		var whip := _cod_ease_out((t - 0.28) / 0.10) * (1.0 - smoothstep(0.62, 0.74, t))
		var tap := maxf(0.0, _cod_punch(t, 0.42, 0.12)) + maxf(0.0, _cod_punch(t, 0.54, 0.12))
		reload_pos_off = cant_p + Vector3(0.0, 0.028 * whip, 0.018 * whip)
		reload_rot_off = cant_r + Vector3(0.66 * whip, 0.0, -0.12 * whip)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, 1.32))
		_pose_part("speed_loader", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		_pose_part("arm_left", hand_clear_p + Vector3(-0.02 * whip, -0.02 * whip, 0.02 * whip + 0.016 * tap), hand_clear_r)
	elif t < 1.54:
		# Muzzle DOWN: SpeedLoader aligned, pressed home (1.20s), knob twisted to release, loader pulled away
		var u_tilt := _cod_ease_out((t - 0.74) / 0.18)
		var u_in := _cod_ease_out((t - 0.84) / 0.30)
		var twist := smoothstep(1.24, 1.32, t)
		var u_out := smoothstep(1.34, 1.52, t)
		reload_pos_off = cant_p.lerp(load_p, u_tilt)
		reload_rot_off = cant_r.lerp(load_r, u_tilt)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, 1.32))
		_pose_part("cylinder", Vector3.ZERO, Vector3(0.0, 0.0, _revolver_cyl_angle + twist * (TAU / 24.0)))
		var sl_z := lerpf(0.11, 0.0, u_in) + 0.14 * u_out
		_pose_part("speed_loader", Vector3(0.0, 0.0, sl_z), Vector3(0.0, 0.0, -0.55 * twist + u_out * 0.40), Vector3.ZERO, t < 1.48)
		var arm_in := hand_clear_p.lerp(hand_load_p + Vector3(0.0, 0.0, sl_z), _cod_ease_out((t - 0.74) / 0.20))
		_pose_part("arm_left", arm_in + Vector3(0.0, -0.04 * u_out, 0.0), hand_clear_r.lerp(hand_load_r, u_tilt) + Vector3(0.0, 0.0, -0.30 * twist))
	else:
		# Wrist-flick: the gun rolls hard right as the crane snaps shut at 1.62s, then settles back
		var u := _cod_ease_out((t - 1.62) / maxf(reload_dur - 1.62, 0.05))
		var snap := pow(smoothstep(1.56, 1.63, t), 1.6)
		var flick := sin(smoothstep(1.54, 1.80, t) * PI)
		reload_pos_off = load_p.lerp(Vector3.ZERO, u) + Vector3(-0.025 * flick, 0.0, 0.0)
		reload_rot_off = load_r.lerp(Vector3.ZERO, u) + Vector3(0.0, 0.0, 0.38 * flick)
		_pose_part("crane", Vector3.ZERO, Vector3(0.0, 0.0, 1.32 * (1.0 - snap)))
		_pose_part("speed_loader", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		var hb := smoothstep(1.50, 1.68, t)
		_pose_part("arm_left", (hand_load_p + Vector3(0.0, -0.04, 0.14)).lerp(Vector3.ZERO, hb), hand_load_r.lerp(Vector3.ZERO, hb))
	var pk_seat := _cod_punch(t, 1.19, 0.28)
	var pk_shut := _cod_punch(t, 1.62, 0.36)
	reload_pos_off += Vector3(0.0, 0.016, -0.006) * pk_seat + Vector3(-0.010, 0.006, 0.0) * pk_shut
	reload_rot_off += Vector3(0.05, 0.0, 0.0) * pk_seat + Vector3(0.02, 0.0, 0.12) * pk_shut
	if t >= 0.28 and t < 0.74:
		var tapk := _cod_punch(t, 0.43, 0.14) + _cod_punch(t, 0.55, 0.14)
		reload_pos_off += Vector3(0.0, 0.008, 0.0) * tapk
		reload_rot_off += Vector3(0.05, 0.0, 0.0) * tapk
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_hunting(delta: float) -> void:
	# Interruptible per-round Springfield M1903 — sharp bolt lift/pull, a tactile thumb-press bump per .30-06 round,
	# forceful bolt slam & lock. 3/4 yaw (-0.62 Y) & roll (+0.72 Z) keep the open breech in view
	reload_shell_timer += delta
	var cant_p := Vector3(-0.115, 0.114, -0.026)
	var cant_r := Vector3(0.24, -0.62, 0.72)
	var hand_bolt_p := Vector3(0.056, 0.068, -0.015)
	var hand_bolt_r := Vector3(0.16, -0.18, -0.28)
	var hand_feed_p := Vector3(0.068, 0.024, -0.052)
	var hand_feed_r := Vector3(0.08, -0.20, -0.20)
	var mag_cap := get_weapon_mag_size(7)

	if reload_shell_phase == 0:
		var st := reload_shell_timer
		var u := _cod_ease_out(st / 0.30)
		var lift := _cod_ease_out((st - 0.04) / 0.10)
		var pull := _cod_ease_out((st - 0.15) / 0.14)
		var pk_open := _cod_punch(st, 0.28, 0.20)
		reload_pos_off = cant_p * u + Vector3(0.0, 0.0, 0.010) * pk_open
		reload_rot_off = cant_r * u + Vector3(0.03, 0.0, -0.04) * pk_open
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085 * pull), Vector3(0.0, 0.0, 1.05 * lift))
		_pose_part("feed_round", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		_pose_part("arm_right", hand_bolt_p * lift + Vector3(0.0, 0.0, 0.085 * pull), hand_bolt_r * lift)
		if st >= 0.16 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_bolt, 0.78)
			_reload_cam_kick(-0.008, 0.008, 0.006, 0.0)
			if _sniper_pending_eject:
				_sniper_pending_eject = false
				_eject_brass_casing(WEAPONS[7], false)
		if st >= 0.36:
			reload_shell_phase = 1
			reload_shell_timer = 0.0
			reload_flags = 0
	elif reload_shell_phase == 1:
		var st := reload_shell_timer
		# Tactile thumb press: round driven down past the feed lips with a crisp downward bump
		var press := _cod_punch(st, 0.23, 0.13) if st < 0.36 else 0.0
		var bob := sin(clampf(st / 0.36, 0.0, 1.0) * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.012 * press + 0.006 * bob, 0.0)
		reload_rot_off = cant_r + Vector3(-0.04 * press, 0.0, 0.02 * bob)
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085), Vector3(0.0, 0.0, 1.05))
		var u_in := _cod_ease_out(st / 0.24)
		var fp := Vector3(lerpf(0.088, 0.0, u_in), lerpf(0.048, -0.014, u_in), lerpf(0.008, 0.0, u_in))
		_pose_part("feed_round", fp, Vector3(-0.14 * (1.0 - u_in), 0.18 * (1.0 - u_in), -0.32 * (1.0 - u_in)), Vector3.ZERO, st < 0.28)
		_pose_part("arm_right", hand_feed_p + fp + Vector3(0.0, -0.006 * maxf(0.0, press), 0.0), hand_feed_r)
		if st >= 0.25 and not (reload_flags & 2):
			reload_flags |= 2
			_play_reload_sfx(_sfx_shell_in, randf_range(1.06, 1.16))
			_reload_cam_kick(0.005, -0.003, 0.002, 0.0)
			if ammo_in_mag[7] < mag_cap and ammo_reserve[7] > 0:
				ammo_in_mag[7] += 1
				ammo_reserve[7] -= 1
				trauma = minf(1.0, trauma + 0.04)
		if st >= 0.36 or (reload_cancel_req and ammo_in_mag[7] > 0 and st >= 0.28):
			if reload_cancel_req or ammo_in_mag[7] >= mag_cap or ammo_reserve[7] <= 0:
				reload_shell_phase = 2
				reload_shell_timer = 0.0
				reload_flags = 0
				_pose_part("feed_round", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
			else:
				reload_shell_timer = 0.0
				reload_flags = 0
	elif reload_shell_phase == 2:
		var st := reload_shell_timer
		var exit_dur := 0.52
		# Bolt thrown forward (accelerating), slammed down into lock at 0.22s
		var close_u := pow(smoothstep(0.04, 0.18, st), 1.5)
		var lock_u := smoothstep(0.18, 0.26, st)
		var back := smoothstep(0.24, exit_dur, st)
		var pk_slam := _cod_punch(st, 0.21, 0.30)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, back) + Vector3(0.0, -0.010, -0.014) * pk_slam
		reload_rot_off = cant_r.lerp(Vector3.ZERO, back) + Vector3(-0.06, 0.0, -0.07) * pk_slam
		_pose_part("bolt", Vector3(0.0, 0.0, 0.085 * (1.0 - close_u)), Vector3(0.0, 0.0, 1.05 * (1.0 - lock_u)))
		_pose_part("feed_round", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		var ret := smoothstep(0.30, exit_dur, st)
		_pose_part("arm_right", (hand_bolt_p + Vector3(0.0, 0.0, 0.085 * (1.0 - close_u))).lerp(Vector3.ZERO, ret), hand_bolt_r.lerp(Vector3.ZERO, ret))
		if st >= 0.21 and not (reload_flags & 4):
			reload_flags |= 4
			weapon_chambered[7] = true
			_play_reload_sfx(_sfx_bolt, 0.88)
			_reload_cam_kick(-0.016, 0.012, 0.010, 0.10)
		if st >= exit_dur:
			weapon_chambered[7] = true
			is_reloading = false
			reload_cancel_req = false
			_reset_weapon_parts()


func _update_reload_rifle() -> void:
	var t := reload_elapsed
	var base_cant_p := Vector3(-0.056, 0.152, -0.088)
	var base_cant_r := Vector3(0.34, 0.48, -0.52)
	var hand_mag_p := Vector3(0.008, -0.172, 0.168)
	var hand_mag_r := Vector3(-0.64, 0.34, 0.52)
	var hand_drop_r := Vector3(-0.78, 0.42, 0.62)
	var hand_extract_end := hand_mag_p + EJECT_AR * 0.25
	var hand_pouch_p := hand_extract_end + Vector3(-0.035, -0.065, 0.030)
	var hand_catch_p := Vector3(-0.025, 0.015, 0.145)
	var hand_catch_r := Vector3(-0.24, 0.22, 0.28)
	var round_vis := (not reload_was_empty) if t < 0.80 else true
	_pose_part("dust_cover", Vector3.ZERO, Vector3.ZERO if (_m16_dust_open or reload_was_empty) else Vector3(0.0, 0.0, 1.48), PIVOT_AR_DUST)
	_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, round_vis)

	if _reload_event(0.24, 1):
		_play_reload_sfx(_sfx_mag_out, 1.0)
		_reload_cam_kick(-0.008, 0.006, 0.0, 0.0)
	if _reload_event(0.58, 32):
		_spawn_dropped_mag(1)
	if _reload_event(1.18, 2):
		_play_reload_sfx(_sfx_mag_in, 1.0)
		_reload_cam_kick(0.014, -0.008, 0.008, 0.0)
	if _reload_event(1.28, 4):
		_commit_mag_ammo()
		if not reload_was_empty:
			weapon_chambered[1] = true
		trauma = minf(1.0, trauma + 0.09)
	if reload_was_empty and _reload_event(1.66, 8):
		# Clean single M16 bolt-release paddle slap!
		weapon_chambered[1] = true
		_m16_dust_open = true
		_play_reload_sfx(_sfx_bolt, 1.04)
		_reload_cam_kick(-0.012, 0.012, 0.006, 0.11)

	# Keep bolt locked back cleanly until bolt-catch slap at 1.66s!
	if reload_was_empty:
		var bolt_u := 1.0 if t < 1.66 else (1.0 - smoothstep(1.66, 1.70, t))
		_pose_part("slide", Vector3(0.0, 0.0, 0.052 * bolt_u))
	else:
		_pose_part("slide", Vector3.ZERO)

	if t < 0.22:
		var u := _cod_ease_out(t / 0.22)
		reload_pos_off = base_cant_p * u
		reload_rot_off = base_cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("arm_left", hand_mag_p * u, hand_mag_r * u, PIVOT_AR_HAND)
	elif t < 0.66:
		# Mag-release pop (a few mm drop), then the hand strips it out with an energetic pull
		var u := 0.12 * smoothstep(0.24, 0.29, t) + 0.88 * _cod_ease_out((t - 0.29) / 0.29)
		var sw := sin(smoothstep(0.22, 0.62, t) * PI)
		reload_pos_off = base_cant_p + Vector3(0.0, -0.022 * sw, 0.012 * smoothstep(0.22, 0.34, t))
		reload_rot_off = base_cant_r + Vector3(0.06 * sw, 0.0, -0.08 * sw)
		var mp := EJECT_AR * (0.25 * u)
		_pose_part("mag", mp, Vector3(-0.22 * u, 0.0, 0.0), PIVOT_AR_MAG, t < 0.58)
		_pose_part("arm_left", hand_mag_p + mp, hand_mag_r.lerp(hand_drop_r, u), PIVOT_AR_HAND)
	elif t < 0.92:
		# Continuous hand dip to the pouch; the shoulder rolls with it so the frame is never dead still
		var u := smoothstep(0.66, 0.92, t)
		var dip := sin(u * PI)
		reload_pos_off = base_cant_p + Vector3(-0.010 * dip, -0.026 * dip, 0.012)
		reload_rot_off = base_cant_r + Vector3(-0.05 * dip, 0.035 * dip, 0.06 * dip)
		_pose_part("mag", EJECT_AR * 0.25, Vector3.ZERO, PIVOT_AR_MAG, false)
		var fetch_p := hand_extract_end.lerp(hand_pouch_p, smoothstep(0.0, 0.45, u)) if u < 0.5 else hand_pouch_p.lerp(hand_mag_p + EJECT_AR * 0.24, smoothstep(0.5, 1.0, u))
		_pose_part("arm_left", fetch_p, hand_drop_r, PIVOT_AR_HAND)
	elif t < 1.40:
		var mp := Vector3.ZERO
		var mrot := Vector3.ZERO
		if t < 1.12:
			# Stage 1: tilt the feed lips up into the well
			var u_align := _cod_ease_out((t - 0.92) / 0.18)
			mp = EJECT_AR * lerpf(0.24, 0.085, u_align)
			mrot = Vector3(lerpf(-0.22, -0.07, u_align), 0.0, 0.0)
			_pose_part("arm_left", hand_mag_p + mp, hand_drop_r.lerp(hand_mag_r, u_align), PIVOT_AR_HAND)
		else:
			# Stage 2: hard punch-up seat
			var u_seat := pow(smoothstep(1.12, 1.24, t), 1.4)
			var hs := maxf(0.0, sin(smoothstep(1.20, 1.36, t) * PI))
			mp = EJECT_AR * lerpf(0.085, 0.0, u_seat)
			mrot = Vector3(lerpf(-0.07, 0.0, u_seat), 0.0, 0.0)
			_pose_part("arm_left", hand_mag_p + mp + Vector3(0.0, 0.018 * hs, 0.0), hand_mag_r, PIVOT_AR_HAND)
		reload_pos_off = base_cant_p + Vector3(0.0, 0.0, 0.012 * (1.0 - smoothstep(0.92, 1.12, t)))
		reload_rot_off = base_cant_r
		_pose_part("mag", mp, mrot, PIVOT_AR_MAG, true)
	elif reload_was_empty and t < 1.88:
		# Clean single bolt-catch paddle slap
		var u := smoothstep(1.40, 1.88, t)
		var reach := _cod_ease_out((t - 1.40) / 0.20)
		var slap := sin(smoothstep(1.60, 1.72, t) * PI)
		reload_pos_off = base_cant_p.lerp(Vector3(-0.02, 0.03, -0.02), u)
		reload_rot_off = base_cant_r.lerp(Vector3(0.10, 0.16, -0.22), u)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("bolt_catch", Vector3.ZERO, Vector3(0.0, 0.0, 0.28 * slap), PIVOT_AR_CATCH)
		var h_eff_start := hand_mag_p + (PIVOT_AR_HAND - Basis.from_euler(hand_mag_r) * PIVOT_AR_HAND)
		_pose_part("arm_left", h_eff_start.lerp(hand_catch_p, reach) + Vector3(0.025 * slap, 0.0, 0.0), hand_mag_r.lerp(hand_catch_r, reach))
	else:
		var start_s := 1.88 if reload_was_empty else 1.40
		var u := _cod_ease_out((t - start_s) / maxf(reload_dur - start_s, 0.05))
		var prev_p := Vector3(-0.02, 0.03, -0.02) if reload_was_empty else base_cant_p
		var prev_r := Vector3(0.10, 0.16, -0.22) if reload_was_empty else base_cant_r
		reload_pos_off = prev_p.lerp(Vector3.ZERO, u)
		reload_rot_off = prev_r.lerp(Vector3.ZERO, u)
		_pose_part("bolt_catch", Vector3.ZERO)
		_pose_part("mag", Vector3.ZERO)
		if reload_was_empty:
			_pose_part("arm_left", hand_catch_p.lerp(Vector3.ZERO, u), hand_catch_r.lerp(Vector3.ZERO, u))
		else:
			_pose_part("arm_left", hand_mag_p.lerp(Vector3.ZERO, u), hand_mag_r.lerp(Vector3.ZERO, u), PIVOT_AR_HAND)
	var pk_seat := _cod_punch(t, 1.22, 0.38)
	reload_pos_off += Vector3(0.0, 0.030, -0.012) * pk_seat
	reload_rot_off += Vector3(0.10, 0.0, 0.07) * pk_seat
	if reload_was_empty:
		var pk_b := _cod_punch(t, 1.66, 0.32)
		reload_pos_off += Vector3(0.012, -0.012, 0.004) * pk_b
		reload_rot_off += Vector3(-0.03, 0.0, -0.08) * pk_b
	_reload_settle(t)
	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_pistol() -> void:
	var t := reload_elapsed
	var cant_p := Vector3(-0.032, 0.095, -0.068)
	var cant_r := Vector3(0.26, 0.36, 0.56)
	var hand_drop_p := Vector3(-0.115, -0.175, 0.065)
	var hand_drop_r := Vector3(-0.28, 0.22, 0.26)
	var hand_seat_p := Vector3(-0.018, -0.072, 0.036)
	var hand_seat_r := Vector3(-0.14, 0.10, 0.14)
	var hand_slide_p := Vector3(-0.026, 0.018, 0.022)
	var hand_slide_r := Vector3(-0.06, 0.05, 0.08)

	# Authoritative timestamp-crossing events (fixes 0.42-0.46s frame-skip bug!)
	if _reload_event(0.16, 1):
		_play_reload_sfx(_sfx_mag_out, 1.18)
	if _reload_event(0.42, 32):
		if reload_was_empty:
			_spawn_dropped_mag(0)
	if _reload_event(0.86, 2):
		_play_reload_sfx(_sfx_mag_in, 1.16)
	if _reload_event(0.95, 4):
		_commit_mag_ammo()
		if not reload_was_empty:
			weapon_chambered[0] = true
		trauma = minf(1.0, trauma + 0.08)
	if reload_was_empty and _reload_event(1.18, 8):
		weapon_chambered[0] = true
		_play_reload_sfx(_sfx_bolt, 1.24)
		trauma = minf(1.0, trauma + 0.09)

	var snap_t := 1.0 - smoothstep(1.18, 1.25, t) if reload_was_empty else 0.0
	var p_slide_z := (0.034 if t < 1.18 else 0.034 * snap_t) if reload_was_empty else 0.0
	_pose_part("slide", Vector3(0.0, 0.0, p_slide_z))
	_pose_optic_hood(Vector3(0.0, 0.0, p_slide_z))
	_pose_part("slidestop", Vector3.ZERO, Vector3(-0.22 * (1.0 if t < 1.16 else (1.0 - smoothstep(1.16, 1.22, t))) if reload_was_empty else 0.0, 0.0, 0.0), PIVOT_G17_SLIDESTOP)
	var bullet_vis := (not reload_was_empty) or t >= 0.76

	if t < 0.16:
		var u := smoothstep(0.0, 0.16, t)
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, not reload_was_empty)
		var start_hp := hand_drop_p if reload_was_empty else hand_seat_p
		var start_hr := hand_drop_r if reload_was_empty else hand_seat_r
		_pose_part("arm_left", start_hp * u, start_hr * u)
	elif t < 0.46:
		var u := smoothstep(0.16, 0.44, t)
		reload_pos_off = cant_p + Vector3(0.0, -0.015 * sin(u * PI), 0.0)
		reload_rot_off = cant_r + Vector3(0.06 * sin(u * PI), 0.0, 0.0)
		var mp := EJECT_G17 * (0.22 * u)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, t < 0.42 if reload_was_empty else u < 0.92)
		_pose_part("mag_bullet", mp, Vector3.ZERO, Vector3.ZERO, (not reload_was_empty) and u < 0.92)
		if reload_was_empty:
			_pose_part("arm_left", hand_drop_p + Vector3(-0.025 * u, -0.065 * u, 0.02 * u), hand_drop_r)
		else:
			_pose_part("arm_left", hand_seat_p + mp, hand_seat_r.lerp(hand_drop_r, u))
	elif t < 0.76:
		var u := smoothstep(0.46, 0.76, t)
		var dip := sin(u * PI)
		reload_pos_off = cant_p + Vector3(0.0, -0.028 * dip, 0.01)
		reload_rot_off = cant_r
		_pose_part("mag", EJECT_G17 * 0.22, Vector3.ZERO, Vector3.ZERO, false)
		_pose_part("mag_bullet", EJECT_G17 * 0.22, Vector3.ZERO, Vector3.ZERO, false)
		var fetch_start := (hand_drop_p + Vector3(-0.025, -0.065, 0.02)) if reload_was_empty else (hand_seat_p + EJECT_G17 * 0.22)
		var fetch_p := fetch_start.lerp(hand_seat_p + EJECT_G17 * 0.20, u)
		_pose_part("arm_left", fetch_p, hand_drop_r.lerp(hand_seat_r, u))
	elif t < 1.02:
		var u := smoothstep(0.76, 0.95, t)
		var slap := sin(smoothstep(0.90, 1.02, t) * PI)
		reload_pos_off = cant_p + Vector3(0.0, 0.022 * slap, 0.0)
		reload_rot_off = cant_r + Vector3(0.08 * slap, 0.0, 0.0)
		var mp := EJECT_G17 * lerpf(0.20, 0.0, u)
		_pose_part("mag", mp, Vector3.ZERO, Vector3.ZERO, true)
		_pose_part("mag_bullet", mp, Vector3.ZERO, Vector3.ZERO, bullet_vis)
		_pose_part("arm_left", hand_seat_p + mp + Vector3(0.0, 0.016 * slap, 0.0), hand_seat_r)
	elif reload_was_empty and t < 1.36:
		# Support hand stays engaged to thumb the slide stop cleanly at 1.18s while holding partial cant!
		var reach := smoothstep(1.02, 1.18, t)
		var dip := sin(smoothstep(1.16, 1.30, t) * PI)
		reload_pos_off = cant_p.lerp(cant_p * 0.45, reach) + Vector3(0.0, -0.012 * dip, 0.012 * dip)
		reload_rot_off = cant_r.lerp(cant_r * 0.45, reach) + Vector3(-0.06 * dip, 0.0, -0.08 * dip)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO)
		_pose_part("arm_left", hand_seat_p.lerp(hand_slide_p, reach), hand_seat_r.lerp(hand_slide_r, reach))
	else:
		# Smooth continuous settle from exact previous cant (ZERO snap back to full cant at 1.40s!)
		var start_s := 1.36 if reload_was_empty else 1.02
		var u := smoothstep(start_s, reload_dur, t)
		var prev_p := (cant_p * 0.45) if reload_was_empty else cant_p
		var prev_r := (cant_r * 0.45) if reload_was_empty else cant_r
		var prev_hp := hand_slide_p if reload_was_empty else hand_seat_p
		var prev_hr := hand_slide_r if reload_was_empty else hand_seat_r
		reload_pos_off = prev_p.lerp(Vector3.ZERO, u)
		reload_rot_off = prev_r.lerp(Vector3.ZERO, u)
		_pose_part("mag", Vector3.ZERO)
		_pose_part("mag_bullet", Vector3.ZERO)
		_pose_part("arm_left", prev_hp.lerp(Vector3.ZERO, u), prev_hr.lerp(Vector3.ZERO, u))

	if t >= reload_dur:
		is_reloading = false
		_reset_weapon_parts()


func _update_reload_shotgun(delta: float) -> void:
	reload_shell_timer += delta
	var cant_p := Vector3(-0.026, 0.092, -0.048)
	var cant_r := Vector3(0.28, 0.22, -1.18)
	var hand_caddy_p := Vector3(-0.015, -0.155, 0.165)
	var hand_caddy_r := Vector3(0.22, 0.08, 0.22)
	var hand_port_p := Vector3(0.032, -0.058, 0.160)
	var hand_port_r := Vector3(0.14, 0.06, 0.16)
	var hand_push_p := Vector3(0.036, -0.026, 0.118)
	var hand_push_r := Vector3(0.06, 0.04, 0.08)
	var mag_cap := get_weapon_mag_size(2)

	if reload_shell_phase == 0:
		if is_instance_valid(_shotgun_shell_rig):
			_shotgun_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		var u := smoothstep(0.0, 0.26, reload_shell_timer)
		if reload_cancel_req and ammo_in_mag[2] > 0:
			_shotgun_exit_arm_p = hand_caddy_p * u
			_shotgun_exit_arm_r = hand_caddy_r * u
			reload_shell_phase = 2
			reload_shell_timer = 0.0
			reload_flags = 0
			return
		reload_pos_off = cant_p * u
		reload_rot_off = cant_r * u
		_pose_part("arm_left", hand_caddy_p * u, hand_caddy_r * u)
		if reload_shell_timer >= 0.26:
			reload_shell_phase = 1
			reload_shell_timer = 0.0
			reload_flags = 0
	elif reload_shell_phase == 1:
		var st := reload_shell_timer
		var push := sin(smoothstep(0.14, 0.34, st) * PI)
		reload_pos_off = cant_p + Vector3(0.0, 0.018 * push, -0.012 * push)
		reload_rot_off = cant_r + Vector3(-0.06 * push, 0.0, 0.08 * push)
		var lift_u := sin(smoothstep(0.14, 0.34, st) * PI) if (st >= 0.14 and st < 0.34) else 0.0
		_pose_part("lifter", Vector3(0.0, 0.012 * lift_u, 0.0), Vector3(-0.16 * lift_u, 0.0, 0.0), PIVOT_M870_LIFTER)

		var cur_ap := hand_caddy_p
		var cur_ar := hand_caddy_r
		if st < 0.16:
			var a := smoothstep(0.0, 0.16, st)
			cur_ap = hand_caddy_p.lerp(hand_port_p, a)
			cur_ar = hand_caddy_r.lerp(hand_port_r, a)
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = true
				_shotgun_shell_rig.position = SHELL_M870_START.lerp(PORT_M870, a)
				_shotgun_shell_rig.rotation = Vector3(0.42, 0.22, 0.18).lerp(Vector3(0.26, 0.0, 0.0), a)
		elif st < 0.25:
			var b := smoothstep(0.16, 0.25, st)
			cur_ap = hand_port_p.lerp(hand_push_p, b * 0.55)
			cur_ar = hand_port_r.lerp(hand_push_r, b * 0.55)
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = true
				_shotgun_shell_rig.position = PORT_M870.lerp(SHELL_M870_ENTER, b)
				_shotgun_shell_rig.rotation = Vector3(lerpf(0.26, 0.10, b), 0.0, 0.0)
		elif st < 0.33:
			var c := smoothstep(0.25, 0.33, st)
			cur_ap = hand_port_p.lerp(hand_push_p, lerpf(0.55, 1.0, c))
			cur_ar = hand_port_r.lerp(hand_push_r, lerpf(0.55, 1.0, c))
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = c < 0.90
				_shotgun_shell_rig.position = SHELL_M870_ENTER.lerp(SHELL_M870_SEAT, c)
				_shotgun_shell_rig.rotation = Vector3(lerpf(0.10, 0.0, c), 0.0, 0.0)
		else:
			var d := smoothstep(0.33, 0.42, st)
			cur_ap = hand_push_p.lerp(hand_caddy_p, d)
			cur_ar = hand_push_r.lerp(hand_caddy_r, d)
			if is_instance_valid(_shotgun_shell_rig):
				_shotgun_shell_rig.visible = false
		_pose_part("arm_left", cur_ap, cur_ar)

		# Single unified commit event at seating (0.31s): audio + ammo + visual hide all agree!
		if st >= 0.31 and not (reload_flags & 1):
			reload_flags |= 1
			_play_reload_sfx(_sfx_shell_in, randf_range(0.96, 1.04))
			if ammo_in_mag[2] < mag_cap and ammo_reserve[2] > 0:
				ammo_in_mag[2] += 1
				ammo_reserve[2] -= 1
				trauma = minf(1.0, trauma + 0.05)

		if st >= 0.42 or (reload_cancel_req and ammo_in_mag[2] > 0 and (st >= 0.33 or (st < 0.15 and not reload_was_empty))):
			if reload_cancel_req or ammo_in_mag[2] >= mag_cap or ammo_reserve[2] <= 0:
				_shotgun_exit_arm_p = cur_ap
				_shotgun_exit_arm_r = cur_ar
				reload_shell_phase = 2
				reload_shell_timer = 0.0
				reload_flags = 0
				_pose_part("lifter", Vector3.ZERO)
				if is_instance_valid(_shotgun_shell_rig):
					_shotgun_shell_rig.visible = false
			else:
				reload_shell_timer = 0.0
				reload_flags = 0
	elif reload_shell_phase == 2:
		if is_instance_valid(_shotgun_shell_rig):
			_shotgun_shell_rig.visible = false
		_pose_part("lifter", Vector3.ZERO)
		var exit_dur := (0.24 if reload_cancel_req else 0.40) if reload_was_empty else (0.12 if reload_cancel_req else 0.26)
		var u := smoothstep(0.0, exit_dur, reload_shell_timer)
		var hand_ret := smoothstep(0.0, exit_dur * 0.50, reload_shell_timer)
		var arm_p := _shotgun_exit_arm_p.lerp(Vector3.ZERO, hand_ret)
		var arm_r := _shotgun_exit_arm_r.lerp(Vector3.ZERO, hand_ret)
		if reload_was_empty:
			var pull := sin(smoothstep(exit_dur * 0.20, exit_dur * 0.88, reload_shell_timer) * PI)
			var pz := pull * 0.072
			_pose_part("pump", Vector3(0, 0, pz))
			_pose_part("slide", Vector3(0, 0, pull * 0.060))
			_pose_part("charge", Vector3(0, 0, pull * 0.060))
			arm_p += Vector3(0, 0, pz)
			if reload_shell_timer >= exit_dur * 0.38 and not (reload_flags & 4):
				reload_flags |= 4
				weapon_chambered[2] = true
				_play_reload_sfx(_sfx_bolt, 0.84)
				trauma = minf(1.0, trauma + 0.12)
		_pose_part("arm_left", arm_p, arm_r)
		reload_pos_off = cant_p.lerp(Vector3.ZERO, u)
		reload_rot_off = cant_r.lerp(Vector3.ZERO, u)
		if reload_shell_timer >= exit_dur:
			weapon_chambered[2] = true
			is_reloading = false
			reload_cancel_req = false
			_reset_weapon_parts()
			if _shotgun_fire_on_cancel:
				_shotgun_fire_on_cancel = false
				_fire_buffer_timer = maxf(_fire_buffer_timer, 0.24)
				reload_pos_off = Vector3.ZERO
				reload_rot_off = Vector3.ZERO


func _align_bow_string_segment(seg: Node3D, p0: Vector3, p1: Vector3) -> void:
	if not is_instance_valid(seg):
		return
	var diff := p1 - p0
	var length := diff.length()
	if length < 0.001:
		return
	var y_axis := diff / length
	var ref := Vector3.RIGHT if absf(y_axis.x) < 0.9 else Vector3.FORWARD
	var z_axis := ref.cross(y_axis).normalized()
	var x_axis := y_axis.cross(z_axis).normalized()
	seg.position = (p0 + p1) * 0.5
	seg.basis = Basis(x_axis, y_axis, z_axis).scaled_local(Vector3(1.0, length, 1.0))


func _pose_bow_rig() -> void:
	if _bow_parts.is_empty():
		return
	var d_vis := 1.0 - pow(1.0 - _bow_draw, 1.45)
	var vib := 0.0
	if _bow_release_timer > 0.0:
		var rt := 0.14 - _bow_release_timer
		# Snap smoothly FROM the actual release draw percentage (never jumping to 0.65!)
		d_vis = maxf(d_vis, (1.0 - smoothstep(0.0, 0.042, rt)) * _bow_release_from_draw)
		vib = sin(rt * 98.0) * 0.0042 * _bow_release_from_draw * exp(-rt * 28.0)

	var limb_top: Node3D = _bow_parts.get("limb_top")
	var limb_bot: Node3D = _bow_parts.get("limb_bot")
	var cam_top: Node3D = _bow_parts.get("cam_top")
	var cam_bot: Node3D = _bow_parts.get("cam_bot")
	var str_top: Node3D = _bow_parts.get("str_top")
	var str_bot: Node3D = _bow_parts.get("str_bot")
	var buss_0: Node3D = _bow_parts.get("buss_0")
	var buss_1: Node3D = _bow_parts.get("buss_1")
	var arrow: Node3D = _bow_parts.get("arrow")
	var arm_draw: Node3D = _bow_parts.get("arm_draw")

	if is_instance_valid(limb_top):
		limb_top.rotation.x = 0.16 * d_vis
	if is_instance_valid(limb_bot):
		limb_bot.rotation.x = -0.16 * d_vis
	if is_instance_valid(cam_top):
		cam_top.rotation.x = 0.68 * d_vis
	if is_instance_valid(cam_bot):
		cam_bot.rotation.x = -0.68 * d_vis

	# Sequential glowing charge bars starting right at minimum release threshold (16% -> 96%)!
	var thresholds: Array[float] = [0.16, 0.42, 0.70, 0.96]
	for bi in range(_bow_charge_mats.size()):
		var lit: bool = _bow_draw >= thresholds[mini(bi, 3)]
		_bow_charge_mats[bi].emission_energy_multiplier = (5.8 if _bow_draw >= 0.96 else 3.8) if lit else 0.30

	# Aligned nock & arrow-rest plane (x = -0.022) so arrow shaft points straight down -Z!
	var arrow_rest := Vector3(-0.022, 0.036, -0.055)
	var nock_rest := Vector3(-0.020, 0.036, 0.090)
	var nock_full := Vector3(-0.020, 0.034, 0.228)
	var nock_pos := nock_rest.lerp(nock_full, d_vis) + Vector3(vib, 0.0, 0.0)

	# Anchor working bowstring on outer REAR pulley rims (not axle centers!) and drive dynamic buss cables!
	var top_rim_p := limb_top.transform * Vector3(0.0, 0.152, 0.104) if is_instance_valid(limb_top) else Vector3(0.0, 0.315, 0.090)
	var bot_rim_p := limb_bot.transform * Vector3(0.0, -0.152, 0.104) if is_instance_valid(limb_bot) else Vector3(0.0, -0.305, 0.090)
	_align_bow_string_segment(str_top, top_rim_p, nock_pos)
	_align_bow_string_segment(str_bot, bot_rim_p, nock_pos)

	var top_buss_p := limb_top.transform * Vector3(0.005, 0.135, 0.064) if is_instance_valid(limb_top) else Vector3(0.005, 0.295, 0.056)
	var bot_buss_p := limb_bot.transform * Vector3(0.005, -0.135, 0.052) if is_instance_valid(limb_bot) else Vector3(0.005, -0.285, 0.044)
	_align_bow_string_segment(buss_0, top_buss_p, bot_buss_p)
	var top_buss_l := limb_top.transform * Vector3(-0.005, 0.135, 0.052) if is_instance_valid(limb_top) else Vector3(-0.005, 0.295, 0.044)
	var bot_buss_l := limb_bot.transform * Vector3(-0.005, -0.135, 0.064) if is_instance_valid(limb_bot) else Vector3(-0.005, -0.285, 0.056)
	_align_bow_string_segment(buss_1, top_buss_l, bot_buss_l)

	if _bow_nock_timer > 0.0 and ammo_reserve[4] > 0:
		# Unmistakable 4-beat 0.78s AAA quiver-draw & string re-nock choreography:
		# 0.00..0.18: cant bow inward into frame & sweep draw hand to quiver
		# 0.18..0.52: draw fresh broadhead arrow visibly up & arc across onto whisker-biscuit rest
		# 0.52..0.78: slide shaft cleanly back & SNAP nock onto bowstring with audible click & settle bump!
		var nu := clampf(1.0 - _bow_nock_timer / BOW_NOCK_DUR, 0.0, 1.0)
		var cant_in := smoothstep(0.04, 0.24, nu)
		var cant_out := 1.0 - smoothstep(0.76, 1.0, nu)
		var cant_env := cant_in * cant_out
		var nock_bump := sin(smoothstep(0.68, 0.84, nu) * PI)
		var sway_n := sin(nu * TAU) * 0.008 * cant_env
		reload_pos_off = Vector3(-0.046 + sway_n, -0.024 + 0.012 * nock_bump, 0.036 + 0.014 * nock_bump) * cant_env
		reload_rot_off = Vector3(0.15 + 0.04 * nock_bump, 0.34, 0.44 - 0.05 * nock_bump) * cant_env

		var quiv_pick := Vector3(0.115, -0.155, 0.115)
		var arc_mid := Vector3(0.068, 0.018, 0.040)
		var rest_entry := Vector3(-0.014, 0.038, 0.018)
		var hand_nock_off := Vector3.ZERO
		if is_instance_valid(arrow):
			arrow.visible = nu >= 0.18
			if arrow.visible:
				var ap: Vector3
				if nu < 0.48:
					var u1 := smoothstep(0.18, 0.48, nu)
					var a1 := quiv_pick.lerp(arc_mid, u1)
					var a2 := arc_mid.lerp(rest_entry, u1)
					ap = a1.lerp(a2, u1)
				elif nu < 0.74:
					var u2 := smoothstep(0.48, 0.74, nu)
					ap = rest_entry.lerp(nock_rest + Vector3(0.0, 0.0, 0.012), u2)
				else:
					var u3 := smoothstep(0.74, 0.88, nu)
					ap = (nock_rest + Vector3(0.0, 0.0, 0.012)).lerp(nock_rest, u3)
				arrow.position = ap
				var aim_tgt := arrow_rest + Vector3(0.055 * (1.0 - smoothstep(0.18, 0.56, nu)), 0.04 * sin(smoothstep(0.18, 0.58, nu) * PI), -0.04 * (1.0 - smoothstep(0.18, 0.56, nu)))
				var dir_a := (aim_tgt - arrow.position).normalized()
				if dir_a.length_squared() > 0.01:
					var rl := dir_a.cross(Vector3.UP).normalized()
					var ul := rl.cross(dir_a).normalized()
					arrow.basis = Basis(rl, ul, -dir_a)
				hand_nock_off = arrow.position - nock_rest
		if is_instance_valid(arm_draw):
			var rp: Vector3 = _w_rest_pos.get(arm_draw.get_instance_id(), Vector3.ZERO)
			var rr: Vector3 = _w_rest_rot.get(arm_draw.get_instance_id(), Vector3.ZERO)
			var dp: Vector3
			var dr: Vector3
			if nu < 0.18:
				var u0 := smoothstep(0.0, 0.18, nu)
				dp = (quiv_pick - nock_rest) * u0
				dr = Vector3(0.24, -0.32, 0.22) * u0
			elif nu < 0.78:
				dp = hand_nock_off
				var reach_w := 1.0 - smoothstep(0.48, 0.78, nu)
				dr = Vector3(0.24 * reach_w, -0.32 * reach_w, 0.22 * reach_w)
			else:
				var u_set := smoothstep(0.78, 1.0, nu)
				dp = hand_nock_off.lerp(Vector3.ZERO, u_set)
				dr = Vector3.ZERO
			arm_draw.position = rp + dp
			arm_draw.rotation = rr + dr
	else:
		if is_instance_valid(arrow):
			var has_arrow := ammo_in_mag[4] > 0
			arrow.visible = has_arrow
			arrow.position = nock_pos
			var dir_l := (arrow_rest - nock_pos).normalized()
			if dir_l.length_squared() > 0.01:
				var right_l := dir_l.cross(Vector3.UP).normalized()
				var up_l := right_l.cross(dir_l).normalized()
				arrow.basis = Basis(right_l, up_l, -dir_l)
		if is_instance_valid(arm_draw):
			var rp: Vector3 = _w_rest_pos.get(arm_draw.get_instance_id(), Vector3.ZERO)
			var rr: Vector3 = _w_rest_rot.get(arm_draw.get_instance_id(), Vector3.ZERO)
			arm_draw.position = rp + (nock_pos - nock_rest)
			arm_draw.rotation = rr + Vector3(0.08 * d_vis, -0.16 * d_vis, 0.14 * d_vis)


func _update_bow_input(delta: float) -> void:
	if _bow_release_timer > 0.0:
		_bow_release_timer = maxf(0.0, _bow_release_timer - delta)
	if _bow_nock_timer > 0.0:
		_bow_nock_timer = maxf(0.0, _bow_nock_timer - delta)
		var nu := clampf(1.0 - _bow_nock_timer / BOW_NOCK_DUR, 0.0, 1.0)
		if nu >= 0.70 and not _bow_nock_sfx_played and ammo_reserve[4] > 0:
			_bow_nock_sfx_played = true
			if _sfx_bow_nock:
				_play_reload_sfx(_sfx_bow_nock, randf_range(0.96, 1.05))
			else:
				_play_reload_sfx(_sfx_shell_in, 1.45)
			trauma = minf(1.0, trauma + 0.025)
		if _bow_nock_timer <= 0.0 and ammo_in_mag[4] <= 0 and ammo_reserve[4] > 0:
			ammo_in_mag[4] = 1
			ammo_reserve[4] -= 1
			_bow_nock_sfx_played = false

	var holding := Input.is_action_pressed("fire")
	if _bow_require_repull:
		if not holding:
			_bow_require_repull = false
		return

	if Input.is_action_just_pressed("fire") and ammo_in_mag[4] <= 0 and ammo_reserve[4] <= 0 and _bow_nock_timer <= 0.0:
		# Audible dry-click cue when out of arrows
		_play_reload_sfx(_sfx_mag_out, 1.55)
		return

	if holding and not _bow_drawing and ammo_in_mag[4] > 0 and _bow_nock_timer <= 0.0 and fire_cd <= 0.0 and _melee_timer <= 0.0 and not is_sprinting:
		_bow_drawing = true
		_bow_draw = 0.0
		_bow_hold_time = 0.0
		if sfx_bow_draw and _sfx_bow_draw:
			sfx_bow_draw.stream = _sfx_bow_draw
			sfx_bow_draw.pitch_scale = randf_range(0.95, 1.05)
			sfx_bow_draw.play()
	elif _bow_drawing:
		if holding:
			_bow_draw = minf(1.0, _bow_draw + delta / 0.58)
			if _bow_draw >= 0.99:
				_bow_hold_time += delta
				sway_offset.x = clampf(sway_offset.x + sin(_bow_hold_time * 3.4) * delta * 0.018, -0.055, 0.055)
				sway_offset.y = clampf(sway_offset.y + cos(_bow_hold_time * 2.7) * delta * 0.014, -0.045, 0.045)
		else:
			var power := _bow_draw
			_bow_drawing = false
			_bow_draw = 0.0
			_bow_hold_time = 0.0
			if sfx_bow_draw and sfx_bow_draw.playing:
				sfx_bow_draw.stop()
			if power >= 0.16:
				_bow_release_from_draw = power
				_bow_release_timer = 0.14
				_fire_bow_arrow(power)
			else:
				# Deliberate soft let-down cue (no silent snap!)
				_bow_release_from_draw = power * 0.4
				_bow_release_timer = 0.06
				_play_reload_sfx(_sfx_shell_in, 0.82)


func _build_world_arrow_node() -> Node3D:
	var root := Node3D.new()
	var sh_m := CylinderMesh.new(); sh_m.top_radius = 0.004; sh_m.bottom_radius = 0.004; sh_m.height = 0.62
	var sh_mat := _make_vm_mat(Color(0.08, 0.09, 0.10), 0.36, 0.35, 0.45)
	sh_m.material = sh_mat
	var sh := MeshInstance3D.new(); sh.mesh = sh_m; sh.rotation.x = PI * 0.5; sh.position.z = 0.18
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sh)
	var bh_m := CylinderMesh.new(); bh_m.top_radius = 0.0006; bh_m.bottom_radius = 0.011; bh_m.height = 0.048; bh_m.radial_segments = 4
	bh_m.material = _make_vm_mat(Color(0.76, 0.78, 0.82), 0.22, 0.92, 0.75)
	var bh := MeshInstance3D.new(); bh.mesh = bh_m; bh.rotation.x = -PI * 0.5; bh.position.z = -0.14
	bh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bh)
	var fl_m := BoxMesh.new(); fl_m.size = Vector3(0.0025, 0.020, 0.078)
	fl_m.material = _make_vm_mat(Color(0.84, 0.12, 0.10), 0.50, 0.0, 0.25)
	for rz: float in [0.0, 2.09, -2.09]:
		var fl := MeshInstance3D.new(); fl.mesh = fl_m; fl.position = Vector3(0, 0.010, 0.44); fl.rotation.z = rz
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(fl)
	return root


func _fire_bow_arrow(power: float, weapon_idx: int = 4) -> void:
	var is_xbow := (weapon_idx == 15)
	if not is_xbow:
		ammo_in_mag[4] = maxi(0, ammo_in_mag[4] - 1)
		# Trigger full 0.78s visible quiver-draw & string re-nock sequence if reserve arrows remain!
		_bow_nock_timer = BOW_NOCK_DUR if ammo_reserve[4] > 0 else 0.0
		_bow_nock_sfx_played = false
		fire_cd = 0.22
		recoil_vel.y += 0.024 * power
		recoil_z += 0.022 * power
		trauma = minf(1.0, trauma + 0.07 * power)
		if _sfx_bow_release:
			_play_gun_sfx(_sfx_bow_release, lerpf(0.88, 1.06, power))

	if _arrows.size() >= 24:
		var old: Dictionary = _arrows.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()

	var arrow_node := _build_world_arrow_node()
	if is_xbow:
		arrow_node.scale = Vector3(1.15, 1.15, 0.78)
	_fx_parent().add_child(arrow_node)
	var cam_orig := camera.global_position
	var cam_fwd := -camera.global_transform.basis.z
	var speed := 76.0 if is_xbow else lerpf(24.0, 62.0, power)

	# Unified zeroed ballistic solution:
	# 1. Sweep from camera eye along cam_fwd to find true aim target (zeroed cleanly at 25m for full draw!).
	var space := get_world_3d().direct_space_state
	var aim_dist := 25.0
	if space:
		var aq := PhysicsRayQueryParameters3D.create(cam_orig, cam_orig + cam_fwd * 40.0, 1)
		aq.exclude = [get_rid()]
		var ahit := space.intersect_ray(aq)
		if ahit:
			aim_dist = clampf(cam_orig.distance_to(ahit["position"]), 1.2, 40.0)
	var z_aim := ZombieAI.raycast_all_zombies(cam_orig, cam_fwd, aim_dist)
	if not z_aim.is_empty():
		aim_dist = clampf(float(z_aim["dist"]), 1.0, aim_dist)
	var zero_dist := minf(aim_dist, 25.0)
	var flight_t := zero_dist / maxf(speed, 10.0)
	var drop_comp := 0.5 * 9.8 * flight_t * flight_t * clampf(power, 0.25, 1.0)
	var target_pt := cam_orig + cam_fwd * zero_dist + Vector3(0.0, drop_comp, 0.0)

	# 2. Launch from muzzle-side arrow rest (clamped behind any close cover so nearby walls intercept cleanly!)
	var rest_local := Vector3(0.0, 0.020, -0.44) if is_xbow else Vector3(-0.022, 0.036, -0.34)
	var rest_w := weapon_pivot.to_global(rest_local)
	var start_pos := rest_w
	if space:
		var cq := PhysicsRayQueryParameters3D.create(cam_orig, rest_w, 1)
		cq.exclude = [get_rid()]
		var chit := space.intersect_ray(cq)
		if chit:
			start_pos = (chit["position"] as Vector3) - (rest_w - cam_orig).normalized() * 0.08
	var launch_dir := (target_pt - start_pos).normalized()
	if launch_dir.length_squared() < 0.01:
		launch_dir = cam_fwd
	var vel := launch_dir * speed
	arrow_node.global_position = start_pos
	arrow_node.look_at(start_pos + launch_dir, Vector3.UP)
	var upg_mult := 1.45 if is_weapon_upgraded(weapon_idx) else 1.0
	var base_dmg := float(WEAPONS[15]["damage"]) if is_xbow else lerpf(28.0, 170.0, pow(power, 1.15))
	_arrows.append({
		"node": arrow_node,
		"vel": vel,
		"dmg": base_dmg * upg_mult,
		"weapon_idx": weapon_idx,
		"total_dist": 0.0,
		"stuck": false,
		"stuck_zombie": null,
		"stuck_bone": -1,
		"stuck_local_pos": Vector3.ZERO,
		"stuck_local_rot": Basis.IDENTITY,
		"age": 0.0,
	})


func _update_arrows(delta: float) -> void:
	if _arrows.is_empty():
		return
	var space := get_world_3d().direct_space_state
	var can_recover := not dead and input_enabled
	var i := _arrows.size() - 1
	while i >= 0:
		var a: Dictionary = _arrows[i]
		a["age"] = float(a["age"]) + delta
		var node: Node3D = a["node"]
		if not is_instance_valid(node) or float(a["age"]) > 35.0:
			if is_instance_valid(node):
				node.queue_free()
			_arrows.remove_at(i)
			i -= 1
			continue
		if bool(a["stuck"]):
			var sz: ZombieAI = a["stuck_zombie"]
			if sz != null:
				if is_instance_valid(sz):
					var sb := int(a.get("stuck_bone", -1))
					if sz.skeleton and sb >= 0:
						var b_glob := sz.skeleton.global_transform * sz.skeleton.get_bone_global_pose(sb)
						node.global_position = b_glob * (a["stuck_local_pos"] as Vector3)
						node.global_transform.basis = (b_glob.basis.orthonormalized()) * (a["stuck_local_rot"] as Basis)
					else:
						node.global_position = sz.global_transform * (a["stuck_local_pos"] as Vector3)
						node.global_transform.basis = sz.global_transform.basis * (a["stuck_local_rot"] as Basis)
				else:
					node.queue_free()
					_arrows.remove_at(i)
					i -= 1
					continue
			# Guarded, line-of-sight-checked walk-over arrow recovery into reserve!
			if can_recover and float(a["age"]) > 0.65:
				var p_eye := global_position + Vector3(0.0, 1.05, 0.0)
				if node.global_position.distance_to(p_eye) < 1.85:
					var blocked := false
					if space:
						var rq := PhysicsRayQueryParameters3D.create(p_eye, node.global_position + Vector3(0, 0.08, 0), 1)
						rq.exclude = [get_rid()]
						blocked = not space.intersect_ray(rq).is_empty()
					var a_widx := int(a.get("weapon_idx", 4))
					if not blocked and unlocked_weapons[a_widx] and ammo_reserve[a_widx] < int(WEAPONS[a_widx]["reserve_max"]):
						ammo_reserve[a_widx] = mini(int(WEAPONS[a_widx]["reserve_max"]), ammo_reserve[a_widx] + 1)
						if a_widx == 4 and current_weapon == 4 and ammo_in_mag[4] <= 0 and _bow_nock_timer <= 0.0:
							_bow_nock_timer = BOW_NOCK_DUR
							_bow_nock_sfx_played = false
						_play_reload_sfx(_sfx_shell_in, 1.35)
						node.queue_free()
						_arrows.remove_at(i)
			i -= 1
			continue

		var prev_pos := node.global_position
		var vel: Vector3 = a["vel"]
		vel.y -= 9.8 * delta
		var next_pos := prev_pos + vel * delta
		var step_v := next_pos - prev_pos
		var step_len := step_v.length()
		var dir := step_v / maxf(step_len, 1e-5)

		var max_d := step_len
		var wall_hit := {}
		if space:
			var wq := PhysicsRayQueryParameters3D.create(prev_pos, next_pos, 1)
			wq.exclude = [get_rid()]
			wall_hit = space.intersect_ray(wq)
			if not wall_hit.is_empty():
				max_d = prev_pos.distance_to(wall_hit["position"])

		var z_hit := ZombieAI.raycast_all_zombies(prev_pos, dir, max_d)
		if not z_hit.is_empty():
			var z := z_hit["zombie"] as ZombieAI
			if is_instance_valid(z) and not z.dead:
				var hpos: Vector3 = z_hit["pos"]
				var hz := str(z_hit["zone"])
				var true_dist := float(a["total_dist"]) + float(z_hit["dist"])
				var res := z.apply_shot([{"zone": hz, "pos": hpos, "dir": dir, "dmg": float(a["dmg"]), "dist": true_dist}], int(a.get("weapon_idx", 4)))
				var is_hs := bool(res.get("headshot", false))
				var killed := bool(res.get("killed", false))
				emit_signal("hit_confirmed", is_hs, killed)
				if sfx_hit_tick and _sfx_hit_confirm:
					sfx_hit_tick.stream = _sfx_hit_confirm
					sfx_hit_tick.pitch_scale = 1.18 if is_hs else 0.96
					sfx_hit_tick.play()
				if sfx_hit and _sfx_arrow_impact:
					sfx_hit.stream = _sfx_arrow_impact
					sfx_hit.pitch_scale = randf_range(0.92, 1.08)
					sfx_hit.play()
				node.global_position = hpos - dir * 0.04
				node.look_at(node.global_position + dir, Vector3.UP)
				a["stuck"] = true
				a["stuck_zombie"] = z
				var b_idx := z.get_bone_for_zone(hz) if z.has_method("get_bone_for_zone") else -1
				if z.skeleton and b_idx >= 0 and z.dismembered.has(hz):
					var p_idx := z.skeleton.get_bone_parent(b_idx)
					if p_idx >= 0:
						b_idx = p_idx
				if z.skeleton and b_idx >= 0:
					var b_glob := z.skeleton.global_transform * z.skeleton.get_bone_global_pose(b_idx)
					a["stuck_bone"] = b_idx
					a["stuck_local_pos"] = b_glob.affine_inverse() * node.global_position
					a["stuck_local_rot"] = b_glob.basis.orthonormalized().inverse() * node.global_transform.basis
				else:
					a["stuck_bone"] = -1
					a["stuck_local_pos"] = z.global_transform.affine_inverse() * node.global_position
					a["stuck_local_rot"] = z.global_transform.basis.inverse() * node.global_transform.basis
				i -= 1
				continue

		if not wall_hit.is_empty():
			node.global_position = (wall_hit["position"] as Vector3) - dir * 0.04
			node.look_at(node.global_position + dir, Vector3.UP)
			a["stuck"] = true
			if sfx_misc and _sfx_arrow_impact:
				sfx_misc.stream = _sfx_arrow_impact
				sfx_misc.pitch_scale = randf_range(0.86, 1.04)
				sfx_misc.play()
			i -= 1
			continue

		a["vel"] = vel
		a["total_dist"] = float(a["total_dist"]) + step_len
		node.global_position = next_pos
		if step_len > 0.001:
			node.look_at(next_pos + dir, Vector3.UP)
		i -= 1


func toggle_flashlight() -> void:
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	flashlight_spill.visible = false
	flashlight_cone.visible = _should_show_flashlight_cone()
	if flashlight_bounce and not flashlight_on:
		flashlight_bounce.visible = false
		flashlight_bounce.light_energy = 0.0
	if sfx_misc:
		if _sfx_flashlight_click == null:
			_sfx_flashlight_click = load("res://assets/audio/flashlight_click.wav")
		sfx_misc.stream = _sfx_flashlight_click
		sfx_misc.play()


func _eject_brass_casing(w: Dictionary, is_hull := false, override_world_pos := Vector3.ZERO) -> void:
	if _casings.size() >= 18:
		var old: Dictionary = _casings.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = _hull_mesh if is_hull else _casing_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	var spawn_p := override_world_pos if override_world_pos != Vector3.ZERO else weapon_pivot.to_global(w["ejection"])
	mi.global_position = spawn_p
	mi.global_rotation = weapon_pivot.global_rotation + Vector3(PI * 0.5, 0, 0)
	var right := weapon_pivot.global_transform.basis.x
	var up := weapon_pivot.global_transform.basis.y
	var back := weapon_pivot.global_transform.basis.z
	var ej_vel := (Vector3(randf_range(-0.6, 0.2), randf_range(-0.4, 0.2), randf_range(-0.4, 0.4)) if override_world_pos != Vector3.ZERO else (right * randf_range(2.0, 3.2) + up * randf_range(1.6, 2.5) + back * randf_range(0.35, 1.0)))
	var floor_y := global_position.y + 0.012
	var space := get_world_3d().direct_space_state
	if space:
		var land_xz := spawn_p + Vector3(ej_vel.x, 0.0, ej_vel.z) * 0.25
		var fq := PhysicsRayQueryParameters3D.create(Vector3(land_xz.x, spawn_p.y + 0.2, land_xz.z), Vector3(land_xz.x, spawn_p.y - 4.0, land_xz.z), 1)
		var fhit := space.intersect_ray(fq)
		if fhit:
			floor_y = float(fhit["position"].y) + (0.012 if is_hull else 0.008)
	_casings.append({
		"node": mi,
		"vel": ej_vel,
		"ang": Vector3(randf_range(14, 28), randf_range(12, 26), randf_range(-20, 20)),
		"age": 0.0,
		"bounced": false,
		"floor_y": floor_y,
		"is_hull": is_hull,
	})


func _melee_profile() -> Dictionary:
	return MELEE_CATALOG.get(equipped_melee_id, MELEE_CATALOG["knife"])


func trigger_melee(heavy: bool = false) -> bool:
	if _melee_timer > 0.08 or dead:
		return false
	_burst_remaining = 0
	_burst_timer = 0.0
	if _bow_drawing:
		cancel_bow_draw(true)
	if is_reloading:
		is_reloading = false
		reload_cancel_req = false
		_shotgun_fire_on_cancel = false
		reload_pos_off = Vector3.ZERO
		reload_rot_off = Vector3.ZERO
		_reset_weapon_parts()
	var m: Dictionary = _melee_profile()
	var weight := float(m.get("weight", 1.0))
	_melee_is_heavy = heavy and current_weapon == 3
	_melee_power = 1.0
	if current_weapon != 3 and equipped_melee_id != "":
		# Quick melee while holding a firearm: whip out the equipped melee weapon for one fast slash
		_quick_melee_active = true
		_melee_is_gun_bash = false
		_melee_combo_idx = 0
		_melee_move = "slash_rl"
		if sniper_scope_alpha > 0.35 and is_instance_valid(weapon_pivot):
			sniper_scope_alpha = 0.0
			_sniper_ads_raw = 0.0
			weapon_pivot.position = WEAPONS[3]["hip_pos"]
			weapon_pivot.rotation = WEAPONS[3]["hip_rot"]
		for ri in range(_weapon_rigs.size()):
			if is_instance_valid(_weapon_rigs[ri]):
				_weapon_rigs[ri].visible = (ri == 3)
	elif current_weapon != 3:
		# No melee weapon equipped: weapon-specific gun-butt bash
		_quick_melee_active = false
		_melee_is_gun_bash = true
		_melee_combo_idx = 0
		_melee_move = "bash_pistol" if (current_weapon == 0 or current_weapon == 6) else "bash_rifle"
	else:
		# Holding the melee weapon: three-hit directional combo, or the weapon's charged heavy move
		_quick_melee_active = false
		_melee_is_gun_bash = false
		if _melee_is_heavy:
			_melee_move = str(m.get("heavy", "overhead"))
			_melee_power = lerpf(1.25, float(m.get("heavy_mult", 1.6)), clampf(_melee_charge, 0.0, 1.0))
			_melee_combo_idx = 0
			_melee_combo_reset = 0.0
		else:
			_melee_combo_idx = (_melee_combo_idx + 1) % 3 if _melee_combo_reset > 0.0 else 0
			_melee_combo_reset = float(m["dur"]) + 0.55
			if _melee_combo_idx == 2:
				# Combo finisher: a thrust for the knife, an overhead chop for everything with a head
				_melee_move = "stab" if equipped_melee_id == "knife" else "overhead"
				_melee_power = 1.3
			else:
				_melee_move = "slash_rl" if _melee_combo_idx == 0 else "slash_lr"
	if _melee_is_gun_bash:
		_melee_dur = 0.38
	elif _melee_is_heavy:
		_melee_dur = float(m["dur"]) * 1.34
	else:
		_melee_dur = float(m["dur"]) if current_weapon == 3 else minf(0.38, float(m["dur"]))
	# Heavier weapons spend longer winding up; the edge is live for ~20% of the swing after that
	var wu := 0.24 if _melee_is_gun_bash else clampf(0.20 + 0.10 * weight, 0.22, 0.36)
	if _melee_is_heavy:
		wu = 0.18 # the wind-up already happened while charging
	_melee_win0 = wu * _melee_dur
	_melee_win1 = (wu + 0.20) * _melee_dur
	_melee_timer = _melee_dur
	_melee_hit_done = false
	_melee_prev_u = 0.0
	_melee_swing_hits.clear()
	_melee_hits_left = 1 if (_melee_is_gun_bash or _quick_melee_active) else (int(m.get("cleave", 1)) + (1 if _melee_is_heavy else 0))
	_melee_any_hit = false
	_melee_wall_done = false
	_melee_charging = false
	_melee_hitstop_timer = 0.0
	fire_cd = maxf(fire_cd, _melee_dur)
	var mv: Dictionary = MELEE_MOVES.get(_melee_move, MELEE_MOVES["slash_rl"])
	recoil_roll += (-0.085 if _melee_is_heavy else -0.055) * float(mv.get("sign", 1.0)) * (0.4 if str(mv["arc"]) != "yaw" else 1.0)
	trauma = minf(1.0, trauma + (0.14 if _melee_is_heavy else 0.07) * weight)
	_start_melee_lunge(m, mv)
	if sfx_misc and _sfx_melee_swing:
		sfx_misc.stream = _sfx_melee_swing
		var base_pitch := lerpf(1.22, 0.78, clampf((weight - 0.6) / 0.7, 0.0, 1.0))
		sfx_misc.pitch_scale = base_pitch * (0.86 if _melee_is_heavy else 1.0) * randf_range(0.95, 1.06)
		sfx_misc.volume_db = -3.5 if _melee_is_heavy else -5.5
		sfx_misc.play()
	return true


func _start_melee_lunge(m: Dictionary, mv: Dictionary) -> void:
	# Soft target magnetism: step into a zombie that is just out of reach so swings connect instead of whiffing
	_melee_lunge_timer = 0.0
	if camera == null:
		return
	var fwd := -camera.global_transform.basis.z
	var flat := Vector3(fwd.x, 0.0, fwd.z)
	if flat.length_squared() < 0.01:
		return
	flat = flat.normalized()
	var reach := float(m.get("reach", 2.2))
	var best_d := 99.0
	for z_raw in ZombieAI._all_zombies:
		var z := z_raw as ZombieAI
		if not is_instance_valid(z) or z.dead:
			continue
		var to := z.global_position - global_position
		if absf(to.y) > 1.3:
			continue
		to.y = 0.0
		var d := to.length()
		if d < 1.15 or d > reach + 1.35:
			continue
		if flat.dot(to / d) < 0.86:
			continue
		best_d = minf(best_d, d)
	var is_lunge := _melee_move == "lunge"
	if best_d < 90.0 or is_lunge:
		var step := clampf(best_d - 1.25, 0.0, 1.6) if best_d < 90.0 else 1.1
		if is_lunge:
			step = maxf(step, 1.1)
		_melee_lunge_timer = 0.16
		_melee_lunge_vel = flat * (step / 0.16) * 0.55


func trigger_shove() -> bool:
	# [V] with a melee weapon in hand: a two-handed shove that staggers everything in front and makes space
	if _shove_cd > 0.0 or _melee_timer > 0.08 or dead or camera == null:
		return false
	_shove_cd = 0.85
	_melee_charging = false
	_quick_melee_active = false
	_melee_is_gun_bash = false
	_melee_is_heavy = false
	_melee_move = "shove"
	_melee_power = 1.0
	_melee_dur = 0.34
	_melee_win0 = 0.07
	_melee_win1 = 0.15
	_melee_timer = _melee_dur
	_melee_hit_done = false
	_melee_prev_u = 0.0
	_melee_swing_hits.clear()
	_melee_hits_left = 4
	_melee_any_hit = false
	_melee_wall_done = true
	fire_cd = maxf(fire_cd, _melee_dur)
	trauma = minf(1.0, trauma + 0.06)
	if sfx_misc and (_sfx_shove or _sfx_melee_swing):
		sfx_misc.stream = _sfx_shove if _sfx_shove else _sfx_melee_swing
		sfx_misc.pitch_scale = randf_range(0.94, 1.06)
		sfx_misc.volume_db = -5.0
		sfx_misc.play()
	return true


func _update_melee_swing(delta: float) -> void:
	_melee_charge_pose = lerpf(_melee_charge_pose, _melee_charge if _melee_charging else 0.0, 1.0 - exp(-delta * 16.0))
	if _melee_hitstop_timer > 0.0:
		_melee_hitstop_timer = maxf(0.0, _melee_hitstop_timer - delta)
		return
	if _melee_timer <= 0.0:
		return
	_melee_timer = maxf(0.0, _melee_timer - delta)
	var elapsed := _melee_dur - _melee_timer
	if elapsed >= _melee_win0 and not _melee_hit_done:
		var span_t := maxf(_melee_win1 - _melee_win0, 0.01)
		var u1 := clampf((elapsed - _melee_win0) / span_t, 0.0, 1.0)
		_sweep_melee(_melee_prev_u, u1)
		_melee_prev_u = u1
		if u1 >= 1.0:
			_melee_hit_done = true
	if _melee_timer <= 0.0 and _quick_melee_active:
		_quick_melee_active = false
		for ri in range(_weapon_rigs.size()):
			if is_instance_valid(_weapon_rigs[ri]):
				_weapon_rigs[ri].visible = (ri == current_weapon)


func _perform_melee_hit() -> void:
	# Whole-arc resolve in one call (scripted tests and anything that needs an instant swing result)
	_sweep_melee(0.0, 1.0)
	_melee_prev_u = 1.0
	_melee_hit_done = true


func _melee_ray_dirs(u0: float, u1: float) -> Array[Vector3]:
	var cb := camera.global_transform.basis
	var fwd := -cb.z
	var right := cb.x
	var up := cb.y
	var mv: Dictionary = MELEE_MOVES.get(_melee_move, MELEE_MOVES["slash_rl"])
	var span := deg_to_rad(float(mv.get("span", 40.0)))
	var sgn := float(mv.get("sign", 1.0))
	var out: Array[Vector3] = []
	match str(mv.get("arc", "yaw")):
		"thrust":
			if u0 <= 0.001:
				for a: float in [0.0, -0.5, 0.5, -1.0, 1.0]:
					var ang := a * span * 0.5
					out.append((fwd * cos(ang) + right * sin(ang)).normalized())
				out.append((fwd * 0.97 - up * 0.24).normalized())
			else:
				out.append(fwd)
		"pitch":
			for k in range(3):
				var uu := lerpf(u0, u1, float(k + 1) / 3.0)
				# An overhead chop carries on down to the floor, so it finishes crawlers and anything knocked flat
				var ang_p := lerpf(span * 0.5, -span * 0.95, uu)
				var base := (fwd * cos(ang_p) + up * sin(ang_p)).normalized()
				out.append(base)
				out.append((base + right * 0.11).normalized())
				out.append((base - right * 0.11).normalized())
		_:
			for k in range(4):
				var uu := lerpf(u0, u1, float(k + 1) / 4.0)
				var ang_y := lerpf(span * 0.5, -span * 0.5, uu) * sgn
				var base_y := (fwd * cos(ang_y) + right * sin(ang_y)).normalized()
				out.append(base_y)
				out.append((base_y - up * 0.16).normalized())
	return out


func _melee_swing_dir() -> Vector3:
	var cb := camera.global_transform.basis
	var fwd := -cb.z
	var mv: Dictionary = MELEE_MOVES.get(_melee_move, MELEE_MOVES["slash_rl"])
	match str(mv.get("arc", "yaw")):
		"pitch":
			return (fwd * 0.72 - cb.y * 0.65).normalized()
		"thrust":
			return fwd
		_:
			return (fwd * 0.62 - cb.x * 0.76 * float(mv.get("sign", 1.0))).normalized()


func _sweep_melee(u0: float, u1: float) -> void:
	var space := get_world_3d().direct_space_state
	if space == null or camera == null:
		return
	var m: Dictionary = _melee_profile()
	var is_shove := _melee_move == "shove"
	var reach: float = 1.85 if _melee_is_gun_bash else (1.95 if is_shove else float(m["reach"]) * (1.12 if _melee_is_heavy else 1.0))
	var origin := camera.global_position
	var swing_dir := _melee_swing_dir()
	var fwd := -camera.global_transform.basis.z
	for dir: Vector3 in _melee_ray_dirs(u0, u1):
		if _melee_hits_left <= 0:
			break
		var wq := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, 1)
		wq.exclude = [get_rid()]
		var wh := space.intersect_ray(wq)
		var max_d := origin.distance_to(wh["position"]) if not wh.is_empty() else reach
		var zh := ZombieAI.raycast_all_zombies(origin, dir, max_d)
		if not zh.is_empty():
			var z := zh["zombie"] as ZombieAI
			if is_instance_valid(z) and not _melee_swing_hits.has(z):
				_melee_swing_hits[z] = true
				_melee_hits_left -= 1
				_apply_melee_to_zombie(z, zh, swing_dir, m, is_shove)
		elif not wh.is_empty() and not _melee_wall_done and not _melee_any_hit and dir.dot(fwd) > 0.965 and max_d < reach * 0.82:
			_melee_wall_done = true
			_melee_wall_impact(wh, dir, m)


func _apply_melee_to_zombie(z: ZombieAI, zh: Dictionary, swing_dir: Vector3, m: Dictionary, is_shove: bool) -> void:
	var m_class := "blunt" if (_melee_is_gun_bash or is_shove) else str(m.get("class", "blade"))
	var zone := str(zh["zone"])
	var dmg: float = 34.0 if _melee_is_gun_bash else (9.0 if is_shove else float(m["damage"]) * _melee_power)
	if perks.has("adrenal") and not is_shove:
		dmg *= 1.25
	var poise_add := 45.0 if _melee_is_gun_bash else (140.0 if is_shove else float(m.get("poise", 40.0)) * (1.45 if _melee_is_heavy else 1.0))
	var kb := 5.2 if _melee_is_gun_bash else (7.5 if is_shove else float(m.get("kb", 4.2)) * (1.35 if _melee_is_heavy else 1.0))
	var horiz := Vector3(swing_dir.x, 0.0, swing_dir.z)
	if is_shove or horiz.length_squared() < 0.01:
		var f := -camera.global_transform.basis.z
		horiz = Vector3(f.x, 0.0, f.z)
	horiz = horiz.normalized()
	# Knife backstab: a zombie facing away from the blade takes a multiplied hit
	var backstab := false
	if not _melee_is_gun_bash and not is_shove and m.has("backstab") and not z.dead:
		var z_fwd := Vector3(sin(z.rotation.y), 0.0, cos(z.rotation.y))
		var p_fwd := -camera.global_transform.basis.z
		if z_fwd.dot(Vector3(p_fwd.x, 0.0, p_fwd.z).normalized()) > 0.35:
			dmg *= float(m["backstab"])
			backstab = true
	var is_tool := not _melee_is_gun_bash and not is_shove
	var opts := {
		"class": m_class,
		"poise": poise_add,
		"kb": horiz * kb,
		"sever": float(m.get("sever", 0.0)) * (1.25 if _melee_is_heavy else 1.0) if is_tool else 0.0,
		"heavy": _melee_is_heavy,
		"knockdown": (_melee_is_heavy and bool(m.get("knockdown", false)) and _melee_power >= 1.4) or (is_shove and z.variant == ZombieAI.Variant.RUNNER),
		"armor_pierce": float(m.get("armor_pierce", 1.0)) if is_tool else 1.0,
		"armor_break": is_tool and bool(m.get("armor_break", false)),
		"bleed_dps": float(m.get("bleed_dps", 0.0)) if is_tool else 0.0,
		"bleed_dur": float(m.get("bleed_dur", 0.0)),
		"shove": is_shove,
	}
	var hit := {"zone": zone, "pos": zh["pos"], "dir": swing_dir, "dmg": dmg, "dist": float(zh["dist"])}
	var res: Dictionary = z.apply_melee(hit, opts)
	if bool(res.get("corpse_hit", false)):
		return
	var is_hs := bool(res.get("headshot", false))
	var killed := bool(res.get("killed", false))
	var blocked := bool(res.get("armor_block", false))
	_melee_any_hit = true
	if not is_shove:
		emit_signal("hit_confirmed", is_hs, killed)
	if killed:
		if backstab:
			emit_signal("score_event", "BACKSTAB", 50)
		elif bool(res.get("dismembered", false)) and zone != "HEAD":
			emit_signal("score_event", "DISMEMBER", 25)
	# Impact feel: hit-stop scaled by weapon heft, a camera shove along the swing, and class-specific impact audio
	var weight := float(m.get("weight", 1.0)) if is_tool else 0.7
	var stop := (0.030 + 0.026 * weight) * (1.55 if (_melee_is_heavy or killed) else 1.0) * (1.25 if is_hs else 1.0)
	if is_shove:
		stop = 0.022
	_melee_hitstop_timer = maxf(_melee_hitstop_timer, minf(stop, 0.115))
	trauma = minf(1.0, trauma + (0.10 + 0.10 * weight) * (1.4 if _melee_is_heavy else 1.0))
	var mv: Dictionary = MELEE_MOVES.get(_melee_move, MELEE_MOVES["slash_rl"])
	if str(mv.get("arc", "yaw")) == "pitch":
		hit_pitch_kick -= 0.035 * weight
	else:
		hit_roll_kick += 0.030 * weight * float(mv.get("sign", 1.0))
	recoil_fov = maxf(recoil_fov, 0.9 * weight)
	if sfx_hit:
		var st: AudioStream = null
		if blocked and _sfx_melee_wall:
			st = _sfx_melee_wall
		elif m_class == "blunt" or m_class == "bar":
			st = _sfx_melee_blunt if _sfx_melee_blunt else _sfx_melee_cleave
		else:
			st = _sfx_melee_cleave
		if st == null and not _sfx_hit_flesh.is_empty():
			st = _sfx_hit_flesh[0]
		if st:
			sfx_hit.stream = st
			sfx_hit.pitch_scale = (randf_range(0.76, 0.88) if _melee_is_heavy else randf_range(0.94, 1.10)) * (1.25 if blocked else 1.0)
			sfx_hit.play()
	if not is_shove and sfx_hit_tick and _sfx_hit_confirm:
		sfx_hit_tick.stream = _sfx_hit_confirm
		sfx_hit_tick.pitch_scale = 1.16 if is_hs else 0.94
		sfx_hit_tick.play()


func _melee_wall_impact(wh: Dictionary, dir: Vector3, m: Dictionary) -> void:
	# Swinging into a wall bites the surface, clanks, and bounces the swing short instead of passing through silently
	var col = wh.get("collider")
	if VFXManager.instance:
		VFXManager.instance.spawn_surface_impact(wh["position"], wh["normal"], dir, col, 0)
	var weight := 0.7 if _melee_is_gun_bash else float(m.get("weight", 1.0))
	trauma = minf(1.0, trauma + 0.12 * weight)
	hit_pitch_kick += 0.02 * weight
	_melee_hitstop_timer = maxf(_melee_hitstop_timer, 0.03)
	_melee_timer = minf(_melee_timer, _melee_dur * 0.42)
	_melee_hit_done = true
	if sfx_hit and (_sfx_melee_wall or _sfx_impact_hard):
		sfx_hit.stream = _sfx_melee_wall if _sfx_melee_wall else _sfx_impact_hard
		var surf := "plaster"
		if col is Object and (col as Object).has_meta(&"surface"):
			surf = str((col as Object).get_meta(&"surface"))
		sfx_hit.pitch_scale = (1.25 if surf == "metal" else (0.72 if surf == "wood" else 0.95)) * randf_range(0.94, 1.06)
		sfx_hit.play()


func get_melee_focus() -> bool:
	# True when a living zombie sits inside the equipped melee weapon's reach along the crosshair (HUD "in range" cue)
	if camera == null or dead:
		return false
	var m: Dictionary = _melee_profile()
	var zh := ZombieAI.raycast_all_zombies(camera.global_position, -camera.global_transform.basis.z, float(m.get("reach", 2.2)))
	return not zh.is_empty() and is_instance_valid(zh["zombie"]) and not (zh["zombie"] as ZombieAI).dead


func has_perk(id: String) -> bool:
	return perks.has(id)


func grant_perk(id: String) -> void:
	if perks.has(id):
		return
	perks[id] = true
	if id == "vitality":
		max_health = 150.0
		health = max_health


func get_perk_tags() -> Array[String]:
	var out: Array[String] = []
	if perks.has("vitality"): out.append("VITALITY")
	if perks.has("quickhands"): out.append("QUICK HANDS")
	if perks.has("adrenal"): out.append("ADRENAL")
	return out


func apply_external_impulse(imp: Vector3) -> void:
	_ext_vel = (_ext_vel + Vector3(imp.x, 0.0, imp.z)).limit_length(11.0)
	if imp.y > 0.5 and is_on_floor():
		velocity.y = minf(imp.y, 4.5)
		floor_snap_length = 0.0


func apply_slow(mult: float, dur: float) -> void:
	var m := clampf(mult, 0.2, 1.0)
	slow_mult = minf(slow_mult, m) if slow_timer > 0.0 else m
	slow_timer = maxf(slow_timer, dur)


func begin_grab(z: Node3D) -> bool:
	if dead or god_mode or grabbed_by != null or grab_immunity > 0.0:
		return false
	grabbed_by = z
	grab_struggle = 0.0
	_melee_charging = false
	if _bow_drawing:
		cancel_bow_draw(true)
	trauma = minf(1.0, trauma + 0.35)
	return true


func end_grab(broke_free: bool) -> void:
	if grabbed_by == null:
		return
	var z := grabbed_by
	grabbed_by = null
	grab_struggle = 0.0
	grab_immunity = 4.0
	if broke_free and is_instance_valid(z) and z.has_method("on_grab_broken"):
		z.on_grab_broken(-global_transform.basis.z)


func struggle_against_grab() -> void:
	if grabbed_by == null:
		return
	grab_struggle += 0.26
	trauma = minf(1.0, trauma + 0.10)
	hit_roll_kick += randf_range(-0.05, 0.05)
	if sfx_misc and (_sfx_shove or _sfx_melee_swing):
		sfx_misc.stream = _sfx_shove if _sfx_shove else _sfx_melee_swing
		sfx_misc.pitch_scale = randf_range(1.1, 1.3)
		sfx_misc.play()
	if grab_struggle >= 1.0:
		end_grab(true)


func _update_grab(delta: float) -> void:
	if grabbed_by == null:
		return
	if not is_instance_valid(grabbed_by) or bool(grabbed_by.get("dead")) or global_position.distance_to(grabbed_by.global_position) > 2.6:
		end_grab(false)
		return
	grab_struggle = maxf(0.0, grab_struggle - delta * 0.22)


static var _grenade_scene_cache: Dictionary = {}

func _instantiate_grenade_visual(g_type: String) -> Node3D:
	var glb_map := {
		"frag": "res://assets/models/weapon_grenade_frag.glb",
		"molotov": "res://assets/models/weapon_grenade_molotov.glb",
		"shock": "res://assets/models/weapon_grenade_shock.glb",
	}
	var glb_path := str(glb_map.get(g_type, glb_map["frag"]))
	var holder := Node3D.new()
	if ResourceLoader.exists(glb_path):
		if not _grenade_scene_cache.has(glb_path):
			_grenade_scene_cache[glb_path] = load(glb_path)
		var pk := _grenade_scene_cache[glb_path] as PackedScene
		if pk:
			var inst := pk.instantiate() as Node3D
			for mn in inst.find_children("*", "MeshInstance3D", true, false):
				var mi := mn as MeshInstance3D
				mi.layers = 1
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(inst)
	if g_type == "molotov" or g_type == "shock":
		var glow := OmniLight3D.new()
		glow.position = Vector3(0.0, 0.14 if g_type == "molotov" else 0.06, 0.0)
		glow.light_color = Color(1.0, 0.48, 0.10) if g_type == "molotov" else Color(0.22, 0.82, 1.0)
		glow.light_energy = 1.4
		glow.omni_range = 2.4
		glow.shadow_enabled = false
		glow.light_cull_mask = 0xFFFFD
		glow.light_volumetric_fog_energy = 0.0
		holder.add_child(glow)
	return holder


func throw_grenade() -> bool:
	if dead or _grenade_cd > 0.0 or _melee_timer > 0.0 or is_reloading:
		return false
	_burst_remaining = 0
	_burst_timer = 0.0
	if _bow_drawing:
		cancel_bow_draw(true)
	var g_type := equipped_grenade
	var cnt: int = int(grenade_counts.get(g_type, 0))
	if cnt <= 0:
		# Auto-switch to any remaining grenade type if current is empty
		for cand: String in GRENADE_ORDER:
			if int(grenade_counts.get(cand, 0)) > 0:
				equipped_grenade = cand
				g_type = cand
				cnt = int(grenade_counts[cand])
				break
	if cnt <= 0:
		emit_signal("status_message", "NO GRENADES LEFT")
		return false
	grenade_counts[g_type] = cnt - 1
	_grenade_cd = 0.65
	var node := _instantiate_grenade_visual(g_type)
	_fx_parent().add_child(node)
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var desired_spawn := camera.global_position + fwd * 0.45 + right * 0.14 - up * 0.08
	var space := get_world_3d().direct_space_state
	if space:
		var sq := PhysicsRayQueryParameters3D.create(camera.global_position, desired_spawn, 1)
		sq.exclude = [get_rid()]
		var shit := space.intersect_ray(sq)
		if not shit.is_empty():
			desired_spawn = (shit["position"] as Vector3) + (shit["normal"] as Vector3) * 0.08
	node.global_position = desired_spawn
	var vel := fwd * 13.8 + up * 3.4 + velocity * 0.35
	_grenades.append({
		"node": node,
		"type": g_type,
		"vel": vel,
		"fuse": 1.55 if g_type == "frag" else (0.90 if g_type == "shock" else 4.0),
		"age": 0.0,
	})
	recoil_vel.y += 0.06
	trauma = minf(1.0, trauma + 0.08)
	if sfx_misc and _sfx_melee_swing:
		sfx_misc.stream = _sfx_melee_swing
		sfx_misc.pitch_scale = 1.18
		sfx_misc.play()
	return true


func _project_to_floor(pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space:
		var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0.0, 0.25, 0.0), pos - Vector3(0.0, 8.0, 0.0), 1)
		q.exclude = [get_rid()]
		var h := space.intersect_ray(q)
		if not h.is_empty():
			return h["position"] as Vector3
	return pos


func _has_aoe_los(origin: Vector3, target_pos: Vector3, blast_normal: Vector3 = Vector3.UP) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var n := blast_normal.normalized() if blast_normal.length_squared() > 0.01 else Vector3.UP
	var start_p := origin + (Vector3(0.0, 0.35, 0.0) if n.y > 0.4 else n * 0.25)
	var q := PhysicsRayQueryParameters3D.create(start_p, target_pos + Vector3(0.0, 0.95, 0.0), 1)
	q.exclude = [get_rid()]
	return space.intersect_ray(q).is_empty()


func _update_grenades(delta: float) -> void:
	if _grenades.is_empty():
		return
	var space := get_world_3d().direct_space_state
	var i := _grenades.size() - 1
	while i >= 0:
		var g: Dictionary = _grenades[i]
		var node: Node3D = g["node"]
		if not is_instance_valid(node):
			_grenades.remove_at(i)
			i -= 1
			continue
		g["age"] = float(g["age"]) + delta
		var vel: Vector3 = g["vel"]
		vel.y -= 18.0 * delta
		var p0 := node.global_position
		var p1 := p0 + vel * delta
		var step_v := p1 - p0
		var step_d := step_v.length()
		var g_type := str(g["type"])
		var hit := {}
		if space and step_d > 0.001:
			var q := PhysicsRayQueryParameters3D.create(p0, p1, 1)
			q.exclude = [get_rid()]
			hit = space.intersect_ray(q)
		# Direct zombie shatter check for Molotovs!
		if g_type == "molotov" and step_d > 0.001:
			var max_zd := p0.distance_to(hit["position"]) if not hit.is_empty() else step_d
			var zh := ZombieAI.raycast_all_zombies(p0, step_v / step_d, max_zd)
			if not zh.is_empty():
				node.global_position = _project_to_floor(zh["pos"] as Vector3)
				_detonate_grenade(g)
				node.queue_free()
				_grenades.remove_at(i)
				i -= 1
				continue
		if not hit.is_empty():
			var hpos: Vector3 = hit["position"]
			var hnrm: Vector3 = hit["normal"]
			node.global_position = hpos + hnrm * 0.05
			if g_type == "molotov":
				if hnrm.y < 0.5:
					node.global_position = _project_to_floor(hpos + hnrm * 0.22)
				_detonate_grenade(g)
				node.queue_free()
				_grenades.remove_at(i)
				i -= 1
				continue
			vel = vel.bounce(hnrm) * 0.44
			if vel.length() < 0.8:
				vel = Vector3.ZERO
			elif sfx_casing and not _sfx_shell_clink.is_empty():
				sfx_casing.stream = _sfx_shell_clink[0]
				sfx_casing.pitch_scale = 0.62
				sfx_casing.play()
		else:
			node.global_position = p1
		node.rotation += Vector3(6.5, 4.2, -5.0) * delta
		g["vel"] = vel
		if float(g["age"]) >= float(g["fuse"]):
			if g_type == "molotov":
				node.global_position = _project_to_floor(node.global_position)
			_detonate_grenade(g)
			node.queue_free()
			_grenades.remove_at(i)
		i -= 1


func _detonate_grenade(g: Dictionary) -> void:
	var g_type := str(g["type"])
	var pos: Vector3 = (g["node"] as Node3D).global_position
	var dist_p := global_position.distance_to(pos)
	trauma = minf(1.0, trauma + clampf(1.0 - dist_p / 14.0, 0.15, 0.85))
	if sfx_gun and _weapon_audio.size() > 2 and _weapon_audio[2]:
		_play_gun_sfx(_weapon_audio[2], 0.56 if g_type == "frag" else (1.35 if g_type == "shock" else 0.78))
	if g_type == "frag":
		var radius := 6.5
		for z_raw in ZombieAI._all_zombies.duplicate():
			var z := z_raw as ZombieAI
			if not is_instance_valid(z) or z.dead:
				continue
			var d := z.global_position.distance_to(pos)
			if d <= radius and absf(z.global_position.y - pos.y) <= 2.8 and _has_aoe_los(pos, z.global_position):
				var falloff := clampf(1.0 - (d / radius) * 0.72, 0.28, 1.0)
				var dir := (z.global_position + Vector3(0, 1.0, 0) - pos).normalized()
				var res := z.apply_shot([{"zone": "CHEST", "pos": z.global_position + Vector3(0, 1.0, 0), "dir": dir, "dmg": 265.0 * falloff, "dist": d}], 2)
				if not bool(res.get("corpse_hit", false)):
					emit_signal("hit_confirmed", bool(res.get("headshot", false)), bool(res.get("killed", false)))
				if not z.dead:
					z.velocity += dir * (8.5 * falloff)
		# Realistic Frag self-damage if player stands right on their own grenade (respects god_mode)
		if dist_p <= 4.5 and absf(global_position.y - pos.y) <= 2.8 and _has_aoe_los(pos, global_position):
			var self_dmg := clampf(48.0 * (1.0 - dist_p / 4.5), 10.0, 48.0)
			take_damage(self_dmg, pos)
		_spawn_hazard_pool("frag_flash", pos, 0.35, 3.0)
	elif g_type == "molotov":
		_spawn_hazard_pool("fire", _project_to_floor(pos), 7.0, 3.6)
	elif g_type == "shock":
		_spawn_hazard_pool("shock", _project_to_floor(pos), 5.5, 4.8)


func _ensure_fire_fx_assets() -> void:
	if _fire_shader == null and ResourceLoader.exists("res://shaders/realistic_fire.gdshader"):
		_fire_shader = load("res://shaders/realistic_fire.gdshader") as Shader
	if _smoke_wisp_tex == null and ResourceLoader.exists("res://assets/textures/gunsmoke_wisp.png"):
		_smoke_wisp_tex = load("res://assets/textures/gunsmoke_wisp.png") as Texture2D
	if _fire_plume_tex == null and ResourceLoader.exists("res://assets/textures/fire_plume_sheet.png"):
		_fire_plume_tex = load("res://assets/textures/fire_plume_sheet.png") as Texture2D
	if _napalm_puff_tex == null and ResourceLoader.exists("res://assets/textures/napalm_puff_sheet.png"):
		_napalm_puff_tex = load("res://assets/textures/napalm_puff_sheet.png") as Texture2D
	if _ember_mat == null:
		# Soft radial incandescent spark: white-hot pinpoint core -> orange-gold glow -> transparent rim
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.16, 0.42, 1.0])
		grad.colors = PackedColorArray([Color(1.0, 0.96, 0.82, 1.0), Color(1.0, 0.70, 0.22, 0.95), Color(1.0, 0.34, 0.04, 0.42), Color(0.8, 0.12, 0.0, 0.0)])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		_ember_mat = StandardMaterial3D.new()
		_ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ember_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_ember_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_ember_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_ember_mat.billboard_keep_scale = true
		_ember_mat.disable_receive_shadows = true
		_ember_mat.albedo_texture = gt
		_ember_mat.albedo_color = Color(1.0, 0.62, 0.20, 1.0)
		_ember_mat.disable_fog = true
	if _ember_mesh == null:
		_ember_mesh = QuadMesh.new()
		_ember_mesh.size = Vector2(0.045, 0.045)
		_ember_mesh.material = _ember_mat
	if _char_shader == null:
		_char_shader = Shader.new()
		_char_shader.code = """shader_type spatial;
render_mode blend_mix, depth_draw_never, unshaded, shadows_disabled;
uniform float fade_alpha = 1.0;
uniform float seed = 0.0;
float h21(vec2 p){p=fract(p*vec2(127.1,311.7));p+=dot(p,p+34.5);return fract(p.x*p.y);}
float vn(vec2 p){vec2 i=floor(p),f=fract(p);vec2 u=f*f*(3.0-2.0*f);return mix(mix(h21(i),h21(i+vec2(1,0)),u.x),mix(h21(i+vec2(0,1)),h21(i+vec2(1,1)),u.x),u.y);}
void fragment(){
	vec2 p=(UV-0.5)*2.0;
	float r=length(p);
	float n=vn(p*3.5+seed)*0.6+vn(p*7.5-seed*1.7)*0.4;
	float mask=1.0-smoothstep(0.22,0.96,r+(n-0.5)*0.55);
	float ember=smoothstep(0.52,0.85,mask*n)*0.32;
	ALBEDO=mix(vec3(0.025,0.02,0.018),vec3(0.95,0.22,0.02),ember);
	ALPHA=mask*0.80*fade_alpha;
	if(ALPHA<0.02)discard;
}"""


static func _make_loop_stream(src: AudioStream) -> AudioStream:
	# Seamless forward-looping copy of a one-shot WAV (keeps the shared imported resource untouched)
	if src == null:
		return null
	var wav := src as AudioStreamWAV
	if wav == null:
		return src
	if wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_end > 0:
		return wav
	var dup := wav.duplicate() as AudioStreamWAV
	dup.loop_mode = AudioStreamWAV.LOOP_FORWARD
	dup.loop_begin = 0
	dup.loop_end = maxi(1, int(wav.get_length() * float(wav.mix_rate)) - 1)
	return dup


func _ensure_flamer_pilot() -> void:
	if is_instance_valid(_flamer_pilot_node):
		return
	_ensure_fire_fx_assets()
	if _fire_shader == null or weapon_pivot == null:
		return
	_flamer_pilot_mat = ShaderMaterial.new()
	_flamer_pilot_mat.shader = _fire_shader
	if _fire_plume_tex:
		_flamer_pilot_mat.set_shader_parameter("fire_tex", _fire_plume_tex)
		_flamer_pilot_mat.set_shader_parameter("has_fire_tex", 1.0)
	_flamer_pilot_mat.set_shader_parameter("atlas_fps", 24.0)
	_flamer_pilot_mat.set_shader_parameter("blue_core", 0.88)
	_flamer_pilot_mat.set_shader_parameter("flame_speed", 5.2)
	_flamer_pilot_mat.set_shader_parameter("phase_seed", randf_range(0.0, 40.0))
	_flamer_pilot_mat.set_shader_parameter("intensity", 1.35)
	_flamer_pilot_mat.set_shader_parameter("smoke_mix", 0.0)
	_flamer_pilot_mat.set_shader_parameter("fade_alpha", 1.0)
	_flamer_pilot_mat.set_shader_parameter("billboard_y", 0.0)
	_flamer_pilot_mat.set_shader_parameter("jet_mode", 0.0)
	# Crossed viewmodel quads (layer 2) so the pilot reads from every first-person angle without camera clipping
	var qm := QuadMesh.new()
	# Real M2 igniter flame is ~10-15 cm; at ~1 m from the eye anything smaller collapses to a few pixels
	qm.size = Vector2(0.060, 0.120)
	qm.center_offset = Vector3(0.0, 0.050, 0.0)
	_flamer_pilot_node = MeshInstance3D.new()
	_flamer_pilot_node.name = "FlamerPilot"
	_flamer_pilot_node.mesh = qm
	_flamer_pilot_node.material_override = _flamer_pilot_mat
	_flamer_pilot_node.layers = 2
	_flamer_pilot_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cross := MeshInstance3D.new()
	cross.mesh = qm
	cross.material_override = _flamer_pilot_mat
	cross.layers = 2
	cross.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cross.rotation.y = PI * 0.5
	_flamer_pilot_node.add_child(cross)
	_flamer_pilot_node.position = (WEAPONS[16]["muzzle"] as Vector3) + Vector3(0.0, 0.012, -0.025)
	_flamer_pilot_node.visible = false
	weapon_pivot.add_child(_flamer_pilot_node)


func _update_flamethrower_audio_and_pilot(delta: float) -> void:
	var firing := _flame_firing_timer > 0.0 and current_weapon == 16 and ammo_in_mag[16] > 0 and not dead
	var t_now := Time.get_ticks_msec() * 0.001
	if firing:
		_flame_firing_timer = maxf(0.0, _flame_firing_timer - delta)
		if sfx_flame_loop:
			if not sfx_flame_loop.playing:
				if _sfx_flame_jet_loop == null:
					_sfx_flame_jet_loop = _make_loop_stream(_sfx_flamethrower_jet)
				if _sfx_flame_jet_loop:
					sfx_flame_loop.stream = _sfx_flame_jet_loop
					sfx_flame_loop.volume_db = -16.0
					sfx_flame_loop.play(randf_range(0.0, 0.6))
			sfx_flame_loop.volume_db = move_toward(sfx_flame_loop.volume_db, -1.5, delta * 120.0)
			# Organic pressure flutter of the fuel valve & roaring burn
			var flutter := 1.01 + 0.035 * sin(t_now * 7.3) + 0.022 * sin(t_now * 13.7 + 1.3) + randf_range(-0.008, 0.008)
			sfx_flame_loop.pitch_scale = clampf(lerpf(sfx_flame_loop.pitch_scale, flutter, 1.0 - exp(-delta * 18.0)), 0.95, 1.07)
	else:
		if current_weapon != 16 or dead:
			_flame_firing_timer = 0.0
		if sfx_flame_loop and sfx_flame_loop.playing:
			sfx_flame_loop.volume_db = move_toward(sfx_flame_loop.volume_db, -34.0, delta * (32.5 / 0.18))
			if sfx_flame_loop.volume_db <= -33.9:
				sfx_flame_loop.stop()
	if is_instance_valid(_flamer_pilot_node):
		var show_p := current_weapon == 16 and not is_reloading and not _quick_melee_active and ammo_in_mag[16] > 0 and not dead
		_flamer_pilot_node.visible = show_p
		_flamer_flare = move_toward(_flamer_flare, 1.0 if (firing and show_p) else 0.0, delta * (14.0 if firing else 5.0))
		if show_p:
			var flick := 1.0 + 0.09 * sin(t_now * 23.0) + 0.06 * sin(t_now * 41.0 + 0.7) + randf_range(-0.03, 0.03)
			var sc := lerpf(1.0, 1.45, _flamer_flare) * flick
			_flamer_pilot_node.scale = Vector3(sc * lerpf(1.0, 0.85, _flamer_flare), sc, sc)
			if _flamer_pilot_mat:
				_flamer_pilot_mat.set_shader_parameter("intensity", lerpf(1.35, 2.0, _flamer_flare) * flick)
				_flamer_pilot_mat.set_shader_parameter("blue_core", lerpf(0.88, 0.50, _flamer_flare))


func _spawn_flame_ember(pos: Vector3, vel: Vector3, dur: float) -> void:
	_ensure_fire_fx_assets()
	if _ember_mesh == null:
		return
	var cap := 20 if OS.has_feature("web") else 56
	while _flame_embers.size() >= cap:
		var old: Dictionary = _flame_embers.pop_front()
		if is_instance_valid(old.get("node")):
			(old["node"] as Node).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = _ember_mesh
	mi.layers = 1
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx_parent().add_child(mi)
	mi.global_position = pos
	var sz := randf_range(0.55, 1.25)
	mi.scale = Vector3.ONE * sz
	_flame_embers.append({
		"node": mi,
		"vel": vel,
		"age": 0.0,
		"dur": maxf(dur, 0.1),
		"size": sz,
		"seed": randf_range(0.0, TAU),
	})


func _update_flame_embers(delta: float) -> void:
	if _flame_embers.is_empty():
		return
	var i := _flame_embers.size() - 1
	while i >= 0:
		var e: Dictionary = _flame_embers[i]
		var node := e.get("node") as MeshInstance3D
		e["age"] = float(e["age"]) + delta
		var dur := float(e["dur"])
		if not is_instance_valid(node) or float(e["age"]) >= dur:
			if is_instance_valid(node):
				node.queue_free()
			_flame_embers.remove_at(i)
			i -= 1
			continue
		var age := float(e["age"])
		var u := age / dur
		var sd := float(e["seed"])
		var vel: Vector3 = e["vel"]
		# Buoyant thermal lift + turbulent swirl, with air drag bleeding off the initial burst
		vel *= exp(-delta * 1.6)
		vel.y += 1.75 * delta
		vel.x += sin(age * 8.5 + sd) * 1.1 * delta
		vel.z += cos(age * 7.1 + sd * 1.7) * 1.1 * delta
		e["vel"] = vel
		node.global_position += vel * delta
		var flick := 0.78 + 0.22 * sin(age * 31.0 + sd * 3.0)
		node.scale = Vector3.ONE * (float(e["size"]) * (1.0 - u * u) * flick + 0.001)
		node.transparency = clampf(smoothstep(0.55, 1.0, u), 0.0, 0.98)
		i -= 1


func _spawn_hazard_pool(kind: String, pos: Vector3, dur: float, radius: float, from_flamer := false) -> void:
	_ensure_fire_fx_assets()
	var is_web := OS.has_feature("web")
	if from_flamer:
		# Keep the clinging napalm trail bounded: retire the oldest flamethrower pools gracefully (fade, never pop)
		var flamer_cap := 3 if is_web else 6
		var live: Array[Dictionary] = []
		for hh: Dictionary in _hazards:
			if bool(hh.get("from_flamer", false)) and float(hh["age"]) < float(hh["dur"]) * 0.72:
				live.append(hh)
		var excess := live.size() - (flamer_cap - 1)
		for li in range(maxi(0, excess)):
			var oh: Dictionary = live[li]
			oh["age"] = maxf(float(oh["age"]), float(oh["dur"]) * 0.72)
	var root_n := Node3D.new()
	root_n.position = pos + Vector3(0.0, 0.02, 0.0)
	var light: OmniLight3D = null
	# Skip dynamic hazard OmniLights on WebGL2 so overlapping flame pools never exceed 8-light per-object budget!
	if not is_web or kind == "frag_flash":
		light = OmniLight3D.new()
		light.position = Vector3(0.0, 0.72, 0.0)
		light.shadow_enabled = false
		light.light_cull_mask = 0xFFFFD
		light.light_volumetric_fog_energy = 0.0
		light.omni_range = radius * 2.2
		if kind == "shock":
			light.light_color = Color(0.25, 0.82, 1.0)
			light.light_energy = 5.5
		elif kind == "frag_flash":
			light.light_color = Color(1.0, 0.56, 0.16)
			light.light_energy = 12.0
		else:
			light.light_color = Color(1.0, 0.38, 0.06)
			light.light_energy = 5.0
		root_n.add_child(light)

	var fire_mats: Array[ShaderMaterial] = []
	var fire_nodes: Array[MeshInstance3D] = []
	var fire_base_hs: Array[float] = []
	var smoke_entries: Array[Dictionary] = []
	var char_mat: ShaderMaterial = null

	if kind == "fire":
		# Organic feathered-edge scorched soot & glowing ember char stain on the floor (ZERO circular cylinder primitives!)
		if _char_shader != null:
			var char_mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(radius * 1.65, radius * 1.65)
			char_mat = ShaderMaterial.new()
			char_mat.shader = _char_shader
			char_mat.set_shader_parameter("fade_alpha", 1.0)
			char_mat.set_shader_parameter("seed", randf_range(0.0, 50.0))
			pm.material = char_mat
			char_mi.mesh = pm
			char_mi.position.y = 0.012
			char_mi.layers = 1
			char_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root_n.add_child(char_mi)

		# Cohesive overlapping multi-tiered photoreal turbulent gasoline flame plumes
		if _fire_shader != null:
			var r_sc := clampf(radius / 3.0, 0.58, 1.32)
			var plume_cnt := (4 if is_web else 7) if from_flamer else (6 if is_web else 11)
			var core_cnt := 2 if from_flamer else 4
			for fi in range(plume_cnt):
				var sm := ShaderMaterial.new()
				sm.shader = _fire_shader
				var is_core := fi < core_cnt
				if _fire_plume_tex:
					# Real high-speed photographic gasoline flame plumes, mirrored alternately so neighbours never repeat
					sm.set_shader_parameter("fire_tex", _fire_plume_tex)
					sm.set_shader_parameter("has_fire_tex", 1.0)
					sm.set_shader_parameter("flip_x", -1.0 if (fi % 2) == 1 else 1.0)
					sm.set_shader_parameter("atlas_fps", randf_range(14.0, 22.0))
				sm.set_shader_parameter("flame_speed", randf_range(2.3, 3.6))
				sm.set_shader_parameter("phase_seed", randf_range(0.0, 40.0))
				sm.set_shader_parameter("intensity", randf_range(1.00, 1.18) if is_core else randf_range(0.82, 1.00))
				sm.set_shader_parameter("smoke_mix", randf_range(0.40, 0.58) if is_core else randf_range(0.58, 0.82))
				sm.set_shader_parameter("fade_alpha", 1.0)
				sm.set_shader_parameter("billboard_y", 1.0)
				sm.set_shader_parameter("jet_mode", 0.0)
				sm.set_shader_parameter("blue_core", 0.0)
				# Layered body: tall dense inner core + shorter licking outer rim tongues
				var pw := (randf_range(0.95, 1.32) if is_core else randf_range(0.62, 0.98)) * r_sc
				var ph := (randf_range(1.08, 1.52) if is_core else randf_range(0.60, 1.08)) * r_sc
				var qm := QuadMesh.new()
				qm.size = Vector2(pw, ph)
				qm.material = sm
				var fmi := MeshInstance3D.new()
				fmi.mesh = qm
				var ang := float(fi) * 2.39996 + randf_range(-0.30, 0.30)
				var dist := (randf_range(0.0, 0.18) if is_core else randf_range(0.20, 0.50)) * radius
				fmi.position = Vector3(cos(ang) * dist, ph * 0.44, sin(ang) * dist)
				fmi.layers = 1
				fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root_n.add_child(fmi)
				fire_mats.append(sm)
				fire_nodes.append(fmi)
				fire_base_hs.append(ph)

		# Rising dark oily soot smoke wisps curling above the gasoline fire
		if _smoke_wisp_tex != null:
			var smoke_cnt := (1 if is_web else 2) if from_flamer else (2 if is_web else 4)
			for si in range(smoke_cnt):
				var smat := StandardMaterial3D.new()
				smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				smat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
				smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
				smat.albedo_texture = _smoke_wisp_tex
				smat.albedo_color = Color(0.05, 0.045, 0.042, 0.40)
				var sqm := QuadMesh.new()
				var sz := randf_range(0.95, 1.55) * clampf(radius / 3.0, 0.65, 1.25)
				sqm.size = Vector2(sz, sz)
				sqm.material = smat
				var smi := MeshInstance3D.new()
				smi.mesh = sqm
				var base_xz := Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35)) * radius
				smi.position = Vector3(base_xz.x, 0.90 + float(si) * 0.36, base_xz.y)
				smi.layers = 1
				smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root_n.add_child(smi)
				smoke_entries.append({
					"node": smi,
					"mat": smat,
					"base_x": base_xz.x,
					"base_z": base_xz.y,
					"phase": float(si) / float(smoke_cnt),
					"speed": randf_range(0.45, 0.72),
				})
	elif kind == "frag_flash":
		# Turbulent expanding blast fireball + dark concussion soot puff for Frag & RPG-7 detonations!
		if _fire_shader != null:
			var blast_cnt := 2 if OS.has_feature("web") else 4
			for bi in range(blast_cnt):
				var sm := ShaderMaterial.new()
				sm.shader = _fire_shader
				if _napalm_puff_tex:
					sm.set_shader_parameter("fire_tex", _napalm_puff_tex)
					sm.set_shader_parameter("has_fire_tex", 1.0)
					sm.set_shader_parameter("atlas_fps", randf_range(16.0, 24.0))
					sm.set_shader_parameter("flip_x", -1.0 if (bi % 2) == 1 else 1.0)
				sm.set_shader_parameter("age_norm", 0.0)
				sm.set_shader_parameter("flame_speed", 4.5)
				sm.set_shader_parameter("phase_seed", randf_range(0.0, 30.0))
				sm.set_shader_parameter("intensity", 1.55)
				sm.set_shader_parameter("smoke_mix", 0.64)
				sm.set_shader_parameter("fade_alpha", 1.0)
				sm.set_shader_parameter("billboard_y", 1.0)
				sm.set_shader_parameter("jet_mode", 1.0)
				var qm := QuadMesh.new()
				qm.size = Vector2(1.0, 1.0)
				qm.material = sm
				var bmi := MeshInstance3D.new()
				bmi.mesh = qm
				bmi.position = Vector3(randf_range(-0.35, 0.35), 0.55 + float(bi) * 0.22, randf_range(-0.35, 0.35))
				bmi.scale = Vector3.ONE * (0.45 * clampf(radius / 3.0, 0.7, 1.5))
				bmi.layers = 1
				bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root_n.add_child(bmi)
				fire_mats.append(sm)
				fire_nodes.append(bmi)
	elif kind == "shock":
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = radius * 0.78; cm.bottom_radius = radius * 0.85; cm.height = 0.025; cm.radial_segments = 20
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.20, 0.78, 1.0, 0.28)
		cm.material = mat
		disc.mesh = cm
		disc.layers = 1
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root_n.add_child(disc)

	# Spatial gasoline crackle & roar on burning pools (bounded voice count so many pools never stack into mud)
	var crackle: AudioStreamPlayer3D = null
	if kind == "fire" and _sfx_fire_crackle != null:
		var voices := 0
		for hh: Dictionary in _hazards:
			if is_instance_valid(hh.get("crackle")):
				voices += 1
		if voices < (2 if is_web else 4):
			if _sfx_fire_crackle_loop == null:
				_sfx_fire_crackle_loop = _make_loop_stream(_sfx_fire_crackle)
			crackle = AudioStreamPlayer3D.new()
			crackle.stream = _sfx_fire_crackle_loop
			crackle.unit_size = 3.5
			crackle.max_distance = 14.0
			crackle.volume_db = -20.0
			crackle.pitch_scale = randf_range(0.92, 1.08)
			crackle.position = Vector3(0.0, 0.45, 0.0)
			root_n.add_child(crackle)

	_fx_parent().add_child(root_n)
	if crackle:
		crackle.play(randf_range(0.0, 2.4))
	_hazards.append({
		"node": root_n,
		"light": light,
		"kind": kind,
		"pos": pos,
		"radius": radius,
		"age": 0.0,
		"dur": dur,
		"tick": 0.0,
		"ember_t": randf_range(0.0, 0.1),
		"fire_mats": fire_mats,
		"fire_nodes": fire_nodes,
		"fire_base_hs": fire_base_hs,
		"smoke": smoke_entries,
		"char_mat": char_mat,
		"crackle": crackle,
		"from_flamer": from_flamer,
	})


func _update_hazards(delta: float) -> void:
	if _hazards.is_empty():
		return
	var i := _hazards.size() - 1
	while i >= 0:
		var h: Dictionary = _hazards[i]
		var node: Node3D = h["node"]
		h["age"] = float(h["age"]) + delta
		var dur: float = float(h["dur"])
		if not is_instance_valid(node) or float(h["age"]) >= dur:
			if is_instance_valid(node):
				node.queue_free()
			_hazards.remove_at(i)
			i -= 1
			continue
		var age_f: float = float(h["age"])
		var fade := clampf(1.0 - maxf(0.0, (age_f - dur * 0.7) / maxf(dur * 0.3, 0.05)), 0.0, 1.0)
		var light: OmniLight3D = h["light"]
		var kind := str(h["kind"])
		if is_instance_valid(light):
			var flicker := 0.82 + 0.30 * sin(age_f * (38.0 if kind == "shock" else 21.0)) + 0.14 * sin(age_f * 37.0)
			light.light_energy = (12.0 if kind == "frag_flash" else 4.8) * fade * flicker
		var fmats: Array = h.get("fire_mats", [])
		var fnodes: Array = h.get("fire_nodes", [])
		var fbhs: Array = h.get("fire_base_hs", [])
		if kind == "fire":
			var rise_in := clampf(age_f / 0.18, 0.15, 1.0)
			var h_sc := rise_in * lerpf(0.32, 1.0, fade)
			for fi in range(fmats.size()):
				var sm := fmats[fi] as ShaderMaterial
				if sm:
					sm.set_shader_parameter("fade_alpha", fade)
					sm.set_shader_parameter("intensity", lerpf(0.60, 1.04, fade))
			for fi in range(fnodes.size()):
				var fn := fnodes[fi] as MeshInstance3D
				if is_instance_valid(fn):
					fn.scale = Vector3(lerpf(0.68, 1.0, fade), h_sc, 1.0)
					if fi < fbhs.size():
						fn.position.y = float(fbhs[fi]) * 0.44 * h_sc
			var cmat := h.get("char_mat") as ShaderMaterial
			if cmat:
				cmat.set_shader_parameter("fade_alpha", fade)
			var crk := h.get("crackle") as AudioStreamPlayer3D
			if is_instance_valid(crk):
				crk.volume_db = lerpf(-30.0, -4.0, clampf(fade * rise_in, 0.0, 1.0))
			# Glowing embers lofted off the burning fuel on the thermal column
			h["ember_t"] = float(h.get("ember_t", 0.0)) - delta
			if float(h["ember_t"]) <= 0.0 and fade > 0.2:
				var web_e := OS.has_feature("web")
				h["ember_t"] = randf_range(0.20, 0.34) if web_e else randf_range(0.07, 0.15)
				var er := float(h["radius"]) * 0.42
				var ep: Vector3 = (h["pos"] as Vector3) + Vector3(randf_range(-er, er), randf_range(0.20, 0.75), randf_range(-er, er))
				var ev := Vector3(randf_range(-0.45, 0.45), randf_range(0.9, 2.1), randf_range(-0.45, 0.45))
				_spawn_flame_ember(ep, ev, randf_range(0.9, 1.7))
			var sm_arr: Array = h.get("smoke", [])
			for se: Dictionary in sm_arr:
				var snode := se.get("node") as MeshInstance3D
				var smat := se.get("mat") as StandardMaterial3D
				if is_instance_valid(snode) and smat:
					var cyc := fmod(float(se["phase"]) + age_f * float(se["speed"]), 1.0)
					snode.position = Vector3(
						float(se["base_x"]) + sin(age_f * 1.4 + float(se["phase"]) * TAU) * 0.24 * cyc,
						0.78 + cyc * 1.85,
						float(se["base_z"]) + cos(age_f * 1.1 + float(se["phase"]) * TAU) * 0.22 * cyc
					)
					var sc_s := lerpf(0.65, 1.75, cyc)
					snode.scale = Vector3(sc_s, sc_s, 1.0)
					smat.albedo_color.a = sin(cyc * PI) * 0.38 * fade
		elif kind == "frag_flash":
			var u := clampf(age_f / maxf(dur, 0.05), 0.0, 1.0)
			var blast_r := clampf(float(h["radius"]) / 3.0, 0.75, 1.55)
			for fi in range(fmats.size()):
				var sm := fmats[fi] as ShaderMaterial
				if sm:
					sm.set_shader_parameter("fade_alpha", clampf(1.0 - pow(u, 1.4), 0.0, 1.0))
					sm.set_shader_parameter("intensity", lerpf(1.75, 0.35, u))
					sm.set_shader_parameter("smoke_mix", lerpf(0.28, 0.94, u))
					sm.set_shader_parameter("age_norm", u)
			for fi in range(fnodes.size()):
				var fn := fnodes[fi] as MeshInstance3D
				if is_instance_valid(fn):
					var ex := lerpf(0.45, 2.35, sqrt(u)) * blast_r
					fn.scale = Vector3(ex, ex, 1.0)
					fn.position.y += delta * 1.6
		if kind == "fire" or kind == "shock":
			h["tick"] = float(h["tick"]) + delta
			if float(h["tick"]) >= 0.30:
				h["tick"] = 0.0
				var pos: Vector3 = h["pos"]
				var rad: float = float(h["radius"])
				for z_raw in ZombieAI._all_zombies.duplicate():
					var z := z_raw as ZombieAI
					if not is_instance_valid(z) or z.dead:
						continue
					if z.global_position.distance_to(pos) <= rad and absf(z.global_position.y - pos.y) <= 2.4 and _has_aoe_los(pos, z.global_position):
						if kind == "fire":
							z.apply_burn(3.5, 32.0)
						else:
							z.apply_shock(2.2)
				if kind == "fire" and not dead and global_position.distance_to(pos) <= rad * 0.82 and absf(global_position.y - pos.y) <= 1.8:
					take_damage(10.0, pos)
		i -= 1


const FLAME_JET_SPEED_MIN := 13.5
const FLAME_JET_SPEED_MAX := 17.5


func _spawn_flame_jet_stream(w: Dictionary) -> void:
	_ensure_fire_fx_assets()
	if _fire_shader == null:
		return
	var was_flowing := _flame_emit_window > 0.0
	_flame_emit_w = w
	_flame_emit_window = float(w["fire_rate"]) * 1.4
	if was_flowing:
		# Trigger held: the per-tick nozzle emitter in _update_flame_jets keeps the lance fed. Re-bursting
		# every shot would leave the nozzle bare for most of each 75 ms shot interval (puffs outrun it at 15 m/s).
		return
	# Trigger pull: lay the whole lance out at once so fuel reaches 1.3 m on the very first frame
	var staggers: Array[float] = [0.12, 0.36, 0.64, 0.96, 1.32]
	if OS.has_feature("web"):
		staggers = [0.12, 0.45, 0.85]
	var fr := _flame_stream_frame(w, 0.022)
	for ji in range(staggers.size()):
		_emit_flame_puff(fr, staggers[ji], ji)
	_flame_emit_accum = 0.0


func _tick_flame_emitter(delta: float) -> void:
	# Continuous nozzle emitter: one puff every ~0.18 m of travel (0.40 m on web) seeded at the 0.12 m stagger,
	# so the stream stays attached to the nozzle tip on every rendered frame, not just on shot frames.
	if _flame_emit_window <= 0.0:
		return
	_flame_emit_window -= delta
	if current_weapon != 16 or dead or is_reloading or ammo_in_mag[16] <= 0 or _flame_emit_w.is_empty() or _fire_shader == null:
		_flame_emit_window = 0.0
		_flame_emit_accum = 0.0
		return
	var mean_speed := (FLAME_JET_SPEED_MIN + FLAME_JET_SPEED_MAX) * 0.5
	var interval := (0.40 if OS.has_feature("web") else 0.18) / mean_speed
	_flame_emit_accum += delta
	if _flame_emit_accum < interval:
		return
	var fr := _flame_stream_frame(_flame_emit_w, 0.012)
	var n := 0
	while _flame_emit_accum >= interval and n < 3:
		_flame_emit_accum -= interval
		# Puffs released earlier within this tick have already travelled further down the stream
		_emit_flame_puff(fr, 0.12 + minf(_flame_emit_accum * mean_speed, 0.30), randi() % 2)
		n += 1
	_flame_emit_accum = minf(_flame_emit_accum, interval)


func _flame_stream_frame(w: Dictionary, axis_jitter: float) -> Dictionary:
	var start_w := weapon_pivot.to_global(w["muzzle"] as Vector3)
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	# Guard against wall-clipping when standing right next to a wall
	var space := get_world_3d().direct_space_state
	if space:
		var cq := PhysicsRayQueryParameters3D.create(camera.global_position, start_w, 1)
		cq.exclude = [get_rid()]
		var ch := space.intersect_ray(cq)
		if not ch.is_empty():
			start_w = (ch["position"] as Vector3) + (ch["normal"] as Vector3) * 0.14
	# Puffs share a jittered axis so the rope of fuel stays tight
	var axis := (fwd + right * randf_range(-axis_jitter, axis_jitter) + up * randf_range(-axis_jitter * 0.73, axis_jitter * 0.73)).normalized()
	return {"start": start_w, "axis": axis, "right": right, "up": up, "space": space}


func _emit_flame_puff(fr: Dictionary, stagger: float, flip_idx: int) -> void:
	var max_jets := 30 if OS.has_feature("web") else 80
	if _flame_jets.size() >= max_jets:
		var old: Dictionary = _flame_jets.pop_front()
		if is_instance_valid(old.get("node")):
			(old["node"] as Node).queue_free()
	var start_w: Vector3 = fr["start"]
	var axis: Vector3 = fr["axis"]
	var right: Vector3 = fr["right"]
	var up: Vector3 = fr["up"]
	var space: PhysicsDirectSpaceState3D = fr["space"]
	var sm := ShaderMaterial.new()
	sm.shader = _fire_shader
	if _napalm_puff_tex:
		sm.set_shader_parameter("fire_tex", _napalm_puff_tex)
		sm.set_shader_parameter("has_fire_tex", 1.0)
		sm.set_shader_parameter("flip_x", -1.0 if (flip_idx % 2) == 1 else 1.0)
	sm.set_shader_parameter("atlas_fps", randf_range(18.0, 26.0))
	# Napalm fireballs are pure gold-orange: blue lives only on the pilot flame and gas burners
	# (blue mixed into the orange atlas reads as a magenta/purple tint)
	sm.set_shader_parameter("blue_core", 0.0)
	sm.set_shader_parameter("age_norm", 0.0)
	sm.set_shader_parameter("flame_speed", randf_range(3.6, 5.2))
	sm.set_shader_parameter("phase_seed", randf_range(0.0, 50.0))
	sm.set_shader_parameter("intensity", 1.50)
	sm.set_shader_parameter("smoke_mix", 0.18)
	sm.set_shader_parameter("fade_alpha", 1.0)
	sm.set_shader_parameter("billboard_y", 1.0)
	sm.set_shader_parameter("jet_mode", 1.0)
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.0)
	qm.material = sm
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.layers = 1
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var spread_dir := (axis + right * randf_range(-0.012, 0.012) + up * randf_range(-0.010, 0.010)).normalized()
	var spawn_pt := start_w + spread_dir * stagger
	var hit_wall := false
	if space and stagger > 0.01:
		var sq := PhysicsRayQueryParameters3D.create(start_w, spawn_pt, 1)
		sq.exclude = [get_rid()]
		var sh := space.intersect_ray(sq)
		if not sh.is_empty():
			spawn_pt = (sh["position"] as Vector3) + (sh["normal"] as Vector3) * 0.14
			hit_wall = true
	_fx_parent().add_child(mi)
	mi.global_position = spawn_pt
	var sc0 := 0.26
	mi.scale = Vector3(sc0, sc0, 1.0)
	var dur := randf_range(0.66, 0.86)
	_flame_jets.append({
		"node": mi,
		"mat": sm,
		"vel": Vector3(0.0, 0.85, 0.0) if hit_wall else (spread_dir * randf_range(FLAME_JET_SPEED_MIN, FLAME_JET_SPEED_MAX) + velocity * 0.35),
		"age": 0.0,
		"dur": dur + (0.35 if hit_wall else 0.0),
		"stopped": hit_wall,
		"sc0": sc0,
	})


func _update_flame_jets(delta: float) -> void:
	_advance_flame_jets(delta)
	# Emit after advancing so fresh puffs render at the nozzle stagger instead of a tick downstream
	_tick_flame_emitter(delta)


func _advance_flame_jets(delta: float) -> void:
	if _flame_jets.is_empty():
		return
	var space := get_world_3d().direct_space_state
	var i := _flame_jets.size() - 1
	while i >= 0:
		var fj: Dictionary = _flame_jets[i]
		var node := fj["node"] as MeshInstance3D
		fj["age"] = float(fj["age"]) + delta
		var dur: float = float(fj["dur"])
		if not is_instance_valid(node) or float(fj["age"]) >= dur:
			if is_instance_valid(node):
				node.queue_free()
			_flame_jets.remove_at(i)
			i -= 1
			continue
		var u := clampf(float(fj["age"]) / maxf(dur, 0.05), 0.0, 1.0)
		var vel: Vector3 = fj["vel"]
		if not bool(fj["stopped"]):
			# Liquid napalm: heavy fuel rope arcs DOWN under gravity with air drag; only the cooling
			# smoke/ember tail turns buoyant and curls upward on the thermal
			vel *= exp(-delta * 1.9)
			if u < 0.55:
				vel.y -= 4.6 * delta
			else:
				vel.y += 2.0 * delta
			var p0 := node.global_position
			var p1 := p0 + vel * delta
			if space and p0.distance_squared_to(p1) > 0.0001:
				var q := PhysicsRayQueryParameters3D.create(p0, p1, 1)
				q.exclude = [get_rid()]
				var h := space.intersect_ray(q)
				if not h.is_empty():
					# Clinging splash: burning fuel sticks to the wall/floor and licks upward
					var hn := h["normal"] as Vector3
					node.global_position = (h["position"] as Vector3) + hn * 0.12
					vel = Vector3(0.0, 0.85, 0.0)
					fj["stopped"] = true
					fj["dur"] = minf(dur + 0.32, float(fj["age"]) + 0.62)
					var n_emb := 1 + (randi() % 2)
					for _e in range(n_emb):
						var ev := (hn * randf_range(0.6, 1.4) + Vector3(randf_range(-0.9, 0.9), randf_range(0.8, 2.0), randf_range(-0.9, 0.9)))
						_spawn_flame_ember(node.global_position, ev, randf_range(0.6, 1.2))
				else:
					node.global_position = p1
			else:
				node.global_position = p1
		else:
			node.global_position += vel * delta
		fj["vel"] = vel
		var sc0 := float(fj.get("sc0", 0.26))
		var sc := lerpf(sc0, 1.38, pow(u, 0.58))
		if bool(fj["stopped"]):
			sc = maxf(sc, 0.55)
		node.scale = Vector3(sc, sc, 1.0)
		var sm := fj["mat"] as ShaderMaterial
		if sm:
			sm.set_shader_parameter("age_norm", u)
			sm.set_shader_parameter("intensity", lerpf(1.50, 0.38, pow(u, 0.85)))
			sm.set_shader_parameter("smoke_mix", lerpf(0.18, 0.92, smoothstep(0.30, 0.92, u)))
			sm.set_shader_parameter("fade_alpha", clampf(1.0 - smoothstep(0.62, 1.0, u), 0.0, 1.0))
		i -= 1


func _flame_los(origin: Vector3, target: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var q := PhysicsRayQueryParameters3D.create(origin, target, 1)
	q.exclude = [get_rid()]
	return space.intersect_ray(q).is_empty()


func _fire_flamethrower(w: Dictionary) -> void:
	_flame_firing_timer = 0.16
	_spawn_flame_jet_stream(w)
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var reach := 11.5
	var dmg_scale := 1.45 if is_weapon_upgraded(current_weapon) else 1.0
	# Wall distance straight down the stream axis (the stream never punches through solid walls)
	var wall_d := reach
	if space:
		var wq := PhysicsRayQueryParameters3D.create(origin, origin + fwd * reach, 1)
		wq.exclude = [get_rid()]
		var wh := space.intersect_ray(wq)
		if not wh.is_empty():
			wall_d = origin.distance_to(wh["position"])
	var z_hit_set := {}
	# Point-blank reliability: direct skeleton raycast down the nozzle axis
	var zh := ZombieAI.raycast_all_zombies(origin, fwd, wall_d)
	if not zh.is_empty():
		var zd := zh["zombie"] as ZombieAI
		if is_instance_valid(zd) and not zd.dead:
			z_hit_set[zd] = true
	# Swept 3D cone + stream-axis capsule against every living zombie, LOS-gated by world geometry
	for z_raw in ZombieAI._all_zombies:
		var z := z_raw as ZombieAI
		if not is_instance_valid(z) or z.dead or not z.is_inside_tree() or z_hit_set.has(z):
			continue
		var best := false
		for hgt: float in [1.05, 0.55, 1.50]:
			var c := z.global_position + Vector3(0.0, hgt, 0.0)
			var to := c - origin
			var along := to.dot(fwd)
			if along < 0.15 or along > reach:
				continue
			var dist := to.length()
			var dotf := to.dot(fwd) / maxf(dist, 0.001)
			# Liquid fuel sags under gravity: widen the capsule slightly with distance & allow for the arc drop
			var sag := 0.5 * 5.4 * pow(along / 15.0, 2.0)
			var perp := (to - fwd * along + Vector3(0.0, sag, 0.0)).length()
			if dotf < 0.92 and perp > 0.95 + along * 0.02:
				continue
			if _flame_los(origin, c):
				best = true
				break
		if best:
			z_hit_set[z] = true
	var any_live := false
	for zk in z_hit_set.keys():
		var z := zk as ZombieAI
		if not is_instance_valid(z) or z.dead:
			continue
		z.apply_burn(5.5, 58.0 * dmg_scale, true)
		z.apply_status_damage(float(w["damage"]) * dmg_scale)
		# apply_status_damage already emits hit_confirmed(false, true) on kill — never double-award points!
		if not z.dead:
			any_live = true
	if any_live and _flame_hit_tick_cd <= 0.0:
		_flame_hit_tick_cd = 0.14
		emit_signal("hit_confirmed", false, false)
	if not z_hit_set.is_empty():
		shots_hit += 1
	# Lay down clinging burning napalm on the floor where the arcing stream lands (never under the player's boots)
	if _flame_pool_cd <= 0.0 and space:
		_flame_pool_cd = 0.42
		var sag_dir := (fwd + Vector3(0.0, -0.10, 0.0)).normalized()
		var fq := PhysicsRayQueryParameters3D.create(origin, origin + sag_dir * reach, 1)
		fq.exclude = [get_rid()]
		var fhit := space.intersect_ray(fq)
		var pool_p := _project_to_floor(fhit["position"] as Vector3) if not fhit.is_empty() else _project_to_floor(origin + sag_dir * 7.5)
		if pool_p.distance_to(global_position) >= 2.0 and absf(pool_p.y - global_position.y) <= 3.5:
			_spawn_hazard_pool("fire", pool_p, 3.2, 2.0, true)


func _fire_rpg_rocket() -> void:
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var base_dmg := float(WEAPONS[17]["damage"]) * (1.45 if is_weapon_upgraded(17) else 1.0)
	var spawn_p := origin + fwd * 0.65 - camera.global_transform.basis.y * 0.06
	var max_spawn_d := origin.distance_to(spawn_p)
	var spawn_nrm := Vector3.UP
	if space:
		var sq := PhysicsRayQueryParameters3D.create(origin, spawn_p, 1)
		sq.exclude = [get_rid()]
		var sh := space.intersect_ray(sq)
		if not sh.is_empty():
			max_spawn_d = origin.distance_to(sh["position"] as Vector3)
			spawn_p = (sh["position"] as Vector3) + (sh["normal"] as Vector3) * 0.12
			spawn_nrm = sh["normal"] as Vector3
	# Immediate point-blank zombie check so close zombies within 0.65m never let rockets pass through!
	var pb_zh := ZombieAI.raycast_all_zombies(origin, fwd, max_spawn_d)
	if not pb_zh.is_empty():
		_pose_part("warhead", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)
		_detonate_rpg(pb_zh["pos"] as Vector3, base_dmg, -fwd, pb_zh["zombie"] as ZombieAI)
		return
	var r_node := Node3D.new()
	# Clone the actual photoreal PBR PG-7V Warhead mesh from weapon_rpg7.glb (AGENTS.md Rule #1!)
	var cloned_wh := false
	if _w_parts.has("warhead"):
		for wn in _w_parts["warhead"]:
			var wmi := wn as MeshInstance3D
			if wmi and wmi.mesh:
				var mi := MeshInstance3D.new()
				mi.mesh = wmi.mesh
				for si in range(wmi.mesh.get_surface_count()):
					var sm := wmi.get_active_material(si)
					if sm: mi.set_surface_override_material(si, sm)
				mi.position = Vector3(0.0, 0.0, 0.35)
				mi.layers = 1
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				r_node.add_child(mi)
				cloned_wh = true
				break
	if not cloned_wh:
		var body := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012; cm.bottom_radius = 0.042; cm.height = 0.42; cm.radial_segments = 12
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.24, 0.30, 0.18); mat.metallic = 0.35; mat.roughness = 0.55
		cm.material = mat
		body.mesh = cm
		body.rotation.x = -PI * 0.5
		body.layers = 1
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		r_node.add_child(body)
	if not OS.has_feature("web"):
		var exhaust := OmniLight3D.new()
		exhaust.position = Vector3(0.0, 0.0, 0.25)
		exhaust.light_color = Color(1.0, 0.56, 0.16)
		exhaust.light_energy = 4.5
		exhaust.omni_range = 6.0
		exhaust.shadow_enabled = false
		exhaust.light_cull_mask = 0xFFFFD
		exhaust.light_volumetric_fog_energy = 0.0
		r_node.add_child(exhaust)
	_fx_parent().add_child(r_node)
	r_node.global_position = spawn_p
	r_node.look_at(spawn_p + fwd * 10.0, Vector3.UP)
	_rockets.append({
		"node": r_node,
		"vel": fwd * 32.0,
		"age": 0.0,
		"dmg": base_dmg,
	})
	_pose_part("warhead", Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, false)


func _update_rockets(delta: float) -> void:
	if _rockets.is_empty():
		return
	var space := get_world_3d().direct_space_state
	var i := _rockets.size() - 1
	while i >= 0:
		var r: Dictionary = _rockets[i]
		var node: Node3D = r["node"]
		if not is_instance_valid(node):
			_rockets.remove_at(i)
			i -= 1
			continue
		r["age"] = float(r["age"]) + delta
		var vel: Vector3 = r["vel"]
		vel.y -= 2.2 * delta
		var p0 := node.global_position
		var p1 := p0 + vel * delta
		var step := p1 - p0
		var step_d := step.length()
		var hit_pos := Vector3.ZERO
		var hit_nrm := Vector3.UP
		var direct_z: ZombieAI = null
		var did_hit := false
		if space and step_d > 0.001:
			var q := PhysicsRayQueryParameters3D.create(p0, p1, 1)
			q.exclude = [get_rid()]
			var wh := space.intersect_ray(q)
			var max_zd := p0.distance_to(wh["position"]) if not wh.is_empty() else step_d
			var zh := ZombieAI.raycast_all_zombies(p0, step / step_d, max_zd)
			if not zh.is_empty():
				hit_pos = zh["pos"] as Vector3
				hit_nrm = -(step / step_d)
				direct_z = zh["zombie"] as ZombieAI
				did_hit = true
			elif not wh.is_empty():
				hit_nrm = wh["normal"] as Vector3
				hit_pos = (wh["position"] as Vector3) + hit_nrm * 0.15
				did_hit = true
		if did_hit or float(r["age"]) >= 4.5:
			var dpos := hit_pos if did_hit else p1
			_detonate_rpg(dpos, float(r["dmg"]), hit_nrm, direct_z)
			node.queue_free()
			_rockets.remove_at(i)
		else:
			node.global_position = p1
			node.look_at(p1 + vel.normalized() * 4.0, Vector3.UP)
			r["vel"] = vel
		i -= 1


func _detonate_rpg(pos: Vector3, base_dmg: float, blast_normal: Vector3 = Vector3.UP, direct_target: ZombieAI = null) -> void:
	var dist_p := global_position.distance_to(pos)
	trauma = minf(1.0, trauma + clampf(1.0 - dist_p / 18.0, 0.25, 1.0))
	if sfx_gun and _weapon_audio.size() > 2 and _weapon_audio[2]:
		_play_gun_sfx(_weapon_audio[2], 0.44)
	var radius := 7.5
	for z_raw in ZombieAI._all_zombies.duplicate():
		var z := z_raw as ZombieAI
		if not is_instance_valid(z) or z.dead:
			continue
		var is_direct := (z == direct_target)
		var d_horiz := Vector2(z.global_position.x - pos.x, z.global_position.z - pos.z).length()
		if is_direct or (d_horiz <= radius and absf(z.global_position.y - pos.y) <= 3.8 and _has_aoe_los(pos, z.global_position, blast_normal)):
			var falloff := 1.0 if is_direct else clampf(1.0 - (d_horiz / radius) * 0.65, 0.35, 1.0)
			var dir := (z.global_position + Vector3(0, 1.0, 0) - pos).normalized()
			if dir.length_squared() < 0.01:
				dir = -camera.global_transform.basis.z
			# RPG-7 shaped-charge warhead punches straight through chest armor on direct hits!
			var armor_bypass := (1.0 / maxf(z._chest_armor_mult, 0.35)) if is_direct else 1.0
			var res := z.apply_shot([{"zone": "CHEST", "pos": z.global_position + Vector3(0, 1.0, 0), "dir": dir, "dmg": base_dmg * falloff * armor_bypass, "dist": d_horiz}], 2)
			if not bool(res.get("corpse_hit", false)):
				emit_signal("hit_confirmed", bool(res.get("headshot", false)), bool(res.get("killed", false)))
			if not z.dead and z.has_method("apply_knockback"):
				z.apply_knockback(dir * (10.0 * falloff))
	if dist_p <= 5.0 and absf(global_position.y - pos.y) <= 3.0 and _has_aoe_los(pos, global_position, blast_normal):
		take_damage(clampf(55.0 * (1.0 - dist_p / 5.0), 14.0, 55.0), pos)
	_spawn_hazard_pool("frag_flash", pos, 0.45, 4.2)
	_spawn_hazard_pool("fire", _project_to_floor(pos), 4.5, 2.8)


func get_spread_now() -> float:
	# Live cone half-angle (tangent units) shared by the shot maths and the HUD crosshair
	var w: Dictionary = WEAPONS[current_weapon]
	if bool(w.get("is_melee", false)) or bool(w.get("is_bow", false)):
		return 0.0
	var is_shotgun := (current_weapon == 2 or current_weapon == 9 or current_weapon == 11)
	var mult := (0.55 if is_ads else 1.0) if is_shotgun else (0.14 if is_ads else 0.72)
	var extra := 0.0
	if not is_shotgun:
		var move := clampf(Vector2(velocity.x, velocity.z).length() / 4.1, 0.0, 1.5)
		extra = 0.0065 * move + _spread_bloom * 0.011 + _sprint_blend * 0.012
		if not is_on_floor():
			extra += 0.014
		if is_ads:
			extra *= 0.22
		if is_crouching:
			mult *= 0.8
			extra *= 0.7
	return float(w["spread"]) * mult + extra


func get_fire_mode_label(idx: int) -> String:
	var w: Dictionary = WEAPONS[idx]
	if bool(w.get("is_melee", false)):
		return "MELEE"
	if bool(w.get("is_bow", false)):
		return "DRAW"
	if bool(w.get("is_flamethrower", false)):
		return "STREAM"
	if int(w.get("burst_count", 0)) > 1:
		return "BURST"
	if bool(w["auto"]):
		return "AUTO"
	if idx == 2:
		return "PUMP"
	if idx == 7 or idx == 14:
		return "BOLT"
	if idx == 11:
		return "BREAK"
	if idx == 6:
		return "DA"
	return "SEMI"


static func get_penetration(idx: int) -> int:
	# Extra bodies a round passes through
	match idx:
		7, 13, 14: return 2 # full-power rifle cartridges
		1, 8, 10, 12, 6: return 1 # intermediate rifles and the .44
	return 0


static func get_falloff_mult(idx: int, dist: float) -> float:
	# Damage falloff by weapon class: [full-damage range, minimum-damage range, floor]
	var r0 := 30.0
	var r1 := 70.0
	var floor_m := 0.8
	match idx:
		0, 5: # 9mm pistol and SMG
			r0 = 12.0; r1 = 34.0; floor_m = 0.55
		6:
			r0 = 16.0; r1 = 40.0; floor_m = 0.65
		2, 9: # buckshot
			r0 = 6.5; r1 = 22.0; floor_m = 0.30
		11: # sawed-off
			r0 = 4.0; r1 = 13.0; floor_m = 0.22
		7, 13, 14:
			return 1.0
	if dist <= r0:
		return 1.0
	return lerpf(1.0, floor_m, clampf((dist - r0) / (r1 - r0), 0.0, 1.0))


static func describe_weapon(idx: int) -> String:
	# One-line stat readout for purchase prompts and the loadout screen
	var w: Dictionary = WEAPONS[idx]
	if bool(w.get("is_melee", false)):
		return ""
	var pel := int(w["pellets"])
	var dmg_s := ("%dx%d" % [int(w["damage"]), pel]) if pel > 1 else str(int(w["damage"]))
	var rpm := int(round(60.0 / maxf(float(w["fire_rate"]), 0.02)))
	var mode := "AUTO" if bool(w["auto"]) else ("BURST" if int(w.get("burst_count", 0)) > 1 else "SEMI")
	var parts: Array[String] = ["DMG %s" % dmg_s, "%d RPM" % rpm, "MAG %d" % int(w["mag_size"]), mode]
	var pen := get_penetration(idx)
	if pen > 0:
		parts.append("PIERCES %d" % pen)
	return "  ·  ".join(parts)


func fire_weapon(is_burst_shot: bool = false) -> bool:
	var w: Dictionary = WEAPONS[current_weapon]
	if ammo_in_mag[current_weapon] <= 0:
		if bool(w.get("is_flamethrower", false)):
			emit_signal("status_message", "FLAMETHROWER TANK EMPTY (LIMITED FUEL)")
			fire_cd = 0.35
			return false
		start_reload()
		return false
	ammo_in_mag[current_weapon] -= 1
	shots_fired += 1
	_spread_bloom = minf(1.0, _spread_bloom + (0.34 if not bool(w["auto"]) else 0.16))
	if ammo_in_mag[current_weapon] <= 0:
		weapon_chambered[current_weapon] = false
		if current_weapon == 13:
			# Iconic M1 Garand en-bloc clip PING + the empty steel clip flipping out of the open breech!
			if sfx_casing:
				if _sfx_garand_ping:
					sfx_casing.stream = _sfx_garand_ping
					sfx_casing.pitch_scale = randf_range(0.97, 1.04)
					sfx_casing.play()
				elif not _sfx_shell_clink.is_empty():
					sfx_casing.stream = _sfx_shell_clink[0]
					sfx_casing.pitch_scale = 2.15
					sfx_casing.play()
			_spawn_garand_clip_eject()
	# 3-Round Burst scheduling (FAMAS F1)!
	var b_cnt := int(w.get("burst_count", 0))
	if b_cnt > 1 and not is_burst_shot and ammo_in_mag[current_weapon] > 0:
		_burst_remaining = mini(b_cnt - 1, ammo_in_mag[current_weapon])
		_burst_timer = float(w.get("burst_interval", 0.058))
	# Carry cooldown overshoot on automatic weapons so MP5 (0.068s) fires at true RPM instead of quantizing to 60Hz ticks!
	if bool(w["auto"]):
		fire_cd = maxf(0.0, fire_cd) + float(w["fire_rate"])
	elif not is_burst_shot:
		fire_cd = float(w["fire_rate"])

	var is_sup := has_attachment(current_weapon, "suppressor")
	var f_scale_base := float(w["flash_scale"]) * (0.42 if is_sup else 1.0)
	muzzle_elapsed = 0.0
	muzzle_peak_e = 2.8 * f_scale_base * randf_range(0.88, 1.15)
	if f_scale_base > 0.05:
		muzzle_light.visible = true
		muzzle_light.light_energy = muzzle_peak_e
		muzzle_vm_light.visible = true
		muzzle_vm_light.light_energy = minf(muzzle_peak_e * 0.38, 1.25)
		_flash_shadow_boost = 1.0
		_barrel_heat_timer = 1.4
		_barrel_heat_step = 0.22

	var m_dist: float = absf((w["muzzle"] as Vector3).z)
	var space := get_world_3d().direct_space_state
	if space:
		var wq := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_transform.basis.z * (m_dist + 0.25), 1)
		var whit := space.intersect_ray(wq)
		if whit:
			var safe_d := maxf(0.18, camera.global_position.distance_to(whit["position"]) - 0.16)
			muzzle_light.position = Vector3(0.0, 0.03, -safe_d)
		else:
			muzzle_light.position = w["muzzle"]
		muzzle_vm_light.position = muzzle_light.position

	if f_scale_base > 0.05 and current_weapon != 16:
		muzzle_flash_timer = 0.036
		muzzle_flash_rig.visible = true
		muzzle_flash_rig.rotation.z = randf() * TAU
		var fscale: float = f_scale_base * randf_range(0.86, 1.18)
		muzzle_flash_rig.scale = Vector3.ONE * fscale
		var seed_v := randf() * 100.0
		for fm in _flash_mats:
			fm.set_shader_parameter("flash_seed", seed_v)
			fm.set_shader_parameter("cool_t", 0.0)

	if VFXManager.instance and f_scale_base > 0.05:
		VFXManager.instance.spawn_muzzle_sparks(muzzle_flash_rig.global_position, -camera.global_transform.basis.z, current_weapon == 2 or current_weapon == 9 or current_weapon == 11 or current_weapon == 16)

	if muzzle_smoke and f_scale_base > 0.05:
		if OS.has_feature("web"):
			muzzle_smoke.restart()
			muzzle_smoke.emitting = true
		else:
			var smoke_xf := muzzle_smoke.global_transform.translated_local(Vector3(0.0, 0.02, -0.08))
			for _s in range(2):
				var sv := -camera.global_transform.basis.z * randf_range(0.25, 0.58) + camera.global_transform.basis.x * randf_range(0.08, 0.26) + Vector3(0.0, randf_range(0.36, 0.72), 0.0)
				muzzle_smoke.emit_particle(smoke_xf, sv, Color.WHITE, Color.WHITE, GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)

	if current_weapon != 2 and current_weapon != 6 and current_weapon != 7 and current_weapon != 11 and current_weapon != 14 and current_weapon != 15 and current_weapon != 16 and current_weapon != 17:
		_eject_brass_casing(w, current_weapon == 9)
	bolt_blowback = 1.0
	if current_weapon == 1:
		_m16_dust_open = true
	if current_weapon == 2:
		shotgun_pump_timer = 0.42
		shotgun_pump_did_sfx = false
	if current_weapon == 6:
		_revolver_cyl_angle += TAU / 6.0
		_revolver_hammer = 1.0
	if current_weapon == 7 or current_weapon == 14:
		_hunting_bolt_timer = 0.78
		_hunting_bolt_did_sfx = false

	var rec_mult := 0.65 if is_sup else 1.0
	recoil_vel.y += w["recoil_pitch"] * rec_mult * (0.65 if is_ads else 1.0)
	recoil_z += w["recoil_kick"] * rec_mult
	recoil_roll += randf_range(-0.018, 0.018) * rec_mult * (0.5 if is_ads else 1.0)
	recoil_fov = 1.15 * rec_mult
	trauma = minf(1.0, trauma + (0.28 if (current_weapon == 2 or current_weapon == 9 or current_weapon == 11 or current_weapon == 17) else (0.14 if current_weapon == 1 else 0.11)))
	pitch = clamp(pitch + w["recoil_pitch"] * rec_mult * 0.32, -1.35, 1.35)

	# Pooled polyphonic gunshot playback (NEVER swaps stream on an active voice, preserving 100% of reverb tails!)
	var shot_stream: AudioStream = null
	if current_weapon < _weapon_audio_vars.size():
		var vars_arr: Array = _weapon_audio_vars[current_weapon]
		if not vars_arr.is_empty():
			_gun_alt_flip = (_gun_alt_flip + 1) % vars_arr.size()
			shot_stream = vars_arr[_gun_alt_flip]
	elif current_weapon < _weapon_audio.size():
		shot_stream = _weapon_audio[current_weapon]
	# The M2 flamethrower is carried by the continuous looping jet roar (sfx_flame_loop), never per-tick booms
	if shot_stream and current_weapon != 16:
		var pitch_s := randf_range(1.25, 1.38) if is_sup else (0.58 if current_weapon == 17 else randf_range(0.95, 1.04))
		_play_gun_sfx(shot_stream, pitch_s)

	# Specialized non-hitscan weapon dispatchers (Crossbow, Flamethrower, RPG-7)!
	if bool(w.get("is_crossbow", false)):
		_fire_bow_arrow(1.0, 15)
		return true
	if bool(w.get("is_flamethrower", false)):
		_fire_flamethrower(w)
		return true
	if bool(w.get("is_rpg", false)):
		_fire_rpg_rocket()
		return true

	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	# Consistent shotgun buckshot spread for M870 (2), Benelli M4 (9), and Sawed-Off DB (11)!
	var is_shotgun := (current_weapon == 2 or current_weapon == 9 or current_weapon == 11)
	var spread: float = get_spread_now()
	var dmg_per_hit: float = float(w["damage"]) * (1.45 if is_weapon_upgraded(current_weapon) else 1.0)
	var pen_left_base := get_penetration(current_weapon)
	var impact_fx_budget := 3 if int(w["pellets"]) > 1 else 1
	var z_hits := {}

	for _p in range(w["pellets"]):
		var dir := (fwd + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
		var wall_excl: Array[RID] = [get_rid()]
		var wall_hit := {}
		for _retry in range(3):
			var wq_hit := PhysicsRayQueryParameters3D.create(origin, origin + dir * 75.0, 1)
			wq_hit.collide_with_areas = false
			wq_hit.collide_with_bodies = true
			wq_hit.exclude = wall_excl
			wall_hit = space.intersect_ray(wq_hit)
			if wall_hit.is_empty():
				break
			var wc = wall_hit["collider"]
			if wc is InteractableObject and (wc as InteractableObject).kind == InteractableObject.Kind.BARRICADE:
				wall_excl.append((wc as CollisionObject3D).get_rid())
				wall_hit = {}
				continue
			break
		var max_dist := origin.distance_to(wall_hit["position"]) if not wall_hit.is_empty() else 75.0

		# Walk the bullet through bodies: rifle-calibre rounds over-penetrate into whoever stands behind, losing energy each time
		var pierced: Array = []
		var pen_left := pen_left_base
		var carry := 1.0
		var hit_any_body := false
		while true:
			var z_hit := ZombieAI.raycast_all_zombies(origin, dir, max_dist, pierced)
			if z_hit.is_empty():
				break
			var z := z_hit["zombie"] as ZombieAI
			if not is_instance_valid(z):
				break
			hit_any_body = true
			var h_dist := float(z_hit["dist"])
			if not z_hits.has(z):
				z_hits[z] = []
			(z_hits[z] as Array).append({
				"zone": str(z_hit["zone"]),
				"pos": z_hit["pos"],
				"dir": dir,
				"dmg": dmg_per_hit * carry * get_falloff_mult(current_weapon, h_dist),
				"dist": h_dist,
			})
			if pen_left <= 0 or z.dead:
				break
			pen_left -= 1
			carry *= 0.62
			pierced.append(z)
		if hit_any_body:
			continue

		if not wall_hit.is_empty():
			if impact_fx_budget > 0:
				impact_fx_budget -= 1
				if VFXManager.instance:
					VFXManager.instance.spawn_surface_impact(wall_hit["position"], wall_hit["normal"], dir, wall_hit["collider"], current_weapon)

	var any_zombie_hit := false
	var any_live_hit := false
	var any_live_headshot := false
	var any_gore_crunch := false
	for z_key in z_hits.keys():
		var z := z_key as ZombieAI
		var arr: Array = z_hits[z_key]
		var res := z.apply_shot(arr, current_weapon)
		var is_hs := bool(res.get("headshot", false))
		var killed := bool(res.get("killed", false))
		var corpse_hit := bool(res.get("corpse_hit", false))
		var did_dismember := bool(res.get("dismembered", false))
		any_zombie_hit = true
		any_gore_crunch = any_gore_crunch or is_hs or did_dismember
		if not corpse_hit:
			any_live_hit = true
			any_live_headshot = any_live_headshot or is_hs
			emit_signal("hit_confirmed", is_hs, killed)

	if any_live_hit:
		shots_hit += 1
	if any_zombie_hit:
		if sfx_hit:
			var pool := _sfx_hit_head if any_gore_crunch else _sfx_hit_flesh
			if not pool.is_empty():
				sfx_hit.stream = pool[randi() % pool.size()]
				sfx_hit.pitch_scale = randf_range(0.92, 1.08)
				sfx_hit.play()
		if any_live_hit and sfx_hit_tick and _sfx_hit_confirm:
			sfx_hit_tick.stream = _sfx_hit_confirm
			sfx_hit_tick.pitch_scale = 1.18 if any_live_headshot else 0.96
			sfx_hit_tick.play()
	return true


func get_looked_interactable() -> InteractableObject:
	if interact_ray and interact_ray.is_colliding():
		var c = interact_ray.get_collider()
		if c is InteractableObject:
			return c
	return null


func try_interact() -> String:
	var obj := get_looked_interactable()
	if obj:
		var msg := obj.interact(game_manager, self)
		if msg != "":
			emit_signal("status_message", msg)
		return msg
	return ""


func take_damage(amount: float, from_pos: Vector3 = Vector3.ZERO) -> void:
	if dead or damage_invuln > 0.0 or god_mode:
		return
	damage_invuln = 0.35
	if _bow_drawing:
		cancel_bow_draw(true)
	health = max(0.0, health - amount)
	damage_taken_total += amount
	regen_delay = 3.5 if perks.has("adrenal") else 5.0
	last_damage_dir = from_pos
	last_damage_time = Time.get_ticks_msec() * 0.001
	_melee_charging = false
	_melee_charge = 0.0
	damage_flash = min(1.0, damage_flash + clampf(0.35 + amount / 45.0, 0.45, 0.85))
	ads_lockout = 0.22
	trauma = minf(1.0, trauma + clampf(0.25 + amount / 60.0, 0.3, 0.7))
	hit_glitch = clampf(amount / 70.0, 0.14, 0.42)
	hit_ca_boost = 0.018

	var kick_side := 1.0
	if from_pos != Vector3.ZERO:
		var local_src := camera.global_transform.basis.inverse() * (from_pos - camera.global_position).normalized()
		hit_dir_screen = Vector2(clampf(local_src.x, -1.0, 1.0), clampf(-local_src.y, -1.0, 1.0))
		kick_side = -signf(local_src.x) if absf(local_src.x) > 0.08 else (1.0 if randf() < 0.5 else -1.0)
	else:
		hit_dir_screen = Vector2(0.0, 0.2)
		kick_side = 1.0 if randf() < 0.5 else -1.0

	hit_roll_kick += kick_side * 0.12
	hit_pitch_kick += randf_range(0.05, 0.09)

	if sfx_slash and not _sfx_player_slash.is_empty():
		sfx_slash.stream = _sfx_player_slash[randi() % _sfx_player_slash.size()]
		sfx_slash.pitch_scale = randf_range(0.92, 1.08)
		sfx_slash.play()
	if sfx_hurt and _sfx_player_hurt:
		sfx_hurt.stream = _sfx_player_hurt
		sfx_hurt.pitch_scale = randf_range(0.94, 1.06)
		sfx_hurt.play()

	if health <= 0.0:
		dead = true
		_burst_remaining = 0
		_burst_timer = 0.0
		if grabbed_by != null:
			end_grab(false)
		if _quick_melee_active:
			_quick_melee_active = false
			_melee_timer = 0.0
			for ri in range(_weapon_rigs.size()):
				if is_instance_valid(_weapon_rigs[ri]):
					_weapon_rigs[ri].visible = (ri == current_weapon)
		emit_signal("player_died")


func heal_full(reset_unlocks: bool = false) -> void:
	health = max_health
	dead = false
	velocity = Vector3.ZERO
	is_ads = false
	_ads_blend = 0.0
	recoil_vel = Vector2.ZERO
	trauma = 0.0
	damage_flash = 0.0
	damage_invuln = 0.0
	hit_glitch = 0.0
	hit_ca_boost = 0.0
	_base_head_roll = 0.0
	head.rotation.z = 0.0
	cancel_bow_draw(false)
	# Clear all live/stuck world arrows cleanly on restart!
	for a: Dictionary in _arrows:
		if is_instance_valid(a.get("node")):
			(a["node"] as Node).queue_free()
	_arrows.clear()
	for g: Dictionary in _grenades:
		if is_instance_valid(g.get("node")):
			(g["node"] as Node).queue_free()
	_grenades.clear()
	for h: Dictionary in _hazards:
		if is_instance_valid(h.get("node")):
			(h["node"] as Node).queue_free()
	_hazards.clear()
	for r: Dictionary in _rockets:
		if is_instance_valid(r.get("node")):
			(r["node"] as Node).queue_free()
	_rockets.clear()
	for fj: Dictionary in _flame_jets:
		if is_instance_valid(fj.get("node")):
			(fj["node"] as Node).queue_free()
	_flame_jets.clear()
	for fe: Dictionary in _flame_embers:
		if is_instance_valid(fe.get("node")):
			(fe["node"] as Node).queue_free()
	_flame_embers.clear()
	_flame_firing_timer = 0.0
	_flame_hit_tick_cd = 0.0
	_flamer_flare = 0.0
	if sfx_flame_loop and sfx_flame_loop.playing:
		sfx_flame_loop.stop()
	if is_instance_valid(_flamer_pilot_node):
		_flamer_pilot_node.visible = false
	_bow_nock_sfx_played = false
	_burst_remaining = 0
	_burst_timer = 0.0
	_flame_pool_cd = 0.0
	_flame_emit_window = 0.0
	_flame_emit_accum = 0.0
	_quick_melee_active = false
	_melee_timer = 0.0
	_melee_hitstop_timer = 0.0
	_melee_charging = false
	_melee_charge = 0.0
	_melee_charge_pose = 0.0
	_melee_lunge_timer = 0.0
	_shove_cd = 0.0
	grabbed_by = null
	grab_struggle = 0.0
	grab_immunity = 0.0
	slow_timer = 0.0
	slow_mult = 1.0
	_ext_vel = Vector3.ZERO
	regen_delay = 0.0
	last_damage_time = -99.0
	if reset_unlocks:
		shots_fired = 0
		shots_hit = 0
		damage_taken_total = 0.0
		perks.clear()
		max_health = 100.0
		health = max_health
		last_hit_by = ""
		firearm_slots = [0]
		special_slot = -1
		owned_melee = ["knife"]
		select_melee_weapon("knife")
		grenade_counts = {"frag": 2, "molotov": 1, "shock": 1}
		equipped_grenade = "frag"
		weapon_attachments.clear()
		_sync_unlocked_from_loadout()
		upgraded_weapons.resize(WEAPONS.size())
		weapon_chambered.resize(WEAPONS.size())
		for wi in range(WEAPONS.size()):
			upgraded_weapons[wi] = false
			weapon_chambered[wi] = true
		equipped_melee_id = "knife"
		for k in _melee_nodes.keys():
			if is_instance_valid(_melee_nodes[k]):
				(_melee_nodes[k] as Node3D).visible = (str(k) == "knife")
		_equip_weapon(0, true)
	for i in range(WEAPONS.size()):
		if reset_unlocks or not is_no_refill_weapon(i):
			ammo_in_mag[i] = get_weapon_mag_size(i)
			ammo_reserve[i] = WEAPONS[i]["reserve_max"]
			weapon_chambered[i] = true
