import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:meditrack/app.dart';
import 'package:meditrack/models/app_settings.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/notification_permission_status.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/models/user_profile.dart';
import 'package:meditrack/providers/medicine_provider.dart';
import 'package:meditrack/repositories/intake_repository.dart';
import 'package:meditrack/repositories/medicine_repository.dart';
import 'package:meditrack/repositories/profile_repository.dart';
import 'package:meditrack/repositories/settings_repository.dart';
import 'package:meditrack/repositories/therapy_repository.dart';
import 'package:meditrack/screens/settings_screen.dart';
import 'package:meditrack/screens/medicine_detail_screen.dart';
import 'package:meditrack/services/intake_action_service.dart';
import 'package:meditrack/services/notification_action_handler.dart';
import 'package:meditrack/services/notification_navigation_service.dart';
import 'package:meditrack/services/notification_service.dart';

void main() {
  group('MedicineProvider notification scheduling', () {
    test(
      'initializes notifications and reschedules only active medicines',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-active',
              medicines: [
                _medicine(id: 'active-medicine', therapyId: 'therapy-active'),
                _medicine(
                  id: 'inactive-medicine',
                  therapyId: 'therapy-active',
                  isActive: false,
                ),
              ],
            ),
            _therapy(
              id: 'therapy-archived',
              isActive: false,
              medicines: [
                _medicine(
                  id: 'archived-medicine',
                  therapyId: 'therapy-archived',
                ),
              ],
            ),
          ],
        );

        await fixture.provider.initialize();
        await fixture.provider.initialize();

        expect(fixture.notifications.initializeCount, 1);
        expect(fixture.notifications.rescheduledBatches, [
          ['active-medicine'],
        ]);
        expect(fixture.notifications.cancelAllCount, 0);
      },
    );

    test(
      'modifying a medicine cancels the old reminder before scheduling the updated one',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateMedicine(
          id: 'medicine-1',
          name: 'Aspirina aggiornata',
          dose: '1/2 pastiglia',
          times: const [TimeOfDay(hour: 9, minute: 30)],
          daysOfWeek: const [DateTime.tuesday],
          stockQuantity: 8,
          stockWarningThreshold: 2,
          isActive: true,
        );

        expect(fixture.notifications.cancelledMedicineIds, ['medicine-1']);
        expect(fixture.notifications.scheduledMedicineIds, ['medicine-1']);
        expect(
          fixture.medicineRepository.medicines['medicine-1']?.dose,
          '1/2 pastiglia',
        );
      },
    );

    test(
      'modifying a medicine can persist different schedules for the same medicine',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateMedicine(
          id: 'medicine-1',
          name: 'Tachipirina',
          dose: '1 compressa',
          times: const [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 14, minute: 0),
          ],
          daysOfWeek: const [DateTime.monday, DateTime.wednesday],
          schedules: const [
            MedicineSchedule(
              time: TimeOfDay(hour: 8, minute: 0),
              daysOfWeek: [DateTime.monday],
            ),
            MedicineSchedule(
              time: TimeOfDay(hour: 14, minute: 0),
              daysOfWeek: [DateTime.wednesday],
            ),
          ],
          stockQuantity: 10,
          stockWarningThreshold: 2,
          isActive: true,
        );

        final updated = fixture.provider.getMedicineById('medicine-1')!;
        expect(updated.id, 'medicine-1');
        expect(updated.schedules, hasLength(2));
        expect(updated.schedules[0].daysOfWeek, [DateTime.monday]);
        expect(updated.schedules[1].daysOfWeek, [DateTime.wednesday]);
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-1']);
        expect(fixture.notifications.scheduledMedicineIds, ['medicine-1']);
      },
    );

    test('dashboard intakes distinguish two slots on the same day', () async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [
              _medicine(
                id: 'medicine-1',
                therapyId: 'therapy-1',
                times: const [
                  TimeOfDay(hour: 8, minute: 0),
                  TimeOfDay(hour: 20, minute: 0),
                ],
                daysOfWeek: const [DateTime.monday],
                schedules: const [
                  MedicineSchedule(
                    time: TimeOfDay(hour: 8, minute: 0),
                    daysOfWeek: [DateTime.monday],
                  ),
                  MedicineSchedule(
                    time: TimeOfDay(hour: 20, minute: 0),
                    daysOfWeek: [DateTime.monday],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await fixture.provider.initialize();

      final intakes = fixture.provider.getTodayScheduledIntakes(
        date: DateTime(2026, 7, 6),
      );

      expect(intakes, hasLength(2));
      expect(intakes[0].scheduledDateTime.hour, 8);
      expect(intakes[1].scheduledDateTime.hour, 20);

      await fixture.provider.markMedicineAsTaken(
        medicineId: 'medicine-1',
        scheduledDateTime: DateTime(2026, 7, 6, 8),
      );
      await fixture.provider.markMedicineAsSkipped(
        medicineId: 'medicine-1',
        scheduledDateTime: DateTime(2026, 7, 6, 20),
      );

      expect(fixture.provider.intakeHistory, hasLength(2));
      expect(
        fixture.provider.intakeHistory.map((record) => record.status),
        containsAll([IntakeStatus.taken, IntakeStatus.skipped]),
      );
    });

    test(
      'stock changes are isolated per real scheduled slot on the same day',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  dose: '1 compressa',
                  stockQuantity: 10,
                  times: const [
                    TimeOfDay(hour: 8, minute: 0),
                    TimeOfDay(hour: 20, minute: 0),
                  ],
                  daysOfWeek: const [DateTime.monday],
                  schedules: const [
                    MedicineSchedule(
                      time: TimeOfDay(hour: 8, minute: 0),
                      daysOfWeek: [DateTime.monday],
                    ),
                    MedicineSchedule(
                      time: TimeOfDay(hour: 20, minute: 0),
                      daysOfWeek: [DateTime.monday],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
        );
        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
        );
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          9,
        );

        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 6, 20),
        );
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          8,
        );

        await fixture.provider.markMedicineAsSkipped(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 6, 20),
        );

        expect(fixture.provider.intakeHistory, hasLength(2));
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          9,
        );
        expect(
          fixture.provider.intakeHistory
              .where(
                (record) => record.scheduledDateTime == DateTime(2026, 7, 6, 8),
              )
              .single
              .status,
          IntakeStatus.taken,
        );
        expect(
          fixture.provider.intakeHistory
              .where(
                (record) =>
                    record.scheduledDateTime == DateTime(2026, 7, 6, 20),
              )
              .single
              .status,
          IntakeStatus.skipped,
        );
      },
    );

    test(
      'advanced schedules do not create cartesian slots for next intake or today list',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  name: 'Tachipirina',
                  times: const [
                    TimeOfDay(hour: 14, minute: 30),
                    TimeOfDay(hour: 15, minute: 30),
                    TimeOfDay(hour: 15, minute: 35),
                    TimeOfDay(hour: 16, minute: 35),
                  ],
                  daysOfWeek: const [
                    DateTime.monday,
                    DateTime.tuesday,
                    DateTime.saturday,
                    DateTime.sunday,
                  ],
                  schedules: _advancedSchedules(),
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        final sunday = DateTime(2026, 7, 5, 15, 33);
        final sundayIntakes = fixture.provider.getTodayScheduledIntakes(
          date: sunday,
        );
        final next = fixture.provider.getNextScheduledIntake(
          referenceDate: sunday,
        );

        expect(
          sundayIntakes.map(
            (intake) => TimeOfDay.fromDateTime(intake.scheduledDateTime),
          ),
          const [
            TimeOfDay(hour: 14, minute: 30),
            TimeOfDay(hour: 16, minute: 35),
          ],
        );
        expect(
          sundayIntakes.any(
            (intake) =>
                intake.scheduledDateTime.hour == 15 &&
                intake.scheduledDateTime.minute == 35,
          ),
          isFalse,
        );
        expect(next?.scheduledDateTime, DateTime(2026, 7, 5, 16, 35));

        expect(
          fixture.provider
              .getTodayScheduledIntakes(date: DateTime(2026, 7, 6))
              .map(
                (intake) => TimeOfDay.fromDateTime(intake.scheduledDateTime),
              ),
          const [
            TimeOfDay(hour: 15, minute: 30),
            TimeOfDay(hour: 15, minute: 35),
          ],
        );
        expect(
          fixture.provider
              .getTodayScheduledIntakes(date: DateTime(2026, 7, 7))
              .map(
                (intake) => TimeOfDay.fromDateTime(intake.scheduledDateTime),
              ),
          const [
            TimeOfDay(hour: 14, minute: 30),
            TimeOfDay(hour: 16, minute: 35),
          ],
        );
        expect(
          fixture.provider
              .getTodayScheduledIntakes(date: DateTime(2026, 7, 11))
              .map(
                (intake) => TimeOfDay.fromDateTime(intake.scheduledDateTime),
              ),
          const [
            TimeOfDay(hour: 15, minute: 30),
            TimeOfDay(hour: 15, minute: 35),
          ],
        );
      },
    );

    test(
      'deleting and deactivating medicines cancel reminders, reactivation schedules them again',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(id: 'medicine-delete', therapyId: 'therapy-1'),
                _medicine(id: 'medicine-toggle', therapyId: 'therapy-1'),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.deleteMedicine('medicine-delete');
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-delete']);

        fixture.notifications.clear();
        await fixture.provider.toggleMedicineActive('medicine-toggle');
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-toggle']);
        expect(fixture.notifications.scheduledMedicineIds, isEmpty);

        fixture.notifications.clear();
        await fixture.provider.toggleMedicineActive('medicine-toggle');
        expect(fixture.notifications.scheduledMedicineIds, ['medicine-toggle']);
        expect(fixture.notifications.cancelledMedicineIds, isEmpty);
      },
    );

    test(
      'archiving, reactivating and deleting therapies update reminders safely',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(id: 'medicine-1', therapyId: 'therapy-1'),
                _medicine(id: 'medicine-2', therapyId: 'therapy-1'),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.archiveTherapy('therapy-1');
        expect(fixture.notifications.cancelledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);

        fixture.notifications.clear();
        await fixture.provider.reactivateTherapy('therapy-1');
        expect(fixture.notifications.scheduledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);

        fixture.notifications.clear();
        await fixture.provider.deleteTherapy('therapy-1');
        expect(fixture.notifications.cancelledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);
      },
    );

    test(
      'profile notification toggle cancels all reminders or reschedules active ones',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateProfile(
          name: 'Utente',
          notificationsEnabled: false,
        );
        expect(fixture.notifications.cancelAllCount, 1);
        expect(fixture.notifications.rescheduledBatches, isEmpty);

        fixture.notifications.clear();
        await fixture.provider.updateProfile(
          name: 'Utente',
          notificationsEnabled: true,
        );
        expect(fixture.notifications.cancelAllCount, 0);
        expect(fixture.notifications.rescheduledBatches, [
          ['medicine-1'],
        ]);
      },
    );

    test(
      'notification permission failures do not block saved medicine changes',
      () async {
        final fixture = _ProviderFixture(
          therapies: [_therapy(id: 'therapy-1')],
          notifications: _FakeNotificationScheduler(throwOnSchedule: true),
        );
        await fixture.provider.initialize();

        await fixture.provider.addMedicine(
          therapyId: 'therapy-1',
          name: 'Vitamina D',
          dose: '1 compressa',
          times: const [TimeOfDay(hour: 8, minute: 0)],
          daysOfWeek: const [DateTime.monday],
          stockQuantity: 10,
          stockWarningThreshold: 2,
        );

        expect(fixture.provider.errorMessage, isNull);
        expect(
          fixture.provider.getMedicineById(fixture.createdMedicineId),
          isNotNull,
        );
        expect(fixture.notifications.scheduledMedicineIds, isEmpty);
      },
    );

    test('creating a medicine deduplicates identical schedule slots', () async {
      final fixture = _ProviderFixture(therapies: [_therapy(id: 'therapy-1')]);
      await fixture.provider.initialize();

      await fixture.provider.addMedicine(
        therapyId: 'therapy-1',
        name: 'Antibiotico',
        dose: '1 compressa',
        times: const [TimeOfDay(hour: 8, minute: 0)],
        daysOfWeek: const [DateTime.monday],
        schedules: const [
          MedicineSchedule(
            time: TimeOfDay(hour: 8, minute: 0),
            daysOfWeek: [DateTime.monday, DateTime.monday],
          ),
          MedicineSchedule(
            time: TimeOfDay(hour: 8, minute: 0),
            daysOfWeek: [DateTime.monday],
          ),
        ],
        stockQuantity: 10,
        stockWarningThreshold: 2,
      );

      final created = fixture.provider.medicines.single;
      expect(created.name, 'Antibiotico');
      expect(created.schedules, hasLength(1));
      expect(created.schedules.single.daysOfWeek, [DateTime.monday]);
    });

    test(
      'notification scheduling receives only real advanced schedule slots',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  schedules: _advancedSchedules(),
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        expect(
          fixture.notifications.rescheduledSlots.single,
          containsAll([
            'medicine-1|1|15|30',
            'medicine-1|1|15|35',
            'medicine-1|6|15|30',
            'medicine-1|6|15|35',
            'medicine-1|2|14|30',
            'medicine-1|2|16|35',
            'medicine-1|7|14|30',
            'medicine-1|7|16|35',
          ]),
        );
        expect(
          fixture.notifications.rescheduledSlots.single,
          isNot(contains('medicine-1|7|15|35')),
        );
      },
    );

    test(
      'updating advanced schedules removes old dashboard and notification slots',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  schedules: _advancedSchedules(),
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateMedicine(
          id: 'medicine-1',
          name: 'Tachis',
          dose: '1 compressa',
          times: const [TimeOfDay(hour: 18, minute: 0)],
          daysOfWeek: const [DateTime.sunday],
          schedules: const [
            MedicineSchedule(
              time: TimeOfDay(hour: 18, minute: 0),
              daysOfWeek: [DateTime.sunday],
            ),
          ],
          stockQuantity: 10,
          stockWarningThreshold: 2,
          isActive: true,
        );

        expect(
          fixture.provider
              .getTodayScheduledIntakes(date: DateTime(2026, 7, 5))
              .map((intake) => intake.scheduledDateTime),
          [DateTime(2026, 7, 5, 18)],
        );
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-1']);
        expect(fixture.notifications.scheduledSlots, ['medicine-1|7|18|0']);
        expect(
          fixture.notifications.scheduledSlots,
          isNot(contains('medicine-1|7|16|35')),
        );
      },
    );

    test(
      'notification initialization failures do not block provider startup',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
          notifications: _FakeNotificationScheduler(throwOnInitialize: true),
        );

        await fixture.provider.initialize();

        expect(fixture.provider.errorMessage, isNull);
        expect(fixture.provider.medicines, hasLength(1));
      },
    );

    test(
      'exact alarm or permission denial during reschedule is best effort',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
          notifications: _FakeNotificationScheduler(throwOnReschedule: true),
        );

        await fixture.provider.initialize();

        expect(fixture.provider.errorMessage, isNull);
        expect(fixture.provider.medicines, hasLength(1));
      },
    );

    test(
      'notification permission status can be refreshed and requested safely',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
          notifications: _FakeNotificationScheduler(
            permissionStatus: const NotificationPermissionStatus(
              localNotificationsSupported: true,
              notificationsAllowed: false,
              exactAlarmsAllowed: false,
              exactAlarmsCanBeChecked: true,
            ),
            requestedNotificationStatus: const NotificationPermissionStatus(
              localNotificationsSupported: true,
              notificationsAllowed: true,
              exactAlarmsAllowed: false,
              exactAlarmsCanBeChecked: true,
            ),
            requestedExactAlarmStatus: const NotificationPermissionStatus(
              localNotificationsSupported: true,
              notificationsAllowed: true,
              exactAlarmsAllowed: true,
              exactAlarmsCanBeChecked: true,
            ),
          ),
        );

        await fixture.provider.initialize();
        expect(
          fixture.provider.notificationPermissionStatus.notificationsAllowed,
          isFalse,
        );

        await fixture.provider.requestNotificationPermission();
        expect(
          fixture.provider.notificationPermissionStatus.notificationsAllowed,
          isTrue,
        );
        expect(
          fixture.provider.notificationPermissionStatus.exactAlarmsAllowed,
          isFalse,
        );

        await fixture.provider.requestExactAlarmPermission();
        expect(
          fixture.provider.notificationPermissionStatus.remindersCanBeScheduled,
          isTrue,
        );
        expect(fixture.notifications.rescheduledBatches, [
          ['medicine-1'],
          ['medicine-1'],
          ['medicine-1'],
        ]);
      },
    );

    test(
      'taken crossing low stock threshold sends one low stock alert',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  dose: '1 compressa',
                  stockQuantity: 6,
                  stockWarningThreshold: 5,
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 2, 8),
        );
        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 2, 12),
        );

        expect(fixture.notifications.lowStockMedicineIds, ['medicine-1']);
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          4,
        );
      },
    );

    test(
      'low stock alert is skipped when app notifications are disabled',
      () async {
        final fixture = _ProviderFixture(
          notificationsEnabled: false,
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  dose: '1 compressa',
                  stockQuantity: 6,
                  stockWarningThreshold: 5,
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        await fixture.provider.markMedicineAsTaken(
          medicineId: 'medicine-1',
          scheduledDateTime: DateTime(2026, 7, 2, 8),
        );

        expect(fixture.notifications.lowStockMedicineIds, isEmpty);
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          5,
        );
      },
    );

    testWidgets(
      'settings screen shows notification permission and exact alarm status',
      (tester) async {
        final fixture = _ProviderFixture(
          therapies: const [],
          notifications: _FakeNotificationScheduler(
            permissionStatus: const NotificationPermissionStatus(
              localNotificationsSupported: true,
              notificationsAllowed: false,
              exactAlarmsAllowed: false,
              exactAlarmsCanBeChecked: true,
            ),
          ),
        );
        await fixture.provider.initialize();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: fixture.provider,
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        expect(find.text('Notifiche'), findsOneWidget);
        expect(find.text('Promemoria app'), findsOneWidget);
        expect(find.text('Permesso notifiche Android'), findsOneWidget);
        expect(find.text('Exact alarm'), findsNWidgets(2));
        expect(find.text('Non concesso'), findsOneWidget);
        expect(find.text('Non disponibile'), findsOneWidget);
        expect(
          find.textContaining('I promemoria potrebbero non arrivare'),
          findsOneWidget,
        );
        expect(
          find.textContaining('ottimizzata per la batteria'),
          findsOneWidget,
        );
      },
    );

    testWidgets('notification body tap opens the medicine detail screen', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: const MyApp(),
        ),
      );
      await tester.pump();

      NotificationNavigationEvents.instance.requestNavigation(
        const NotificationNavigationRequest(medicineId: 'medicine-1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dettaglio medicina'), findsOneWidget);
      expect(find.text('medicine-1'), findsWidgets);
      expect(
        find.byKey(const ValueKey('medicine-schedule-time-8-0')),
        findsOneWidget,
      );
    });

    testWidgets(
      'notification body tap with missing medicine keeps the dashboard stable',
      (tester) async {
        final fixture = _ProviderFixture(therapies: const []);
        await fixture.provider.initialize();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: fixture.provider,
            child: const MyApp(),
          ),
        );
        await tester.pump();

        NotificationNavigationEvents.instance.requestNavigation(
          const NotificationNavigationRequest(medicineId: 'missing-medicine'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dettaglio medicina'), findsNothing);
        expect(find.text('Nessuna terapia ancora'), findsOneWidget);
      },
    );

    testWidgets('dashboard next medicine card opens medicine detail', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [
              _medicine(
                id: 'medicine-1',
                therapyId: 'therapy-1',
                times: const [TimeOfDay(hour: 23, minute: 59)],
                daysOfWeek: [DateTime.now().weekday],
              ),
            ],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: const MyApp(),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('medicine-1').first);
      await tester.pumpAndSettle();

      expect(find.text('Dettaglio medicina'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('medicine-schedule-time-23-59')),
        findsOneWidget,
      );
    });

    testWidgets('medicine detail shows one chip for equivalent schedules', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [
              _medicine(
                id: 'medicine-1',
                therapyId: 'therapy-1',
                times: const [TimeOfDay(hour: 13, minute: 53)],
                daysOfWeek: const [DateTime.monday, DateTime.wednesday],
                schedules: const [
                  MedicineSchedule(
                    time: TimeOfDay(hour: 13, minute: 53),
                    daysOfWeek: [DateTime.monday],
                  ),
                  MedicineSchedule(
                    time: TimeOfDay(hour: 13, minute: 53),
                    daysOfWeek: [DateTime.wednesday],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: MaterialApp(
            home: MedicineDetailScreen(
              medicine: fixture.provider.getMedicineById('medicine-1')!,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('medicine-schedule-time-13-53')),
        findsOneWidget,
      );
      expect(find.text('Lun, Mer'), findsOneWidget);
    });

    testWidgets('medicine detail shows multiple different schedules once', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [
              _medicine(
                id: 'medicine-1',
                therapyId: 'therapy-1',
                times: const [
                  TimeOfDay(hour: 8, minute: 0),
                  TimeOfDay(hour: 20, minute: 30),
                ],
                daysOfWeek: const [DateTime.monday],
              ),
            ],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: MaterialApp(
            home: MedicineDetailScreen(
              medicine: fixture.provider.getMedicineById('medicine-1')!,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('medicine-schedule-time-8-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('medicine-schedule-time-20-30')),
        findsOneWidget,
      );
    });

    testWidgets('medicine detail edit updates medicine and keeps same id', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
          ),
        ],
      );
      await fixture.provider.initialize();
      fixture.notifications.clear();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: MaterialApp(
            home: MedicineDetailScreen(
              medicine: fixture.provider.getMedicineById('medicine-1')!,
            ),
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('medicine-detail-edit-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('medicine-detail-edit-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Modifica medicina'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('medicine-name-field')),
        'Aspirina aggiornata',
      );
      await tester.tap(find.text('1/2'));
      await tester.enterText(
        find.byKey(const ValueKey('medicine-stock-field')),
        '12.5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('medicine-warning-threshold-field')),
        '4',
      );
      await tester.ensureVisible(find.text('Salva modifiche'));
      await tester.tap(find.text('Salva modifiche'));
      await tester.pumpAndSettle();

      final updated = fixture.provider.getMedicineById('medicine-1')!;
      expect(updated.id, 'medicine-1');
      expect(updated.name, 'Aspirina aggiornata');
      expect(updated.dose, '1/2 compressa');
      expect(updated.stockQuantity, 12.5);
      expect(updated.stockWarningThreshold, 4);
      expect(fixture.notifications.cancelledMedicineIds, ['medicine-1']);
      expect(fixture.notifications.scheduledMedicineIds, ['medicine-1']);
      expect(find.text('Aspirina aggiornata'), findsOneWidget);
    });

    testWidgets('cancelling medicine edit does not change the medicine', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: MaterialApp(
            home: MedicineDetailScreen(
              medicine: fixture.provider.getMedicineById('medicine-1')!,
            ),
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('medicine-detail-edit-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('medicine-detail-edit-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('medicine-name-field')),
        'Nome da annullare',
      );
      await tester.ensureVisible(find.text('Annulla'));
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(
        fixture.provider.getMedicineById('medicine-1')!.name,
        'medicine-1',
      );
      expect(find.text('Nome da annullare'), findsNothing);
    });

    testWidgets('dashboard intake action buttons still update intake status', (
      tester,
    ) async {
      final fixture = _ProviderFixture(
        therapies: [
          _therapy(
            id: 'therapy-1',
            medicines: [
              _medicine(
                id: 'medicine-1',
                therapyId: 'therapy-1',
                times: const [TimeOfDay(hour: 23, minute: 59)],
                daysOfWeek: [DateTime.now().weekday],
              ),
            ],
          ),
        ],
      );
      await fixture.provider.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: fixture.provider,
          child: const MyApp(),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Assunta'), 300);
      await tester.tap(find.text('Assunta'));
      await tester.pumpAndSettle();

      expect(find.text('Dettaglio medicina'), findsNothing);
      expect(fixture.provider.intakeHistory.single.status, IntakeStatus.taken);
    });

    test(
      'external notification action reloads provider history and stock without restart',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  dose: '1/2 pastiglia',
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        final handler = NotificationActionHandler(
          intakeActionService: IntakeActionService(
            profileRepository: fixture.profileRepository,
            medicineRepository: fixture.medicineRepository,
            intakeRepository: fixture.intakeRepository,
            therapyRepository: fixture.therapyRepository,
          ),
        );

        final handled = await handler.handle(
          actionId: NotificationActionIds.taken,
          payload: NotificationService.payloadFor(
            medicineId: 'medicine-1',
            dayOfWeek: DateTime.monday,
            hour: 8,
            minute: 0,
          ),
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        );
        await _waitFor(
          () =>
              fixture.provider.intakeHistory.isNotEmpty &&
              fixture.provider.getMedicineById('medicine-1')?.stockQuantity ==
                  9.5,
        );

        expect(handled, isTrue);
        expect(fixture.provider.intakeHistory, hasLength(1));
        expect(
          fixture.provider.intakeHistory.single.status,
          IntakeStatus.taken,
        );
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          9.5,
        );
      },
    );
  });
}

