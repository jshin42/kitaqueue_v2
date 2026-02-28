# claude.md — Kata Queue: Sliding Gates (iOS + iPadOS) One-Shot Build Spec
Owner intent: ship a premium-feeling hybrid-casual puzzle game that maximizes “continue intent” per minute by compressing cognition → action → feedback; monetizes at the moments when continuation intent is highest (post-win momentum, post-fail frustration, near-completion tension); keeps core play deterministic and attributable. No regressions from overloading gestures or adding twitch requirements.

---

## 0) Non-negotiable product invariants
- Single primary verb: **Swipe** on lane grid to place an operator on a snapped slot. No gesture classification (“short vs long vs vertical”).
- Determinism contract: same level seed + same inputs => same outcome.
- Pressure is cognitive (planning + constraints), not reflex.
- Near-miss is designed and measurable; fail UX shows “how close you were”.
- Ads never interrupt mid-run. Ads only at natural transitions and explicitly rewarded offers.

---

## 1) Platforms + Tech Stack
### Targets
- iOS 17+ (iPhone), iPadOS 17+ (iPad). Portrait primary; iPad supports portrait + landscape.
- No account/login. Local-first persistence.

### Rendering + UI Composition
- **SpriteKit** for the entire gameplay screen (single canvas) and in-game overlays (win/fail/pause).
- **SwiftUI** for app shell screens (Home/Play hub, Daily, Shop, Settings).
- Embed SpriteKit scene into SwiftUI using SpriteView.

### Store + Ads
- StoreKit 2 for IAP.
- Ads SDK: AdMob (Google Mobile Ads) for interstitial + rewarded.

### Persistence
- SwiftData (or Codable JSON if SwiftData is a time risk). Persist: progression, daily streak, settings, cosmetics unlocks, currency.

### Analytics / Telemetry
- Minimal internal event logger (write JSON lines to local file in Debug; in Release, either no-op or hook to a lightweight analytics SDK if desired). Events defined in section 12.

---

## 2) Core Game Constants (locked defaults)
### Board
- Lanes: **4**
- Operator placement rows: **12** (R1..R12)
- Operator slots per row: **3 boundary slots**:
  - Slot A: between lane 1↔2
  - Slot B: between lane 2↔3
  - Slot C: between lane 3↔4
- Banks: **4** (one per lane) fixed mapping:
  - Lane 1 = Red bank
  - Lane 2 = Green bank
  - Lane 3 = Yellow bank
  - Lane 4 = Blue bank

### Shuriken
- Colors: Red, Green, Yellow, Blue
- Level length: **24 shuriken** (6 waves × 4), deterministic sequence in level data.

### Operators (v1)
- Operator types in v1: **Deflect only**
- Active operator cap: **3** on board at once
- Charges per operator: **K = 3**
- Operator triggers at discrete row events; each trigger decrements charges; operator disappears at 0 charges.

### Gates (v1 minimal palette)
- Color Gate (blocks non-matching -> jam)
- Toggle Gate (allowed color cycles deterministically)
- Paint Gate (color conversion)

### Fail Modes (v1 enabled)
- Misbank (wrong color enters a bank) => immediate fail
- Overflow (jam stack >= 3 in a lane) => fail
- Timer exists only as “par rating” (stars), not as hard fail in v1.

### Par / Stars (v1)
- 3 stars: win using ≤ 6 operator placements
- 2 stars: win using ≤ 8
- 1 star: win otherwise

---

## 3) Deterministic Simulation Model (no physics drift)
### Fixed timestep
- Gameplay logic updates at 60Hz fixed timestep.

### Row-based interactions (no pixel collisions)
Represent shuriken progress in discrete steps:
- State: (laneIndex, rowIndex, phaseWithinRow)
- Interactions only occur when entering a row boundary that is marked:
  - gateRow
  - operatorRow
  - bankRow

