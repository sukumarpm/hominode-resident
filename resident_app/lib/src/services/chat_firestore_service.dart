// lib/src/services/chat_firestore_service.dart
// Firestore service for chat functionality

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_model.dart';
import 'firestore_auth_service.dart';
import 'user_data_service.dart';

class ChatFirestoreService {
  // Singleton pattern
  static final ChatFirestoreService instance = ChatFirestoreService._internal();
  factory ChatFirestoreService() => instance;
  ChatFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserDataService _userDataService = UserDataService.instance;
  final FirestoreAuthService _authService = FirestoreAuthService.instance;

  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String chatRequestsCollection = 'chatRequests';
  static const String usersCollection = 'users';

  // Cache user ID to avoid repeated queries
  String? _cachedUserId;
  DateTime? _cacheTime;

  /// Get current user ID with caching for performance
  /// Tries Firebase Auth first, then falls back to SharedPreferences
  /// IMPORTANT: Always validates user exists in Firestore
  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    try {
      // Return cached value if available and not expired (cache for 5 minutes)
      if (!forceRefresh &&
          _cachedUserId != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!).inMinutes < 5) {
        print('⚡ ChatService: Using cached user ID: $_cachedUserId');
        return _cachedUserId;
      }

      String? userId;

      // First try Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('📱 ChatService: Firebase Auth User: ${firebaseUser.uid}');

