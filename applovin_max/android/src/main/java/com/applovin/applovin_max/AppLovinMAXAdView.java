package com.applovin.applovin_max;

import android.content.Context;
import android.view.View;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.sdk.AppLovinSdk;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

/**
 * Created by Thomas So on July 17 2022
 */
public class AppLovinMAXAdView
        implements PlatformView, MaxAdViewAdListener, MaxAdRevenueListener
{
    private final MethodChannel channel;
    private final MaxAdView     adView;

    public AppLovinMAXAdView(final int viewId,
                             final String adUnitId,
                             final MaxAdFormat adFormat,
                             final boolean isAutoRefreshEnabled,
                             @Nullable final String placement,
                             @Nullable final String customData,
                             final BinaryMessenger messenger,
                             final AppLovinSdk sdk,
                             final Context context)
    {
        String uniqueChannelName = "applovin_max/adview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        channel.setMethodCallHandler( new MethodChannel.MethodCallHandler()
        {
            @Override
            public void onMethodCall(@NonNull final MethodCall call, @NonNull final MethodChannel.Result result)
            {
                if ( "startAutoRefresh".equals( call.method ) )
                {
                    adView.startAutoRefresh();
                    result.success( null );
                }
                else if ( "stopAutoRefresh".equals( call.method ) )
                {
                    adView.stopAutoRefresh();
                    result.success( null );
                }
                else
                {
                    result.notImplemented();
                }
            }
        } );

        adView = new MaxAdView( adUnitId, adFormat, sdk, context );
        adView.setListener( this );
        adView.setRevenueListener( this );

        adView.setPlacement( placement );
        adView.setCustomData( customData );

        adView.setExtraParameter( "allow_pause_auto_refresh_immediately", "true" );

        adView.loadAd();

        if ( !isAutoRefreshEnabled )
        {
            adView.stopAutoRefresh();
        }
    }

    @Nullable
    @Override
    public View getView()
    {
        return adView;
    }

    @Override
    public void onFlutterViewAttached(@NonNull final View flutterView) { }

    @Override
    public void onFlutterViewDetached() { }

    @Override
    public void dispose()
    {
        if ( adView != null )
        {
            adView.destroy();
            adView.setListener( null );
            adView.setRevenueListener( null );
        }

        if ( channel != null )
        {
            channel.setMethodCallHandler( null );
        }
    }

    @Override
    public void onAdLoaded(final MaxAd ad)
    {
        sendEvent( "OnAdViewAdLoadedEvent", ad );
    }

    @Override
    public void onAdLoadFailed(final String adUnitId, final MaxError error)
    {
        AppLovinMAX.getInstance().fireErrorCallback( "OnAdViewAdLoadFailedEvent", adUnitId, error, channel );
    }

    @Override
    public void onAdClicked(final MaxAd ad)
    {
        sendEvent( "OnAdViewAdClickedEvent", ad );
    }

    @Override
    public void onAdExpanded(final MaxAd ad)
    {
        sendEvent( "OnAdViewAdExpandedEvent", ad );
    }

    @Override
    public void onAdCollapsed(final MaxAd ad)
    {
        sendEvent( "OnAdViewAdCollapsedEvent", ad );
    }

    @Override
    public void onAdDisplayed(final MaxAd ad) { }

    @Override
    public void onAdDisplayFailed(final MaxAd ad, final MaxError error) { }

    @Override
    public void onAdHidden(final MaxAd ad) { }

    @Override
    public void onAdRevenuePaid(final MaxAd ad)
    {
        sendEvent( "OnAdViewAdRevenuePaidEvent", ad );
    }

    private void sendEvent(final String event, final MaxAd ad)
    {
        AppLovinMAX.getInstance().fireCallback( event, ad, channel );
    }
}
