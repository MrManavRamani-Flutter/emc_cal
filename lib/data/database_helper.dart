import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/account_model.dart';
import '../models/customer_bill_model.dart';
import '../models/customer_model.dart';
import '../models/customer_payment_model.dart';
import '../models/deleted_record_item.dart';
import '../models/employee_model.dart';
import '../models/employee_upad_model.dart';
import '../models/expense_model.dart';
import '../models/machine_model.dart';
import '../models/material_item.dart';
import '../models/material_product.dart';
import '../models/production_record.dart';
import '../models/settings_model.dart';
import '../models/supplier.dart';
import '../models/whatsapp_log_model.dart';
import 'sample_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'embroidery_production.db';
    } else if (Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(p.join(appDocDir.path, 'EmbroideryProductionCalculator'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      path = p.join(appDir.path, 'embroidery_production.db');
    }

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE machines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            machine_no TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            head_capacity INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            area TEXT,
            display_order INTEGER NOT NULL DEFAULT 0,
            color_hex TEXT DEFAULT '#2563EB',
            is_active INTEGER NOT NULL DEFAULT 1,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE production_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            created_at TEXT,
            design_no TEXT NOT NULL,
            machine_no TEXT NOT NULL,
            total_stitch INTEGER NOT NULL,
            final_stitch REAL NOT NULL,
            rate REAL NOT NULL,
            amount REAL NOT NULL,
            heads INTEGER NOT NULL,
            final_amount REAL NOT NULL,
            notes TEXT,
            account_name TEXT NOT NULL DEFAULT '250 Area',
            shift TEXT NOT NULL DEFAULT 'Day'
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            company_name TEXT,
            operator_name TEXT,
            currency_symbol TEXT,
            stitch_divider REAL,
            available_rates TEXT,
            available_heads TEXT,
            default_rate REAL,
            default_heads INTEGER,
            date_format TEXT,
            auto_refresh_seconds INTEGER DEFAULT 120,
            is_dark_mode INTEGER DEFAULT 0,
            theme_color_hex TEXT DEFAULT '#0066FF',
            employee_roles TEXT DEFAULT 'Operator,Master,Karigar,Helper,Designer,Checker,Manager,Other',
            expense_categories TEXT DEFAULT '',
            sender_phone TEXT DEFAULT '',
            whatsapp_auto_send INTEGER DEFAULT 0,
            whatsapp_message_language TEXT DEFAULT 'English',
            app_language TEXT DEFAULT 'en',
            font_scale REAL DEFAULT 1.0
          )
        ''');

        await db.execute('''
          CREATE TABLE material_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challan_no TEXT,
            supplier_name TEXT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            product_name TEXT NOT NULL,
            item_type TEXT NOT NULL,
            mtr REAL DEFAULT 0.0,
            mm REAL DEFAULT 0.0,
            qty REAL NOT NULL,
            rate REAL NOT NULL,
            amount REAL NOT NULL,
            used_qty REAL DEFAULT 0.0,
            notes TEXT,
            paid_amount REAL DEFAULT 0.0,
            payment_status TEXT DEFAULT 'Pending',
            payment_date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE deleted_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_type TEXT NOT NULL,
            record_title TEXT NOT NULL,
            record_subtitle TEXT,
            original_id INTEGER,
            original_data TEXT NOT NULL,
            deleted_at TEXT NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE material_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            category TEXT NOT NULL,
            default_rate REAL NOT NULL DEFAULT 0.0,
            unit TEXT NOT NULL DEFAULT 'piece',
            default_mtr REAL DEFAULT 0.0,
            default_mm REAL DEFAULT 0.0,
            notes TEXT,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            phone TEXT DEFAULT '',
            city TEXT DEFAULT '',
            gst_no TEXT DEFAULT '',
            notes TEXT DEFAULT '',
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE employees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'Operator',
            gender TEXT NOT NULL DEFAULT 'Male',
            phone TEXT DEFAULT '',
            joining_date TEXT NOT NULL,
            monthly_salary REAL NOT NULL DEFAULT 0.0,
            is_active INTEGER NOT NULL DEFAULT 1,
            notes TEXT DEFAULT ''
          )
        ''');

        await db.execute('''
          CREATE TABLE employee_upads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            employee_name TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            notes TEXT DEFAULT '',
            is_settled INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE whatsapp_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER,
            employee_name TEXT NOT NULL,
            recipient_phone TEXT NOT NULL,
            sender_phone TEXT NOT NULL,
            message TEXT NOT NULL,
            message_type TEXT NOT NULL DEFAULT 'upad_receipt',
            amount REAL NOT NULL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Sent'
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL DEFAULT 0.0,
            payment_mode TEXT NOT NULL DEFAULT 'Cash',
            paid_to TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            phone TEXT NOT NULL DEFAULT '',
            city TEXT NOT NULL DEFAULT '',
            gst_no TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_no TEXT NOT NULL UNIQUE,
            customer_id INTEGER,
            customer_name TEXT NOT NULL,
            date TEXT NOT NULL,
            total_amount REAL NOT NULL DEFAULT 0.0,
            paid_amount REAL NOT NULL DEFAULT 0.0,
            payment_status TEXT NOT NULL DEFAULT 'Unpaid',
            payment_date TEXT,
            design_details TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_id INTEGER,
            customer_id INTEGER,
            customer_name TEXT NOT NULL,
            amount REAL NOT NULL DEFAULT 0.0,
            date TEXT NOT NULL,
            payment_mode TEXT NOT NULL DEFAULT 'Cash',
            notes TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');

        // Seed initial data
        final batch = db.batch();

        for (final machine in SampleData.getMachines()) {
          batch.insert('machines', machine.toMap());
        }

        for (final account in SampleData.getInitialAccounts()) {
          batch.insert('accounts', account.toMap());
        }

        for (final record in SampleData.getInitialRecords()) {
          final map = record.toMap()..remove('id');
          batch.insert('production_records', map);
        }

        for (final material in SampleData.getInitialMaterials()) {
          final map = material.toMap()..remove('id');
          batch.insert('material_items', map);
        }

        final defaultSettings = SettingsModel();
        final settingsMap = defaultSettings.toMap();
        settingsMap['id'] = 1;
        batch.insert('settings', settingsMap);

        await batch.commit();
      },
    );

    await _ensureMigration(db);
    return db;
  }

  bool _migrationCompleted = false;

  Future<void> _ensureMigration(Database db) async {
    if (_migrationCompleted) return;
    _migrationCompleted = true;
    // 1. Ensure accounts table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          area TEXT,
          display_order INTEGER NOT NULL DEFAULT 0,
          color_hex TEXT DEFAULT '#2563EB',
          is_active INTEGER NOT NULL DEFAULT 1,
          notes TEXT
        )
      ''');
    } catch (_) {}

    // 2. Ensure default accounts seeded or migrated
    try {
      final existingAccounts = await db.query('accounts');
      if (existingAccounts.isEmpty) {
        final batch = db.batch();
        for (final account in SampleData.getInitialAccounts()) {
          batch.insert('accounts', account.toMap());
        }
        await batch.commit(noResult: true);
      } else {
        // Migrate legacy names if present
        await db.execute("UPDATE accounts SET name = '250 Area' WHERE name = '250 Area Khatu'");
        await db.execute("UPDATE accounts SET name = '400 Area' WHERE name = '400 Area Khatu'");
        await db.execute("UPDATE accounts SET name = 'Beads' WHERE name = 'Beads Khatu'");
      }
    } catch (_) {}

    // 3. Ensure production_records columns exist
    try {
      await db.execute("ALTER TABLE production_records ADD COLUMN account_name TEXT DEFAULT '250 Area'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE production_records ADD COLUMN shift TEXT DEFAULT 'Day'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE production_records ADD COLUMN created_at TEXT");
    } catch (_) {}

    // 4. Fill and update any legacy values in production_records
    try {
      await db.execute("UPDATE production_records SET account_name = '250 Area' WHERE account_name = '250 Area Khatu'");
      await db.execute("UPDATE production_records SET account_name = '400 Area' WHERE account_name = '400 Area Khatu'");
      await db.execute("UPDATE production_records SET account_name = 'Beads' WHERE account_name = 'Beads Khatu'");
      await db.execute("UPDATE production_records SET account_name = '250 Area' WHERE account_name IS NULL OR account_name = ''");
      await db.execute("UPDATE production_records SET shift = 'Day' WHERE shift IS NULL OR shift = ''");
      await db.execute("UPDATE production_records SET created_at = date || 'T12:00:00' WHERE created_at IS NULL OR created_at = ''");
    } catch (_) {}

    // 5. Ensure all 8 Dahao factory machines exist (M-01 to M-08)
    try {
      final existingMachines = await db.query('machines');
      final existingNos = existingMachines.map((m) => m['machine_no'] as String).toSet();
      for (final machine in SampleData.getMachines()) {
        if (!existingNos.contains(machine.machineNo)) {
          final map = machine.toMap()..remove('id');
          await db.insert('machines', map);
        }
      }
    } catch (_) {}

    // 6. Ensure material_items table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS material_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          challan_no TEXT,
          supplier_name TEXT,
          date TEXT NOT NULL,
          category TEXT NOT NULL,
          product_name TEXT NOT NULL,
          item_type TEXT NOT NULL,
          mtr REAL DEFAULT 0.0,
          mm REAL DEFAULT 0.0,
          qty REAL NOT NULL,
          rate REAL NOT NULL,
          amount REAL NOT NULL,
          used_qty REAL DEFAULT 0.0,
          notes TEXT,
          payment_status TEXT DEFAULT 'Pending',
          payment_date TEXT
        )
      ''');
    } catch (_) {}

    // 9. Update default chart auto_refresh_seconds to 120 (2 minutes)
    try {
      await db.execute('''
        UPDATE settings 
        SET auto_refresh_seconds = 120 
        WHERE auto_refresh_seconds = 10 OR auto_refresh_seconds IS NULL
      ''');
    } catch (_) {}

    // 10. Ensure material_products table exists and seed initial master products
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS material_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          default_rate REAL NOT NULL,
          unit TEXT NOT NULL,
          default_mtr REAL DEFAULT 0.0,
          default_mm REAL DEFAULT 0.0,
          notes TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');

      final existingProducts = await db.query('material_products');
      if (existingProducts.isEmpty) {
        final batch = db.batch();
        for (final product in SampleData.getInitialMaterialProducts()) {
          final map = product.toMap()..remove('id');
          batch.insert('material_products', map);
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {}

    // 11. Ensure suppliers table exists and seed initial suppliers from ledger
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          phone TEXT DEFAULT '',
          city TEXT DEFAULT '',
          gst_no TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      final existingSuppliers = await db.query('suppliers');
      if (existingSuppliers.isEmpty) {
        final batch = db.batch();
        for (final supplier in SampleData.getInitialSuppliers()) {
          final map = supplier.toMap()..remove('id');
          batch.insert('suppliers', map);
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {}

    // 12. Normalize legacy 'Daga' / 'Dhaga' to standard 'Thread' across material tables
    try {
      await db.execute("UPDATE material_items SET category = 'Thread' WHERE LOWER(category) IN ('daga', 'dhaga')");
      await db.execute("UPDATE material_products SET category = 'Thread' WHERE LOWER(category) IN ('daga', 'dhaga')");
    } catch (_) {}

    // 13. Ensure deleted_records (Recycle Bin) table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          record_type TEXT NOT NULL,
          record_title TEXT NOT NULL,
          record_subtitle TEXT,
          original_id INTEGER,
          original_data TEXT NOT NULL,
          deleted_at TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
      try {
        await db.execute('ALTER TABLE deleted_records ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    } catch (_) {}

    // 14. Ensure employees and employee_upads tables exist
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employees (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'Operator',
          gender TEXT NOT NULL DEFAULT 'Male',
          phone TEXT DEFAULT '',
          joining_date TEXT NOT NULL,
          monthly_salary REAL NOT NULL DEFAULT 0.0,
          is_active INTEGER NOT NULL DEFAULT 1,
          notes TEXT DEFAULT ''
        )
      ''');
    } catch (_) {}

    try {
      await db.execute("ALTER TABLE employees ADD COLUMN gender TEXT DEFAULT 'Male'");
    } catch (_) {}

    try {
      await db.execute("ALTER TABLE settings ADD COLUMN sender_phone TEXT DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN whatsapp_auto_send INTEGER DEFAULT 0");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN whatsapp_message_language TEXT DEFAULT 'English'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN app_language TEXT DEFAULT 'en'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN font_scale REAL DEFAULT 1.0");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN expense_categories TEXT DEFAULT ''");
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS employee_upads (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employee_id INTEGER NOT NULL,
          employee_name TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          notes TEXT DEFAULT '',
          is_settled INTEGER NOT NULL DEFAULT 0
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS whatsapp_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employee_id INTEGER,
          employee_name TEXT NOT NULL,
          recipient_phone TEXT NOT NULL,
          sender_phone TEXT NOT NULL,
          message TEXT NOT NULL,
          message_type TEXT NOT NULL DEFAULT 'upad_receipt',
          amount REAL NOT NULL DEFAULT 0.0,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'Sent'
        )
      ''');
    } catch (_) {}

    // 16. Ensure payment_status and payment_date exist on material_items
    try {
      await db.execute("ALTER TABLE material_items ADD COLUMN payment_status TEXT DEFAULT 'Pending'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE material_items ADD COLUMN payment_date TEXT");
    } catch (_) {}

    // 17. Sanitize legacy sample data that contained Gujarati/Hindi in parentheses
    try {
      final nonAsciiParenRegex = RegExp(r'\s*\([\u0a80-\u0aff\u0900-\u097f\s\d\.\,\-]+\)');

      final prods = await db.query('material_products', columns: ['id', 'name']);
      for (final p in prods) {
        final id = p['id'] as int;
        final name = p['name'] as String? ?? '';
        if (nonAsciiParenRegex.hasMatch(name)) {
          final cleanName = name.replaceAll(nonAsciiParenRegex, '').trim();
          await db.update('material_products', {'name': cleanName}, where: 'id = ?', whereArgs: [id]);
        }
      }

      final supps = await db.query('suppliers', columns: ['id', 'name']);
      for (final s in supps) {
        final id = s['id'] as int;
        final name = s['name'] as String? ?? '';
        if (nonAsciiParenRegex.hasMatch(name)) {
          final cleanName = name.replaceAll(nonAsciiParenRegex, '').trim();
          await db.update('suppliers', {'name': cleanName}, where: 'id = ?', whereArgs: [id]);
        }
      }

      final items = await db.query('material_items', columns: ['id', 'product_name', 'supplier_name']);
      for (final item in items) {
        final id = item['id'] as int;
        final pName = item['product_name'] as String? ?? '';
        final sName = item['supplier_name'] as String? ?? '';
        final cleanPName = nonAsciiParenRegex.hasMatch(pName) ? pName.replaceAll(nonAsciiParenRegex, '').trim() : null;
        final cleanSName = nonAsciiParenRegex.hasMatch(sName) ? sName.replaceAll(nonAsciiParenRegex, '').trim() : null;
        if (cleanPName != null || cleanSName != null) {
          final updates = <String, dynamic>{};
          if (cleanPName != null) updates['product_name'] = cleanPName;
          if (cleanSName != null) updates['supplier_name'] = cleanSName;
          await db.update('material_items', updates, where: 'id = ?', whereArgs: [id]);
        }
      }
    } catch (_) {}

    // 21. Normalize employee roles and settings roles to uppercase
    try {
      await db.execute('UPDATE employees SET role = UPPER(TRIM(role)) WHERE role IS NOT NULL');
      await db.execute('UPDATE settings SET employee_roles = UPPER(TRIM(employee_roles)) WHERE employee_roles IS NOT NULL');
    } catch (_) {}

    // 22. Ensure material_items has paid_amount column
    try {
      await db.execute('ALTER TABLE material_items ADD COLUMN paid_amount REAL DEFAULT 0.0');
    } catch (_) {}
    try {
      // Sync legacy paid records so paid_amount equals amount
      await db.execute("UPDATE material_items SET paid_amount = amount WHERE LOWER(payment_status) = 'paid' AND (paid_amount IS NULL OR paid_amount = 0)");
    } catch (_) {}

    // 23. Ensure expenses table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_mode TEXT DEFAULT 'Cash',
          paid_to TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    // 24. Ensure customers table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          phone TEXT DEFAULT '',
          city TEXT DEFAULT '',
          gst_no TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    // 25. Ensure customer_bills table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer_bills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_no TEXT NOT NULL,
          customer_id INTEGER,
          customer_name TEXT NOT NULL,
          date TEXT NOT NULL,
          total_amount REAL NOT NULL,
          paid_amount REAL DEFAULT 0.0,
          payment_status TEXT DEFAULT 'Unpaid',
          payment_date TEXT,
          design_details TEXT DEFAULT '',
          notes TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    // 26. Ensure customer_payments table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customer_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_id INTEGER,
          customer_id INTEGER,
          customer_name TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          payment_mode TEXT DEFAULT 'Cash',
          notes TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}
  }

  // --- Account Operations ---
  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    await _ensureMigration(db);
    final List<Map<String, dynamic>> maps = await db.query('accounts', orderBy: 'display_order ASC, id ASC');
    return maps.map((m) => AccountModel.fromMap(m)).toList();
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await database;
    await _ensureMigration(db);
    final map = account.toMap()..remove('id');
    return await db.insert('accounts', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAccountOrders(List<AccountModel> accounts) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < accounts.length; i++) {
      final acc = accounts[i];
      batch.update(
        'accounts',
        {'display_order': i + 1},
        where: 'id = ?',
        whereArgs: [acc.id],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Machine Operations ---
  Future<List<MachineModel>> getMachines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('machines', orderBy: 'machine_no ASC');
    return maps.map((m) => MachineModel.fromMap(m)).toList();
  }

  Future<int> insertMachine(MachineModel machine) async {
    final db = await database;
    final map = machine.toMap()..remove('id');
    return await db.insert('machines', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMachine(MachineModel machine) async {
    final db = await database;
    return await db.update(
      'machines',
      machine.toMap(),
      where: 'id = ?',
      whereArgs: [machine.id],
    );
  }

  Future<int> deleteMachine(int id) async {
    final db = await database;
    return await db.delete('machines', where: 'id = ?', whereArgs: [id]);
  }

  // --- Production Record Operations ---
  Future<List<ProductionRecord>> getRecords() async {
    final db = await database;
    await _ensureMigration(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'production_records',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => ProductionRecord.fromMap(m)).toList();
  }

  Future<int> insertRecord(ProductionRecord record) async {
    final db = await database;
    await _ensureMigration(db);
    final map = record.toMap()..remove('id');
    return await db.insert('production_records', map);
  }

  Future<void> insertRecordsBatch(List<ProductionRecord> records) async {
    if (records.isEmpty) return;
    final db = await database;
    await _ensureMigration(db);
    final batch = db.batch();
    for (final record in records) {
      final map = record.toMap()..remove('id');
      batch.insert('production_records', map);
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateRecord(ProductionRecord record) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'production_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('production_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecordsBatch(List<int> ids) async {
    final db = await database;
    return await db.delete(
      'production_records',
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // --- Settings Operations ---
  Future<SettingsModel> getSettings() async {
    final db = await database;
    try {
      await db.execute('ALTER TABLE settings ADD COLUMN auto_refresh_seconds INTEGER DEFAULT 120');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE settings ADD COLUMN is_dark_mode INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN theme_color_hex TEXT DEFAULT '#0066FF'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN employee_roles TEXT DEFAULT 'Operator,Master,Karigar,Helper,Designer,Checker,Manager,Other'");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN sender_phone TEXT DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN whatsapp_auto_send INTEGER DEFAULT 0");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE settings ADD COLUMN whatsapp_message_language TEXT DEFAULT 'English'");
    } catch (_) {}
    final List<Map<String, dynamic>> maps = await db.query('settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      final s = SettingsModel.fromMap(maps.first);
      SettingsModel current = s;
      bool needSave = false;
      if (current.companyName == 'Embroidery Production Calculator' || current.companyName == 'OM Mavtar Group') {
        current = current.copyWith(companyName: 'OM MAVTAR GROUP');
        needSave = true;
      }
      if (current.appLanguage == 'en_gu' || current.appLanguage == 'en_hi' || current.appLanguage.isEmpty) {
        current = current.copyWith(appLanguage: 'en');
        needSave = true;
      }
      if (current.whatsappMessageLanguage == 'Both' || current.whatsappMessageLanguage.isEmpty) {
        current = current.copyWith(whatsappMessageLanguage: 'English');
        needSave = true;
      }
      if (needSave) {
        await saveSettings(current);
      }
      return current;
    }
    final defaultSettings = SettingsModel();
    final settingsMap = defaultSettings.toMap();
    settingsMap['id'] = 1;
    await db.insert('settings', settingsMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return defaultSettings;
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final db = await database;
    final map = settings.toMap();
    map['id'] = 1;
    await db.insert('settings', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Backup & Restore ---
  Future<String> exportBackupJson() async {
    final accounts = await getAccounts();
    final machines = await getMachines();
    final records = await getRecords();
    final materials = await getMaterialItems();
    final products = await getMaterialProducts();
    final suppliers = await getSuppliers();
    final deletedRecords = await getDeletedRecords();
    final employees = await getEmployees();
    final employeeUpads = await getEmployeeUpads();
    final whatsappLogs = await getWhatsAppLogs();
    final expenses = await getExpenses();
    final customers = await getCustomers();
    final customerBills = await getCustomerBills();
    final customerPayments = await getCustomerPayments();
    final settings = await getSettings();

    final data = {
      'app': 'OM MAVTAR GROUP',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'backup_timestamp': DateTime.now().toIso8601String(),
      'accounts': accounts.map((a) => a.toMap()).toList(),
      'machines': machines.map((m) => m.toMap()).toList(),
      'production_records': records.map((r) => r.toMap()).toList(),
      'records': records.map((r) => r.toMap()).toList(), // legacy key compatibility
      'material_items': materials.map((m) => m.toMap()).toList(),
      'materials': materials.map((m) => m.toMap()).toList(), // legacy key compatibility
      'material_products': products.map((p) => p.toMap()).toList(),
      'suppliers': suppliers.map((s) => s.toMap()).toList(),
      'deleted_records': deletedRecords.map((d) => d.toMap()).toList(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'employee_upads': employeeUpads.map((u) => u.toMap()).toList(),
      'whatsapp_logs': whatsappLogs.map((l) => l.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'customers': customers.map((c) => c.toMap()).toList(),
      'customer_bills': customerBills.map((b) => b.toMap()).toList(),
      'customer_payments': customerPayments.map((p) => p.toMap()).toList(),
      'settings': settings.toMap(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static const _validColumns = {
    'accounts': {'id', 'name', 'area', 'display_order', 'color_hex', 'is_active', 'notes'},
    'machines': {'id', 'machine_no', 'name', 'head_capacity', 'is_active', 'notes'},
    'production_records': {'id', 'date', 'created_at', 'design_no', 'machine_no', 'total_stitch', 'final_stitch', 'rate', 'amount', 'heads', 'final_amount', 'notes', 'account_name', 'shift'},
    'material_items': {'id', 'challan_no', 'supplier_name', 'date', 'category', 'product_name', 'item_type', 'mtr', 'mm', 'qty', 'rate', 'amount', 'used_qty', 'notes', 'paid_amount', 'payment_status', 'payment_date'},
    'material_products': {'id', 'name', 'category', 'default_rate', 'unit', 'default_mtr', 'default_mm', 'notes', 'is_active'},
    'suppliers': {'id', 'name', 'phone', 'city', 'gst_no', 'notes', 'is_active', 'created_at'},
    'deleted_records': {'id', 'record_type', 'record_title', 'record_subtitle', 'original_id', 'original_data', 'deleted_at', 'is_archived'},
    'employees': {'id', 'name', 'role', 'gender', 'phone', 'joining_date', 'monthly_salary', 'is_active', 'notes'},
    'employee_upads': {'id', 'employee_id', 'employee_name', 'amount', 'date', 'notes', 'is_settled'},
    'whatsapp_logs': {'id', 'employee_id', 'employee_name', 'recipient_phone', 'sender_phone', 'message', 'message_type', 'amount', 'created_at', 'status'},
    'expenses': {'id', 'date', 'category', 'amount', 'payment_mode', 'paid_to', 'notes', 'created_at'},
    'customers': {'id', 'name', 'phone', 'city', 'gst_no', 'notes', 'is_active', 'created_at'},
    'customer_bills': {'id', 'bill_no', 'customer_id', 'customer_name', 'date', 'total_amount', 'paid_amount', 'payment_status', 'payment_date', 'design_details', 'notes', 'created_at'},
    'customer_payments': {'id', 'bill_id', 'customer_id', 'customer_name', 'amount', 'date', 'payment_mode', 'notes', 'created_at'},
    'settings': {'id', 'company_name', 'operator_name', 'currency_symbol', 'stitch_divider', 'available_rates', 'available_heads', 'default_rate', 'default_heads', 'date_format', 'auto_refresh_seconds', 'is_dark_mode', 'theme_color_hex', 'employee_roles', 'sender_phone', 'whatsapp_auto_send', 'whatsapp_message_language', 'app_language', 'font_scale'},
  };

  static const _integerColumns = {
    'id',
    'display_order',
    'is_active',
    'head_capacity',
    'total_stitch',
    'heads',
    'original_id',
    'is_archived',
    'employee_id',
    'customer_id',
    'bill_id',
    'is_settled',
    'auto_refresh_seconds',
    'is_dark_mode',
    'default_heads',
    'whatsapp_auto_send',
  };

  static const _doubleColumns = {
    'final_stitch',
    'rate',
    'amount',
    'final_amount',
    'mtr',
    'mm',
    'qty',
    'used_qty',
    'paid_amount',
    'total_amount',
    'default_rate',
    'default_mtr',
    'default_mm',
    'monthly_salary',
    'stitch_divider',
    'font_scale',
  };

  static const _dateColumns = {
    'date',
    'joining_date',
    'created_at',
    'deleted_at',
    'payment_date',
  };

  static const Map<String, Map<String, String>> _columnAliases = {
    'accounts': {
      'account_name': 'name',
      'accountName': 'name',
      'title': 'name',
      'displayOrder': 'display_order',
      'order': 'display_order',
      'colorHex': 'color_hex',
      'color': 'color_hex',
      'isActive': 'is_active',
      'active': 'is_active',
    },
    'machines': {
      'machineNo': 'machine_no',
      'machine': 'machine_no',
      'code': 'machine_no',
      'machine_name': 'name',
      'machineName': 'name',
      'headCapacity': 'head_capacity',
      'heads': 'head_capacity',
      'total_heads': 'head_capacity',
      'totalHeads': 'head_capacity',
      'isActive': 'is_active',
      'active': 'is_active',
    },
    'production_records': {
      'designNo': 'design_no',
      'design': 'design_no',
      'design_number': 'design_no',
      'machineNo': 'machine_no',
      'machine': 'machine_no',
      'totalStitch': 'total_stitch',
      'stitches': 'total_stitch',
      'stitch': 'total_stitch',
      'finalStitch': 'final_stitch',
      'finalAmount': 'final_amount',
      'total_amount': 'final_amount',
      'totalAmount': 'final_amount',
      'accountName': 'account_name',
      'account': 'account_name',
      'khata': 'account_name',
      'category': 'account_name',
      'shiftName': 'shift',
      'head_count': 'heads',
      'headCount': 'heads',
    },
    'material_items': {
      'challanNo': 'challan_no',
      'challan': 'challan_no',
      'bill_no': 'challan_no',
      'billNo': 'challan_no',
      'bill': 'challan_no',
      'supplierName': 'supplier_name',
      'supplier': 'supplier_name',
      'vendor': 'supplier_name',
      'vendor_name': 'supplier_name',
      'vendorName': 'supplier_name',
      'productName': 'product_name',
      'product': 'product_name',
      'item_name': 'product_name',
      'itemName': 'product_name',
      'itemType': 'item_type',
      'type': 'item_type',
      'quantity': 'qty',
      'price': 'rate',
      'total': 'amount',
      'total_amount': 'amount',
      'totalAmount': 'amount',
      'usedQty': 'used_qty',
      'used': 'used_qty',
      'paymentStatus': 'payment_status',
      'status': 'payment_status',
      'paid_status': 'payment_status',
      'paymentDate': 'payment_date',
      'paid_date': 'payment_date',
      'paidDate': 'payment_date',
      'meter': 'mtr',
      'meters': 'mtr',
      'size_mm': 'mm',
      'sizeMm': 'mm',
    },
    'material_products': {
      'product_name': 'name',
      'productName': 'name',
      'title': 'name',
      'defaultRate': 'default_rate',
      'rate': 'default_rate',
      'price': 'default_rate',
      'defaultMtr': 'default_mtr',
      'mtr': 'default_mtr',
      'meter': 'default_mtr',
      'defaultMm': 'default_mm',
      'mm': 'default_mm',
      'size': 'default_mm',
      'isActive': 'is_active',
      'active': 'is_active',
    },
    'suppliers': {
      'supplier_name': 'name',
      'supplierName': 'name',
      'title': 'name',
      'vendor': 'name',
      'mobile': 'phone',
      'contact': 'phone',
      'phone_no': 'phone',
      'phoneNo': 'phone',
      'address': 'city',
      'location': 'city',
      'gstNo': 'gst_no',
      'gst': 'gst_no',
      'gstin': 'gst_no',
      'isActive': 'is_active',
      'active': 'is_active',
      'createdAt': 'created_at',
      'date': 'created_at',
    },
    'deleted_records': {
      'recordType': 'record_type',
      'recordTitle': 'record_title',
      'recordSubtitle': 'record_subtitle',
      'originalId': 'original_id',
      'originalData': 'original_data',
      'deletedAt': 'deleted_at',
      'isArchived': 'is_archived',
    },
    'employees': {
      'employee_name': 'name',
      'employeeName': 'name',
      'mobile': 'phone',
      'contact': 'phone',
      'joiningDate': 'joining_date',
      'join_date': 'joining_date',
      'monthlySalary': 'monthly_salary',
      'salary': 'monthly_salary',
      'isActive': 'is_active',
      'active': 'is_active',
    },
    'employee_upads': {
      'employeeId': 'employee_id',
      'employeeName': 'employee_name',
      'isSettled': 'is_settled',
      'settled': 'is_settled',
    },
    'whatsapp_logs': {
      'employeeId': 'employee_id',
      'employeeName': 'employee_name',
      'recipientPhone': 'recipient_phone',
      'senderPhone': 'sender_phone',
      'messageType': 'message_type',
      'createdAt': 'created_at',
    },
    'settings': {
      'companyName': 'company_name',
      'operatorName': 'operator_name',
      'currencySymbol': 'currency_symbol',
      'stitchDivider': 'stitch_divider',
      'availableRates': 'available_rates',
      'availableHeads': 'available_heads',
      'defaultRate': 'default_rate',
      'defaultHeads': 'default_heads',
      'dateFormat': 'date_format',
      'autoRefreshSeconds': 'auto_refresh_seconds',
      'autoRefreshIntervalSeconds': 'auto_refresh_seconds',
      'isDarkMode': 'is_dark_mode',
      'themeColorHex': 'theme_color_hex',
      'employeeRoles': 'employee_roles',
      'expenseCategories': 'expense_categories',
      'senderPhone': 'sender_phone',
      'whatsappAutoSend': 'whatsapp_auto_send',
      'whatsappMessageLanguage': 'whatsapp_message_language',
      'appLanguage': 'app_language',
      'fontScale': 'font_scale',
    },
  };

  static int _sanitizeInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is bool) return val ? 1 : 0;
    if (val is num) return val.toInt();
    final str = val.toString().trim().toLowerCase();
    if (str == 'true' || str == 'yes' || str == '1') return 1;
    if (str == 'false' || str == 'no' || str == '0') return 0;
    return int.tryParse(str) ?? (double.tryParse(str)?.toInt() ?? fallback);
  }

  static double _sanitizeDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    final str = val.toString().trim().replaceAll(',', '');
    return double.tryParse(str) ?? fallback;
  }

  static String _sanitizeString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    return val.toString().trim();
  }

  static String _sanitizeDate(dynamic val) {
    if (val == null) return DateTime.now().toIso8601String().split('T').first;
    String str = val.toString().trim();
    if (str.isEmpty) return DateTime.now().toIso8601String().split('T').first;
    if (str.contains('T')) {
      str = str.split('T').first;
    }
    // Check if dd-MM-yyyy or dd/MM/yyyy
    if (str.contains('-')) {
      final parts = str.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return str;
        } else if (parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    } else if (str.contains('/')) {
      final parts = str.split('/');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        } else if (parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    }
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return DateTime.now().toIso8601String().split('T').first;
  }

  Map<String, dynamic> _filterTableColumns(String table, Map<dynamic, dynamic> row) {
    final allowed = _validColumns[table] ?? {};
    final aliases = _columnAliases[table] ?? {};
    final filtered = <String, dynamic>{};

    for (final entry in row.entries) {
      final rawKey = entry.key.toString().trim();
      final key = aliases[rawKey] ?? rawKey;

      // STRICT VALIDATION: If not an allowed schema column, IGNORE IT COMPLETELY!
      if (!allowed.contains(key)) {
        continue;
      }

      final val = entry.value;

      // Type sanitization
      if (_integerColumns.contains(key)) {
        filtered[key] = _sanitizeInt(val);
      } else if (_doubleColumns.contains(key)) {
        filtered[key] = _sanitizeDouble(val);
      } else if (_dateColumns.contains(key)) {
        if (key == 'payment_date' && (val == null || val.toString().trim().isEmpty)) {
          filtered[key] = null;
        } else if (key == 'created_at' || key == 'deleted_at') {
          filtered[key] = val?.toString().trim();
        } else {
          filtered[key] = _sanitizeDate(val);
        }
      } else {
        filtered[key] = _sanitizeString(val);
      }
    }
    return filtered;
  }

  Future<int> _tableCount(DatabaseExecutor txn, String table) async {
    final res = await txn.rawQuery('SELECT COUNT(*) as count FROM $table');
    if (res.isEmpty) return 0;
    final val = res.first['count'];
    return (val is int) ? val : (int.tryParse(val.toString()) ?? 0);
  }

  Future<bool> isDatabaseEmpty() async {
    final db = await database;
    await _ensureMigration(db);
    final recCount = await _tableCount(db, 'production_records');
    final matCount = await _tableCount(db, 'material_items');
    final upadCount = await _tableCount(db, 'employee_upads');
    return recCount == 0 && matCount == 0 && upadCount == 0;
  }

  Future<void> restoreFromJson(String jsonContent, {bool merge = false}) async {
    final dynamic decoded = jsonDecode(jsonContent);
    final Map<String, dynamic> data;

    // Support root List export (legacy single-table backups or record arrays)
    if (decoded is List) {
      if (decoded.isNotEmpty && decoded.first is Map) {
        final first = decoded.first as Map;
        final hasMatKeys = first.containsKey('challan_no') ||
            first.containsKey('challanNo') ||
            first.containsKey('supplier_name') ||
            first.containsKey('supplierName') ||
            first.containsKey('item_type') ||
            first.containsKey('itemType');
        if (hasMatKeys) {
          data = {'material_items': decoded};
        } else {
          data = {'production_records': decoded};
        }
      } else {
        data = {'production_records': decoded};
      }
    } else if (decoded is Map) {
      data = Map<String, dynamic>.from(decoded);
    } else {
      throw const FormatException('Invalid backup file format: JSON root must be an Object or Array.');
    }

    final db = await database;

    await db.transaction((txn) async {
      // Check if system currently has any existing transactional records
      final recCount = await _tableCount(txn, 'production_records');
      final matCount = await _tableCount(txn, 'material_items');
      final upadCount = await _tableCount(txn, 'employee_upads');
      final bool isSystemEmpty = (recCount == 0 && matCount == 0 && upadCount == 0);

      // CRITICAL FIX: If the system has NO data, ALWAYS perform a direct, full restore
      // regardless of whether merge was requested! This sets the full backup data directly into the system.
      final bool effectiveMerge = merge && !isSystemEmpty;

      if (!effectiveMerge) {
        await txn.delete('accounts');
        await txn.delete('machines');
        await txn.delete('production_records');
        await txn.delete('material_items');
        await txn.delete('material_products');
        await txn.delete('suppliers');
        await txn.delete('deleted_records');
        await txn.delete('employees');
        await txn.delete('employee_upads');
        await txn.delete('whatsapp_logs');
        await txn.delete('expenses');
        await txn.delete('customers');
        await txn.delete('customer_bills');
        await txn.delete('customer_payments');
        await txn.delete('settings');
      }

      // 1. Accounts
      final accountsList = data['accounts'] ?? data['Accounts'];
      if (accountsList is List && accountsList.isNotEmpty) {
        for (final a in accountsList) {
          if (a is Map) {
            final row = _filterTableColumns('accounts', a);
            final name = (row['name'] as String? ?? '').trim();
            if (name.isEmpty) continue; // Skip invalid row
            if (name == '250 Area Khatu') row['name'] = '250 Area';
            if (name == '400 Area Khatu') row['name'] = '400 Area';
            if (name == 'Beads Khatu') row['name'] = 'Beads';
            row.putIfAbsent('display_order', () => 0);
            row.putIfAbsent('color_hex', () => '#2563EB');
            row.putIfAbsent('is_active', () => 1);
            row.putIfAbsent('notes', () => '');

            if (effectiveMerge) {
              final existing = await txn.query('accounts', where: 'name = ?', whereArgs: [row['name']]);
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('accounts', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('accounts', insertMap);
              }
            } else {
              await txn.insert('accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Ensure starter accounts exist if none were imported
      final accCount = await _tableCount(txn, 'accounts');
      if (accCount == 0) {
        for (final a in SampleData.getInitialAccounts()) {
          await txn.insert('accounts', _filterTableColumns('accounts', a.toMap()), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 2. Machines
      final machinesList = data['machines'] ?? data['Machines'];
      if (machinesList is List && machinesList.isNotEmpty) {
        for (final m in machinesList) {
          if (m is Map) {
            final row = _filterTableColumns('machines', m);
            final machineNo = (row['machine_no'] as String? ?? '').trim();
            if (machineNo.isEmpty) continue; // Skip invalid row
            row['machine_no'] = machineNo;
            final mName = (row['name'] as String? ?? '').trim();
            row['name'] = mName.isEmpty ? machineNo : mName;
            final heads = row['head_capacity'] as int? ?? 12;
            row['head_capacity'] = heads <= 0 ? 12 : heads;
            row.putIfAbsent('is_active', () => 1);

            if (effectiveMerge) {
              final existing = await txn.query('machines', where: 'machine_no = ?', whereArgs: [machineNo]);
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('machines', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('machines', insertMap);
              }
            } else {
              await txn.insert('machines', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Ensure factory machines exist if none were imported
      final machineCount = await _tableCount(txn, 'machines');
      if (machineCount == 0) {
        for (final m in SampleData.getMachines()) {
          await txn.insert('machines', _filterTableColumns('machines', m.toMap()), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 3. Production Records
      final recordsList = data['production_records'] ??
          data['records'] ??
          data['ProductionRecords'] ??
          data['productionRecords'];
      if (recordsList is List) {
        for (final r in recordsList) {
          if (r is Map) {
            final row = _filterTableColumns('production_records', r);
            final designNo = (row['design_no'] as String? ?? '').trim();
            final totalStitch = row['total_stitch'] as int? ?? 0;
            final mNo = (row['machine_no'] as String? ?? '').trim();

            // Skip empty/corrupted rows
            if (designNo.isEmpty && totalStitch == 0 && mNo.isEmpty) {
              continue;
            }

            row['design_no'] = designNo.isEmpty ? '0' : designNo;
            row['machine_no'] = mNo.isEmpty ? 'M-01' : mNo;
            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);

            final heads = (row['heads'] as int? ?? 0) <= 0 ? 12 : (row['heads'] as int);
            row['heads'] = heads;

            final rate = (row['rate'] as double? ?? 0.0) <= 0.0 ? 1.25 : (row['rate'] as double);
            row['rate'] = rate;

            row.putIfAbsent('total_stitch', () => totalStitch);

            // Recompute derived fields if missing or zero
            final curTotal = row['total_stitch'] as int? ?? 0;
            final curFinalStitch = (row['final_stitch'] as double? ?? 0.0) <= 0.0 ? (curTotal / 1000.0) : (row['final_stitch'] as double);
            row['final_stitch'] = curFinalStitch;

            final curAmount = (row['amount'] as double? ?? 0.0) <= 0.0 ? (curFinalStitch * rate) : (row['amount'] as double);
            row['amount'] = curAmount;

            final curFinalAmount = (row['final_amount'] as double? ?? 0.0) <= 0.0 ? (curAmount * heads) : (row['final_amount'] as double);
            row['final_amount'] = curFinalAmount;

            // Normalize account_name
            var acc = (row['account_name'] as String? ?? '').trim();
            if (acc == '250 Area Khatu' || acc.isEmpty) acc = '250 Area';
            if (acc == '400 Area Khatu') acc = '400 Area';
            if (acc == 'Beads Khatu') acc = 'Beads';
            row['account_name'] = acc;

            // Normalize shift
            var shift = (row['shift'] as String? ?? '').trim();
            if (shift.isEmpty || shift.toLowerCase() == 'day') {
              shift = 'Day';
            } else if (shift.toLowerCase() == 'night') {
              shift = 'Night';
            }
            row['shift'] = shift;

            if (effectiveMerge) {
              // Smart merge: check if a matching batch already exists
              final existing = await txn.query(
                'production_records',
                where: 'date = ? AND machine_no = ? AND design_no = ? AND shift = ? AND total_stitch = ?',
                whereArgs: [row['date'], row['machine_no'], row['design_no'], row['shift'], row['total_stitch']],
              );
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('production_records', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('production_records', insertMap);
              }
            } else {
              await txn.insert('production_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // 4. Material Items
      final materialsList = data['material_items'] ??
          data['materials'] ??
          data['MaterialItems'] ??
          data['materialItems'];
      if (materialsList is List) {
        for (final mat in materialsList) {
          if (mat is Map) {
            final row = _filterTableColumns('material_items', mat);
            final itemType = (row['item_type'] as String? ?? '').trim();
            final productName = (row['product_name'] as String? ?? '').trim();
            final qty = row['qty'] as double? ?? 0.0;
            final challan = (row['challan_no'] as String? ?? '').trim();

            // Skip completely empty/corrupted rows
            if (itemType.isEmpty && productName.isEmpty && qty == 0.0 && challan.isEmpty) {
              continue;
            }

            // Normalize category
            var cat = (row['category'] as String? ?? '').trim();
            final catLower = cat.toLowerCase();
            if (catLower == 'daga' || catLower == 'dhaga' || catLower == 'thread') {
              cat = 'Thread';
            } else if (catLower == 'beads') {
              cat = 'Beads';
            } else {
              cat = 'Sequence';
            }
            row['category'] = cat;

            // Ensure product_name and item_type
            if (itemType.isEmpty && productName.isNotEmpty) {
              row['item_type'] = productName;
            } else if (itemType.isEmpty) {
              row['item_type'] = 'Regular';
            }

            if (productName.isEmpty && itemType.isNotEmpty) {
              row['product_name'] = itemType;
            } else if (productName.isEmpty) {
              row['product_name'] = 'Material Item';
            }

            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('supplier_name', () => '');
            row.putIfAbsent('challan_no', () => '');
            row.putIfAbsent('mtr', () => 0.0);
            row.putIfAbsent('mm', () => 0.0);
            row.putIfAbsent('qty', () => 0.0);
            row.putIfAbsent('rate', () => 0.0);

            final curQty = row['qty'] as double? ?? 0.0;
            final curRate = row['rate'] as double? ?? 0.0;
            final curAmt = row['amount'] as double? ?? 0.0;
            if (curAmt <= 0.0 && curQty > 0.0 && curRate > 0.0) {
              row['amount'] = curQty * curRate;
            } else {
              row.putIfAbsent('amount', () => 0.0);
            }
            row.putIfAbsent('used_qty', () => 0.0);
            row.putIfAbsent('notes', () => '');

            // Backward Compatibility: normalize payment_status for old backups
            var pStatus = (row['payment_status'] as String? ?? '').trim();
            final pDate = (row['payment_date'] as String? ?? '').trim();
            if (pStatus.isEmpty) {
              pStatus = pDate.isNotEmpty ? 'Paid' : 'Pending';
            } else if (pStatus.toLowerCase() == 'paid') {
              pStatus = 'Paid';
            } else {
              pStatus = 'Pending';
            }
            row['payment_status'] = pStatus;
            final finalAmt = row['amount'] as double? ?? 0.0;
            if (!row.containsKey('paid_amount') || row['paid_amount'] == null) {
              row['paid_amount'] = pStatus == 'Paid' ? finalAmt : 0.0;
            }

            if (effectiveMerge) {
              final existing = await txn.query(
                'material_items',
                where: 'challan_no = ? AND supplier_name = ? AND product_name = ? AND date = ?',
                whereArgs: [row['challan_no'], row['supplier_name'], row['product_name'], row['date']],
              );
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('material_items', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('material_items', insertMap);
              }
            } else {
              await txn.insert('material_items', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // 5. Material Products (Master)
      final productsList = data['material_products'] ??
          data['materialProducts'] ??
          data['products'] ??
          data['Products'];
      if (productsList is List && productsList.isNotEmpty) {
        for (final p in productsList) {
          if (p is Map) {
            final row = _filterTableColumns('material_products', p);
            final name = (row['name'] as String? ?? '').trim();
            if (name.isEmpty) continue; // Skip blank product
            row['name'] = name;

            var cat = (row['category'] as String? ?? '').trim();
            final catLower = cat.toLowerCase();
            if (catLower == 'daga' || catLower == 'dhaga' || catLower == 'thread') {
              cat = 'Thread';
            } else if (catLower == 'beads') {
              cat = 'Beads';
            } else {
              cat = 'Sequence';
            }
            row['category'] = cat;

            row.putIfAbsent('unit', () => 'piece');
            row.putIfAbsent('default_rate', () => 0.0);
            row.putIfAbsent('default_mtr', () => 0.0);
            row.putIfAbsent('default_mm', () => 0.0);
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('is_active', () => 1);

            if (effectiveMerge) {
              final existing = await txn.query('material_products', where: 'name = ?', whereArgs: [name]);
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('material_products', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('material_products', insertMap);
              }
            } else {
              await txn.insert('material_products', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Ensure master products exist if none were imported
      final productCount = await _tableCount(txn, 'material_products');
      if (productCount == 0) {
        for (final p in SampleData.getInitialMaterialProducts()) {
          final map = p.toMap()..remove('id');
          await txn.insert('material_products', _filterTableColumns('material_products', map), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 6. Suppliers (Master)
      final suppliersList = data['suppliers'] ?? data['Suppliers'];
      if (suppliersList is List && suppliersList.isNotEmpty) {
        for (final s in suppliersList) {
          if (s is Map) {
            final row = _filterTableColumns('suppliers', s);
            final name = (row['name'] as String? ?? '').trim();
            if (name.isEmpty) continue; // Skip blank supplier
            row['name'] = name;
            row.putIfAbsent('phone', () => '');
            row.putIfAbsent('city', () => 'Surat');
            row.putIfAbsent('gst_no', () => '');
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('is_active', () => 1);
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());

            if (effectiveMerge) {
              final existing = await txn.query('suppliers', where: 'name = ?', whereArgs: [name]);
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('suppliers', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('suppliers', insertMap);
              }
            } else {
              await txn.insert('suppliers', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // Ensure master suppliers exist if none were imported
      final suppCount = await _tableCount(txn, 'suppliers');
      if (suppCount == 0) {
        for (final s in SampleData.getInitialSuppliers()) {
          final map = s.toMap()..remove('id');
          await txn.insert('suppliers', _filterTableColumns('suppliers', map), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 7. Deleted Records (Recycle Bin)
      final deletedList = data['deleted_records'] ??
          data['deletedRecords'] ??
          data['recycle_bin'];
      if (deletedList is List) {
        for (final d in deletedList) {
          if (d is Map) {
            final row = _filterTableColumns('deleted_records', d);
            final recTitle = (row['record_title'] as String? ?? '').trim();
            if (recTitle.isEmpty) continue;
            row.putIfAbsent('record_type', () => 'production_record');
            row.putIfAbsent('original_data', () => '{}');
            row.putIfAbsent('deleted_at', () => DateTime.now().toIso8601String());
            row.putIfAbsent('is_archived', () => 0);
            await txn.insert('deleted_records', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      // 8. Settings
      final defaultSettingsMap = SettingsModel().toMap();
      final mergedSettings = Map<String, dynamic>.from(defaultSettingsMap);

      final settingsObj = data['settings'] ?? data['Settings'];
      if (settingsObj is Map) {
        final smap = _filterTableColumns('settings', settingsObj);
        mergedSettings.addAll(smap);
      }

      // Modernize company name if default legacy
      final compName = mergedSettings['company_name'] as String? ?? '';
      if (compName == 'Embroidery Production Calculator' || compName == 'Om Mavtar Group' || compName.isEmpty) {
        mergedSettings['company_name'] = 'OM MAVTAR GROUP';
      }
      mergedSettings['id'] = 1;
      if (mergedSettings['app_language'] == null ||
          (mergedSettings['app_language'] as String).isEmpty ||
          mergedSettings['app_language'] == 'en_gu' ||
          mergedSettings['app_language'] == 'en_hi') {
        mergedSettings['app_language'] = 'en';
      }
      if (mergedSettings['font_scale'] == null || (mergedSettings['font_scale'] as num) <= 0) {
        mergedSettings['font_scale'] = 1.0;
      }

      if (!effectiveMerge) {
        await txn.insert('settings', mergedSettings, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await txn.update('settings', mergedSettings, where: 'id = 1');
      }

      // 9. Employees
      final employeesList = data['employees'] ?? data['Employees'];
      if (employeesList is List) {
        for (final e in employeesList) {
          if (e is Map) {
            final row = _filterTableColumns('employees', e);
            final name = (row['name'] as String? ?? '').trim();
            if (name.isEmpty) continue;
            row['name'] = name;
            row.putIfAbsent('role', () => 'Operator');
            row.putIfAbsent('gender', () => 'Male');
            row.putIfAbsent('phone', () => '');
            row.putIfAbsent('joining_date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('monthly_salary', () => 0.0);
            row.putIfAbsent('is_active', () => 1);
            row.putIfAbsent('notes', () => '');

            if (effectiveMerge) {
              final existing = await txn.query('employees', where: 'name = ?', whereArgs: [name]);
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('employees', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('employees', insertMap);
              }
            } else {
              await txn.insert('employees', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // 10. Employee Upads
      final upadsList = data['employee_upads'] ??
          data['employeeUpads'] ??
          data['upads'] ??
          data['Upads'];
      if (upadsList is List) {
        for (final u in upadsList) {
          if (u is Map) {
            final row = _filterTableColumns('employee_upads', u);
            final empName = (row['employee_name'] as String? ?? '').trim();
            final amt = row['amount'] as double? ?? 0.0;
            if (empName.isEmpty && amt <= 0.0) continue;
            row['employee_name'] = empName.isEmpty ? 'Staff' : empName;
            row.putIfAbsent('employee_id', () => 0);
            row.putIfAbsent('amount', () => amt);
            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('is_settled', () => 0);

            if (effectiveMerge) {
              final existing = await txn.query(
                'employee_upads',
                where: 'employee_name = ? AND date = ? AND amount = ?',
                whereArgs: [row['employee_name'], row['date'], row['amount']],
              );
              if (existing.isNotEmpty) {
                final existingId = existing.first['id'];
                final updateMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.update('employee_upads', updateMap, where: 'id = ?', whereArgs: [existingId]);
              } else {
                final insertMap = Map<String, dynamic>.from(row)..remove('id');
                await txn.insert('employee_upads', insertMap);
              }
            } else {
              await txn.insert('employee_upads', row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      // 11. WhatsApp Message Logs
      final logsList = data['whatsapp_logs'] ?? data['whatsappLogs'];
      if (logsList is List) {
        for (final l in logsList) {
          if (l is Map) {
            final row = _filterTableColumns('whatsapp_logs', l);
            final empName = (row['employee_name'] as String? ?? '').trim();
            final msg = (row['message'] as String? ?? '').trim();
            if (empName.isEmpty && msg.isEmpty) continue;
            row['employee_name'] = empName.isEmpty ? 'Staff' : empName;
            row.putIfAbsent('recipient_phone', () => '');
            row.putIfAbsent('sender_phone', () => '');
            row.putIfAbsent('message', () => msg);
            row.putIfAbsent('message_type', () => 'upad_receipt');
            row.putIfAbsent('amount', () => 0.0);
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());
            row.putIfAbsent('status', () => 'Sent');
            await txn.insert('whatsapp_logs', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      // 12. Expenses
      final expensesList = data['expenses'] ?? data['Expenses'];
      if (expensesList is List) {
        for (final ex in expensesList) {
          if (ex is Map) {
            final row = _filterTableColumns('expenses', ex);
            final cat = (row['category'] as String? ?? '').trim();
            if (cat.isEmpty) continue;
            row['category'] = cat.toUpperCase();
            row.putIfAbsent('amount', () => 0.0);
            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('payment_mode', () => 'Cash');
            row.putIfAbsent('paid_to', () => '');
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());
            await txn.insert('expenses', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      // 13. Customers
      final customersList = data['customers'] ?? data['Customers'];
      if (customersList is List) {
        for (final c in customersList) {
          if (c is Map) {
            final row = _filterTableColumns('customers', c);
            final name = (row['name'] as String? ?? '').trim();
            if (name.isEmpty) continue;
            row['name'] = name;
            row.putIfAbsent('phone', () => '');
            row.putIfAbsent('city', () => '');
            row.putIfAbsent('gst_no', () => '');
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('is_active', () => 1);
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());
            await txn.insert('customers', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      // 14. Customer Bills
      final billsList = data['customer_bills'] ?? data['customerBills'];
      if (billsList is List) {
        for (final b in billsList) {
          if (b is Map) {
            final row = _filterTableColumns('customer_bills', b);
            final billNo = (row['bill_no'] as String? ?? '').trim();
            final cName = (row['customer_name'] as String? ?? '').trim();
            if (billNo.isEmpty && cName.isEmpty) continue;
            row.putIfAbsent('total_amount', () => 0.0);
            row.putIfAbsent('paid_amount', () => 0.0);
            row.putIfAbsent('payment_status', () => 'Unpaid');
            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('design_details', () => '');
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());
            await txn.insert('customer_bills', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      // 15. Customer Payments
      final paymentsList = data['customer_payments'] ?? data['customerPayments'];
      if (paymentsList is List) {
        for (final p in paymentsList) {
          if (p is Map) {
            final row = _filterTableColumns('customer_payments', p);
            final cName = (row['customer_name'] as String? ?? '').trim();
            if (cName.isEmpty) continue;
            row.putIfAbsent('amount', () => 0.0);
            row.putIfAbsent('date', () => DateTime.now().toIso8601String().split('T').first);
            row.putIfAbsent('payment_mode', () => 'Cash');
            row.putIfAbsent('notes', () => '');
            row.putIfAbsent('created_at', () => DateTime.now().toIso8601String());
            await txn.insert('customer_payments', row, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }

  Future<void> resetToSampleData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('accounts');
      await txn.delete('machines');
      await txn.delete('production_records');
      await txn.delete('material_items');
      await txn.delete('material_products');
      await txn.delete('suppliers');
      await txn.delete('deleted_records');
      await txn.delete('employees');
      await txn.delete('employee_upads');
      await txn.delete('expenses');
      await txn.delete('customers');
      await txn.delete('customer_bills');
      await txn.delete('customer_payments');
      await txn.delete('settings');

      for (final account in SampleData.getInitialAccounts()) {
        await txn.insert('accounts', account.toMap());
      }

      for (final machine in SampleData.getMachines()) {
        await txn.insert('machines', machine.toMap());
      }

      for (final product in SampleData.getInitialMaterialProducts()) {
        final map = product.toMap()..remove('id');
        await txn.insert('material_products', map);
      }

      for (final supplier in SampleData.getInitialSuppliers()) {
        final map = supplier.toMap()..remove('id');
        await txn.insert('suppliers', map);
      }

      // Production records & material items start clean (no dummy data)

      final defaultSettings = SettingsModel();
      final settingsMap = defaultSettings.toMap()..['id'] = 1;
      await txn.insert('settings', settingsMap);
    });
  }

  /// Explicit purge method to eliminate all dummy data from tables
  Future<void> purgeAllDummyData() async {
    final db = await database;
    await _ensureMigration(db);
    await db.transaction((txn) async {
      await txn.execute('''
        DELETE FROM production_records 
        WHERE design_no IN (
          '11131 (24H+26H)',
          '11010 (30,26,40,38)',
          '724 (38+40)',
          '11010 (36,34,32,30)',
          '257 TOP.DH',
          '10151 KALI'
        )
        OR design_no LIKE 'D0%'
        OR notes LIKE '%Dahao MATE-A8 screen%'
        OR notes LIKE '%OM MAVTAR memo%';
      ''');

      await txn.execute('''
        DELETE FROM material_items 
        WHERE challan_no IN ('1086', 'CH-4091', 'CH-4120', 'BD-882', 'BD-895')
           OR notes LIKE '%Khushi Fashion, Shubham Ind.%'
           OR notes LIKE '%Surat Zari & Thread Mills%';
      ''');
    });
  }

  // --- Deleted Records (Recycle Bin) Operations ---
  Future<List<DeletedRecordItem>> getDeletedRecords({
    String? recordType,
    String? searchQuery,
    bool? isArchived,
  }) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (recordType != null && recordType.isNotEmpty && recordType != 'All') {
      whereClauses.add('record_type = ?');
      whereArgs.add(recordType);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(record_title) LIKE ? OR LOWER(record_subtitle) LIKE ?)');
      whereArgs.addAll([query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'deleted_records',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'deleted_at DESC, id DESC',
    );
    return maps.map((m) => DeletedRecordItem.fromMap(m)).toList();
  }

  Future<List<DeletedRecordItem>> getArchivedRecords({
    String? recordType,
    String? searchQuery,
  }) async {
    return [];
  }

  Future<int> insertDeletedRecord(DeletedRecordItem item) async {
    final db = await database;
    await _ensureMigration(db);
    final map = item.toMap()..remove('id');
    return await db.insert('deleted_records', map);
  }

  /// Permanent hard delete of a deleted record from Recycle Bin - nowhere stored
  Future<int> deleteDeletedRecord(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete(
      'deleted_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanent hard clear of all Recycle Bin records - nowhere stored
  Future<int> clearAllDeletedRecords() async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('deleted_records');
  }

  Future<bool> restoreDeletedRecord(int id) async {
    final db = await database;
    await _ensureMigration(db);
    final List<Map<String, dynamic>> maps = await db.query(
      'deleted_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return false;

    final item = DeletedRecordItem.fromMap(maps.first);
    final dataMap = jsonDecode(item.originalData) as Map<String, dynamic>;

    await db.transaction((txn) async {
      switch (item.recordType) {
        case 'production_record':
          final map = Map<String, dynamic>.from(dataMap)..remove('id');
          await txn.insert('production_records', map);
          break;
        case 'material_item':
          final map = Map<String, dynamic>.from(dataMap)..remove('id');
          await txn.insert('material_items', map);
          break;
        case 'machine':
          await txn.insert('machines', dataMap, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
        case 'account':
          await txn.insert('accounts', dataMap, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
        case 'material_product':
          final map = Map<String, dynamic>.from(dataMap)..remove('id');
          await txn.insert('material_products', map);
          break;
        case 'supplier':
          await txn.insert('suppliers', dataMap, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
        case 'employee':
          await txn.insert('employees', dataMap, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
        case 'employee_upad':
          await txn.insert('employee_upads', dataMap, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
      }
      await txn.delete('deleted_records', where: 'id = ?', whereArgs: [id]);
    });
    return true;
  }

  Future<int> restoreAllDeletedRecords() async {
    final db = await database;
    await _ensureMigration(db);
    final all = await getDeletedRecords();
    int count = 0;
    for (final item in all) {
      if (item.id != null) {
        final ok = await restoreDeletedRecord(item.id!);
        if (ok) count++;
      }
    }
    return count;
  }

  // --- Material & Stock Operations (Daga, Sequence, Beads) ---
  Future<List<MaterialItem>> getMaterialItems({String? category, String? searchQuery}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All' && category != 'All Material') {
      final catLower = category.trim().toLowerCase();
      if (catLower == 'dhaga' || catLower == 'daga' || catLower == 'thread') {
        whereClauses.add('(LOWER(category) = ? OR LOWER(category) = ? OR LOWER(category) = ?)');
        whereArgs.addAll(['dhaga', 'daga', 'thread']);
      } else {
        whereClauses.add('category = ?');
        whereArgs.add(category);
      }
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(product_name) LIKE ? OR LOWER(challan_no) LIKE ? OR LOWER(supplier_name) LIKE ? OR LOWER(item_type) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'material_items',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => MaterialItem.fromMap(m)).toList();
  }

  Future<int> insertMaterialItem(MaterialItem item) async {
    final db = await database;
    await _ensureMigration(db);
    final map = item.toMap()..remove('id');
    return await db.insert('material_items', map);
  }

  Future<List<int>> insertMaterialItems(List<MaterialItem> items) async {
    final db = await database;
    await _ensureMigration(db);
    final batch = db.batch();
    for (final item in items) {
      final map = item.toMap()..remove('id');
      batch.insert('material_items', map);
    }
    final results = await batch.commit();
    return results.cast<int>();
  }

  Future<int> updateMaterialItem(MaterialItem item) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'material_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMaterialItem(int id) async {
    final db = await database;
    return await db.delete('material_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> recordMaterialUsage(int id, double addedUsedQty) async {
    final db = await database;
    await _ensureMigration(db);
    final List<Map<String, dynamic>> maps = await db.query('material_items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return 0;
    final current = MaterialItem.fromMap(maps.first);
    final newUsed = (current.usedQty + addedUsedQty).clamp(0.0, current.qty);
    return await db.update(
      'material_items',
      {'used_qty': newUsed},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateMaterialItemPaymentStatus(int id, String status, [DateTime? paymentDate]) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'material_items',
      {
        'payment_status': status,
        'payment_date': (paymentDate ?? (status.toLowerCase() == 'paid' ? DateTime.now() : null))?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateChallanPaymentStatus(String challanNo, String supplierName, String status, [DateTime? paymentDate]) async {
    final db = await database;
    await _ensureMigration(db);
    final paymentDateStr = (paymentDate ?? (status.toLowerCase() == 'paid' ? DateTime.now() : null))?.toIso8601String();
    return await db.update(
      'material_items',
      {
        'payment_status': status,
        'payment_date': paymentDateStr,
      },
      where: 'challan_no = ? AND supplier_name = ?',
      whereArgs: [challanNo, supplierName],
    );
  }

  Future<int> updateSupplierAllPaymentStatus(String supplierName, String status, [DateTime? paymentDate]) async {
    final db = await database;
    await _ensureMigration(db);
    final paymentDateStr = (paymentDate ?? (status.toLowerCase() == 'paid' ? DateTime.now() : null))?.toIso8601String();
    return await db.update(
      'material_items',
      {
        'payment_status': status,
        'payment_date': paymentDateStr,
      },
      where: 'supplier_name = ?',
      whereArgs: [supplierName],
    );
  }

  // --- Material Product Master Operations ---
  Future<List<MaterialProduct>> getMaterialProducts({String? category, String? searchQuery}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = ['is_active = 1'];
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All' && category != 'All Material') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(name) LIKE ? OR LOWER(unit) LIKE ? OR LOWER(notes) LIKE ?)');
      whereArgs.addAll([query, query, query]);
    }

    final where = whereClauses.join(' AND ');
    final List<Map<String, dynamic>> maps = await db.query(
      'material_products',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'category ASC, name ASC',
    );
    return maps.map((m) => MaterialProduct.fromMap(m)).toList();
  }

  Future<int> insertMaterialProduct(MaterialProduct product) async {
    final db = await database;
    await _ensureMigration(db);
    final map = product.toMap()..remove('id');
    return await db.insert('material_products', map);
  }

  Future<int> updateMaterialProduct(MaterialProduct product) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'material_products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteMaterialProduct(int id) async {
    final db = await database;
    return await db.delete('material_products', where: 'id = ?', whereArgs: [id]);
  }

  // --- Supplier Operations ---
  Future<List<Supplier>> getSuppliers({String? searchQuery, bool? activeOnly}) async {
    final db = await database;
    await _ensureMigration(db);

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (activeOnly == true) {
      whereClauses.add('is_active = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(name) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(city) LIKE ? OR LOWER(notes) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    await _ensureMigration(db);
    final map = supplier.toMap()..remove('id');
    return await db.insert('suppliers', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Employee & Upad Operations ---
  Future<List<EmployeeModel>> getEmployees({bool? activeOnly, String? searchQuery}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (activeOnly == true) {
      whereClauses.add('is_active = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(name) LIKE ? OR LOWER(role) LIKE ? OR LOWER(phone) LIKE ?)');
      whereArgs.addAll([query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
    return maps.map((e) => EmployeeModel.fromMap(e)).toList();
  }

  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await database;
    await _ensureMigration(db);
    final map = employee.toMap()..remove('id');
    return await db.insert('employees', map);
  }

  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    await _ensureMigration(db);
    await db.delete('employee_upads', where: 'employee_id = ?', whereArgs: [id]);
    return await db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EmployeeUpadModel>> getEmployeeUpads({int? employeeId, bool? unsettledOnly}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (employeeId != null) {
      whereClauses.add('employee_id = ?');
      whereArgs.add(employeeId);
    }
    if (unsettledOnly == true) {
      whereClauses.add('is_settled = 0');
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'employee_upads',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((u) => EmployeeUpadModel.fromMap(u)).toList();
  }

  Future<int> insertEmployeeUpad(EmployeeUpadModel upad) async {
    final db = await database;
    await _ensureMigration(db);
    final map = upad.toMap()..remove('id');
    return await db.insert('employee_upads', map);
  }

  Future<int> updateEmployeeUpad(EmployeeUpadModel upad) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update(
      'employee_upads',
      upad.toMap(),
      where: 'id = ?',
      whereArgs: [upad.id],
    );
  }

  Future<int> deleteEmployeeUpad(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('employee_upads', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> settleEmployeeUpads(int employeeId, {double? carryForwardAmount, String? carryForwardNotes}) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.transaction((txn) async {
      final updated = await txn.update(
        'employee_upads',
        {'is_settled': 1},
        where: 'employee_id = ? AND is_settled = 0',
        whereArgs: [employeeId],
      );

      if (carryForwardAmount != null && carryForwardAmount > 0) {
        final now = DateTime.now();
        final empRes = await txn.query('employees', columns: ['name'], where: 'id = ?', whereArgs: [employeeId]);
        final empName = empRes.isNotEmpty ? (empRes.first['name'] as String? ?? 'Employee') : 'Employee';
        await txn.insert('employee_upads', {
          'employee_id': employeeId,
          'employee_name': empName,
          'amount': carryForwardAmount,
          'notes': carryForwardNotes ?? 'Previous Month Excess Advance Carry-Forward',
          'date': now.toIso8601String().split('T').first,
          'is_settled': 0,
        });
      }
      return updated;
    });
  }

  // --- WhatsApp Logs Operations ---
  Future<List<WhatsAppLogModel>> getWhatsAppLogs({
    int? employeeId,
    String? searchQuery,
    int limit = 500,
  }) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (employeeId != null) {
      whereClauses.add('employee_id = ?');
      whereArgs.add(employeeId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add(
        '(LOWER(employee_name) LIKE ? OR LOWER(recipient_phone) LIKE ? OR LOWER(sender_phone) LIKE ? OR LOWER(message) LIKE ?)',
      );
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'whatsapp_logs',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return maps.map((l) => WhatsAppLogModel.fromMap(l)).toList();
  }

  Future<int> insertWhatsAppLog(WhatsAppLogModel log) async {
    final db = await database;
    await _ensureMigration(db);
    final map = log.toMap()..remove('id');
    return await db.insert('whatsapp_logs', map);
  }

  Future<int> deleteWhatsAppLog(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('whatsapp_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllWhatsAppLogs() async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('whatsapp_logs');
  }

  // --- Material Challan Partial & Full Payment Operations ---
  Future<void> recordChallanPayment({
    required String challanNo,
    required double paymentAmount,
    DateTime? paymentDate,
    String? notes,
  }) async {
    final db = await database;
    await _ensureMigration(db);
    final date = paymentDate ?? DateTime.now();
    final dateStr = date.toIso8601String();

    final List<Map<String, dynamic>> items = await db.query(
      'material_items',
      where: 'challan_no = ?',
      whereArgs: [challanNo],
      orderBy: 'id ASC',
    );

    if (items.isEmpty) return;

    double remainingToAllocate = paymentAmount;

    for (final map in items) {
      final id = map['id'] as int;
      final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
      final currentPaid = (map['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final itemRemaining = (amount - currentPaid).clamp(0.0, double.infinity);

      if (itemRemaining <= 0) continue;

      final allocate = remainingToAllocate > itemRemaining ? itemRemaining : remainingToAllocate;
      final newPaid = (currentPaid + allocate).clamp(0.0, amount);
      final newStatus = newPaid >= amount ? 'Paid' : (newPaid > 0 ? 'Partial' : 'Pending');

      await db.update(
        'material_items',
        {
          'paid_amount': newPaid,
          'payment_status': newStatus,
          'payment_date': dateStr,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      remainingToAllocate -= allocate;
      if (remainingToAllocate <= 0) break;
    }
  }

  // --- Expenses Operations ---
  Future<List<ExpenseModel>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (category != null && category.trim().isNotEmpty && category != 'ALL') {
      whereClauses.add('UPPER(category) = ?');
      whereArgs.add(category.trim().toUpperCase());
    }

    if (startDate != null) {
      final sStr = startDate.toIso8601String().split('T').first;
      whereClauses.add('date >= ?');
      whereArgs.add(sStr);
    }

    if (endDate != null) {
      final eStr = endDate.toIso8601String().split('T').first;
      whereClauses.add('date <= ?');
      whereArgs.add(eStr);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(category) LIKE ? OR LOWER(paid_to) LIKE ? OR LOWER(notes) LIKE ? OR LOWER(payment_mode) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await database;
    await _ensureMigration(db);
    final map = expense.toMap()..remove('id');
    return await db.insert('expenses', map);
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- Customer / Party Operations ---
  Future<List<CustomerModel>> getCustomers({bool? activeOnly, String? searchQuery}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (activeOnly == true) {
      whereClauses.add('is_active = 1');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(name) LIKE ? OR LOWER(phone) LIKE ? OR LOWER(city) LIKE ? OR LOWER(gst_no) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
    return maps.map((c) => CustomerModel.fromMap(c)).toList();
  }

  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await database;
    await _ensureMigration(db);
    final map = customer.toMap()..remove('id');
    return await db.insert('customers', map);
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Customer Bills Operations ---
  Future<List<CustomerBillModel>> getCustomerBills({
    int? customerId,
    String? status,
    String? searchQuery,
  }) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClauses.add('customer_id = ?');
      whereArgs.add(customerId);
    }

    if (status != null && status.trim().isNotEmpty && status.toUpperCase() != 'ALL') {
      whereClauses.add('LOWER(payment_status) = ?');
      whereArgs.add(status.trim().toLowerCase());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(bill_no) LIKE ? OR LOWER(customer_name) LIKE ? OR LOWER(design_details) LIKE ? OR LOWER(notes) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_bills',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((b) => CustomerBillModel.fromMap(b)).toList();
  }

  Future<int> insertCustomerBill(CustomerBillModel bill) async {
    final db = await database;
    await _ensureMigration(db);
    final map = bill.toMap()..remove('id');
    return await db.insert('customer_bills', map);
  }

  Future<int> updateCustomerBill(CustomerBillModel bill) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.update('customer_bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<int> deleteCustomerBill(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.delete('customer_bills', where: 'id = ?', whereArgs: [id]);
  }

  // --- Customer Payments Operations ---
  Future<List<CustomerPaymentModel>> getCustomerPayments({int? customerId, int? billId}) async {
    final db = await database;
    await _ensureMigration(db);
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereClauses.add('customer_id = ?');
      whereArgs.add(customerId);
    }
    if (billId != null) {
      whereClauses.add('bill_id = ?');
      whereArgs.add(billId);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final List<Map<String, dynamic>> maps = await db.query(
      'customer_payments',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((p) => CustomerPaymentModel.fromMap(p)).toList();
  }

  Future<int> recordCustomerPayment(CustomerPaymentModel payment) async {
    final db = await database;
    await _ensureMigration(db);

    return await db.transaction((txn) async {
      // 1. Insert customer payment record
      final map = payment.toMap()..remove('id');
      final paymentId = await txn.insert('customer_payments', map);

      // 2. If billId is attached, update the customer bill's paid_amount and status
      if (payment.billId != null) {
        final List<Map<String, dynamic>> bills = await txn.query(
          'customer_bills',
          where: 'id = ?',
          whereArgs: [payment.billId],
        );

        if (bills.isNotEmpty) {
          final billMap = bills.first;
          final totalAmount = (billMap['total_amount'] as num?)?.toDouble() ?? 0.0;
          final currentPaid = (billMap['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final newPaid = currentPaid + payment.amount;
          final newStatus = newPaid >= totalAmount && totalAmount > 0
              ? 'Paid'
              : (newPaid > 0 ? 'Partial' : 'Unpaid');

          await txn.update(
            'customer_bills',
            {
              'paid_amount': newPaid,
              'payment_status': newStatus,
              'payment_date': payment.date.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.billId],
          );
        }
      }

      return paymentId;
    });
  }

  Future<int> deleteCustomerPayment(int id) async {
    final db = await database;
    await _ensureMigration(db);
    return await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(
        'customer_payments',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        final paymentMap = maps.first;
        final billId = paymentMap['bill_id'] as int?;
        final amount = (paymentMap['amount'] as num?)?.toDouble() ?? 0.0;

        if (billId != null) {
          final List<Map<String, dynamic>> bills = await txn.query(
            'customer_bills',
            where: 'id = ?',
            whereArgs: [billId],
          );
          if (bills.isNotEmpty) {
            final billMap = bills.first;
            final totalAmount = (billMap['total_amount'] as num?)?.toDouble() ?? 0.0;
            final currentPaid = (billMap['paid_amount'] as num?)?.toDouble() ?? 0.0;
            final newPaid = (currentPaid - amount).clamp(0.0, double.infinity);
            final newStatus = newPaid >= totalAmount && totalAmount > 0
                ? 'Paid'
                : (newPaid > 0 ? 'Partial' : 'Unpaid');

            await txn.update(
              'customer_bills',
              {
                'paid_amount': newPaid,
                'payment_status': newStatus,
              },
              where: 'id = ?',
              whereArgs: [billId],
            );
          }
        }
      }
      return await txn.delete('customer_payments', where: 'id = ?', whereArgs: [id]);
    });
  }
}