class _ProviderFixture {
  _ProviderFixture({
    required List<Therapy> therapies,
    _FakeNotificationScheduler? notifications,
    bool notificationsEnabled = true,
  }) : notifications = notifications ?? _FakeNotificationScheduler(),
       profileRepository = _FakeProfileRepository(
         _profile(notificationsEnabled: notificationsEnabled),
       ),
       settingsRepository = _FakeSettingsRepository(
         _settings(notificationsEnabled: notificationsEnabled),
       ),
       therapyRepository = _FakeTherapyRepository(therapies),
       medicineRepository = _FakeMedicineRepository.fromTherapies(therapies),
       intakeRepository = _FakeIntakeRepository() {
    intakeRepository.onUpdateMedicine = (medicine) {
      medicineRepository.medicines[medicine.id] = medicine;
    };
    provider = MedicineProvider(
      profileRepository: profileRepository,
      settingsRepository: settingsRepository,
      therapyRepository: therapyRepository,
      medicineRepository: medicineRepository,
      intakeRepository: intakeRepository,
      notificationService: this.notifications,
    );
  }

  final _FakeProfileRepository profileRepository;
  final _FakeSettingsRepository settingsRepository;
  final _FakeTherapyRepository therapyRepository;
  final _FakeMedicineRepository medicineRepository;
  final _FakeIntakeRepository intakeRepository;
  final _FakeNotificationScheduler notifications;
  late final MedicineProvider provider;

