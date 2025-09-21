# 记账

一个简洁高效的记账应用，使用 Flutter 开发，支持跨平台使用。

## 主要功能

### 📊 记账管理
- **收支记录**: 支持添加收入和支出记录
- **分类管理**: 自定义收支类别，支持图标和颜色配置
- **快速操作**: 侧滑删除交易记录，支持撤销操作
- **时间筛选**: 按日、月、年筛选查看交易记录

### 📈 统计分析
- **月度汇总**: 查看每月收入、支出和结余统计
- **支出分类统计**: 饼图显示各类别支出占比
- **支出趋势**: 近3个月的每日支出和月度汇总趋势图
- **月份选择**: 自由选择查看任意月份的统计数据

### 💾 数据管理
- **数据导出**: 将交易记录导出为 JSON 格式文件
- **数据导入**: 从 JSON 文件导入交易记录
- **本地存储**: 使用 SharedPreferences 进行本地数据持久化
- **数据备份**: 支持完整的数据备份和恢复

### 🎨 界面设计
- **Material Design**: 采用 Material Design 设计规范
- **中文界面**: 完全中文化的用户界面
- **响应式布局**: 适配不同屏幕尺寸
- **主题色彩**: 统一的 Indigo 主题色系

## 技术特性

### 架构设计
- **单页应用**: 基于 StatefulWidget 的状态管理
- **模块化设计**: 分离的数据模型和业务逻辑
- **JSON 序列化**: 支持数据的序列化和反序列化

### 核心依赖
- `flutter`: 跨平台 UI 框架
- `intl`: 国际化和日期格式化
- `shared_preferences`: 本地数据存储
- `file_picker`: 文件选择和保存
- `path_provider`: 系统路径访问
- `fl_chart`: 图表绘制

### 平台支持
- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 安装使用

### 从源码构建

1. 克隆项目
```bash
git clone <repository-url>
cd flutter2
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 构建发布版本

#### Android APK
```bash
# 构建通用 APK
flutter build apk --release

# 构建分架构 APK（体积更小）
flutter build apk --release --split-per-abi
```

#### Windows
```bash
flutter build windows --release
```

#### iOS
```bash
flutter build ios --release
```

## 应用截图

- 主界面: 交易记录列表和余额显示
- 添加记录: 支持选择类别、输入金额和备注
- 统计页面: 月度汇总、分类统计和趋势图表
- 类别管理: 自定义收支类别和图标

## 数据格式

### 交易记录
```json
{
  "id": "timestamp_string",
  "amount": 100.00,
  "description": "描述",
  "category": "类别名称",
  "isExpense": true,
  "date": "2025-01-01T00:00:00.000Z"
}
```

### 类别配置
```json
{
  "id": "unique_id",
  "name": "类别名称",
  "iconCodePoint": 57898,
  "isExpense": true
}
```

## 开发信息

- **Flutter SDK**: >=3.0.0 <4.0.0
- **开发语言**: Dart
- **最低支持**: Android API 21+, iOS 12+
- **包大小**: 约 14-18MB (分架构构建)

## 常用命令

**依赖管理:**
```bash
flutter pub get              # 安装依赖
```

**开发运行:**
```bash
flutter run                  # 运行应用 (默认设备)
flutter run -d windows       # 运行在 Windows
flutter run -d android       # 运行在 Android 模拟器
flutter run -d ios          # 运行在 iOS 模拟器
```

**代码质量:**
```bash
flutter analyze             # 静态代码分析
flutter test                # 运行单元测试
```

**构建发布:**
```bash
flutter build apk           # 构建 Android APK
flutter build windows       # 构建 Windows 可执行文件
flutter build ios           # 构建 iOS 应用
```

## 项目结构

- `lib/main.dart` - 主入口文件，包含应用主界面和交易管理
- `lib/transaction.dart` - 交易记录数据模型
- `lib/category.dart` - 类别数据模型
- `lib/category_management.dart` - 类别管理页面
- `lib/statistics_page.dart` - 统计分析页面

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个应用。

---

*这是一个使用 Flutter 开发的开源记账应用，专注于简洁易用的记账体验。*