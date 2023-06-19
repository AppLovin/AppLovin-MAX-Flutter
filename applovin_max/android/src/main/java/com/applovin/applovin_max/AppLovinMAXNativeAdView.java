package com.applovin.applovin_max;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.applovin.impl.mediation.MaxErrorImpl;
import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.MaxErrorCode;
import com.applovin.mediation.nativeAds.MaxNativeAd;
import com.applovin.mediation.nativeAds.MaxNativeAdListener;
import com.applovin.mediation.nativeAds.MaxNativeAdLoader;
import com.applovin.mediation.nativeAds.MaxNativeAdView;
import com.applovin.sdk.AppLovinSdk;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.util.HandlerCompat;

public class AppLovinMAXNativeAdView
        implements PlatformView, MethodChannel.MethodCallHandler, MaxAdRevenueListener
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
    private       MaxAd             ad;
    @Nullable
    private       MaxNativeAd       nativeAd;
    private final AtomicBoolean     isLoading = new AtomicBoolean(); // Guard against repeated ad loads

    private String adUnitId;
    @Nullable
    private String placement;
    @Nullable
    private String customData;

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

    private interface AddComponent
    {
        void add(Rect rect);
    }

    private final Map<String, AddComponent> componentCommands = new HashMap<>();

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

        componentCommands.put( "addTitleView", this::addTitleView );
        componentCommands.put( "addAdvertiserView", this::addAdvertiserView );
        componentCommands.put( "addBodyView", this::addBodyView );
        componentCommands.put( "addCallToActionView", this::addCallToActionView );
        componentCommands.put( "addIconView", this::addIconView );
        componentCommands.put( "addOptionsView", this::addOptionsView );
        componentCommands.put( "addMediaView", this::addMediaView );

        String uniqueChannelName = "applovin_max/nativeadview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        channel.setMethodCallHandler( this );

        nativeAdView = new FrameLayout( context );

        loadAd();
    }

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
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final MethodChannel.Result result)
    {
        AddComponent addComponent = componentCommands.get( call.method );
        if ( addComponent != null )
        {
            int x = call.argument( "x" );
            int y = call.argument( "y" );
            int width = call.argument( "width" );
            int height = call.argument( "height" );
            Rect rect = new Rect( x, y, x + width, y + height );
            addComponent.add( rect );
            result.success( null );
        }
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
    }

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
        }

        if ( channel != null )
        {
            channel.setMethodCallHandler( null );
        }
    }

    // Ad Loader

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
    }

    private void maybeDestroyCurrentAd()
    {
        if ( ad != null )
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
            }

            if ( adLoader != null )
            {
                adLoader.destroy( ad );
            }

            nativeAd = null;
            ad = null;
        }
    }

    // Ad Loader Listener

    class NativeAdListener
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

            AppLovinMAXNativeAdView.this.ad = ad;
            nativeAd = ad.getNativeAd();

            sendEvent( "OnNativeAdViewAdLoadedEvent", ad );

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

    @Override
    public void onAdRevenuePaid(final MaxAd ad)
    {
        sendEvent( "OnNativeAdViewAdRevenuePaidEvent", ad );
    }

    private void sendEvent(final String event, final MaxAd ad)
    {
        AppLovinMAX.getInstance().fireCallback( event, ad, channel );
    }

    // Native Ad Components

    private void addTitleView(final Rect rect)
    {
        if ( nativeAd == null || nativeAd.getTitle() == null ) return;

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
        if ( nativeAd == null || nativeAd.getAdvertiser() == null ) return;

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
        if ( nativeAd == null || nativeAd.getBody() == null ) return;

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
        if ( nativeAd == null || nativeAd.getCallToAction() == null ) return;

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
        MaxNativeAd.MaxNativeAdImage icon = nativeAd != null ? nativeAd.getIcon() : null;

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
            // FIXME: do we have an utility for this???
            Runnable download = () -> {
                try
                {
                    InputStream in = new java.net.URL( icon.getUri().toString() ).openStream();
                    Bitmap bitmap = BitmapFactory.decodeStream( in );

                    HandlerCompat.createAsyncHandler( Looper.getMainLooper() ).post( () -> iconView.setImageBitmap( bitmap ) );
                }
                catch ( Exception e )
                {
                }
            };

            Executors.newSingleThreadExecutor().execute( download );
        }
        else if ( icon.getDrawable() != null )
        {
            iconView.setImageDrawable( icon.getDrawable() );
        }
    }

    private void addOptionsView(final Rect rect)
    {
        if ( nativeAd == null || nativeAd.getOptionsView() == null ) return;

        if ( optionsViewContainer == null )
        {
            optionsViewContainer = new FrameLayout( context );
            optionsViewContainer.setId( View.generateViewId() );
            nativeAdView.addView( optionsViewContainer );
        }

        View optionsView = nativeAd.getOptionsView();

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
        if ( nativeAd == null || nativeAd.getMediaView() == null ) return;

        if ( mediaViewContainer == null )
        {
            mediaViewContainer = new FrameLayout( context );
            mediaViewContainer.setId( View.generateViewId() );
            mediaViewContainer.setTag( MEDIA_VIEW_CONTAINER_TAG );
            nativeAdView.addView( mediaViewContainer );
        }

        View mediaView = nativeAd.getMediaView();

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
        if ( adLoader != null )
        {
            adLoader.a( clickableViews, nativeAdView, ad );
            adLoader.b( ad );
        }
    }

    private void updateViewLayout(ViewGroup parent, View view, Rect rect)
    {
        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams( rect.width(), rect.height() );
        params.leftMargin = rect.left;
        params.topMargin = rect.top;
        parent.updateViewLayout( view, params );
    }
}