### Global ordering rule (must be consistent)
At a row boundary:
1) Apply gate effect (block/toggle/paint) if present at this row+lane.
2) Apply operator effect if an operator exists at this row’s boundary slot relevant to current lane.
3) Update lane + rowIndex.

Paint must be applied before bank validation.

### Gate transitions
- Toggle gates change allowed color based on **global spawn index**, not wall-clock time.
  - Default: change allowed color every 2 spawns (global counter).
  - Telegraphed in UI: small indicator showing current allowed color.

---

## 4) Spawn + Pacing (not DDR continuous)
### Wave model
- 6 waves per level; wave size = 4.
- Inter-shuriken spacing = 0.6s.
- Breath window between waves = 1.2s (player planning window).
- Show NEXT strip: next 8 shuriken colors.

Rationale: planning windows preserve “attribution” and reduce twitch. Continuous DDR-style spawn is disallowed.

---

## 5) Player Controls (MECE, v1)
### Primary action: place operator
- Player swipes anywhere inside lane grid.
- System finds nearest snapped target:
  1) nearest row (R1..R12) via y
  2) nearest boundary slot (A/B/C) via x
- Show ghost preview while finger is down + drag.
- On release: commit operator.
- If cap (3) reached: show red ghost + haptic error; do not place.

### Secondary action: Undo
- Undo button removes most recently placed operator (if still present).
- Undo does not refund already-consumed charges on older operators (simple, predictable).

No other gestures in v1. No “move ninja” mechanic (ninja is cosmetic only).

---

## 6) Core Loop Rules
### Banking
- A shuriken is “banked” when it enters the bank zone at bottom (bankRow) AND its current color matches the bank color for that lane.
- Banking increments per-level progress counter immediately and triggers micro-reward VFX/SFX.

### Deflect operator behavior (v1)
- Operator is placed on a boundary slot between two lanes at a specific row.
- When a shuriken enters that row boundary and intersects that boundary slot:
  - It shifts one lane across that boundary (left or right depending on which boundary slot it’s on).
  - Charges decrement.
- If shifting would move out of bounds (e.g., lane 1 left): clamp (no move) and still consume charge OR mark invalid placement. Choose one:
  - v1: invalid placement is prevented by not offering ghost on out-of-bounds.

### Gates behavior
- Color Gate: if shuriken color != allowedColor => shuriken becomes JAMMED at that lane/row and stops moving.
- Toggle Gate: same as Color Gate, but allowedColor cycles per global spawn count.
- Paint Gate: shuriken color transforms and continues.

### Jam and overflow
- Jammed shuriken increments jamCount for that lane.
- If jamCount >= 3 => fail (Overflow).
- Jammed shuriken remains as a blocker until run ends (v1).

---

## 7) Level Data Format (authorable and deterministic)
Use JSON per level:
- id, seed (optional), waves: array of wave objects
- Each wave: list of 4 shuriken entries with initial lane + color
- Gates: array with (type, lane, row, params)
  - ColorGate: allowedColor
  - ToggleGate: colorCycle array + cycleEveryNSpawns
  - PaintGate: fromColor -> toColor
- Par thresholds: stars operator count thresholds

Level generation v1:
- Hand-author first 30 levels.
- After that, optionally template-generate with constraints.

---

## 8) FTUE (Tutorial) — exact steps (v1)
### Level 1: “Banking”
- No gates needed. Shuriken already aligned to correct banks.
- Teach: “Match color to bank.” (text overlay)
- Player can do nothing and still win in <10s.
- End card shows: “Slashes reroute. Banking is the goal.”

### Level 2: “Place one slash”
- Add one Color Gate in lane 2 that blocks Red.
- Spawn includes a Red that would jam lane 2 unless rerouted.
- Teach swipe placement + ghost preview.
- Require 1 operator placement to win.

### Level 3: “Charges”
- Similar to Level 2 but 4 mismatched shuriken appear; K=3 means player must place 2 operators.
- Teach charges pips on operator.

### Level 4: “Paint gate”
- Add a Paint Gate converting one color.
- Teach: “Color can change before banking.”

