3.1 (2019-10-19)
---

Improvements:

- Added support for key up events in Shortcut Monitors
- Style can now customize no-value labels and tooltips
- Reviewed and fixed translations to match modern Apple vocabulary
- New and shorter label for the control when there is no value
- New tooltip for the clean button
- New tooltip for the cancel button when there no value: "use old shortcut" does not make sense if there is no old shortcut

Fixes:

- Fix various errors and edge cases in Shortcut Monitors
- Fix undefined behavior warning due to a missing `nullable` in the `-[SRRecorderControl propagateValue:forKey:] definition
- Fix incorrect intrinsic width of the control (was visible only after certain style customizations)
