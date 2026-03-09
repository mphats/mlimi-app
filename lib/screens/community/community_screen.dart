import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/community_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/models/community_model.dart';
import '../../core/utils/error_handler.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _communityService = CommunityService();
  List<CommunityPostModel> _posts = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  final bool _isQuestionFilter = false;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': '${LocalizationService().getString('all')} ${LocalizationService().getString('posts')}'},
    {'value': 'question', 'label': '${LocalizationService().getString('question')}s'},
    {'value': 'advice', 'label': LocalizationService().getString('advice')},
    {'value': 'discussion', 'label': '${LocalizationService().getString('discussion')}s'},
    {'value': 'experience', 'label': '${LocalizationService().getString('experience')}s'},
    {'value': 'problem', 'label': '${LocalizationService().getString('problem')}s'},
    {'value': 'solution', 'label': '${LocalizationService().getString('solution')}s'},
    {'value': 'general', 'label': LocalizationService().getString('general')},
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _communityService.getPosts(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        isQuestion: _isQuestionFilter ? true : null,
      );

      if (result.isSuccess) {
        setState(() {
          _posts = result.posts;
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  void _navigateToCreatePost() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreatePostScreen()))
        .then((value) {
          if (value == true) {
            _loadPosts(); // Refresh posts if a new one was created
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.community,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          const SizedBox(height: 8),

          // Posts List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshPosts,
              child: _buildPostsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category['value']!);
                  _loadPosts();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService().getString('noDataFound'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService().getString('communityForum'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToCreatePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(LocalizationService().getString('createPost')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(CommunityPostModel post) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      post.author.initials,
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
                          post.author.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          post.timeAgo,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (post.isQuestion)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                  if (post.isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
            ),

            // Post Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.categoryDisplayName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Content (truncated)
                  Text(
                    post.content.length > 150
                        ? '${post.content.substring(0, 150)}...'
                        : post.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.chat_bubble_outline,
                        '${post.replyCount}',
                        AppColors.info,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.visibility_outlined,
                        '${post.viewCount}',
                        AppColors.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.share_outlined,
                        '${post.shareCount}',
                        AppColors.textSecondary,
                      ),
                      const Spacer(),
                      _buildStatItem(
                        post.isLikedByUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        '${post.likeCount}',
                        post.isLikedByUser
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
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
}