### Level 5: “Overflow”
- Introduce jam threshold: 3 jam fails.
- Intentionally set up a fail if player ignores rerouting; fail screen must show “Overflow margin: 1” on near-miss.

FTUE rule: no ads, no shop prompts, no remove-ads prompts until after level 10.

---

## 9) In-Game HUD + UX (match mockup style, but functional)
Gameplay screen components:
- Top:
  - Title plate (baked logo image)
  - Spawn strip (NEXT 8 icons) with empty slots
  - Optional timer badge exists but shows “Par” context in v1 (not hard countdown)
- Middle:
  - 4 lanes with rails and subtle operator slot hints
  - Gates visible, with allowed-color indicator
  - Shuriken moving down
- Bottom:
  - Bank tray with 4 colored banks
  - Progress counter: e.g., “6/24”
  - Stars indicator (par)
  - Undo button + Settings button (small)

Affordance rules:
- Ghost operator preview is always high-contrast.
- Snap highlight animates and haptics confirm commit.
- Fail/win overlays appear on top of the SpriteKit scene (no scene transitions).

---

## 10) Post-Win / Post-Fail Experience (monetization + retention topology)
### Win Screen (post-win momentum)
- Shows:
  - “CLEAR” banner + micro-confetti
  - Stars earned + “Missed 3-star by 1 operator” messaging if applicable
  - Campaign progress bar (Level X/Y)
  - CTA: Next
- Optional deterministic “pre-boost choice” only on first-try wins (no RNG):
  - Choose 1: “+1 operator cap for next level” OR “1 free undo for next level”
  - This is momentum reinforcement; does not change core determinism.

Interstitial policy:
- Interstitial only after win, every 3 wins (counter), and never in FTUE.

### Fail Screen (post-fail frustration)
- Must show:
  - Fail reason (Overflow or Misbank)
  - Near-miss stat:
    - Overflow: overflowMargin (how many jams away)
    - Misbank: remainingToBank
  - CTA: Retry (instant)
  - CTA: Fix It (rewarded) — salvage-only & capped

Fix It offers (cause-specific):
- Overflow => “Clear 1 jam” (removes one jammed shuriken in the most recent jam lane)
- Misbank => “Undo last operator”

Salvage-only thresholds:
- show Fix It only if remainingToBank <= 3 OR overflowMargin == 1
Caps:
- 1 Fix It per attempt
- 3 Fix It per session

No interstitial after fail until after level 10, then every 2 fails (counter) but suppressed if Fix It is shown.

---

## 11) App Shell (outside core) — exciting but MECE
### Navigation: 3 tabs
1) Play (Home Hub)
2) Daily
3) Shop
Settings accessed from Play via gear.

### Play (Home Hub)
Goal: zero thinking; one primary action.
- Primary CTA: Play Next
- Cards:
  - Daily Kata (progress + streak)
  - Dojo Belt progress (XP bar)
  - Cosmetics collection progress (if enabled)
- Show “Continue intent” drivers: progress numbers always visible (goal-gradient).

### Daily
- Daily Kata Pack: 3 levels, fixed seed, streak badge.
- Daily Quests: 3 tasks (simple, measurable) rewarded with Technique Tokens.
  - Examples:
    - “Bank 30 shuriken”
    - “Win 3 levels with ≤ 6 operators”
    - “Win 2 levels without misbank”
- Completing Daily Pack grants 1 Token.

### Shop
MECE separation:
- Relief: Remove Ads (non-consumable)
- Value: Starter Pack (Remove Ads + cosmetics currency)
- Cosmetics bundles: dojo themes, blade trails, shuriken skins

### Settings
- Sound, Music, Haptics toggles
- Accessibility: reduce motion, high contrast ghost preview
- Restore purchases
- Privacy note

---

## 12) Economy + Progression (v1)
### Currencies
- Coins: earned per level (small); used only for cosmetic unlocks in v1 (avoid pay-to-win)
- Technique Tokens: earned from Daily Pack + quests + milestones; spent on cosmetics

