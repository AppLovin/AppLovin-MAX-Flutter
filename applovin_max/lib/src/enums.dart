import 'package:flutter/foundation.dart';

/// Represents an ad format.
enum AdFormat {
  /// Banner ad format.
  banner("banner"),

  /// MREC ad format.
  mrec("mrec");

  /// @nodoc
  final String value;
  const AdFormat(this.value);
}

/// Represents an AdView ad position.
enum AdViewPosition {
  /// Top center of the screen.
  topCenter("top_center"),

  /// Top right of the screen.
  topRight("top_right"),

  /// Center of the screen.
  centered("centered"),

  /// Center left of the screen.
  centerLeft("center_left"),

  /// Center right of the screen.
  centerRight("center_right"),

  /// Bottom left of the screen.
  bottomLeft("bottom_left"),

  /// Bottom center of the screen.
  bottomCenter("bottom_center"),

  /// Bottom right of the screen.
  bottomRight("bottom_right");

  /// @nodoc
  final String value;
  const AdViewPosition(this.value);
}

/// Represents content ratings for ads shown to users.
///
/// Corresponds to IQG media content ratings.
enum AdContentRating {
  /// No content rating.
  none(0),

  /// Suitable for all audiences.
  allAudiences(1),

  /// Suitable for users aged 12 and above.
  everyoneOverTwelve(2),

  /// Suitable for mature audiences only.
  matureAudiences(3);

  /// @nodoc
  final int value;
  const AdContentRating(this.value);
}

/// User's gender for ad targeting.
enum UserGender {
  /// Unknown gender.
  unknown('U'),

  /// Female.
  female('F'),

  /// Male.
  male('M'),

  /// Other or non-binary.
  other('O');

  /// @nodoc
  final String value;
  const UserGender(this.value);
}

/// User's geography for determining consent flow.
enum ConsentFlowUserGeography {
  /// User's geography is unknown.
  unknown('U'),

  /// Located in a GDPR-regulated region.
  gdpr('G'),

  /// Located in a non-GDPR region.
  other('O');

  /// @nodoc
  final String value;
  const ConsentFlowUserGeography(this.value);
}

/// App tracking transparency status (iOS only).
enum AppTrackingStatus {
  /// Unavailable (iOS < 14).
  unavailable('U'),

  /// User has not responded to the tracking prompt.
  notDetermined('N'),

  /// Tracking is restricted by system settings.
  restricted('R'),

  /// User denied tracking permission.
  denied('D'),

  /// User granted tracking permission.
  authorized('A');

  /// @nodoc
  final String value;
  const AppTrackingStatus(this.value);
}

/// Error codes for CMP flow.
enum CMPErrorCode {
  /// Unspecified error.
  unspecified(-1),

  /// CMP not integrated correctly.
  integrationError(1),

  /// CMP form is unavailable.
  formUnavailable(2),

  /// CMP form is not required.
  formNotRequired(3);

  /// @nodoc
  final int value;
  const CMPErrorCode(this.value);
}

/// Load state of an ad in the waterfall.
enum AdLoadState {
  /// SDK did not attempt to load this ad (a prior ad already loaded).
  adLoadNotAttempted,

  /// Ad loaded successfully.
  adLoaded,

  /// Ad failed to load.
  adFailedToLoad;
}

/// SDK error codes for load/display failures.
enum ErrorCode {
  /// Fallback error when no specific category applies. See [message] for details.
  unspecified(-1),

  /// No eligible ads returned from mediated networks.
  noFill(204),

  /// Eligible ads found, but all failed to load.
  adLoadFailed(-5001),

  /// Error occurred while displaying the ad.
  adDisplayFailed(-4205),

  /// Network error during ad request.
  networkError(-1000),

  /// Network timeout during ad request.
  networkTimeout(-1001),

  /// Device is offline.
  noNetwork(-1009),

  /// Fullscreen ad is already showing.
  fullscreenAdAlreadyShowing(-23),

  /// Fullscreen ad was not loaded before showing.
  fullscreenAdNotReady(-24),

  /// Invalid view controller used for fullscreen ad (iOS only).
  fullscreenAdInvalidViewController(-25),

  /// "Don't Keep Activities" is enabled (Android only).
  dontKeepActivitiesEnabled(-5602),

  /// Invalid ad unit ID.
  ///
  /// Possible reasons:
  /// - Malformed or non-existent ad unit ID.
  /// - Disabled ad unit.
  /// - Package name mismatch.
  /// - Created recently (within the last 30-60 minutes).
  invalidAdUnitId(-5603);

  /// @nodoc
  final int value;
  const ErrorCode(this.value);

  /// Returns the matching [ErrorCode] for a given integer value.
  ///
  /// Returns [ErrorCode.unspecified] if no match is found.
  static ErrorCode fromValue(int value) {
    try {
      return ErrorCode.values.firstWhere((e) => e.value == value);
    } catch (e) {
      debugPrint('Unknown error code: $value');
      return ErrorCode.unspecified;
    }
  }
}
