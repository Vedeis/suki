import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool access = false;
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final value = await NotificationService.hasAccess();
    if (mounted) setState(() => access = value);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengaturan')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('DETEKSI OTOMATIS', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Card(child: SwitchListTile(
        value: access, activeColor: const Color(0xFF39D6A3),
        title: const Text('Akses notifikasi'),
        subtitle: Text(access ? 'Izin telah diberikan di Android.' : 'Buka pengaturan akses notifikasi Android.'),
        onChanged: (_) async { await NotificationService.openSettings(); await Future.delayed(const Duration(milliseconds: 500)); _check(); },
      )),
      const SizedBox(height: 14),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Privasi & keamanan', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('MONEYFLOW memproses notifikasi secara lokal di perangkat. Aplikasi ini tidak meminta PIN, password, atau akses login m-banking. Data transaksi disimpan di database lokal.', style: TextStyle(color: Colors.white60, height: 1.5, fontSize: 12)),
      ]))),
      const SizedBox(height: 14),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Catatan deteksi', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Format notifikasi tiap bank berbeda. Deteksi memakai pola teks umum sehingga tidak semua transaksi pasti terbaca dan hasilnya perlu diperiksa. Beberapa aplikasi tidak menampilkan nominal lengkap pada notifikasi.', style: TextStyle(color: Colors.white60, height: 1.5, fontSize: 12)),
      ]))),
    ]),
  );
}
