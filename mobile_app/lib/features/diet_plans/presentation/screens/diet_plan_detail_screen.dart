import 'package:flutter/material.dart';

import '../../../../core/models/diet_plan_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/section_header.dart';

class DietPlanDetailScreen extends StatelessWidget {
  final DietPlanModel plan;

  const DietPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diyet Planı Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(
            title: plan.title,
            subtitle: '${DateFormatter.shortDay.format(plan.startDate)} - ${DateFormatter.shortDay.format(plan.endDate)}',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Diyetisyen: ${plan.dietitianName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Günlük su hedefi: ${plan.waterTargetLiters} L', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (plan.notes.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Notlar:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(plan.notes, style: const TextStyle(height: 1.4)),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Öğünler',
            subtitle: 'Saatlerine uymaya özen gösterin.',
          ),
          const SizedBox(height: 12),
          ...plan.meals.map(
            (meal) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    meal.timeLabel.length >= 2
                        ? meal.timeLabel.substring(0, 2)
                        : meal.timeLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(meal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${meal.timeLabel} • ${meal.description}',
                    style: const TextStyle(height: 1.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}