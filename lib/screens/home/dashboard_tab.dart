import 'package:flutter/material.dart';
import 'package:mulimi/screens/market_prices_screen.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/websocket_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/market_price_service.dart';
import '../../core/models/market_price_model.dart';
import '../products/add_product_screen.dart';
import '../community/create_post_screen.dart';
import '../community/community_screen.dart';
import '../ai_diagnosis/pest_diagnosis_screen.dart';
import '../weather/weather_screen.dart';
import '../newsletter/newsletter_subscription_screen.dart';
import '../reports/reports_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
  final WebSocketService _webSocketService = WebSocketService();
  final MarketPriceService _marketPriceService = MarketPriceService();
  
  final List<dynamic> _recentActivities = [
    {
      'icon': Icons.add_circle,
      'title': 'Added new product: Maize',
      'time': '2 hours ago',
      'color': AppColors.success,
    },
    {
      'icon': Icons.forum,
      'title': 'Posted question about pest control',
      'time': '1 day ago',
      'color': AppColors.info,
    },
    {
      'icon': Icons.science,
      'title': 'Completed AI diagnosis',
      'time': '2 days ago',
      'color': AppColors.warning,
    },
  ];
  
  List<MarketPriceModel> _marketPrices = [];
  bool _isLoadingMarketPrices = false;
  String? _marketPricesError;
  bool _isOffline = false;
  bool _animationsInitialized = false; // Add initialization tracking flag
  
  // Animation controllers for visual feedback
  late AnimationController _activityAnimationController;
  late Animation<double> _activityAnimation;
  
  // Track recently updated items for animation
  final Set<int> _updatedPriceIds = <int>{};
  final Map<int, AnimationController> _priceAnimationControllers = {};
  final Map<int, Animation<double>> _priceAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _initializeWebSocketConnections();
    _loadMarketPrices();
    _checkConnectivity();
    
    // Add connection state listeners
    _webSocketService.addActivityConnectionListener(_onActivityConnectionStateChange);
    _webSocketService.addMarketPriceConnectionListener(_onMarketPriceConnectionStateChange);
  }

  void _initializeAnimationControllers() {
    // Initialize animation controller for activity updates
    _activityAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _activityAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _activityAnimationController, curve: Curves.easeInOut),
    );
    
    // Mark animations as initialized
    _animationsInitialized = true;
  }

  void _initializeWebSocketConnections() {
    // Initialize WebSocket connections after a short delay to ensure auth is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        final token = await ApiService().getAccessToken();
        if (token != null) {
          _connectToWebSockets(token);
        }
      }
    });
  }

  void _connectToWebSockets(String token) {
    // Connect to activity stream
    _webSocketService.connectToActivityStream(token);
    
    // Add listener for activity updates
    _webSocketService.addActivityListener(_handleActivityUpdate);
    
    // Connect to market prices stream
    _webSocketService.connectToMarketPricesStream(token);
    
    // Add listener for market price updates
    _webSocketService.addMarketPriceListener(_handleMarketPriceUpdate);
  }

  void _onActivityConnectionStateChange(bool connected) {
    if (mounted) {
      if (connected) {
        debugPrint('Activity WebSocket connected');
      } else {
        debugPrint('Activity WebSocket disconnected');
      }
    }
  }

  void _onMarketPriceConnectionStateChange(bool connected) {
    if (mounted) {
      if (connected) {
        debugPrint('Market Prices WebSocket connected');
      } else {
        debugPrint('Market Prices WebSocket disconnected');
      }
    }
  }

  void _handleActivityUpdate(dynamic activityData) {
    if (mounted) {
      setState(() {
        // Add new activity at the beginning of the list
        final newActivity = {
          'icon': _getActivityIcon(activityData['type']),
          'title': activityData['description'] ?? 'New activity',
          'time': 'Just now',
          'color': _getActivityColor(activityData['type']),
        };
        
        // Add to the beginning of the list
        _recentActivities.insert(0, newActivity);
        
        // Keep only the 5 most recent activities
        if (_recentActivities.length > 5) {
          _recentActivities.removeLast();
        }
      });
      
      // Trigger animation for new activity only if initialized
      if (_animationsInitialized) {
        _activityAnimationController.forward().then((_) {
          _activityAnimationController.reverse();
        });
      }
    }
  }

  void _handleMarketPriceUpdate(MarketPriceModel priceData) {
    if (mounted) {
      setState(() {
        // Track this as an updated price
        _updatedPriceIds.add(priceData.id);
        
        // Check if we already have this price in our list
        final index = _marketPrices.indexWhere((price) => price.id == priceData.id);
        
        if (index != -1) {
          // Update existing price
          _marketPrices[index] = priceData;
        } else {
          // Add new price to the beginning of the list
          _marketPrices.insert(0, priceData);
          
          // Keep only the 5 most recent prices
          if (_marketPrices.length > 5) {
            _marketPrices.removeLast();
          }
        }
        
        // Initialize animation controller for this price if not already done
        if (!_priceAnimationControllers.containsKey(priceData.id)) {
          final controller = AnimationController(
            duration: const Duration(milliseconds: 1000),
            vsync: this,
          );
          final animation = Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
          
          _priceAnimationControllers[priceData.id] = controller;
          _priceAnimations[priceData.id] = animation;
        }
      });
      
      // Trigger animation for updated price only if initialized
      if (_priceAnimationControllers.containsKey(priceData.id) && _animationsInitialized) {
        _priceAnimationControllers[priceData.id]!.forward().then((_) {
          _priceAnimationControllers[priceData.id]!.reverse();
          
          // Remove the updated flag after animation
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _updatedPriceIds.remove(priceData.id);
              });
            }
          });
        });
      }
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'product_added':
        return Icons.add_circle;
      case 'community_post':
        return Icons.forum;
      case 'ai_diagnosis':
        return Icons.science;
      case 'market_price_update':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'product_added':
        return AppColors.success;
      case 'community_post':
        return AppColors.info;
      case 'ai_diagnosis':
        return AppColors.warning;
      case 'market_price_update':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _loadMarketPrices() async {
    if (_isLoadingMarketPrices) return;
    
    setState(() {
      _isLoadingMarketPrices = true;
      _marketPricesError = null;
    });

    try {
      // Check if we're online
      final isOnline = await _webSocketService.isOnline();
      setState(() {
        _isOffline = !isOnline;
      });
      
      final result = await _marketPriceService.getMarketPrices(
        pageSize: 5,
        useCache: true, // Use cache for offline support
      );
      
      if (result.isSuccess && mounted) {
        setState(() {
          _marketPrices = result.prices;
        });
      } else if (mounted) {
        setState(() {
          _marketPricesError = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marketPricesError = 'Failed to load market prices';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMarketPrices = false;
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _webSocketService.isOnline();
      if (mounted) {
        setState(() {
          _isOffline = !isOnline;
        });
      }
    } catch (e) {
      // Ignore connectivity check errors
    }
  }

  @override
  void dispose() {
    // Clean up animation controllers
    _activityAnimationController.dispose();
    
    // Clean up price animation controllers
    for (var controller in _priceAnimationControllers.values) {
      controller.dispose();
    }
    
    // Clean up WebSocket connections
    _webSocketService.disconnectFromActivityStream();
    _webSocketService.disconnectFromMarketPricesStream();
    
    // Remove listeners
    _webSocketService.removeActivityListener(_handleActivityUpdate);
    _webSocketService.removeMarketPriceListener(_handleMarketPriceUpdate);
    _webSocketService.removeActivityConnectionListener(_onActivityConnectionStateChange);
    _webSocketService.removeMarketPriceConnectionListener(_onMarketPriceConnectionStateChange);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildStatsCards(),
                    const SizedBox(height: 32),
                    _buildRecentActivity(),
                    const SizedBox(height: 32),
                    _buildWeatherWidget(),
                    const SizedBox(height: 32),
                    _buildMarketPrices(),
                    const SizedBox(height: 120), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showQuickActionBottomSheet(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, size: 28),
          label: Text(
            LocalizationService().getString('quickAction'),
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Icon(Icons.menu_rounded, color: Colors.white),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/dashboard_header.png',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black45,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 25,
              right: 20,
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationService().getString('welcomeBackUser')} ${user?.displayName ?? 'User'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: 0.9,
                        child: Text(
                          LocalizationService().getString('connectLearnGrow'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocalizationService().getString('quickActions'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildActionCard(
              icon: Icons.add_business_rounded,
              title: LocalizationService().getString('addProduct'),
              subtitle: LocalizationService().getString('listProduce'),
              color: AppColors.success,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              ),
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              icon: Icons.biotech_rounded,
              title: LocalizationService().getString('aiDiagnosis'),
              subtitle: LocalizationService().getString('pestDiagnosis'),
              color: AppColors.info,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PestDiagnosisScreenWidget()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              icon: Icons.forum_rounded,
              title: LocalizationService().getString('askQuestion'),
              subtitle: LocalizationService().getString('communityForum'),
              color: AppColors.warning,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              ),
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              icon: Icons.analytics_rounded,
              title: LocalizationService().getString('marketPrices'),
              subtitle: LocalizationService().getString('currentPrices'),
              color: AppColors.secondary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MarketPricesScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationService().getString('userActivity'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Products',
                value: '12',
                icon: Icons.inventory,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Posts',
                value: '8',
                icon: Icons.article,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Diagnoses',
                value: '5',
                icon: Icons.science,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocalizationService().getString('userActivity'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(onPressed: () {}, child: Text(LocalizationService().getString('viewAll'))),
          ],
        ),
        const SizedBox(height: 16),
        ..._recentActivities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return _buildActivityItem(
            icon: activity['icon'],
            title: activity['title'],
            time: activity['time'],
            color: activity['color'],
            isNew: index == 0, // Mark the first (most recent) as new
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
    bool isNew = false,
  }) {
    Widget activityItem = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Add visual indicator for new items with animation only when initialized
    if (_animationsInitialized && isNew) {
      return ScaleTransition(
        scale: _activityAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: activityItem,
        ),
      );
    }

    return activityItem;
  }

  Widget _buildWeatherWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Weather',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.wb_sunny, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '28°C',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sunny',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Blantyre, Malawi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildWeatherDetail('Humidity', '65%'),
              const SizedBox(width: 24),
              _buildWeatherDetail('Wind', '12 km/h'),
              const SizedBox(width: 24),
              _buildWeatherDetail('Rain', '0mm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketPrices() {
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
            TextButton(
              onPressed: _loadMarketPrices,
              child: Text(LocalizationService().getString('viewAll')),
            ),
          ],
        ),
        if (_isOffline)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'Showing cached data - offline mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_isLoadingMarketPrices)
          const Center(child: CircularProgressIndicator())
        else if (_marketPricesError != null)
          Center(
            child: Text(
              _marketPricesError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
            ),
          )
        else if (_marketPrices.isEmpty)
          Center(
            child: Text(
              'No market prices available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ..._marketPrices.map((price) {
            // Determine trend and color
            String trend = '→';
            Color trendColor = AppColors.textSecondary;
            
            // For demo purposes, we'll simulate some price changes
            // In a real implementation, this would come from the data
            if (price.pricePerUnit > 0) {
              // Random trend for demo
              final random = DateTime.now().millisecondsSinceEpoch % 3;
              if (random == 0) {
                trend = '↗';
                trendColor = AppColors.success;
              } else if (random == 1) {
                trend = '↘';
                trendColor = AppColors.error;
              }
            }
            
            return _buildPriceItem(
              product: '${price.productCategory} - ${price.marketName}',
              price: price.formattedPrice,
              trend: trend,
              trendColor: trendColor,
              priceId: price.id,
            );
          }),
      ],
    );
  }

  Widget _buildPriceItem({
    required String product,
    required String price,
    required String trend,
    required Color trendColor,
    int? priceId,
  }) {
    Widget priceItem = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.agriculture,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest price',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trend,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Add animation for updated items only when initialized
    if (priceId != null && _priceAnimations.containsKey(priceId) && _animationsInitialized) {
      return ScaleTransition(
        scale: _priceAnimations[priceId]!,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _updatedPriceIds.contains(priceId)
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: priceItem,
        ),
      );
    }

    // Add visual indicator for updated items without animation
    if (priceId != null && _updatedPriceIds.contains(priceId)) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: priceItem,
      );
    }

    return priceItem;
  }

  Future<void> _refreshDashboard() async {
    // Refresh both activities and market prices
    await Future.wait([
      _loadMarketPrices(),
      Future.delayed(const Duration(seconds: 1)), // Simulate refresh delay
    ]);
    
    if (mounted) {
      setState(() {
        // Refresh data
      });
    }
  }

  void _showQuickActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LocalizationService().getString('quickActions'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Make the content scrollable to prevent overflow
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickActionItem(
                      icon: Icons.add_box,
                      title: LocalizationService().getString('addProduct'),
                      subtitle: LocalizationService().getString('listProduce'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.bug_report,
                      title: LocalizationService().getString('aiDiagnosis'),
                      subtitle: LocalizationService().getString('pestDiagnosis'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PestDiagnosisScreenWidget(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.forum,
                      title: LocalizationService().getString('askQuestion'),
                      subtitle: LocalizationService().getString('communityForum'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreatePostScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.people,
                      title: LocalizationService().getString('community'),
                      subtitle: LocalizationService().getString('communityForum'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CommunityScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.cloud,
                      title: LocalizationService().getString('weather'),
                      subtitle: LocalizationService().getString('weatherForecast'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WeatherScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.article,
                      title: LocalizationService().getString('newsletters'),
                      subtitle: LocalizationService().getString('subscribeToReports'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NewsletterSubscriptionScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.description,
                      title: LocalizationService().getString('reports'),
                      subtitle: LocalizationService().getString('myReports'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ReportsDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.person,
                      title: LocalizationService().getString('profile'),
                      subtitle: LocalizationService().getString('editProfile'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(), // Remove const
                          ),
                        );
                      },
                    ),
                    _buildQuickActionItem(
                      icon: Icons.settings,
                      title: LocalizationService().getString('settings'),
                      subtitle: LocalizationService().getString('appSettings'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(), // Remove const
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}