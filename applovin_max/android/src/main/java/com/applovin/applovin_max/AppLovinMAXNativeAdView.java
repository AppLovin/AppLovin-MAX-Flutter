package com.applovin.applovin_max;

import android.content.Context;
import android.view.View;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.mediation.nativeAds.MaxNativeAdListener;
import com.applovin.mediation.nativeAds.MaxNativeAdLoader;
import com.applovin.mediation.nativeAds.MaxNativeAdView;
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
public class AppLovinMAXNativeAdView extends MaxNativeAdListener
    implements PlatformView, MaxAdRevenueListener
{
    private final MethodChannel channel;

    private final MaxNativeAdLoader nativeAdLoader;
    private final MaxNativeAdView adView;

    private MaxAd nativeAd;

    public AppLovinMAXNativeAdView(final int viewId,
                             final String adUnitId,
                             final String adTemplate,
                             @Nullable final String placement,
                             @Nullable final String customData,
                             final BinaryMessenger messenger,
                             final AppLovinSdk sdk,
                             final Context context)
    {
        String uniqueChannelName = "applovin_max/adview_" + viewId;
        channel = new MethodChannel( messenger, uniqueChannelName );
        nativeAdLoader = new MaxNativeAdLoader(adUnitId, sdk, context);
        nativeAdLoader.setNativeAdListener(this);
        nativeAdLoader.setRevenueListener(this);
        nativeAdLoader.setPlacement(placement);
        nativeAdLoader.setCustomData(customData);

        adView = new MaxNativeAdView( adTemplate, context );

        channel.setMethodCallHandler( new MethodChannel.MethodCallHandler()
        {
            @Override
            public void onMethodCall(@NonNull final MethodCall call, @NonNull final MethodChannel.Result result)
            {
                if ( "load".equals( call.method ) )
                {
                    nativeAdLoader.loadAd(adView);
                    result.success( null );
                }
                else
                {
                    result.notImplemented();
                }
            }
        } );

        nativeAdLoader.loadAd(adView);


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
        if ( nativeAd != null )
        {
            nativeAdLoader.destroy(nativeAd);
            nativeAdLoader.setNativeAdListener( null );
            nativeAdLoader.setRevenueListener( null );
        }

        if ( channel != null )
        {
            channel.setMethodCallHandler( null );
        }
    }

    @Override
    public void onNativeAdLoaded(final MaxNativeAdView nativeAdView, final MaxAd ad)
    {
        this.nativeAd = ad;
        sendEvent( "OnNativeAdViewAdLoadedEvent", ad );
    }

    @Override
    public void onNativeAdLoadFailed(final String adUnitId, final MaxError error)
    {
        AppLovinMAX.getInstance().fireErrorCallback( "OnNativeAdViewAdLoadFailedEvent", adUnitId, error );
    }

    @Override
    public void onNativeAdClicked(final MaxAd ad)
    {
        sendEvent( "OnNativeAdViewAdClickedEvent", ad );
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
}
