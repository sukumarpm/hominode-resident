// lib/community_wall_screen.dart
// Community Wall main screen

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'comments_screen.dart';
import 'src/components/post_card.dart';
import 'src/components/standard_screen.dart';
import 'src/modals/add_post_modal.dart';
import 'src/modals/post_menu_bottomsheet.dart';
import 'src/models/post.dart';
import 'src/services/post_firestore_service.dart';

const kPrimaryBlue = Color(0xFF0E4778);

class CommunityWallScreen extends StatefulWidget {
  const CommunityWallScreen({super.key});

  @override
  State<CommunityWallScreen> createState() => _CommunityWallScreenState();
}

class _CommunityWallScreenState extends State<CommunityWallScreen> {
  final PostFirestoreService _service = PostFirestoreService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _service.getAllPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddPost(String content, String? imageUrl) async {
    try {
      final result = await _service.createPost(
        content: content,
        imageUrl: imageUrl,
      );

      if (result.success) {
        _loadPosts(); // Refresh posts list
        _showSnackBar('Post created successfully!', Colors.green);
      } else {
        _showSnackBar(result.message ?? 'Failed to create post', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to create post', Colors.red);
    }
  }

  Future<void> _handleLike(Post post) async {
    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    // Optimistic update
    final wasLiked = post.isLiked;
    setState(() {
      if (post.isLiked) {
        _posts[postIndex].isLiked = false;
        _posts[postIndex].likes--;
      } else {
        _posts[postIndex].isLiked = true;
        _posts[postIndex].likes++;
      }
    });

    try {
      final result = wasLiked
          ? await _service.unlikePost(post.id)
          : await _service.likePost(post.id);

      if (!result.success) {
        // Revert on error
        setState(() {
          if (wasLiked) {
            _posts[postIndex].isLiked = true;
            _posts[postIndex].likes++;
          } else {
            _posts[postIndex].isLiked = false;
            _posts[postIndex].likes--;
          }
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (wasLiked) {
          _posts[postIndex].isLiked = true;
          _posts[postIndex].likes++;
        } else {
          _posts[postIndex].isLiked = false;
          _posts[postIndex].likes--;
        }
      });
    }
  }

  void _handleComment(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(post: post)),
    ).then((_) {
      // Refresh posts when returning from comments screen
      _loadPosts();
    });
  }

  Future<void> _handleShare(Post post) async {
    try {
      final result = await _service.sharePost(post.id);
      if (result.success) {
        _showSnackBar('Post shared!', Colors.green);
      } else {
        _showSnackBar(result.message ?? 'Failed to share post', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to share post', Colors.red);
    }
  }

  void _handleMenu(Post post) {
    showPostMenu(
      context,
      post,
      onEdit: () => _handleEdit(post),
      onDelete: () => _handleDelete(post),
      onReport: () => _handleReport(post),
    );
  }

  void _handleEdit(Post post) {
    // TODO: Implement edit functionality
    _showSnackBar('Edit feature coming soon', Colors.blue);
  }

  Future<void> _handleDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _service.deletePost(post.id);

        if (result.success) {
          setState(() {
            _posts.removeWhere((p) => p.id == post.id);
          });
          _showSnackBar('Post deleted', Colors.green);
        } else {
          _showSnackBar(result.message ?? 'Failed to delete post', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Failed to delete post', Colors.red);
      }
    }
  }

  Future<void> _handleReport(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _service.reportPost(
          post.id,
          'Inappropriate content',
        );

        if (result.success) {
          _showSnackBar('Post reported', Colors.green);
        } else {
          _showSnackBar(result.message ?? 'Failed to report post', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Failed to report post', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: StandardScreen(
        title: 'Community Wall',
        showBackButton: true,
        isScrollable: false,
        padding: EdgeInsets.zero,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Text(
                    'No posts yet. Be the first to post!',
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPosts,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return PostCard(
                      post: post,
                      onLikePressed: () => _handleLike(post),
                      onCommentPressed: () => _handleComment(post),
                      onSharePressed: () => _handleShare(post),
                      onMenuPressed: () => _handleMenu(post),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddPostModal(context, onSubmit: _handleAddPost);
        },
        backgroundColor: kPrimaryBlue,
        child: Icon(Icons.add, color: Colors.white, size: 28.w),
      ),
    );
  }
}
