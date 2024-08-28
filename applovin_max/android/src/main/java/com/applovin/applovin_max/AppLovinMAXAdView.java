package com.applovin.applovin_max;

import android.content.Context;
import android.view.View;

import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.sdk.AppLovinSdk;

import java.util.HashMap;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

/**
 * Created by Thomas So on July 17 2022
 */
public class AppLovinMAXAdView
        implements PlatformView
{
    private static final Map<String, AppLovinMAXAdViewPlatformWidget> platformWidgetInstances          = new HashMap<>( 2 );
    private static final Map<String, AppLovinMAXAdViewPlatformWidget> preloadedPlatformWidgetInstances = new HashMap<>( 2 );

    @Nullable
    private AppLovinMAXAdViewPlatformWidget platformWidget;

    private final MethodChannel channel;

    public static MaxAdView getInstance(final String adUnitId)
    {
        AppLovinMAXAdViewPlatformWidget platformWidget = preloadedPlatformWidgetInstances.get( adUnitId );
        if ( platformWidget == null ) platformWidget = platformWidgetInstances.get( adUnitId );
        return ( platformWidget != null ) ? platformWidget.getAdView() : null;
    }

    public static void preloadPlatformWidgetAdView(final String adUnitId,
                                                   final MaxAdFormat adFormat,
                                                   @Nullable final String placement,
                                                   @Nullable final String customData,
                                                   @Nullable final Map<String, Object> extraParameters,
                                                   @Nullable final Map<String, Object> localExtraParameters,
                                                   final Result result,
                                                   final AppLovinSdk sdk,
                                                   final Context context)
    {
        AppLovinMAXAdViewPlatformWidget preloadedPlatformWidget = preloadedPlatformWidgetInstances.get( adUnitId );
        if ( preloadedPlatformWidget != null )
        {
            result.error( AppLovinMAX.TAG, "Cannot preload more than once for a single Ad Unit ID.", null );
            return;
        }

        preloadedPlatformWidget = new AppLovinMAXAdViewPlatformWidget( adUnitId, adFormat, true, sdk, context );
        preloadedPlatformWidgetInstances.put( adUnitId, preloadedPlatformWidget );

        preloadedPlatformWidget.setPlacement( placement );
        preloadedPlatformWidget.setCustomData( customData );
        preloadedPlatformWidget.setExtraParameters( extraParameters );
        preloadedPlatformWidget.setLocalExtraParameters( localExtraParameters );

        preloadedPlatformWidget.loadAd();

        result.success( null );
    }

    public static void destroyPlatformWidgetAdView(final String adUnitId, final Result result)
    {
        AppLovinMAXAdViewPlatformWidget preloadedPlatformWidget = preloadedPlatformWidgetInstances.get( adUnitId );
        if ( preloadedPlatformWidget == null )
        {
            result.error( AppLovinMAX.TAG, "No platform widget found to destroy", null );
            return;
        }

        if ( preloadedPlatformWidget.hasContainerView() )
        {
            result.error( AppLovinMAX.TAG, "Cannot destroy - currently in use", null );
            return;
        }

        preloadedPlatformWidgetInstances.remove( adUnitId );

        preloadedPlatformWidget.detachAdView();
        preloadedPlatformWidget.destroy();

        result.success( null );
    }

    public AppLovinMAXAdView(final int viewId,
                             final String adUnitId,
                             final MaxAdFormat adFormat,
                             final boolean isAutoRefreshEnabled,
                             @Nullable final String placement,
                             @Nullable final String customData,
                             @Nullable final Map<String, Object> extraParameters,
                             @Nullable final Map<String, Object> localExtraParameters,
                             final BinaryMessenger messenger,
                             final AppLovinSdk sdk,
                             final Context context)
    {
        String uniqueChannelName = "applovin_max/adview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        channel.setMethodCallHandler( (call, result) -> {
            if ( "startAutoRefresh".equals( call.method ) )
            {
                platformWidget.setAutoRefresh( true );
                result.success( null );
            }
            else if ( "stopAutoRefresh".equals( call.method ) )
            {
                platformWidget.setAutoRefresh( false );
                result.success( null );
            }
            else
            {
                result.notImplemented();
            }
        } );

        platformWidget = preloadedPlatformWidgetInstances.get( adUnitId );
        if ( platformWidget != null )
        {
            // Attach the preloaded widget if possible, otherwise create a new one for the
            // same adUnitId
            if ( !platformWidget.hasContainerView() )
            {
                platformWidget.setAutoRefresh( isAutoRefreshEnabled );
                platformWidget.attachAdView( this );
                return;
            }
        }

        platformWidget = new AppLovinMAXAdViewPlatformWidget( adUnitId, adFormat, sdk, context );
        platformWidgetInstances.put( adUnitId, platformWidget );

        platformWidget.setPlacement( placement );
        platformWidget.setCustomData( customData );
        platformWidget.setExtraParameters( extraParameters );
        platformWidget.setLocalExtraParameters( localExtraParameters );
        platformWidget.setAutoRefresh( isAutoRefreshEnabled );

        platformWidget.attachAdView( this );
        platformWidget.loadAd();
    }

    /// Flutter Lifecycle Methods

    @Nullable
    @Override
    public View getView()
    {
        return platformWidget != null ? platformWidget.getAdView() : null;
    }

    @Override
    public void onFlutterViewAttached(@NonNull final View flutterView) { }

    @Override
    public void onFlutterViewDetached() { }

    @Override
    public void dispose()
    {
        if ( platformWidget != null )
        {
            platformWidget.detachAdView();

            AppLovinMAXAdViewPlatformWidget preloadedPlatformWidget = preloadedPlatformWidgetInstances.get( platformWidget.getAdView().getAdUnitId() );

            if ( platformWidget != preloadedPlatformWidget )
            {
                platformWidgetInstances.remove( platformWidget.getAdView().getAdUnitId() );
                platformWidget.destroy();
            }
        }

        if ( channel != null )
        {
            channel.setMethodCallHandler( null );
        }
    }

    public void sendEvent(final String event, final Map<String, Object> params)
    {
        AppLovinMAX.getInstance().fireCallback( event, params, channel );
    }
}
