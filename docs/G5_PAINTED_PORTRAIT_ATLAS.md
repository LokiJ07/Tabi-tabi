# G5 NPC painted portrait atlas

Added a committed offline portrait texture at `assets/portraits/night01_painted_sheet.png` (1024×1024 PNG, SHA256 verified before import). The four original head-and-shoulders designs are arranged as a 2×2 atlas: Lola top left, Tatay Dado top right, Teacher Mara bottom left, and Aling Sabel bottom right.

`SpeakerPortrait` now renders the relevant atlas quadrant in the conversation overlay and preserves the existing original vector portraits for Apprentice, Bantay, Santelmo and narrator. This is a real in-game texture in the repository and exported APK, not a network request during play; all assets work fully offline.

Artwork is a painterly concept-quality portrait sheet. The original generation was downsampled through an external media-transfer thumbnail and resampled before repository import, so the embedded texture is not final uncompressed master illustration quality. No final rigged 3D character model or facial performance is implied. The NPC 3D silhouettes have matching clothes/headwear palettes; the two visual representations are not the same fully rigged mesh.

Mandatory remaining gate: review actual Android rendered portrait and perform physical-thumb dialogue tests on a new install, including all four witnesses and multi-speaker conversations.
