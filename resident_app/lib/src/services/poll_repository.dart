// lib/src/services/poll_repository.dart
// Repository for poll data with API stubs, offline queue, and caching

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/poll.dart';
import '../models/poll_option.dart';

/// API Contract:
/// GET /polls?tab=active&page=1 -> List of polls
/// GET /polls/{id} -> Single poll details
/// POST /polls/{id}/vote body: { "optionId": "opt_123" } -> Updated poll
/// WebSocket /ws/polls -> { "type": "vote", "pollId": "...", "optionId": "...", "counts": {...} }

class PollRepository {
  // Singleton pattern
  static final PollRepository _instance = PollRepository._internal();
  factory PollRepository() => _instance;
  PollRepository._internal();

  // Mock data storage
  final Map<String, Poll> _pollCache = {};
  final List<Map<String, String>> _offlineQueue = [];
  final StreamController<PollEvent> _pollUpdatesController =
      StreamController<PollEvent>.broadcast();

  /// Fetch list of polls with pagination
  /// API: GET /polls?tab=active&page=1
  Future<List<Poll>> fetchPolls({int page = 1}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data - replace with actual API call
    final mockPolls = _getMockPolls();
    
    // Cache polls
    for (var poll in mockPolls) {
      _pollCache[poll.id] = poll;
    }

    return mockPolls;
  }

  /// Fetch single poll by ID
  /// API: GET /polls/{id}
  Future<Poll> fetchPoll(String pollId) async {
    // Check cache first
    if (_pollCache.containsKey(pollId)) {
      return _pollCache[pollId]!;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock API call - replace with actual implementation
    final poll = _getMockPolls().firstWhere(
      (p) => p.id == pollId,
      orElse: () => throw Exception('Poll not found'),
    );

    _pollCache[pollId] = poll;
    return poll;
  }

  /// Submit vote for a poll option
  /// API: POST /polls/{pollId}/vote body: { "optionId": "opt_123" }
  /// Returns updated poll on success
  Future<Poll> submitVote(String pollId, String optionId) async {
    // Check network connectivity (mock)
    final isOnline = await _checkConnectivity();

    if (!isOnline) {
      // Queue for offline sync
      await queueVoteWhenOffline(pollId, optionId);
      throw Exception('Offline - vote queued');
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock API call - replace with actual HTTP POST
    // Example: await http.post('/polls/$pollId/vote', body: {'optionId': optionId});

    // Simulate success - update local cache
    final poll = _pollCache[pollId];
    if (poll == null) throw Exception('Poll not found');

    // Update vote counts
    final updatedOptions = poll.options.map((opt) {
      if (opt.id == optionId) {
        return opt.copyWith(votes: opt.votes + 1);
      }
      return opt;
    }).toList();

    final updatedPoll = poll.copyWith(
      options: updatedOptions,
      totalVotes: poll.totalVotes + 1,
      userVotedOptionId: optionId,
    );

    _pollCache[pollId] = updatedPoll;

    // Emit realtime update
    _pollUpdatesController.add(PollEvent(
      type: 'vote',
      pollId: pollId,
      optionId: optionId,
      counts: {for (var opt in updatedOptions) opt.id: opt.votes},
    ));

    return updatedPoll;
  }

  /// Queue vote for offline sync
  /// Stores vote locally (Hive/SharedPreferences) to sync when online
  Future<void> queueVoteWhenOffline(String pollId, String optionId) async {
    _offlineQueue.add({
      'pollId': pollId,
      'optionId': optionId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // TODO: Persist to Hive or SharedPreferences
    // Example: await Hive.box('offline_votes').add({'pollId': pollId, 'optionId': optionId});
    
    debugPrint('Vote queued offline: $pollId -> $optionId');
  }

  /// Sync queued votes when connectivity is restored
  Future<void> syncQueuedVotes() async {
    if (_offlineQueue.isEmpty) return;

    debugPrint('Syncing ${_offlineQueue.length} queued votes...');

    final failedVotes = <Map<String, String>>[];

    for (var vote in _offlineQueue) {
      try {
        await submitVote(vote['pollId']!, vote['optionId']!);
        debugPrint('Synced vote: ${vote['pollId']} -> ${vote['optionId']}');
      } catch (e) {
        debugPrint('Failed to sync vote: $e');
        failedVotes.add(vote);
      }
    }

    _offlineQueue.clear();
    _offlineQueue.addAll(failedVotes);

    // TODO: Update persistent storage
  }

  /// Stream of realtime poll updates
  /// WebSocket topic: /ws/polls
  /// Message format: { "type": "vote", "pollId": "...", "optionId": "...", "counts": {...} }
  Stream<PollEvent> pollUpdates({String? pollId}) {
    // Filter by pollId if provided
    if (pollId != null) {
      return _pollUpdatesController.stream
          .where((event) => event.pollId == pollId);
    }
    return _pollUpdatesController.stream;
  }

  /// Cache polls for instant display
  void cachePolls(List<Poll> polls) {
    for (var poll in polls) {
      _pollCache[poll.id] = poll;
    }
    // TODO: Persist to local storage (Hive/SharedPreferences)
  }

  /// Get cached poll
  Poll? getCachedPoll(String pollId) {
    return _pollCache[pollId];
  }

  /// Mock connectivity check - replace with actual implementation
  Future<bool> _checkConnectivity() async {
    // TODO: Use connectivity_plus package
    // final connectivityResult = await Connectivity().checkConnectivity();
    // return connectivityResult != ConnectivityResult.none;
    return true; // Mock: always online
  }

  /// Mock data generator
  List<Poll> _getMockPolls() {
    return [
      Poll(
        id: 'poll_1',
        question: 'Should we install solar panels on the terrace?',
        options: [
          PollOption(id: 'opt_1_yes', label: 'Yes', votes: 0),
          PollOption(id: 'opt_1_no', label: 'No', votes: 0),
        ],
        totalVotes: 0,
        userVotedOptionId: null, // User hasn't voted
        status: PollStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      ),
      Poll(
        id: 'poll_2',
        question: 'Should we install solar panels on the terrace?',
        options: [
          PollOption(id: 'opt_2_yes', label: 'Yes', votes: 46),
          PollOption(id: 'opt_2_no', label: 'No', votes: 14),
        ],
        totalVotes: 60,
        userVotedOptionId: 'opt_2_yes', // User already voted
        status: PollStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        expiresAt: DateTime.now().add(const Duration(days: 4)),
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _pollUpdatesController.close();
  }
}
