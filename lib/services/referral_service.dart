import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:usdtmining/services/storage_service.dart';

class ReferralData {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final DateTime joinedAt;
  final double rewardEarned;
  final bool isActive;

  ReferralData({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.joinedAt,
    this.rewardEarned = 0.0,
    this.isActive = true,
  });

  factory ReferralData.fromMap(Map<dynamic, dynamic> map) {
    return ReferralData(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      userEmail: map['userEmail'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      joinedAt: map['joinedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int)
          : DateTime.now(),
      rewardEarned: (map['rewardEarned'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
      'rewardEarned': rewardEarned,
      'isActive': isActive,
    };
  }
}

class ReferralService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _referralCode;
  List<ReferralData> _referrals = [];
  double _totalReferralEarnings = 0.0;
  int _totalReferrals = 0;
  bool _isLoading = true;

  String? get referralCode => _referralCode;
  List<ReferralData> get referrals => _referrals;
  double get totalReferralEarnings => _totalReferralEarnings;
  int get totalReferrals => _totalReferrals;
  bool get isLoading => _isLoading;

  DatabaseReference? _referralsRef;
  DatabaseReference? _userRef;

  // Costanti per le ricompense
  static const double referrerReward = 0.05; // Ricompensa per chi ha invitato
  static const double refereeReward = 0.02; // Ricompensa per chi si iscrive con codice

  ReferralService() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _initializeForUser(user);
      } else {
        _cleanup();
      }
    });
  }

  Future<void> _initializeForUser(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Genera o recupera codice referral
      await _ensureReferralCode(user);

      // Carica dati referral
      await _loadUserReferrals(user.uid);

      // Ascolta cambiamenti in tempo reale
      _listenToReferrals(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing referral service: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureReferralCode(User user) async {
    // Controlla se esiste già un codice in local storage
    String? localCode = await StorageService.getReferralCode();
    if (localCode != null && localCode.isNotEmpty) {
      _referralCode = localCode;
    } else {
      // Genera nuovo codice basato sull'UID
      _referralCode = _generateReferralCode(user.uid);
      await StorageService.setReferralCode(_referralCode!);
    }

    // Salva nel database
    _userRef = _database.child('users').child(user.uid);
    await _userRef!.child('referralCode').set(_referralCode);
    await _userRef!.child('displayName').set(user.displayName ?? 'User');
    await _userRef!.child('email').set(user.email ?? '');
    await _userRef!.child('photoUrl').set(user.photoURL);
    await _userRef!.child('createdAt').set(ServerValue.timestamp);
  }

  String _generateReferralCode(String uid) {
    // Usa i primi 6 caratteri dell'UID + 2 caratteri random
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomSuffix = String.fromCharCodes(
      Iterable.generate(2, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return (uid.substring(0, 6).toUpperCase() + randomSuffix);
  }

  Future<void> _loadUserReferrals(String userId) async {
    try {
      final snapshot = await _database
          .child('users')
          .child(userId)
          .child('referrals')
          .once();

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        _referrals = data.entries.map((entry) {
          return ReferralData.fromMap(entry.value as Map<dynamic, dynamic>);
        }).toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

        _totalReferrals = _referrals.length;
        _totalReferralEarnings = _referrals.fold(
          0.0,
          (sum, ref) => sum + ref.rewardEarned,
        );
      } else {
        _referrals = [];
        _totalReferrals = 0;
        _totalReferralEarnings = 0.0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading referrals: $e');
    }
  }

  void _listenToReferrals(String userId) {
    _referralsRef?.onValue.drain();
    _referralsRef = _database.child('users').child(userId).child('referrals');

    _referralsRef!.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _referrals = data.entries.map((entry) {
          return ReferralData.fromMap(entry.value as Map<dynamic, dynamic>);
        }).toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

        _totalReferrals = _referrals.length;
        _totalReferralEarnings = _referrals.fold(
          0.0,
          (sum, ref) => sum + ref.rewardEarned,
        );
      } else {
        _referrals = [];
        _totalReferrals = 0;
        _totalReferralEarnings = 0.0;
      }
      notifyListeners();
    });
  }

  /// Usa un codice referral durante la registrazione
  /// Restituisce l'UID del referrer se il codice è valido, null altrimenti
  Future<String?> useReferralCode(String code, User newUser) async {
    try {
      // Normalizza il codice
      final normalizedCode = code.toUpperCase().trim();

      // Cerca l'utente con questo codice referral
      final snapshot = await _database
          .child('users')
          .orderByChild('referralCode')
          .equalTo(normalizedCode)
          .once();

      if (!snapshot.snapshot.exists || snapshot.snapshot.value == null) {
        debugPrint('Referral code not found: $normalizedCode');
        return null;
      }

      // Ottieni il primo risultato (dovrebbe essere unico)
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final referrerEntry = data.entries.first;
      final referrerUid = referrerEntry.key as String;

      // Verifica che non sia lo stesso utente
      if (referrerUid == newUser.uid) {
        debugPrint('Cannot use own referral code');
        return null;
      }

      // Verifica se l'utente ha già usato un codice referral
      final userRef = _database.child('users').child(newUser.uid);
      final userSnapshot = await userRef.child('referredBy').once();
      if (userSnapshot.snapshot.exists) {
        debugPrint('User already has a referrer');
        return null;
      }

      // Registra il referral
      await _registerReferral(referrerUid, newUser);

      // Dà ricompense
      await _giveReferralRewards(referrerUid, newUser.uid);

      return referrerUid;
    } catch (e) {
      debugPrint('Error using referral code: $e');
      return null;
    }
  }

  Future<void> _registerReferral(String referrerUid, User newUser) async {
    final referralData = ReferralData(
      userId: newUser.uid,
      userName: newUser.displayName ?? 'Unknown',
      userEmail: newUser.email ?? '',
      userPhotoUrl: newUser.photoURL,
      joinedAt: DateTime.now(),
      rewardEarned: 0.0,
      isActive: true,
    );

    // Aggiungi ai referral del referrer
    await _database
        .child('users')
        .child(referrerUid)
        .child('referrals')
        .child(newUser.uid)
        .set(referralData.toMap());

    // Salva chi ha invitato il nuovo utente
    await _database.child('users').child(newUser.uid).child('referredBy').set({
      'referrerUid': referrerUid,
      'referredAt': ServerValue.timestamp,
    });

    // Salva anche il codice referral del nuovo utente
    final newUserRef = _database.child('users').child(newUser.uid);
    final newCode = _generateReferralCode(newUser.uid);
    await newUserRef.child('referralCode').set(newCode);
    await StorageService.setReferralCode(newCode);
    await newUserRef.child('displayName').set(newUser.displayName ?? 'User');
    await newUserRef.child('email').set(newUser.email ?? '');
    await newUserRef.child('photoUrl').set(newUser.photoURL);
    await newUserRef.child('createdAt').set(ServerValue.timestamp);
  }

  Future<void> _giveReferralRewards(String referrerUid, String refereeUid) async {
    // Aggiorna il balance del referrer nel database
    await _database
        .child('users')
        .child(referrerUid)
        .child('referrals')
        .child(refereeUid)
        .child('rewardEarned')
        .set(referrerReward);

    // Aggiorna il total referral earnings
    final refSnapshot = await _database
        .child('users')
        .child(referrerUid)
        .child('referrals')
        .once();

    double totalEarnings = referrerReward;
    if (refSnapshot.snapshot.exists && refSnapshot.snapshot.value != null) {
      final data = refSnapshot.snapshot.value as Map<dynamic, dynamic>;
      for (var entry in data.entries) {
        final refData = ReferralData.fromMap(entry.value as Map<dynamic, dynamic>);
        if (entry.key != refereeUid) {
          totalEarnings += refData.rewardEarned;
        }
      }
    }

    await _database
        .child('users')
        .child(referrerUid)
        .child('totalReferralEarnings')
        .set(totalEarnings);

    // Salva anche in local storage per il referrer
    final currentBalance = await StorageService.getReferralBalance();
    await StorageService.setReferralBalance(currentBalance + referrerReward);

    final currentIncome = await StorageService.getReferralIncome();
    await StorageService.setReferralIncome(currentIncome + referrerReward);

    // Dà ricompensa al referee (nuovo utente)
    final refereeBalance = await StorageService.getMiningBalance();
    await StorageService.setMiningBalance(refereeBalance + refereeReward);

    debugPrint(
      'Rewards given: Referrer $referrerUid got $referrerReward USDT, Referee $refereeUid got $refereeReward USDT',
    );
  }

  /// Controlla se un codice referral è valido
  Future<bool> isReferralCodeValid(String code) async {
    try {
      final normalizedCode = code.toUpperCase().trim();
      final snapshot = await _database
          .child('users')
          .orderByChild('referralCode')
          .equalTo(normalizedCode)
          .once();

      if (!snapshot.snapshot.exists || snapshot.snapshot.value == null) {
        return false;
      }

      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final referrerUid = data.keys.first as String;
      final currentUser = _auth.currentUser;

      // Non può usare il proprio codice
      if (currentUser != null && referrerUid == currentUser.uid) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking referral code: $e');
      return false;
    }
  }

  /// Ottieni il referral code dell'utente corrente
  Future<String?> getUserReferralCode() async {
    if (_referralCode != null) return _referralCode;
    return await StorageService.getReferralCode();
  }

  void _cleanup() {
    _referralsRef?.onValue.drain();
    _referralsRef = null;
    _userRef = null;
    _referralCode = null;
    _referrals = [];
    _totalReferrals = 0;
    _totalReferralEarnings = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}





