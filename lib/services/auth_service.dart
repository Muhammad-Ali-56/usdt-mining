import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:usdtmining/services/storage_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = true;
  bool _isSigningIn = false;
  ReferralServiceCallback? _referralServiceCallback;

  User? get user => _user;
  bool get isLoading => _isLoading;



  // Callback per ReferralService - sarà impostato dopo l'inizializzazione
  void setReferralServiceCallback(ReferralServiceCallback? callback) {
    _referralServiceCallback = callback;
  }

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Ottieni lo stato iniziale dell'utente
    _user = _auth.currentUser;
    _isLoading = false;
    notifyListeners();
    
    // Ascolta i cambiamenti di stato (solo per logout o cambiamenti esterni)
    _auth.authStateChanges().listen((User? user) {
      // Durante il login manuale, ignora completamente il listener
      // Questo evita interferenze con il processo di login
      if (_isSigningIn) {
        return;
      }
      
      // Solo aggiorna se l'utente è effettivamente cambiato
      if (_user?.uid != user?.uid) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<bool> isFirstTime() async {
    return await StorageService.isFirstTime();
  }

  Future<void> markFirstTimeDone() async {
    await StorageService.setFirstTime(false);
  }

  Future<UserCredential?> signInWithGoogle({String? referralCode}) async {
    try {
      _isSigningIn = true;
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        _isSigningIn = false;
        notifyListeners();
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Aggiorna _user immediatamente
      _user = userCredential.user;
      _isLoading = false;
      _isSigningIn = false;
      
      // Notifica i listener
      notifyListeners();
      
      // Processa il referral code in background per non bloccare la navigazione
      if (referralCode != null && 
          referralCode.trim().isNotEmpty && 
          _referralServiceCallback != null &&
          userCredential.user != null) {
        // Esegui in background senza bloccare
        _referralServiceCallback!(referralCode, userCredential.user!).then((referrerUid) {
          if (referrerUid != null) {
            debugPrint('Referral code used successfully. Referrer: $referrerUid');
          }
        }).catchError((error) {
          debugPrint('Error processing referral code: $error');
        });
      }
      
      return userCredential;
    } catch (e) {
      _isLoading = false;
      _isSigningIn = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

// Callback type per ReferralService
typedef ReferralServiceCallback = Future<String?> Function(String code, User user);



