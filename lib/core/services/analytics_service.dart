import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // MARKET ANALYTICS

  // Add market price data point
  Future<void> addMarketPriceData(
    String cropType,
    String market,
    double price,
    DateTime timestamp,
  ) async {
    // Ensure price is finite
    if (!price.isFinite) {
      // Use a default value if price is not finite
      price = 0.0;
    }
    
    final key = 'market_data_${cropType}_$market';
    final data = await _getMarketData(key);
    data.add(MarketDataPoint(
      price: price,
      timestamp: timestamp,
    ));
    
    // Keep only the last 30 data points
    if (data.length > 30) {
      data.removeRange(0, data.length - 30);
    }
    
    await _saveMarketData(key, data);
  }

  // Get market price trend
  Future<List<MarketDataPoint>> getMarketPriceTrend(
    String cropType,
    String market,
  ) async {
    final key = 'market_data_${cropType}_$market';
    return await _getMarketData(key);
  }

  // Get market price statistics
  Future<MarketStatistics> getMarketStatistics(
    String cropType,
    String market,
  ) async {
    final data = await getMarketPriceTrend(cropType, market);
    
    if (data.isEmpty) {
      return MarketStatistics(
        averagePrice: 0,
        highestPrice: 0,
        lowestPrice: 0,
        priceChange: 0,
        trend: PriceTrend.stable,
      );
    }
    
    double sum = 0;
    double max = data.first.price.isFinite ? data.first.price : 0;
    double min = data.first.price.isFinite ? data.first.price : 0;
    
    // Filter out non-finite values
    final finiteData = data.where((point) => point.price.isFinite).toList();
    if (finiteData.isEmpty) {
      return MarketStatistics(
        averagePrice: 0,
        highestPrice: 0,
        lowestPrice: 0,
        priceChange: 0,
        trend: PriceTrend.stable,
      );
    }
    
    for (final point in finiteData) {
      sum += point.price;
      if (point.price > max) max = point.price;
      if (point.price < min) min = point.price;
    }
    
    final average = (sum / finiteData.length).toDouble();
    final priceChange = finiteData.length > 1 
        ? (((finiteData.last.price - finiteData.first.price) / finiteData.first.price) * 100).toDouble()
        : 0.0;
    
    // Ensure priceChange is finite
    final finitePriceChange = priceChange.isFinite ? priceChange : 0.0;
    
    PriceTrend trend;
    if (finitePriceChange > 5) {
      trend = PriceTrend.increasing;
    } else if (finitePriceChange < -5) {
      trend = PriceTrend.decreasing;
    } else {
      trend = PriceTrend.stable;
    }
    
    return MarketStatistics(
      averagePrice: average.isFinite ? average : 0,
      highestPrice: max.isFinite ? max : 0,
      lowestPrice: min.isFinite ? min : 0,
      priceChange: finitePriceChange,
      trend: trend,
    );
  }

  // FARMING ANALYTICS

  // Track pest diagnosis
  Future<void> trackPestDiagnosis(
    String cropType,
    String diagnosis,
    double confidence,
    DateTime timestamp,
  ) async {
    // Ensure confidence is finite
    if (!confidence.isFinite) {
      confidence = 0.0;
    }
    
  // ...existing code...
    final diagnoses = await _getPestDiagnoses();
    diagnoses.add(PestDiagnosisRecord(
      cropType: cropType,
      diagnosis: diagnosis,
      confidence: confidence,
      timestamp: timestamp,
    ));
    
    // Keep only the last 50 diagnoses
    if (diagnoses.length > 50) {
      diagnoses.removeRange(0, diagnoses.length - 50);
    }
    
    await _savePestDiagnoses(diagnoses);
  }

  // Get common pest diagnoses
  Future<List<PestDiagnosisRecord>> getCommonPestDiagnoses(
    String cropType,
  ) async {
    final diagnoses = await _getPestDiagnoses();
    // Filter out records with non-finite confidence values
    final finiteDiagnoses = diagnoses.where((d) => d.confidence.isFinite).toList();
    final cropDiagnoses = finiteDiagnoses
        .where((d) => d.cropType == cropType)
        .toList();
    
    // Sort by frequency
    final diagnosisCount = <String, int>{};
    for (final diagnosis in cropDiagnoses) {
      diagnosisCount[diagnosis.diagnosis] = 
          (diagnosisCount[diagnosis.diagnosis] ?? 0) + 1;
    }
    
    cropDiagnoses.sort((a, b) {
      final countA = diagnosisCount[a.diagnosis] ?? 0;
      final countB = diagnosisCount[b.diagnosis] ?? 0;
      return countB.compareTo(countA);
    });
    
    // Return unique diagnoses sorted by frequency
    final uniqueDiagnoses = <PestDiagnosisRecord>[];
    final seen = <String>{};
    
    for (final diagnosis in cropDiagnoses) {
      if (!seen.contains(diagnosis.diagnosis)) {
        uniqueDiagnoses.add(diagnosis);
        seen.add(diagnosis.diagnosis);
      }
    }
    
    return uniqueDiagnoses.take(5).toList();
  }

  // Track crop performance
  Future<void> trackCropPerformance(
    String cropType,
    double cropYield,
    DateTime timestamp,
  ) async {
    // Ensure cropYield is finite
    if (!cropYield.isFinite) {
      cropYield = 0.0;
    }
    
    final key = 'crop_performance_$cropType';
    final data = await _getCropPerformanceData(key);
    data.add(CropPerformanceRecord(
      cropYield: cropYield.toDouble(),
      timestamp: timestamp,
    ));
    
    // Keep only the last 20 data points
    if (data.length > 20) {
      data.removeRange(0, data.length - 20);
    }
    
    await _saveCropPerformanceData(key, data);
  }

  // Get crop performance data
  Future<List<CropPerformanceRecord>> getCropPerformance(
    String cropType,
  ) async {
    final key = 'crop_performance_$cropType';
    return await _getCropPerformanceData(key);
  }

  // USER ACTIVITY ANALYTICS

  // Track user activity
  Future<void> trackUserActivity(
    String activityType,
    DateTime timestamp,
  ) async {
  // ...existing code...
    final activities = await _getUserActivities();
    activities.add(UserActivity(
      type: activityType,
      timestamp: timestamp,
    ));
    
    // Keep only the last 100 activities
    if (activities.length > 100) {
      activities.removeRange(0, activities.length - 100);
    }
    
    await _saveUserActivities(activities);
  }

  // Get user activity statistics
  Future<UserActivityStats> getUserActivityStats() async {
    final activities = await _getUserActivities();
    
    if (activities.isEmpty) {
      return UserActivityStats(
        totalActivities: 0,
        dailyAverage: 0,
        mostActiveDay: '',
        activityBreakdown: {},
      );
    }
    
    // Group by date
    final activityByDate = <String, int>{};
    for (final activity in activities) {
      final date = '${activity.timestamp.year}-${activity.timestamp.month}-${activity.timestamp.day}';
      activityByDate[date] = (activityByDate[date] ?? 0) + 1;
    }
    
    // Calculate statistics
    final totalActivities = activities.length;
    final dailyAverage = activityByDate.isNotEmpty 
        ? (activityByDate.values.reduce((a, b) => a + b) / activityByDate.length).toDouble()
        : 0.0;
    
    // Find most active day
    String mostActiveDay = '';
    int maxActivities = 0;
    activityByDate.forEach((date, count) {
      if (count > maxActivities) {
        maxActivities = count;
        mostActiveDay = date;
      }
    });
    
    // Activity breakdown
    final activityBreakdown = <String, int>{};
    for (final activity in activities) {
      activityBreakdown[activity.type] = (activityBreakdown[activity.type] ?? 0) + 1;
    }
    
    return UserActivityStats(
      totalActivities: totalActivities,
      dailyAverage: dailyAverage.isFinite ? dailyAverage : 0,
      mostActiveDay: mostActiveDay,
      activityBreakdown: activityBreakdown,
    );
  }

  // FINANCIAL ANALYTICS

  // Track financial transaction
  Future<void> trackFinancialTransaction(
    String type, // 'revenue' or 'expense'
    String category,
    double amount,
    DateTime timestamp,
  ) async {
    // Ensure amount is finite
    if (!amount.isFinite) {
      amount = 0.0;
    }
    
  // ...existing code...
    final transactions = await _getFinancialTransactions();
    transactions.add(FinancialTransaction(
      type: type,
      category: category,
      amount: amount,
      timestamp: timestamp,
    ));
    
    // Keep only the last 100 transactions
    if (transactions.length > 100) {
      transactions.removeRange(0, transactions.length - 100);
    }
    
    await _saveFinancialTransactions(transactions);
  }

  // Get financial summary
  Future<FinancialSummary> getFinancialSummary() async {
    final transactions = await _getFinancialTransactions();
    
    double totalRevenue = 0;
    double totalExpenses = 0;
    final expenseBreakdown = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.amount.isFinite) {
        if (transaction.type == 'revenue') {
          totalRevenue += transaction.amount;
        } else if (transaction.type == 'expense') {
          totalExpenses += transaction.amount;
          expenseBreakdown[transaction.category] = 
              (expenseBreakdown[transaction.category] ?? 0) + transaction.amount;
        }
      }
    }
    
    final profit = totalRevenue - totalExpenses;
    final roi = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;
    
    return FinancialSummary(
      totalRevenue: totalRevenue.isFinite ? totalRevenue : 0,
      totalExpenses: totalExpenses.isFinite ? totalExpenses : 0,
      profit: profit.isFinite ? profit : 0,
      roi: roi.isFinite ? roi.toDouble() : 0,
      expenseBreakdown: expenseBreakdown,
    );
  }

  // PRIVATE METHODS

  // Market data storage
  Future<List<MarketDataPoint>> _getMarketData(String key) async {
    final serialized = _prefs.getStringList(key);
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => MarketDataPoint.fromJson(json))
        // Filter out points with non-finite prices
        .where((point) => point.price.isFinite)
        .toList();
  }

  Future<void> _saveMarketData(
    String key,
    List<MarketDataPoint> data,
  ) async {
    // Filter out points with non-finite prices before saving
    final finiteData = data.where((point) => point.price.isFinite).toList();
    final serialized = finiteData.map((point) => point.toJson()).toList();
    await _prefs.setStringList(key, serialized);
  }

  // Pest diagnosis storage
  Future<List<PestDiagnosisRecord>> _getPestDiagnoses() async {
    final serialized = _prefs.getStringList('pest_diagnoses');
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => PestDiagnosisRecord.fromJson(json))
        // Filter out records with non-finite confidence values
        .where((record) => record.confidence.isFinite)
        .toList();
  }

  Future<void> _savePestDiagnoses(
    List<PestDiagnosisRecord> diagnoses,
  ) async {
    // Filter out records with non-finite confidence values before saving
    final finiteDiagnoses = diagnoses.where((d) => d.confidence.isFinite).toList();
    final serialized = finiteDiagnoses.map((d) => d.toJson()).toList();
    await _prefs.setStringList('pest_diagnoses', serialized);
  }

  // Crop performance storage
  Future<List<CropPerformanceRecord>> _getCropPerformanceData(String key) async {
    final serialized = _prefs.getStringList(key);
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => CropPerformanceRecord.fromJson(json))
        // Filter out records with non-finite yield values
        .where((record) => record.cropYield.isFinite)
        .toList();
  }

  Future<void> _saveCropPerformanceData(
    String key,
    List<CropPerformanceRecord> data,
  ) async {
    // Filter out records with non-finite yield values before saving
    final finiteData = data.where((d) => d.cropYield.isFinite).toList();
    final serialized = finiteData.map((d) => d.toJson()).toList();
    await _prefs.setStringList(key, serialized);
  }

  // User activity storage
  Future<List<UserActivity>> _getUserActivities() async {
    final serialized = _prefs.getStringList('user_activities');
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => UserActivity.fromJson(json))
        .toList();
  }

  Future<void> _saveUserActivities(
    List<UserActivity> activities,
  ) async {
    final serialized = activities.map((a) => a.toJson()).toList();
    await _prefs.setStringList('user_activities', serialized);
  }

  // Financial transaction storage
  Future<List<FinancialTransaction>> _getFinancialTransactions() async {
    final serialized = _prefs.getStringList('financial_transactions');
    if (serialized == null || serialized.isEmpty) {
      return [];
    }
    
    return serialized
        .map((json) => FinancialTransaction.fromJson(json))
        // Filter out transactions with non-finite amounts
        .where((transaction) => transaction.amount.isFinite)
        .toList();
  }

  Future<void> _saveFinancialTransactions(
    List<FinancialTransaction> transactions,
  ) async {
    // Filter out transactions with non-finite amounts before saving
    final finiteTransactions = transactions.where((t) => t.amount.isFinite).toList();
    final serialized = finiteTransactions.map((t) => t.toJson()).toList();
    await _prefs.setStringList('financial_transactions', serialized);
  }

  // Clear all analytics data
  Future<void> clearAnalyticsData() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('market_data_') || 
          key == 'pest_diagnoses' || 
          key == 'user_activities' ||
          key.startsWith('crop_performance_') ||
          key == 'financial_transactions') {
        await _prefs.remove(key);
      }
    }
  }
}

