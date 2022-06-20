enum AdViewPosition {
  topCenter("top_center"),
  topRight("top_right"),
  centered("centered"),
  centerLeft("center_left"),
  centerRight("center_right"),
  bottomLeft("bottom_left"),
  bottomCenter("bottom_center"),
  bottomRight("bottom_right");

  final String value;

  const AdViewPosition(this.value);
}

///
/// This enum represents whether or not the consent dialog should be shown for this user.
/// The state where no such determination could be made is represented by {@code ConsentDialogState.ConsentDialogState.ConsentDialogStateUnknown}.
///
enum ConsentDialogState {
  ///
  /// The consent dialog state could not be determined. This is likely due to the SDK failing to initialize.
  ///
  unknown(0),

  ///
  /// This user should be shown a consent dialog.
  ///
  applies(1),

  ///
  /// This user should not be shown a consent dialog.
  ///
  doesNotApply(2);

  final int value;

  const ConsentDialogState(this.value);
}
