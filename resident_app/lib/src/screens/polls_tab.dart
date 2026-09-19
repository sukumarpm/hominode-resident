// lib/src/screens/polls_tab.dart
// Polls tab with voting functionality

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/poll.dart';
import '../services/poll_repository.dart';
import '../components/poll_card.dart';

class PollsTab extends StatefulWidget {
  const PollsTab({super.key});

  @override
  State<PollsTab> createState() => _PollsTabState();
}

class _PollsTabState extends State<PollsTab> {
  final PollRepository _repository = PollRepository();
  List<Poll> _polls = [];
  bool _isLoading = true;
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
    }
  }

  void _subscribeToUpdates() {
    _pollUpdatesSubscription = _repository.pollUpdates().listen((event) {
      setState(() {
        final index = _polls.indexWhere((p) => p.id == event.pollId);
        if (index != -1 && event.counts != null) {
          final poll = _polls[index];
          final updatedOptions = poll.options.map((opt) {
            return opt.copyWith(votes: event.counts![opt.id] ?? opt.votes);
          }).toList();
          final totalVotes = updatedOptions.fold<int>(0, (sum, opt) => sum + opt.votes);
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

    final pollIndex = _polls.indexWhere((p) => p.id == pollId);
    if (pollIndex == -1) return;

    final originalPoll = _polls[pollIndex];
    
    // Optimistic update
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
        _showError('Failed to submit vote');
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_polls.isEmpty) {
      return const Center(
        child: Text('No polls available', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
}
