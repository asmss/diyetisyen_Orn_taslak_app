# Diyetisyen Randevu Demo

Bu calisma alani iki klasore ayrildi:

- `mobile_app`: Flutter ile yazilan musteri uygulamasi
- `admin_panel`: React tabanli diyetisyen admin paneli

Su an Firebase gercek baglantisi bilerek eklenmedi. Bir sonraki adimda birlikte:
Firebase baglantisi artik yapildi. Su yapilar aktif:

1. Flutter Auth: Email/Password ile kayit ve giris
2. `users`: profil, kilo, boy, hedef
3. `appointments`: musteri randevu kayitlari
4. `dietPlans`: diyetisyen tarafindan yazilan planlar

Notlar:

- Admin panel mobil uygulamaya canli veri yazar.
- Firestore kurallari artik musteri/admin ayrimi ile sinirlandi: [firestore.rules](/Users/asimkarabulut/Documents/diyetsiyenRandevu/firestore.rules)
- Admin paneline girecek kullanici once Firebase Authentication'da olusmali.
- Ardindan Firestore'da `admins` koleksiyonunda kullanicinin `uid` degeriyle bir dokuman olusturulmali.
- Ornek `admins/{uid}` dokumani:
  `email`, `fullName`, `role: "admin"`
- Bu admin dokumanini Firebase Console'dan manuel ekleyebilirsin.
