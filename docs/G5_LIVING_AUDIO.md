# G5 Sound — functional but deliberately modest ambience layer

This iteration adds an entirely offline, original synthesized ambient layer. The daytime sound blends soft river wash with an intermittent synthetic birdlike call; nighttime uses a lower river layer and periodic high insectlike hum. There are no third-party media assets, borrowed tracks, sacred music or required network connections.

- Day/night crossfade happens gradually when the player changes time.
- Options menu has OFF / QUIET / NORMAL. QUIET is default. The preference is persisted separately from the canonical story and compatible with older settings.
- All evidence and puzzle clues continue to be visual; no sound is necessary for progress.
- WAV generation creates short deterministic mono 16-bit loops once per session; the low sample rate reduces mobile CPU and asset footprint. The sound works without an external media download.
- Headless tests verify deterministic buffers, looping, non-silent samples, distinct day/night audio and mute choice.

**Not final audio signoff:** these are synthetic placeholders, not authentic field recordings, voice performances, finished cinematic score or physically accurate positional Foley. Phone speaker quality, clipping and mute must still be verified by actual Android playtest.
