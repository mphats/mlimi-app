import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/product_service.dart';
import '../../core/models/product_model.dart';
import '../../core/services/localization_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _unitController = TextEditingController(); // Changed to text controller

  bool _isLoading = false;
  String _selectedCategory = 'GRAINS';
  DateTime _selectedDate = DateTime.now();
  List<File> _selectedImages = []; // Added for image selection

  final List<Map<String, String>> _categories = [
    {'value': 'GRAINS', 'label': LocalizationService().getString('grains')},
    {'value': 'VEGETABLES', 'label': LocalizationService().getString('vegetables')},
    {'value': 'FRUITS', 'label': LocalizationService().getString('fruits')},
    {'value': 'LIVESTOCK', 'label': LocalizationService().getString('livestock')},
    {'value': 'DAIRY', 'label': LocalizationService().getString('dairy')},
    {'value': 'OTHER', 'label': LocalizationService().getString('otherCategory')},
  ];

  // Removed units list since we're using text input now

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _unitController.dispose(); // Dispose the unit controller
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Added image selection method
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        // Validate files before adding them
        final List<File> validImages = [];
        for (final image in images) {
          final file = File(image.path);
          // Check if file exists and is readable
          if (await file.exists()) {
            validImages.add(file);
          }
        }
        
        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages = validImages;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected ${validImages.length} images'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to access selected images'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Added method to remove an image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = ProductCreateRequest(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(), // Changed to use text input
        pricePerUnit: double.parse(_priceController.text.trim()),
        harvestDate: _selectedDate,
        location: _locationController.text.trim(),
        contactPhone: _phoneController.text.trim(),
      );

      final result = await _productService.createProduct(request);

      if (result.isSuccess) {
        // Upload images if any were selected
        if (_selectedImages.isNotEmpty && result.firstProduct != null) {
          // Show uploading images message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Product created successfully. Uploading ${_selectedImages.length} images...'),
                backgroundColor: AppColors.info,
              ),
            );
          }
          
          final imageResult = await _productService.uploadProductImages(
            result.firstProduct!.id,
            _selectedImages,
          );
          
          if (imageResult.isFailure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${LocalizationService().getString('productListedSuccessfully')} but ${LocalizationService().getString('failedToUploadImages')}: ${imageResult.message}'),
                  backgroundColor: AppColors.warning,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${LocalizationService().getString('productListedSuccessfully')} All images uploaded successfully.'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(LocalizationService().getString('productListedSuccessfully')),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
        if (!mounted) return;
        Navigator.of(context).pop(true); // Return true to indicate success
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
            content: Text('${LocalizationService().getString('failedToListProduct')} ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Check if the widget is still mounted before updating state
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
        title: Text(LocalizationService().getString('addProductTitle')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Add back arrow button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                LocalizationService().getString('listYourAgriculturalProduct'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              CustomTextField(
                controller: _nameController,
                label: AppStrings.productName,
                hint: LocalizationService().getString('enterProductName'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LocalizationService().getString('pleaseEnterProductName');
                  }
                  if (value.trim().length < 3) {
                    return LocalizationService().getString('productNameMustBeAtLeast');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: AppStrings.productDescription,
                hint: LocalizationService().getString('enterProductDescription'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LocalizationService().getString('fieldRequired');
                  }
                  if (value.trim().length < 10) {
                    return '${LocalizationService().getString('productNameMustBeAtLeast')} 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and Unit Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: AppStrings.quantity,
                      hint: LocalizationService().getString('enterQuantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocalizationService().getString('pleaseEnterQuantity');
                        }
                        if (double.tryParse(value) == null) {
                          return LocalizationService().getString('pleaseEnterValidNumber');
                        }
                        if (double.parse(value) <= 0) {
                          return LocalizationService().getString('quantityMustBeGreaterThan');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Changed unit to text field to match web
                  Expanded(
                    child: CustomTextField(
                      controller: _unitController,
                      label: AppStrings.unit,
                      hint: LocalizationService().getString('enterUnit'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return LocalizationService().getString('pleaseEnterUnit');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price
              CustomTextField(
                controller: _priceController,
                label: '${AppStrings.pricePerUnit} (MWK)',
                hint: LocalizationService().getString('enterPrice'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LocalizationService().getString('pleaseEnterPrice');
                  }
                  if (double.tryParse(value) == null) {
                    return LocalizationService().getString('pleaseEnterValidNumber');
                  }
                  if (double.parse(value) <= 0) {
                    return LocalizationService().getString('priceMustBeGreaterThan');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Harvest Date
              _buildHarvestDateField(),
              const SizedBox(height: 16),

              // Location
              CustomTextField(
                controller: _locationController,
                label: AppStrings.location,
                hint: LocalizationService().getString('enterLocation'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LocalizationService().getString('pleaseEnterLocation');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Phone
              CustomTextField(
                controller: _phoneController,
                label: AppStrings.contactPhone,
                hint: LocalizationService().getString('enterPhoneNumber'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return LocalizationService().getString('pleaseEnterPhoneNumber');
                  }
                  // Simple phone validation
                  if (value.trim().length < 10) {
                    return LocalizationService().getString('pleaseEnterValidPhoneNumber');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: AppStrings.addProduct,
                onPressed: _submitProduct,
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
          AppStrings.productCategory,
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

  // Removed _buildUnitDropdown since we're using text input now

  Widget _buildHarvestDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.harvestDate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Added image upload section
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService().getString('productImages'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.inputBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService().getString('addProductImages'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_selectedImages.length} ${LocalizationService().getString('imagesSelected')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}