# Hallederiz | Smart Daily Planner & Routine Tracker 🚀

Hallederiz, kullanıcıların günlük görevlerini, alışkanlıklarını ve tekrarlayan rutinlerini pürüzsüz (seamless) bir kullanıcı deneyimi ile yönetmelerini sağlayan, modern ve minimalist bir iOS uygulamasıdır. Tamamen **SwiftUI** kullanılarak native olarak geliştirilmiş olup, zengin animasyonlar, akıllı durum yönetimi (state management) ve performanslı bir veri senkronizasyonu sunar.

## 🌟 Öne Çıkan Özellikler

### 🧠 Akıllı Rutin Motoru (Smart Routine Engine)
* **Dinamik Zamanlama:** Kullanıcılar tarafından oluşturulan rutinler (örn. Spor, Kitap Okuma) belirlenen spesifik günlere (Pzt, Çar vb.) otomatik olarak enjekte edilir.
* **Geçmiş Veri Koruması:** Algoritma, cihazın yerel saatini baz alarak geçmiş günlerin verilerini (immutable) korur ve otomatik rutin eklemelerini yalnızca mevcut ve gelecek tarihler için tetikler.
* **Bağımsız Senkronizasyon:** Rutin şablonunda yapılan herhangi bir `update` veya `delete` işlemi, ana takvimdeki aktif görevlerle saniyesinde (real-time) senkronize olur.

### 🎨 İleri Düzey UI / UX Tasarımı
* **Pixel-Perfect Arayüz:** Apple Human Interface Guidelines'a (HIG) tam uyumlu, yumuşatılmış köşeler, hiyerarşik gölgelendirmeler ve custom (özel) bileşenler.
* **Dinamik Renk Ataması:** Her bir rutinin benzersiz `UUID` değeri, matematiksel bir hashing fonksiyonu ile işlenerek rutine kalıcı bir pastel renk (Lilac, Peach, Mint vb.) atanmasını sağlar.
* **Haptik Geri Bildirimler:** Uygulama içindeki swipe, toggle ve buton aksiyonları `UIImpactFeedbackGenerator` ile desteklenerek fiziksel bir dokunma hissiyatı yaratır.

### 🏆 Oyunlaştırma (Gamification) & Veri Analizi
* Günlük bazda hesaplanan dinamik ilerleme çubukları (Progress Bars) ve alt rutin takip göstergeleri.
* Başarıyla tamamlanan günlerde asenkron olarak tetiklenen interaktif konfeti animasyonları.
* Kullanıcının geçmiş verileri işlenerek (Weekly, Monthly, Yearly) oluşturulan kişisel istatistikler ve kategori bazlı otomatik rozet (Badge) atama sistemi.

### 🔍 Türkçe NLP Destekli İkon Motoru
* Apple'ın `SF Symbols` kütüphanesi üzerine inşa edilmiş, Türkçe anahtar kelimelerle (örn: "kahve", "spor", "yazılım") anında lokal filtreleme yapabilen akıllı çıkartma arama entegrasyonu.

---

## 🛠 Teknik Altyapı & Mimari

* **UI Framework:** SwiftUI (iOS 15.0+)
* **Architecture:** Component-driven mimari ve modüler View yapıları.
* **Data Persistence:** 
  * `Codable` protokolü ile modellenmiş veri yapılarının `JSONEncoder/JSONDecoder` kullanılarak `UserDefaults` üzerinde asenkron ve güvenli saklanması.
  * Profil verileri için `@AppStorage` entegrasyonu.
* **Concurrency & Memory Management:** 
  * `DispatchQueue.main.asyncAfter` ile yönetilen thread optimizasyonları ve animasyon gecikmeleri.
  * Gereksiz render işlemlerini önleyen `@State` ve `@Binding` yaşam döngüsü (lifecycle) yönetimi.
* **Media & Notifications:**
  * `PhotosUI` ve `Transferable` protokolü ile asenkron profil fotoğrafı yükleme.
  * `UserNotifications` ile göreve özel, yerel (local) anımsatıcı zamanlaması (`UNCalendarNotificationTrigger`).

---

## 🚀 Kurulum & Çalıştırma

Projeyi lokal ortamınızda derlemek için aşağıdaki adımları izleyebilirsiniz:

1. Repoyu klonlayın:
   ```bash
   git clone [https://github.com/zeynepozgetemel/Hallederiz-App.git](https://github.com/zeynepozgetemel/Hallederiz-App.git)

2. Proje dizinine gidin ve Xcode ile açın:
   ```bash
   cd Hallederiz-App
   open Hallederiz.xcodeproj
   ```

3. Target olarak bir iOS Simülatörü veya fiziksel cihaz seçerek projeyi çalıştırın (`Cmd + R`).

---

## 👩‍💻 Geliştirici

**Zeynep Özge Temel**  
Computer Engineering Student | iOS Developer  
[GitHub Profilim](https://github.com/zeynepozgetemel)
