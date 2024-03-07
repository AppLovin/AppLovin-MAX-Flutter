package com.applovin.applovin_max;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Point;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdListener;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxAdWaterfallInfo;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.MaxErrorCode;
import com.applovin.mediation.MaxMediatedNetworkInfo;
import com.applovin.mediation.MaxNetworkResponseInfo;
import com.applovin.mediation.MaxReward;
import com.applovin.mediation.MaxRewardedAdListener;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.mediation.ads.MaxAppOpenAd;
import com.applovin.mediation.ads.MaxInterstitialAd;
import com.applovin.mediation.ads.MaxRewardedAd;
import com.applovin.sdk.AppLovinAdContentRating;
import com.applovin.sdk.AppLovinCmpError;
import com.applovin.sdk.AppLovinGender;
import com.applovin.sdk.AppLovinMediationProvider;
import com.applovin.sdk.AppLovinPrivacySettings;
import com.applovin.sdk.AppLovinSdk;
import com.applovin.sdk.AppLovinSdkConfiguration;
import com.applovin.sdk.AppLovinSdkConfiguration.ConsentFlowUserGeography;
import com.applovin.sdk.AppLovinSdkSettings;
import com.applovin.sdk.AppLovinSdkUtils;
import com.applovin.sdk.AppLovinUserService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class AppLovinMAX
        implements FlutterPlugin, MethodCallHandler, ActivityAware, MaxAdListener, MaxAdViewAdListener, MaxRewardedAdListener, MaxAdRevenueListener
{
    private static final String SDK_TAG = "AppLovinSdk";
    private static final String TAG     = "AppLovinMAX";

    private static final String USER_GEOGRAPHY_GDPR    = "G";
    private static final String USER_GEOGRAPHY_OTHER   = "O";
    private static final String USER_GEOGRAPHY_UNKNOWN = "U";

    public static AppLovinMAX instance;

    private MethodChannel         sharedChannel;
    private Context               applicationContext;
    private ActivityPluginBinding lastActivityPluginBinding;

    // Parent Fields
    private AppLovinSdk              sdk;
    private boolean                  isPluginInitialized;
    private boolean                  isSdkInitialized;
    private AppLovinSdkConfiguration sdkConfiguration;

    // Store these values if pub attempts to set it before initializing
    private       List<String>        initializationAdUnitIdsToSet;
    private       String              userIdToSet;
    private       Boolean             mutedToSet;
    private       List<String>        testDeviceAdvertisingIdsToSet;
    private       Boolean             verboseLoggingToSet;
    private       Boolean             creativeDebuggerEnabledToSet;
    private       Boolean             locationCollectionEnabledToSet;
    private final Map<String, String> extraParametersToSet = new HashMap<>( 8 );

    private Boolean termsAndPrivacyPolicyFlowEnabledToSet;
    private Uri     privacyPolicyURLToSet;
    private Uri     termsOfServiceURLToSet;
    private String  debugUserGeographyToSet;

    private Integer      targetingYearOfBirthToSet;
    private String       targetingGenderToSet;
    private Integer      targetingMaximumAdContentRatingToSet;
    private String       targetingEmailToSet;
    private String       targetingPhoneNumberToSet;
    private List<String> targetingKeywordsToSet;
    private List<String> targetingInterestsToSet;

    // Fullscreen Ad Fields
    private final Map<String, MaxInterstitialAd> mInterstitials = new HashMap<>( 2 );
    private final Map<String, MaxRewardedAd>     mRewardedAds   = new HashMap<>( 2 );
    private final Map<String, MaxAppOpenAd>      mAppOpenAds    = new HashMap<>( 2 );

    // AdView Fields
    private final Map<String, MaxAdView>   mAdViews                            = new HashMap<>( 2 );
    private final Map<String, MaxAdFormat> mAdViewAdFormats                    = new HashMap<>( 2 );
    private final Map<String, String>      mAdViewPositions                    = new HashMap<>( 2 );
    private final List<String>             mAdUnitIdsToShowAfterCreate         = new ArrayList<>( 2 );
    private final Set<String>              mDisabledAutoRefreshAdViewAdUnitIds = new HashSet<>( 2 );

    public static AppLovinMAX getInstance()
    {
        return instance;
    }

    public AppLovinSdk getSdk()
    {
        return sdk;
    }

    @Override
    public void onAttachedToEngine(@NonNull final FlutterPluginBinding binding)
    {
        // KNOWN ISSUE: onAttachedToEngine will be call twice, which may be caused by using
        // firebase_messaging plugin. See https://github.com/flutter/flutter/issues/97840
        //
        // Workaround is move the code to onAttachedToActivity
        // and onReattachedToActivityForConfigChanges, which will be only called once.
        //
        // instance = this;

        applicationContext = binding.getApplicationContext();

        sharedChannel = new MethodChannel( binding.getBinaryMessenger(), "applovin_max" );
        sharedChannel.setMethodCallHandler( this );

        AppLovinMAXAdViewFactory adViewFactory = new AppLovinMAXAdViewFactory( binding.getBinaryMessenger() );
        binding.getPlatformViewRegistry().registerViewFactory( "applovin_max/adview", adViewFactory );

        AppLovinMAXNativeAdViewFactory nativeAdViewFactory = new AppLovinMAXNativeAdViewFactory( binding.getBinaryMessenger() );
        binding.getPlatformViewRegistry().registerViewFactory( "applovin_max/nativeadview", nativeAdViewFactory );
    }

    @Override
    public void onDetachedFromEngine(@NonNull final FlutterPluginBinding binding)
    {
        sharedChannel.setMethodCallHandler( null );
    }

    private boolean isInitialized()
    {
        return isInitialized( null );
    }

    private boolean isInitialized(@Nullable final Result result)
    {
        boolean isInitialized = isPluginInitialized && isSdkInitialized;

        if ( result != null )
        {
            result.success( isInitialized );
        }

        return isInitialized;
    }

    private void initialize(final String pluginVersion, final String sdkKey, final Result result)
    {
        // Guard against running init logic multiple times
        if ( isPluginInitialized )
        {
            result.success( getInitializationMessage() );
            return;
        }

        isPluginInitialized = true;

        d( "Initializing AppLovin MAX Flutter v" + pluginVersion + "..." );

        // If SDK key passed in is empty, check Android Manifest
        String sdkKeyToUse = sdkKey;
        if ( TextUtils.isEmpty( sdkKey ) )
        {
            try
            {
                PackageManager packageManager = applicationContext.getPackageManager();
                String packageName = applicationContext.getPackageName();
                ApplicationInfo applicationInfo = packageManager.getApplicationInfo( packageName, PackageManager.GET_META_DATA );
                Bundle metaData = applicationInfo.metaData;

                sdkKeyToUse = metaData.getString( "applovin.sdk.key", "" );
            }
            catch ( Throwable th )
            {
                e( "Unable to retrieve SDK key from Android Manifest: " + th );
            }

            if ( TextUtils.isEmpty( sdkKeyToUse ) )
            {
                throw new IllegalStateException( "Unable to initialize AppLovin SDK - no SDK key provided and not found in Android Manifest!" );
            }
        }

        AppLovinSdkSettings settings = new AppLovinSdkSettings( applicationContext );

        // Selective init
        if ( initializationAdUnitIdsToSet != null )
        {
            settings.setInitializationAdUnitIds( initializationAdUnitIdsToSet );
            initializationAdUnitIdsToSet = null;
        }

        if ( termsAndPrivacyPolicyFlowEnabledToSet != null )
        {
            settings.getTermsAndPrivacyPolicyFlowSettings().setEnabled( termsAndPrivacyPolicyFlowEnabledToSet );
            termsAndPrivacyPolicyFlowEnabledToSet = null;
        }

        if ( privacyPolicyURLToSet != null )
        {
            settings.getTermsAndPrivacyPolicyFlowSettings().setPrivacyPolicyUri( privacyPolicyURLToSet );
            privacyPolicyURLToSet = null;
        }

        if ( termsOfServiceURLToSet != null )
        {
            settings.getTermsAndPrivacyPolicyFlowSettings().setTermsOfServiceUri( termsOfServiceURLToSet );
            termsOfServiceURLToSet = null;
        }

        if ( AppLovinSdkUtils.isValidString( debugUserGeographyToSet ) )
        {
            settings.getTermsAndPrivacyPolicyFlowSettings().setDebugUserGeography( getAppLovinConsentFlowUserGeography( debugUserGeographyToSet ) );
            debugUserGeographyToSet = null;
        }

        if ( mutedToSet != null )
        {
            settings.setMuted( mutedToSet );
            mutedToSet = null;
        }

        if ( testDeviceAdvertisingIdsToSet != null )
        {
            settings.setTestDeviceAdvertisingIds( testDeviceAdvertisingIdsToSet );
            testDeviceAdvertisingIdsToSet = null;
        }

        if ( verboseLoggingToSet != null )
        {
            settings.setVerboseLogging( verboseLoggingToSet );
            verboseLoggingToSet = null;
        }

        if ( creativeDebuggerEnabledToSet != null )
        {
            settings.setCreativeDebuggerEnabled( creativeDebuggerEnabledToSet );
            creativeDebuggerEnabledToSet = null;
        }

        if ( locationCollectionEnabledToSet != null )
        {
            settings.setLocationCollectionEnabled( locationCollectionEnabledToSet );
            locationCollectionEnabledToSet = null;
        }

        setPendingExtraParametersIfNeeded( settings );

        // Initialize SDK
        sdk = AppLovinSdk.getInstance( sdkKeyToUse, settings, applicationContext );
        sdk.setPluginVersion( "Flutter-" + pluginVersion );
        sdk.setMediationProvider( AppLovinMediationProvider.MAX );

        if ( AppLovinSdkUtils.isValidString( userIdToSet ) )
        {
            sdk.setUserIdentifier( userIdToSet );
            userIdToSet = null;
        }

        if ( targetingYearOfBirthToSet != null )
        {
            sdk.getTargetingData().setYearOfBirth( targetingYearOfBirthToSet <= 0 ? null : targetingYearOfBirthToSet );
            targetingYearOfBirthToSet = null;
        }

        if ( targetingGenderToSet != null )
        {
            sdk.getTargetingData().setGender( getAppLovinGender( targetingGenderToSet ) );
            targetingGenderToSet = null;
        }

        if ( targetingMaximumAdContentRatingToSet != null )
        {
            sdk.getTargetingData().setMaximumAdContentRating( getAppLovinAdContentRating( targetingMaximumAdContentRatingToSet ) );
            targetingMaximumAdContentRatingToSet = null;
        }

        if ( targetingEmailToSet != null )
        {
            sdk.getTargetingData().setEmail( targetingEmailToSet );
            targetingEmailToSet = null;
        }

        if ( targetingPhoneNumberToSet != null )
        {
            sdk.getTargetingData().setPhoneNumber( targetingPhoneNumberToSet );
            targetingPhoneNumberToSet = null;
        }

        if ( targetingKeywordsToSet != null )
        {
            sdk.getTargetingData().setKeywords( targetingKeywordsToSet );
            targetingKeywordsToSet = null;
        }

        if ( targetingInterestsToSet != null )
        {
            sdk.getTargetingData().setInterests( targetingInterestsToSet );
            targetingInterestsToSet = null;
        }

        sdk.initializeSdk( configuration -> {

            d( "SDK initialized" );

            sdkConfiguration = configuration;
            isSdkInitialized = true;

            result.success( getInitializationMessage() );
        } );
    }

    private Map<String, Object> getInitializationMessage()
    {
        Map<String, Object> message = new HashMap<>( 4 );

        if ( sdkConfiguration != null )
        {
            message.put( "consentDialogState", sdkConfiguration.getConsentDialogState().ordinal() );
            message.put( "countryCode", sdkConfiguration.getCountryCode() );
            message.put( "isTestModeEnabled", sdkConfiguration.isTestModeEnabled() );
            message.put( "consentFlowUserGeography", getRawAppLovinConsentFlowUserGeography( sdkConfiguration.getConsentFlowUserGeography() ) );
        }
        else
        {
            message.put( "consentDialogState", AppLovinSdkConfiguration.ConsentDialogState.UNKNOWN.ordinal() );
        }

        return message;
    }

    // General Public API

    public void isTablet(final Result result)
    {
        result.success( AppLovinSdkUtils.isTablet( applicationContext ) );
    }

    public void showMediationDebugger()
    {
        if ( sdk == null )
        {
            logUninitializedAccessError( "showMediationDebugger" );
            return;
        }

        sdk.showMediationDebugger();
    }

    public void showConsentDialog(final Result result)
    {
        if ( sdk == null )
        {
            logUninitializedAccessError( "showConsentDialog" );
            return;
        }

        sdk.getUserService().showConsentDialog( getCurrentActivity(), (AppLovinUserService.OnConsentDialogDismissListener) () -> result.success( null ) );
    }

    public void getConsentDialogState(final Result result)
    {
        if ( !isInitialized() ) result.success( AppLovinSdkConfiguration.ConsentDialogState.UNKNOWN.ordinal() );

        result.success( sdkConfiguration.getConsentDialogState().ordinal() );
    }

    public void setHasUserConsent(boolean hasUserConsent)
    {
        AppLovinPrivacySettings.setHasUserConsent( hasUserConsent, applicationContext );
    }

    public void hasUserConsent(final Result result)
    {
        result.success( AppLovinPrivacySettings.hasUserConsent( applicationContext ) );
    }

    public void setIsAgeRestrictedUser(boolean isAgeRestrictedUser)
    {
        AppLovinPrivacySettings.setIsAgeRestrictedUser( isAgeRestrictedUser, applicationContext );
    }

    public void isAgeRestrictedUser(final Result result)
    {
        result.success( AppLovinPrivacySettings.isAgeRestrictedUser( applicationContext ) );
    }

    public void setDoNotSell(final boolean doNotSell)
    {
        AppLovinPrivacySettings.setDoNotSell( doNotSell, applicationContext );
    }

    public void isDoNotSell(final Result result)
    {
        result.success( AppLovinPrivacySettings.isDoNotSell( applicationContext ) );
    }

    public void setUserId(String userId)
    {
        if ( isPluginInitialized )
        {
            sdk.setUserIdentifier( userId );
            userIdToSet = null;
        }
        else
        {
            userIdToSet = userId;
        }
    }

    public void setMuted(final boolean muted)
    {
        if ( isPluginInitialized )
        {
            sdk.getSettings().setMuted( muted );
            mutedToSet = null;
        }
        else
        {
            mutedToSet = muted;
        }
    }

    public boolean isMuted()
    {
        if ( !isPluginInitialized ) return false;

        return sdk.getSettings().isMuted();
    }

    public void setVerboseLogging(final boolean enabled)
    {
        if ( isPluginInitialized )
        {
            sdk.getSettings().setVerboseLogging( enabled );
            verboseLoggingToSet = null;
        }
        else
        {
            verboseLoggingToSet = enabled;
        }
    }

    public void setCreativeDebuggerEnabled(final boolean enabled)
    {
        if ( isPluginInitialized )
        {
            sdk.getSettings().setCreativeDebuggerEnabled( enabled );
            creativeDebuggerEnabledToSet = null;
        }
        else
        {
            creativeDebuggerEnabledToSet = enabled;
        }
    }

    public void setTestDeviceAdvertisingIds(final List<String> rawAdvertisingIds)
    {
        List<String> advertisingIds = new ArrayList<>( rawAdvertisingIds.size() );

        if ( isPluginInitialized )
        {
            sdk.getSettings().setTestDeviceAdvertisingIds( advertisingIds );
            testDeviceAdvertisingIdsToSet = null;
        }
        else
        {
            testDeviceAdvertisingIdsToSet = advertisingIds;
        }
    }

    public void setLocationCollectionEnabled(final boolean enabled)
    {
        if ( isPluginInitialized )
        {
            sdk.getSettings().setLocationCollectionEnabled( enabled );
            locationCollectionEnabledToSet = null;
        }
        else
        {
            locationCollectionEnabledToSet = enabled;
        }
    }

    public void setExtraParameter(final String key, @Nullable final String value)
    {
        if ( TextUtils.isEmpty( key ) )
        {
            e( "ERROR: Failed to set extra parameter for null or empty key: " + key );
            return;
        }

        if ( sdk != null )
        {
            AppLovinSdkSettings settings = sdk.getSettings();
            settings.setExtraParameter( key, value );
            setPendingExtraParametersIfNeeded( settings );
        }
        else
        {
            extraParametersToSet.put( key, value );
        }
    }

    public void setInitializationAdUnitIds(final List<String> rawAdUnitIds)
    {
        initializationAdUnitIdsToSet = new ArrayList<>( rawAdUnitIds );
    }

    // MAX Terms and Privacy Policy Flow

    public void setTermsAndPrivacyPolicyFlowEnabled(final boolean enabled)
    {
        termsAndPrivacyPolicyFlowEnabledToSet = enabled;
    }

    public void setPrivacyPolicyUrl(final String urlString)
    {
        privacyPolicyURLToSet = Uri.parse( urlString );
    }

    public void setTermsOfServiceUrl(final String urlString)
    {
        termsOfServiceURLToSet = Uri.parse( urlString );
    }

    public void setConsentFlowDebugUserGeography(final String userGeography)
    {
        debugUserGeographyToSet = userGeography;
    }

    public void showCmpForExistingUser(final Result result)
    {
        if ( !isPluginInitialized )
        {
            logUninitializedAccessError( "showCmpForExistingUser", result );
            return;
        }

        sdk.getCmpService().showCmpForExistingUser( getCurrentActivity(), (@Nullable final AppLovinCmpError error) -> {

            if ( error == null )
            {
                result.success( null );
                return;
            }

            Map<String, Object> params = new HashMap<>( 4 );
            params.put( "code", error.getCode().getValue() );
            params.put( "message", error.getMessage() );
            params.put( "cmpCode", error.getCmpCode() );
            params.put( "cmpMessage", error.getCmpMessage() );
            result.success( params );
        } );
    }

    public void hasSupportedCmp(final Result result)
    {
        if ( !isPluginInitialized )
        {
            logUninitializedAccessError( "hasSupportedCmp", result );
            return;
        }

        result.success( sdk.getCmpService().hasSupportedCmp() );
    }

    // Data Passing

    public void setTargetingDataYearOfBirth(final int yearOfBirth)
    {
        if ( sdk == null )
        {
            targetingYearOfBirthToSet = yearOfBirth;
            return;
        }

        sdk.getTargetingData().setYearOfBirth( yearOfBirth <= 0 ? null : yearOfBirth );
    }

    public void setTargetingDataGender(@Nullable final String gender)
    {
        if ( sdk == null )
        {
            targetingGenderToSet = gender;
            return;
        }

        sdk.getTargetingData().setGender( getAppLovinGender( gender ) );
    }

    public void setTargetingDataMaximumAdContentRating(final int maximumAdContentRating)
    {
        if ( sdk == null )
        {
            targetingMaximumAdContentRatingToSet = maximumAdContentRating;
            return;
        }

        sdk.getTargetingData().setMaximumAdContentRating( getAppLovinAdContentRating( maximumAdContentRating ) );
    }

    public void setTargetingDataEmail(@Nullable final String email)
    {
        if ( sdk == null )
        {
            targetingEmailToSet = email;
            return;
        }

        sdk.getTargetingData().setEmail( email );
    }

    public void setTargetingDataPhoneNumber(@Nullable final String phoneNumber)
    {
        if ( sdk == null )
        {
            targetingPhoneNumberToSet = phoneNumber;
            return;
        }

        sdk.getTargetingData().setPhoneNumber( phoneNumber );
    }

    public void setTargetingDataKeywords(@Nullable final List<String> keywords)
    {
        if ( sdk == null )
        {
            targetingKeywordsToSet = keywords;
            return;
        }

        sdk.getTargetingData().setKeywords( keywords );
    }

    public void setTargetingDataInterests(@Nullable final List<String> interests)
    {
        if ( sdk == null )
        {
            targetingInterestsToSet = interests;
            return;
        }

        sdk.getTargetingData().setInterests( interests );
    }

    public void clearAllTargetingData()
    {
        if ( sdk == null )
        {
            logUninitializedAccessError( "clearAllTargetingData" );
            return;
        }

        sdk.getTargetingData().clearAll();
    }

    // BANNERS

    public void createBanner(final String adUnitId, final String bannerPosition)
    {
        createAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat(), bannerPosition );
    }

    public void setBannerBackgroundColor(final String adUnitId, final String hexColorCode)
    {
        setAdViewBackgroundColor( adUnitId, getDeviceSpecificBannerAdViewAdFormat(), hexColorCode );
    }

    public void setBannerPlacement(final String adUnitId, final String placement)
    {
        setAdViewPlacement( adUnitId, getDeviceSpecificBannerAdViewAdFormat(), placement );
    }

    public void updateBannerPosition(final String adUnitId, final String bannerPosition)
    {
        updateAdViewPosition( adUnitId, bannerPosition, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void setBannerExtraParameter(final String adUnitId, final String key, final String value)
    {
        setAdViewExtraParameters( adUnitId, getDeviceSpecificBannerAdViewAdFormat(), key, value );
    }

    public void showBanner(final String adUnitId)
    {
        showAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void hideBanner(final String adUnitId)
    {
        hideAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void loadBanner(final String adUnitId)
    {
        loadAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void startBannerAutoRefresh(final String adUnitId)
    {
        startAdViewAutoRefresh( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void stopBannerAutoRefresh(final String adUnitId)
    {
        stopAdViewAutoRefresh( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void destroyBanner(final String adUnitId)
    {
        destroyAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
    }

    public void getAdaptiveBannerHeightForWidth(final double width, final Result result)
    {
        result.success( (double) getDeviceSpecificBannerAdViewAdFormat().getAdaptiveSize( (int) width, applicationContext ).getHeight() );
    }

    // MRECS

    public void createMRec(final String adUnitId, final String mrecPosition)
    {
        createAdView( adUnitId, MaxAdFormat.MREC, mrecPosition );
    }

    public void setMRecPlacement(final String adUnitId, final String placement)
    {
        setAdViewPlacement( adUnitId, MaxAdFormat.MREC, placement );
    }

    public void updateMRecPosition(final String adUnitId, final String mrecPosition)
    {
        updateAdViewPosition( adUnitId, mrecPosition, MaxAdFormat.MREC );
    }

    public void setMRecExtraParameter(final String adUnitId, final String key, final String value)
    {
        setAdViewExtraParameters( adUnitId, MaxAdFormat.MREC, key, value );
    }

    public void showMRec(final String adUnitId)
    {
        showAdView( adUnitId, MaxAdFormat.MREC );
    }

    public void hideMRec(final String adUnitId)
    {
        hideAdView( adUnitId, MaxAdFormat.MREC );
    }

    public void loadMRec(final String adUnitId)
    {
        loadAdView( adUnitId, MaxAdFormat.MREC );
    }

    public void startMRecAutoRefresh(final String adUnitId)
    {
        startAdViewAutoRefresh( adUnitId, MaxAdFormat.MREC );
    }

    public void stopMRecAutoRefresh(final String adUnitId)
    {
        stopAdViewAutoRefresh( adUnitId, MaxAdFormat.MREC );
    }

    public void destroyMRec(final String adUnitId)
    {
        destroyAdView( adUnitId, MaxAdFormat.MREC );
    }

    // INTERSTITIALS

    public void loadInterstitial(final String adUnitId)
    {
        MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
        interstitial.loadAd();
    }

    public void isInterstitialReady(final String adUnitId, final Result result)
    {
        MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
        result.success( interstitial.isReady() );
    }

    public void showInterstitial(final String adUnitId, final String placement, final String customData)
    {
        MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
        interstitial.showAd( placement, customData );
    }

    public void setInterstitialExtraParameter(final String adUnitId, final String key, final String value)
    {
        MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
        interstitial.setExtraParameter( key, value );
    }

    // REWARDED

    public void loadRewardedAd(final String adUnitId)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        rewardedAd.loadAd();
    }

    public void isRewardedAdReady(final String adUnitId, final Result result)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        result.success( rewardedAd.isReady() );
    }

    public void showRewardedAd(final String adUnitId, final String placement, final String customData)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        rewardedAd.showAd( placement, customData );
    }

    public void setRewardedAdExtraParameter(final String adUnitId, final String key, final String value)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        rewardedAd.setExtraParameter( key, value );
    }

    // APP OPEN AD

    public void loadAppOpenAd(final String adUnitId)
    {
        MaxAppOpenAd appOpenAd = retrieveAppOpenAd( adUnitId );
        appOpenAd.loadAd();
    }

    public void isAppOpenAdReady(final String adUnitId, final Result result)
    {
        MaxAppOpenAd appOpenAd = retrieveAppOpenAd( adUnitId );
        result.success( appOpenAd.isReady() );
    }

    public void showAppOpenAd(final String adUnitId, final String placement, final String customData)
    {
        MaxAppOpenAd appOpenAd = retrieveAppOpenAd( adUnitId );
        appOpenAd.showAd( placement, customData );
    }

    public void setAppOpenAdExtraParameter(final String adUnitId, final String key, final String value)
    {
        MaxAppOpenAd appOpenAd = retrieveAppOpenAd( adUnitId );
        appOpenAd.setExtraParameter( key, value );
    }

    // AD CALLBACKS

    @Override
    public void onAdLoaded(MaxAd ad)
    {
        String name;
        MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat.isAdViewAd() )
        {
            name = ( MaxAdFormat.MREC == adFormat ) ? "OnMRecAdLoadedEvent" : "OnBannerAdLoadedEvent";

            String adViewPosition = mAdViewPositions.get( ad.getAdUnitId() );
            if ( AppLovinSdkUtils.isValidString( adViewPosition ) )
            {
                // Only position ad if not native UI component
                positionAdView( ad );
            }

            // Do not auto-refresh by default if the ad view is not showing yet (e.g. first load during app launch and publisher does not automatically show banner upon load success)
            // We will resume auto-refresh in {@link #showBanner(String)}.
            MaxAdView adView = retrieveAdView( ad.getAdUnitId(), adFormat );
            if ( adView != null && adView.getVisibility() != View.VISIBLE )
            {
                adView.stopAutoRefresh();
            }
        }
        else if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialLoadedEvent";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdLoadedEvent";
        }
        else if ( MaxAdFormat.APP_OPEN == adFormat )
        {
            name = "OnAppOpenAdLoadedEvent";
        }
        else
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdLoadFailed(final String adUnitId, final MaxError error)
    {
        if ( TextUtils.isEmpty( adUnitId ) )
        {
            logStackTrace( new IllegalArgumentException( "adUnitId cannot be null" ) );
            return;
        }

        String name;
        if ( mAdViews.containsKey( adUnitId ) )
        {
            name = ( MaxAdFormat.MREC == mAdViewAdFormats.get( adUnitId ) ) ? "OnMRecAdLoadFailedEvent" : "OnBannerAdLoadFailedEvent";
        }
        else if ( mInterstitials.containsKey( adUnitId ) )
        {
            name = "OnInterstitialLoadFailedEvent";
        }
        else if ( mRewardedAds.containsKey( adUnitId ) )
        {
            name = "OnRewardedAdLoadFailedEvent";
        }
        else if ( mAppOpenAds.containsKey( adUnitId ) )
        {
            name = "OnAppOpenAdLoadFailedEvent";
        }
        else
        {
            logStackTrace( new IllegalStateException( "invalid adUnitId: " + adUnitId ) );
            return;
        }

        fireCallback( name, getAdLoadFailedInfo( adUnitId, error ) );
    }

    @Override
    public void onAdClicked(final MaxAd ad)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        final String name;
        if ( MaxAdFormat.BANNER == adFormat || MaxAdFormat.LEADER == adFormat )
        {
            name = "OnBannerAdClickedEvent";
        }
        else if ( MaxAdFormat.MREC == adFormat )
        {
            name = "OnMRecAdClickedEvent";
        }
        else if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialClickedEvent";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdClickedEvent";
        }
        else if ( MaxAdFormat.APP_OPEN == adFormat )
        {
            name = "OnAppOpenAdClickedEvent";
        }
        else
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdDisplayed(final MaxAd ad)
    {
        // BMLs do not support [DISPLAY] events
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED && adFormat != MaxAdFormat.APP_OPEN ) return;

        final String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialDisplayedEvent";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdDisplayedEvent";
        }
        else // APP OPEN
        {
            name = "OnAppOpenAdDisplayedEvent";
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdDisplayFailed(final MaxAd ad, final MaxError error)
    {
        // BMLs do not support [DISPLAY] events
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED && adFormat != MaxAdFormat.APP_OPEN ) return;

        final String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialAdFailedToDisplayEvent";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdFailedToDisplayEvent";
        }
        else // APP OPEN
        {
            name = "OnAppOpenAdFailedToDisplayEvent";
        }

        fireCallback( name, getAdDisplayFailedInfo( ad, error ) );
    }

    @Override
    public void onAdHidden(final MaxAd ad)
    {
        // BMLs do not support [HIDDEN] events
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED && adFormat != MaxAdFormat.APP_OPEN ) return;

        String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialHiddenEvent";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdHiddenEvent";
        }
        else // APP OPEN
        {
            name = "OnAppOpenAdHiddenEvent";
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdExpanded(final MaxAd ad)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        if ( !adFormat.isAdViewAd() )
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( ( MaxAdFormat.MREC == adFormat ) ? "OnMrecAdExpandedEvent" : "OnBannerAdExpandedEvent", getAdInfo( ad ) );
    }

    @Override
    public void onAdCollapsed(final MaxAd ad)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        if ( !adFormat.isAdViewAd() )
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( ( MaxAdFormat.MREC == adFormat ) ? "OnMRecAdCollapsedEvent" : "OnBannerAdCollapsedEvent", getAdInfo( ad ) );
    }

    @Override
    public void onAdRevenuePaid(final MaxAd ad)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        final String name;
        if ( MaxAdFormat.BANNER == adFormat || MaxAdFormat.LEADER == adFormat )
        {
            name = "OnBannerAdRevenuePaid";
        }
        else if ( MaxAdFormat.MREC == adFormat )
        {
            name = "OnMRecAdRevenuePaid";
        }
        else if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialAdRevenuePaid";
        }
        else if ( MaxAdFormat.REWARDED == adFormat )
        {
            name = "OnRewardedAdRevenuePaid";
        }
        else if ( MaxAdFormat.APP_OPEN == adFormat )
        {
            name = "OnAppOpenAdRevenuePaid";
        }
        else
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onRewardedVideoCompleted(final MaxAd ad)
    {
        // This event is not forwarded
    }

    @Override
    public void onRewardedVideoStarted(final MaxAd ad)
    {
        // This event is not forwarded
    }

    @Override
    public void onUserRewarded(final MaxAd ad, final MaxReward reward)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.REWARDED )
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        final String rewardLabel = reward != null ? reward.getLabel() : "";
        final int rewardAmount = reward != null ? reward.getAmount() : 0;

        try
        {
            Map<String, Object> params = getAdInfo( ad );
            params.put( "rewardLabel", rewardLabel );
            params.put( "rewardAmount", rewardAmount );
            fireCallback( "OnRewardedAdReceivedRewardEvent", params );
        }
        catch ( Throwable ignored ) { }
    }

    // INTERNAL METHODS

    private void createAdView(final String adUnitId, final MaxAdFormat adFormat, final String adViewPosition)
    {
        d( "Creating " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\" and position: \"" + adViewPosition + "\"" );

        // Retrieve ad view from the map
        final MaxAdView adView = retrieveAdView( adUnitId, adFormat, adViewPosition );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        adView.setVisibility( View.GONE );

        if ( adView.getParent() == null )
        {
            final Activity currentActivity = getCurrentActivity();
            final RelativeLayout relativeLayout = new RelativeLayout( currentActivity );
            currentActivity.addContentView( relativeLayout, new LinearLayout.LayoutParams( LinearLayout.LayoutParams.MATCH_PARENT,
                                                                                           LinearLayout.LayoutParams.MATCH_PARENT ) );
            relativeLayout.addView( adView );

            // Position ad view immediately so if publisher sets color before ad loads, it will not be the size of the screen
            mAdViewAdFormats.put( adUnitId, adFormat );
            positionAdView( adUnitId, adFormat );
        }

        adView.loadAd();

        // Disable auto-refresh if publisher sets it before creating the ad view.
        if ( mDisabledAutoRefreshAdViewAdUnitIds.contains( adUnitId ) )
        {
            adView.stopAutoRefresh();
        }

        // The publisher may have requested to show the banner before it was created. Now that the banner is created, show it.
        if ( mAdUnitIdsToShowAfterCreate.contains( adUnitId ) )
        {
            showAdView( adUnitId, adFormat );
            mAdUnitIdsToShowAfterCreate.remove( adUnitId );
        }
    }

    private void loadAdView(final String adUnitId, final MaxAdFormat adFormat)
    {
        MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        if ( !mDisabledAutoRefreshAdViewAdUnitIds.contains( adUnitId ) )
        {
            if ( adView.getVisibility() != View.VISIBLE )
            {
                e( "Auto-refresh will resume when the " + adFormat.getLabel() + " ad is shown. You should only call LoadBanner() or LoadMRec() if you explicitly pause auto-refresh and want to manually load an ad." );
                return;
            }

            e( "You must stop auto-refresh if you want to manually load " + adFormat.getLabel() + " ads." );
            return;
        }

        adView.loadAd();
    }

    private void startAdViewAutoRefresh(final String adUnitId, final MaxAdFormat adFormat)
    {
        d( "Starting " + adFormat.getLabel() + " auto refresh for ad unit identifier \"" + adUnitId + "\"" );

        mDisabledAutoRefreshAdViewAdUnitIds.remove( adUnitId );

        MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist for ad unit identifier \"" + adUnitId + "\"" );
            return;
        }

        adView.startAutoRefresh();
    }

    private void stopAdViewAutoRefresh(final String adUnitId, final MaxAdFormat adFormat)
    {
        d( "Stopping " + adFormat.getLabel() + " auto refresh for ad unit identifier \"" + adUnitId + "\"" );

        mDisabledAutoRefreshAdViewAdUnitIds.add( adUnitId );

        MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist for ad unit identifier \"" + adUnitId + "\"" );
            return;
        }

        adView.stopAutoRefresh();
    }

    private void setAdViewPlacement(final String adUnitId, final MaxAdFormat adFormat, final String placement)
    {
        d( "Setting placement \"" + placement + "\" for " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\"" );

        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        adView.setPlacement( placement );
    }

    private void updateAdViewPosition(final String adUnitId, final String adViewPosition, final MaxAdFormat adFormat)
    {
        d( "Updating " + adFormat.getLabel() + " position to \"" + adViewPosition + "\" for ad unit id \"" + adUnitId + "\"" );

        // Retrieve ad view from the map
        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        // Check if the previous position is same as the new position. If so, no need to update the position again.
        final String previousPosition = mAdViewPositions.get( adUnitId );
        if ( adViewPosition == null || adViewPosition.equals( previousPosition ) ) return;

        mAdViewPositions.put( adUnitId, adViewPosition );
        positionAdView( adUnitId, adFormat );
    }

    private void showAdView(final String adUnitId, final MaxAdFormat adFormat)
    {
        d( "Showing " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\"" );

        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist for ad unit id " + adUnitId );

            // The adView has not yet been created. Store the ad unit ID, so that it can be displayed once the banner has been created.
            mAdUnitIdsToShowAfterCreate.add( adUnitId );
            return;
        }

        adView.setVisibility( View.VISIBLE );
        adView.startAutoRefresh();

        if ( !mDisabledAutoRefreshAdViewAdUnitIds.contains( adUnitId ) )
        {
            adView.startAutoRefresh();
        }
    }

    private void hideAdView(final String adUnitId, final MaxAdFormat adFormat)
    {
        d( "Hiding " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\"" );
        mAdUnitIdsToShowAfterCreate.remove( adUnitId );

        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        adView.setVisibility( View.GONE );
        adView.stopAutoRefresh();
    }

    private void destroyAdView(final String adUnitId, final MaxAdFormat adFormat)
    {
        d( "Destroying " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\"" );

        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        final ViewParent parent = adView.getParent();
        if ( parent instanceof ViewGroup )
        {
            ( (ViewGroup) parent ).removeView( adView );
        }

        adView.setListener( null );
        adView.setRevenueListener( null );
        adView.destroy();

        mAdViews.remove( adUnitId );
        mAdViewAdFormats.remove( adUnitId );
        mAdViewPositions.remove( adUnitId );
    }

    private void setAdViewBackgroundColor(final String adUnitId, final MaxAdFormat adFormat, final String hexColorCode)
    {
        d( "Setting " + adFormat.getLabel() + " with ad unit id \"" + adUnitId + "\" to color: " + hexColorCode );

        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        adView.setBackgroundColor( Color.parseColor( hexColorCode ) );
    }

    private void setAdViewExtraParameters(final String adUnitId, final MaxAdFormat adFormat, final String key, final String value)
    {
        d( "Setting " + adFormat.getLabel() + " extra with key: \"" + key + "\" value: " + value );

        // Retrieve ad view from the map
        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        adView.setExtraParameter( key, value );

        // Handle local changes as needed
        if ( "force_banner".equalsIgnoreCase( key ) && MaxAdFormat.MREC != adFormat )
        {
            final MaxAdFormat forcedAdFormat;

            boolean shouldForceBanner = Boolean.parseBoolean( value );
            if ( shouldForceBanner )
            {
                forcedAdFormat = MaxAdFormat.BANNER;
            }
            else
            {
                forcedAdFormat = getDeviceSpecificBannerAdViewAdFormat();
            }

            mAdViewAdFormats.put( adUnitId, forcedAdFormat );
            positionAdView( adUnitId, forcedAdFormat );
        }
    }

    private void setPendingExtraParametersIfNeeded(final AppLovinSdkSettings settings)
    {
        if ( extraParametersToSet.size() <= 0 ) return;

        for ( final String key : extraParametersToSet.keySet() )
        {
            settings.setExtraParameter( key, extraParametersToSet.get( key ) );
        }

        extraParametersToSet.clear();
    }

    // Utility Methods

    private void logInvalidAdFormat(MaxAdFormat adFormat)
    {
        logStackTrace( new IllegalStateException( "invalid ad format: " + adFormat ) );
    }

    private void logStackTrace(Exception e)
    {
        e( Log.getStackTraceString( e ) );
    }

    private static void logUninitializedAccessError(final String callingMethod)
    {
        logUninitializedAccessError( callingMethod, null );
    }

    private static void logUninitializedAccessError(final String callingMethod, @Nullable final Result result)
    {
        final String message = "ERROR: Failed to execute " + callingMethod + "() - please ensure the AppLovin MAX Flutter plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!";

        if ( result == null )
        {
            e( message );
            return;
        }

        result.error( TAG, message, null );
    }

    public static void d(final String message)
    {
        final String fullMessage = "[" + TAG + "] " + message;
        Log.d( SDK_TAG, fullMessage );
    }

    public static void w(final String message)
    {
        final String fullMessage = "[" + TAG + "] " + message;
        Log.w( SDK_TAG, fullMessage );
    }

    public static void e(final String message)
    {
        final String fullMessage = "[" + TAG + "] " + message;
        Log.e( SDK_TAG, fullMessage );
    }

    // NOTE: Do not update signature as some integrations depend on it via Java reflection
    private MaxInterstitialAd retrieveInterstitial(String adUnitId)
    {
        MaxInterstitialAd result = mInterstitials.get( adUnitId );
        if ( result == null )
        {
            result = new MaxInterstitialAd( adUnitId, sdk, getCurrentActivity() );
            result.setListener( this );
            result.setRevenueListener( this );

            mInterstitials.put( adUnitId, result );
        }

        return result;
    }

    // NOTE: Do not update signature as some integrations depend on it via Java reflection
    private MaxRewardedAd retrieveRewardedAd(String adUnitId)
    {
        MaxRewardedAd result = mRewardedAds.get( adUnitId );
        if ( result == null )
        {
            result = MaxRewardedAd.getInstance( adUnitId, sdk, getCurrentActivity() );
            result.setListener( this );
            result.setRevenueListener( this );

            mRewardedAds.put( adUnitId, result );
        }

        return result;
    }

    // NOTE: Do not update signature as some integrations depend on it via Java reflection
    private MaxAppOpenAd retrieveAppOpenAd(String adUnitId)
    {
        MaxAppOpenAd result = mAppOpenAds.get( adUnitId );
        if ( result == null )
        {
            result = new MaxAppOpenAd( adUnitId, sdk );
            result.setListener( this );
            result.setRevenueListener( this );

            mAppOpenAds.put( adUnitId, result );
        }

        return result;
    }

    // NOTE: Do not update signature as some integrations depend on it via Java reflection
    private MaxAdView retrieveAdView(String adUnitId, MaxAdFormat adFormat)
    {
        return retrieveAdView( adUnitId, adFormat, null );
    }

    public MaxAdView retrieveAdView(String adUnitId, MaxAdFormat adFormat, String adViewPosition)
    {
        MaxAdView result = mAdViews.get( adUnitId );
        if ( result == null && adViewPosition != null )
        {
            result = new MaxAdView( adUnitId, adFormat, sdk, getCurrentActivity() );
            result.setListener( this );
            result.setRevenueListener( this );

            mAdViews.put( adUnitId, result );
            mAdViewPositions.put( adUnitId, adViewPosition );

            // Allow pubs to pause auto-refresh immediately, by default.
            result.setExtraParameter( "allow_pause_auto_refresh_immediately", "true" );
        }

        return result;
    }

    private void positionAdView(MaxAd ad)
    {
        positionAdView( ad.getAdUnitId(), ad.getFormat() );
    }

    private void positionAdView(String adUnitId, MaxAdFormat adFormat)
    {
        final MaxAdView adView = retrieveAdView( adUnitId, adFormat );
        if ( adView == null )
        {
            e( adFormat.getLabel() + " does not exist" );
            return;
        }

        final String adViewPosition = mAdViewPositions.get( adUnitId );
        final RelativeLayout relativeLayout = (RelativeLayout) adView.getParent();
        if ( relativeLayout == null )
        {
            e( adFormat.getLabel() + "'s parent does not exist" );
            return;
        }

        // Size the ad
        final AdViewSize adViewSize = getAdViewSize( adFormat );
        final int width = AppLovinSdkUtils.dpToPx( getCurrentActivity(), adViewSize.widthDp );
        final int height = AppLovinSdkUtils.dpToPx( getCurrentActivity(), adViewSize.heightDp );

        final RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams) adView.getLayoutParams();
        params.height = height;
        adView.setLayoutParams( params );

        // Parse gravity
        int gravity = 0;

        // Reset rotation, translation and margins so that the banner can be positioned again
        adView.setRotation( 0 );
        adView.setTranslationX( 0 );
        params.setMargins( 0, 0, 0, 0 );

        if ( "centered".equalsIgnoreCase( adViewPosition ) )
        {
            gravity = Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL;
        }
        else
        {
            // Figure out vertical params
            if ( adViewPosition.contains( "top" ) )
            {
                gravity = Gravity.TOP;
            }
            else if ( adViewPosition.contains( "bottom" ) )
            {
                gravity = Gravity.BOTTOM;
            }

            // Figure out horizontal params
            if ( adViewPosition.contains( "center" ) )
            {
                gravity |= Gravity.CENTER_HORIZONTAL;
                params.width = ( MaxAdFormat.MREC == adFormat ) ? width : RelativeLayout.LayoutParams.MATCH_PARENT; // Stretch width if banner
            }
            else
            {
                params.width = width;

                if ( adViewPosition.contains( "left" ) )
                {
                    gravity |= Gravity.LEFT;
                }
                else if ( adViewPosition.contains( "right" ) )
                {
                    gravity |= Gravity.RIGHT;
                }
            }
        }

        relativeLayout.setGravity( gravity );
    }

    // AD INFO

    public Map<String, Object> getAdInfo(final MaxAd ad)
    {
        Map<String, Object> adInfo = new HashMap<>( 7 );
        adInfo.put( "adUnitId", ad.getAdUnitId() );
        adInfo.put( "creativeId", AppLovinSdkUtils.isValidString( ad.getCreativeId() ) ? ad.getCreativeId() : "" );
        adInfo.put( "networkName", ad.getNetworkName() );
        adInfo.put( "placement", AppLovinSdkUtils.isValidString( ad.getPlacement() ) ? ad.getPlacement() : "" );
        adInfo.put( "revenue", ad.getRevenue() );
        adInfo.put( "revenuePrecision", ad.getRevenuePrecision() );
        adInfo.put( "dspName", AppLovinSdkUtils.isValidString( ad.getDspName() ) ? ad.getDspName() : "" );
        adInfo.put( "waterfall", createAdWaterfallInfo( ad.getWaterfall() ) );

        return adInfo;
    }

    public Map<String, Object> getAdLoadFailedInfo(final String adUnitId, @Nullable final MaxError error)
    {
        Map<String, Object> errorInfo = new HashMap<>( 4 );
        errorInfo.put( "adUnitId", adUnitId );
        if ( error != null )
        {
            errorInfo.put( "code", error.getCode() );
            errorInfo.put( "message", error.getMessage() );
            errorInfo.put( "waterfall", createAdWaterfallInfo( error.getWaterfall() ) );
        }
        else
        {
            errorInfo.put( "code", MaxErrorCode.UNSPECIFIED );
        }
        return errorInfo;
    }

    public Map<String, Object> getAdDisplayFailedInfo(final MaxAd ad, final MaxError error)
    {
        Map<String, Object> info = new HashMap<>( 2 );
        info.put( "ad", getAdInfo( ad ) );
        info.put( "error", getAdLoadFailedInfo( ad.getAdUnitId(), error ) );
        return info;
    }

    // AD WATERFALL INFO

    private Map<String, Object> createAdWaterfallInfo(final MaxAdWaterfallInfo waterfallInfo)
    {
        Map<String, Object> waterfallInfoObject = new HashMap<>();
        if ( waterfallInfo == null ) return waterfallInfoObject;

        waterfallInfoObject.put( "name", waterfallInfo.getName() );
        waterfallInfoObject.put( "testName", waterfallInfo.getTestName() );

        List<Object> networkResponsesArray = new ArrayList<>();
        for ( MaxNetworkResponseInfo response : waterfallInfo.getNetworkResponses() )
        {
            networkResponsesArray.add( createNetworkResponseInfo( response ) );
        }
        waterfallInfoObject.put( "networkResponses", networkResponsesArray );

        waterfallInfoObject.put( "latencyMillis", waterfallInfo.getLatencyMillis() );

        return waterfallInfoObject;
    }

    private Map<String, Object> createNetworkResponseInfo(final MaxNetworkResponseInfo response)
    {
        Map<String, Object> networkResponseObject = new HashMap<>();
        networkResponseObject.put( "adLoadState", response.getAdLoadState().ordinal() );

        MaxMediatedNetworkInfo mediatedNetworkInfo = response.getMediatedNetwork();
        if ( mediatedNetworkInfo != null )
        {
            Map<String, String> networkInfoObject = new HashMap<>( 4 );
            networkInfoObject.put( "name", mediatedNetworkInfo.getName() );
            networkInfoObject.put( "adapterClassName", mediatedNetworkInfo.getAdapterClassName() );
            networkInfoObject.put( "adapterVersion", mediatedNetworkInfo.getAdapterVersion() );
            networkInfoObject.put( "sdkVersion", mediatedNetworkInfo.getSdkVersion() );

            networkResponseObject.put( "mediatedNetwork", networkInfoObject );
        }

        Bundle credentialBundle = response.getCredentials();
        Map<String, String> credentials = new HashMap<>();
        for ( String key : credentialBundle.keySet() )
        {
            Object obj = credentialBundle.get( key );
            if ( obj instanceof String )
            {
                credentials.put( key, (String) obj );
            }
        }
        networkResponseObject.put( "credentials", credentials );

        MaxError error = response.getError();
        if ( error != null )
        {
            networkResponseObject.put( "error", getAdLoadFailedInfo( "", error ) );
        }

        networkResponseObject.put( "latencyMillis", response.getLatencyMillis() );

        return networkResponseObject;
    }

    // Amazon

    public void setAmazonBannerResult(final Object result, final String adUnitId)
    {
        setAmazonResult( result, adUnitId, MaxAdFormat.BANNER );
    }

    public void setAmazonMRecResult(final Object result, final String adUnitId)
    {
        setAmazonResult( result, adUnitId, MaxAdFormat.MREC );
    }

    public void setAmazonInterstitialResult(final Object result, final String adUnitId)
    {
        setAmazonResult( result, adUnitId, MaxAdFormat.INTERSTITIAL );
    }

    public void setAmazonRewardedResult(final Object result, final String adUnitId)
    {
        setAmazonResult( result, adUnitId, MaxAdFormat.REWARDED );
    }

    private void setAmazonResult(final Object result, final String adUnitId, final MaxAdFormat adFormat)
    {
        if ( sdk == null )
        {
            logUninitializedAccessError( "Failed to set Amazon result - SDK not initialized: " + adUnitId );
            return;
        }

        if ( result == null )
        {
            e( "Failed to set Amazon result - null value" );
            return;
        }

        String key = getLocalExtraParameterKeyForAmazonResult( result );

        if ( adFormat == MaxAdFormat.INTERSTITIAL )
        {
            MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
            if ( interstitial == null )
            {
                e( "Failed to set Amazon result - unable to find interstitial" );
                return;
            }

            interstitial.setLocalExtraParameter( key, result );
        }
        else if ( adFormat == MaxAdFormat.REWARDED )
        {
            MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
            if ( rewardedAd == null )
            {
                e( "Failed to set Amazon result - unable to find rewarded ad" );
                return;
            }

            rewardedAd.setLocalExtraParameter( key, result );
        }
        else // MaxAdFormat.BANNER or MaxAdFormat.MREC
        {
            MaxAdView adView = AppLovinMAXAdView.getInstance( adUnitId );

            if ( adView == null )
            {
                adView = retrieveAdView( adUnitId, adFormat );
            }

            if ( adView != null )
            {
                adView.setLocalExtraParameter( key, result );
            }
            else
            {
                e( "Failed to set Amazon result - unable to find " + adFormat );
            }
        }
    }

    private String getLocalExtraParameterKeyForAmazonResult(final Object /* DTBAdResponse or AdError */ result)
    {
        String className = result.getClass().getSimpleName();
        return "DTBAdResponse".equalsIgnoreCase( className ) ? "amazon_ad_response" : "amazon_ad_error";
    }

    // Utility Methods

    public MaxAdFormat getDeviceSpecificBannerAdViewAdFormat()
    {
        return getDeviceSpecificBannerAdViewAdFormat( applicationContext );
    }

    public static MaxAdFormat getDeviceSpecificBannerAdViewAdFormat(final Context context)
    {
        return AppLovinSdkUtils.isTablet( context ) ? MaxAdFormat.LEADER : MaxAdFormat.BANNER;
    }

    protected static class AdViewSize
    {
        public final int widthDp;
        public final int heightDp;

        private AdViewSize(final int widthDp, final int heightDp)
        {
            this.widthDp = widthDp;
            this.heightDp = heightDp;
        }
    }

    public static AdViewSize getAdViewSize(final MaxAdFormat format)
    {
        if ( MaxAdFormat.LEADER == format )
        {
            return new AdViewSize( 728, 90 );
        }
        else if ( MaxAdFormat.BANNER == format )
        {
            return new AdViewSize( 320, 50 );
        }
        else if ( MaxAdFormat.MREC == format )
        {
            return new AdViewSize( 300, 250 );
        }
        else
        {
            throw new IllegalArgumentException( "Invalid ad format" );
        }
    }

    private static Point getOffsetPixels(final float xDp, final float yDp, final Context context)
    {
        return new Point( AppLovinSdkUtils.dpToPx( context, (int) xDp ), AppLovinSdkUtils.dpToPx( context, (int) yDp ) );
    }

    private static AppLovinGender getAppLovinGender(@Nullable String gender)
    {
        if ( gender != null )
        {
            if ( "F".equalsIgnoreCase( gender ) )
            {
                return AppLovinGender.FEMALE;
            }
            else if ( "M".equalsIgnoreCase( gender ) )
            {
                return AppLovinGender.MALE;
            }
            else if ( "O".equalsIgnoreCase( gender ) )
            {
                return AppLovinGender.OTHER;
            }
        }

        return AppLovinGender.UNKNOWN;
    }

    private static AppLovinAdContentRating getAppLovinAdContentRating(int maximumAdContentRating)
    {
        if ( maximumAdContentRating == 1 )
        {
            return AppLovinAdContentRating.ALL_AUDIENCES;
        }
        else if ( maximumAdContentRating == 2 )
        {
            return AppLovinAdContentRating.EVERYONE_OVER_TWELVE;
        }
        else if ( maximumAdContentRating == 3 )
        {
            return AppLovinAdContentRating.MATURE_AUDIENCES;
        }

        return AppLovinAdContentRating.NONE;
    }

    private static ConsentFlowUserGeography getAppLovinConsentFlowUserGeography(final String userGeography)
    {
        if ( USER_GEOGRAPHY_GDPR.equalsIgnoreCase( userGeography ) )
        {
            return ConsentFlowUserGeography.GDPR;
        }
        else if ( USER_GEOGRAPHY_OTHER.equalsIgnoreCase( userGeography ) )
        {
            return ConsentFlowUserGeography.OTHER;
        }

        return ConsentFlowUserGeography.UNKNOWN;
    }

    private static String getRawAppLovinConsentFlowUserGeography(final ConsentFlowUserGeography userGeography)
    {
        if ( ConsentFlowUserGeography.GDPR == userGeography )
        {
            return USER_GEOGRAPHY_GDPR;
        }
        else if ( ConsentFlowUserGeography.OTHER == userGeography )
        {
            return USER_GEOGRAPHY_OTHER;
        }

        return USER_GEOGRAPHY_UNKNOWN;
    }

    // Flutter channel

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result)
    {
        if ( "initialize".equals( call.method ) )
        {
            String pluginVersion = call.argument( "plugin_version" );
            String sdkKey = call.argument( "sdk_key" );
            initialize( pluginVersion, sdkKey, result );
        }
        else if ( "isInitialized".equals( call.method ) )
        {
            isInitialized( result );
        }
        else if ( "isTablet".equals( call.method ) )
        {
            isTablet( result );
        }
        else if ( "showMediationDebugger".equals( call.method ) )
        {
            showMediationDebugger();

            result.success( null );
        }
        else if ( "getConsentDialogState".equals( call.method ) )
        {
            getConsentDialogState( result );
        }
        else if ( "setHasUserConsent".equals( call.method ) )
        {
            boolean hasUserConsent = call.argument( "value" );
            setHasUserConsent( hasUserConsent );

            result.success( null );
        }
        else if ( "hasUserConsent".equals( call.method ) )
        {
            hasUserConsent( result );
        }
        else if ( "setIsAgeRestrictedUser".equals( call.method ) )
        {
            boolean isAgeRestrictedUser = call.argument( "value" );
            setIsAgeRestrictedUser( isAgeRestrictedUser );

            result.success( null );
        }
        else if ( "isAgeRestrictedUser".equals( call.method ) )
        {
            isAgeRestrictedUser( result );
        }
        else if ( "setDoNotSell".equals( call.method ) )
        {
            boolean isDoNotSell = call.argument( "value" );
            setDoNotSell( isDoNotSell );

            result.success( null );
        }
        else if ( "isDoNotSell".equals( call.method ) )
        {
            isDoNotSell( result );
        }
        else if ( "setUserId".equals( call.method ) )
        {
            String userId = call.argument( "value" );
            setUserId( userId );

            result.success( null );
        }
        else if ( "setMuted".equals( call.method ) )
        {
            boolean isMuted = call.argument( "value" );
            setMuted( isMuted );

            result.success( null );
        }
        else if ( "setVerboseLogging".equals( call.method ) )
        {
            boolean isVerboseLogging = call.argument( "value" );
            setVerboseLogging( isVerboseLogging );

            result.success( null );
        }
        else if ( "setCreativeDebuggerEnabled".equals( call.method ) )
        {
            boolean isCreativeDebuggerEnabled = call.argument( "value" );
            setCreativeDebuggerEnabled( isCreativeDebuggerEnabled );

            result.success( null );
        }
        else if ( "setTestDeviceAdvertisingIds".equals( call.method ) )
        {
            List<String> testDeviceAdvertisingIds = call.argument( "value" );
            setTestDeviceAdvertisingIds( testDeviceAdvertisingIds );

            result.success( null );
        }
        else if ( "setLocationCollectionEnabled".equals( call.method ) )
        {
            boolean isLocationCollectionEnabled = call.argument( "value" );
            setLocationCollectionEnabled( isLocationCollectionEnabled );

            result.success( null );
        }
        else if ( "setExtraParameter".equals( call.method ) )
        {
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setExtraParameter( key, value );

            result.success( null );
        }
        else if ( "setInitializationAdUnitIds".equals( call.method ) )
        {
            List<String> adUnitIds = call.argument( "value" );
            setInitializationAdUnitIds( adUnitIds );

            result.success( null );
        }
        else if ( "setTermsAndPrivacyPolicyFlowEnabled".equals( call.method ) )
        {
            boolean value = call.argument( "value" );
            setTermsAndPrivacyPolicyFlowEnabled( value );

            result.success( null );
        }
        else if ( "setPrivacyPolicyUrl".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setPrivacyPolicyUrl( value );

            result.success( null );
        }
        else if ( "setTermsOfServiceUrl".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setTermsOfServiceUrl( value );

            result.success( null );
        }
        else if ( "setConsentFlowDebugUserGeography".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setConsentFlowDebugUserGeography( value );

            result.success( null );
        }
        else if ( "showCmpForExistingUser".equals( call.method ) )
        {
            showCmpForExistingUser( result );
        }
        else if ( "hasSupportedCmp".equals( call.method ) )
        {
            hasSupportedCmp( result );
        }
        else if ( "createBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String position = call.argument( "position" );
            createBanner( adUnitId, position );

            result.success( null );
        }
        else if ( "setBannerBackgroundColor".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String hexColorCode = call.argument( "hex_color_code" );
            setBannerBackgroundColor( adUnitId, hexColorCode );

            result.success( null );
        }
        else if ( "setBannerPlacement".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String placement = call.argument( "placement" );
            setBannerPlacement( adUnitId, placement );

            result.success( null );
        }
        else if ( "updateBannerPosition".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String position = call.argument( "position" );
            updateBannerPosition( adUnitId, position );

            result.success( null );
        }
        else if ( "setBannerExtraParameter".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setBannerExtraParameter( adUnitId, key, value );

            result.success( null );
        }
        else if ( "showBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            showBanner( adUnitId );

            result.success( null );
        }
        else if ( "hideBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            hideBanner( adUnitId );

            result.success( null );
        }
        else if ( "startBannerAutoRefresh".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            startBannerAutoRefresh( adUnitId );

            result.success( null );
        }
        else if ( "stopBannerAutoRefresh".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            stopBannerAutoRefresh( adUnitId );

            result.success( null );
        }
        else if ( "loadBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            loadBanner( adUnitId );

            result.success( null );
        }
        else if ( "destroyBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            destroyBanner( adUnitId );

            result.success( null );
        }
        else if ( "getAdaptiveBannerHeightForWidth".equals( call.method ) )
        {
            double width = call.argument( "width" );
            getAdaptiveBannerHeightForWidth( width, result );
        }
        else if ( "createMRec".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String position = call.argument( "position" );
            createMRec( adUnitId, position );

            result.success( null );
        }
        else if ( "setMRecPlacement".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String placement = call.argument( "placement" );
            setMRecPlacement( adUnitId, placement );

            result.success( null );
        }
        else if ( "updateMRecPosition".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String position = call.argument( "position" );
            updateMRecPosition( adUnitId, position );

            result.success( null );
        }
        else if ( "setMRecExtraParameter".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setMRecExtraParameter( adUnitId, key, value );

            result.success( null );
        }
        else if ( "showMRec".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            showMRec( adUnitId );

            result.success( null );
        }
        else if ( "hideMRec".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            hideMRec( adUnitId );

            result.success( null );
        }
        else if ( "startMRecAutoRefresh".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            startMRecAutoRefresh( adUnitId );

            result.success( null );
        }
        else if ( "stopMRecAutoRefresh".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            stopMRecAutoRefresh( adUnitId );

            result.success( null );
        }
        else if ( "loadMRec".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            loadMRec( adUnitId );

            result.success( null );
        }
        else if ( "destroyMRec".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            destroyMRec( adUnitId );

            result.success( null );
        }
        else if ( "loadInterstitial".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            loadInterstitial( adUnitId );

            result.success( null );
        }
        else if ( "isInterstitialReady".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            isInterstitialReady( adUnitId, result );
        }
        else if ( "showInterstitial".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String placement = call.argument( "placement" );
            String customData = call.argument( "custom_data" );
            showInterstitial( adUnitId, placement, customData );

            result.success( null );
        }
        else if ( "setInterstitialExtraParameter".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setInterstitialExtraParameter( adUnitId, key, value );

            result.success( null );
        }
        else if ( "loadRewardedAd".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            loadRewardedAd( adUnitId );

            result.success( null );
        }
        else if ( "isRewardedAdReady".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            isRewardedAdReady( adUnitId, result );
        }
        else if ( "showRewardedAd".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String placement = call.argument( "placement" );
            String customData = call.argument( "custom_data" );
            showRewardedAd( adUnitId, placement, customData );

            result.success( null );
        }
        else if ( "setRewardedAdExtraParameter".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setRewardedAdExtraParameter( adUnitId, key, value );

            result.success( null );
        }
        else if ( "loadAppOpenAd".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            loadAppOpenAd( adUnitId );

            result.success( null );
        }
        else if ( "isAppOpenAdReady".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            isAppOpenAdReady( adUnitId, result );
        }
        else if ( "showAppOpenAd".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String placement = call.argument( "placement" );
            String customData = call.argument( "custom_data" );
            showAppOpenAd( adUnitId, placement, customData );

            result.success( null );
        }
        else if ( "setAppOpenAdExtraParameter".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            String key = call.argument( "key" );
            String value = call.argument( "value" );
            setAppOpenAdExtraParameter( adUnitId, key, value );

            result.success( null );
        }
        else if ( "setTargetingDataYearOfBirth".equals( call.method ) )
        {
            int value = call.argument( "value" );
            setTargetingDataYearOfBirth( value );

            result.success( null );
        }
        else if ( "setTargetingDataGender".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setTargetingDataGender( value );

            result.success( null );
        }
        else if ( "setTargetingDataMaximumAdContentRating".equals( call.method ) )
        {
            int value = call.argument( "value" );
            setTargetingDataMaximumAdContentRating( value );

            result.success( null );
        }
        else if ( "setTargetingDataEmail".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setTargetingDataEmail( value );

            result.success( null );
        }
        else if ( "setTargetingDataPhoneNumber".equals( call.method ) )
        {
            String value = call.argument( "value" );
            setTargetingDataPhoneNumber( value );

            result.success( null );
        }
        else if ( "setTargetingDataKeywords".equals( call.method ) )
        {
            List<String> value = call.argument( "value" );
            setTargetingDataKeywords( value );

            result.success( null );
        }
        else if ( "setTargetingDataInterests".equals( call.method ) )
        {
            List<String> value = call.argument( "value" );
            setTargetingDataInterests( value );

            result.success( null );
        }
        else if ( "clearAllTargetingData".equals( call.method ) )
        {
            clearAllTargetingData();

            result.success( null );
        }
        else
        {
            result.notImplemented();
        }
    }

    public void fireCallback(final String name, final MaxAd ad, final MethodChannel channel)
    {
        fireCallback( name, getAdInfo( ad ), channel );
    }

    public void fireCallback(final String name, final Map<String, Object> params)
    {
        fireCallback( name, params, sharedChannel );
    }

    public void fireCallback(final String name, final Map<String, Object> params, final MethodChannel channel)
    {
        channel.invokeMethod( name, params );
    }

    // Activity Lifecycle Listener

    @Override
    public void onAttachedToActivity(@NonNull final ActivityPluginBinding binding)
    {
        // KNOWN ISSUE: onAttachedToEngine will be call twice, which may be caused by using
        // firebase_messaging plugin. See https://github.com/flutter/flutter/issues/97840
        // Once the issue is resolved, we can check if we can move following one lines to onAttachedToEngine.
        instance = this;
        lastActivityPluginBinding = binding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() { }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull final ActivityPluginBinding binding)
    {
        // KNOWN ISSUE: onAttachedToEngine will be call twice, which may be caused by using
        // firebase_messaging plugin. See https://github.com/flutter/flutter/issues/97840
        // Once the issue is resolved, we can check if we can move following one lines to onAttachedToEngine.
        instance = this;
    }

    @Override
    public void onDetachedFromActivity() { }

    private Activity getCurrentActivity()
    {
        return ( lastActivityPluginBinding != null ) ? lastActivityPluginBinding.getActivity() : null;
    }
}