### Progression
- Campaign levels: 1..100 placeholder; ship first 30 authored.
- Dojo Belt XP: +XP per win; belt is cosmetic/status only.

No lootboxes in v1. Add in v1.1 if implementing duplicate protection and rarity tables.

---

## 13) Monetization (v1)
### Ads
- Interstitial:
  - after win: every 3 wins (post level 10)
  - after fail: every 2 fails (post level 10), suppressed if Fix It shown
- Rewarded:
  - Fix It offers only (salvage-only)
No in-run ads.

### IAP (StoreKit 2)
- remove_ads (non-consumable)
- starter_pack (non-consumable): remove_ads + 200 coins + 5 tokens + exclusive skin
- cosmetic_theme_pack_01 (non-consumable)
- cosmetic_trail_pack_01 (non-consumable)

---

## 14) Telemetry Events (v1 minimal, sufficient for tuning)
Emit these events with timestamp + context (levelId, attemptId, sessionId):
- app_open
- hub_viewed
- play_next_clicked
- daily_pack_started, daily_pack_completed, streak_updated
- quest_completed(questId)
- level_start(levelId, attemptId)
- operator_previewed(row, slot)
- operator_placed(row, slot, charges=3, activeCount)
- operator_triggered(row, slot, shurikenId, remainingCharges)
- gate_triggered(type, lane, row, result=pass|jam|paint)
- shuriken_banked(shurikenId, bankColor)
- level_win(levelId, usedOperators, stars)
- level_fail(levelId, reason, remainingToBank, overflowMargin, usedOperators)
- fixit_offer_shown(reason)
- fixit_offer_accepted(type=rewarded)
- ad_impression(format, placement, policyVersion)
- purchase(sku)
- remove_ads_enabled(true|false)

---

## 15) Assets Required (must match premium mockup look)
### General format
- PNG-24 with alpha, exported @3x, @2x, @1x.
- Group into two atlases: Gameplay.atlas, Shell.atlas.
- Panels that scale must be 9-slice (.9.png).

### Gameplay.atlas (core scene)
Background + frame:
- bg/dojo_backplate.png
- frame/top_header_plate.9.png
- frame/bottom_tray_plate.9.png
- frame/side_pillars_left.png, frame/side_pillars_right.png
- frame/lane_rail.png (tileable)

Title:
- ui/title_logo.png
- ui/subtitle_plate.png
- ui/title_shimmer_0001..0030.png (optional)

HUD:
- hud/spawn_strip_plate.9.png
- hud/spawn_slot_empty.png
- hud/timer_badge_plate.png
- hud/counter_badge.9.png
- hud/stars_empty.png, stars_1.png, stars_2.png, stars_3.png

Operators:
- lane/operator_slot_hint.png
- lane/operator_ghost.png
- lane/operator_active.png
- lane/operator_charges_pip.png
- lane/snap_highlight.png

Gates:
- gate/gate_housing.9.png
- gate/gate_core.png (+ tint at runtime) OR per-color overlays
- gate/toggle_tick.png
- gate/paint_drop.png
- gate/state_open.png, gate/state_closed.png

Shuriken:
- shuriken/body_red.png, body_green.png, body_yellow.png, body_blue.png
- shuriken/icon_red.png, icon_green.png, icon_yellow.png, icon_blue.png (spawn strip)

Banks:
- bank/bank_tray_plate.9.png
- bank/bank_slot_red.png, bank_slot_green.png, bank_slot_yellow.png, bank_slot_blue.png
- bank/bank_glow.png

Buttons:
- btn/round_gold_base.png
- btn/round_gold_pressed.png
- btn/icon_undo.png
- btn/icon_settings.png

Overlays:
- overlay/modal_plate.9.png
- overlay/banner_clear.png
- overlay/banner_fail.png
- overlay/button_primary.9.png
- overlay/button_secondary.9.png

