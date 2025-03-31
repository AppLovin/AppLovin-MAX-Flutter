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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final bool isBanner = index % 2 == 0;
                        final String adUnitId = isBanner ? widget.bannerAdUnitId : widget.mrecAdUnitId;
                        final AdFormat adFormat = isBanner ? AdFormat.banner : AdFormat.mrec;

                        AdViewId? adViewId;
                        if (index == 0) {
                          adViewId = widget.preloadedBannerId;
                        } else if (index == 1) {
                          adViewId = widget.preloadedMRecId;
                        } else if (index == 2) {
                          adViewId = widget.preloadedBanner2Id;
                        } else if (index == 3) {
                          adViewId = widget.preloadedMRec2Id;
                        }

                        return ListItem(
                          key: ValueKey('item_$index'),
                          isAdEnabled: _isAdEnabled,
                          adUnitId: adUnitId,
                          adFormat: adFormat,
                          adViewId: adViewId,
                        );
                      },
                    ),
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

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.isAdEnabled,
    required this.adUnitId,
    required this.adFormat,
    this.adViewId,
  });

  final bool isAdEnabled;
  final String adUnitId;
  final AdFormat adFormat;
  final AdViewId? adViewId;

  static const String _sampleText = ScrolledAdViewState._sampleText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          _sampleText,
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 18.0),
        ),
        isAdEnabled
            ? MaxAdView(
                adUnitId: adUnitId,
                adFormat: adFormat,
                adViewId: adViewId,
              )
            : const SizedBox(
                height: 50,
                child: Center(child: Text('AD Placeholder')),
              ),
        const Text(
          _sampleText,
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 18.0),
        ),
      ],
    );
  }
}
