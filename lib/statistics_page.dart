import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'transaction.dart';
import 'category.dart';

class StatisticsPage extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const StatisticsPage({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 24),
            _buildMonthSummary(),
            const SizedBox(height: 24),
            _buildExpensePieChart(),
            const SizedBox(height: 24),
            _buildExpenseTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            InkWell(
              onTap: () async {
                final DateTime? picked = await _showMonthYearPicker(context, _selectedMonth);
                if (picked != null) {
                  setState(() {
                    _selectedMonth = picked;
                  });
                }
              },
              child: Text(
                _getChineseYearMonth(_selectedMonth),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: _selectedMonth.isBefore(DateTime(DateTime.now().year + 10, DateTime.now().month)) ? () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              } : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSummary() {
    final monthTransactions = _getMonthTransactions(_selectedMonth);
    final totalIncome = monthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = monthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getChineseYearMonth(_selectedMonth)} 汇总',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '收入',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${totalIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '支出',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      '结余',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${(totalIncome - totalExpense).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: totalIncome - totalExpense >= 0 ? Colors.green[600] : Colors.red[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    final monthTransactions = _getMonthTransactions(_selectedMonth);
    final expenseTransactions = monthTransactions.where((t) => t.isExpense).toList();

    if (expenseTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                '支出分类统计',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text('本月暂无支出记录'),
            ],
          ),
        ),
      );
    }

    // 按类型统计支出
    final Map<String, double> categoryExpenses = {};
    for (var transaction in expenseTransactions) {
      categoryExpenses[transaction.category] =
          (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
    }

    // 生成饼图数据
    final pieData = categoryExpenses.entries.map((entry) {
      final category = widget.categories.firstWhere(
        (c) => c.name == entry.key && c.isExpense,
        orElse: () => Category(
          id: 'unknown',
          name: entry.key,
          iconCodePoint: Icons.category.codePoint,
          isExpense: true,
        ),
      );

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${(entry.value / categoryExpenses.values.fold(0.0, (a, b) => a + b) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '支出分类统计',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieData,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categoryExpenses.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${entry.key}: ¥${entry.value.toStringAsFixed(2)}'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTrendChart() {
    // 获取过去3个月的每日数据
    final List<FlSpot> dailySpots = [];
    final List<FlSpot> monthlySpots = [];
    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month - 2, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // 按日期分组统计每日支出
    final Map<String, double> dailyExpenses = {};
    final Map<int, double> monthlyExpenses = {};

    for (var transaction in widget.transactions) {
      if (transaction.isExpense &&
          transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {

        // 每日支出统计
        final dateKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}';
        dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0) + transaction.amount;

        // 每月支出统计
        final monthKey = transaction.date.month;
        monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + transaction.amount;
      }
    }

    // 生成每日数据点
    int dayIndex = 0;
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final expense = dailyExpenses[dateKey] ?? 0;
      dailySpots.add(FlSpot(dayIndex.toDouble(), expense));
      dayIndex++;
    }

    // 生成月度汇总点（在每月末显示）
    final monthEnds = <int, int>{}; // 月份 -> 月末日期索引
    dayIndex = 0;
    int currentMonth = startDate.month;

    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      if (date.month != currentMonth) {
        // 月份变化，记录上个月的最后一天
        monthEnds[currentMonth] = dayIndex - 1;
        currentMonth = date.month;
      }
      dayIndex++;
    }
    // 处理最后一个月
    monthEnds[currentMonth] = dayIndex - 1;

    // 生成月度数据点
    for (final entry in monthEnds.entries) {
      final month = entry.key;
      final endIndex = entry.value;
      final monthExpense = monthlyExpenses[month] ?? 0;
      if (endIndex >= 0) {
        monthlySpots.add(FlSpot(endIndex.toDouble(), monthExpense));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '支出趋势 (近3个月)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // 图例
            Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(width: 4),
                    const Text('每日支出', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 4),
                    const Text('月度汇总', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20, // 每20天显示一个标签，减少重叠
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dailySpots.length) {
                            final date = startDate.add(Duration(days: value.toInt()));
                            return Transform.rotate(
                              angle: -0.5, // 轻微倾斜标签减少重叠
                              child: Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 9)
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        interval: null,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('¥0', style: TextStyle(fontSize: 10));
                          if (value >= 1000) {
                            return Text('¥${(value / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10));
                          }
                          return Text('¥${value.toInt()}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  lineBarsData: [
                    // 每日支出数据点
                    LineChartBarData(
                      spots: dailySpots,
                      isCurved: false,
                      color: Colors.blue[400],
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                    // 月度汇总折线
                    LineChartBarData(
                      spots: monthlySpots,
                      isCurved: false,
                      color: Colors.red[400],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red[100]!.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: dailySpots.length > 0 ? dailySpots.length - 1.0 : 90,
                  minY: 0,
                  maxY: _calculateMaxY([...dailySpots, ...monthlySpots]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> _getMonthTransactions(DateTime month) {
    return widget.transactions.where((transaction) {
      return transaction.date.year == month.year &&
             transaction.date.month == month.month;
    }).toList();
  }

  // 计算合适的Y轴最大值
  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 100;

    // 根据数值大小确定合适的步长
    double step;
    if (maxValue <= 100) {
      step = 20;
    } else if (maxValue <= 500) {
      step = 100;
    } else if (maxValue <= 1000) {
      step = 200;
    } else if (maxValue <= 5000) {
      step = 500;
    } else if (maxValue <= 10000) {
      step = 1000;
    } else {
      step = 2000;
    }

    // 向上取整到下一个步长倍数
    return ((maxValue / step).ceil() * step).toDouble();
  }

  Color _getCategoryColor(String categoryName) {
    // 为不同类型生成固定的颜色
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
      Colors.amber[400]!,
      Colors.cyan[400]!,
    ];

    final hash = categoryName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _getChineseMonth(DateTime date) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return months[date.month - 1];
  }

  String _getChineseYearMonth(DateTime date) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return '${date.year}年${months[date.month - 1]}';
  }

  Future<DateTime?> _showMonthYearPicker(BuildContext context, DateTime initialDate) async {
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
}