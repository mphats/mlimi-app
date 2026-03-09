import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizationService.getString('language'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(localizationService.getString('english')),
              trailing: Radio<String>(
                value: 'en',
                // ignore: deprecated_member_use
                groupValue: localizationService.currentLanguage,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    localizationService.setLanguage(value);
                  }
                },
              ),
              onTap: () {
                localizationService.setLanguage('en');
              },
            ),
            ListTile(
              title: Text(localizationService.getString('chichewa')),
              trailing: Radio<String>(
                value: 'ch',
                // ignore: deprecated_member_use
                groupValue: localizationService.currentLanguage,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    localizationService.setLanguage(value);
                  }
                },
              ),
              onTap: () {
                localizationService.setLanguage('ch');
              },
            ),
          ],
        ),
      ),
    );
  }
}