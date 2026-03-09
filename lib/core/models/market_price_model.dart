class MarketPriceModel {
  final int id;
  final String productCategory;
  final String marketName;
  final String location;
  final double pricePerUnit;
  final String unit;
  final String currency;
  final bool isBuying;
  final String source;
  final DateTime recordedAt;
  final bool isActive;

  MarketPriceModel({
    required this.id,
    required this.productCategory,
    required this.marketName,
    required this.location,
    required this.pricePerUnit,
    required this.unit,
    this.currency = 'MWK',
    this.isBuying = false,
    required this.source,
    required this.recordedAt,
    this.isActive = true,
  });

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse all numeric values
      final idValue = json['id'];
      final id = idValue is int ? idValue : (idValue is String ? int.parse(idValue) : 0);
      
      final priceValue = json['price_per_unit'];
      final pricePerUnit = priceValue is double 
          ? priceValue 
          : (priceValue is int 
              ? priceValue.toDouble() 
              : (priceValue is String 
                  ? double.tryParse(priceValue) ?? 0.0 
                  : 0.0));

      return MarketPriceModel(
        id: id,
        productCategory: json['product_category'] is String ? json['product_category'] : 'Unknown',
        marketName: json['market_name'] is String ? json['market_name'] : 'Unknown Market',
        location: json['location'] is String ? json['location'] : 'Unknown Location',
        pricePerUnit: pricePerUnit,
        unit: json['unit'] is String ? json['unit'] : 'kg',
        currency: json['currency'] is String ? json['currency'] : 'MWK',
        isBuying: json['is_buying'] is bool ? json['is_buying'] : false,
        source: json['source'] is String ? json['source'] : 'Unknown Source',
        recordedAt: json['recorded_at'] is String
            ? DateTime.parse(json['recorded_at'])
            : DateTime.now(),
        isActive: json['is_active'] is bool ? json['is_active'] : true,
      );
    } catch (e) {
      // Return a default MarketPriceModel if parsing fails
      return MarketPriceModel(
        id: 0,
        productCategory: 'Unknown',
        marketName: 'Failed to Load',
        location: 'Unknown',
        pricePerUnit: 0.0,
        unit: 'kg',
        currency: 'MWK',
        isBuying: false,
        source: 'Unknown',
        recordedAt: DateTime.now(),
        isActive: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_category': productCategory,
      'market_name': marketName,
      'location': location,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'currency': currency,
      'is_buying': isBuying,
      'source': source,
      'recorded_at': recordedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  String get categoryDisplayName {
    switch (productCategory.toUpperCase()) {
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
      default:
        return productCategory;
    }
  }

  String get formattedPrice {
    return '$currency ${pricePerUnit.toStringAsFixed(2)}/$unit';
  }

  String get priceTypeDisplay {
    return isBuying ? 'Buying Price' : 'Selling Price';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(recordedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(recordedAt);
    return difference.inHours < 24;
  }

  bool get isVeryRecent {
    final now = DateTime.now();
    final difference = now.difference(recordedAt);
    return difference.inHours < 6;
  }

  String get freshnessIndicator {
    if (isVeryRecent) {
      return 'Fresh';
    } else if (isRecent) {
      return 'Recent';
    } else {
      return 'Older';
    }
  }

  MarketPriceModel copyWith({
    int? id,
    String? productCategory,
    String? marketName,
    String? location,
    double? pricePerUnit,
    String? unit,
    String? currency,
    bool? isBuying,
    String? source,
    DateTime? recordedAt,
    bool? isActive,
  }) {
    return MarketPriceModel(
      id: id ?? this.id,
      productCategory: productCategory ?? this.productCategory,
      marketName: marketName ?? this.marketName,
      location: location ?? this.location,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      currency: currency ?? this.currency,
      isBuying: isBuying ?? this.isBuying,
      source: source ?? this.source,
      recordedAt: recordedAt ?? this.recordedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketPriceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MarketPriceModel(id: $id, productCategory: $productCategory, marketName: $marketName, price: $formattedPrice)';
  }
}

// Market price creation request model
class MarketPriceCreateRequest {
  final String productCategory;
  final String marketName;
  final String location;
  final double pricePerUnit;
  final String unit;
  final String currency;
  final bool isBuying;
  final String source;

  MarketPriceCreateRequest({
    required this.productCategory,
    required this.marketName,
    required this.location,
    required this.pricePerUnit,
    required this.unit,
    this.currency = 'MWK',
    this.isBuying = false,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_category': productCategory,
      'market_name': marketName,
      'location': location,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'currency': currency,
      'is_buying': isBuying,
      'source': source,
    };
  }
}

// Market price trend data
class MarketPriceTrend {
  final String productCategory;
  final List<MarketPriceModel> prices;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final String trend; // 'rising', 'falling', 'stable'
  final double changePercentage;

  MarketPriceTrend({
    required this.productCategory,
    required this.prices,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.trend,
    required this.changePercentage,
  });

  factory MarketPriceTrend.fromPrices(
    String category,
    List<MarketPriceModel> priceList,
  ) {
    if (priceList.isEmpty) {
      return MarketPriceTrend(
        productCategory: category,
        prices: [],
        averagePrice: 0,
        minPrice: 0,
        maxPrice: 0,
        trend: 'stable',
        changePercentage: 0,
      );
    }

    final sortedPrices = List<MarketPriceModel>.from(priceList)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final prices = sortedPrices.map((p) => p.pricePerUnit).toList();
    final average = prices.reduce((a, b) => a + b) / prices.length;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);

    // Calculate trend
    String trendDirection = 'stable';
    double changePercent = 0;

    if (prices.length > 1) {
      final latest = prices.first;
      final previous = prices[1];
      changePercent = ((latest - previous) / previous) * 100;

      if (changePercent > 5) {
        trendDirection = 'rising';
      } else if (changePercent < -5) {
        trendDirection = 'falling';
      }
    }

    return MarketPriceTrend(
      productCategory: category,
      prices: sortedPrices,
      averagePrice: average,
      minPrice: min,
      maxPrice: max,
      trend: trendDirection,
      changePercentage: changePercent,
    );
  }

  String get trendIcon {
    switch (trend) {
      case 'rising':
        return '📈';
      case 'falling':
        return '📉';
      default:
        return '➡️';
    }
  }

  String get trendDisplay {
    switch (trend) {
      case 'rising':
        return 'Rising';
      case 'falling':
        return 'Falling';
      default:
        return 'Stable';
    }
  }

  String get formattedChange {
    final sign = changePercentage >= 0 ? '+' : '';
    return '$sign${changePercentage.toStringAsFixed(1)}%';
  }
}
