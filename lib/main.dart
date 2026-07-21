import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('expenseBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    );
  }
}

class Expense {
  String category;
  String amount;
  DateTime date;
  String notes;

  Expense({
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();
  List<Expense> expenses = [];
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();
  String filterType = 'All';
  double monthlyBudget = 0;
  bool showBudgetInput = false;

  List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'];
  List<String> filters = ['All', 'Today', 'Yesterday', 'This Month', 'Last Month'];

  Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.pink,
    'Bills': Colors.red,
    'Entertainment': Colors.purple,
    'Other': Colors.grey,
  };

  Map<String, String> placeholderTexts = {
    'Food': 'E.g., Pizza from Dominos, Biryani from XYZ restaurant',
    'Transport': 'E.g., Uber to office, Bus ride to mall',
    'Shopping': 'E.g., Shoes from Nike store, Clothes from H&M',
    'Bills': 'E.g., Electricity bill, Internet bill, Water bill',
    'Entertainment': 'E.g., Movie tickets, Concert, Gaming',
    'Other': 'E.g., Any additional details',
  };

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadBudget();
  }

  Future<void> loadExpenses() async {
    final box = Hive.box('expenseBox');
    final String? expensesJson = box.get('expenses');

    if (expensesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(expensesJson);
        setState(() {
          expenses = decoded.map((item) => Expense.fromMap(item)).toList();
        });
      } catch (e) {
        debugPrint('Error loading expenses: $e');
      }
    }
  }

  Future<void> saveExpenses() async {
    try {
      final box = Hive.box('expenseBox');
      final String expensesJson = jsonEncode(
        expenses.map((e) => e.toMap()).toList(),
      );
      await box.put('expenses', expensesJson);
    } catch (e) {
      debugPrint('Error saving expenses: $e');
    }
  }

  Future<void> loadBudget() async {
    final box = Hive.box('expenseBox');
    final double? budget = box.get('monthlyBudget');

    if (budget != null) {
      setState(() {
        monthlyBudget = budget;
        _budgetController.text = monthlyBudget.toString();
      });
    }
  }

  Future<void> saveBudget() async {
    try {
      final box = Hive.box('expenseBox');
      await box.put('monthlyBudget', monthlyBudget);
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  bool isNumeric(String str) {
    if (str.isEmpty) return false;
    return double.tryParse(str) != null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void addExpense() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter amount!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!isNumeric(_amountController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount must be a number! (e.g., 500, 100.50)'), backgroundColor: Colors.red),
      );
      return;
    }

    String finalCategory = selectedCategory;
    if (selectedCategory == 'Other' && _customCategoryController.text.isNotEmpty) {
      finalCategory = _customCategoryController.text;
      categoryColors[finalCategory] = Colors.teal;
    }

    setState(() {
      expenses.add(
        Expense(
          category: finalCategory,
          amount: _amountController.text,
          date: selectedDate,
          notes: _notesController.text,
        ),
      );
      _amountController.clear();
      _customCategoryController.clear();
      _notesController.clear();
      selectedDate = DateTime.now();
    });

    saveExpenses();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense added!'), backgroundColor: Colors.green),
    );
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
    saveExpenses();
  }

  void setBudget() {
    if (_budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter budget!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!isNumeric(_budgetController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget must be a number!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      monthlyBudget = double.parse(_budgetController.text);
      showBudgetInput = false;
    });
    saveBudget();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Monthly budget set to Rs $monthlyBudget'), backgroundColor: Colors.green),
    );
  }

  double getMonthlySpent() {
    DateTime now = DateTime.now();
    double total = 0;
    for (var expense in expenses) {
      if (expense.date.year == now.year && expense.date.month == now.month) {
        total += double.parse(expense.amount);
      }
    }
    return total;
  }

  double getRemainingBudget() {
    return monthlyBudget - getMonthlySpent();
  }

  List<Expense> getFilteredExpenses() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    return expenses.where((expense) {
      DateTime expDate = DateTime(expense.date.year, expense.date.month, expense.date.day);

      switch (filterType) {
        case 'Today':
          return expDate == today;
        case 'Yesterday':
          return expDate == yesterday;
        case 'This Month':
          return expense.date.year == now.year && expense.date.month == now.month;
        case 'Last Month':
          return expense.date.year == now.year && expense.date.month == (now.month - 1);
        default:
          return true;
      }
    }).toList();
  }

  double getTotalAmount() {
    double total = 0;
    for (var expense in getFilteredExpenses()) {
      total += double.parse(expense.amount);
    }
    return total;
  }

  Color getBudgetColor() {
    double remaining = getRemainingBudget();
    if (remaining < 0) return Colors.red;
    if (remaining < monthlyBudget * 0.2) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  if (monthlyBudget == 0)
                    Text('No Budget Set', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  else
                    Column(
                      children: [
                        Text('Monthly Budget', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Text('Rs ${monthlyBudget.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('Spent This Month', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Rs ${getMonthlySpent().toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('Remaining', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Rs ${getRemainingBudget().toStringAsFixed(2)}', style: TextStyle(color: getBudgetColor(), fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showBudgetInput = !showBudgetInput;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: Text(monthlyBudget == 0 ? 'Set Budget' : 'Change Budget', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            if (showBudgetInput)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Enter monthly budget', prefixText: 'Rs ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey[100]),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(onPressed: setBudget, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: Text('Save Budget', style: TextStyle(color: Colors.white))),
                    SizedBox(height: 16),
                  ],
                ),
              ),

            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo, Colors.blue]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Total Spent', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text('Rs ${getTotalAmount().toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Expenses', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text('${getFilteredExpenses().length}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(filter),
                        selected: filterType == filter,
                        onSelected: (selected) {
                          setState(() {
                            filterType = filter;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.indigo,
                        labelStyle: TextStyle(color: filterType == filter ? Colors.white : Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.indigo), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  underline: SizedBox(),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: categoryColors[category], shape: BoxShape.circle)),
                          SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                      _notesController.clear();
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 12),

            if (selectedCategory == 'Other')
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(hintText: 'Enter custom category name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey[100]),
                ),
              ),

            if (selectedCategory == 'Other') SizedBox(height: 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: 'Enter amount (e.g., 500 or 100.50)', prefixText: 'Rs ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey[100]),
              ),
            ),

            SizedBox(height: 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: placeholderTexts[selectedCategory] ?? 'Enter optional details',
                  label: Text('Optional Details'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),

            SizedBox(height: 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: Icon(Icons.calendar_today),
                label: Text('Date: ${selectedDate.toString().split(' ')[0]}'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: addExpense,
              icon: Icon(Icons.add, size: 28),
              label: Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 8,
              ),
            ),

            SizedBox(height: 16),

            if (getFilteredExpenses().isEmpty)
              Center(child: Text('No expenses ${filterType.toLowerCase()}', style: TextStyle(fontSize: 18, color: Colors.grey)))
            else
              Column(
                children: getFilteredExpenses().map((expense) {
                  int index = expenses.indexOf(expense);
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 3,
                    child: ExpansionTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: categoryColors[expense.category] ?? Colors.grey, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(expense.category[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                      ),
                      title: Text(expense.category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(expense.date.toString().split(' ')[0], style: TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Rs ${expense.amount}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                          SizedBox(width: 8),
                          IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteExpense(index)),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 8),
                              Text(expense.notes.isEmpty ? 'No additional details' : expense.notes, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}