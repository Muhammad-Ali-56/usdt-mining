enum SubscriptionTier {
  free,
  starter,
  pro,
  elite,
}

class PlanConfig {
  const PlanConfig({
    required this.displayName,
    required this.description,
    required this.miningRate,
    required this.featureUsesPerDay,
    required this.tapEnergyAdReward,
    required this.tapEnergyCostPerTap,
    required this.clickBoosterMultiplier,
    required this.autoClickInterval,
  });

  final String displayName;
  final String description;
  final double miningRate;
  final int featureUsesPerDay;
  final double tapEnergyAdReward;
  final double tapEnergyCostPerTap;
  final double clickBoosterMultiplier;
  final Duration autoClickInterval;
}

const Map<SubscriptionTier, PlanConfig> planConfigs = {
  SubscriptionTier.free: PlanConfig(
    displayName: 'Free Plan',
    description: 'Slow mining speed, 1 boost use per feature daily.',
    miningRate: 0.000002,
    featureUsesPerDay: 1,
    tapEnergyAdReward: 5,
    tapEnergyCostPerTap: 2,
    clickBoosterMultiplier: 1.25,
    autoClickInterval: Duration(milliseconds: 900),
  ),
  SubscriptionTier.starter: PlanConfig(
    displayName: 'Starter Plan',
    description: 'Faster mining and 3 boost uses per feature daily.',
    miningRate: 0.000008,
    featureUsesPerDay: 3,
    tapEnergyAdReward: 6,
    tapEnergyCostPerTap: 1.8,
    clickBoosterMultiplier: 1.4,
    autoClickInterval: Duration(milliseconds: 750),
  ),
  SubscriptionTier.pro: PlanConfig(
    displayName: 'Pro Plan',
    description: 'High mining speed and 5 boost uses per feature daily.',
    miningRate: 0.00002,
    featureUsesPerDay: 5,
    tapEnergyAdReward: 7,
    tapEnergyCostPerTap: 1.6,
    clickBoosterMultiplier: 1.6,
    autoClickInterval: Duration(milliseconds: 650),
  ),
  SubscriptionTier.elite: PlanConfig(
    displayName: 'Elite Plan',
    description: 'Maximum mining speed and 8 boost uses per feature daily.',
    miningRate: 0.00004,
    featureUsesPerDay: 8,
    tapEnergyAdReward: 8,
    tapEnergyCostPerTap: 1.4,
    clickBoosterMultiplier: 1.8,
    autoClickInterval: Duration(milliseconds: 550),
  ),
};

SubscriptionTier subscriptionTierFromString(String? value) {
  switch (value) {
    case 'starter':
      return SubscriptionTier.starter;
    case 'pro':
      return SubscriptionTier.pro;
    case 'elite':
      return SubscriptionTier.elite;
    case 'free':
    default:
      return SubscriptionTier.free;
  }
}

String subscriptionTierToString(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.free:
      return 'free';
    case SubscriptionTier.starter:
      return 'starter';
    case SubscriptionTier.pro:
      return 'pro';
    case SubscriptionTier.elite:
      return 'elite';
  }
}

