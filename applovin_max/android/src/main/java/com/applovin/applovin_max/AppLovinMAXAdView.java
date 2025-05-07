package com.applovin.applovin_max;

import android.content.Context;
import android.view.View;

import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.ads.MaxAdView;

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
    private static final Map<Integer, AppLovinMAXAdViewWidget> widgetInstances          = new HashMap<>( 2 );
    private static final Map<Integer, AppLovinMAXAdViewWidget> preloadedWidgetInstances = new HashMap<>( 2 );

    @Nullable
    private       AppLovinMAXAdViewWidget widget;
    private final int                     adViewId;

    private final MethodChannel channel;

    // Returns an MaxAdView to support Amazon integrations. This method returns the first instance
    // that matches the Ad Unit ID, consistent with the behavior introduced when this feature was
    // first implemented.
    @Nullable
    public static MaxAdView getInstance(final String adUnitId)
    {
        for ( Map.Entry<Integer, AppLovinMAXAdViewWidget> entry : preloadedWidgetInstances.entrySet() )
        {
            if ( entry.getValue().getAdUnitId().equals( adUnitId ) )
            {
                return entry.getValue().getAdView();
            }
        }

        for ( Map.Entry<Integer, AppLovinMAXAdViewWidget> entry : widgetInstances.entrySet() )
        {
            if ( entry.getValue().getAdUnitId().equals( adUnitId ) )
            {
                return entry.getValue().getAdView();
            }
        }

        return null;
    }

    public static void preloadWidgetAdView(final String adUnitId,
                                           final MaxAdFormat adFormat,
                                           final boolean isAdaptiveBannerEnabled,
                                           @Nullable final String placement,
                                           @Nullable final String customData,
                                           @Nullable final Map<String, Object> extraParameters,
                                           @Nullable final Map<String, Object> localExtraParameters,
                                           final Result result,
                                           final Context context)
    {
        AppLovinMAXAdViewWidget preloadedWidget = new AppLovinMAXAdViewWidget( adUnitId, adFormat, isAdaptiveBannerEnabled, context, true );
        preloadedWidgetInstances.put( preloadedWidget.hashCode(), preloadedWidget );

        preloadedWidget.setPlacement( placement );
        preloadedWidget.setCustomData( customData );
        preloadedWidget.setExtraParameters( extraParameters );
        preloadedWidget.setLocalExtraParameters( localExtraParameters );

        preloadedWidget.loadAd();

        result.success( preloadedWidget.hashCode() );
    }

    public static void destroyWidgetAdView(final int adViewId, final Result result)
    {
        AppLovinMAXAdViewWidget preloadedWidget = preloadedWidgetInstances.get( adViewId );
        if ( preloadedWidget == null )
        {
            result.error( AppLovinMAX.TAG, "No preloaded AdView found to destroy", null );
            return;
        }

        if ( preloadedWidget.hasContainerView() )
        {
            result.error( AppLovinMAX.TAG, "Cannot destroy - the preloaded AdView is currently in use", null );
            return;
        }

        preloadedWidgetInstances.remove( adViewId );

        preloadedWidget.detachAdView();
        preloadedWidget.destroy();

        result.success( null );
    }

    public AppLovinMAXAdView(final int viewId,
                             final String adUnitId,
                             final int adViewId,
                             final MaxAdFormat adFormat,
                             final boolean isAdaptiveBannerEnabled,
                             final boolean isAutoRefreshEnabled,
                             @Nullable final String placement,
                             @Nullable final String customData,
                             @Nullable final Map<String, Object> extraParameters,
                             @Nullable final Map<String, Object> localExtraParameters,
                             final BinaryMessenger messenger,
                             final Context context)
    {
        String uniqueChannelName = "applovin_max/adview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        channel.setMethodCallHandler( (call, result) -> {
            if ( "startAutoRefresh".equals( call.method ) )
            {
                widget.setAutoRefreshEnabled( true );
                result.success( null );
            }
            else if ( "stopAutoRefresh".equals( call.method ) )
            {
                widget.setAutoRefreshEnabled( false );
                result.success( null );
            }
            else
            {
                result.notImplemented();
            }
        } );

        widget = preloadedWidgetInstances.get( adViewId );
        if ( widget != null )
        {
            // Attach the preloaded widget if possible, otherwise create a new one for the
            // same adUnitId
            if ( !widget.hasContainerView() )
            {
                AppLovinMAX.d( "Mounting the preloaded AdView (" + adViewId + ") for Ad Unit ID " + adUnitId );

                this.adViewId = adViewId;
                widget.setAutoRefreshEnabled( isAutoRefreshEnabled );
                widget.attachAdView( this );
                return;
            }
        }

        widget = new AppLovinMAXAdViewWidget( adUnitId, adFormat, isAdaptiveBannerEnabled, context );
        this.adViewId = widget.hashCode();
        widgetInstances.put( this.adViewId, widget );

        AppLovinMAX.d( "Mounting a new AdView (" + this.adViewId + ") for Ad Unit ID " + adUnitId );

        widget.setPlacement( placement );
        widget.setCustomData( customData );
        widget.setExtraParameters( extraParameters );
        widget.setLocalExtraParameters( localExtraParameters );
        widget.setAutoRefreshEnabled( isAutoRefreshEnabled );

        widget.attachAdView( this );
        widget.loadAd();
    }

    /// Flutter Lifecycle Methods

    @Nullable
    @Override
    public View getView()
    {
        return widget;
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

            AppLovinMAXAdViewWidget preloadedWidget = preloadedWidgetInstances.get( adViewId );

            if ( widget == preloadedWidget )
            {
                AppLovinMAX.d( "Unmounting the preloaded AdView (" + adViewId + ") for Ad Unit ID " + widget.getAdUnitId() );

                widget.setAutoRefreshEnabled( false );
            }
            else
            {
                AppLovinMAX.d( "Unmounting the AdView (" + adViewId + ") to destroy for Ad Unit ID " + widget.getAdUnitId() );

                widgetInstances.remove( adViewId );
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
