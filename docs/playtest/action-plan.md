# Parkin' Space – Playtest Action Plan (Step 8.5)

**Round 1:** 10 testers (T1–T10) filled in the feedback form. T1 and T2 were observed in full (think-aloud, Levels 1–5 plus an online duel).
**Retest:** after the fixes, on the tutorial build, with T3 and T4 observed. No new testers were available, so these were returning testers. The paper reports this as a limitation.
Raw data: [data/feedback.csv](data/feedback.csv), [data/observations.csv](data/observations.csv).

Severity: **Critical** = crash, lost progress, cannot finish a level · **Major** = confusing goal, unfair difficulty, online fails often · **Minor** = cosmetic, typos, small sound issues.

## Round 1 summary
- **Likert (n = 10):** all items M = 4.27. Problem areas (M < 3.5): **q5** "unlocking made me want to keep playing" M = 3.00, and **q2** "understood the goal without help" M = 3.40 (SD 0.84). Six items scored 5.00: offline, joining online, graphics, sound, readability and stability.
- **Overall stars:** 4.1 / 5 (SD 0.74).
- **Themes:**
  - controls were the most frustrating part for **10/10**;
  - Level 3 (5) or Level 4 (5) was named too hard;
  - no bugs reported (0/10);
  - liked most: graphics or mood (6), gameplay or concept (4);
  - wanted: racing mode (4), mining asteroids (2), more or bigger levels (2), bumper-cars mode (1), shooting (1).
- **Observed:** completion was 100% on all levels. Mean attempts: L1 3.5 · L2 5 · L3 7.5 · L4 12.5 · L5 7. T1 needed help on L1–L4 (controls, and discovering that *holding* STOP gives full control).

## Fixes

| # | Issue found | Testers who reported it | Severity | Fix | Fixed? (commit) | Result after retest (T3, T4) |
|---|---|---|---|---|---|---|
| 1 | Playtesters got stuck on the controls and skipped the How to Play guide | 10/10 (form); T1 and T2 observed | Major | A 12-step Tutorial lot that can't be failed, opened automatically on the first Offline tap. Each step is shown by a sign, the goal line, and a pulsing ring with an arrow on what to tap. Plus a pulsing ARRIVALS bay while a ship waits | Yes (merge `b698f7b`, 2026-11-16) | **Solved.** Both finished the tutorial on the first try (4:00, 3:30) and then read the guide on their own. They needed no help and were never stuck. Mean attempts per level fell from 7.1 to 3.3 (L4: 12.5 → 5) |
| 2 | No warning before a ship hits the lot walls | Developer playtest (2026-11-03) | Major | Red lot-edge outline that glows when the driven ship nears a wall | Yes (`feature/playtest-fixes`) | No issue seen |
| 3 | Players think the game is stuck while parked ships wait to be asked for, and quit | Developer playtest (2026-11-03) | Major | Countdown on each parked leaver + HUD "Waiting for customers to return – next in 0:12" | Yes (`feature/playtest-fixes`) | No issue seen |
| 4 | Players hold the thrust buttons and overshoot | Developer playtest (2026-11-03) | Minor | Yellow tip on the How to Play Controls page: tap, don't hold | Yes (`feature/playtest-fixes`) | No issue seen |
| 5 | Hard to judge when a ship is going fast enough to dent (T1 kept hitting L5 pillars at speed) | Developer playtest (2026-11-16), T1 | Minor | Speed glow: a thin screen-edge band while a ship is selected, green → yellow at 120 px/s (dents start) → red at 600 px/s, counting spin | Yes (merge `b698f7b`) | No issue seen |
| 6 | Level 5: a customer asks for a space that is already occupied; tester didn't know parked ships can be moved | T1 (T2 found it in the guide) | Minor | Not changed; already explained in the guide | No | Did not recur |

## Open items (future work)
- q5 (unlocking motivation, M = 3.00) wasn't addressed. Ideas: a visible reward per unlock (a new ship), and a smoother step into Level 4.
- q2 and q5 were not re-measured, because the retest testers did not fill in a second form.
- Most-requested feature: a competitive racing or bumper-cars mode. Both online duels turned into bumper cars on their own.