  String get createdMedicineId => medicineRepository.medicines.keys.firstWhere(
    (id) => id != 'medicine-1' && id != 'medicine-2',
    orElse: () => medicineRepository.medicines.keys.last,
  );
}

class _FakeNotificationScheduler implements MedicineNotificationScheduler {
  _FakeNotificationScheduler({
    this.throwOnInitialize = false,
    this.throwOnSchedule = false,
    this.throwOnReschedule = false,
    NotificationPermissionStatus? permissionStatus,
    NotificationPermissionStatus? requestedNotificationStatus,
    NotificationPermissionStatus? requestedExactAlarmStatus,
  }) : permissionStatus =
           permissionStatus ?? const NotificationPermissionStatus.unknown(),
       requestedNotificationStatus =
           requestedNotificationStatus ??
           permissionStatus ??
           const NotificationPermissionStatus.unknown(),
       requestedExactAlarmStatus =
           requestedExactAlarmStatus ??
           permissionStatus ??
           const NotificationPermissionStatus.unknown();

  final bool throwOnInitialize;
  final bool throwOnSchedule;
  final bool throwOnReschedule;
  NotificationPermissionStatus permissionStatus;
  final NotificationPermissionStatus requestedNotificationStatus;
  final NotificationPermissionStatus requestedExactAlarmStatus;
  int initializeCount = 0;
  int cancelAllCount = 0;
  final scheduledMedicineIds = <String>[];
  final cancelledMedicineIds = <String>[];
  final rescheduledBatches = <List<String>>[];
  final rescheduledSlots = <List<String>>[];
  final scheduledSlots = <String>[];
  final lowStockMedicineIds = <String>[];

