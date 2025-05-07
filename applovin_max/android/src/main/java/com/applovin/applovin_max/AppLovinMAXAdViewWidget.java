package com.applovin.applovin_max;

import android.content.Context;
import android.widget.FrameLayout;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdListener;
import com.applovin.mediation.MaxAdRevenueListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxAdViewConfiguration;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.ads.MaxAdView;

import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

class AppLovinMAXAdViewWidget
        extends FrameLayout
        implements MaxAdListener, MaxAdViewAdListener, MaxAdRevenueListener
{
    private final MaxAdView adView;
    private final boolean   shouldPreloadWidget;

    @Nullable
    private AppLovinMAXAdView containerView;

    public AppLovinMAXAdViewWidget(final String adUnitId, final MaxAdFormat adFormat, final boolean isAdaptiveBannerEnabled, final Context context)
    {
        this( adUnitId, adFormat, isAdaptiveBannerEnabled, false, context );
    }

    public AppLovinMAXAdViewWidget(final String adUnitId, final MaxAdFormat adFormat, final boolean isAdaptiveBannerEnabled, final boolean shouldPreloadWidget, final Context context)
    {
        super( context );

        this.shouldPreloadWidget = shouldPreloadWidget;

        MaxAdViewConfiguration config = MaxAdViewConfiguration.builder()
                .setAdaptiveType( isAdaptiveBannerEnabled ? MaxAdViewConfiguration.AdaptiveType.ANCHORED : MaxAdViewConfiguration.AdaptiveType.NONE )
                .build();

        adView = new MaxAdView( adUnitId, adFormat, config );
        adView.setListener( this );
        adView.setRevenueListener( this );

        // Set this extra parameter to work around a SDK bug that ignores calls to stopAutoRefresh()
        adView.setExtraParameter( "allow_pause_auto_refresh_immediately", "true" );

        adView.stopAutoRefresh();

        addView( adView );

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
        );

        adView.setLayoutParams( params );
    }

    public MaxAdView getAdView()
    {
        return adView;
    }

    public String getAdUnitId()
    {
        return adView.getAdUnitId();
    }

    public void setPlacement(@Nullable final String value)
    {
        adView.setPlacement( value );
    }

    public void setCustomData(@Nullable final String value)
    {
        adView.setCustomData( value );
    }

    public void setAutoRefreshEnabled(final boolean enabled)
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
        params.put( "adViewId", hashCode() );

        if ( shouldPreloadWidget )
        {
            // Copy the `params` for the next sending, as they are consumed (i.e., released) by
            // `MethodChannel.invokeMethod()` through `fireCallback()`.
            AppLovinMAX.getInstance().fireCallback( "OnWidgetAdViewAdLoadedEvent", Map.copyOf( params ) );
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
        params.put( "adViewId", hashCode() );

        if ( shouldPreloadWidget )
        {
            // Copy the `params` for the next sending, as they are consumed (i.e., released) by
            // `MethodChannel.invokeMethod()` through `fireCallback()`.
            AppLovinMAX.getInstance().fireCallback( "OnWidgetAdViewAdLoadFailedEvent", Map.copyOf( params ) );
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
            params.put( "adViewId", hashCode() );

            containerView.sendEvent( "OnAdViewAdClickedEvent", params );
        }
    }

    @Override
    public void onAdExpanded(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            params.put( "adViewId", hashCode() );

            containerView.sendEvent( "OnAdViewAdExpandedEvent", params );
        }
    }

    @Override
    public void onAdCollapsed(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            params.put( "adViewId", hashCode() );

            containerView.sendEvent( "OnAdViewAdCollapsedEvent", params );
        }
    }

    @Override
    public void onAdRevenuePaid(@NonNull final MaxAd ad)
    {
        if ( containerView != null )
        {
            Map<String, Object> params = AppLovinMAX.getInstance().getAdInfo( ad );
            params.put( "adViewId", hashCode() );

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
