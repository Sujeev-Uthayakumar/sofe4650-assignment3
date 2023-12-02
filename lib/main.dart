import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'meal_plan_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calories Calculator',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Initialize database
  final dbHelper = DatabaseHelper();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //Initialize variables
  int targetCalories = 0;
  DateTime selectedDate = DateTime.now();
  int totalConsumedCalories = 0;
  TextEditingController foodController = TextEditingController();
  int calories = 0;
  bool usePredefinedList = true;

  @override
  void initState() {
    super.initState();
    _loadTotalConsumedCalories();
  }

  //Custom function to pick date
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadTotalConsumedCalories();
      });
    }
  }

  //Custom function to load total calories after food items are added
  void _loadTotalConsumedCalories() async {
    final consumedFoods =
    await dbHelper.getMealPlanForDate(_formatDate(selectedDate));
    int totalCalories = consumedFoods.fold(0, (sum, food) => sum + food.calories);
    setState(() {
      totalConsumedCalories = totalCalories;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  //Custom function which builds a dialog box full of foods
  Future<void> _showFoodSelectionDialog() async {
    List<Map<String, dynamic>> foods = await dbHelper.getFoods();

    showDialog(
      context: _scaffoldKey.currentContext!,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Predefined Options'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  children: foods.map((food) {
                    return ListTile(
                      title: Text(food['name']),
                      onTap: () => _handleFoodTap(food),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFoodTap(Map food) {
    if (food['name'] != null && food['name'].isNotEmpty) {
      if (mounted) {
        setState(() {
          foodController.text = food['name'];
          calories = food['calories'];
        });
      }
    }
    Navigator.of(_scaffoldKey.currentContext!).pop();
  }

  //Custom function which allows the addition of food
  void _addFood() async {

    if (selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }

    //Check if target calories is inputted
    if (targetCalories==0){
      _showSnackBar('Target calories must be filled.');
      return;
    }

    await _showFoodSelectionDialog();

    if (calories > 0) {
      // Check if calories is greater than 0 before adding to total.
      if (totalConsumedCalories + calories > targetCalories) {
        _showSnackBar('Exceeding Target Calories!');
        return;
      }

      //Insert food item to database
      await dbHelper.insertFood(
        foodController.text,
        calories,
        _formatDate(selectedDate),
      );

      //Update total calories
      _loadTotalConsumedCalories();

      //reset state
      setState(() {
        foodController.text = '';
        calories = 0;
      });
    }
  }

  //Custom function to remove food
  void _deleteFood(int calories) {
    //remove food from state
    setState(() {
      totalConsumedCalories -= calories;
    });
  }

  //Custom function which switch pages
  void _viewMealPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPlanScreen(
          selectedDate: selectedDate,
          onDeleteFood: _deleteFood,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Calories Calculator'),
      ),
      body: Column(
        children: [
          _buildTargetCaloriesInput(),
          _buildSelectedDateRow(),
          _buildAddFoodButton(),
          _buildTotalConsumedCaloriesText(),
          if (totalConsumedCalories > targetCalories)
            _buildExceedingCaloriesWarning(),
          _buildViewMealPlanButton(),
        ],
      ),
    );
  }

  Widget _buildTargetCaloriesInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Target Calories:'),
            const SizedBox(height: 10),
            SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center, // Center the content within the TextField
                onChanged: (value) {
                  setState(() {
                    targetCalories = int.parse(value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Selected Date: ${_formatDate(selectedDate)}'),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFoodButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFood,
                child: const Text('Add Food Item'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalConsumedCaloriesText() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
      child: Center(
        child: Text(
          'Total Consumed Calories: $totalConsumedCalories',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  Widget _buildExceedingCaloriesWarning() {
    return const Text(
      'Target Calories Surpassed',
      style: TextStyle(color: Colors.red),
    );
  }

  Widget _buildViewMealPlanButton() {
    return ElevatedButton(
      onPressed: _viewMealPlan,
      child: const Text('Current Meal Plan'),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
