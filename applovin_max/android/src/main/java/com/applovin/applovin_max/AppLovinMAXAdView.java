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
    private static final Map<String, AppLovinMAXAdViewWidget> widgetInstances          = new HashMap<>( 2 );
    private static final Map<String, AppLovinMAXAdViewWidget> preloadedWidgetInstances = new HashMap<>( 2 );

    @Nullable
    private AppLovinMAXAdViewWidget widget;

    private final MethodChannel channel;

    public static MaxAdView getInstance(final String adUnitId)
    {
        AppLovinMAXAdViewWidget widget = preloadedWidgetInstances.get( adUnitId );
        if ( widget == null ) widget = widgetInstances.get( adUnitId );
        return ( widget != null ) ? widget.getAdView() : null;
    }

    public static void preloadWidgetAdView(final String adUnitId,
                                           final MaxAdFormat adFormat,
                                           @Nullable final String placement,
                                           @Nullable final String customData,
                                           @Nullable final Map<String, Object> extraParameters,
                                           @Nullable final Map<String, Object> localExtraParameters,
                                           final Result result,
                                           final AppLovinSdk sdk,
                                           final Context context)
    {
        AppLovinMAXAdViewWidget preloadedWidget = preloadedWidgetInstances.get( adUnitId );
        if ( preloadedWidget != null )
        {
            result.error( AppLovinMAX.TAG, "Cannot preload more than once for a single Ad Unit ID.", null );
            return;
        }

        preloadedWidget = new AppLovinMAXAdViewWidget( adUnitId, adFormat, true, sdk, context );
        preloadedWidgetInstances.put( adUnitId, preloadedWidget );

        preloadedWidget.setPlacement( placement );
        preloadedWidget.setCustomData( customData );
        preloadedWidget.setExtraParameters( extraParameters );
        preloadedWidget.setLocalExtraParameters( localExtraParameters );

        preloadedWidget.loadAd();

        result.success( null );
    }

    public static void destroyWidgetAdView(final String adUnitId, final Result result)
    {
        AppLovinMAXAdViewWidget preloadedWidget = preloadedWidgetInstances.get( adUnitId );
        if ( preloadedWidget == null )
        {
            result.error( AppLovinMAX.TAG, "No widget found to destroy", null );
            return;
        }

        if ( preloadedWidget.hasContainerView() )
        {
            result.error( AppLovinMAX.TAG, "Cannot destroy - currently in use", null );
            return;
        }

        preloadedWidgetInstances.remove( adUnitId );

        preloadedWidget.detachAdView();
        preloadedWidget.destroy();

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
                widget.setAutoRefresh( true );
                result.success( null );
            }
            else if ( "stopAutoRefresh".equals( call.method ) )
            {
                widget.setAutoRefresh( false );
                result.success( null );
            }
            else
            {
                result.notImplemented();
            }
        } );

        widget = preloadedWidgetInstances.get( adUnitId );
        if ( widget != null )
        {
            // Attach the preloaded widget if possible, otherwise create a new one for the
            // same adUnitId
            if ( !widget.hasContainerView() )
            {
                widget.setAutoRefresh( isAutoRefreshEnabled );
                widget.attachAdView( this );
                return;
            }
        }

        widget = new AppLovinMAXAdViewWidget( adUnitId, adFormat, sdk, context );
        widgetInstances.put( adUnitId, widget );

        widget.setPlacement( placement );
        widget.setCustomData( customData );
        widget.setExtraParameters( extraParameters );
        widget.setLocalExtraParameters( localExtraParameters );
        widget.setAutoRefresh( isAutoRefreshEnabled );

        widget.attachAdView( this );
        widget.loadAd();
    }

    /// Flutter Lifecycle Methods

    @Nullable
    @Override
    public View getView()
    {
        return widget != null ? widget.getAdView() : null;
    }

    @Override
    public void onFlutterViewAttached(@NonNull final View flutterView) { }

    @Override
    public void onFlutterViewDetached() { }

    @Override
    public void dispose()
    {
        if ( widget != null )
        {
            widget.detachAdView();

            AppLovinMAXAdViewWidget preloadedWidget = preloadedWidgetInstances.get( widget.getAdView().getAdUnitId() );

            if ( widget != preloadedWidget )
            {
                widgetInstances.remove( widget.getAdView().getAdUnitId() );
                widget.destroy();
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
