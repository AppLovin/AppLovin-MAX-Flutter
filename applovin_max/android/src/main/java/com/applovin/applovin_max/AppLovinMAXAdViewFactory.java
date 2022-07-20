package com.applovin.applovin_max;

import android.content.Context;

import com.applovin.mediation.MaxAdFormat;
import com.applovin.sdk.AppLovinSdk;

import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * Created by Thomas So on July 17 2022
 */
public class AppLovinMAXAdViewFactory
        extends PlatformViewFactory
{
    private final BinaryMessenger messenger;

    public AppLovinMAXAdViewFactory(final BinaryMessenger messenger)
    {
        super( StandardMessageCodec.INSTANCE );

        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(@Nullable final Context context, final int viewId, final Object rawArgs)
    {
        // Ensure plugin has been initialized
        AppLovinSdk sdk = AppLovinMAX.getInstance().getSdk();
        if ( sdk == null )
        {
            AppLovinMAX.e( "Failed to create MaxAdView widget - please ensure the AppLovin MAX plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!" );
            return null;
        }

        Map<String, String> args = (Map<String, String>) rawArgs;

        String adUnitId = (String) args.get( "ad_unit_id" );
        String adFormatStr = (String) args.get( "ad_format" );
        MaxAdFormat adFormat = "mrec".equals( adFormatStr ) ? MaxAdFormat.MREC : AppLovinMAX.getDeviceSpecificBannerAdViewAdFormat( context );

        AppLovinMAX.d( "Creating MaxAdView widget with Ad Unit ID: " + adUnitId );

        // Optional params

        String placement = args.containsKey( "placement" ) ? (String) args.get( "placement" ) : null;
        String customData = args.containsKey( "customData" ) ? (String) args.get( "customData" ) : null;

        return new AppLovinMAXAdView( viewId, adUnitId, adFormat, placement, customData, messenger, sdk, context );
    }
}
