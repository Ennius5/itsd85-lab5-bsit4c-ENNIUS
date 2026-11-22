# Parkin' Space – Phone Test Matrix (Phase 7)

The handout's checklist, run on two different phones with the build being submitted.

**Build tested:** `ParkinSpace-playtest-2026-11-16.apk` (debug-signed, `main` at `b698f7b`)
**How to fill:** write **Pass**, **Fail** (with a note), or **–** (not tested yet), plus the date.

| Test | Phone 1: Huawei LYA-L29 (Mate 20 Pro), Android 10 | Phone 2: Oppo A57 (2022), MediaTek Dimensity 810, 6 GB RAM, 6.56" IPS LCD |
|---|---|---|
| App installs and opens | Pass (2026-11-16, tutorial build installed with `adb install -r` and played) | Pass – installs and opens, tutorial build works |
| Layout fits the screen, nothing cut off (notch side too) | Pass – layout fits the screen | Pass – layout fits the screen |
| Touch controls respond correctly (tap ship, driving pad, Done, multi-touch) | Pass | Pass |
| Progress saved after force-close (clear Level 1 → swipe the app away → reopen → Level 2 still unlocked) | Pass – progress kept | Pass – progress kept |
| Offline mode in airplane mode (Tutorial + Level 1 with airplane mode on) | Pass | Pass |
| Online match between the two phones (same Wi-Fi, host + join, play to the result screen on both) | Pass – as host and as joiner | Pass – as host and as joiner |
| Online error with Wi-Fi off (Join shows "Cannot reach host", no crash) | Pass – no crash when hosting or joining | Pass – no crash when hosting or joining |
| Frame rate smooth (no visible stutter while driving and in the lot view) | Pass – smooth | Pass – smooth |
| Battery/heat acceptable after 10 minutes (note battery % before/after) | Pass – battery OK before and after, minimal heat | Pass – battery OK before and after, minimal heat |

## Notes
- All 9 checks passed on both phones. No problems found, so no fixes were needed.
