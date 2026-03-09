import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/community_service.dart';
import '../../core/models/community_model.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class EnhancedCommunityScreen extends StatefulWidget {
  const EnhancedCommunityScreen({super.key});

  @override
  State<EnhancedCommunityScreen> createState() => _EnhancedCommunityScreenState();
}

class _EnhancedCommunityScreenState extends State<EnhancedCommunityScreen> {
  final _communityService = CommunityService();
  List<CommunityPostModel> _posts = [];
  List<CommunityPostModel> _filteredPosts = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  bool _isQuestionFilter = false;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMorePosts = true;
  final int _postsPerPage = 10;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'All Posts'},
    {'value': 'question', 'label': 'Questions'},
    {'value': 'advice', 'label': 'Advice'},
    {'value': 'discussion', 'label': 'Discussions'},
    {'value': 'experience', 'label': 'Experiences'},
    {'value': 'problem', 'label': 'Problems'},
    {'value': 'solution', 'label': 'Solutions'},
    {'value': 'general', 'label': 'General'},
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePosts = true;
    }

    if (!_hasMorePosts && !refresh) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _communityService.getPosts(
        page: _currentPage,
        pageSize: _postsPerPage,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        isQuestion: _isQuestionFilter ? true : null,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (result.isSuccess) {
        if (refresh) {
          _posts = result.posts;
        } else {
          _posts.addAll(result.posts);
        }

        // Apply filters
        _applyFilters();

        setState(() {
          _hasMorePosts = result.posts.length == _postsPerPage;
          _currentPage++;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _posts.where((post) {
        // Category filter
        bool categoryMatch = _selectedCategory == 'all' ||
            post.category == _selectedCategory;

        // Question filter
        bool questionMatch = !_isQuestionFilter || post.isQuestion;

        // Search filter
        bool searchMatch = _searchQuery.isEmpty ||
            post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            post.content.toLowerCase().contains(_searchQuery.toLowerCase());

        return categoryMatch && questionMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _refreshPosts() async {
    await _loadPosts(refresh: true);
  }

  void _navigateToCreatePost() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreatePostScreen()))
        .then((value) {
          if (value == true) {
            _loadPosts(refresh: true); // Refresh posts if a new one was created
          }
        });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.community),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPosts),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Filters
          _buildFilters(),
          const SizedBox(height: 16),

          // Posts List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _buildPostsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search posts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.inputBackground,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category['value'],
                          child: Text(category['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Questions'),
                selected: _isQuestionFilter,
                selectedColor: AppColors.primary,
                onSelected: (selected) {
                  setState(() {
                    _isQuestionFilter = selected;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading && _filteredPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredPosts.isEmpty) {
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
              'No community posts found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Be the first to start a discussion'
                  : 'Try adjusting your search or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton(
                onPressed: _navigateToCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Post'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPosts.length + (_hasMorePosts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredPosts.length) {
          // Load more indicator
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Center(
              child: ElevatedButton(
                onPressed: () => _loadPosts(),
                child: const Text('Load More'),
              ),
            );
          }
        }

        final post = _filteredPosts[index];
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
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