<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>IoT Controller - Smart Home Dashboard</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; max-width: 800px; margin: auto; background-color: #f9f9f9;">

  <h1>📡 IoT Controller - Smart Home Dashboard</h1>

  <p>Aplikasi <strong>IoT Controller</strong> adalah dashboard Flutter untuk memantau dan mengontrol perangkat IoT secara real-time menggunakan protokol <strong>MQTT</strong>. Fitur utama mencakup koneksi broker, status perangkat, kontrol LED, dan visualisasi data sensor suhu serta kelembaban.</p>

  <hr>

  <h2>🚀 Fitur Utama</h2>
  <ul>
    <li>🔗 <strong>MQTT Connection</strong>: Input broker IP, username, dan password. Tombol Connect / Disconnect serta status koneksi.</li>
    <li>📶 <strong>Device Status</strong>: Indikator ONLINE dan status LED (ON/OFF).</li>
    <li>🌡️ <strong>Sensor Data</strong>: Tampilan suhu dalam °C dan kelembaban dalam %.</li>
  </ul>

  <hr>

  <h2>📱 Tampilan Antarmuka</h2>
  <p>Tampilan clean dan interaktif seperti di bawah ini:</p>
  <img src="./assets/screenshots/full_dashboard.png" alt="Tampilan UI" style="max-width: 100%; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">

  <hr>

  <h2>⚙️ Teknologi</h2>
  <ul>
    <li><a href="https://flutter.dev/" target="_blank">Flutter</a> - UI Framework</li>
    <li><a href="https://pub.dev/packages/mqtt_client" target="_blank">mqtt_client</a> - Library MQTT</li>
    <li><a href="https://pub.dev/packages/provider" target="_blank">provider</a> - State Management</li>
    <li><a href="https://pub.dev/packages/flutter_svg" target="_blank">flutter_svg</a> - Icon SVG</li>
    <li><a href="https://pub.dev/packages/http" target="_blank">http</a> - (Opsional) untuk REST API</li>
  </ul>

  <hr>

  <h2>🛠️ Cara Menjalankan</h2>
  <ol>
    <li>Clone project:
      <pre><code>git clone https://github.com/Iniwizzy/monitoring_app.git
cd monitoring_app</code></pre>
    </li>
    <li>Install dependencies:
      <pre><code>flutter pub get</code></pre>
    </li>
    <li>Jalankan aplikasi:
      <pre><code>flutter run</code></pre>
    </li>
  </ol>

  <blockquote>Pastikan broker MQTT sudah tersedia dan ESP atau perangkat IoT sudah terhubung ke broker tersebut.</blockquote>

  <hr>

  <h2>🔐 Konfigurasi MQTT</h2>
  <p>Sesuaikan konfigurasi MQTT di form aplikasi atau langsung pada file konfigurasi:</p>
  <pre><code>String Broker = "192.168.1.24";
String Username = "badawi";
String Password = "********";</code></pre>

  <hr>

  <h2>📡 Contoh Topik MQTT</h2>
  <ul>
    <li><code>/status/online</code> → <code>online</code></li>
    <li><code>/device/led</code> → <code>on/off</code></li>
    <li><code>/sensor/temperature</code> → <code>48.0</code></li>
    <li><code>/sensor/humidity</code> → <code>68.0</code></li>
  </ul>

  <hr>

  <h2>✨ Kontribusi</h2>
  <p>Silakan fork, kembangkan, atau ajukan pull request untuk menambahkan fitur atau perbaikan.</p>

  <hr>

  <h2>📝 Lisensi</h2>
  <p>Proyek ini menggunakan lisensi <strong>MIT</strong>. Lihat file <code>LICENSE</code> untuk detail lebih lanjut.</p>

</body>
</html>
