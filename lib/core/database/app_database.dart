import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'daos/account_dao.dart';
import 'daos/employee_dao.dart';
import 'daos/machine_dao.dart';
import 'daos/material_dao.dart';
import 'daos/product_dao.dart';
import 'daos/production_dao.dart';
import 'daos/recycle_bin_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/supplier_dao.dart';
import 'daos/upad_dao.dart';

/// Centralized Database Service with OOP DAOs and Index Optimization
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _createPerformanceIndexes(db);
      },
      onOpen: (db) async {
        await _createPerformanceIndexes(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS machines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machine_no TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        head_capacity INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');

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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS production_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
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
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        factory_name TEXT NOT NULL,
        default_rate REAL NOT NULL,
        default_heads INTEGER NOT NULL,
        available_rates TEXT NOT NULL,
        available_heads TEXT NOT NULL,
        theme_mode TEXT NOT NULL DEFAULT 'system',
        accent_color TEXT DEFAULT '#0066FF',
        calculation_explanation_enabled INTEGER NOT NULL DEFAULT 1,
        auto_backup_enabled INTEGER NOT NULL DEFAULT 0,
        whatsapp_auto_send INTEGER NOT NULL DEFAULT 0,
        whatsapp_message_language TEXT NOT NULL DEFAULT 'English',
        whatsapp_phone_number TEXT NOT NULL DEFAULT '',
        excel_export_include_summary INTEGER NOT NULL DEFAULT 1,
        excel_export_include_details INTEGER NOT NULL DEFAULT 1,
        excel_export_group_by TEXT NOT NULL DEFAULT 'Date',
        default_account_name TEXT NOT NULL DEFAULT '250 Area'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS material_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        UNIQUE(product_name, category)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        contact_person TEXT,
        phone TEXT,
        address TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS material_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        product_name TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        challan_no TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        rate REAL NOT NULL,
        total_amount REAL NOT NULL,
        notes TEXT,
        payment_status TEXT NOT NULL DEFAULT 'Pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'Operator',
        phone TEXT DEFAULT '',
        gender TEXT NOT NULL DEFAULT 'Male',
        joining_date TEXT NOT NULL,
        monthly_salary REAL NOT NULL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employee_upad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT DEFAULT '',
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_type TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        json_data TEXT NOT NULL,
        deleted_at TEXT NOT NULL
      )
    ''');
  }

  /// Create High-Performance SQLite Indexes for Instant Queries
  static Future<void> _createPerformanceIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prod_date ON production_records(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prod_machine ON production_records(machine_no);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prod_account ON production_records(account_name);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_upad_emp_id ON employee_upad(employee_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_upad_date ON employee_upad(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mat_cat ON material_items(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mat_challan ON material_items(challan_no);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_del_type ON deleted_records(record_type);');
  }

  // OOP DAO Accessors
  Future<ProductionDao> get productionDao async => ProductionDao(await database);
  Future<EmployeeDao> get employeeDao async => EmployeeDao(await database);
  Future<UpadDao> get upadDao async => UpadDao(await database);
  Future<MaterialDao> get materialDao async => MaterialDao(await database);
  Future<SupplierDao> get supplierDao async => SupplierDao(await database);
  Future<ProductDao> get productDao async => ProductDao(await database);
  Future<AccountDao> get accountDao async => AccountDao(await database);
  Future<MachineDao> get machineDao async => MachineDao(await database);
  Future<SettingsDao> get settingsDao async => SettingsDao(await database);
  Future<RecycleBinDao> get recycleBinDao async => RecycleBinDao(await database);
}
