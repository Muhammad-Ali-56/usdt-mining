import 'package:flutter/material.dart';
import 'package:usdtmining/widgets/spin_wheel_card.dart';
import 'package:usdtmining/widgets/ads/native_ad_panel.dart';
import 'package:usdtmining/widgets/mining_background.dart';

class SpinWheelScreen extends StatelessWidget {
  const SpinWheelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin Wheel'),
        backgroundColor: const Color(0xFF0A0E27),
      ),
      body: MiningBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                SpinWheelCard(),
                SizedBox(height: 16),
                NativeAdPanel(),
              ],
            ),
          ),
        ),
      ),

    );
  }
}