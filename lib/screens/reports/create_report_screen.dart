import 'package:flutter/material.dart';
import 'package:mulimi/core/services/api_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/report_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late ReportService _reportService;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _reportType = 'MARKET_ANALYSIS';
  String _format = 'PDF';
  bool _isPublic = false;

  // Filter fields
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dateFrom) {
      setState(() {
        _dateFrom = picked;
      });
    }
  }

  Future<void> _selectDateTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dateTo) {
      setState(() {
        _dateTo = picked;
      });
    }
  }

  Future<void> _createReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await ApiService().getAccessToken();

      // Build filters map
      final Map<String, dynamic> filters = {};
      if (_categoryController.text.isNotEmpty) {
        filters['category'] = _categoryController.text;
      }
      if (_locationController.text.isNotEmpty) {
        filters['location'] = _locationController.text;
      }
      if (_dateFrom != null) {
        filters['date_from'] = _dateFrom!.toIso8601String();
      }
      if (_dateTo != null) {
        filters['date_to'] = _dateTo!.toIso8601String();
      }

      await _reportService.createReport(
        title: _titleController.text,
        description: _descriptionController.text,
        reportType: _reportType,
        format: _format,
        isPublic: _isPublic,
        filters: filters,
        authToken: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate successful creation
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create report: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createReport),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _reportType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MARKET_ANALYSIS',
                    child: Text('Market Analysis'),
                  ),
                  DropdownMenuItem(
                    value: 'CROP_PERFORMANCE',
                    child: Text('Crop Performance'),
                  ),
                  DropdownMenuItem(
                    value: 'WEATHER_IMPACT',
                    child: Text('Weather Impact'),
                  ),
                  DropdownMenuItem(
                    value: 'PEST_DISEASE',
                    child: Text('Pest & Disease'),
                  ),
                  DropdownMenuItem(
                    value: 'FINANCIAL',
                    child: Text('Financial Analysis'),
                  ),
                  DropdownMenuItem(
                    value: 'GENERAL',
                    child: Text('General Report'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _reportType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _format,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PDF',
                    child: Text('PDF'),
                  ),
                  DropdownMenuItem(
                    value: 'EXCEL',
                    child: Text('Excel'),
                  ),
                  DropdownMenuItem(
                    value: 'CSV',
                    child: Text('CSV'),
                  ),
                  DropdownMenuItem(
                    value: 'JSON',
                    child: Text('JSON'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _format = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Make Public:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Filters (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Maize, Beans, etc.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Blantyre, Lilongwe, etc.',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date From',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      controller: _dateFrom != null
                          ? TextEditingController(
                              text:
                                  '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}')
                          : null,
                      onTap: _selectDateFrom,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Date To',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      controller: _dateTo != null
                          ? TextEditingController(
                              text:
                                  '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}')
                          : null,
                      onTap: _selectDateTo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Card(
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}