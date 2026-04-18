import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../diet_plans/presentation/providers/diet_plan_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/navigation_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final dietPlanProvider = context.watch<DietPlanProvider>();
    final profile = profileProvider.profile;
    final nextAppointment = appointmentProvider.upcomingAppointments.isNotEmpty
        ? appointmentProvider.upcomingAppointments.first
        : null;
    final activePlan = dietPlanProvider.activePlan;
    final theme = Theme.of(context);

    if (profileProvider.isLoading || appointmentProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil bilgisi henuz hazir degil.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F5C4E), Color(0xFF4E907B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${profile.fullName.split(' ').first}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nextAppointment != null
                        ? 'Bugun rutininin merkezinde iyi hissetmek var. Siradaki kontrolun ${DateFormatter.full.format(nextAppointment.dateTime)}.'
                        : 'Bugun icin kayitli bir randevun yok. Takvimden yeni talep olusturabilirsin.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatBadge(label: 'Boy', value: '${profile.heightCm} cm'),
                      _StatBadge(
                        label: 'Kilo',
                        value: '${profile.weightKg.toStringAsFixed(1)} kg',
                      ),
                      _StatBadge(label: 'Hedef', value: profile.goal),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Hizli gecisler',
              subtitle: 'Ana sayfadan diger sayfalara kartlarla ulas.',
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              childAspectRatio: 0.92,
              children: [
                NavigationCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Randevular',
                  subtitle: 'Takvim ve saat kayitlari',
                  accentColor: const Color(0xFFE7886D),
                  onTap: () => onNavigate(1),
                ),
                NavigationCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Diyetim',
                  subtitle: 'Yazilan gunluk plan',
                  accentColor: const Color(0xFF8BBF76),
                  onTap: () => onNavigate(2),
                ),
                NavigationCard(
                  icon: Icons.person_rounded,
                  title: 'Profil',
                  subtitle: 'Boy, kilo ve hedefler',
                  accentColor: const Color(0xFF79B6D8),
                  onTap: () => onNavigate(3),
                ),
                NavigationCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Diyetisyen',
                  subtitle: AppConstants.dietitianName,
                  accentColor: const Color(0xFFC7A36A),
                  onTap: () => onNavigate(2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktif plan', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(activePlan?.title ?? 'Henuz aktif diyet plani yok'),
                    const SizedBox(height: 6),
                    Text(
                      activePlan?.notes ??
                          'Admin panelinden ilk diyet plani tanimlandiginda burada gorunecek.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
