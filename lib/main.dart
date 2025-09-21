import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'transaction.dart';
import 'category.dart';
import 'category_management.dart';
import 'statistics_page.dart';

void main() {
  runApp(const BookkeepingApp());
}

class BookkeepingApp extends StatelessWidget {
  const BookkeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账本',
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final List<Transaction> _transactions = [];
  final List<Category> _categories = [];
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTransactions();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesString = prefs.getStringList('categories');

    if (categoriesString == null || categoriesString.isEmpty) {
      _initializeDefaultCategories();
    } else {
      final categories = categoriesString
          .map((cat) => Category.fromJson(jsonDecode(cat)))
          .toList();
      setState(() {
        _categories.clear();
        _categories.addAll(categories);
      });
    }
  }

  void _initializeDefaultCategories() {
    final defaultCategories = [
      Category(id: '1', name: '食物', iconCodePoint: Icons.restaurant.codePoint, isExpense: true, isDefault: true, sortOrder: 0),
      Category(id: '2', name: '交通', iconCodePoint: Icons.directions_car.codePoint, isExpense: true, isDefault: true, sortOrder: 1),
      Category(id: '3', name: '购物', iconCodePoint: Icons.shopping_cart.codePoint, isExpense: true, isDefault: true, sortOrder: 2),
      Category(id: '4', name: '其他', iconCodePoint: Icons.category.codePoint, isExpense: true, isDefault: true, sortOrder: 3),
      Category(id: '5', name: '工资', iconCodePoint: Icons.work.codePoint, isExpense: false, isDefault: true, sortOrder: 0),
      Category(id: '6', name: '理财', iconCodePoint: Icons.trending_up.codePoint, isExpense: false, isDefault: true, sortOrder: 1),
      Category(id: '7', name: '其他', iconCodePoint: Icons.category.codePoint, isExpense: false, isDefault: true, sortOrder: 2),
    ];

    setState(() {
      _categories.clear();
      _categories.addAll(defaultCategories);
    });
    _saveCategories();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesString = _categories.map((cat) => jsonEncode(cat.toJson())).toList();
    await prefs.setStringList('categories', categoriesString);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getStringList('transactions') ?? [];
    final transactions = transactionsString
        .map((tx) => Transaction.fromJson(jsonDecode(tx)))
        .toList();
    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);
      _calculateBalance();
    });
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = _transactions.map((tx) => jsonEncode(tx.toJson())).toList();
    await prefs.setStringList('transactions', transactionsString);
  }

  void _calculateBalance() {
    double balance = 0.0;
    for (var tx in _transactions) {
      if (tx.isExpense) {
        balance -= tx.amount;
      } else {
        balance += tx.amount;
      }
    }
    setState(() {
      _balance = balance;
    });
  }

  /// 构建主页面UI
  /// 包含底部导航和对应的页面内容
  @override
  Widget build(BuildContext context) {
    // 页面列表：记账页面和统计页面
    final List<Widget> pages = [
      TransactionPage(
        transactions: _transactions,
        categories: _categories,
        balance: _balance,
        onTransactionAdded: (transaction) {
          setState(() {
            _transactions.insert(0, transaction);
            _transactions.sort((a, b) => b.date.compareTo(a.date));
            _calculateBalance();
          });
          _saveTransactions();
        },
        onTransactionDeleted: (id) {
          final txIndex = _transactions.indexWhere((tx) => tx.id == id);
          if (txIndex != -1) {
            setState(() {
              _transactions.removeAt(txIndex);
              _calculateBalance();
            });
            _saveTransactions();
          }
        },
        onTransactionEdited: (editedTransaction) {
          final txIndex = _transactions.indexWhere((tx) => tx.id == editedTransaction.id);
          if (txIndex != -1) {
            setState(() {
              _transactions[txIndex] = editedTransaction;
              _transactions.sort((a, b) => b.date.compareTo(a.date));
              _calculateBalance();
            });
            _saveTransactions();
          }
        },
        onCategoriesUpdated: (categories) {
          setState(() {
            _categories.clear();
            _categories.addAll(categories);
          });
          _saveCategories();
        },
      ),
      StatisticsPage(
        transactions: _transactions,
        categories: _categories,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '记账',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '统计',
          ),
        ],
      ),
    );
  }
}

