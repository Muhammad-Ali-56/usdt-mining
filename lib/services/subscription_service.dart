import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:usdtmining/models/subscription_plan.dart';
import 'package:usdtmining/services/storage_service.dart';

class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  SubscriptionTier _currentTier = SubscriptionTier.free;
  bool _isLoading = false;
  bool _isAvailable = false;
  Set<String> _notFoundIds = <String>{};
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  
  // Product IDs per ogni tier (devi configurarli nel Google Play Console e App Store Connect)
  static const Map<SubscriptionTier, String> _productIds = {
    SubscriptionTier.starter: 'starter_monthly_subscription',
    SubscriptionTier.pro: 'pro_monthly_subscription',
    SubscriptionTier.elite: 'elite_monthly_subscription',
  };

  SubscriptionTier get currentTier => _currentTier;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  List<PurchaseDetails> get purchases => _purchases;

  PlanConfig get config => planConfigs[_currentTier]!;

  SubscriptionService() {
    _initialize();
  }

  void _initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-app purchase not available');
      // Fallback: carica tier salvato localmente
      await _loadLocalTier();
      return;
    }

    // Ascolta aggiornamenti acquisti
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Carica tier salvato
    await _loadLocalTier();

    // Carica prodotti disponibili
    await loadProducts();

    // Restore acquisti precedenti
    await restorePurchases();
  }

  Future<void> _loadLocalTier() async {
    final storedTierString = await StorageService.getSubscriptionTier();
    _currentTier = subscriptionTierFromString(storedTierString);
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    final Set<String> productIds = Set<String>.from(_productIds.values);
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      _notFoundIds = Set<String>.from(response.notFoundIDs);
      debugPrint('Products not found: $_notFoundIds');
    }

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      _isLoading = false;
      notifyListeners();
      return;
    }

    _products = response.productDetails;
    _isLoading = false;
    notifyListeners();
  }

  ProductDetails? getProductForTier(SubscriptionTier tier) {
    if (tier == SubscriptionTier.free) return null;
    final productId = _productIds[tier];
    if (productId == null) {
      debugPrint('No product ID configured for tier: $tier');
      return null;
    }
    try {
      return _products.firstWhere(
        (product) => product.id == productId,
      );
    } catch (e) {
      debugPrint('Product not found for tier: $tier, productId: $productId');
      debugPrint('Available products: ${_products.map((p) => p.id).toList()}');
      return null;
    }
  }

  Future<bool> purchaseSubscription(SubscriptionTier tier) async {
    if (!_isAvailable || tier == SubscriptionTier.free) {
      debugPrint('Purchase not available: isAvailable=$_isAvailable, tier=$tier');
      return false;
    }

    // Assicurati che i prodotti siano caricati
    if (_products.isEmpty) {
      debugPrint('Products not loaded yet. Loading products...');
      await loadProducts();
      
      // Se ancora vuoto dopo il caricamento, c'è un problema
      if (_products.isEmpty) {
        debugPrint('Failed to load products. Available: $_isAvailable');
        return false;
      }
    }

    final product = getProductForTier(tier);
    if (product == null) {
      debugPrint('Product not available for tier: $tier');
      debugPrint('Available products: ${_products.map((p) => p.id).toList()}');
      debugPrint('Expected product ID: ${_productIds[tier]}');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      // Per le sottoscrizioni, usa buyNonConsumable (ma in realtà dovrebbe essere una subscription)
      // Nota: buyNonConsumable funziona anche per le sottoscrizioni su alcune piattaforme
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Il risultato verrà gestito in _onPurchaseUpdated
      return true;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
      // Il risultato verrà gestito in _onPurchaseUpdated
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _handlePurchaseError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handleSuccessfulPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    debugPrint('Purchase successful: ${purchaseDetails.productID}');

    // Trova il tier corrispondente al product ID
    SubscriptionTier? purchasedTier;
    for (final entry in _productIds.entries) {
      if (entry.value == purchaseDetails.productID) {
        purchasedTier = entry.key;
        break;
      }
    }

    if (purchasedTier != null && purchasedTier != SubscriptionTier.free) {
      _currentTier = purchasedTier;
      _saveSubscriptionTier(purchasedTier);
      _verifyPurchase(purchaseDetails);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Qui puoi implementare la verifica server-side se necessario
    // Per ora salviamo solo localmente
    debugPrint('Purchase verified: ${purchaseDetails.productID}');
    notifyListeners();
  }

  Future<void> _saveSubscriptionTier(SubscriptionTier tier) async {
    await StorageService.setSubscriptionTier(subscriptionTierToString(tier));
    await StorageService.setSubscriptionActive(tier != SubscriptionTier.free);
  }

  void _handlePurchaseError(IAPError error) {
    debugPrint('Purchase error: ${error.message}');
    _isLoading = false;
    notifyListeners();
  }

  void _showPendingUI() {
    // Mostra UI di attesa se necessario
  }

  Future<void> cancelSubscription(SubscriptionTier tier) async {
    // Le sottoscrizioni devono essere cancellate tramite Google Play o App Store
    // Questo metodo può aprire l'URL appropriato o fornire istruzioni
    debugPrint('To cancel subscription, please visit your app store settings');
    
    // Reimposta a free tier localmente
    _currentTier = SubscriptionTier.free;
    await _saveSubscriptionTier(SubscriptionTier.free);
    notifyListeners();
  }

  Future<void> checkSubscriptionStatus() async {
    // Verifica lo stato delle sottoscrizioni attive
    if (!_isAvailable) return;

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(Set<String>.from(_productIds.values));

    // Controlla se ci sono acquisti attivi
    for (final purchase in _purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verifica se la sottoscrizione è ancora valida
        // Nota: per verifiche più accurate, usa un server-side receipt validation
        SubscriptionTier? tier;
        for (final entry in _productIds.entries) {
          if (entry.value == purchase.productID) {
            tier = entry.key;
            break;
          }
        }

        if (tier != null && tier != SubscriptionTier.free) {
          _currentTier = tier;
          await _saveSubscriptionTier(tier);
          notifyListeners();
          return;
        }
      }
    }

    // Se non ci sono acquisti attivi, ripristina free
    if (_currentTier != SubscriptionTier.free) {
      _currentTier = SubscriptionTier.free;
      await _saveSubscriptionTier(SubscriptionTier.free);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Metodo legacy per compatibilità
  Future<void> selectTier(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.free) {
      // Per free tier, salva direttamente
      _currentTier = tier;
      await _saveSubscriptionTier(tier);
      notifyListeners();
    } else {
      // Per tier a pagamento, avvia l'acquisto
      await purchaseSubscription(tier);
    }
  }

  Future<void> initialize() async {
    // Metodo legacy - già inizializzato nel costruttore
    await _loadLocalTier();
    await loadProducts();
  }

  List<SubscriptionTier> get availableTiers => SubscriptionTier.values;
}
