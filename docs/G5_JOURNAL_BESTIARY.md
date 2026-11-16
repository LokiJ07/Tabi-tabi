# Night 1 canon-safe notebook and bestiary iteration

The Night 1 investigation now displays a categorized field journal with distinct source-confidence labels:

- Dado eyewitness testimony remains **suspected**, not proof of supernatural identity.
- The old mooring is an observable physical location.
- Mara's ledger corroborates Mang Celso's boatman name and historical connection only. It does not establish that he became the spirit, reveal Sabel's husband's identity, or establish who acted in the great flood.
- Private theories remain explicitly revisable, without penalties.
- The Santelmo encounter records **exactly one** Bestiary observation upon committed result; it persists through saves and never duplicates after a reload.
- Story-result record is source-aware and avoids unsupported identity assertions.

Mobile UI fix: dialogue has a scroll container and all modal open/close actions reset held touch controls. Movement suppression runs *after* keyboard and touch axes have been combined; it therefore also blocks late touches while a dialogue remains open.

Headless tests verify the journal, incomplete evidence, result exclusivity, bestiary uniqueness, save persistence, and touch control gating. Audio and all relevant earlier regressions remain.
