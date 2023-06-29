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
    public PlatformView create(@Nullable final Context context, final int viewId, final Object args)
    {
        // Ensure plugin has been initialized
        AppLovinSdk sdk = AppLovinMAX.getInstance().getSdk();
        if ( sdk == null )
        {
            AppLovinMAX.e( "Failed to create MaxAdView widget - please ensure the AppLovin MAX plugin has been initialized by calling 'AppLovinMAX.initialize(...);'!" );
            return null;
        }

        Map<String, Object> params = (Map<String, Object>) args;

        String adUnitId = (String) params.get( "ad_unit_id" );
        String adFormatStr = (String) params.get( "ad_format" );
        MaxAdFormat adFormat = "mrec".equals( adFormatStr ) ? MaxAdFormat.MREC : AppLovinMAX.getDeviceSpecificBannerAdViewAdFormat( context );

        AppLovinMAX.d( "Creating MaxAdView widget with Ad Unit ID: " + adUnitId );

        // Optional params
        boolean isAutoRefreshEnabled = Boolean.TRUE.equals( params.get( "is_auto_refresh_enabled" ) ); // Defaults to true
        String placement = params.containsKey( "placement" ) ? (String) params.get( "placement" ) : null;
        String customData = params.containsKey( "custom_data" ) ? (String) params.get( "custom_data" ) : null;
        Map<String, Object> extraParameters = params.containsKey( "extra_parameters" ) ? (Map<String, Object>) params.get( "extra_parameters" ) : null;
        Map<String, Object> localExtraParameters = params.containsKey( "local_extra_parameters" ) ? (Map<String, Object>) params.get( "local_extra_parameters" ) : null;

        return new AppLovinMAXAdView( viewId, adUnitId, adFormat, isAutoRefreshEnabled, placement, customData, extraParameters, localExtraParameters, messenger, sdk, context );
    }
}
