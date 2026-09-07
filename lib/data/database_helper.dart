import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }

    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.current;
    }
    final path = p.join(dir.path, 'expense_tracker.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seed(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createLoanTables(db);
          }
          if (oldVersion < 3) {
            await _createChatTables(db);
          }
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        color TEXT DEFAULT '#5B4BF0',
        user_id INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        bill_category_id INTEGER,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        notes TEXT,
        payment_method TEXT DEFAULT 'cash',
        currency_code TEXT DEFAULT 'USD',
        receipt_image TEXT,
        bill_type TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (bill_category_id) REFERENCES bill_categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        income_date TEXT NOT NULL,
        notes TEXT,
        payment_method TEXT DEFAULT 'bank_transfer',
        currency_code TEXT DEFAULT 'USD',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        limit_amount REAL NOT NULL,
        period TEXT DEFAULT 'monthly',
        month INTEGER,
        year INTEGER,
        notes TEXT,
        carryover_enabled INTEGER DEFAULT 0,
        carryover_amount REAL DEFAULT 0,
        carried_over_from TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        target_date TEXT,
        category TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE category_keywords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        keyword TEXT NOT NULL UNIQUE,
        priority INTEGER DEFAULT 5,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_code TEXT NOT NULL,
        exchange_rate REAL DEFAULT 1,
        is_primary INTEGER DEFAULT 0,
        last_updated TEXT,
        created_at TEXT,
        UNIQUE (currency_code)
      )
    ''');

    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER DEFAULT 0,
        mime_type TEXT,
        ocr_text TEXT,
        is_processed INTEGER DEFAULT 0,
        processing_status TEXT DEFAULT 'pending',
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        FOREIGN KEY (expense_id) REFERENCES expenses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        bill_category_id INTEGER,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'cash',
        notes TEXT,
        frequency TEXT DEFAULT 'monthly',
        interval_days INTEGER,
        day_of_week INTEGER,
        day_of_month INTEGER,
        month_of_year INTEGER,
        next_due_date TEXT NOT NULL,
        last_generated_date TEXT,
        end_date TEXT,
        max_occurrences INTEGER,
        occurrences_generated INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        last_expense_id INTEGER,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (bill_category_id) REFERENCES bill_categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT DEFAULT 'info',
        title TEXT NOT NULL,
        body TEXT,
        data TEXT,
        read INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_name TEXT DEFAULT 'default',
        description TEXT NOT NULL,
        properties TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_expenses_date ON expenses (expense_date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses (category_id)');
    await db.execute('CREATE INDEX idx_income_date ON income (income_date)');
    await db.execute('CREATE INDEX idx_budgets_category ON budgets (category_id)');

    await _createLoanTables(db);
    await _createChatTables(db);
  }

  Future<void> _createLoanTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lender TEXT,
        principal REAL NOT NULL,
        annual_interest_rate REAL DEFAULT 0,
        term_months INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        payment_day INTEGER DEFAULT 15,
        payment_method TEXT DEFAULT 'bank_transfer',
        notes TEXT,
        paid_off INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS loan_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        amount_due REAL NOT NULL,
        principal_paid REAL DEFAULT 0,
        interest_paid REAL DEFAULT 0,
        status TEXT DEFAULT 'upcoming',
        paid_date TEXT,
        expense_id INTEGER,
        created_at TEXT,
        FOREIGN KEY (loan_id) REFERENCES user_loans (id)
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments (loan_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_loan_payments_due ON loan_payments (due_date)');
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        kind TEXT DEFAULT 'text',
        text TEXT NOT NULL,
        payload TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON chat_messages (created_at)');
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final bc in _billCategoriesSeed) {
      await db.insert('bill_categories', {...bc, 'created_at': now});
    }
  }

  static const _billCategoriesSeed = [
    {'name': 'Electricity'},
    {'name': 'Water'},
    {'name': 'Internet'},
    {'name': 'Phone'},
    {'name': 'Gas'},
    {'name': 'Rent'},
    {'name': 'Insurance'},
    {'name': 'Property Tax'},
    {'name': 'Subscription'},
    {'name': 'Healthcare'},
    {'name': 'Loan Payment'},
    {'name': 'Education'},
    {'name': 'Transportation'},
    {'name': 'Other'},
  ];

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

String nowIso() => DateTime.now().toIso8601String();