import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_parser.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MoneyTransaction> transactions = [];
  bool notificationAccess = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final access = await NotificationService.hasAccess();
    final pending = await NotificationService.pending();
    for (final item in pending) {
      if (item is! Map) continue;
      final pkg = item['package']?.toString() ?? '';
      final body = item['text']?.toString() ?? '';
      final parsed = TransactionParser.parse(pkg, body);
      if (parsed == null) continue;
      final when = DateTime.tryParse(item['time']?.toString() ?? '') ?? DateTime.now();
      if (await DatabaseService.instance.existsSimilar(body, when)) continue;
      await DatabaseService.instance.insert(MoneyTransaction(
        title: parsed.title, category: parsed.category, amount: parsed.amount,
        type: parsed.type, source: parsed.source, rawText: body, createdAt: when,
      ));
    }
    await NotificationService.clearPending();
    final rows = await DatabaseService.instance.all();
    if (!mounted) return;
    setState(() { notificationAccess = access; transactions = rows; loading = false; });
  }

  int get income => transactions.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
  int get expense => transactions.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
  List<MoneyTransaction> get thisMonth {
    final now = DateTime.now();
    return transactions.where((t) => t.createdAt.year == now.year && t.createdAt.month == now.month).toList();
  }
  int get monthExpense => thisMonth.where((t) => t.type == 'expense').fold(0, (s,t) => s+t.amount);
  int get monthIncome => thisMonth.where((t) => t.type == 'income').fold(0, (s,t) => s+t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF39D6A3)),
          SizedBox(width: 9),
          Text('MONEYFLOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        ]),
        actions: [IconButton(onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          _refresh();
        }, icon: const Icon(Icons.settings_outlined))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          _refresh();
        },
        backgroundColor: const Color(0xFF39D6A3),
        foregroundColor: const Color(0xFF07110E),
        icon: const Icon(Icons.add), label: const Text('Catat transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            _balanceCard(),
            const SizedBox(height: 14),
            if (!notificationAccess) _permissionCard(),
            _monthSummary(),
            const SizedBox(height: 18),
            _spendingCard(),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Transaksi terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${transactions.length} transaksi', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('Belum ada transaksi. Tambahkan transaksi atau aktifkan deteksi notifikasi.'))))
            else ...transactions.take(8).map(_transactionTile),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF174B3B), Color(0xFF10251F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TOTAL SALDO TERCATAT', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
        const SizedBox(height: 9),
        Text(rupiah(balance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _miniMetric('Pemasukan', income, Icons.arrow_downward_rounded, const Color(0xFF6EE7B7))),
          Expanded(child: _miniMetric('Pengeluaran', expense, Icons.arrow_upward_rounded, const Color(0xFFFF9C9C))),
        ]),
        const SizedBox(height: 12),
        const Text('Saldo dihitung dari transaksi yang tercatat di MONEYFLOW.', style: TextStyle(fontSize: 10, color: Colors.white54)),
      ]),
    );
  }

  Widget _miniMetric(String label, int amount, IconData icon, Color color) => Row(children: [
    Icon(icon, color: color, size: 17), const SizedBox(width: 7),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      Text(rupiah(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ])),
  ]);

  Widget _permissionCard() => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      const Icon(Icons.notifications_active_outlined, color: Color(0xFF39D6A3), size: 28),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Aktifkan deteksi transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 3),
        Text('Izinkan akses notifikasi agar MONEYFLOW dapat membaca notifikasi transaksi.', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ])),
      TextButton(onPressed: NotificationService.openSettings, child: const Text('Aktifkan')),
    ]),
  ));

  Widget _monthSummary() => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Row(children: [
      Expanded(child: _summaryTile('Masuk bulan ini', monthIncome, const Color(0xFF6EE7B7))),
      const SizedBox(width: 10),
      Expanded(child: _summaryTile('Keluar bulan ini', monthExpense, const Color(0xFFFF9C9C))),
    ]),
  );

  Widget _summaryTile(String label, int value, Color color) => Card(child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      const SizedBox(height: 8),
      Text(rupiah(value), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
    ]),
  ));

  Widget _spendingCard() {
    final byCategory = <String, int>{};
    for (final t in thisMonth.where((t) => t.type == 'expense')) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final entries = byCategory.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pengeluaran bulan ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (entries.isEmpty) const Center(child: Padding(
          padding: EdgeInsets.all(20), child: Text('Belum ada data pengeluaran bulan ini.', style: TextStyle(color: Colors.white54)),
        )) else Row(children: [
          SizedBox(width: 116, height: 116, child: PieChart(PieChartData(
            centerSpaceRadius: 30, sectionsSpace: 3,
            sections: entries.take(5).map((e) => PieChartSectionData(value: e.value.toDouble(), title: '', radius: 18)).toList(),
          ))),
          const SizedBox(width: 15),
          Expanded(child: Column(children: entries.take(5).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
              Text(rupiah(e.value), style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
          )).toList())),
        ]),
      ]),
    ));
  }

  Widget _transactionTile(MoneyTransaction t) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: CircleAvatar(backgroundColor: const Color(0xFF24352F), child: Icon(
        t.type == 'income' ? Icons.south_west_rounded : Icons.north_east_rounded,
        color: t.type == 'income' ? const Color(0xFF6EE7B7) : const Color(0xFFFF9C9C),
      )),
      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text('${t.category} • ${t.source}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
      trailing: Text('${t.type == 'income' ? '+' : '-'}${rupiah(t.amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t.type == 'income' ? const Color(0xFF6EE7B7) : const Color(0xFFFF9C9C))),
      onLongPress: t.id == null ? null : () async {
        await DatabaseService.instance.delete(t.id!);
        _refresh();
      },
    ),
  );
}
