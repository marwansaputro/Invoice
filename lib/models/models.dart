import 'package:hive/hive.dart';

/// Unified status used for both invoice workflow state and payment
/// badge display (spec sections 6, 8, 28 combined for simplicity —
/// `InvoiceStatus` doubles as the payment status shown on badges).
enum InvoiceStatus { draft, unpaid, paid, overdue, partial }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.unpaid:
        return 'UNPAID';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
      case InvoiceStatus.partial:
        return 'PARTIAL';
    }
  }
}

class InvoiceItem {
  String id;
  String name;
  double price;
  double quantity;
  double discount; // flat amount
  double tax; // flat amount

  InvoiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.discount = 0,
    this.tax = 0,
  });

  double get lineSubtotal => price * quantity;
  double get lineTotal => lineSubtotal - discount + tax;

  InvoiceItem copyWith({
    String? name,
    double? price,
    double? quantity,
    double? discount,
    double? tax,
  }) {
    return InvoiceItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }
}

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 1;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      id: fields[0] as String,
      name: fields[1] as String,
      price: (fields[2] as num).toDouble(),
      quantity: (fields[3] as num).toDouble(),
      discount: (fields[4] as num?)?.toDouble() ?? 0,
      tax: (fields[5] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.tax);
  }
}

class Customer extends HiveObject {
  String id;
  String name;
  String phone;
  String email;
  String address;
  DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 0;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String? ?? '',
      email: fields[3] as String? ?? '',
      address: fields[4] as String? ?? '',
      createdAt: fields[5] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}

class Invoice extends HiveObject {
  String id;
  String invoiceNumber;
  String customerId;
  DateTime invoiceDate;
  DateTime? dueDate;
  List<InvoiceItem> items;
  double discount; // invoice-level flat amount
  double tax; // invoice-level flat amount
  double shipping;
  double amountPaid;
  InvoiceStatus status;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavorite;
  String poNumber; // PO / reference number from the customer
  String paymentMethod; // e.g. Bank Transfer, Cash, QRIS, E-Wallet
  List<int>? attachmentBytes; // optional attached photo (PNG/JPEG)
  List<int>? signatureBytes; // optional drawn signature (PNG)
  bool isApproved;
  String approverName;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.invoiceDate,
    this.dueDate,
    List<InvoiceItem>? items,
    this.discount = 0,
    this.tax = 0,
    this.shipping = 0,
    this.amountPaid = 0,
    this.status = InvoiceStatus.draft,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.poNumber = '',
    this.paymentMethod = '',
    this.attachmentBytes,
    this.signatureBytes,
    this.isApproved = false,
    this.approverName = '',
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineSubtotal);
  double get total => subtotal - discount + tax + shipping;
  double get balanceDue => (total - amountPaid).clamp(0, double.infinity);
}

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 2;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      customerId: fields[2] as String,
      invoiceDate: fields[3] as DateTime,
      dueDate: fields[4] as DateTime?,
      items: (fields[5] as List).cast<InvoiceItem>(),
      discount: (fields[6] as num?)?.toDouble() ?? 0,
      tax: (fields[7] as num?)?.toDouble() ?? 0,
      shipping: (fields[8] as num?)?.toDouble() ?? 0,
      amountPaid: (fields[9] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values[fields[10] as int? ?? 0],
      notes: fields[11] as String? ?? '',
      createdAt: fields[12] as DateTime? ?? DateTime.now(),
      updatedAt: fields[13] as DateTime? ?? DateTime.now(),
      isFavorite: fields[14] as bool? ?? false,
      poNumber: fields[15] as String? ?? '',
      paymentMethod: fields[16] as String? ?? '',
      attachmentBytes: (fields[17] as List?)?.cast<int>(),
      signatureBytes: (fields[18] as List?)?.cast<int>(),
      isApproved: fields[19] as bool? ?? false,
      approverName: fields[20] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.invoiceDate)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.discount)
      ..writeByte(7)
      ..write(obj.tax)
      ..writeByte(8)
      ..write(obj.shipping)
      ..writeByte(9)
      ..write(obj.amountPaid)
      ..writeByte(10)
      ..write(obj.status.index)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.isFavorite)
      ..writeByte(15)
      ..write(obj.poNumber)
      ..writeByte(16)
      ..write(obj.paymentMethod)
      ..writeByte(17)
      ..write(obj.attachmentBytes)
      ..writeByte(18)
      ..write(obj.signatureBytes)
      ..writeByte(19)
      ..write(obj.isApproved)
      ..writeByte(20)
      ..write(obj.approverName);
  }
}

