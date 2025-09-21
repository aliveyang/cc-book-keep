/// 交易记录数据模型
/// 用于存储单笔交易的所有信息，包括金额、日期、类型等
/// 支持JSON序列化和反序列化，用于本地存储和数据导入导出
class Transaction {
  final String id;          // 交易记录的唯一标识符（通常使用时间戳）
  final String description; // 交易描述信息（用户输入或使用类型名称）
  final double amount;      // 交易金额（正数，收支通过isExpense区分）
  final DateTime date;      // 交易发生的日期时间
  final bool isExpense;     // 是否为支出（true=支出，false=收入）
  final String category;    // 交易类型/分类名称

  /// 构造函数
  /// 创建一个新的交易记录，所有字段都是必需的
  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
  });

  /// 从JSON数据创建Transaction对象
  /// 用于数据导入和本地存储加载
  /// [jsonData] 包含交易数据的Map对象
  /// 返回构建好的Transaction实例
  factory Transaction.fromJson(Map<String, dynamic> jsonData) {
    return Transaction(
      id: jsonData['id'],
      description: jsonData['description'],
      amount: jsonData['amount'],                          // 直接使用存储的数值
      date: DateTime.parse(jsonData['date']),             // 解析ISO8601格式的日期字符串
      isExpense: jsonData['isExpense'],
      category: jsonData['category'] ?? '其他',             // 如果类型为空则使用默认值
    );
  }

  /// 将Transaction对象转换为JSON数据
  /// 用于数据导出和本地存储保存
  /// 返回包含所有字段的Map对象
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),                     // 转换为ISO8601标准格式字符串
      'isExpense': isExpense,
      'category': category,
    };
  }
}