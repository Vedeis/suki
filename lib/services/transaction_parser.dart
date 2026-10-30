import '../models/transaction.dart';

class ParsedTransaction {
  final String title, category, type, source;
  final int amount;
  const ParsedTransaction(this.title, this.category, this.type, this.source, this.amount);
}

class TransactionParser {
  // Heuristic parser: notification formats differ by bank/app and can change.
  // It deliberately avoids interpreting notifications without a clear amount.
  static ParsedTransaction? parse(String packageName, String text) {
    final lower = text.toLowerCase();
    final amountMatch = RegExp(
      r'(?:rp\.?\s?|idr\s?)([0-9][0-9.,]*)|(?:nominal|amount|sebesar)\s*[:：]?\s*rp?\\s*([0-9][0-9.,]*)',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null) return null;
    final rawAmount = (amountMatch.group(1) ?? amountMatch.group(2) ?? '')
        .replaceAll('.', '').replaceAll(',', '');
    final amount = int.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    final expenseWords = ['debit', 'transfer keluar', 'pembayaran', 'payment', 'berhasil bayar', 'purchase', 'belanja', 'kirim uang', 'transaksi keluar'];
    final incomeWords = ['kredit', 'uang masuk', 'transfer masuk', 'top up diterima', 'menerima transfer', 'refund', 'cashback'];
    String type = 'expense';
    if (incomeWords.any(lower.contains)) {
      type = 'income';
    } else if (!expenseWords.any(lower.contains)) {
      return null; // avoid false positives
    }

    final source = _source(packageName);
    String category = 'Lainnya';
    if (['makan', 'resto', 'restaurant', 'food', 'gofood', 'grabfood'].any(lower.contains)) category = 'Makanan';
    else if (['transport', 'gojek', 'grab', 'parkir', 'bensin', 'tol'].any(lower.contains)) category = 'Transportasi';
    else if (['tokopedia', 'shopee', 'marketplace', 'belanja'].any(lower.contains)) category = 'Belanja';
    else if (['pulsa', 'paket data', 'internet'].any(lower.contains)) category = 'Tagihan';
    else if (type == 'income') category = 'Pemasukan';

    final title = type == 'income' ? 'Uang masuk • $source' : 'Transaksi • $source';
    return ParsedTransaction(title, category, type, source, amount);
  }

  static String _source(String packageName) {
    final p = packageName.toLowerCase();
    if (p.contains('dana')) return 'DANA';
    if (p.contains('gojek')) return 'GoPay / Gojek';
    if (p.contains('ovo')) return 'OVO';
    if (p.contains('shopee')) return 'ShopeePay';
    if (p.contains('bca')) return 'BCA';
    if (p.contains('bni')) return 'BNI';
    if (p.contains('bri')) return 'BRI';
    if (p.contains('mandiri')) return 'Mandiri';
    if (p.contains('blu')) return 'blu';
    if (p.contains('seabank')) return 'SeaBank';
    return 'Notifikasi Android';
  }
}
