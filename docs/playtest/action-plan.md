# Parkin' Space – Playtest Action Plan (Step 8.5)

Fill after the first round (T1–T5+). Fix the highest-severity, most-mentioned issues first (at least 3), then retest with at least 2 new testers and record the result.

Severity: **Critical** = crash, lost progress, cannot finish a level · **Major** = confusing goal, unfair difficulty, online fails often · **Minor** = cosmetic, typos, small sound issues.

| # | Issue found | Testers who reported it (of N) | Severity | Planned fix | Fixed? (commit) | Result after retest |
|---|---|---|---|---|---|---|
| 1 | No warning before a ship hits the lot walls | Developer playtest (2026-11-03), before the tester round | Major | Red lot-edge outline that glows when the driven ship nears a wall | Yes (`feature/playtest-fixes`) | _retest_ |
| 2 | Players think the game is stuck while parked ships wait to be asked for, and quit | Developer playtest (2026-11-03) | Major | Countdown on each parked leaver + HUD "Waiting for customers to return – next in 0:12" | Yes (`feature/playtest-fixes`) | _retest_ |
| 3 | Players hold the thrust buttons and overshoot | Developer playtest (2026-11-03) | Minor | Yellow tip on the How to Play Controls page: tap, don't hold | Yes (`feature/playtest-fixes`) | _retest_ |
| 4 | Playtesters got stuck on the controls and skipped the How to Play guide | _count of N_ (outside playtesters, 2026-11) | Major | A 12-step Tutorial lot that can't be failed, opened automatically on the first Offline tap. Each step is shown by a sign, the goal line, and a pulsing ring with an arrow on what to tap. Plus a pulsing ARRIVALS bay while a ship waits | Yes (merge `b698f7b`, 2026-11-16) | _retest: did new testers park Level 1's first ship without help?_ |
| 5 | Hard to judge when a ship is going fast enough to dent | Developer playtest (2026-11-16) | Minor | Speed glow: a thin screen-edge band while a ship is selected, green → yellow at 120 px/s (dents start) → red at 600 px/s, counting spin | Yes (merge `b698f7b`) | _retest_ |
| 6 | | | | | | |
