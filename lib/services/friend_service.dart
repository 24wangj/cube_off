import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Returns list of friend userIds for the given user.
  Future<List<String>> getFriendIds(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  // Add a friend (creates a doc under users/{userId}/friends/{friendId})
  Future<void> addFriend(String userId, String friendId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .set({'addedAt': DateTime.now().millisecondsSinceEpoch});
  }

  // Remove friend
  Future<void> removeFriend(String userId, String friendId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .delete();
  }

  // Friend request operations. Requests are stored under the recipient's
  // `incoming_requests` subcollection keyed by the sender id.
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _db
        .collection('users')
        .doc(toUserId)
        .collection('incoming_requests')
        .doc(fromUserId)
        .set({
          'from': fromUserId,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
  }

  Future<List<String>> getIncomingRequests(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('incoming_requests')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<void> acceptFriendRequest(String userId, String fromUserId) async {
    // Add each other as friends
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(userId);
    final fromRef = _db.collection('users').doc(fromUserId);

    final userFriendRef = userRef.collection('friends').doc(fromUserId);
    final fromFriendRef = fromRef.collection('friends').doc(userId);

    batch.set(userFriendRef, {
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.set(fromFriendRef, {
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Remove incoming request
    final reqRef = userRef.collection('incoming_requests').doc(fromUserId);
    batch.delete(reqRef);

    await batch.commit();
  }

  Future<void> rejectFriendRequest(String userId, String fromUserId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('incoming_requests')
        .doc(fromUserId)
        .delete();
  }
}
