# DEADCAM: BLACKOUT — Agent Engineering & Asset Standards (`AGENTS.md`)

## RULE #1 (TOP PRIORITY): Weapon, Melee & Asset Quality Gate
**NO weapon — firearm, melee weapon, bow, crossbow, throwable, or special weapon — may be added to or shipped in the game without passing a deep visual and mechanical inspection.**

1. **Zero Stylistic / Low-Tier / Blocky Assets:**
   - Never ship primitive box/cylinder procedural weapons or low-poly/cartoon/stylized models.
   - Every firearm, melee weapon, bow, crossbow, and grenade must use a genuine high-detail photorealistic 3D mesh with real PBR textures (`albedo`, `normal`, `roughness/metallic`), realistic proportions, and authentic surface wear matching the existing G17, M16A2, and M870 standard.
2. **Straight, Properly Seated Attachments & Parts:**
   - Barrels, suppressors, optics, magazines, bolts, charging handles, cylinders, slings, and grips must be geometrically straight, axis-aligned, and physically seated to the receiver — never bent, floating, clipped, or misaligned.
   - Do **not** force scopes or suppressors onto weapons by default unless the weapon authentically requires it; prefer clean iron-sight base models with modular/optional attachments.
3. **Mandatory Deep Visual Inspection Before Shipping Any Weapon:**
   - Render and visually inspect **three views** of every new or modified weapon via Godot before committing:
     1. **Bright Neutral Studio 3/4 Profile** (verifying silhouette, proportions, attachment alignment, and PBR textures with zero missing/white maps).
     2. **In-Game First-Person Hip & ADS View** (verifying hand placement, eye-relief/sight picture, and zero camera clipping).
     3. **4-Phase Reload / Action Contact Sheet** (verifying clip/mag extraction, empty magwell, insertion, bolt/slide/cylinder/lid action, and zero floating hands or giant sleeve bloat).
   - If any part looks bent, floating, fake, blocky, or mis-textured, **fix it before shipping**.
4. **Distinct Mechanics & Feel:**
   - Every firearm must have authentic reload choreography (clip visibly out -> empty -> clip in -> bolt/slide/charge).
   - Every melee weapon must have tailored swing weight, combo arcs, alternate heavy attack feel, and directional zombie hit reactions.

---

## Core Engineering Rules

- **Never Degrade Desktop Forward+ for Web:** Desktop builds (`Forward+`, Windows x64 + macOS Universal) must retain full lighting, shadows, MetalFX/FSR/TAA, and volumetric fog. WebGL2 (`gl_compatibility`) optimizations must always be gated behind `OS.has_feature("web")`.
- **File Size & Repo Hygiene:**
  - Never commit any file `>= 10 MB` (target `0.15–4.5 MB` per weapon GLB with Pillow-verified `<= 1024px` JPEG/PNG textures).
  - Never leave `export_presets.cfg` in the repository after Web export. Build the web release with `python tools/export_web.py <godot console exe> <output dir>`: it exports from a temporary copy (so the preset never touches the repo), drops assets nothing loads, and applies the web-only texture budget without changing desktop import settings.
  - After adding any model or texture run `python tools/fix_texture_imports.py` and re-import. Textures loaded only from code default to lossless (5.6 MB of video memory per 1024px map); the tool switches them to VRAM compression with mipmaps, detects normal maps from their pixels, and uses BC7 for first-person weapons.
  - Never modify `checks/`.
  - When updating `main` for GitHub Releases, advance `main` via `git commit-tree "HEAD^{tree}" -p $(git rev-parse main)` + `git update-ref refs/heads/main` so legacy >100 MB history blobs never enter `main`.
- **Verification Gate:** Run automated verification (`tools/verify_phase1.gd` … `tools/verify_phase5.gd`) on **both** `--rendering-method forward_plus` and `--rendering-method gl_compatibility` before shipping any gameplay or asset change. Phase 5 covers every zombie attack and special, every melee move, navigation reachability from all spawns, and walking the starting staircase.
- **Navigation Mesh:** Zombies path on `assets/baked/navmesh.res`. After ANY change to world collision (walls, props with colliders, stairs, gates) re-run `godot --path . --script tools/bake_nav.gd` and commit the result. The bake stores a fingerprint of the static colliders; a stale file is rejected at load (desktop re-bakes at startup, the web build falls back to the legacy waypoint router), so a forgotten bake degrades web pathing silently.
- **Variant Kits:** Special zombies are a base body plus a Blender-built attachment kit (`assets/models/zombie_kit_*.glb`, source `tools/build_zombie_kits.py`). Kit meshes are authored in the rest-pose character space of the base body and named `<BoneKey>__<Part>`; `ZombieAI._attach_variant_kit()` parents each to its bone. Rule #1's bar (photoreal PBR, seated, never floating) applies to kits and to environment props (`assets/models/prop_*.glb`, source `tools/build_env_props.py`).
