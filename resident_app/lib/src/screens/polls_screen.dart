// lib/src/screens/polls_screen.dart
// Main Polls screen with tabs (Events | Notices | Polls)

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/poll.dart';
import '../services/poll_repository.dart';
import '../components/poll_card.dart';

// Design tokens
const Color kPrimary = Color(0xFF0E4778);
const Color kTabBarBg = Color(0xFFF4F4F6);
const Color kActivePillBg = Colors.white;

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  final PollRepository _repository = PollRepository();
  List<Poll> _polls = [];
  bool _isLoading = true;
  String _selectedTab = 'Polls'; // Default to Polls tab
  final Map<String, bool> _submittingVotes = {};
  final Map<String, bool> _queuedVotes = {};
  StreamSubscription<PollEvent>? _pollUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _loadPolls();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _pollUpdatesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoading = true);
    try {
      final polls = await _repository.fetchPolls(page: 1);
      setState(() {
        _polls = polls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load polls: $e');
    }
  }

  void _subscribeToUpdates() {
    _pollUpdatesSubscription = _repository.pollUpdates().listen((event) {
      // Update poll in list when realtime event received
      setState(() {
        final index = _polls.indexWhere((p) => p.id == event.pollId);
        if (index != -1 && event.counts != null) {
          final poll = _polls[index];
          final updatedOptions = poll.options.map((opt) {
            return opt.copyWith(votes: event.counts![opt.id] ?? opt.votes);
          }).toList();
          final totalVotes = updatedOptions.fold<int>(
            0,
            (sum, opt) => sum + opt.votes,
          );
          _polls[index] = poll.copyWith(
            options: updatedOptions,
            totalVotes: totalVotes,
          );
        }
      });
    });
  }

  Future<void> _handleVote(String pollId, String optionId) async {
    setState(() => _submittingVotes[pollId] = true);

    // Optimistic update
    final pollIndex = _polls.indexWhere((p) => p.id == pollId);
    if (pollIndex == -1) return;

    final originalPoll = _polls[pollIndex];
    final optimisticOptions = originalPoll.options.map((opt) {
      if (opt.id == optionId) {
        return opt.copyWith(votes: opt.votes + 1);
      }
      return opt;
    }).toList();

    final optimisticPoll = originalPoll.copyWith(
      options: optimisticOptions,
      totalVotes: originalPoll.totalVotes + 1,
      userVotedOptionId: optionId,
    );

    setState(() => _polls[pollIndex] = optimisticPoll);

    try {
      final updatedPoll = await _repository.submitVote(pollId, optionId);
      setState(() {
        _polls[pollIndex] = updatedPoll;
        _submittingVotes[pollId] = false;
      });
      _showSuccess('Vote submitted successfully!');
    } catch (e) {
      // Rollback on error
      setState(() {
        _polls[pollIndex] = originalPoll;
        _submittingVotes[pollId] = false;
      });

      if (e.toString().contains('Offline')) {
        setState(() => _queuedVotes[pollId] = true);
        _showInfo('Vote queued - will sync when online');
      } else {
        _showError('Failed to submit vote: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Events & Announcements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kTabBarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('Events'),
                  _buildTab('Notices'),
                  _buildTab('Polls'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 'Polls'
                ? _buildPollsContent()
                : _buildPlaceholderContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isActive = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? kActivePillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.black : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_polls.isEmpty) {
      return const Center(
        child: Text(
          'No polls available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolls,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          final poll = _polls[index];
          return PollCard(
            poll: poll,
            onVote: (optionId) => _handleVote(poll.id, optionId),
            isSubmitting: _submittingVotes[poll.id] ?? false,
            isQueued: _queuedVotes[poll.id] ?? false,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Text(
        '$_selectedTab content coming soon',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
