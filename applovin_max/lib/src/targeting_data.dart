import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/services.dart';

/// Allows you to provide user or app data that will improve how we target ads.
class TargetingData {
  /// @nodoc
  final MethodChannel _channel;

  /// @nodoc
  TargetingData(this._channel);

  /// The year of birth of the user.
  ///
  /// Set this property to zero or a less than zero to clear this value.
  ///
  set yearOfBirth(int value) {
    _channel.invokeMethod('setTargetingDataYearOfBirth', {
      'value': value,
    });
  }

  /// The gender of the user.
  ///
  /// Set this property to [UserGender.unknown] to clear this value.
  ///
  set gender(UserGender value) {
    if (value == UserGender.unknown ||
        value == UserGender.female ||
        value == UserGender.male ||
        value == UserGender.other) {
      _channel.invokeMethod('setTargetingDataGender', {
        'value': value.value,
      });
    }
  }

  /// The maximum ad content rating shown to the user.
  ///
  /// Set this property to [AdContentRating.none] to clear this value.
  ///
  set maximumAdContentRating(AdContentRating value) {
    if (value == AdContentRating.none ||
        value == AdContentRating.allAudiences ||
        value == AdContentRating.everyoneOverTwelve ||
        value == AdContentRating.matureAudiences) {
      _channel.invokeMethod('setTargetingDataMaximumAdContentRating', {
        'value': value.value,
      });
    }
  }

  /// The email of the user.
  ///
  /// Set this property to null to clear this value.
  ///
  set email(String? value) {
    _channel.invokeMethod('setTargetingDataEmail', {
      'value': value,
    });
  }

  /// The phone number of the user. Do not include the country calling code.
  ///
  /// Set this property to null to clear this value.
  ///
  set phoneNumber(String? value) {
    _channel.invokeMethod('setTargetingDataPhoneNumber', {
      'value': value,
    });
  }

  /// The keywords describing the application.
  ///
  /// Set this property to null to clear this value.
  ///
  set keywords(List<String>? value) {
    _channel.invokeMethod('setTargetingDataKeywords', {
      'value': value,
    });
  }

  /// The interests of the user.
  ///
  /// Set this property to null to clear this value.
  ///
  set interests(List<String>? value) {
    _channel.invokeMethod('setTargetingDataInterests', {
      'value': value,
    });
  }

  /// Clear all saved data from this class.
  void clearAll() {
    _channel.invokeMethod('clearAllTargetingData');
  }
}
