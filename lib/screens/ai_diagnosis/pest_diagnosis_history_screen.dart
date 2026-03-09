import 'package:flutter/material.dart';
import '../../core/services/pest_diagnosis_service.dart';
import '../../core/models/pest_diagnosis_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PestDiagnosisHistoryScreen extends StatefulWidget {
  const PestDiagnosisHistoryScreen({super.key});

  @override
  State<PestDiagnosisHistoryScreen> createState() =>
      _PestDiagnosisHistoryScreenState();
}

class _PestDiagnosisHistoryScreenState
    extends State<PestDiagnosisHistoryScreen> {
  List<PestDiagnosisModel> _diagnosisHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDiagnosisHistory();
  }

  Future<void> _loadDiagnosisHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final diagnosisService = PestDiagnosisService();
      final result = await diagnosisService.getDiagnosisHistory();

      if (result.isSuccess) {
        setState(() {
          _diagnosisHistory = result.diagnoses;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load diagnosis history';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pest Diagnosis History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDiagnosisHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDiagnosisHistory,
                          child: Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  )
                : _diagnosisHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No diagnosis history found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _diagnosisHistory.length,
                        itemBuilder: (context, index) {
                          final diagnosis = _diagnosisHistory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                diagnosis.cropType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detected Pest: ${diagnosis.diagnosis}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${diagnosis.createdAt.toString().split(' ').first}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${(diagnosis.confidenceScore * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                // Navigate to detailed view if needed
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}