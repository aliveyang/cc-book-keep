/// 交易类型/分类数据模型
/// 用于存储交易类型的配置信息，包括名称、图标、收支类型等
/// 支持自定义类型和默认类型，支持排序和JSON序列化
class Category {
  final String id;          // 类型的唯一标识符
  final String name;        // 类型显示名称（如“食物”、“交通”等）
  final int iconCodePoint;  // Material Icons图标的码点值，用于显示图标
  final bool isExpense;     // true为支出类型，false为收入类型
  final bool isDefault;     // 是否为系统默认类型（默认类型不允许删除）
  final int sortOrder;      // 在同类型中的排序序号（越小越靠前）

  /// 构造函数
  /// 创建一个新的类型配置
  /// [isDefault] 默认为false（非默认类型）
  /// [sortOrder] 默认为0（最高优先级）
  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.isExpense,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// 从JSON数据创建Category对象
  /// 用于数据导入和本地存储加载
  /// [json] 包含类型数据的Map对象
  /// 为向下兼容，缺失的字段使用默认值
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      iconCodePoint: json['iconCodePoint'],
      isExpense: json['isExpense'],
      isDefault: json['isDefault'] ?? false,     // 缺失时默认为非默认类型
      sortOrder: json['sortOrder'] ?? 0,         // 缺失时默认排序为0
    );
  }

  /// 将Category对象转换为JSON数据
  /// 用于数据导出和本地存储保存
  /// 返回包含所有字段的Map对象
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'isExpense': isExpense,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  /// 创建一个当前对象的副本，并允许修改指定字段
  /// 这是一个常用的Dart模式，用于更新不可变对象的部分字段
  /// 未指定的参数将使用原对象的值
  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    bool? isExpense,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,                               // 使用新值或保持原值
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}