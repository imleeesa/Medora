import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        final profile = provider.currentProfile;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F8),
          appBar: AppBar(title: const Text('Impostazioni')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SettingsSection(
                title: 'Preferenze',
                children: [
                  SwitchListTile(
                    value: profile.notificationsEnabled,
                    activeColor: const Color(0xFF2E7D32),
                    title: const Text('Notifiche'),
                    subtitle: const Text('Promemoria per le terapie attive'),
                    onChanged: (value) {
                      provider.updateProfile(
                        name: profile.name,
                        notificationsEnabled: value,
                      );
                    },
                  ),
                  const SwitchListTile(
                    value: false,
                    title: Text('Tema scuro'),
                    subtitle: Text('Disponibile in una prossima versione'),
                    onChanged: null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Dati',
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.backup_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    title: const Text('Backup'),
                    subtitle: const Text('Predisposizione per backup futuro'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPlannedFeatureMessage(context, 'Backup'),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    title: const Text('Report medico PDF'),
                    subtitle: const Text('Esportazione predisposta'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPlannedFeatureMessage(
                      context,
                      'Report medico PDF',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlannedFeatureMessage(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$featureName sara' disponibile in una prossima versione",
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
