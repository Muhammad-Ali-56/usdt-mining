enum TapFeature { unlimitedCharge, autoClick, clickBooster }

String tapFeatureLabel(TapFeature feature) {
  switch (feature) {
    case TapFeature.unlimitedCharge:
      return 'Unlimited Charge';
    case TapFeature.autoClick:
      return 'Auto Click';
    case TapFeature.clickBooster:
      return 'Click Booster';
  }
}

String tapFeatureDescription(TapFeature feature) {
  switch (feature) {
    case TapFeature.unlimitedCharge:
      return 'Unlimited tap energy for 2 minutes.';
    case TapFeature.autoClick:
      return 'Automatically taps for you over 2 minutes.';
    case TapFeature.clickBooster:
      return 'Boost tap rewards for 2 minutes.';
  }
}

