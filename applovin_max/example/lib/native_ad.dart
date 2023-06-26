import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

class NativeAdView extends StatefulWidget {
  const NativeAdView({
    super.key,
    required this.adUnitId,
  });

  final String adUnitId;

  @override
  State createState() => NativeAdViewState();
}

class NativeAdViewState extends State<NativeAdView> {
  static const double _kMediaViewAspectRatio = 16 / 9;

  String _statusText = "";

  double _mediaViewAspectRatio = _kMediaViewAspectRatio;

  final MaxNativeAdViewController _nativeAdViewController = MaxNativeAdViewController();

  void logStatus(String status) {
    /// ignore: avoid_print
    print(status);

    setState(() {
      _statusText = '$_statusText\n$status';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Native Ad'),
        ),
        body: SafeArea(
            child: Column(children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              reverse: true,
              child: Text(
                _statusText,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.all(8.0),
            height: 300,
            child: MaxNativeAdView(
              adUnitId: widget.adUnitId,
              controller: _nativeAdViewController,
              listener: NativeAdListener(onAdLoadedCallback: (ad) {
                logStatus('Native ad loaded from ${ad.networkName}');
                setState(() {
                  _mediaViewAspectRatio = ad.nativeAd?.mediaContentAspectRatio ?? _kMediaViewAspectRatio;
                });
              }, onAdLoadFailedCallback: (adUnitId, error) {
                logStatus('Native ad failed to load with error code ${error.code} and message: ${error.message}');
              }, onAdClickedCallback: (ad) {
                logStatus('Native ad clicked');
              }, onAdRevenuePaidCallback: (ad) {
                logStatus('Native ad revenue paid: ${ad.revenue}');
              }),
              child: Container(
                color: const Color(0xffefefef),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          child: const MaxNativeAdIconView(
                            width: 48,
                            height: 48,
                          ),
                        ),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MaxNativeAdTitleView(
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                              MaxNativeAdAdvertiserView(
                                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                              ),
                              MaxNativeAdStarRatingView(
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                        const MaxNativeAdOptionsView(
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: MaxNativeAdBodyView(
                            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _mediaViewAspectRatio,
                        child: const MaxNativeAdMediaView(),
                      ),
                    ),
                    const SizedBox(
                      width: double.infinity,
                      child: MaxNativeAdCallToActionView(
                        style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll<Color>(Color(0xff2d545e)),
                          textStyle: MaterialStatePropertyAll<TextStyle>(TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _nativeAdViewController.loadAd();
            },
            child: const Text('Reload'),
          ),
        ])));
  }
}
