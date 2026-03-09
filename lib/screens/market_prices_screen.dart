import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/market_price_service.dart';
import '../core/services/offline_service.dart';
import '../core/services/localization_service.dart';
import '../core/models/market_price_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marketPriceService = MarketPriceService();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  final _priceController = TextEditingController();

  List<MarketPriceModel> _marketPrices = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isOfflineMode = false;
  String _selectedCategory = 'GRAINS';
  String _unit = 'kg';
  String _currency = 'MWK';
  bool _isBuying = false;

  final List<String> _categories = [
    'GRAINS',
    'VEGETABLES',
    'FRUITS',
    'LIVESTOCK',
    'DAIRY',
    'OTHER',
  ];

  final List<String> _units = ['kg', 'pieces', 'bunches', 'liters', 'bags'];
  final List<String> _currencies = ['MWK', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _loadMarketPrices();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketPrices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only pass non-empty filter parameters
      final String? categoryFilter = _categoryController.text.trim().isNotEmpty 
          ? _categoryController.text.trim() 
          : null;
          
      final String? locationFilter = _locationController.text.trim().isNotEmpty 
          ? _locationController.text.trim() 
          : null;
          
      final String? searchFilter = _searchController.text.trim().isNotEmpty 
          ? _searchController.text.trim() 
          : null;

      final result = await _marketPriceService.getMarketPrices(
        category: categoryFilter,
        location: locationFilter,
        search: searchFilter,
      );

      if (result.isSuccess) {
        setState(() {
          _marketPrices = result.prices;
          _isOfflineMode = false;
        });
        
        // Save data for offline use
        final List<Map<String, dynamic>> offlineData = 
            result.prices.map((p) => p.toJson()).toList();
        await OfflineService.saveMarketPrices(offlineData);
      } else {
        // Try to load offline data if API fails
        await _loadOfflineData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.message}. Showing offline data.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      // Try to load offline data if API fails
      await _loadOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load market prices: ${e.toString()}. Showing offline data.'),
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

  Future<void> _loadOfflineData() async {
    try {
      final isRecent = await OfflineService.isDataRecent();
      if (isRecent) {
        final offlineData = await OfflineService.getMarketPrices();
        if (offlineData != null && offlineData.isNotEmpty) {
          final prices = offlineData.map((json) => MarketPriceModel.fromJson(json)).toList();
          if (mounted) {
            setState(() {
              _marketPrices = prices;
              _isOfflineMode = true;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail if offline data is not available
      debugPrint('Failed to load offline data: $e');
    }
  }

  Future<void> _createMarketPrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final request = MarketPriceCreateRequest(
        productCategory: _selectedCategory,
        marketName: 'Local Market',
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : 'Blantyre',
        pricePerUnit: double.parse(_priceController.text.trim()),
        unit: _unit,
        currency: _currency,
        isBuying: _isBuying,
        source: context.read<AuthProvider>().user?.username ?? 'Anonymous',
      );

      final result = await _marketPriceService.createMarketPrice(request);

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Market price created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _loadMarketPrices();
        _clearForm();
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
            content: Text('Failed to create market price: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _clearForm() {
    _categoryController.clear();
    _locationController.clear();
    _searchController.clear();
    _priceController.clear();
    setState(() {
      _selectedCategory = 'GRAINS';
      _unit = 'kg';
      _currency = 'MWK';
      _isBuying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().getString('marketPrices')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isOfflineMode)
            IconButton(
              icon: const Icon(Icons.offline_pin, color: AppColors.warning),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing offline data. Connect to the internet for latest updates.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarketPrices,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMarketPrices,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Stats
              _buildHeaderStats(),
              const SizedBox(height: 24),

              // Search Section
              _buildSearchSection(),
              const SizedBox(height: 24),

              // Create Price Section
              _buildCreatePriceSection(),
              const SizedBox(height: 24),

              // Market Prices List
              _buildMarketPricesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService().getString('marketPrices'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            LocalizationService().getString('priceHistory'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          // Fix RenderFlex overflow by using ConstrainedBox
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  _marketPrices.length.toString(),
                  LocalizationService().getString('myProducts'),
                  Icons.inventory_2_outlined,
                ),
                _buildStatItem(
                  _getUniqueCategories().toString(),
                  'Categories',
                  Icons.category_outlined,
                ),
                _buildStatItem(
                  _getUniqueLocations().toString(),
                  'Locations',
                  Icons.location_on_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getUniqueCategories() {
    final categories = <String>{};
    for (final price in _marketPrices) {
      categories.add(price.productCategory);
    }
    return categories.length;
  }

  int _getUniqueLocations() {
    final locations = <String>{};
    for (final price in _marketPrices) {
      locations.add(price.location);
    }
    return locations.length;
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${LocalizationService().getString('search')} ${LocalizationService().getString('marketPrices')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _searchController,
            hint: '${LocalizationService().getString('search')} ${LocalizationService().getString('products').toLowerCase()}, ${LocalizationService().getString('marketName').toLowerCase()}, ${LocalizationService().getString('location').toLowerCase()}',
            prefixIcon: Icons.search,
          ),

          const SizedBox(height: 16),

          // Fix RenderFlex overflow by using ConstrainedBox
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _categoryController,
                    label: 'Category',
                    hint: '${LocalizationService().getString('filter')} ${LocalizationService().getString('products').toLowerCase()}',
                    prefixIcon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: '${LocalizationService().getString('filter')} ${LocalizationService().getString('location').toLowerCase()}',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          CustomButton(
            text: LocalizationService().getString('search'),
            onPressed: _loadMarketPrices,
            isLoading: _isLoading,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${LocalizationService().getString('addProduct')} ${LocalizationService().getString('marketPrices')}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            _buildDropdown(
              label: LocalizationService().getString('productCategory'),
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Price Input
            CustomTextField(
              controller: _priceController,
              label: LocalizationService().getString('pricePerUnit'),
              hint: LocalizationService().getString('pricePerUnit'),
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return LocalizationService().getString('fieldRequired');
                }
                if (double.tryParse(value) == null) {
                  return LocalizationService().getString('invalidEmail');
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Unit and Currency Row
            // Fix RenderFlex overflow by using ConstrainedBox
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: LocalizationService().getString('unit'),
                      value: _unit,
                      items: _units,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _unit = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: LocalizationService().getString('currency'),
                      value: _currency,
                      items: _currencies,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currency = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location Input
            CustomTextField(
              controller: _locationController,
              label: LocalizationService().getString('location'),
              hint: LocalizationService().getString('location'),
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),

            // Buying/Selling Toggle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${LocalizationService().getString('pricePerUnit')}:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                // Wrap the ChoiceChips in a Wrap widget for better responsiveness
                Wrap(
                  spacing: 8.0, // gap between chips
                  children: [
                    ChoiceChip(
                      label: Text(LocalizationService().getString('selling')),
                      selected: !_isBuying,
                      selectedColor: AppColors.primary,
                      onSelected: (selected) {
                        setState(() {
                          _isBuying = !selected;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(LocalizationService().getString('buying')),
                      selected: _isBuying,
                      selectedColor: AppColors.primary,
                      onSelected: (selected) {
                        setState(() {
                          _isBuying = selected;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: '${LocalizationService().getString('addProduct')} ${LocalizationService().getString('marketPrices')}',
              onPressed: _createMarketPrice,
              isLoading: _isCreating,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketPricesList() {
    if (_isLoading && _marketPrices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_marketPrices.isEmpty) {
      return Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.price_change_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationService().getString('noDataFound'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${LocalizationService().getString('listProduce')} ${LocalizationService().getString('marketPrices').toLowerCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '${LocalizationService().getString('addProduct')} ${LocalizationService().getString('marketPrices')}',
              onPressed: () {
                // We can't easily scroll to the create section without a ScrollController
                // Instead, we'll show a snackbar directing the user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${LocalizationService().getString('listProduce')} ${LocalizationService().getString('marketPrices').toLowerCase()}'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocalizationService().getString('marketPrices'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              '${_marketPrices.length} records',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _marketPrices.length,
          itemBuilder: (context, index) {
            final price = _marketPrices[index];
            return _buildMarketPriceCard(price);
          },
        ),
      ],
    );
  }

  Widget _buildMarketPriceCard(MarketPriceModel price) {
    final categoryColor = AppColors.categoryColors[price.productCategory] ??
        AppColors.categoryColors['OTHER']!;
        
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          // Header with category indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(price.productCategory),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.categoryDisplayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        price.marketName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: price.isBuying ? AppColors.info : AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    price.priceTypeDisplay,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      price.formattedPrice,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    // Fix text overflow
                    Expanded(
                      child: Text(
                        price.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      price.timeAgo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                if (price.isRecent)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_new,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price.freshnessIndicator,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'GRAINS':
        return Icons.grain_outlined;
      case 'VEGETABLES':
        return Icons.eco_outlined;
      case 'FRUITS':
        return Icons.apple_outlined;
      case 'LIVESTOCK':
        return Icons.pets_outlined;
      case 'DAIRY':
        return Icons.local_drink_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}