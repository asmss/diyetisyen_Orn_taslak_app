import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../../core/models/profile_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    if (profileProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profil bilgisi bulunamadı.')),
      );
    }

    // BMI Durumunu Hesapla
    String bmiStatus;
    Color bmiColor;
    if (profile.bodyMassIndex < 18.5) {
      bmiStatus = 'Zayıf';
      bmiColor = Colors.blue;
    } else if (profile.bodyMassIndex < 25) {
      bmiStatus = 'Normal';
      bmiColor = Colors.green;
    } else if (profile.bodyMassIndex < 30) {
      bmiStatus = 'Fazla Kilolu';
      bmiColor = Colors.orange;
    } else {
      bmiStatus = 'Obez';
      bmiColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- PROFİL BAŞLIĞI ---
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // --- HIZLI İSTATİSTİKLER ---
            Row(
              children: [
                Expanded(child: _StatBox(title: 'Yaş', value: '${profile.age}', icon: Icons.cake)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(title: 'Boy', value: '${profile.heightCm} cm', icon: Icons.height)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(title: 'Kilo', value: '${profile.weightKg} kg', icon: Icons.monitor_weight)),
              ],
            ),
            const SizedBox(height: 16),

            // --- BMI VE HEDEF KARTLARI ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bmiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bmiColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, size: 18, color: bmiColor),
                            const SizedBox(width: 6),
                            Text('BMI', style: TextStyle(color: bmiColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.bodyMassIndex.toStringAsFixed(1),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: bmiColor),
                        ),
                        Text(bmiStatus, style: TextStyle(color: bmiColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text('Hedef', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.goal,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- KİLO GEÇMİŞİ (Önceki adımdaki model yapısını kullanıyoruz) ---
            if (profile.weightHistory.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Son Kilo Kayıtları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                // Sadece son 3 kaydı gösterelim ki liste çok uzamasın (ters çevirip en yeniyi üste alıyoruz)
                child: Column(
                  children: profile.weightHistory.reversed.take(5).map((log) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.trending_down, size: 18, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text('${log.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        DateFormatter.shortDay.format(log.date),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- BUTONLAR ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileBottomSheet(context, profile),
                icon: const Icon(Icons.edit),
                label: const Text('Profili Düzenle', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- PROFİL DÜZENLEME MODALI ---
  void _showEditProfileBottomSheet(BuildContext context, ProfileModel profile) {
    // Controller'ları mevcut bilgilerle dolduruyoruz
    final nameController = TextEditingController(text: profile.fullName);
    final ageController = TextEditingController(text: profile.age.toString());
    final heightController = TextEditingController(text: profile.heightCm.toString());
    final goalController = TextEditingController(text: profile.goal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin altından çıkması için
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom, // Klavye boşluğu
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profili Düzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Yaş', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Boy (cm)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goalController,
                decoration: InputDecoration(labelText: 'Hedefiniz', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // YENİ PROFİL BİLGİLERİNİ GÜNCELLEME İŞLEMİ
                    // Profil sağlayıcında updateProfile adında bir fonksiyonun olduğunu veya
                    // FirestoreService üzerinden createOrUpdateUserProfile'ı çağırabileceğini varsayıyoruz.
                    /* final updatedProfile = profile.copyWith(
                       fullName: nameController.text,
                       age: int.tryParse(ageController.text) ?? profile.age,
                       heightCm: int.tryParse(heightController.text) ?? profile.heightCm,
                       goal: goalController.text,
                     );
                     context.read<FirestoreService>().createOrUpdateUserProfile(updatedProfile);
                    */

                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil güncelleme işlemi backend tarafına bağlanmalı.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Kaydet'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// --- MİNİ İSTATİSTİK KUTUSU WIDGET'I ---
class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}