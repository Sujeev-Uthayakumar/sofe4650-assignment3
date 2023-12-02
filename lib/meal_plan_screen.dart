import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'food.dart';

class MealPlanScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(int) onDeleteFood;

  const MealPlanScreen({super.key,
    required this.selectedDate,
    required this.onDeleteFood,
  });

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final dbHelper = DatabaseHelper();
  List<Food> mealPlan = [];

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  //Function to load all the food item based on date
  void _loadMealPlan() async {
    final loadedMealPlan =
    await dbHelper.getMealPlanForDate(_formatDate(widget.selectedDate));
    setState(() {
      mealPlan = loadedMealPlan;
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  //Custom function which allows food items to be updated
  void _updateFood(int id, String currentName, int currentCalories) {
    Food selectedFoodItem = mealPlan.firstWhere((food) => food.id == id);

    TextEditingController foodNameController =
    TextEditingController(text: currentName);
    TextEditingController foodCaloriesController =
    TextEditingController(text: currentCalories.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Food'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: foodNameController,
                onChanged: (value) {
                  selectedFoodItem.name = value;
                },
                decoration: const InputDecoration(labelText: 'Food Name'),
              ),
              const SizedBox(height: 10),
              Text('Current Calories: ${selectedFoodItem.calories}'),
              const SizedBox(height: 10),
              TextFormField(
                controller: foodCaloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (foodCaloriesController.text.isNotEmpty) {
                  // Update food item in the database.
                  selectedFoodItem.calories =
                      int.parse(foodCaloriesController.text);
                  await dbHelper.updateFood(
                    selectedFoodItem.id,
                    selectedFoodItem.name,
                    selectedFoodItem.calories,
                    _formatDate(widget.selectedDate),
                  );

                  _loadMealPlan();
                  Navigator.pop(context);
                  foodCaloriesController.clear();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  //Custom function which deletes food item
  void _deleteFood(int id, int calories) async {
    await dbHelper.deleteFood(id);
    _loadMealPlan();
    widget.onDeleteFood(calories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Plan for ${_formatDate(widget.selectedDate)}'),
      ),
      body: ListView.builder(
        itemCount: mealPlan.length,
        itemBuilder: (context, index) {
          final food = mealPlan[index];
          return ListTile(
            title: Text(food.name),
            subtitle: Text('${food.calories} calories'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _updateFood(food.id, food.name, food.calories),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteFood(food.id, food.calories),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
