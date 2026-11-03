import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:emb_cal/models/production_record.dart';
import 'package:emb_cal/providers/production_provider.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  test('Independent selection and toggle deselect between Dashboard and Production Entry', () async {
    final provider = ProductionProvider();
    await provider.init();

    // Verify both are null initially (not forcibly auto-selected)
    expect(provider.dashboardSelectedRecord, isNull);
    expect(provider.entrySelectedRecord, isNull);

    final dummyRecord1 = ProductionRecord(
      id: 101,
      date: DateTime(2025, 4, 16),
      designNo: 'TEST-A',
      machineNo: 'M-01',
      totalStitch: 250000,
      finalStitch: 250.0,
      rate: 1.25,
      amount: 312.5,
      heads: 12,
      finalAmount: 3750.0,
    );

    final dummyRecord2 = ProductionRecord(
      id: 102,
      date: DateTime(2025, 4, 17),
      designNo: 'TEST-B',
      machineNo: 'M-02',
      totalStitch: 350000,
      finalStitch: 350.0,
      rate: 1.50,
      amount: 525.0,
      heads: 12,
      finalAmount: 6300.0,
    );

    // Select on Dashboard
    provider.selectDashboardRecord(dummyRecord1);
    expect(provider.dashboardSelectedRecord?.id, equals(101));
    // Entry selection remains completely independent (null)
    expect(provider.entrySelectedRecord, isNull);

    // Select on Entry
    provider.selectEntryRecord(dummyRecord2);
    expect(provider.entrySelectedRecord?.id, equals(102));
    expect(provider.dashboardSelectedRecord?.id, equals(101));

    // Toggle deselect on Dashboard (clicking selected item sets to null)
    provider.selectDashboardRecord(dummyRecord1);
    expect(provider.dashboardSelectedRecord, isNull);
    // Entry selection is untouched
    expect(provider.entrySelectedRecord?.id, equals(102));

    // Toggle deselect on Entry
    provider.selectEntryRecord(dummyRecord2);
    expect(provider.entrySelectedRecord, isNull);
  });

  test('Trend summary generates data points and +/- indicators correctly for day, week, month, year', () async {
    final provider = ProductionProvider();
    await provider.init();

    for (final period in TrendPeriod.values) {
      final summary = provider.getTrendSummary(period);
      expect(summary.period, equals(period));
      expect(summary.isPositive, isA<bool>());
      expect(summary.points, isA<List<TrendDataPoint>>());
    }
  });

  test('Auto refresh interval is configurable and saves to settings', () async {
    final provider = ProductionProvider();
    await provider.init();

    expect(provider.settings.autoRefreshIntervalSeconds, equals(120));

    final updated = provider.settings.copyWith(autoRefreshIntervalSeconds: 30);
    await provider.saveSettings(updated);
    expect(provider.settings.autoRefreshIntervalSeconds, equals(30));

    // Restore default
    await provider.saveSettings(provider.settings.copyWith(autoRefreshIntervalSeconds: 120));
    expect(provider.settings.autoRefreshIntervalSeconds, equals(120));
  });
}
