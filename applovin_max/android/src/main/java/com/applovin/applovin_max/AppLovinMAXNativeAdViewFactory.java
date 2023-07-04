package com.applovin.applovin_max;

import android.content.Context;

import com.applovin.sdk.AppLovinSdk;

import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AppLovinMAXNativeAdViewFactory
        extends PlatformViewFactory
{
    private final BinaryMessenger messenger;

    public AppLovinMAXNativeAdViewFactory(final BinaryMessenger messenger)
    {
        super( StandardMessageCodec.INSTANCE );

        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(@Nullable final Context context, final int viewId, final Object args)
    {
        // Ensure plugin has been initialized
        AppLovinSdk sdk = AppLovinMAX.getInstance().getSdk();
        if ( sdk == null )
        {
            AppLovinMAX.e( "Failed to create MaxNativeAdView widget - please ensure the AppLovin MAX plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!" );
            return null;
        }

        Map<String, Object> params = (Map<String, Object>) args;

        String adUnitId = (String) params.get( "ad_unit_id" );

        AppLovinMAX.d( "Creating MaxNativeAdView widget with Ad Unit ID: " + adUnitId );

        // Optional params
        String placement = params.containsKey( "placement" ) ? (String) params.get( "placement" ) : null;
        String customData = params.containsKey( "custom_data" ) ? (String) params.get( "custom_data" ) : null;
        Map<String, Object> extraParameters = params.containsKey( "extra_parameters" ) ? (Map<String, Object>) params.get( "extra_parameters" ) : null;
        Map<String, Object> localExtraParameters = params.containsKey( "local_extra_parameters" ) ? (Map<String, Object>) params.get( "local_extra_parameters" ) : null;

        return new AppLovinMAXNativeAdView( viewId, adUnitId, placement, customData, extraParameters, localExtraParameters, messenger, sdk, context );
    }
}
