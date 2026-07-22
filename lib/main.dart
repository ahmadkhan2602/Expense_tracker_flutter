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
  int _currentIndex = 0;
  DateTime? _selectedMonthHistory;
  double monthlyBudget = 0;
  bool showBudgetInput = false;

  List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'];

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
    _selectedMonthHistory = DateTime(DateTime.now().year, DateTime.now().month);
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

    // Merge picked date with current hour/minute/second
    final now = DateTime.now();
    final combinedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    setState(() {
      expenses.add(
        Expense(
          category: finalCategory,
          amount: _amountController.text,
          date: combinedDateTime,
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

  Color getBudgetColor() {
    double remaining = getRemainingBudget();
    if (remaining < 0) return Colors.red;
    if (remaining < monthlyBudget * 0.2) return Colors.orange;
    return Colors.green;
  }

  List<Expense> getTodayExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((expense) {
      final expDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expDate == today;
    }).toList();
  }

  double getTodaySpent() {
    double total = 0;
    for (var expense in getTodayExpenses()) {
      total += double.parse(expense.amount);
    }
    return total;
  }

  List<DateTime> getAvailableMonths() {
    final monthsSet = <DateTime>{};
    
    // Always include the current month
    final now = DateTime.now();
    monthsSet.add(DateTime(now.year, now.month));
    
    for (var expense in expenses) {
      monthsSet.add(DateTime(expense.date.year, expense.date.month));
    }
    
    final list = monthsSet.toList();
    // Sort descending (newest month first)
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  List<Expense> getExpensesForMonth(DateTime monthYear) {
    return expenses.where((expense) {
      return expense.date.year == monthYear.year && expense.date.month == monthYear.month;
    }).toList();
  }

  double getMonthSpent(DateTime monthYear) {
    double total = 0;
    for (var expense in getExpensesForMonth(monthYear)) {
      total += double.parse(expense.amount);
    }
    return total;
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    
    int hour = dt.hour;
    final isPm = hour >= 12;
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = isPm ? 'PM' : 'AM';
    
    return '$month $day, $year • $hour:$minute $period';
  }

  String _formatMonthYear(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildBudgetCard() {
    return Container(
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
    );
  }

  Widget _buildBudgetInputForm() {
    return Padding(
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
    );
  }

  Widget _buildTodaySpentSummaryCard() {
    return Container(
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
              Text('Today Spent', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text('Rs ${getTodaySpent().toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            children: [
              Text('Today Expenses', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text('${getTodayExpenses().length}', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddExpenseForm() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildExpenseCard(Expense expense, int index) {
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
        subtitle: Text(_formatDateTime(expense.date), style: TextStyle(fontSize: 12)),
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
  }

  Widget _buildTodayView() {
    final todayExpensesList = getTodayExpenses();
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBudgetCard(),

          if (showBudgetInput)
            _buildBudgetInputForm(),

          _buildTodaySpentSummaryCard(),

          _buildAddExpenseForm(),

          SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Text(
                  "Today's Expenses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          if (todayExpensesList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No expenses logged today', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else
            Column(
              children: todayExpensesList.map((expense) {
                int index = expenses.indexOf(expense);
                return _buildExpenseCard(expense, index);
              }).toList(),
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    final availableMonths = getAvailableMonths();
    if (_selectedMonthHistory == null || !availableMonths.contains(_selectedMonthHistory)) {
      _selectedMonthHistory = availableMonths.isNotEmpty ? availableMonths.first : DateTime(DateTime.now().year, DateTime.now().month);
    }
    
    final selectedMonth = _selectedMonthHistory!;
    final monthlyExpensesList = getExpensesForMonth(selectedMonth);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          if (availableMonths.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: availableMonths.map((month) {
                    final isSelected = _selectedMonthHistory == month;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_formatMonthYear(month)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMonthHistory = month;
                            });
                          }
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.indigo,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Month Spent', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('Rs ${getMonthSpent(selectedMonth).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Expenses', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('${monthlyExpensesList.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Expenses for ${_formatMonthYear(selectedMonth)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          if (monthlyExpensesList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No expenses logged for this month', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            )
          else
            Column(
              children: monthlyExpensesList.map((expense) {
                int index = expenses.indexOf(expense);
                return _buildExpenseCard(expense, index);
              }).toList(),
            ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 5,
      ),
      body: _currentIndex == 0 ? _buildTodayView() : _buildHistoryView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Monthly History',
          ),
        ],
      ),
    );
  }
}