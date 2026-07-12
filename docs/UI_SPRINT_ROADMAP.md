# Roadmap Full UI Redesign — Medora "Calm Precision"

Ordine adottato: quello proposto dall'utente, con la navbar in Sprint 2 (subito dopo i token, prima della Dashboard, perché la Dashboard dipende visivamente dalla navbar). Dettaglio Medicina separato dal Form (Sprint 6 dopo Sprint 5) per poter unificare prima la logica di raggruppamento schedule nel form e poi riapplicarla al dettaglio senza duplicarla due volte.

| Sprint | Obiettivo | File probabili | Non toccare | Rischio | Output atteso |
|---|---|---|---|---|---|
| **0** | Direzione UI + documentazione handoff | `docs/UI_*.md` | tutto il codice app | nessuno | questo set di documenti (fatto) |
| **1** ✅ | Design tokens + componenti base | `lib/theme/app_colors.dart`, `app_dimens.dart`, `responsive.dart`; `lib/utils/color_parser.dart`, `weekday_labels.dart`; `lib/widgets/app_card.dart`, `status_chip.dart`; restyle `primary_button.dart`, `empty_state.dart`, `app.dart` | provider, repository, services, data | basso | fatto — `flutter analyze`/`test`/`build apk --debug` verdi |
| **2** ✅ | App shell + nuova bottom navbar | `lib/widgets/app_bottom_nav_bar.dart`, `quick_action_sheet.dart`, `dashboard_screen.dart` (shell + quick actions) | logica tab index, Provider | basso (Opzione A, no CustomClipper) | fatto — navbar pill + `+` con quick sheet, `flutter analyze`/`test`/`build apk --debug` verdi |
| **3** | Nuova Dashboard | `dashboard_screen.dart` | `MedicineProvider`, calcolo next-intake | medio (schermata più vista) | Dashboard riprogettata, riuso componenti |
| **4** | Terapie e Dettaglio Terapia | `medicines_screen.dart`, `therapy_detail_screen.dart` | azioni archivia/elimina/cambio terapia | medio | liste/dettaglio coerenti, riuso card medicina |
| **5** | Form Medicina | `add_medicine_screen.dart` | validazione/salvataggio verso Provider | medio-alto (file più complesso) | form sezionato, estrazione logica raggruppamento schedule in helper condiviso |
| **6** | Dettaglio Medicina | `medicine_detail_screen.dart` | azioni edit/cambio terapia/elimina | medio | riuso helper schedule dello Sprint 5, fix box larghezza fissa 132px |
| **7** | Storico e Statistiche | `history_screen.dart`, `statistics_screen.dart` | `HistoryFilterService`, `HistoryStatisticsService`, formula aderenza | medio (CustomPainter del grafico) | filtri a sheet, statistiche più visive, grafico restilizzato |
| **8** | Scorte, Impostazioni, Profilo | `stock_screen.dart`, `settings_screen.dart`, `profile_screen.dart` | `NotificationService`, stato permessi reale | basso | fix onestà UI Backup/PDF, fix `SizedBox(width:116)`, riuso componenti |
| **9** | Responsive QA Samsung Z Flip | trasversale | nessuna logica | basso | verifica sistematica 280-344px, touch target, tastiera aperta |

## Regole di esecuzione
- Uno sprint = una PR/commit tematico, mai tutto insieme.
- Dopo ogni sprint: `flutter analyze` + `flutter test` prima di passare al successivo.
- Sprint 2 (navbar) e Sprint 5-6 (schedule) richiedono test manuale su emulatore/dispositivo oltre ai test automatici.
- Qualsiasi modifica che tocchi Provider/repository/servizi durante uno sprint UI va segnalata esplicitamente come rischio prima di procedere, non applicata silenziosamente.
