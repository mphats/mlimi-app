import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../models/consultation_model.dart';
import '../../widgets/custom_button.dart';
import 'consultation_detail_screen.dart';
import 'create_consultation_screen.dart';

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  List<ConsultationModel> _consultations = [];
  bool _isLoading = true;
  bool _isExpert = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadConsultations();
  }

  void _checkUserRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isExpert = authProvider.user?.role == 'AGRONOMIST';
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final consultations = await ApiService().getConsultations();
      if (mounted) {
        setState(() {
          _consultations = consultations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading consultations: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _refreshConsultations() {
    _loadConsultations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isExpert
            ? AppStrings.expertConsultations
            : AppStrings.myConsultations),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConsultations,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isExpert)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: AppStrings.requestConsultation,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateConsultationScreen(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadConsultations(); // Refresh after creating
                    }
                  });
                },
                icon: Icons.add,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _consultations.isEmpty
                    ? _buildEmptyState()
                    : _buildConsultationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isExpert ? Icons.work_outline : Icons.question_answer_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _isExpert
                ? 'No consultation requests'
                : 'No consultations yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isExpert
                ? 'Consultation requests will appear here'
                : 'Request expert advice to get started',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (!_isExpert) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: AppStrings.requestConsultation,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateConsultationScreen(),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadConsultations(); // Refresh after creating
                  }
                });
              },
              icon: Icons.add,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultationList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadConsultations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          final consultation = _consultations[index];
          return _buildConsultationItem(consultation);
        },
      ),
    );
  }

  Widget _buildConsultationItem(ConsultationModel consultation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConsultationDetailScreen(
                consultation: consultation,
              ),
            ),
          ).then((value) {
            if (value == true) {
              _loadConsultations(); // Refresh after changes
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      consultation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(consultation.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      consultation.status.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                consultation.description.length > 120
                    ? '${consultation.description.substring(0, 120)}...'
                    : consultation.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    consultation.category.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Priority: ${consultation.priority}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (consultation.expert != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expert: ${consultation.expert!.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(consultation.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (consultation.isPremium) ...[
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}