        // Try to find user document by Firebase Auth UID
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          print('✅ ChatService: Found user document by Firebase Auth UID');
          userId = doc.id;
        } else {
          // Try to find by authUid field
          print('🔍 ChatService: Searching by authUid field...');
          final querySnapshot = await _firestore
              .collection('users')
              .where('authUid', isEqualTo: firebaseUser.uid)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            print('✅ ChatService: Found user document by authUid field');
            userId = querySnapshot.docs.first.id;
          }
        }
      }

      // Fall back to SharedPreferences if Firebase Auth didn't work
      if (userId == null) {
        print(
          '⚠️  ChatService: No Firebase Auth user, trying SharedPreferences...',
        );
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');

        if (userId != null) {
          print(
            '📱 ChatService: Using user ID from SharedPreferences: $userId',
          );

          // Validate user exists in Firestore
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (!userDoc.exists) {
            print('❌ ChatService: User document not found in Firestore');
            return null;
          }
        }
      }

      if (userId == null) {
        print('❌ ChatService: No user ID found');
        return null;
      }

      // Cache the result
      _cachedUserId = userId;
      _cacheTime = DateTime.now();

      return userId;
    } catch (e) {
      print('❌ ChatService: Error getting user ID: $e');
      return null;
    }
  }

  /// Clear cached user ID (call this on logout)
  void clearCache() {
    _cachedUserId = null;
    _cacheTime = null;
    print('🗑️  ChatService: Cache cleared');
  }

  /// Public method to get current user ID (for UI components)
  Future<String?> getCurrentUserIdPublic() async {
    return await _getCurrentUserId();
  }

  /// Synchronous method to get current user ID from Firebase Auth
  /// Returns null if no user is logged in
  String? getCurrentUserIdSync() {
    return _auth.currentUser?.uid;
  }

  /// Get current user data
  Future<Map<String, dynamic>?> _getCurrentUserData() async {
    return await _userDataService.getCurrentUserData();
  }

  // ============================================================================
  // CHAT OPERATIONS
  // ============================================================================

  /// Stream all chats for current user
  Stream<List<ChatModel>> streamUserChats() async* {
    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        print('❌ ChatService: No user logged in');
        yield [];
        return;
      }

      print('📡 ChatService: Streaming chats for user: $userId');

      yield* _firestore
          .collection(chatsCollection)
          .where('participantIds', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
            print('📊 ChatService: Received ${snapshot.docs.length} chats');

            // Sort Firestore documents in memory.
            final docs = snapshot.docs.toList();

            docs.sort((a, b) {
              final aData = a.data();
              final bData = b.data();

              final aTimestamp = aData['updatedAt'] as Timestamp?;
              final bTimestamp = bData['updatedAt'] as Timestamp?;

              if (aTimestamp == null && bTimestamp == null) return 0;
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;

              return bTimestamp.compareTo(aTimestamp);
            });

            return docs
                .map((doc) {
                  try {
                    return ChatModel.fromFirestore(doc);
                  } catch (e) {
                    print('⚠️ ChatService: Error parsing chat ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<ChatModel>()
                .toList();
          });
    } catch (e) {
      print('❌ ChatService: Error streaming chats: $e');
      rethrow;
    }
  }

  /// Get a specific chat by ID
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .get();

      if (!doc.exists) {
        print('❌ ChatService: Chat not found: $chatId');
        return null;
      }

      return ChatModel.fromFirestore(doc);
    } catch (e) {
      print('❌ ChatService: Error getting chat: $e');
      return null;
    }
  }

  /// Create a new chat
  Future<String?> createChat({
    required String title,
    String? subtitle,
    required List<String> participantIds,
    bool isGroup = false,
    String? buildingId,
    String? flatId,
    String? iconName,
    String? iconBg,
  }) async {
    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        print('❌ ChatService: No user logged in');
        return null;
      }

      // Ensure current user is in participants
      if (!participantIds.contains(userId)) {
        participantIds.add(userId);
      }

      final now = FieldValue.serverTimestamp();

      final chatData = {
        'title': title,
        'subtitle': subtitle,
        'participants': participantIds, // Array field for queries
        'participantIds': participantIds, // Keep for compatibility
        'lastMessage': null,
        'lastMessageTime': null,
        'unreadCount': 0,
        'iconName': iconName,
        'iconBg': iconBg,
        'isGroup': isGroup,
        'buildingId': buildingId,
        'flatId': flatId,
        'createdAt': now,
        'updatedAt': now, // Important: set updatedAt for ordering
      };

      final docRef = await _firestore.collection(chatsCollection).add(chatData);

      print('✅ ChatService: Chat created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ ChatService: Error creating chat: $e');
      print('   Error details: ${e.toString()}');
      return null;
    }
  }

  /// Find or create a direct chat with another user
  Future<String?> findOrCreateDirectChat({
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        print('❌ ChatService: No user logged in');
        return null;
      }

      // Check if chat already exists
      final existingChats = await _firestore
          .collection(chatsCollection)
          .where('participantIds', arrayContains: userId)
          .where('isGroup', isEqualTo: false)
          .get();

      for (var doc in existingChats.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participantIds.contains(otherUserId) &&
            chat.participantIds.length == 2) {
          print('✅ ChatService: Found existing chat: ${doc.id}');
          return doc.id;
        }
      }

      // Create new chat
      print('📝 ChatService: Creating new direct chat');
      return await createChat(
        title: otherUserName,
        participantIds: [userId, otherUserId],
        isGroup: false,
      );
    } catch (e) {
      print('❌ ChatService: Error finding/creating chat: $e');
      return null;
    }
  }

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  /// Stream messages for a specific chat
  Stream<List<MessageModel>> streamChatMessages(String chatId) {
    try {
      print('📡 ChatService: Streaming messages for chat: $chatId');

      return _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            print('📊 ChatService: Received ${snapshot.docs.length} messages');

            return snapshot.docs
                .map((doc) {
                  try {
                    return MessageModel.fromFirestore(doc);
                  } catch (e) {
                    print(
                      '⚠️  ChatService: Error parsing message ${doc.id}: $e',
                    );
                    return null;
                  }
                })
                .whereType<MessageModel>()
                .toList();
          });
    } catch (e) {
      print('❌ ChatService: Error streaming messages: $e');
      return Stream.value([]);
    }
  }

  /// Send a message
  Future<String?> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final userData = await _getCurrentUserData();

      if (userId == null || userData == null) {
        print('❌ ChatService: No user logged in');
        return null;
      }

      final senderName = userData['name'] ?? 'Unknown';
      final senderPhotoUrl = userData['photoUrl'] ?? userData['profileImage'];

      // Create message
      final messageData = {
        'chatId': chatId,
        'senderId': userId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': MessageStatus.sent.toString().split('.').last,
        'readBy': [userId], // Sender has read it
        'imageUrl': imageUrl,
        'fileUrl': fileUrl,
        'fileName': fileName,
      };

      // Add message to subcollection
      final messageRef = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .add(messageData);

      // Update chat's last message
      await _firestore.collection(chatsCollection).doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ ChatService: Message sent: ${messageRef.id}');
      return messageRef.id;
    } catch (e) {
      print('❌ ChatService: Error sending message: $e');
      return null;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        return;
      }

      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .doc(messageId)
          .update({
            'readBy': FieldValue.arrayUnion([userId]),
            'status': MessageStatus.read.toString().split('.').last,
          });

      print('✅ ChatService: Message marked as read: $messageId');
    } catch (e) {
      print('❌ ChatService: Error marking message as read: $e');
    }
  }

  /// Mark all messages in chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        return;
      }

      // Get unread messages
      final messages = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .where('senderId', isNotEqualTo: userId)
          .get();

      // Mark each as read
      final batch = _firestore.batch();

      for (var doc in messages.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection(chatsCollection).doc(chatId).update({
        'unreadCount': 0,
      });

      print('✅ ChatService: Chat marked as read: $chatId');
    } catch (e) {
      print('❌ ChatService: Error marking chat as read: $e');
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .doc(messageId)
          .delete();

      print('✅ ChatService: Message deleted: $messageId');
      return true;
    } catch (e) {
      print('❌ ChatService: Error deleting message: $e');
      return false;
    }
  }

  /// Delete a chat
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messages = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesSubcollection)
          .get();

      final batch = _firestore.batch();

      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete chat document
      await _firestore.collection(chatsCollection).doc(chatId).delete();

      print('✅ ChatService: Chat deleted: $chatId');
      return true;
    } catch (e) {
      print('❌ ChatService: Error deleting chat: $e');
      return false;
    }
  }

  // ============================================================================
  // CHAT REQUEST OPERATIONS
  // ============================================================================

  /// Send a chat request to another user
  Future<String?> sendChatRequest({
    required String toUserId,
    required String toUserName,
    String? message,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final userData = await _getCurrentUserData();

      if (userId == null || userData == null) {
        print('❌ ChatService: No user logged in');
        return null;
      }

      final userFlatId = userData['flatId'];

      if (userFlatId == null || userFlatId.isEmpty) {
        print('❌ ChatService: No flat ID found');
        return null;
      }

      // Check if request already exists
      final existingRequest = await _firestore
          .collection(chatRequestsCollection)
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('⚠️  ChatService: Request already sent');
        return existingRequest.docs.first.id;
      }

      // Check if chat already exists
      final existingChat = await _findExistingDirectChat(userId, toUserId);
      if (existingChat != null) {
        print('⚠️  ChatService: Chat already exists');
        return null; // Return null to indicate chat exists
      }

      final requestData = {
        'senderId': userId,
        'senderName': userData['name'] ?? 'Unknown',
        'senderPhoto': userData['photoUrl'] ?? userData['profileImage'],
        'receiverId': toUserId,
        'receiverName': toUserName,
        'flatId': userFlatId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(chatRequestsCollection)
          .add(requestData);

      print('✅ ChatService: Chat request sent: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ ChatService: Error sending chat request: $e');
      return null;
    }
  }

  /// Find existing direct chat between two users
  Future<String?> _findExistingDirectChat(
    String userId1,
    String userId2,
  ) async {
    try {
      final chats = await _firestore
          .collection(chatsCollection)
          .where('participantIds', arrayContains: userId1)
          .where('isGroup', isEqualTo: false)
          .get();

      for (var doc in chats.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participantIds.contains(userId2) &&
            chat.participantIds.length == 2) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      print('❌ ChatService: Error finding existing chat: $e');
      return null;
    }
  }

  /// Accept a chat request
  Future<String?> acceptChatRequest(String requestId) async {
    try {
      // Get request
      final requestDoc = await _firestore
          .collection(chatRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('❌ ChatService: Request not found');
        return null;
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final senderId = requestData['senderId'];
      final senderName = requestData['senderName'];
      final receiverName = requestData['receiverName'];
      final flatId = requestData['flatId'];

      // Update request status
      await _firestore.collection(chatRequestsCollection).doc(requestId).update(
        {'status': 'accepted', 'respondedAt': FieldValue.serverTimestamp()},
      );

      // Create chat with sorted participant IDs for consistency
      final userId = await _getCurrentUserId();
      if (userId == null) return null;

      final participantIds = [senderId, userId]..sort();
      final chatId = '${participantIds[0]}_${participantIds[1]}';

      // Check if chat already exists
      final existingChat = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .get();

      if (!existingChat.exists) {
        final now = FieldValue.serverTimestamp();

        // Create new chat document with both participant names
        await _firestore.collection(chatsCollection).doc(chatId).set({
          'chatId': chatId,
          'participants': participantIds, // Array field for queries
          'participantIds': participantIds, // Keep for compatibility
          'participantNames': {senderId: senderName, userId: receiverName},
          'flatId': flatId,
          'type': 'resident',
          'isGroup': false,
          'title': senderName,
          'lastMessage': null,
          'lastMessageTime': null,
          'unreadCount': 0,
          'createdAt': now,
          'updatedAt': now, // Important: set updatedAt for ordering
        });

        print('✅ ChatService: Chat created: $chatId');
        print('   Sender: $senderName ($senderId)');
        print('   Receiver: $receiverName ($userId)');
      }

      print('✅ ChatService: Chat request accepted');
      return chatId;
    } catch (e) {
      print('❌ ChatService: Error accepting chat request: $e');
      print('   Error details: ${e.toString()}');
      return null;
    }
  }

  /// Reject a chat request
  Future<bool> rejectChatRequest(String requestId) async {
    try {
      await _firestore
          .collection(chatRequestsCollection)
          .doc(requestId)
          .update({
            'status': ChatRequestStatus.rejected.toString().split('.').last,
            'respondedAt': FieldValue.serverTimestamp(),
          });

      print('✅ ChatService: Chat request rejected');
      return true;
    } catch (e) {
      print('❌ ChatService: Error rejecting chat request: $e');
      return false;
    }
  }

  /// Stream incoming chat requests for current user
  /// OPTIMIZED: Direct query with minimal overhead
  /// Flow Function:
  /// 1. Get Firebase Auth UID
  /// 2. Query users by authUid to get user document ID
  /// 3. Query chatRequests by receiverId (user document ID)
  /// Stream incoming chat requests for current user
  /// Flow Function: Get user ID → Query chatRequests by receiverId → Filter by status = 'pending'
  Stream<List<ChatRequestModel>> streamIncomingChatRequests() async* {
    try {
      print('📡 ChatService: Initializing chat requests stream...');

      final userId = await _getCurrentUserId();

      if (userId == null) {
        print('❌ ChatService: No user logged in');
        yield [];
        return;
      }

      print('⚡ ChatService: User ID: $userId');
      print('📡 ChatService: Starting requests stream for user: $userId');

      yield* _firestore
          .collection(chatRequestsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            print(
              '📊 ChatService: Received ${snapshot.docs.length} chat request(s)',
            );

            final docs = snapshot.docs.toList();

            // Sort newest first in memory.
            docs.sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            return docs
                .map((doc) {
                  try {
                    return ChatRequestModel.fromFirestore(doc);
                  } catch (e) {
                    print(
                      '⚠️ ChatService: Error parsing request ${doc.id}: $e',
                    );
                    return null;
                  }
                })
                .whereType<ChatRequestModel>()
                .toList();
          });
    } catch (e) {
      print('❌ ChatService: Error in chat requests stream: $e');
      rethrow;
    }
  }

  /// Get building members from users collection (same building)
  /// Flow Function: Matches users by buildingId (NOT flatId)
  /// Excludes current user from results
  /// Fetches FLAT members (same flat), not building members
  Future<List<Map<String, dynamic>>> getBuildingMembers() async {
    try {
      print('\n═══════════════════════════════════════════════════');
      print('📋 FETCHING FLAT MEMBERS (Same Flat Only)');
      print('═══════════════════════════════════════════════════\n');

      // STEP 1: Get current user UID from Firebase Auth or Firestore Auth
      print('📋 STEP 1: Get Current User UID');

      // Try Firebase Auth first
      var firebaseUser = _auth.currentUser;
      String? currentAuthUid;

      if (firebaseUser != null) {
        currentAuthUid = firebaseUser.uid;
        print('✅ Firebase Auth UID: $currentAuthUid\n');
      } else {
        // Fall back to Firestore Auth
        print('⚠️  No Firebase Auth user, trying Firestore Auth...');
        final firestoreUserId = await _authService.getCurrentUserId();

        if (firestoreUserId == null) {
          print('❌ No user logged in (Firebase Auth or Firestore Auth)');
          return [];
        }

        // For Firestore Auth, we already have the user ID
        print('✅ Using Firestore user ID: $firestoreUserId\n');

        // Query user document to get flatId
        final userDoc = await _firestore
            .collection('users')
            .doc(firestoreUserId)
            .get();
        if (!userDoc.exists) {
          print('❌ User document not found');
          return [];
        }

        final userData = userDoc.data();
        final flatId = userData?['flatId'];

        if (flatId == null || flatId.isEmpty) {
          print('❌ User has no flatId');
          return [];
        }

        print('✅ Current User Found:');
        print('   User ID: $firestoreUserId');
        print('   Name: ${userData?['name']}');
        print('   flatId: $flatId\n');

        // Query flat members (same flat only)
        print('📋 STEP 2: Query Flat Members');
        print('🔍 Query: users.where("flatId", isEqualTo: "$flatId")\n');

        final flatMembersQuery = await _firestore
            .collection('users')
            .where('flatId', isEqualTo: flatId)
            .get();

        print(
          '📊 Query Results: ${flatMembersQuery.docs.length} documents found\n',
        );

        // Filter out current user
        print('📋 STEP 3: Filter Results (Exclude Current User)\n');

        final List<Map<String, dynamic>> members = [];

        for (var doc in flatMembersQuery.docs) {
          final memberData = doc.data();

          // Exclude current user - DO NOT SHOW SAME USER
          if (doc.id == firestoreUserId) {
            print('⏭️  Skipping current user: ${memberData['name']}');
            continue;
          }

          String displayFlatNumber = 'Unknown';
          if (memberData['flatNumber'] != null &&
              memberData['flatNumber'].toString().isNotEmpty) {
            displayFlatNumber = memberData['flatNumber'].toString();
          } else if (memberData['flatLabel'] != null &&
              memberData['flatLabel'].toString().isNotEmpty &&
              memberData['flatLabel'] != memberData['flatId']) {
            displayFlatNumber = memberData['flatLabel'].toString();
          }

          members.add({
            'id': doc.id,
            'name': memberData['name'] ?? 'Unknown',
            'email': memberData['email'],
            'phone': memberData['phone'],
            'photoUrl': memberData['photoUrl'] ?? memberData['profileImage'],
            'flatId': memberData['flatId'],
            'flatNumber': displayFlatNumber,
            'buildingId': memberData['buildingId'],
            'buildingName': memberData['buildingName'],
            'authUid': memberData['authUid'],
          });

          print('✅ Added building member: ${memberData['name']}');
          print('   User ID: ${doc.id}');
          print('   Flat: $displayFlatNumber');
          print('   buildingId: ${memberData['buildingId']}\n');
        }

        print('═══════════════════════════════════════════════════');
        print('✅ RESULT: Found ${members.length} building member(s)');
        print('═══════════════════════════════════════════════════\n');

        members.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        return members;
      }

      print('✅ Firebase Auth UID: $currentAuthUid\n');

      // STEP 2: Fetch current user document from users collection
      print('📋 STEP 2: Fetch Current User Document');
      print('🔍 Query: users.where("authUid", isEqualTo: "$currentAuthUid")');

      final currentUserQuery = await _firestore
          .collection('users')
          .where('authUid', isEqualTo: currentAuthUid)
          .limit(1)
          .get();

      if (currentUserQuery.docs.isEmpty) {
        print('❌ User document not found for authUid: $currentAuthUid');
        return [];
      }

      final currentUserDoc = currentUserQuery.docs.first;
      final currentUserId = currentUserDoc.id;
      final currentUserData = currentUserDoc.data();

      final currentUserBuildingId = currentUserData['buildingId'];
      final currentUserBuildingName = currentUserData['buildingName'];

      print('✅ Current User Found:');
      print('   User ID: $currentUserId');
      print('   Name: ${currentUserData['name']}');
      print('   buildingId: $currentUserBuildingId');
      print('   buildingName: $currentUserBuildingName\n');

      if (currentUserBuildingId == null || currentUserBuildingId.isEmpty) {
        print('❌ Current user has no buildingId');
        return [];
      }

      // STEP 3: Query Firestore for building members (same building)
      print('📋 STEP 3: Query Building Members');
      print(
        '🔍 Query: users.where("buildingId", isEqualTo: "$currentUserBuildingId")\n',
      );

      final buildingMembersQuery = await _firestore
          .collection('users')
          .where('buildingId', isEqualTo: currentUserBuildingId)
          .get();

      print(
        '📊 Query Results: ${buildingMembersQuery.docs.length} documents found\n',
      );

      // STEP 4: Remove logged-in user from list
      print('📋 STEP 4: Filter Results (Exclude Current User)\n');

      final List<Map<String, dynamic>> members = [];

      for (var doc in buildingMembersQuery.docs) {
        final memberData = doc.data();
        final memberAuthUid = memberData['authUid'];

        // Exclude current user
        if (memberAuthUid == currentAuthUid) {
          print('⏭️  Skipping current user: ${memberData['name']}');
          continue;
        }

        // Determine flat number display
        // Priority: flatNumber > flatLabel (if not same as flatId) > "Unknown"
        String displayFlatNumber = 'Unknown';

        if (memberData['flatNumber'] != null &&
            memberData['flatNumber'].toString().isNotEmpty) {
          displayFlatNumber = memberData['flatNumber'].toString();
        } else if (memberData['flatLabel'] != null &&
            memberData['flatLabel'].toString().isNotEmpty &&
            memberData['flatLabel'] != memberData['flatId']) {
          // Only use flatLabel if it's different from flatId (not a duplicate)
          displayFlatNumber = memberData['flatLabel'].toString();
        }

        // Add to members list
        members.add({
          'id': doc.id,
          'name': memberData['name'] ?? 'Unknown',
          'email': memberData['email'],
          'phone': memberData['phone'],
          'photoUrl': memberData['photoUrl'] ?? memberData['profileImage'],
          'flatId': memberData['flatId'],
          'flatNumber': displayFlatNumber,
          'buildingId': memberData['buildingId'],
          'buildingName': memberData['buildingName'],
          'authUid': memberData['authUid'],
        });

        print('✅ Added building member: ${memberData['name']}');
        print('   User ID: ${doc.id}');
        print('   Flat: $displayFlatNumber');
        print('   buildingId: ${memberData['buildingId']}\n');
      }

      print('═══════════════════════════════════════════════════');
      print('✅ RESULT: Found ${members.length} building member(s)');
      print('═══════════════════════════════════════════════════\n');

      // Sort by name
      members.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      return members;
    } catch (e) {
      print('❌ ChatService: Error fetching building members: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get admin chat or create one with real admin user
  Future<String?> getOrCreateAdminChat() async {
    try {
      final userId = await _getCurrentUserId();
      final userData = await _getCurrentUserData();

      if (userId == null || userData == null) {
        print('❌ ChatService: No user logged in');
        return null;
      }

      final buildingId = userData['buildingId'];

      if (buildingId == null || buildingId.isEmpty) {
        print('⚠️  ChatService: No building ID');
        return null;
      }

      // Check if admin chat already exists
      final existingChats = await _firestore
          .collection(chatsCollection)
          .where('participantIds', arrayContains: userId)
          .where('type', isEqualTo: 'admin')
          .where('buildingId', isEqualTo: buildingId)
          .get();

      if (existingChats.docs.isNotEmpty) {
        print('✅ ChatService: Found existing admin chat');
        return existingChats.docs.first.id;
      }

      // Find admin user for this building
      print('📋 ChatService: Looking for admin user in building: $buildingId');

      final adminSnapshot = await _firestore
          .collection(usersCollection)
          .where('buildingId', isEqualTo: buildingId)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      String adminId;
      String adminName;
      String? adminPhoto;

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData = adminSnapshot.docs.first.data();
        adminId = adminSnapshot.docs.first.id;
        adminName = adminData['name'] ?? 'Building Admin';
        adminPhoto = adminData['photoUrl'] ?? adminData['profileImage'];
        print('✅ ChatService: Found admin user: $adminName');
      } else {
        // No admin found, create placeholder
        print(
          '⚠️  ChatService: No admin user found, creating placeholder chat',
        );
        adminId = 'admin_$buildingId';
        adminName = 'Building Admin';
        adminPhoto = null;
      }

      // Create new admin chat with both user and admin as participants
      print('📝 ChatService: Creating new admin chat');

      final participantIds = [userId, adminId]..sort();
      final chatId = 'admin_${buildingId}_$userId';

      final now = FieldValue.serverTimestamp();

      final chatData = {
        'chatId': chatId,
        'title': adminName,
        'subtitle': 'Support & Assistance',
        'participants': participantIds, // Array field for queries
        'participantIds': participantIds, // Keep for compatibility
        'lastMessage': null,
        'lastMessageTime': null,
        'unreadCount': 0,
        'iconName': 'support_agent',
        'iconBg': '#10B981',
        'iconUrl': adminPhoto,
        'isGroup': false,
        'type': 'admin',
        'buildingId': buildingId,
        'adminId': adminId,
        'createdAt': now,
        'updatedAt': now, // Important: set updatedAt for ordering
      };

      await _firestore.collection(chatsCollection).doc(chatId).set(chatData);

      print('✅ ChatService: Admin chat created: $chatId');
      return chatId;
    } catch (e) {
      print('❌ ChatService: Error creating admin chat: $e');
      print('   Error details: ${e.toString()}');
      return null;
    }
  }
}
