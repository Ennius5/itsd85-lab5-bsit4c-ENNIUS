# Parkin' Space – Phone Test Matrix (Phase 7)

The handout's checklist, run on two different phones with the build being submitted.

**Build tested:** `ParkinSpace-playtest-2026-11-16.apk` (debug-signed, `main` at `b698f7b`)
**How to fill:** write **Pass**, **Fail** (with a note), or **–** (not tested yet), plus the date.

| Test | Phone 1: Huawei LYA-L29 (Mate 20 Pro), Android 10 | Phone 2: _model, Android version, screen_ |
|---|---|---|
| App installs and opens | Pass (2026-11-16, tutorial build installed with `adb install -r` and played) | |
| Layout fits the screen, nothing cut off (notch side too) | | |
| Touch controls respond correctly (tap ship, driving pad, Done, multi-touch) | | |
| Progress saved after force-close (clear Level 1 → swipe the app away → reopen → Level 2 still unlocked) | | |
| Offline mode in airplane mode (Tutorial + Level 1 with airplane mode on) | | |
| Online match between the two phones (same Wi-Fi, host + join, play to the result screen on both) | | |
| Online error with Wi-Fi off (Join shows "Cannot reach host", no crash) | | |
| Frame rate smooth (no visible stutter while driving and in the lot view) | | |
| Battery/heat acceptable after 10 minutes (note battery % before/after) | | |

## Notes
- _Problems found and the fix or commit._
