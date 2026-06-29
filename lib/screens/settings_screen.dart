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
                title: 'Notifiche',
                children: [
                  _NotificationSettingsContent(
                    provider: provider,
                    notificationsEnabled: profile.notificationsEnabled,
                    onToggleNotifications: (value) async {
                      await provider.updateProfile(
                        name: profile.name,
                        notificationsEnabled: value,
                      );
                      if (!context.mounted) return;
                      if (value &&
                          !provider
                              .notificationPermissionStatus
                              .remindersCanBeScheduled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notifiche app attive, ma controlla i permessi Android.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _SettingsSection(
                title: 'Preferenze',
                children: [
                  SwitchListTile(
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

class _NotificationSettingsContent extends StatelessWidget {
  final MedicineProvider provider;
  final bool notificationsEnabled;
  final ValueChanged<bool> onToggleNotifications;

  const _NotificationSettingsContent({
    required this.provider,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final status = provider.notificationPermissionStatus;

    return Column(
      children: [
        SwitchListTile(
          value: notificationsEnabled,
          activeColor: const Color(0xFF2E7D32),
          title: const Text('Promemoria app'),
          subtitle: Text(
            notificationsEnabled
                ? 'Le notifiche sono attive nell app.'
                : 'Le notifiche sono disattivate nell app.',
          ),
          onChanged: onToggleNotifications,
        ),
        const Divider(height: 1),
        _NotificationStatusTile(
          icon: Icons.notifications_active_outlined,
          title: 'Permesso notifiche Android',
          value: !status.localNotificationsSupported
              ? 'Non supportato su questa piattaforma'
              : status.notificationsAllowed
              ? 'Concesso'
              : 'Non concesso',
          warning:
              status.localNotificationsSupported &&
              !status.notificationsAllowed,
          description: status.notificationsAllowed
              ? 'I promemoria possono essere mostrati dal sistema.'
              : 'Il permesso notifiche non e concesso. I promemoria potrebbero non arrivare.',
        ),
        _NotificationStatusTile(
          icon: Icons.alarm_on_outlined,
          title: 'Exact alarm',
          value: !status.exactAlarmsCanBeChecked
              ? 'Non verificabile'
              : status.exactAlarmsAllowed
              ? 'Disponibile'
              : 'Non disponibile',
          warning: status.exactAlarmsCanBeChecked && !status.exactAlarmsAllowed,
          description: status.exactAlarmsAllowed
              ? 'Gli orari dei promemoria possono essere pianificati con precisione.'
              : 'Android potrebbe non consentire promemoria precisi.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _refreshStatus(context, provider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Aggiorna stato'),
              ),
              if (status.localNotificationsSupported &&
                  !status.notificationsAllowed)
                FilledButton.icon(
                  onPressed: () =>
                      _requestNotificationPermission(context, provider),
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: const Text('Richiedi permesso'),
                ),
              if (status.exactAlarmsCanBeChecked && !status.exactAlarmsAllowed)
                OutlinedButton.icon(
                  onPressed: () =>
                      _requestExactAlarmPermission(context, provider),
                  icon: const Icon(Icons.alarm_add_outlined, size: 18),
                  label: const Text('Exact alarm'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        const _NotificationStatusTile(
          icon: Icons.battery_saver_outlined,
          title: 'Ottimizzazione batteria',
          value: 'Da controllare sul telefono',
          warning: false,
          description:
              'Android e Samsung possono limitare i promemoria se l app e ottimizzata per la batteria.',
        ),
      ],
    );
  }

  Future<void> _refreshStatus(
    BuildContext context,
    MedicineProvider provider,
  ) async {
    await provider.refreshNotificationPermissionStatus();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stato notifiche aggiornato.')),
    );
  }

  Future<void> _requestNotificationPermission(
    BuildContext context,
    MedicineProvider provider,
  ) async {
    await provider.requestNotificationPermission();
    if (!context.mounted) return;
    final allowed = provider.notificationPermissionStatus.notificationsAllowed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowed
              ? 'Permesso notifiche concesso.'
              : 'Permesso notifiche non concesso. Puoi abilitarlo dalle impostazioni Android.',
        ),
      ),
    );
  }

  Future<void> _requestExactAlarmPermission(
    BuildContext context,
    MedicineProvider provider,
  ) async {
    await provider.requestExactAlarmPermission();
    if (!context.mounted) return;
    final allowed = provider.notificationPermissionStatus.exactAlarmsAllowed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowed
              ? 'Exact alarm disponibile.'
              : 'Exact alarm non disponibile. Controlla le impostazioni promemoria del telefono.',
        ),
      ),
    );
  }
}

class _NotificationStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool warning;
  final String description;

  const _NotificationStatusTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.warning,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange.shade700 : const Color(0xFF2E7D32);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(description),
      trailing: SizedBox(
        width: 116,
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
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
