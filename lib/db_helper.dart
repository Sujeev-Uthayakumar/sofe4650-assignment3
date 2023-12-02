import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'food.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    return _database ??= await initDatabase();
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'food_database.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database
  void _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE foods(id INTEGER PRIMARY KEY, name TEXT, calories INTEGER, date TEXT)',
    );
    await _insertInitialFoodItems(db);
  }

  void _onUpgrade(tabase db, int oldVersion, int newVersion) async {
    // Handle database upgrades if needed.
  }

  // Initialize database with food
  Future<void> _insertInitialFoodItems(Database db) async {
    final foodItemsList = [
      {'name': 'Blueberries (1 cup)', 'calories': 85},
      {'name': 'Cottage Cheese (1 cup)', 'calories': 220},
      {'name': 'Tofu (1/2 cup, firm)', 'calories': 94},
      {'name': 'Kale (1 cup, cooked)', 'calories': 36},
      {'name': 'Walnuts (1 oz)', 'calories': 185},
      {'name': 'Raspberries (1 cup)', 'calories': 64},
      {'name': 'Lentils (1 cup, cooked)', 'calories': 230},
      {'name': 'Turkey Breast (3 oz, cooked)', 'calories': 135},
      {'name': 'Whole Milk (1 cup)', 'calories': 149},
      {'name': 'Mango (1 cup, sliced)', 'calories': 99},
      {'name': 'Asparagus (1 cup, cooked)', 'calories': 40},
      {'name': 'Pumpkin Seeds (1 oz)', 'calories': 126},
      {'name': 'Strawberries (1 cup, halves)', 'calories': 49},
      {'name': 'Black Beans (1 cup, cooked)', 'calories': 227},
      {'name': 'Shrimp (3 oz, cooked)', 'calories': 84},
      {'name': 'Pasta (cooked, 1 cup)', 'calories': 220},
      {'name': 'Cucumber (1 cup, sliced)', 'calories': 16},
      {'name': 'Hummus (2 tbsp)', 'calories': 50},
      {'name': 'Pear (medium)', 'calories': 102},
      {'name': 'Granola (1/2 cup)', 'calories': 200},
    ];


    for (final foodItem in foodItemsList) {
      await db.insert(
        'foods',
        foodItem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Add food to database
  Future<void> insertFood(String name, int calories, String date) async {
    final db = await database;
    await db.insert('foods', {'name': name, 'calories': calories, 'date': date});
  }

  Future<List<Map<String, dynamic>>> getFoods() async {
    final db = await database;
    return db.query('foods');
  }

  // Get all food plan for a date
  Future<List<Food>> getMealPlanForDate(String date) async {
    final db = await database;
    final result = await db.query('foods', where: 'date = ?', whereArgs: [date]);
    return result.map((map) => Food.fromMap(map)).toList();
  }

  // Update food in database
  Future<void> updateFood(int id, String name, int calories, String date) async {
    final db = await database;
    await db.update(
      'foods',
      {'name': name, 'calories': calories, 'date': date},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete food from db
  Future<void> deleteFood(int id) async {
    final db = await database;
    await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }
}
