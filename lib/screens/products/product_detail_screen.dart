import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/auth_provider.dart';


class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final isOwnProduct = currentUser?.id == widget.product.seller.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isOwnProduct)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implement edit product functionality
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Carousel
            if (widget.product.hasImages)
              Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.product.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.product.images[index].imageUrl,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.product.images.asMap().entries.map((
                      entry,
                    ) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == entry.key
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                color: AppColors.inputBackground,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No images available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.product.isActive
                              ? AppColors.success
                              : AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.product.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product.categoryDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seller Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            widget.product.seller.initials,
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
                                widget.product.seller.displayName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              Text(
                                widget.product.seller.roleDisplayName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Details
                  Text(
                    'Product Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    Icons.description,
                    'Description',
                    widget.product.description,
                  ),
                  _buildDetailRow(
                    Icons.scale,
                    'Quantity',
                    '${widget.product.quantity} ${widget.product.unit}',
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Harvest Date',
                    '${widget.product.harvestDate.day}/${widget.product.harvestDate.month}/${widget.product.harvestDate.year}',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    widget.product.location,
                  ),
                  _buildDetailRow(
                    Icons.phone,
                    'Contact',
                    widget.product.contactPhone,
                  ),
                  const SizedBox(height: 16),

                  // Price Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pricing Information',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          'Price per ${widget.product.unit}',
                          widget.product.formattedPrice,
                        ),
                        _buildPriceRow(
                          'Total Value',
                          widget.product.formattedTotalValue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Seller Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Implement contact seller functionality
                        _contactSeller();
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'GRAINS':
        return Colors.orange;
      case 'VEGETABLES':
        return Colors.green;
      case 'FRUITS':
        return Colors.red;
      case 'LIVESTOCK':
        return Colors.brown;
      case 'DAIRY':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  void _contactSeller() {
    // Get the seller's phone number
    final phoneNumber = widget.product.contactPhone;

    if (phoneNumber.isNotEmpty) {
      // Show a dialog with contact options
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Contact Seller'),
            content: Text(
              'How would you like to contact ${widget.product.seller.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
                  if (await canLaunchUrl(callUri)) {
                    await launchUrl(callUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not launch phone call to $phoneNumber',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Call'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not launch SMS to $phoneNumber',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Send SMS'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller contact information not available'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
