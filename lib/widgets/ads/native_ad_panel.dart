import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';

class NativeAdPanel extends StatefulWidget {
  const NativeAdPanel({
    super.key,
    this.height = 320,
    this.margin,
    this.borderRadius = 16,
  });

  final double height;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  State<NativeAdPanel> createState() => _NativeAdPanelState();
}

class _NativeAdPanelState extends State<NativeAdPanel> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adService = context.read<AdService>();
    if (!adService.adsEnabled || _nativeAd != null) return;

    final ad = NativeAd(
      adUnitId: adService.nativeUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    await ad.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = context.watch<AdService>();
    if (!adService.adsEnabled) {
      _nativeAd?.dispose();
      _nativeAd = null;
      _isLoaded = false;
      return const SizedBox.shrink();
    }
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final padding = widget.margin ?? EdgeInsets.zero;
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          height: widget.height,
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}

