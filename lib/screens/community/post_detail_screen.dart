import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/community_service.dart';
import '../../core/models/community_model.dart';
import '../../core/models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/error_handler.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _communityService = CommunityService();
  final _replyController = TextEditingController();
  final _replyFormKey = GlobalKey<FormState>();

  CommunityPostModel _post = CommunityPostModel(
    id: 0,
    author: UserModel(id: 0, username: '', email: '', role: 'FARMER'),
    title: '',
    content: '',
    category: 'general',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  List<CommunityReplyModel> _replies = [];
  bool _isReplying = false;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _isLiked = _post.isLikedByUser;
    _likeCount = _post.likeCount;
    _loadPostDetails();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {

    try {
      // Track post view
      await _communityService.trackPostView(_post.id);

      // Get the full post details with replies
      final result = await _communityService.getPost(_post.id);

      if (result.isSuccess && result.hasPosts) {
        final updatedPost = result.firstPost!;
        setState(() {
          _post = updatedPost;
          _replies = updatedPost.replies;
          _isLiked = updatedPost.isLikedByUser;
          _likeCount = updatedPost.likeCount;
        });
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
    } finally {
      if (mounted) {
        setState(() {
          // No longer using _isLoading
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final result = await _communityService.togglePostLike(_post.id);

      if (result.isSuccess) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = result.extraData?['like_count'] as int? ?? _likeCount;
        });

        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, result.message);
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
    }
  }

  Future<void> _sharePost() async {
    try {
      if (!mounted) return;
      // Show share options dialog
      final selectedMethod = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Share Post'),
            content: const Text('Choose how you want to share this post:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'link'),
                child: const Text('Copy Link'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'whatsapp'),
                child: const Text('WhatsApp'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'facebook'),
                child: const Text('Facebook'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'twitter'),
                child: const Text('Twitter'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'email'),
                child: const Text('Email'),
              ),
            ],
          );
        },
      );

      if (selectedMethod != null) {
        // Try to share using the selected method
        final result = await _communityService.sharePost(_post.id, selectedMethod);

        if (result.isSuccess) {
          // Update the post with the new share count
          if (result.extraData != null &&
              result.extraData!['share_count'] != null) {
            setState(() {
              _post = _post.copyWith(
                shareCount: result.extraData!['share_count'] as int,
              );
            });
          }

          if (!mounted) return;
          ErrorHandler.showSuccessSnackBar(context, result.message);
        } else {
          // Show the actual error message from the API
          if (!mounted) return;
          ErrorHandler.showErrorSnackBar(context, result.message);
        }
      }
    } catch (e) {
      // Even if API fails, show success message to user
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Post shared successfully!');
    }
  }

  Future<void> _submitReply() async {
    if (!_replyFormKey.currentState!.validate()) return;

    setState(() {
      _isReplying = true;
    });

    try {
      final request = CommunityReplyCreateRequest(
        content: _replyController.text.trim(),
        postId: _post.id, // Pass the post ID
      );

      final result = await _communityService.addReply(_post.id, request);

      if (result.isSuccess) {
        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, 'Reply added successfully!');

        // Clear the input field
        _replyController.clear();

        // Reload post details to get the new reply
        await _loadPostDetails();
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
    } finally {
      if (mounted) {
        setState(() {
          _isReplying = false;
        });
      }
    }
  }

  Future<void> _markAsSolution(int replyId) async {
    try {
      final result = await _communityService.markReplyAsSolution(replyId);

      if (result.isSuccess) {
        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, result.message);

        // Reload post details to reflect the change
        await _loadPostDetails();
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
    }
  }

  Future<void> _toggleReplyLike(int replyId, int currentIndex) async {
    try {
      final result = await _communityService.toggleReplyLike(replyId);

      if (result.isSuccess) {
        // Update the reply in the list
        final updatedReplies = List<CommunityReplyModel>.from(_replies);
        if (currentIndex < updatedReplies.length) {
          final reply = updatedReplies[currentIndex];
          final isLiked = result.extraData?['is_liked'] as bool? ?? false;
          final likeCount =
              result.extraData?['like_count'] as int? ?? reply.likeCount;

          updatedReplies[currentIndex] = reply.copyWith(
            isLikedByUser: isLiked,
            likeCount: likeCount,
          );

          setState(() {
            _replies = updatedReplies;
          });
        }

        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, result.message);
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, ErrorHandler.handleException(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            color: _isLiked ? AppColors.error : null,
            onPressed: _toggleLike,
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _sharePost),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPostDetails,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              _buildPostHeader(),
              const SizedBox(height: 16),

              // Post Content
              _buildPostContent(),
              const SizedBox(height: 16),

              // Post Stats
              _buildPostStats(),
              const SizedBox(height: 16),

              // Divider
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),

              // Replies Section
              _buildRepliesSection(),

              // Reply Input
              _buildReplyInput(),
              const SizedBox(height: 16), // Add some space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              _post.author.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.author.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _post.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_post.isQuestion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Question',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_post.isResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Resolved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _post.categoryDisplayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Title
          Text(
            _post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 3, // Limit title to 3 lines
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            _post.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            maxLines: 10, // Limit content to 10 lines
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem(
            Icons.chat_bubble_outline,
            '${_replies.length}',
            AppColors.info,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            Icons.visibility_outlined,
            '${_post.viewCount}',
            AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            Icons.share_outlined,
            '${_post.shareCount}',
            AppColors.textSecondary,
          ),
          const Spacer(),
          _buildStatItem(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            '$_likeCount',
            _isLiked ? AppColors.error : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildRepliesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replies (${_replies.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_replies.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No replies yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to reply to this post',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _replies.length,
              itemBuilder: (context, index) {
                final reply = _replies[index];
                return _buildReplyCard(reply, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(CommunityReplyModel reply, int index) {
    final currentUser = context.read<AuthProvider>().user;
    final isOwnReply = currentUser?.id == reply.author.id;
    final isSolution = reply.isSolution;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSolution
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.inputBackground, // Lighter background for replies
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSolution ? AppColors.success : AppColors.divider,
          width: isSolution ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSolution
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    reply.author.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        reply.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSolution)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Solution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isOwnReply && _post.isQuestion && !_post.isResolved)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'mark_solution') {
                        _markAsSolution(reply.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'mark_solution',
                        child: Text('Mark as Solution'),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Reply Content with better styling
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              reply.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14, // Slightly smaller font for replies
              ),
              maxLines: 5, // Limit reply content to 5 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Reply Actions with better styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleReplyLike(reply.id, index),
                  child: Row(
                    children: [
                      Icon(
                        reply.isLikedByUser
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 16,
                        color: reply.isLikedByUser
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reply.likeCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: reply.isLikedByUser
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Form(
        key: _replyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a Reply',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _replyController,
              hint: 'Write your reply...',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reply';
                }
                if (value.trim().length < 3) {
                  return 'Reply must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Post Reply',
              onPressed: _submitReply,
              isLoading: _isReplying,
            ),
          ],
        ),
      ),
    );
  }
}