VFX:
- vfx/slash_trail.png
- vfx/spark_hit_0001..0012.png OR spark_hit.emitter
- vfx/confetti.emitter (win)

Audio (separate bundle):
- sfx/slash_place.wav
- sfx/slash_trigger.wav
- sfx/gate_block.wav
- sfx/paint_convert.wav
- sfx/bank_tick.wav
- sfx/coin_tick.wav
- sfx/win_sting.wav
- sfx/fail_thud.wav
- sfx/button_tap.wav

### Shell.atlas (SwiftUI screens)
- app/app_bg.png
- app/top_nav_plate.9.png
- app/card_plate.9.png
- app/button_cta.9.png
- app/tab_play.png, tab_daily.png, tab_shop.png

Home:
- home/card_play_next.9.png
- home/card_daily_kata.9.png
- home/card_belt_progress.9.png
- home/progress_bar_fill.png, progress_bar_track.png

Daily:
- daily/daily_pack_header.9.png
- daily/streak_badge.png
- daily/quest_row.9.png
- daily/reward_token_icon.png

Shop:
- shop/product_card.9.png
- shop/remove_ads_badge.png
- shop/starter_pack_badge.png
- shop/price_pill.9.png

Settings:
- settings/row_plate.9.png
- settings/icon_sound.png, icon_haptics.png, icon_privacy.png

---

## 16) Animation + VFX Requirements (premium feel)
- Ghost preview shimmer while finger is down.
- Snap highlight pulse on valid slot.
- Placement confirmation: subtle camera nudge + haptic + slash glow.
- Trigger hit: spark burst + SFX.
- Banking: glow flash on bank + counter pop + coin tick.
- Win: confetti burst, clear banner.
- Fail: screen flash + fail thud; show near-miss numbers.

All VFX must be triggered from discrete row events (deterministic).

---

## 17) Acceptance Tests (must pass to ship v1)
### Determinism
- Same seed + same recorded input sequence => identical end state (hash compare).
- Gate toggles do not drift with framerate.

### Controls
- No gesture misclassification exists because only one gesture exists.
- Placement always snaps; ghost preview matches committed position.

### UX
- FTUE levels 1–5 completable and teach each concept in isolation.
- Fail screen always shows near-miss stat.
- “Fix It” appears only when salvage thresholds are met and respects caps.

### Monetization
- No ads in FTUE.
- No ads mid-run.
- Interstitial counters match policy.
- Remove Ads disables interstitials but not rewarded Fix It (rewarded remains optional).

### iPad
- Layout scales with 9-slice panels; lane grid remains readable; snap targets remain forgiving.

---

## 18) Build Plan (execution order)
1) Create SwiftUI shell with 3 tabs and placeholder screens.
2) Create SpriteKit scene with static background + lane rails + HUD chrome.
3) Implement deterministic sim core (row-based), spawn waves, shuriken movement.
4) Implement Deflect operator placement (snap grid + ghost preview + cap).
5) Implement banking + misbank fail.
6) Implement Color Gate + jam + overflow fail.
7) Implement Toggle Gate (spawn-index-based).
8) Implement Paint Gate.
9) Implement FTUE levels 1–5 and tutorial overlays.
10) Implement win/fail overlays + star rating.
11) Implement Daily Pack + streak + quests (local).
12) Implement Shop (StoreKit 2) + Remove Ads.
13) Implement Ads policies (AdMob) with counters.
14) Implement telemetry logger.
15) Replace placeholder art with final atlases; tune VFX and haptics.

---

## 19) Scope locks (avoid regressions)
Not in v1:
- Sliding gates, elevators, one-way arrows
- Continuous DDR spawn
- Multiple gestures for different actions
- Lootboxes / rarity tables
- Mid-run ads
- Competitive leaderboards

v1.1 candidates:
- Sliding gates as a new obstacle family
- Cosmetic lootboxes with duplicate protection
- Additional operator stances (Switch, Brake) via stance button (still one swipe verb)