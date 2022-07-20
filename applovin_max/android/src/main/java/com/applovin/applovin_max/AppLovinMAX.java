package com.applovin.applovin_max;

import android.app.Activity;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Point;
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
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.MaxReward;
import com.applovin.mediation.MaxRewardedAdListener;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.mediation.ads.MaxInterstitialAd;
import com.applovin.mediation.ads.MaxRewardedAd;
import com.applovin.sdk.AppLovinMediationProvider;
import com.applovin.sdk.AppLovinPrivacySettings;
import com.applovin.sdk.AppLovinSdk;
import com.applovin.sdk.AppLovinSdkConfiguration;
import com.applovin.sdk.AppLovinSdkSettings;
import com.applovin.sdk.AppLovinSdkUtils;
import com.applovin.sdk.AppLovinUserService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
        implements FlutterPlugin, MethodCallHandler, ActivityAware, MaxAdListener, MaxAdViewAdListener, MaxRewardedAdListener
{
    private static final String SDK_TAG = "AppLovinSdk";
    private static final String TAG     = "AppLovinMAX";

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
    private String       userIdToSet;
    private List<String> testDeviceAdvertisingIdsToSet;
    private Boolean      verboseLoggingToSet;
    private Boolean      creativeDebuggerEnabledToSet;

    // Fullscreen Ad Fields
    private final Map<String, MaxInterstitialAd> mInterstitials = new HashMap<>( 2 );
    private final Map<String, MaxRewardedAd>     mRewardedAds   = new HashMap<>( 2 );

    // Banner Fields
    private final Map<String, MaxAdView>   mAdViews                    = new HashMap<>( 2 );
    private final Map<String, MaxAdFormat> mAdViewAdFormats            = new HashMap<>( 2 );
    private final Map<String, String>      mAdViewPositions            = new HashMap<>( 2 );
    private final List<String>             mAdUnitIdsToShowAfterCreate = new ArrayList<>( 2 );

    public static AppLovinMAX getInstance()
    {
        return instance;
    }

    public AppLovinSdk getSdk()
    {
        return sdk;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding)
    {
        instance = this;

        applicationContext = binding.getApplicationContext();

        sharedChannel = new MethodChannel( binding.getBinaryMessenger(), "applovin_max" );
        sharedChannel.setMethodCallHandler( this );

        AppLovinMAXAdViewFactory adViewFactory = new AppLovinMAXAdViewFactory( binding.getBinaryMessenger() );
        binding.getPlatformViewRegistry().registerViewFactory( "applovin_max/adview", adViewFactory );
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding)
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

        // Initialize SDK
        sdk = AppLovinSdk.getInstance( sdkKeyToUse, new AppLovinSdkSettings( applicationContext ), applicationContext );
        sdk.setPluginVersion( "Flutter-" + pluginVersion );
        sdk.setMediationProvider( AppLovinMediationProvider.MAX );

        // Set user id if needed
        if ( !TextUtils.isEmpty( userIdToSet ) )
        {
            sdk.setUserIdentifier( userIdToSet );
            userIdToSet = null;
        }

        // Set test device ids if needed
        if ( testDeviceAdvertisingIdsToSet != null )
        {
            sdk.getSettings().setTestDeviceAdvertisingIds( testDeviceAdvertisingIdsToSet );
            testDeviceAdvertisingIdsToSet = null;
        }

        // Set verbose logging state if needed
        if ( verboseLoggingToSet != null )
        {
            sdk.getSettings().setVerboseLogging( verboseLoggingToSet );
            verboseLoggingToSet = null;
        }

        // Set creative debugger enabled if needed.
        if ( creativeDebuggerEnabledToSet != null )
        {
            sdk.getSettings().setCreativeDebuggerEnabled( creativeDebuggerEnabledToSet );
            creativeDebuggerEnabledToSet = null;
        }

        sdk.initializeSdk( configuration -> {

            d( "SDK initialized" );

            sdkConfiguration = configuration;
            isSdkInitialized = true;

            Map<String, Object> sdkConfiguration = new HashMap<>( 2 );
            sdkConfiguration.put( "consentDialogState", configuration.getConsentDialogState().ordinal() );
            sdkConfiguration.put( "countryCode", configuration.getCountryCode() );

            result.success( sdkConfiguration );
        } );
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
        if ( !isPluginInitialized ) return;

        sdk.getSettings().setMuted( muted );
    }

    public boolean isMuted()
    {
        if ( !isPluginInitialized ) return false;

        return sdk.getSettings().isMuted();
    }

    public void setVerboseLogging(final boolean verboseLoggingEnabled)
    {
        if ( isPluginInitialized )
        {
            sdk.getSettings().setVerboseLogging( verboseLoggingEnabled );
            verboseLoggingToSet = null;
        }
        else
        {
            verboseLoggingToSet = verboseLoggingEnabled;
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

    public void destroyBanner(final String adUnitId)
    {
        destroyAdView( adUnitId, getDeviceSpecificBannerAdViewAdFormat() );
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

    public void showMRec(final String adUnitId)
    {
        showAdView( adUnitId, MaxAdFormat.MREC );
    }

    public void hideMRec(final String adUnitId)
    {
        hideAdView( adUnitId, MaxAdFormat.MREC );
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

    public void showInterstitial(final String adUnitId, final String placement)
    {
        MaxInterstitialAd interstitial = retrieveInterstitial( adUnitId );
        interstitial.showAd( placement );
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

    public void showRewardedAd(final String adUnitId, final String placement)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        rewardedAd.showAd( placement );
    }

    public void setRewardedAdExtraParameter(final String adUnitId, final String key, final String value)
    {
        MaxRewardedAd rewardedAd = retrieveRewardedAd( adUnitId );
        rewardedAd.setExtraParameter( key, value );
    }

    // AD CALLBACKS

    @Override
    public void onAdLoaded(MaxAd ad)
    {
        String name;
        MaxAdFormat adFormat = ad.getFormat();
        if ( MaxAdFormat.BANNER == adFormat || MaxAdFormat.LEADER == adFormat || MaxAdFormat.MREC == adFormat )
        {
            name = ( MaxAdFormat.MREC == adFormat ) ? "OnMRecAdLoadedEvent" : "OnBannerAdLoadedEvent";

            String adViewPosition = mAdViewPositions.get( ad.getAdUnitId() );
            if ( !TextUtils.isEmpty( adViewPosition ) )
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
        else
        {
            logStackTrace( new IllegalStateException( "invalid adUnitId: " + adUnitId ) );
            return;
        }

        try
        {
            Map<String, String> params = new HashMap<>( 3 );
            params.put( "adUnitId", adUnitId );
            params.put( "errorCode", Integer.toString( error.getCode() ) );
            params.put( "errorMessage", error.getMessage() );
            fireCallback( name, params );
        }
        catch ( Throwable ignored ) { }
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
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED ) return;

        final String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialDisplayedEvent";
        }
        else // REWARDED
        {
            name = "OnRewardedAdDisplayedEvent";
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdDisplayFailed(final MaxAd ad, final MaxError error)
    {
        // BMLs do not support [DISPLAY] events
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED ) return;

        final String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialAdFailedToDisplayEvent";
        }
        else // REWARDED
        {
            name = "OnRewardedAdFailedToDisplayEvent";
        }

        try
        {
            Map<String, String> params = getAdInfo( ad );
            params.put( "errorCode", Integer.toString( error.getCode() ) );
            params.put( "errorMessage", error.getMessage() );
            fireCallback( name, params );
        }
        catch ( Throwable ignored ) { }
    }

    @Override
    public void onAdHidden(final MaxAd ad)
    {
        // BMLs do not support [HIDDEN] events
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.INTERSTITIAL && adFormat != MaxAdFormat.REWARDED ) return;

        String name;
        if ( MaxAdFormat.INTERSTITIAL == adFormat )
        {
            name = "OnInterstitialHiddenEvent";
        }
        else // REWARDED
        {
            name = "OnRewardedAdHiddenEvent";
        }

        fireCallback( name, getAdInfo( ad ) );
    }

    @Override
    public void onAdExpanded(final MaxAd ad)
    {
        final MaxAdFormat adFormat = ad.getFormat();
        if ( adFormat != MaxAdFormat.BANNER && adFormat != MaxAdFormat.LEADER && adFormat != MaxAdFormat.MREC )
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
        if ( adFormat != MaxAdFormat.BANNER && adFormat != MaxAdFormat.LEADER && adFormat != MaxAdFormat.MREC )
        {
            logInvalidAdFormat( adFormat );
            return;
        }

        fireCallback( ( MaxAdFormat.MREC == adFormat ) ? "OnMRecAdCollapsedEvent" : "OnBannerAdCollapsedEvent", getAdInfo( ad ) );
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
        final String rewardAmount = Integer.toString( reward != null ? reward.getAmount() : 0 );

        try
        {
            Map<String, String> params = getAdInfo( ad );
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

        // The publisher may have requested to show the banner before it was created. Now that the banner is created, show it.
        if ( mAdUnitIdsToShowAfterCreate.contains( adUnitId ) )
        {
            showAdView( adUnitId, adFormat );
            mAdUnitIdsToShowAfterCreate.remove( adUnitId );
        }
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
        e( "ERROR: Failed to execute " + callingMethod + "() - please ensure the AppLovin MAX Flutter plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!" );
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

    private MaxInterstitialAd retrieveInterstitial(String adUnitId)
    {
        MaxInterstitialAd result = mInterstitials.get( adUnitId );
        if ( result == null )
        {
            result = new MaxInterstitialAd( adUnitId, sdk, getCurrentActivity() );
            result.setListener( this );

            mInterstitials.put( adUnitId, result );
        }

        return result;
    }

    private MaxRewardedAd retrieveRewardedAd(String adUnitId)
    {
        MaxRewardedAd result = mRewardedAds.get( adUnitId );
        if ( result == null )
        {
            result = MaxRewardedAd.getInstance( adUnitId, sdk, getCurrentActivity() );
            result.setListener( this );

            mRewardedAds.put( adUnitId, result );
        }

        return result;
    }

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

            mAdViews.put( adUnitId, result );
            mAdViewPositions.put( adUnitId, adViewPosition );
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

    private Map<String, String> getAdInfo(final MaxAd ad)
    {
        Map<String, String> adInfo = new HashMap<>( 6 );
        adInfo.put( "adUnitId", ad.getAdUnitId() );
        adInfo.put( "creativeId", !TextUtils.isEmpty( ad.getCreativeId() ) ? ad.getCreativeId() : "" );
        adInfo.put( "networkName", ad.getNetworkName() );
        adInfo.put( "placement", !TextUtils.isEmpty( ad.getPlacement() ) ? ad.getPlacement() : "" );
        adInfo.put( "revenue", Double.toString( ad.getRevenue() ) );
        adInfo.put( "dspName", !TextUtils.isEmpty( ad.getDspName() ) ? ad.getDspName() : "" );

        return adInfo;
    }

    private static Point getOffsetPixels(final float xDp, final float yDp, final Context context)
    {
        return new Point( AppLovinSdkUtils.dpToPx( context, (int) xDp ), AppLovinSdkUtils.dpToPx( context, (int) yDp ) );
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
        else if ( "setTestDeviceAdvertisingIds".equals( call.method ) )
        {
            List<String> testDeviceAdvertisingIds = call.argument( "value" );
            setTestDeviceAdvertisingIds( testDeviceAdvertisingIds );

            result.success( null );
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
        else if ( "destroyBanner".equals( call.method ) )
        {
            String adUnitId = call.argument( "ad_unit_id" );
            destroyBanner( adUnitId );

            result.success( null );
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
            showInterstitial( adUnitId, placement );

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
            showRewardedAd( adUnitId, placement );

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
        else
        {
            result.notImplemented();
        }
    }

    public void fireCallback(final String name, final MaxAd ad, final MethodChannel channel)
    {
        fireCallback( name, getAdInfo( ad ), channel );
    }

    public void fireCallback(final String name, final Map<String, String> params)
    {
        fireCallback( name, params, sharedChannel );
    }

    public void fireCallback(final String name, final Map<String, String> params, final MethodChannel channel)
    {
        channel.invokeMethod( name, params );
    }

    // Activity Lifecycle Listener

    @Override
    public void onAttachedToActivity(@NonNull final ActivityPluginBinding binding)
    {
        lastActivityPluginBinding = binding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() { }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull final ActivityPluginBinding binding) { }

    @Override
    public void onDetachedFromActivity() { }

    private Activity getCurrentActivity()
    {
        return ( lastActivityPluginBinding != null ) ? lastActivityPluginBinding.getActivity() : null;
    }
}
