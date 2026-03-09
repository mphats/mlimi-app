import 'user_model.dart';

class ProductModel {
  final int id;
  final UserModel seller;
  final String name;
  final String category;
  final String description;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final DateTime harvestDate;
  final String location;
  final String contactPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProductImage> images;
  final int viewCount; // Add this property

  ProductModel({
    required this.id,
    required this.seller,
    required this.name,
    required this.category,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.harvestDate,
    required this.location,
    required this.contactPhone,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.viewCount = 0, // Add this property
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      // Ensure all values are properly cast
      final idValue = json['id'];
      final id = idValue is int
          ? idValue
          : (idValue is String ? int.parse(idValue) : 0);

      final quantityValue = json['quantity'];
      final quantity = quantityValue is double
          ? quantityValue
          : (quantityValue is int
                ? quantityValue.toDouble()
                : (quantityValue is String
                      ? double.tryParse(quantityValue) ?? 0.0
                      : 0.0));

      final priceValue = json['price_per_unit'];
      final pricePerUnit = priceValue is double
          ? priceValue
          : (priceValue is int
                ? priceValue.toDouble()
                : (priceValue is String
                      ? double.tryParse(priceValue) ?? 0.0
                      : 0.0));

      // Handle viewCount
      final viewCountValue = json['view_count'];
      final viewCount = viewCountValue is int
          ? viewCountValue
          : (viewCountValue is String ? int.tryParse(viewCountValue) ?? 0 : 0);

      // Handle seller data with better fallback
      UserModel seller;
      if (json['seller'] is Map<String, dynamic>) {
        seller = UserModel.fromJson(json['seller'] as Map<String, dynamic>);
      } else {
        // Create a default user with meaningful values
        seller = UserModel(
          id: 0,
          username: 'unknown_seller',
          email: '',
          role: 'FARMER',
          isActive: true,
        );
      }

      return ProductModel(
        id: id,
        seller: seller,
        name: json['name'] is String ? json['name'] : 'Unnamed Product',
        category: json['category'] is String ? json['category'] : 'OTHER',
        description: json['description'] is String
            ? json['description']
            : 'No description available',
        quantity: quantity,
        unit: json['unit'] is String ? json['unit'] : 'kg',
        pricePerUnit: pricePerUnit,
        harvestDate: json['harvest_date'] is String
            ? DateTime.parse(json['harvest_date'])
            : DateTime.now(),
        location: json['location'] is String
            ? json['location']
            : 'Unknown Location',
        contactPhone: json['contact_phone'] is String
            ? json['contact_phone']
            : 'No contact',
        isActive: json['is_active'] is bool ? json['is_active'] : true,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
        images: json['images'] is List
            ? (json['images'] as List)
                  .map(
                    (img) => img is Map<String, dynamic>
                        ? ProductImage.fromJson(img)
                        : ProductImage.fromJson({}),
                  )
                  .toList()
            : [],
        viewCount: viewCount, // Add this line
      );
    } catch (e) {
      // Return a default ProductModel if parsing fails
      return ProductModel(
        id: 0,
        seller: UserModel(
          id: 0,
          username: 'unknown_seller',
          email: '',
          role: 'FARMER',
          isActive: false,
        ),
        name: 'Unknown Product',
        category: 'OTHER',
        description: 'Failed to load product details',
        quantity: 0.0,
        unit: 'kg',
        pricePerUnit: 0.0,
        harvestDate: DateTime.now(),
        location: 'Unknown',
        contactPhone: '',
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0, // Add this line
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller': seller.toJson(),
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'harvest_date': harvestDate.toIso8601String().split('T')[0],
      'location': location,
      'contact_phone': contactPhone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'images': images.map((img) => img.toJson()).toList(),
      'view_count': viewCount, // Add this line
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case 'GRAINS':
        return 'Grains';
      case 'VEGETABLES':
        return 'Vegetables';
      case 'FRUITS':
        return 'Fruits';
      case 'LIVESTOCK':
        return 'Livestock';
      case 'DAIRY':
        return 'Dairy';
      case 'OTHER':
        return 'Other';
      default:
        return category;
    }
  }

  String get statusText {
    return isActive ? 'Available' : 'Sold Out';
  }

  double get totalValue {
    return quantity * pricePerUnit;
  }

  String get formattedPrice {
    return 'MWK ${pricePerUnit.toStringAsFixed(2)}';
  }

  String get formattedTotalValue {
    return 'MWK ${totalValue.toStringAsFixed(2)}';
  }

  bool get hasImages {
    return images.isNotEmpty;
  }

  String? get primaryImageUrl {
    return hasImages ? images.first.imageUrl : null;
  }

  int get daysToHarvest {
    final now = DateTime.now();
    final difference = harvestDate.difference(now);
    return difference.inDays;
  }

  bool get isHarvested {
    return DateTime.now().isAfter(harvestDate);
  }

  ProductModel copyWith({
    int? id,
    UserModel? seller,
    String? name,
    String? category,
    String? description,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    DateTime? harvestDate,
    String? location,
    String? contactPhone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductImage>? images,
  }) {
    return ProductModel(
      id: id ?? this.id,
      seller: seller ?? this.seller,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      harvestDate: harvestDate ?? this.harvestDate,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, category: $category, seller: ${seller.username})';
  }
}

class ProductImage {
  final int id;
  final String image;
  final DateTime uploadedAt;

  ProductImage({
    required this.id,
    required this.image,
    required this.uploadedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse the id
      final idValue = json['id'];
      final id = idValue is int
          ? idValue
          : (idValue is String ? int.parse(idValue) : 0);

      return ProductImage(
        id: id,
        image: json['image'] is String ? json['image'] : '',
        uploadedAt: json['uploaded_at'] is String
            ? DateTime.parse(json['uploaded_at'])
            : DateTime.now(),
      );
    } catch (e) {
      // Return a default ProductImage if parsing fails
      return ProductImage(id: 0, image: '', uploadedAt: DateTime.now());
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  String get imageUrl {
    // If image is already a full URL, return as is
    if (image.startsWith('http')) {
      return image;
    }
    // Otherwise, construct full URL with base URL
    return 'http://10.0.2.2:8000$image';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProductImage(id: $id, image: $image)';
  }
}

// Product creation/update request model
class ProductCreateRequest {
  final String name;
  final String category;
  final String description;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final DateTime harvestDate;
  final String location;
  final String contactPhone;

  ProductCreateRequest({
    required this.name,
    required this.category,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.harvestDate,
    required this.location,
    required this.contactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'harvest_date': harvestDate.toIso8601String().split('T')[0],
      'location': location,
      'contact_phone': contactPhone,
    };
  }
}
