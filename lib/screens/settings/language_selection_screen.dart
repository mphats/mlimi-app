import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/localization_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizationService.getString('language')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizationService.getString('language'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              'en',
              localizationService.getString('english'),
              localizationService.currentLanguage == 'en',
              localizationService,
            ),
            const SizedBox(height: 10),
            _buildLanguageOption(
              context,
              'ch', // Changed from 'ny' to 'ch' to match backend
              localizationService.getString('chichewa'),
              localizationService.currentLanguage == 'ch',
              localizationService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String languageName,
    bool isSelected,
    LocalizationService localizationService,
  ) {
    return Card(
      child: ListTile(
        title: Text(languageName),
        trailing: isSelected
            ? const Icon(Icons.check, color: Colors.green)
            : null,
        onTap: () {
          localizationService.setLanguage(languageCode);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}