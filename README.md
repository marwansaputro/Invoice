# Invoicely — Create. Send. Get Paid.

A modern, premium Invoice Management & Generator mobile app built with
Flutter + Dart, Material 3, Riverpod, and Hive (local, offline-first
storage).

## Getting started

```bash
flutter pub get
flutter run
```

The app seeds itself with realistic dummy data (5 customers, 8 invoices)
on first launch, so every screen is populated immediately — no backend
required.

## Stack

- **Flutter (stable) + Dart**, Material 3
- **State management:** flutter_riverpod
- **Local database:** Hive (hand-written `TypeAdapter`s — no code
  generation step required, so `flutter pub get` is all you need)
- **PDF generation:** `pdf` + `printing`
- **Sharing:** `share_plus`
- **Typography:** `google_fonts` (Plus Jakarta Sans)

## Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/app_theme.dart        # Material 3 color scheme, light + dark
│   ├── animations/app_motion.dart  # Durations, curves, AnimatedEntry, PressableScale, route transitions
│   ├── widgets/                    # AppButton, AppCard, StatusBadge, MoneyText, AnimatedNumber,
│   │                                #   EmptyState, LoadingSkeleton, AppBottomSheet, InvoicePaper, etc.
│   └── utils/                      # formatters, pdf_generator
├── models/models.dart              # Customer, Invoice, InvoiceItem, BusinessProfile, InvoiceSettingsModel
├── data/
│   ├── database/app_database.dart  # Hive init + box handles
│   ├── repositories/                # Riverpod StateNotifiers (Customer, Invoice, Theme)
│   └── dummy_data.dart
├── features/
│   ├── dashboard/
│   ├── invoices/
│   ├── invoice_create/
│   ├── invoice_preview/
│   ├── customers/
│   └── settings/
└── routes/root_shell.dart          # Bottom nav + animated FAB
```

## Design notes / simplifications

- `InvoiceStatus` doubles as both the workflow state and the payment
  badge shown on cards (`draft / unpaid / partial / paid / overdue`) to
  keep the model simple, instead of two separate enums.
- Discount / tax on both the line-item level and the invoice level are
  stored as flat amounts (not percentages) for predictable, real-time
  totals.
- Currency defaults to **Rp (IDR)** everywhere, matching the sample
  content in the spec. The Settings → Currency picker stores your
  selection, but most display surfaces are currently wired to Rp — swap
  the `symbol` passed into `MoneyText` / `AnimatedNumber` from
  `AppDatabase.settings.currencySymbol` if you want it fully dynamic.
- "Business Profile" and "Payment Methods" share one edit sheet since
  they're stored on the same `BusinessProfile` record.
- The dummy repository layer (`InvoiceRepository`, `CustomerRepository`)
  is a thin wrapper around Hive boxes — swap the box calls for
  REST/Supabase/Firebase calls later without touching the UI layer.

## Fonts / icons

Uses Material Icons (bundled) and Google Fonts (fetched at runtime on
first launch, then cached) — no asset bundling required.
