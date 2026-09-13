import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'database/app_database.dart';

const _uuid = Uuid();

/// Seeds the local Hive database with realistic sample data the very
/// first time the app runs, so every screen is immediately populated
/// and functional without needing a backend.
class DummyData {
  DummyData._();

  static Future<void> seedIfEmpty() async {
    if (AppDatabase.customersBox.isNotEmpty ||
        AppDatabase.invoicesBox.isNotEmpty) {
      return;
    }

    final customerNames = [
      ['Mas Pra', '0812-3456-7890', 'maspra@mail.com', 'Jl. Kaliurang KM 5, Sleman, Yogyakarta'],
      ['Budi Santoso', '0813-1122-3344', 'budi.s@mail.com', 'Jl. Malioboro No. 12, Yogyakarta'],
      ['Andi Wijaya', '0857-9988-1122', 'andi.w@mail.com', 'Jl. Solo KM 8, Yogyakarta'],
      ['Sari Dewi', '0821-4455-6677', 'sari.dewi@mail.com', 'Jl. Gejayan No. 3, Yogyakarta'],
      ['Rina Amelia', '0878-2233-4455', 'rina.a@mail.com', 'Jl. Parangtritis KM 4, Bantul'],
    ];

    final customers = <Customer>[];
    for (final c in customerNames) {
      final customer = Customer(
        id: _uuid.v4(),
        name: c[0],
        phone: c[1],
        email: c[2],
        address: c[3],
        createdAt:
            DateTime.now().subtract(Duration(days: 60 + customers.length * 10)),
      );
      AppDatabase.customersBox.put(customer.id, customer);
      customers.add(customer);
    }

    final products = [
      ['Waffle Tinggi Ori', 800.0],
      ['Eskrim Powder Cokelat 1kg', 45000.0],
      ['Eskrim Powder Vanilla 1kg', 42000.0],
      ['Cup Eskrim 8oz (isi 50)', 35000.0],
      ['Cone Waffle Premium', 1200.0],
      ['Topping Cokelat Chip 500g', 28000.0],
    ];

    final now = DateTime.now();
    final invoiceSeeds = [
      [0, InvoiceStatus.unpaid, 0, 100, 0],
      [1, InvoiceStatus.paid, 1, 5, 1],
      [2, InvoiceStatus.overdue, 2, 8, 3],
      [3, InvoiceStatus.paid, 3, 20, 4],
      [4, InvoiceStatus.unpaid, 4, 3, 5],
      [0, InvoiceStatus.paid, 5, 15, 2],
      [1, InvoiceStatus.draft, 0, 50, 1],
      [2, InvoiceStatus.paid, 1, 10, 0],
    ];

    int seq = 490;
    for (int i = 0; i < invoiceSeeds.length; i++) {
      final seed = invoiceSeeds[i];
      final customer = customers[seed[0] as int];
      final status = seed[1] as InvoiceStatus;
      final product = products[seed[2] as int];
      final qty = (seed[3] as int).toDouble();
      final daysAgo = seed[4] as int;

      final item = InvoiceItem(
        id: _uuid.v4(),
        name: product[0] as String,
        price: product[1] as double,
        quantity: qty,
      );

      final invoiceDate = now.subtract(Duration(days: daysAgo));
      final invoice = Invoice(
        id: _uuid.v4(),
        invoiceNumber: 'INV${(seq - i).toString().padLeft(4, '0')}',
        customerId: customer.id,
        invoiceDate: invoiceDate,
        dueDate: invoiceDate.add(const Duration(days: 7)),
        items: [item],
        shipping: i.isEven ? 10000 : 0,
        discount: i % 3 == 0 ? 5000 : 0,
        status: status,
        notes: 'Thank you for shopping with us!',
        createdAt: invoiceDate,
        updatedAt: invoiceDate,
        isFavorite: i == 1,
      );
      if (status == InvoiceStatus.paid) {
        invoice.amountPaid = invoice.total;
      }
      AppDatabase.invoicesBox.put(invoice.id, invoice);
    }

    final settings = AppDatabase.settings;
    settings.nextInvoiceSequence = seq + 1;
    await settings.save();
  }
}
