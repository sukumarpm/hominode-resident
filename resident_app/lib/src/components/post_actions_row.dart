// lib/src/components/post_actions_row.dart
// Post actions row with like, comment, share

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const kLikeRed = Color(0xFFFF3B30);
const kIconGray = Color(0xFF8C8C8C);

class PostActionsRow extends StatelessWidget {
  final int likes;
  final int comments;
  final bool isLiked;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const PostActionsRow({
    super.key,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button
        InkWell(
          onTap: onLikePressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? kLikeRed : kIconGray,
                  size: 22.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$likes',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: isLiked ? kLikeRed : kIconGray,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 20.w),

        // Comment button
        InkWell(
          onTap: onCommentPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: kIconGray, size: 22.w),
                SizedBox(width: 6.w),
                Text(
                  '$comments',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: kIconGray,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 20.w),

        // Share button
        InkWell(
          onTap: onSharePressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              children: [
                Icon(Icons.share_outlined, color: kIconGray, size: 22.w),
                SizedBox(width: 6.w),
                Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: kIconGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
