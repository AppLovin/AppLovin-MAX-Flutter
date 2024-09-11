import 'package:flutter/foundation.dart';

/// Represents an ad format.
enum AdFormat {
  /// The banner ad.
  banner("banner"),

  /// The MREC ad.
  mrec("mrec");

  /// @nodoc
  final String value;

  /// @nodoc
  const AdFormat(this.value);
}

/// Represents an AdView ad position.
enum AdViewPosition {
  topCenter("top_center"),
  topRight("top_right"),
  centered("centered"),
  centerLeft("center_left"),
  centerRight("center_right"),
  bottomLeft("bottom_left"),
  bottomCenter("bottom_center"),
  bottomRight("bottom_right");

  /// @nodoc
  final String value;

  /// @nodoc
  const AdViewPosition(this.value);
}

/// Represents content ratings for the ads shown to users.
///
/// These ratings correspond to IQG Media Ratings.
enum AdContentRating {
  none(0),
  allAudiences(1),
  everyoneOverTwelve(2),
  matureAudiences(3);

  /// @nodoc
  final int value;

  /// @nodoc
  const AdContentRating(this.value);
}

/// Represents gender.
enum UserGender {
  unknown('U'),
  female('F'),
  male('M'),
  other('O');

  /// @nodoc
  final String value;

  /// @nodoc
  const UserGender(this.value);
}

/// Represents the user's geography used to determine the type of consent flow
/// shown to the user.
enum ConsentFlowUserGeography {
  /// User's geography is unknown.
  unknown('U'),

  /// The user is in GDPR region.
  gdpr('G'),

  /// The user is in a non-GDPR region.
  other('O');

  /// @nodoc
  final String value;

  /// @nodoc
  const ConsentFlowUserGeography(this.value);
}

/// AppLovin SDK-defined app tracking transparency status values (extended to
/// include "unavailable" state on iOS before iOS14).
enum AppTrackingStatus {
  /// Device is on iOS before iOS14, AppTrackingTransparency.framework is not
  /// available.
  unavailable('U'),

  /// The user has not yet received an authorization request to authorize access
  /// to app-related data that can be used for tracking the user or the device.
  notDetermined('N'),

  /// Authorization to access app-related data that can be used for tracking the
  /// user or the device is restricted.
  restricted('R'),

  /// The user denies authorization to access app-related data that can be used
  /// for tracking the user or the device.
  denied('D'),

  /// The user authorizes access to app-related data that can be used for
  /// tracking the user or the device.
  authorized('A');

  /// @nodoc
  final String value;

  /// @nodoc
  const AppTrackingStatus(this.value);
}

/// Represents errors for CMP flow.
enum CMPErrorCode {
  /// Indicates that an unspecified error has occurred.
  unspecified(-1),

  /// Indicates that the CMP has not been integrated correctly.
  integrationError(1),

  /// Indicates that the CMP form is unavailable.
  formUnavailable(2),

  /// Indicates that the CMP form is not required.
  formNotRequired(3);

  /// @nodoc
  final int value;

  /// @nodoc
  const CMPErrorCode(this.value);
}

/// Represents the load state of an ad in the waterfall.
///
/// This enum contains possible states of an ad in the waterfall the adapter
/// response info could represent.
enum AdLoadState {
  /// The AppLovin MAX SDK did not attempt to load an ad from this network in
  /// the waterfall because an ad higher in the waterfall loaded successfully.
  adLoadNotAttempted,

  /// An ad successfully loaded from this network.
  adLoaded,

  /// An ad failed to load from this network.
  adFailedToLoad;
}

/// This enum contains various error codes that the SDK can return when a MAX ad fails to load or display.
enum ErrorCode {
  /// This error code represents an error that could not be categorized into one of the other defined
  /// errors. See the message field in the error object for more details.
  unspecified(-1),

  /// This error code indicates that MAX returned no eligible ads from any mediated networks for this
  /// app/device.
  noFill(204),

  /// This error code indicates that MAX returned eligible ads from mediated networks, but all ads
  /// failed to load. See the adLoadFailureInfo field in the error object for more details.
  adLoadFailed(-5001),

  /// This error code represents an error that was encountered when showing an ad.
  adDisplayFailed(-4205),

  /// This error code indicates that the ad request failed due to a generic network error. See the
  /// message field in the error object for more details.
  networkError(-1000),

  /// This error code indicates that the ad request timed out due to a slow internet connection.
  networkTimeout(-1001),

  /// This error code indicates that the ad request failed because the device is not connected to the
  /// internet.
  noNetwork(-1009),

  /// This error code indicates that you attempted to show a fullscreen ad while another fullscreen ad
  /// is still showing.
  fullscreenAdAlreadyShowing(-23),

  /// This error code indicates you are attempting to show a fullscreen ad before the one has been
  /// loaded.
  fullscreenAdNotReady(-24),

  /// This error code indicates you attempted to present a fullscreen ad from an invalid view controller.
  ///
  /// Note: iOS only.
  fullscreenAdInvalidViewController(-25),

  /// This error code indicates you are attempting to load a fullscreen ad while another
  /// fullscreen ad is already loading.
  fullscreenAdAlreadyLoading(-26),

  /// This error code indicates you are attempting to load a fullscreen ad while another fullscreen ad
  /// is still showing.
  fullscreenAdLoadWhileShowing(-27),

  /// This error code indicates that the SDK failed to display an ad because the
  /// user has the "Don't Keep Activities" developer setting enabled.
  ///
  /// Note: Android only.
  dontKeepActivitiesEnabled(-5602),

  /// This error code indicates that the SDK failed to load an ad because the publisher provided an
  /// invalid ad unit identifier.
  ///
  /// Possible reasons for an invalid ad unit identifier:
  /// 1. Ad unit identifier is malformed or does not exist.
  /// 2. Ad unit is disabled.
  /// 3. Ad unit is not associated with the current app's package name.
  /// 4. Ad unit was created within the last 30-60 minutes.
  invalidAdUnitId(-5603);

  /// @nodoc
  final int value;

  /// @nodoc
  const ErrorCode(this.value);

  /// Returns the corresponding [ErrorCode] enum for a given integer value.
  ///
  /// If the provided integer value does not match any defined [ErrorCode],
  /// the method returns `null`.
  static ErrorCode fromValue(int value) {
    try {
      return ErrorCode.values.firstWhere((e) => e.value == value);
    } catch (e) {
      debugPrint('Unknown error code: $value');
      return ErrorCode.unspecified;
    }
  }
}
