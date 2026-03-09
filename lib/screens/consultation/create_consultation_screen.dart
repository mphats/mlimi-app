import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../widgets/custom_button.dart';

class CreateConsultationScreen extends StatefulWidget {
  const CreateConsultationScreen({super.key});

  @override
  State<CreateConsultationScreen> createState() =>
      _CreateConsultationScreenState();
}

class _CreateConsultationScreenState extends State<CreateConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'PEST_CONTROL';
  int _priority = 3;
  bool _isPremium = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'PEST_CONTROL', 'label': 'Pest Control'},
    {'value': 'DISEASE_MANAGEMENT', 'label': 'Disease Management'},
    {'value': 'SOIL_HEALTH', 'label': 'Soil Health'},
    {'value': 'CROP_MANAGEMENT', 'label': 'Crop Management'},
    {'value': 'IRRIGATION', 'label': 'Irrigation'},
    {'value': 'FERTILIZATION', 'label': 'Fertilization'},
    {'value': 'HARVESTING', 'label': 'Harvesting'},
    {'value': 'STORAGE', 'label': 'Storage'},
    {'value': 'MARKETING', 'label': 'Marketing'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  Future<void> _submitConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService().createConsultation({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priority': _priority,
        'is_premium': _isPremium,
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation request submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Return true to indicate successful creation
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting consultation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Expert Consultation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Describe your agricultural challenge and get expert advice',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Our team of expert agronomists will review your request and provide personalized guidance to help solve your farming challenges.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title field
              _buildTitleField(),
              const SizedBox(height: 16),
              
              // Description field
              _buildDescriptionField(),
              const SizedBox(height: 16),
              
              // Category dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              
              // Priority slider
              _buildPrioritySlider(),
              const SizedBox(height: 16),
              
              // Premium toggle
              _buildPremiumToggle(),
              const SizedBox(height: 32),
              
              // Submit button
              CustomButton(
                text: _isSubmitting ? AppStrings.submitting : 'Submit Request',
                onPressed: _isSubmitting ? null : _submitConsultation,
                isLoading: _isSubmitting,
                icon: _isSubmitting ? null : Icons.send,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Consultation Title',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'e.g., Tomato blight issue in my field',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        if (value.trim().length < 5) {
          return 'Title must be at least 5 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Detailed Description',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Describe your agricultural challenge in detail...',
      ),
      maxLines: 6,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please provide a detailed description';
        }
        if (value.trim().length < 20) {
          return 'Description must be at least 20 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPrioritySlider() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.textSecondary.withValues(alpha: 0.2),
                thumbColor: AppColors.primary,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                tickMarkShape: const RoundSliderTickMarkShape(),
                activeTickMarkColor: AppColors.primary,
                inactiveTickMarkColor: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _priority.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _priority.toString(),
                onChanged: (value) {
                  setState(() {
                    _priority = value.toInt();
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Low',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Medium',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'High',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumToggle() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Premium Consultation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Get faster response and priority handling from our expert agronomists. Premium consultations are reviewed within 2 hours compared to 24 hours for standard requests.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Request Premium Service'),
              value: _isPremium,
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                });
              },
              secondary: const Icon(Icons.flash_on),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}