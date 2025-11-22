import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:usdtmining/services/ad_service.dart';
import 'package:usdtmining/services/auth_service.dart';
import 'package:usdtmining/services/mining_service.dart';
import 'package:usdtmining/services/subscription_service.dart';
import 'package:usdtmining/services/notification_service.dart';
import 'package:usdtmining/services/leaderboard_service.dart';
import 'package:usdtmining/services/messaging_service.dart';
import 'package:usdtmining/services/meta_analytics_service.dart';
import 'package:usdtmining/services/referral_service.dart';
import 'package:usdtmining/theme/app_theme.dart';
import 'package:usdtmining/screens/intro_screen.dart';
import 'package:usdtmining/screens/login_screen.dart';
import 'package:usdtmining/screens/main_tabs.dart';
import 'package:usdtmining/screens/intro_video_screen.dart';
import 'package:usdtmining/widgets/app_loading_indicator.dart';
import 'package:usdtmining/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final messagingService = MessagingService();
  await messagingService.initialize();
  final metaAnalyticsService = MetaAnalyticsService();
  await metaAnalyticsService.initialize();
  await metaAnalyticsService.logAppOpen();
  runApp(MyApp(
    messagingService: messagingService,
    metaAnalyticsService: metaAnalyticsService,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.messagingService,
    required this.metaAnalyticsService,
  });

  final MessagingService messagingService;
  final MetaAnalyticsService metaAnalyticsService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProxyProvider<ReferralService, AuthService>(
          create: (_) => AuthService(),
          update: (_, referralService, authService) {
            authService ??= AuthService();
            // Connetti ReferralService ad AuthService
            authService.setReferralServiceCallback((code, user) {
              return referralService.useReferralCode(code, user);
            });
            return authService;
          },
        ),
        Provider(create: (_) => LeaderboardService()),
        Provider.value(value: messagingService),
        Provider.value(value: metaAnalyticsService),
        ChangeNotifierProvider(create: (_) => SubscriptionService()..initialize()),
        ChangeNotifierProxyProvider2<SubscriptionService, LeaderboardService, MiningService>(
          create: (_) => MiningService(),
          update: (_, subscriptionService, leaderboardService, miningService) {
            miningService ??= MiningService();
            miningService.updateSubscriptionTier(subscriptionService.currentTier);
            miningService.attachLeaderboardService(leaderboardService);
            return miningService;
          },
        ),
        ChangeNotifierProvider(create: (_) => AdService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Bruno USDT Miner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<bool>? _hasSeenVideoFuture;
  Future<bool>? _isFirstTimeFuture;
  String? _previousUserId;
  bool _shouldRebuild = false;

  @override
  void initState() {
    super.initState();
    // Inizializza i future una sola volta
    _isFirstTimeFuture = StorageService.isFirstTime();
    
    // Ascolta i cambiamenti di AuthService per forzare rebuild
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.addListener(_onAuthChanged);
  }
  
  void _onAuthChanged() {
    // Forza un rebuild quando lo stato di autenticazione cambia
    if (mounted) {
      setState(() {
        _shouldRebuild = !_shouldRebuild; // Toggle per forzare rebuild
      });
    }
  }

  @override
  void dispose() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usa listen: true per reagire ai cambiamenti
    final authService = Provider.of<AuthService>(context, listen: true);
    final currentUserId = authService.user?.uid;
    
    // Usa _shouldRebuild per forzare il rebuild (anche se non cambia)
    final _ = _shouldRebuild;
    
    // Se l'utente è appena loggato (cambiamento di stato), reset il future
    if (_previousUserId == null && currentUserId != null) {
      // Utente appena loggato
      _hasSeenVideoFuture = StorageService.hasSeenIntroVideo(); // Crea subito il future
      _previousUserId = currentUserId;
    } else if (_previousUserId != null && currentUserId == null) {
      // Utente ha fatto logout
      _hasSeenVideoFuture = null;
      _previousUserId = null;
    } else if (_previousUserId != currentUserId && currentUserId != null) {
      // Utente diverso (switched account)
      _hasSeenVideoFuture = StorageService.hasSeenIntroVideo(); // Crea subito il future
      _previousUserId = currentUserId;
    }

    if (authService.isLoading) {
      return const Scaffold(
        body: AppLoadingIndicator(
          fullScreen: true,
          text: 'Initializing app...',
        ),
      );
    }
    
    if (authService.user == null) {
      // Check if it is the first launch
      return FutureBuilder<bool>(
        future: _isFirstTimeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: AppLoadingIndicator(
                fullScreen: true,
                text: 'Checking user status...',
              ),
            );
          }
          
          if (snapshot.data == true) {
            return const IntroScreen();
          }
          return const LoginScreen();
        },
      );
    }
    
    // User is logged in - check if they need to see the intro video
    // Memoizza il future solo quando l'utente è loggato e non è già stato caricato
    _hasSeenVideoFuture ??= StorageService.hasSeenIntroVideo();
    
    return FutureBuilder<bool>(
      key: ValueKey('${currentUserId}_${_shouldRebuild}'), // Forza il rebuild
      future: _hasSeenVideoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: AppLoadingIndicator(
              fullScreen: true,
              text: 'Loading...',
            ),
          );
        }
        
        // Se l'utente non ha ancora visto il video, mostralo
        if (snapshot.data == false) {
          return const IntroVideoScreen();
        }
        
        // Altrimenti vai direttamente alla dashboard
        return const MainTabs();
      },
    );
  }
}
