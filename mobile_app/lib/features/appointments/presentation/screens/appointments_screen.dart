import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/appointment_provider.dart';
import '../../../../core/models/appointment_model.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    void _showTimeSlotsBottomSheet(BuildContext context, DateTime selectedDate) {
      final List<String> availableTimeSlots = [
        "09:00", "10:00", "11:30", "13:00", "14:30", "16:00",
      ];

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormatter.full.format(selectedDate)} için Saat Seçin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableTimeSlots.map((time) {
                    return ActionChip(
                      label: Text(time),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      onPressed: () async {
                        if (profile == null) return;

                        final parts = time.split(':');
                        final appointmentDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          int.parse(parts[0]),
                          int.parse(parts[1]),
                        );

                        await context.read<AppointmentProvider>().createAppointment(
                          date: appointmentDateTime,
                          profile: profile,
                        );

                        if (context.mounted) {
                          Navigator.pop(bottomSheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Randevu talebiniz başarıyla oluşturuldu! Admin onayı bekleniyor.'),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Takvimi')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: CalendarDatePicker(
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    onDateChanged: (DateTime date) {
                      _showTimeSlotsBottomSheet(context, date);
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator.adaptive(
                    color: Theme.of(context).colorScheme.primary,
                    onRefresh: () async {
                      await context.read<AppointmentProvider>().refreshData();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(), 
                      children: [
                        const SectionHeader(
                          title: 'Randevularım',
                          subtitle: 'Aldığın randevular ve taleplerin burada listelenir.',
                        ),
                        const SizedBox(height: 18),
                        if (provider.allAppointments.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'Henüz randevu bulunmuyor. Yukarıdaki takvimden bir gün seçerek talep oluşturabilirsin.',
                              ),
                            ),
                          ),
                        ...provider.allAppointments.map((appointment) {
                          
                          // DÜZELTME: Statü renkleri ve metinleri daha net hale getirildi
                          Color statusColor;
                          String statusText;

                          switch (appointment.status) {
                            case AppointmentStatus.pending:
                              statusColor = Colors.orange;
                              statusText = 'Onay Bekliyor';
                              break;
                            case AppointmentStatus.upcoming:
                              statusColor = Colors.green;
                              statusText = 'Onaylandı';
                              break;
                            case AppointmentStatus.completed:
                              statusColor = Theme.of(context).colorScheme.primary;
                              statusText = 'Tamamlandı';
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusText = 'Bilinmiyor';
                          }

                          final canBeDeleted = appointment.status == AppointmentStatus.pending || 
                                               appointment.status == AppointmentStatus.upcoming;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appointment.title,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  if (canBeDeleted)
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          final isDeleted = await context.read<AppointmentProvider>().deleteAppointment(appointment.id);
                                          
                                          if (context.mounted) {
                                            if (isDeleted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Randevu tamamen silindi.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Silme başarısız! (Veritabanı veya ID hatası)'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text(
                                            'İptal Et ve Sil',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(DateFormatter.full.format(appointment.dateTime)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${DateFormatter.hourMinute.format(appointment.dateTime)} - ${DateFormatter.hourMinute.format(appointment.endTime)}',
                                  ),
                                  const SizedBox(height: 10),
                                  Text(appointment.notes),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}