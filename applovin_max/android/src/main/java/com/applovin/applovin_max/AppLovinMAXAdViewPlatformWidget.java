package com.applovin.applovin_max;

import android.content.Context;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdListener;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.sdk.AppLovinSdk;

import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

class AppLovinMAXAdViewPlatformWidget
        implements MaxAdListener, MaxAdViewAdListener, MaxAdRevenueListener
{
    private final MaxAdView adView;
    private final boolean   isPreloadPlatformWidget;

    @Nullable
    private AppLovinMAXAdView containerView;

    public AppLovinMAXAdViewPlatformWidget(final String adUnitId, final MaxAdFormat adFormat, final AppLovinSdk sdk, final Context context)
    {
        this( adUnitId, adFormat, false, sdk, context );
    }

    public AppLovinMAXAdViewPlatformWidget(final String adUnitId, final MaxAdFormat adFormat, final boolean preload, final AppLovinSdk sdk, final Context context)
    {
        adView = new MaxAdView( adUnitId, adFormat, sdk, context );
        adView.setListener( this );
        adView.setRevenueListener( this );

        adView.setExtraParameter( "adaptive_banner", "true" );

        // Set this extra parameter to work around a SDK bug that ignores calls to stopAutoRefresh()
        adView.setExtraParameter( "allow_pause_auto_refresh_immediately", "true" );

        isPreloadPlatformWidget = preload;
    }

    public MaxAdView getAdView()
    {
        return adView;
    }

    public void setPlacement(@Nullable final String value)
    {
        adView.setPlacement( value );
    }

    public void setCustomData(@Nullable final String value)
    {
        adView.setCustomData( value );
    }

    public void setAutoRefresh(final boolean enabled)
    {
        if ( enabled )
        {
            adView.startAutoRefresh();
        }
        else
        {
            adView.stopAutoRefresh();
        }
    }

    public void setExtraParameters(@Nullable final Map<String, Object> extraParameters)
    {
        if ( extraParameters == null ) return;

        for ( Map.Entry<String, Object> entry : extraParameters.entrySet() )
        {
            adView.setExtraParameter( entry.getKey(), (String) entry.getValue() );
        }
    }

    public void setLocalExtraParameters(@Nullable final Map<String, Object> localExtraParameters)
    {
        if ( localExtraParameters == null ) return;

        for ( Map.Entry<String, Object> entry : localExtraParameters.entrySet() )
        {
            adView.setLocalExtraParameter( entry.getKey(), entry.getValue() );
        }
    }

    public boolean hasContainerView()
    {
        return containerView != null;
    }

    public void attachAdView(AppLovinMAXAdView view)
    {
        containerView = view;
    }

    public void detachAdView()
    {
        containerView = null;
    }

    public void loadAd()
    {
        adView.loadAd();
    }

    public void destroy()
    {
        detachAdView();

        adView.setListener( null );
        adView.setRevenueListener( null );
        adView.destroy();
    }

    @Override
    public void onAdLoaded(@NonNull final MaxAd ad)
    {
        Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );

        if ( isPreloadPlatformWidget )
        {
            AppLovinMAX.getInstance().fireCallback( "OnPlatformWidgetAdViewAdLoadedEvent", Map.copyOf( params ) );
        }

        if ( containerView != null )
        {
            containerView.sendEvent( "OnAdViewAdLoadedEvent", params );
        }
    }

    @Override
    public void onAdLoadFailed(@NonNull final String adUnitId, @NonNull final MaxError error)
    {
        Map<String, Object> params = AppLovinMAX.getInstance().getAdLoadFailedInfo( adUnitId, error );

        if ( isPreloadPlatformWidget )
        {
            AppLovinMAX.getInstance().fireCallback( "OnPlatformWidgetAdViewAdLoadFailedEvent", Map.copyOf( params ) );
        }

        if ( containerView != null )
        {
            containerView.sendEvent( "OnAdViewAdLoadFailedEvent", params );
        }
    }

    @Override
    public void onAdClicked(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            containerView.sendEvent( "OnAdViewAdClickedEvent", params );
        }
    }

    @Override
    public void onAdExpanded(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            containerView.sendEvent( "OnAdViewAdExpandedEvent", params );
        }
    }

    @Override
    public void onAdCollapsed(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            containerView.sendEvent( "OnAdViewAdCollapsedEvent", params );
        }
    }

    @Override
    public void onAdRevenuePaid(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            containerView.sendEvent( "OnAdViewAdRevenuePaidEvent", params );
        }
    }

    /// Deprecated Callbacks

    @Override
    public void onAdDisplayed(@NonNull final MaxAd ad) { }

    @Override
    public void onAdDisplayFailed(@NonNull final MaxAd ad, @NonNull final MaxError error) { }

    @Override
    public void onAdHidden(@NonNull final MaxAd ad) { }
}