// Data models
class MarketDataPoint {
  final double price;
  final DateTime timestamp;

  MarketDataPoint({
    required this.price,
    required this.timestamp,
  });

  String toJson() {
    // Ensure price is finite before serializing
    final finitePrice = price.isFinite ? price : 0.0;
    return '$finitePrice|${timestamp.millisecondsSinceEpoch}';
  }

  factory MarketDataPoint.fromJson(String json) {
    final parts = json.split('|');
    return MarketDataPoint(
      price: double.parse(parts[0]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
    );
  }
}

class MarketStatistics {
  final double averagePrice;
  final double highestPrice;
  final double lowestPrice;
  final double priceChange;
  final PriceTrend trend;

  MarketStatistics({
    required this.averagePrice,
    required this.highestPrice,
    required this.lowestPrice,
    required this.priceChange,
    required this.trend,
  });
}

enum PriceTrend { increasing, decreasing, stable }

class PestDiagnosisRecord {
  final String cropType;
  final String diagnosis;
  final double confidence;
  final DateTime timestamp;

  PestDiagnosisRecord({
    required this.cropType,
    required this.diagnosis,
    required this.confidence,
    required this.timestamp,
  });

  String toJson() {
    // Ensure confidence is finite before serializing
    final finiteConfidence = confidence.isFinite ? confidence : 0.0;
    return '$cropType|$diagnosis|$finiteConfidence|${timestamp.millisecondsSinceEpoch}';
  }

