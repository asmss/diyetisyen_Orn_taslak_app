import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/diet_plan_provider.dart';
import 'diet_plan_detail_screen.dart';
import '../../../../core/services/firebase/firestore_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final TextEditingController _weightController = TextEditingController();
  bool _isSavingWeight = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveDailyWeight() async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;

    final weightStr = _weightController.text.trim().replaceAll(',', '.');
    final weightDouble = double.tryParse(weightStr);

    if (weightDouble == null || weightDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir kilo giriniz.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingWeight = true);

    try {
      await context.read<FirestoreService>().logDailyWeight(
            userId: profile.id,
            weightKg: weightDouble,
          );
      _weightController.clear();
      FocusScope.of(context).unfocus(); // Klavyeyi kapat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlük kilo kaydınız başarıyla eklendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingWeight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DietPlanProvider>();
    final plans = provider.plans; // Artık tüm planları alıyoruz

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Diyet Planlarım')),
      body: Column(
        children: [
          // ÜST KISIM: Diyet Planları Listesi
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Henüz sana atanmış bir diyet planı yok. Admin panelinden plan yazıldığında burada görünecek.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      // İlk plan (en güncel olan) için farklı bir vurgu yapabiliriz
                      final isActive = index == 0; 

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isActive ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Tıklanınca detay sayfasına git
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DietPlanDetailScreen(plan: plan),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plan.title,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Aktif Plan',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${DateFormatter.shortDay.format(plan.startDate)} - ${DateFormatter.shortDay.format(plan.endDate)}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Diyetisyen: ${plan.dietitianName}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // ALT KISIM: Günlük Kilo Kaydı Alanı
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Günlük Kilo Takibi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Örn: 72.5',
                            suffixText: 'kg',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSavingWeight ? null : _saveDailyWeight,
                          icon: _isSavingWeight 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.monitor_weight),
                          label: const Text('Kaydet'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}