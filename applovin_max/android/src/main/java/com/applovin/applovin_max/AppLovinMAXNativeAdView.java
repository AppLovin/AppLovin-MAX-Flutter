package com.applovin.applovin_max;

import android.content.Context;
import android.graphics.Rect;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.applovin.impl.mediation.MaxErrorImpl;
import com.applovin.impl.sdk.utils.Utils;
import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.MaxErrorCode;
import com.applovin.mediation.nativeAds.MaxNativeAd;
import com.applovin.mediation.nativeAds.MaxNativeAdListener;
import com.applovin.mediation.nativeAds.MaxNativeAdLoader;
import com.applovin.mediation.nativeAds.MaxNativeAdView;
import com.applovin.sdk.AppLovinSdk;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class AppLovinMAXNativeAdView
        implements PlatformView, MaxAdRevenueListener
{
    private static final int TITLE_LABEL_TAG          = 1;
    private static final int MEDIA_VIEW_CONTAINER_TAG = 2;
    private static final int ICON_VIEW_TAG            = 3;
    private static final int BODY_VIEW_TAG            = 4;
    private static final int CALL_TO_ACTION_VIEW_TAG  = 5;
    private static final int ADVERTISER_VIEW_TAG      = 8;

    private final Context       context;
    private final MethodChannel channel;
    private final AppLovinSdk   sdk;

    @Nullable
    private       MaxNativeAdLoader adLoader;
    @Nullable
    private       MaxAd             nativeAd; // TODO: Maybe re-name to `ad`? Then for parity, we'd have to do the same in RN as well.
    private final AtomicBoolean     isLoading = new AtomicBoolean(); // Guard against repeated ad loads

    private final String adUnitId;
    @Nullable
    private final String placement;
    @Nullable
    private final String customData;

    private final FrameLayout nativeAdView;
    @Nullable
    private       View        titleView;
    @Nullable
    private       View        advertiserView;
    @Nullable
    private       View        bodyView;
    @Nullable
    private       View        callToActionView;
    @Nullable
    private       ImageView   iconView;
    @Nullable
    private       FrameLayout optionsViewContainer;
    @Nullable
    private       FrameLayout mediaViewContainer;

    private final List<View> clickableViews = new ArrayList<>();

    public AppLovinMAXNativeAdView(final int viewId,
                                   final String adUnitId,
                                   @Nullable final String placement,
                                   @Nullable final String customData,
                                   final BinaryMessenger messenger,
                                   final AppLovinSdk sdk,
                                   final Context context)
    {
        this.adUnitId = adUnitId;
        this.placement = placement;
        this.customData = customData;
        this.sdk = sdk;
        this.context = context;

        String uniqueChannelName = "applovin_max/nativeadview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        channel.setMethodCallHandler( (call, result) -> {

            if ( "addTitleView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addTitleView( rect );

                result.success( null );
            }
            else if ( "addAdvertiserView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addAdvertiserView( rect );

                result.success( null );
            }
            else if ( "addBodyView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addBodyView( rect );

                result.success( null );
            }
            else if ( "addCallToActionView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addCallToActionView( rect );

                result.success( null );
            }
            else if ( "addIconView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addIconView( rect );

                result.success( null );
            }
            else if ( "addOptionsView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addOptionsView( rect );

                result.success( null );
            }
            else if ( "addMediaView".equals( call.method ) )
            {
                Rect rect = getRect( call );
                addMediaView( rect );

                result.success( null );
            }
            // TODO: nit - rename to "renderAd" which is a bit more descriptive since we're registering clickable views and rendering the ad
            else if ( "completeViewAddition".equals( call.method ) )
            {
                completeViewAddition();

                result.success( null );
            }
            else if ( "load".equals( call.method ) )
            {
                loadAd();

                result.success( null );
            }
            else
            {
                result.notImplemented();
            }
        } );

        nativeAdView = new FrameLayout( context );

        loadAd();
    }

    /// Flutter Lifecycle Methods

    @Nullable
    @Override
    public View getView()
    {
        return nativeAdView;
    }

    @Override
    public void onFlutterViewAttached(@NonNull final View flutterView) { }

    @Override
    public void onFlutterViewDetached() { }

    @Override
    public void dispose()
    {
        maybeDestroyCurrentAd();

        if ( titleView != null )
        {
            nativeAdView.removeView( titleView );
        }

        if ( advertiserView != null )
        {
            nativeAdView.removeView( advertiserView );
        }

        if ( bodyView != null )
        {
            nativeAdView.removeView( bodyView );
        }

        if ( callToActionView != null )
        {
            nativeAdView.removeView( callToActionView );
        }

        if ( iconView != null )
        {
            nativeAdView.removeView( iconView );
        }

        if ( adLoader != null )
        {
            adLoader.destroy();
            adLoader = null;
        }

        if ( channel != null )
        {
            channel.setMethodCallHandler( null );
        }
    }

    private void loadAd()
    {
        if ( isLoading.compareAndSet( false, true ) )
        {
            AppLovinMAX.d( "Loading a native ad for Ad Unit ID: " + adUnitId + "..." );

            if ( adLoader == null || !adUnitId.equals( adLoader.getAdUnitId() ) )
            {
                adLoader = new MaxNativeAdLoader( adUnitId, sdk, context );
                adLoader.setRevenueListener( this );
                adLoader.setNativeAdListener( new NativeAdListener() );
            }

            adLoader.setPlacement( placement );
            adLoader.setCustomData( customData );

            adLoader.loadAd();
        }
        else
        {
            AppLovinMAX.e( "Ignoring request to load native ad for Ad Unit ID " + adUnitId + ", another ad load in progress" );
        }
    }

    /// Ad Loader Listener

    private class NativeAdListener
            extends MaxNativeAdListener
    {
        @Override
        public void onNativeAdLoaded(@Nullable final MaxNativeAdView nativeAdView, final MaxAd ad)
        {
            AppLovinMAX.d( "Native ad loaded: " + ad );

            // Log a warning if it is a template native ad returned - as our plugin will be responsible for re-rendering the native ad's assets
            if ( nativeAdView != null )
            {
                isLoading.set( false );

                AppLovinMAX.e( "Native ad is of template type, failing ad load..." );

                MaxErrorImpl error = new MaxErrorImpl( MaxErrorCode.AD_LOAD_FAILED, "Native ad is of template type" );
                AppLovinMAX.getInstance().fireErrorCallback( "OnNativeAdViewAdLoadFailedEvent", adUnitId, error, channel );

                return;
            }

            maybeDestroyCurrentAd();

            nativeAd = ad;

            sendEvent( "OnNativeAdViewAdLoadedEvent", ad );

            // TODO: Investigate parity with RN is possible re: slight delay vs more deterministic approach in Flutter (preferable)
            isLoading.set( false );
        }

        @Override
        public void onNativeAdLoadFailed(final String adUnitId, final MaxError error)
        {
            isLoading.set( false );

            AppLovinMAX.e( "Failed to load native ad for Ad Unit ID " + adUnitId + " with error: " + error );

            AppLovinMAX.getInstance().fireErrorCallback( "OnNativeAdViewAdLoadFailedEvent", adUnitId, error, channel );
        }

        @Override
        public void onNativeAdClicked(final MaxAd ad)
        {
            sendEvent( "OnNativeAdViewAdClickedEvent", ad );
        }
    }

    /// Ad Revenue Listener

    @Override
    public void onAdRevenuePaid(final MaxAd ad)
    {
        sendEvent( "OnNativeAdViewAdRevenuePaidEvent", ad );
    }

    /// Native Ad Component Methods

    private void addTitleView(final Rect rect)
    {
        // TODO: RN doesn't have `nativeAd == null` check, is it necessary here?
        if ( nativeAd == null || nativeAd.getNativeAd().getTitle() == null ) return;

        if ( titleView == null )
        {
            titleView = new View( context );
            titleView.setTag( TITLE_LABEL_TAG );
            nativeAdView.addView( titleView );

            clickableViews.add( titleView );
        }

        updateViewLayout( nativeAdView, titleView, rect );
    }

    private void addAdvertiserView(final Rect rect)
    {
        if ( nativeAd == null || nativeAd.getNativeAd().getAdvertiser() == null ) return;

        if ( advertiserView == null )
        {
            advertiserView = new View( context );
            advertiserView.setTag( ADVERTISER_VIEW_TAG );
            nativeAdView.addView( advertiserView );

            clickableViews.add( advertiserView );
        }

        updateViewLayout( nativeAdView, advertiserView, rect );
    }

    private void addBodyView(final Rect rect)
    {
        if ( nativeAd == null || nativeAd.getNativeAd().getBody() == null ) return;

        if ( bodyView == null )
        {
            bodyView = new View( context );
            bodyView.setTag( BODY_VIEW_TAG );
            nativeAdView.addView( bodyView );

            clickableViews.add( bodyView );
        }

        updateViewLayout( nativeAdView, bodyView, rect );
    }

    private void addCallToActionView(final Rect rect)
    {
        if ( nativeAd == null || nativeAd.getNativeAd().getCallToAction() == null ) return;

        if ( callToActionView == null )
        {
            callToActionView = new View( context );
            callToActionView.setTag( CALL_TO_ACTION_VIEW_TAG );
            nativeAdView.addView( callToActionView );

            clickableViews.add( callToActionView );
        }

        updateViewLayout( nativeAdView, callToActionView, rect );
    }

    private void addIconView(final Rect rect)
    {
        if ( nativeAd == null ) return;

        // TODO: On a new ad load, even if it does not have an app icon, we should clear out the icon set by the previous ad
        MaxNativeAd.MaxNativeAdImage icon = nativeAd.getNativeAd().getIcon();
        if ( icon == null ) return;

        if ( iconView == null )
        {
            iconView = new ImageView( context );
            iconView.setTag( ICON_VIEW_TAG );
            nativeAdView.addView( iconView );

            clickableViews.add( iconView );
        }

        updateViewLayout( nativeAdView, iconView, rect );

        if ( icon.getUri() != null )
        {
            // TODO: `Utils` is a private AppLovin SDK call, and also `getUri` will always returned a cached image so you can set directly
            Utils.setImageUrl( icon.getUri().toString(), iconView, sdk.coreSdk );
        }
        else if ( icon.getDrawable() != null )
        {
            iconView.setImageDrawable( icon.getDrawable() );
        }
    }

    private void addOptionsView(final Rect rect)
    {
        if ( nativeAd == null ) return;

        View optionsView = nativeAd.getNativeAd().getOptionsView();
        if ( optionsView == null ) return;

        if ( optionsViewContainer == null )
        {
            optionsViewContainer = new FrameLayout( context );
            // TODO: What is `setId()` for? `View.generateViewId()` is supposed on API17+ but we technically support API16+, we can bump it to min API 17 but I want to understand this functionality more
            optionsViewContainer.setId( View.generateViewId() );
            nativeAdView.addView( optionsViewContainer );
        }

        if ( optionsView.getParent() == null )
        {
            optionsViewContainer.addView( optionsView );

            optionsView.getLayoutParams().height = ViewGroup.LayoutParams.MATCH_PARENT;
            optionsView.getLayoutParams().width = ViewGroup.LayoutParams.MATCH_PARENT;
        }

        updateViewLayout( nativeAdView, optionsViewContainer, rect );
    }

    private void addMediaView(final Rect rect)
    {
        if ( nativeAd == null ) return;

        View mediaView = nativeAd.getNativeAd().getMediaView();
        if ( mediaView == null ) return;

        if ( mediaViewContainer == null )
        {
            mediaViewContainer = new FrameLayout( context );
            // TODO: What is `setId()` for? `View.generateViewId()` is supposed on API17+ but we technically support API16+, we can bump it to min API 17 but I want to understand this functionality more
            mediaViewContainer.setId( View.generateViewId() );
            mediaViewContainer.setTag( MEDIA_VIEW_CONTAINER_TAG );
            nativeAdView.addView( mediaViewContainer );
        }

        if ( mediaView.getParent() == null )
        {
            mediaViewContainer.addView( mediaView );

            mediaView.getLayoutParams().height = ViewGroup.LayoutParams.MATCH_PARENT;
            mediaView.getLayoutParams().width = ViewGroup.LayoutParams.MATCH_PARENT;
        }

        updateViewLayout( nativeAdView, mediaViewContainer, rect );
    }

    private void completeViewAddition()
    {
        if ( adLoader == null ) return;

        adLoader.a( clickableViews, nativeAdView, nativeAd );
        adLoader.b( nativeAd );
    }

    private void updateViewLayout(final ViewGroup parent, final View view, final Rect rect)
    {
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams( rect.width(), rect.height() );
        params.leftMargin = rect.left;
        params.topMargin = rect.top;
        parent.updateViewLayout( view, params );
    }

    private Rect getRect(final MethodCall call)
    {
        int x = call.argument( "x" );
        int y = call.argument( "y" );
        int width = call.argument( "width" );
        int height = call.argument( "height" );
        return new Rect( x, y, x + width, y + height );
    }

    /// Utility Methods

    private void sendEvent(final String event, final MaxAd ad)
    {
        // TODO: Do not re-use `getAdInfo` from `AppLovinMAX` since that is used for non-native ads - should we do what we do on RN `sendAdLoadedReactNativeEventForAd()`? Right now there's no parity.
        AppLovinMAX.getInstance().fireCallback( event, ad, channel );
    }

    private void maybeDestroyCurrentAd()
    {
        if ( nativeAd != null )
        {
            if ( mediaViewContainer != null )
            {
                mediaViewContainer.removeAllViews();
            }

            if ( optionsViewContainer != null )
            {
                optionsViewContainer.removeAllViews();
            }

            adLoader.destroy( nativeAd );

            nativeAd = null;
        }

        clickableViews.clear();
    }
}
