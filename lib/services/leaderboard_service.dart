import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final double earnings;
  final String? photoUrl;
  final DateTime? updatedAt;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.earnings,
    this.photoUrl,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromSnapshot(DataSnapshot snapshot) {
    final Object? rawValue = snapshot.value;
    if (rawValue is! Map) {
      return LeaderboardEntry(
        uid: snapshot.key ?? '',
        displayName: 'Miner',
        earnings: 0,
      );
    }

    final map = rawValue.cast<Object?, Object?>();
    final earnings = (map['earnings'] as num?)?.toDouble() ?? 0;
    final updatedAtMs = (map['updatedAt'] as num?)?.toInt();

    return LeaderboardEntry(
      uid: snapshot.key ?? '',
      displayName: (map['displayName'] as String?)?.trim().isNotEmpty == true
          ? map['displayName'] as String
          : 'Miner',
      earnings: earnings,
      photoUrl: map['photoUrl'] as String?,
      updatedAt: updatedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs)
          : null,
    );
  }
}

class LeaderboardService {
  LeaderboardService() : _leaderboardRef = FirebaseDatabase.instance.ref('leaderboard');

  final DatabaseReference _leaderboardRef;

  Stream<List<LeaderboardEntry>> leaderboardStream({int limit = 100}) {
    final query = _leaderboardRef.orderByChild('earnings').limitToLast(limit);
    return query.onValue.map((event) {
      final entries = event.snapshot.children
          .map(LeaderboardEntry.fromSnapshot)
          .where((entry) => entry.uid.isNotEmpty)
          .toList();
      entries.sort((a, b) => b.earnings.compareTo(a.earnings));
      return entries;
    });
  }

  Future<void> updateCurrentUserEarnings(double earnings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final payload = <String, Object?>{
      'displayName': (user.displayName ?? 'Miner').trim().isEmpty
          ? 'Miner'
          : user.displayName,
    };

    payload['earnings'] = double.parse(earnings.toStringAsFixed(6));
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      payload['photoUrl'] = user.photoURL;
    }
    payload['updatedAt'] = ServerValue.timestamp;

    await _leaderboardRef.child(user.uid).update(payload);
  }
}

