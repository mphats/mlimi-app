import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/community_service.dart';
import '../../core/models/community_model.dart';
import '../../core/utils/error_handler.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _communityService = CommunityService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isQuestion = false;
  String _selectedCategory = 'general';

  final List<Map<String, String>> _categories = [
    {'value': 'question', 'label': 'Question'},
    {'value': 'advice', 'label': 'Advice'},
    {'value': 'discussion', 'label': 'Discussion'},
    {'value': 'experience', 'label': 'Experience Sharing'},
    {'value': 'problem', 'label': 'Problem'},
    {'value': 'solution', 'label': 'Solution'},
    {'value': 'general', 'label': 'General'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CommunityPostCreateRequest(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        isQuestion: _isQuestion,
      );

      final result = await _communityService.createPost(request);

      if (result.isSuccess) {
        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, 'Post created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Share your thoughts with the community',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              CustomTextField(
                controller: _titleController,
                label: AppStrings.postTitle,
                hint: 'Enter a descriptive title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Question Toggle
              _buildQuestionToggle(),
              const SizedBox(height: 16),

              // Content Input
              CustomTextField(
                controller: _contentController,
                label: AppStrings.postContent,
                hint:
                    'Share your thoughts, ask questions, or provide advice...',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  if (value.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: 'Create Post',
                onPressed: _submitPost,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.postCategory,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Is this a question?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marking this as a question will help other users identify and respond to your query more easily.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isQuestion,
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _isQuestion = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
