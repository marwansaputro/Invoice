/// Lightweight, hand-rolled localization for the app's main navigation
/// chrome (bottom nav, Dashboard, Settings) plus the Transaction Recap
/// screen. Other deeper flows (Create Invoice, Invoices/Customers lists,
/// PDF export) stay in English for now.
class AppStrings {
  final String locale; // 'en' or 'id'
  const AppStrings(this.locale);

  bool get _id => locale == 'id';
  String _t(String en, String id) => _id ? id : en;

  // Bottom navigation
  String get navDashboard => _t('Dashboard', 'Dasbor');
  String get navInvoices => _t('Invoices', 'Invoice');
  String get navCustomers => _t('Customers', 'Pelanggan');
  String get navSettings => _t('Settings', 'Pengaturan');

  // Dashboard
  String get manageInvoicesEasily => _t('Manage your invoices easily', 'Kelola invoice Anda dengan mudah');
  String get totalRevenue => _t('Total Revenue', 'Total Pendapatan');
  String get comparedToLastMonth => _t('Compared to last month', 'Dibanding bulan lalu');
  String get paid => _t('Paid', 'Lunas');
  String get pending => _t('Pending', 'Tertunda');
  String get overdue => _t('Overdue', 'Jatuh Tempo');
  String get recentInvoices => _t('Recent Invoices', 'Invoice Terbaru');
  String get seeAll => _t('See All', 'Lihat Semua');
  String get noInvoicesYetTitle => _t('No invoices yet', 'Belum ada invoice');
  String get noInvoicesYetMessage => _t(
      'Create your first invoice and start tracking your payments.',
      'Buat invoice pertama Anda dan mulai lacak pembayaran.');

  // Settings
  String get settingsTitle => _t('Settings', 'Pengaturan');
  String get manageBusinessPreferences =>
      _t('Manage your business & app preferences', 'Kelola bisnis & preferensi aplikasi');
  String get sectionBusiness => _t('Business', 'Bisnis');
  String get sectionPreferences => _t('Preferences', 'Preferensi');
  String get sectionAppearance => _t('Appearance', 'Tampilan');
  String get sectionData => _t('Data', 'Data');
  String get businessProfile => _t('Business Profile', 'Profil Bisnis');
  String get invoiceSettings => _t('Invoice Settings', 'Pengaturan Invoice');
  String get paymentMethods => _t('Payment Methods', 'Metode Pembayaran');
  String get taxSettings => _t('Tax Settings', 'Pengaturan Pajak');
  String get currency => _t('Currency', 'Mata Uang');
  String get invoiceTemplate => _t('Invoice Template', 'Template Invoice');
  String get language => _t('Language', 'Bahasa');
  String get transactionRecap => _t('Transaction Recap', 'Rekap Transaksi');
  String get notifications => _t('Notifications', 'Notifikasi');
  String get light => _t('Light', 'Terang');
  String get dark => _t('Dark', 'Gelap');
  String get system => _t('System', 'Sistem');
  String get backupRestore => _t('Backup & Restore', 'Cadangkan & Pulihkan');
  String get about => _t('About', 'Tentang');
  String get tapToEditBusinessProfile => _t('Tap to edit business profile', 'Ketuk untuk edit profil bisnis');
  String get dataAlreadySavedLocally => _t(
      'All your data is already saved locally on this device.',
      'Semua data Anda sudah tersimpan secara lokal di perangkat ini.');

  // Language picker sheet
  String get selectLanguage => _t('Select Language', 'Pilih Bahasa');
  String get selectLanguageDescription =>
      _t('Choose the app display language.', 'Pilih bahasa tampilan aplikasi.');
  String get languageEnglish => 'English';
  String get languageIndonesian => 'Indonesia';

  // Transaction Recap screen
  String get recapSubtitle =>
      _t('Summary of your transactions by period', 'Ringkasan transaksi berdasarkan periode');
  String get periodToday => _t('Today', 'Hari Ini');
  String get periodWeek => _t('This Week', 'Minggu Ini');
  String get periodMonth => _t('This Month', 'Bulan Ini');
  String get periodYear => _t('This Year', 'Tahun Ini');
  String get periodAll => _t('All Time', 'Semua Waktu');
  String get totalInvoices => _t('Total Invoices', 'Total Invoice');
  String get totalCollected => _t('Collected', 'Terkumpul');
  String get noTransactionsTitle => _t('No transactions', 'Tidak ada transaksi');
  String get noTransactionsMessage =>
      _t('No invoices were issued in this period.', 'Tidak ada invoice yang dibuat pada periode ini.');
}