class TransactionPage extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final double balance;
  final Function(Transaction) onTransactionAdded;
  final Function(String) onTransactionDeleted;
  final Function(Transaction) onTransactionEdited;
  final Function(List<Category>) onCategoriesUpdated;

  const TransactionPage({
    super.key,
    required this.transactions,
    required this.categories,
    required this.balance,
    required this.onTransactionAdded,
    required this.onTransactionDeleted,
    required this.onTransactionEdited,
    required this.onCategoriesUpdated,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _filterType = '全部'; // 筛选类型：全部、按日、按月、按年
  DateTime? _selectedDate; // 选中的日期

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  IconData _getCategoryIcon(String category, bool isExpense) {
    final cat = widget.categories.firstWhere(
      (c) => c.name == category && c.isExpense == isExpense,
      orElse: () => Category(
        id: 'default',
        name: '其他',
        iconCodePoint: Icons.category.codePoint,
        isExpense: isExpense,
      ),
    );
    return IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons');
  }

  void _deleteTransaction(String id) {
    widget.onTransactionDeleted(id);
  }

  void _openCategoryManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagementPage(
          categories: widget.categories,
          onCategoriesUpdated: widget.onCategoriesUpdated,
        ),
      ),
    );
  }

  Future<void> _exportToJson() async {
    try {
      // 准备数据
      final data = {
        'app_name': '记账本',
        'export_date': DateTime.now().toIso8601String(),
        'version': '2.0', // 标记为支持类型配置的版本
        'total_transactions': widget.transactions.length,
        'current_balance': widget.balance,
        'transactions': widget.transactions.map((tx) => tx.toJson()).toList(),
        'categories': widget.categories.map((cat) => cat.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final fileName = '记账本_备份_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';

      if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台：使用FilePicker保存文件
        final bytes = Uint8List.fromList(utf8.encode(jsonString));

        final result = await FilePicker.platform.saveFile(
          dialogTitle: '选择导出位置',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );

        if (result != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('数据已导出: $fileName'),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else if (false) {
        // iOS平台：保存到应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('数据已导出到: ${file.path}'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 桌面平台：使用文件选择器
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '选择导出位置',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('数据已导出到: ${file.path}'),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: '打开文件夹',
                  textColor: Colors.white,
                  onPressed: () async {
                    // 打开文件所在文件夹
                    final directory = file.parent.path;
                    await Process.run('explorer', [directory]);
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择记账数据文件',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);

        if (data['transactions'] != null) {
          // 显示确认对话框
          if (!mounted) return;

          String confirmMessage = '将导入 ${data['transactions'].length} 条交易记录';
          if (data['categories'] != null) {
            confirmMessage += '和 ${data['categories'].length} 个类型配置';
          }
          confirmMessage += '。\n\n警告：这将替换当前所有数据！';

          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认导入'),
              content: Text(confirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('确认导入'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final transactions = (data['transactions'] as List)
                .map((tx) => Transaction.fromJson(tx))
                .toList();

            // 导入类型配置（如果存在）
            if (data['categories'] != null) {
              final categories = (data['categories'] as List)
                  .map((cat) => Category.fromJson(cat))
                  .toList();
              widget.onCategoriesUpdated(categories);
            }

            // 导入交易记录
            for (var transaction in transactions) {
              widget.onTransactionAdded(transaction);
            }

            if (mounted) {
              String successMessage = '成功导入 ${transactions.length} 条交易记录';
              if (data['categories'] != null) {
                successMessage += '和 ${data['categories'].length} 个类型配置';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } else {
          throw '无效的数据格式';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  /// 构建交易记录页面UI
  /// 包含应用栏、筛选卡片、交易列表和浮动按钮
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        elevation: 0,                   // 去除应用栏阴影
        actions: [                      // 应用栏右侧操���按钮
          // 弹出菜单按钮，提供导出、导入和类型管理功能
          PopupMenuButton<String>(
            onSelected: (value) {           // 菜单项选择处理
              if (value == 'export') {
                _exportToJson();            // 导出数据到JSON文件
              } else if (value == 'import') {
                _importFromJson();          // 从JSON文件导入数据
              } else if (value == 'categories') {
                _openCategoryManagement();  // 打开类型管理页面
              }
            },
            icon: const Icon(Icons.more_vert), // 三点菜单图标
            tooltip: '选项',
            itemBuilder: (context) => [         // 构建菜单项列表
              // 类型管理菜单项
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.purple),
                    SizedBox(width: 12),
                    Text('类型管理'),
                  ],
                ),
              ),
              // 导出数据菜单项
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.green),
                    SizedBox(width: 12),
                    Text('导出数据'),
                  ],
                ),
              ),
              // 导入数据菜单项
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('导入数据'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(                        // 垂直布局���筛选卡片 + 交易列表
        children: [
          _buildFilterCard(),             // 构建筛选条件卡片
          Expanded(child: _buildTransactionList()), // 构建交易列表（占据剩余空间）
        ],
      ),
      floatingActionButton: FloatingActionButton(  // 浮动添加按钮
        onPressed: () => _showAddTransactionDialog(context), // 点击显示添加对话框
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建筛选条件卡片
  /// 包含筛选类型选择（全部/按日/按月/按年）和日期选择器
  Widget _buildFilterCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('全部'),
                        const SizedBox(width: 8),
                        _buildFilterChip('按日'),
                        const SizedBox(width: 8),
                        _buildFilterChip('按月'),
                        const SizedBox(width: 8),
                        _buildFilterChip('按年'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_filterType != '全部') ...[
              const SizedBox(height: 12),
              _buildDateSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = label;
          });
        }
      },
      selectedColor: Colors.indigo[100],
    );
  }

  Widget _buildDateSelector() {
    String dateText;
    switch (_filterType) {
      case '按日':
        dateText = _formatChineseDate(_selectedDate!);
        break;
      case '按月':
        dateText = _getChineseYearMonth(_selectedDate!);
        break;
      case '按年':
        dateText = '${_selectedDate!.year}年';
        break;
      default:
        dateText = '';
    }

    return Row(
      children: [
        Icon(Icons.date_range, color: Colors.indigo[400]),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTransactionList() {
    final filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          widget.transactions.isEmpty ? '没有记录。点击右下角按钮添加。' : '没有符合筛选条件的记录。',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];
        return Dismissible(
          key: ValueKey(tx.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteTransaction(tx.id);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.isExpense ? Colors.red[100] : Colors.green[100],
                child: Icon(
                  _getCategoryIcon(tx.category, tx.isExpense),
                  color: tx.isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Row(
                children: [
                  Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tx.isExpense ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tx.isExpense ? Colors.red[200]! : Colors.green[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tx.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: tx.isExpense ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(_formatChineseDate(tx.date)),
              trailing: Text(
                '${tx.isExpense ? '-' : '+'} ${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: tx.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () => _showEditTransactionDialog(context, tx),
            ),
          ),
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    String selectedCategory = '其他';
    DateTime selectedDate = DateTime.now(); // 默认为当天

    // 获取当前类型的默认选项
    final currentCategories = widget.categories.where((c) => c.isExpense == isExpense).toList();
    if (currentCategories.isNotEmpty) {
      selectedCategory = currentCategories.first.name;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableCategories = widget.categories.where((c) => c.isExpense == isExpense).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '添加新记录',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 所有字段统一滚动区域
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 核心字段组
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[100]!, width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 金额输入
                                  TextField(
                                    controller: amountController,
                                    decoration: const InputDecoration(
                                      labelText: '金额',
                                      prefixText: '¥ ',
                                      hintText: '请输入金额',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(10),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 10),

                                  // 收入/支出切换
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('收入', style: TextStyle(color: Colors.green, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Switch(
                                            value: isExpense,
                                            onChanged: (value) {
                                              setState(() {
                                                isExpense = value;
                                                final newCategories = widget.categories.where((c) => c.isExpense == isExpense).toList();
                                                selectedCategory = newCategories.isNotEmpty ? newCategories.first.name : '其他';
                                              });
                                            },
                                            activeTrackColor: Colors.red.withValues(alpha: 0.5),
                                            activeThumbColor: Colors.red,
                                            inactiveTrackColor: Colors.green.withValues(alpha: 0.5),
                                            inactiveThumbColor: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('支出', style: TextStyle(color: Colors.red, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 类型选择
                                  DropdownButtonFormField<String>(
                                    initialValue: availableCategories.any((c) => c.name == selectedCategory) ? selectedCategory : null,
                                    decoration: const InputDecoration(
                                      labelText: '类型',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(10),
                                    ),
                                    items: availableCategories
                                        .map((category) => DropdownMenuItem(
                                              value: category.name,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(category.name, style: const TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategory = value ?? availableCategories.first.name;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // 日期选择
                                  InkWell(
                                    onTap: () async {
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                                      );
                                      if (picked != null && picked != selectedDate) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: '日期',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today, size: 16),
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(10),
                                      ),
                                      child: Text(
                                        _formatChineseDate(selectedDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 描述字段
                            TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: '描述 (可选)',
                                hintText: '留空则使用类型名称',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.all(10),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    // 按钮区域
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final description = descriptionController.text.trim();
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              if (amount > 0) {
                                final finalDescription = description.isEmpty ? selectedCategory : description;
                                final newTransaction = Transaction(
                                  id: DateTime.now().toString(),
                                  description: finalDescription,
                                  amount: amount,
                                  date: selectedDate,
                                  isExpense: isExpense,
                                  category: selectedCategory,
                                );
                                widget.onTransactionAdded(newTransaction);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTransactionDialog(BuildContext context, Transaction transaction) {
    final descriptionController = TextEditingController(text: transaction.description);
    final amountController = TextEditingController(text: transaction.amount.toString());
    bool isExpense = transaction.isExpense;
    String selectedCategory = transaction.category;
    DateTime selectedDate = transaction.date;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableCategories = widget.categories.where((c) => c.isExpense == isExpense).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    // 标题栏
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '编辑记录',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 所有字段统一滚动区域
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 核心字段组
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[100]!, width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 金额输入
                                  TextField(
                                    controller: amountController,
                                    decoration: const InputDecoration(
                                      labelText: '金额',
                                      prefixText: '¥ ',
                                      hintText: '请输入金额',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(10),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 10),

                                  // 收入/支出切换
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('收入', style: TextStyle(color: Colors.green, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Switch(
                                            value: isExpense,
                                            onChanged: (value) {
                                              setState(() {
                                                isExpense = value;
                                                final newCategories = widget.categories.where((c) => c.isExpense == isExpense).toList();
                                                selectedCategory = newCategories.isNotEmpty ? newCategories.first.name : '其他';
                                              });
                                            },
                                            activeTrackColor: Colors.red.withValues(alpha: 0.5),
                                            activeThumbColor: Colors.red,
                                            inactiveTrackColor: Colors.green.withValues(alpha: 0.5),
                                            inactiveThumbColor: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('支出', style: TextStyle(color: Colors.red, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 类型选择
                                  DropdownButtonFormField<String>(
                                    value: availableCategories.any((c) => c.name == selectedCategory) ? selectedCategory : null,
                                    decoration: const InputDecoration(
                                      labelText: '类型',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(10),
                                    ),
                                    items: availableCategories
                                        .map((category) => DropdownMenuItem(
                                              value: category.name,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(category.name, style: const TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategory = value ?? availableCategories.first.name;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // 日期选择
                                  InkWell(
                                    onTap: () async {
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                                      );
                                      if (picked != null && picked != selectedDate) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: '日期',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today, size: 16),
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(10),
                                      ),
                                      child: Text(
                                        _formatChineseDate(selectedDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 描述字段
                            TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: '描述 (可选)',
                                hintText: '留空则使用类型名称',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.all(10),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    // 按钮区域
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final description = descriptionController.text.trim();
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              if (amount > 0) {
                                final finalDescription = description.isEmpty ? selectedCategory : description;
                                final editedTransaction = Transaction(
                                  id: transaction.id,
                                  description: finalDescription,
                                  amount: amount,
                                  date: selectedDate,
                                  isExpense: isExpense,
                                  category: selectedCategory,
                                );
                                widget.onTransactionEdited(editedTransaction);
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Transaction> _getFilteredTransactions() {
    if (_filterType == '全部') {
      return widget.transactions;
    }

    return widget.transactions.where((transaction) {
      switch (_filterType) {
        case '按日':
          return transaction.date.year == _selectedDate!.year &&
                 transaction.date.month == _selectedDate!.month &&
                 transaction.date.day == _selectedDate!.day;
        case '按月':
          return transaction.date.year == _selectedDate!.year &&
                 transaction.date.month == _selectedDate!.month;
        case '按年':
          return transaction.date.year == _selectedDate!.year;
        default:
          return true;
      }
    }).toList();
  }

  void _selectDate() async {
    DateTime? pickedDate;

    switch (_filterType) {
      case '按日':
        pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate!,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 3650)), // 扩展到未来10年
        );
        break;
      case '按月':
        pickedDate = await _showMonthYearPicker(context, _selectedDate!, showDay: false);
        break;
      case '按年':
        pickedDate = await _showYearPicker(context, _selectedDate!);
        break;
    }

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<DateTime?> _showMonthYearPicker(BuildContext context, DateTime initialDate, {bool showDay = true}) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];

    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择月份'),
              content: SizedBox(
                width: 300,
                height: 300,
                child: Column(
                  children: [
                    // 年份选择
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedYear--;
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '${selectedYear}年',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: selectedYear < DateTime.now().year + 10 ? () {
                            setState(() {
                              selectedYear++;
                            });
                          } : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 月份网格
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == selectedMonth;
                          final isCurrentOrPast = DateTime(selectedYear, month).isBefore(
                            DateTime(DateTime.now().year + 10, DateTime.now().month + 1)
                          );

                          return InkWell(
                            onTap: isCurrentOrPast ? () {
                              setState(() {
                                selectedMonth = month;
                              });
                            } : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.indigo[100] : null,
                                border: Border.all(
                                  color: isSelected ? Colors.indigo : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  months[index],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentOrPast ? (isSelected ? Colors.indigo : Colors.black) : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final result = DateTime(selectedYear, selectedMonth);
                    Navigator.of(context).pop(result);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _showYearPicker(BuildContext context, DateTime initialDate) async {
    int selectedYear = initialDate.year;
    final ScrollController scrollController = ScrollController();

    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentYear = DateTime.now().year;
            final startYear = currentYear - 50;
            final endYear = currentYear + 10; // 扩展到未来10年

            // 计算当前年份在网格中的位置并滚动到那里
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                final currentYearIndex = currentYear - startYear;
                final itemHeight = 60.0; // 估算每行高度
                final itemsPerRow = 3;
                final rowIndex = currentYearIndex ~/ itemsPerRow;
                final targetOffset = rowIndex * itemHeight;

                scrollController.animateTo(
                  targetOffset,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });

            return AlertDialog(
              title: const Text('选择年份'),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: selectedYear > startYear ? () {
                            setState(() {
                              selectedYear--;
                            });
                          } : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '${selectedYear}年',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: selectedYear < endYear ? () {
                            setState(() {
                              selectedYear++;
                            });
                          } : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: endYear - startYear + 1,
                        itemBuilder: (context, index) {
                          final year = startYear + index;
                          final isSelected = year == selectedYear;
                          final isCurrentYear = year == currentYear;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedYear = year;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.indigo[100] : (isCurrentYear ? Colors.grey[50] : null),
                                border: Border.all(
                                  color: isSelected ? Colors.indigo : (isCurrentYear ? Colors.indigo[200]! : Colors.grey[300]!),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${year}年',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : (isCurrentYear ? FontWeight.w500 : FontWeight.normal),
                                    color: isSelected ? Colors.indigo : (isCurrentYear ? Colors.indigo[600] : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final result = DateTime(selectedYear);
                    Navigator.of(context).pop(result);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getChineseYearMonth(DateTime date) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return '${date.year}年${months[date.month - 1]}';
  }

  String _formatChineseDate(DateTime date) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return '${date.year}年${months[date.month - 1]}${date.day}日';
  }

  String _formatChineseDateWithTime(DateTime date) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}年${months[date.month - 1]}${date.day}日 $hour:$minute';
  }
}