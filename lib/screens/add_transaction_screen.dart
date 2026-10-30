import 'package:flutter/material.dart';
import '../main.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final title = TextEditingController();
  final amount = TextEditingController();
  String type = 'expense';
  String category = 'Makanan';
  String source = 'Tunai';
  final categories = ['Makanan','Transportasi','Belanja','Tagihan','Hiburan','Pendidikan','Kesehatan','Pemasukan','Lainnya'];

  @override
  void dispose() { title.dispose(); amount.dispose(); super.dispose(); }

  Future<void> save() async {
    final value = int.tryParse(amount.text.replaceAll('.', '').replaceAll(',', ''));
    if (title.text.trim().isEmpty || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama dan nominal transaksi dengan benar.')));
      return;
    }
    await DatabaseService.instance.insert(MoneyTransaction(
      title: title.text.trim(), category: category, amount: value,
      type: type, source: source, createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tambah transaksi')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'expense', label: Text('Pengeluaran'), icon: Icon(Icons.arrow_upward)),
          ButtonSegment(value: 'income', label: Text('Pemasukan'), icon: Icon(Icons.arrow_downward)),
        ],
        selected: {type}, onSelectionChanged: (v) => setState(() => type = v.first),
      ),
      const SizedBox(height: 20),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Nama transaksi', hintText: 'Contoh: Makan siang')),
      const SizedBox(height: 14),
      TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (Rp)', hintText: '25000')),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Kategori'),
        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => category = v ?? category)),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: source, decoration: const InputDecoration(labelText: 'Sumber dana'),
        items: ['Tunai','BCA','BRI','BNI','Mandiri','DANA','GoPay','OVO','ShopeePay','blu','SeaBank','Lainnya'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => source = v ?? source)),
      const SizedBox(height: 28),
      FilledButton.icon(onPressed: save, icon: const Icon(Icons.check), label: const Padding(padding: EdgeInsets.all(13), child: Text('Simpan transaksi'))),
    ]),
  );
}