  @override
  Future<void> initialize() async {
    initializeCount++;
    if (throwOnInitialize) throw StateError('Notifications unavailable');
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async =>
      permissionStatus;

  @override
  Future<NotificationPermissionStatus> requestNotificationPermission() async {
    permissionStatus = requestedNotificationStatus;
    return permissionStatus;
  }

  @override
  Future<NotificationPermissionStatus> requestExactAlarmPermission() async {
    permissionStatus = requestedExactAlarmStatus;
    return permissionStatus;
  }

  @override
  Future<void> rescheduleActiveMedicines(Iterable<Medicine> medicines) async {
    if (throwOnReschedule) throw StateError('Permission denied');
    rescheduledBatches.add(
      medicines.map((medicine) => medicine.id).toList(growable: false),
    );
    rescheduledSlots.add(medicines.expand(_slotKeys).toList(growable: false));
  }

  @override
  Future<void> scheduleMedicineNotifications(Medicine medicine) async {
    if (throwOnSchedule) throw StateError('Permission denied');
    scheduledMedicineIds.add(medicine.id);
    scheduledSlots.addAll(_slotKeys(medicine));
  }

  @override
  Future<void> cancelMedicineNotifications(Medicine medicine) async {
    cancelledMedicineIds.add(medicine.id);
  }

  @override
  Future<void> showLowStockNotification(Medicine medicine) async {
    lowStockMedicineIds.add(medicine.id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCount++;
  }

  void clear() {
    cancelAllCount = 0;
    scheduledMedicineIds.clear();
    cancelledMedicineIds.clear();
    rescheduledBatches.clear();
    rescheduledSlots.clear();
    scheduledSlots.clear();
    lowStockMedicineIds.clear();
  }

  Iterable<String> _slotKeys(Medicine medicine) sync* {
    for (final schedule in medicine.schedules) {
      for (final dayOfWeek in schedule.daysOfWeek.toSet()) {
        yield '${medicine.id}|$dayOfWeek|${schedule.time.hour}|${schedule.time.minute}';
      }
    }
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;

  @override
  Future<void> createProfile(UserProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async => profile;

  @override
  Future<UserProfile?> getProfileById(String profileId) async =>
      profile.id == profileId ? profile : null;

  @override
  Future<bool> updateProfile(UserProfile profile) async {
    this.profile = profile;
    return true;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  AppSettings settings;

  @override
  Future<AppSettings?> getSettingsForProfile(String profileId) async =>
      settings.profileId == profileId ? settings : null;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    this.settings = settings;
  }
}

class _FakeTherapyRepository implements TherapyRepository {
  _FakeTherapyRepository(List<Therapy> therapies)
    : therapies = {
        for (final therapy in therapies)
          therapy.id: therapy.copyWith(medicines: const []),
      };

  final Map<String, Therapy> therapies;

  @override
  Future<void> createTherapy(Therapy therapy) async {
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
  }

  @override
  Future<void> createTherapyWithMedicine(
    Therapy therapy,
    Medicine medicine,
  ) async {
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
  }

  @override
  Future<void> deleteTherapy(String therapyId) async {
    therapies.remove(therapyId);
  }

  @override
  Future<List<Therapy>> getTherapies(String profileId) async =>
      therapies.values.toList(growable: false);

  @override
  Future<bool> updateTherapy(Therapy therapy) async {
    if (!therapies.containsKey(therapy.id)) return false;
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
    return true;
  }

  @override
  Stream<List<Therapy>> watchTherapies(String profileId) =>
      Stream.value(therapies.values.toList(growable: false));
}

class _FakeMedicineRepository implements MedicineRepository {
  _FakeMedicineRepository.fromTherapies(List<Therapy> therapies)
    : medicines = {
        for (final therapy in therapies)
          for (final medicine in therapy.medicines) medicine.id: medicine,
      };

  final Map<String, Medicine> medicines;

  @override
  Future<void> createMedicine(Medicine medicine) async {
    medicines[medicine.id] = medicine;
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    medicines.remove(medicineId);
  }

  @override
  Future<List<Medicine>> getLowStockMedicines(String profileId) async =>
      (await getMedicines(profileId))
          .where(
            (medicine) =>
                medicine.stockQuantity <= medicine.stockWarningThreshold,
          )
          .toList(growable: false);

  @override
  Future<List<Medicine>> getMedicines(String profileId) async => medicines
      .values
      .where((medicine) => medicine.profileId == profileId)
      .toList(growable: false);

  @override
  Future<List<Medicine>> getMedicinesByTherapy(String therapyId) async =>
      medicines.values
          .where((medicine) => medicine.therapyId == therapyId)
          .toList(growable: false);

  @override
  Future<List<MedicineSchedule>> getSchedulesForMedicine(
    String medicineId,
  ) async => medicines[medicineId]?.schedules ?? const [];

  @override
  Future<void> replaceSchedules(
    String medicineId,
    List<MedicineSchedule> schedules,
  ) async {
    final medicine = medicines[medicineId];
    if (medicine != null) {
      medicines[medicineId] = medicine.copyWith(schedules: schedules);
    }
  }

  @override
  Future<bool> updateMedicine(Medicine medicine) async {
    if (!medicines.containsKey(medicine.id)) return false;
    medicines[medicine.id] = medicine;
    return true;
  }

  @override
  Stream<List<Medicine>> watchMedicines(String profileId) =>
      Stream.value(medicines.values.toList(growable: false));
}

class _FakeIntakeRepository implements IntakeRepository {
  final records = <IntakeRecord>[];
  void Function(Medicine medicine)? onUpdateMedicine;

  @override
  Future<void> createIntakeRecord(IntakeRecord record) async {
    records.add(record);
  }

  @override
  Future<void> createIntakeRecords(List<IntakeRecord> records) async {
    this.records.addAll(records);
  }

  @override
  Future<IntakeRecord?> getIntakeRecordForSchedule({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async => records
      .where(
        (record) =>
            record.medicineId == medicineId &&
            record.scheduledDateTime == scheduledDateTime,
      )
      .firstOrNull;

  @override
  Future<List<IntakeRecord>> getIntakeRecords(String profileId) async => records
      .where((record) => record.profileId == profileId)
      .toList(growable: false);

  @override
  Future<List<IntakeRecord>> getIntakeRecordsByMedicine(
    String medicineId,
  ) async => records
      .where((record) => record.medicineId == medicineId)
      .toList(growable: false);

  @override
  Future<void> saveIntakeRecordWithStock({
    required IntakeRecord record,
    required bool updateExistingRecord,
    Medicine? updatedMedicine,
  }) async {
    if (updatedMedicine != null) {
      onUpdateMedicine?.call(updatedMedicine);
    }
    if (updateExistingRecord) {
      final index = records.indexWhere((item) => item.id == record.id);
      if (index == -1) throw StateError('Record not found');
      records[index] = record;
    } else {
      records.add(record);
    }
  }

  @override
  Future<bool> updateIntakeRecord(IntakeRecord record) async {
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) return false;
    records[index] = record;
    return true;
  }
}

Therapy _therapy({
  required String id,
  List<Medicine> medicines = const [],
  bool isActive = true,
}) {
  final now = DateTime.now();
  return Therapy(
    id: id,
    profileId: 'profile-1',
    name: id,
    color: '#2E7D32',
    isActive: isActive,
    medicines: medicines,
    createdAt: now,
    updatedAt: now,
  );
}

Medicine _medicine({
  required String id,
  required String therapyId,
  String dose = '1 compressa',
  String? name,
  bool isActive = true,
  double stockQuantity = 10,
  double stockWarningThreshold = 2,
  List<TimeOfDay> times = const [TimeOfDay(hour: 8, minute: 0)],
  List<int> daysOfWeek = const [DateTime.monday],
  List<MedicineSchedule>? schedules,
}) {
  final now = DateTime.now();
  return Medicine(
    id: id,
    profileId: 'profile-1',
    therapyId: therapyId,
    name: name ?? id,
    dose: dose,
    times: times,
    daysOfWeek: daysOfWeek,
    schedules: schedules,
    stockQuantity: stockQuantity,
    stockWarningThreshold: stockWarningThreshold,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

List<MedicineSchedule> _advancedSchedules() {
  return const [
    MedicineSchedule(
      time: TimeOfDay(hour: 15, minute: 30),
      daysOfWeek: [DateTime.monday, DateTime.saturday],
    ),
    MedicineSchedule(
      time: TimeOfDay(hour: 15, minute: 35),
      daysOfWeek: [DateTime.monday, DateTime.saturday],
    ),
    MedicineSchedule(
      time: TimeOfDay(hour: 14, minute: 30),
      daysOfWeek: [DateTime.tuesday, DateTime.sunday],
    ),
    MedicineSchedule(
      time: TimeOfDay(hour: 16, minute: 35),
      daysOfWeek: [DateTime.tuesday, DateTime.sunday],
    ),
  ];
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Condition not reached before timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

UserProfile _profile({required bool notificationsEnabled}) {
  final now = DateTime.now();
  return UserProfile(
    id: 'profile-1',
    name: 'Utente',
    notificationsEnabled: notificationsEnabled,
    createdAt: now,
    updatedAt: now,
  );
}

AppSettings _settings({required bool notificationsEnabled}) {
  final now = DateTime.now();
  return AppSettings(
    id: 'profile-1-settings',
    profileId: 'profile-1',
    themeMode: 'light',
    notificationsEnabled: notificationsEnabled,
    createdAt: now,
    updatedAt: now,
  );
}