  factory PestDiagnosisRecord.fromJson(String json) {
    final parts = json.split('|');
    return PestDiagnosisRecord(
      cropType: parts[0],
      diagnosis: parts[1],
      confidence: double.parse(parts[2]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3])),
    );
  }
}

class CropPerformanceRecord {
  final double cropYield;
  final DateTime timestamp;

  CropPerformanceRecord({
    required this.cropYield,
    required this.timestamp,
  });

  String toJson() {
    // Ensure cropYield is finite before serializing
    final finiteYield = cropYield.isFinite ? cropYield : 0.0;
    return '$finiteYield|${timestamp.millisecondsSinceEpoch}';
  }

  factory CropPerformanceRecord.fromJson(String json) {
    final parts = json.split('|');
    return CropPerformanceRecord(
      cropYield: double.parse(parts[0]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
    );
  }
}

class UserActivity {
  final String type;
  final DateTime timestamp;

  UserActivity({
    required this.type,
    required this.timestamp,
  });

  String toJson() {
    return '$type|${timestamp.millisecondsSinceEpoch}';
  }

  factory UserActivity.fromJson(String json) {
    final parts = json.split('|');
    return UserActivity(
      type: parts[0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
    );
  }
}

class UserActivityStats {
  final int totalActivities;
  final double dailyAverage;
  final String mostActiveDay;
  final Map<String, int> activityBreakdown;

  UserActivityStats({
    required this.totalActivities,
    required this.dailyAverage,
    required this.mostActiveDay,
    required this.activityBreakdown,
  });
}

class FinancialTransaction {
  final String type; // 'revenue' or 'expense'
  final String category;
  final double amount;
  final DateTime timestamp;

  FinancialTransaction({
    required this.type,
    required this.category,
    required this.amount,
    required this.timestamp,
  });

  String toJson() {
    // Ensure amount is finite before serializing
    final finiteAmount = amount.isFinite ? amount : 0.0;
    return '$type|$category|$finiteAmount|${timestamp.millisecondsSinceEpoch}';
  }

  factory FinancialTransaction.fromJson(String json) {
    final parts = json.split('|');
    return FinancialTransaction(
      type: parts[0],
      category: parts[1],
      amount: double.parse(parts[2]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3])),
    );
  }
}

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double profit;
  final double roi;
  final Map<String, double> expenseBreakdown;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profit,
    required this.roi,
    required this.expenseBreakdown,
  });
}