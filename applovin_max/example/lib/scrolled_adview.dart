import 'package:applovin_flutter/main.dart';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/material.dart';

class ScrolledAdView extends StatefulWidget {
  const ScrolledAdView({
    super.key,
    required this.bannerAdUnitId,
    required this.mrecAdUnitId,
    this.preloadedBannerId,
    this.preloadedMRecId,
    this.preloadedBanner2Id,
    this.preloadedMRec2Id,
  });

  final String bannerAdUnitId;
  final String mrecAdUnitId;
  final AdViewId? preloadedBannerId;
  final AdViewId? preloadedMRecId;
  final AdViewId? preloadedBanner2Id;
  final AdViewId? preloadedMRec2Id;

  @override
  State createState() => ScrolledAdViewState();
}

class ScrolledAdViewState extends State<ScrolledAdView> {
  static const String _sampleText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
      'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad '
      'minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
      'aliquip ex ea commodo consequat. Duis aute irure dolor in '
      'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
      'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in '
      'culpa qui officia deserunt mollit anim id est laborum.';

  bool _isAdEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scrolled Banner / MREC'),
        ),
        body: SafeArea(
            child: Container(
                margin: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 10),
                  AppButton(
                    onPressed: () {
                      setState(() {
                        _isAdEnabled = !_isAdEnabled;
                      });
                    },
                    text: _isAdEnabled ? 'Disable ADs' : 'Enable ADs',
                  ),
                  Expanded(
                    child: ListView(padding: const EdgeInsets.all(4), shrinkWrap: true, children: [
                      Column(children: [
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                        _isAdEnabled
                            ? MaxAdView(adUnitId: widget.bannerAdUnitId, adFormat: AdFormat.banner, adViewId: widget.preloadedBannerId)
                            : const SizedBox(
                                height: 50,
                                child: Center(child: Text('AD Placeholder')),
                              ),
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ]),
                      Column(children: [
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                        _isAdEnabled
                            ? MaxAdView(adUnitId: widget.mrecAdUnitId, adFormat: AdFormat.mrec, adViewId: widget.preloadedMRecId)
                            : const SizedBox(
                                height: 50,
                                child: Center(child: Text('AD Placeholder')),
                              ),
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ]),
                      Column(children: [
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                        _isAdEnabled
                            ? MaxAdView(adUnitId: widget.bannerAdUnitId, adFormat: AdFormat.banner, adViewId: widget.preloadedBanner2Id)
                            : const SizedBox(
                                height: 50,
                                child: Center(child: Text('AD Placeholder')),
                              ),
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ]),
                      Column(children: [
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                        _isAdEnabled
                            ? MaxAdView(adUnitId: widget.mrecAdUnitId, adFormat: AdFormat.mrec, adViewId: widget.preloadedMRec2Id)
                            : const SizedBox(
                                height: 50,
                                child: Center(child: Text('AD Placeholder')),
                              ),
                        const Text(
                          _sampleText,
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ])
                    ]),
                  ),
                  _isAdEnabled
                      ? MaxAdView(adUnitId: widget.bannerAdUnitId, adFormat: AdFormat.banner)
                      : const SizedBox(
                          height: 50,
                          child: Center(child: Text('AD Placeholder')),
                        ),
                ]))));
  }
}