class BusinessProfile extends HiveObject {
  String businessName;
  String address;
  String phone;
  String email;
  String bankName;
  String bankAccountName;
  String bankAccountNumber;
  List<String> acceptedPaymentMethods;
  List<int>? logoBytes;
  String qrisId;
  String eWalletProvider;
  String eWalletNumber;

  BusinessProfile({
    this.businessName = 'Purnama Eskrim Powder',
    this.address = 'Jl. Kembaran RT. 03, Tamantirto, Kasihan, Bantul, Yogyakarta.',
    this.phone = '',
    this.email = '',
    this.bankName = 'BCA',
    this.bankAccountName = 'CV. Maurindo Purnama Abadi',
    this.bankAccountNumber = '',
    List<String>? acceptedPaymentMethods,
    this.logoBytes,
    this.qrisId = '',
    this.eWalletProvider = 'OVO',
    this.eWalletNumber = '',
  }) : acceptedPaymentMethods = acceptedPaymentMethods ?? ['Bank Transfer'];
}

class BusinessProfileAdapter extends TypeAdapter<BusinessProfile> {
  @override
  final int typeId = 3;

  @override
  BusinessProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessProfile(
      businessName: fields[0] as String? ?? 'My Business',
      address: fields[1] as String? ?? '',
      phone: fields[2] as String? ?? '',
      email: fields[3] as String? ?? '',
      bankName: fields[4] as String? ?? '',
      bankAccountName: fields[5] as String? ?? '',
      bankAccountNumber: fields[6] as String? ?? '',
      acceptedPaymentMethods: (fields[7] as List?)?.cast<String>(),
      logoBytes: (fields[8] as List?)?.cast<int>(),
      qrisId: fields[9] as String? ?? '',
      eWalletProvider: fields[10] as String? ?? 'OVO',
      eWalletNumber: fields[11] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, BusinessProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.businessName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.bankName)
      ..writeByte(5)
      ..write(obj.bankAccountName)
      ..writeByte(6)
      ..write(obj.bankAccountNumber)
      ..writeByte(7)
      ..write(obj.acceptedPaymentMethods)
      ..writeByte(8)
      ..write(obj.logoBytes)
      ..writeByte(9)
      ..write(obj.qrisId)
      ..writeByte(10)
      ..write(obj.eWalletProvider)
      ..writeByte(11)
      ..write(obj.eWalletNumber);
  }
}

class InvoiceSettingsModel extends HiveObject {
  String currencySymbol;
  String invoiceNumberPrefix;
  int nextInvoiceSequence;
  int defaultDueDays;
  double defaultTaxPercent;
  int themeMode; // 0 = system, 1 = light, 2 = dark
  bool notificationsEnabled;

  InvoiceSettingsModel({
    this.currencySymbol = 'Rp',
    this.invoiceNumberPrefix = 'INV',
    this.nextInvoiceSequence = 491,
    this.defaultDueDays = 0,
    this.defaultTaxPercent = 0,
    this.themeMode = 0,
    this.notificationsEnabled = true,
  });
}

class InvoiceSettingsAdapter extends TypeAdapter<InvoiceSettingsModel> {
  @override
  final int typeId = 4;

  @override
  InvoiceSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceSettingsModel(
      currencySymbol: fields[0] as String? ?? 'Rp',
      invoiceNumberPrefix: fields[1] as String? ?? 'INV',
      nextInvoiceSequence: fields[2] as int? ?? 1,
      defaultDueDays: fields[3] as int? ?? 0,
      defaultTaxPercent: (fields[4] as num?)?.toDouble() ?? 0,
      themeMode: fields[5] as int? ?? 0,
      notificationsEnabled: fields[6] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceSettingsModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.currencySymbol)
      ..writeByte(1)
      ..write(obj.invoiceNumberPrefix)
      ..writeByte(2)
      ..write(obj.nextInvoiceSequence)
      ..writeByte(3)
      ..write(obj.defaultDueDays)
      ..writeByte(4)
      ..write(obj.defaultTaxPercent)
      ..writeByte(5)
      ..write(obj.themeMode)
      ..writeByte(6)
      ..write(obj.notificationsEnabled);
  }
}
