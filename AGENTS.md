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
  - Never leave `export_presets.cfg` in the repository after Web export.
  - Never modify `checks/`.
  - When updating `main` for GitHub Releases, advance `main` via `git commit-tree "HEAD^{tree}" -p $(git rev-parse main)` + `git update-ref refs/heads/main` so legacy >100 MB history blobs never enter `main`.
- **Verification Gate:** Run automated verification (`tools/verify_phase1.gd` and regression checks) on **both** `--rendering-method forward_plus` and `--rendering-method gl_compatibility` before shipping any gameplay or asset change.
