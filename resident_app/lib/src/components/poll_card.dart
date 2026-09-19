// lib/src/components/poll_card.dart
// Reusable PollCard widget with vote and results views

import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../widgets/poll_progress_bar.dart';

// Design tokens
const Color kPrimary = Color(0xFF0E4778);
const Color kVotedGreen = Color(0xFF00A84F);
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kCardBorder = Color(0xFFE6E6E6);
const double kCardRadius = 12.0;
const double kSpacing = 16.0;

class PollCard extends StatefulWidget {
  final Poll poll;
  final Function(String optionId)? onVote;
  final bool isSubmitting;
  final bool isQueued;

  const PollCard({
    super.key,
    required this.poll,
    this.onVote,
    this.isSubmitting = false,
    this.isQueued = false,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _selectedOptionId = widget.poll.userVotedOptionId;
  }

  bool get _showResults => widget.poll.hasUserVoted || widget.poll.isClosed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            widget.poll.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Options (vote view or results view)
          if (_showResults) _buildResultsView() else _buildVoteView(),

          const SizedBox(height: 16),

          // Footer: total votes + action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.poll.totalVotes} total votes',
                style: const TextStyle(fontSize: 14, color: kTextMuted),
              ),
              if (widget.isQueued)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Queued',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (_showResults)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kVotedGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Voted',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _selectedOptionId != null && !widget.isSubmitting
                      ? () => widget.onVote?.call(_selectedOptionId!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    minimumSize: const Size(
                      100,
                      44,
                    ), // Accessibility: 44px touch target
                  ),
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Vote Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteView() {
    return Column(
      children: widget.poll.options.map((option) {
        final isSelected = _selectedOptionId == option.id;
        return GestureDetector(
          onTap: widget.isSubmitting
              ? null
              : () {
                  setState(() {
                    _selectedOptionId = option.id;
                  });
                },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? kPrimary : kCardBorder,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? kPrimary : kTextMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Option label
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: widget.poll.options.map((option) {
        final percent = calculatePercent(option.votes, widget.poll.totalVotes);
        final isUserVote = option.id == widget.poll.userVotedOptionId;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Option label and stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: isUserVote
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${option.votes} votes (${formatPercent(percent)})',
                    style: const TextStyle(fontSize: 13, color: kTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              PollProgressBar(
                percent: percent / 100,
                fillColor: Colors.black,
                trackColor: const Color(0xFFE6E6E6),
                height: 6,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
