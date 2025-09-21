import 'package:flutter/material.dart';
import 'category.dart';

class CategoryManagementPage extends StatefulWidget {
  final List<Category> categories;
  final Function(List<Category>) onCategoriesUpdated;

  const CategoryManagementPage({
    super.key,
    required this.categories,
    required this.onCategoriesUpdated,
  });

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  late List<Category> _categories;


  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: null,
        onSave: (category) {
          setState(() {
            // 计算同类型的最大排序序号
            final sameTypeCategories = _categories.where((c) => c.isExpense == category.isExpense);
            final maxSortOrder = sameTypeCategories.isEmpty ? 0 : sameTypeCategories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);

            // 添加新类型，排序序号为最大值+1
            final newCategory = category.copyWith(sortOrder: maxSortOrder + 1);
            _categories.add(newCategory);
          });
          widget.onCategoriesUpdated(_categories);
        },
      ),
    );
  }

  void _editCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (updatedCategory) {
          setState(() {
            final index = _categories.indexWhere((c) => c.id == category.id);
            _categories[index] = updatedCategory;
          });
          widget.onCategoriesUpdated(_categories);
        },
      ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除类型"${category.name}"吗？${category.isDefault ? '\n\n注意：这是一个默认类型。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
              });
              widget.onCategoriesUpdated(_categories);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = _categories.where((c) => c.isExpense).toList();
    final incomeCategories = _categories.where((c) => !c.isExpense).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('类型管理'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: [
                Tab(text: '支出类型'),
                Tab(text: '收入类型'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCategoryList(expenseCategories, true),
                  _buildCategoryList(incomeCategories, false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, bool isExpense) {
    // 按排序序号排序
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = categories.removeAt(oldIndex);
          categories.insert(newIndex, item);

          // 更新排序序号
          for (int i = 0; i < categories.length; i++) {
            final updatedCategory = categories[i].copyWith(sortOrder: i);
            categories[i] = updatedCategory;

            // 更新主列表中的对应项
            final mainIndex = _categories.indexWhere((c) => c.id == updatedCategory.id);
            if (mainIndex != -1) {
              _categories[mainIndex] = updatedCategory;
            }
          }
        });
        widget.onCategoriesUpdated(_categories);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          key: ValueKey(category.id),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_handle, color: Colors.grey[400]),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
                  child: Icon(
                    IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            title: Text(category.name),
            subtitle: Text(category.isDefault ? '默认类型' : '自定义类型'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCategory(category),
                  tooltip: '编辑',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category),
                  tooltip: '删除',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  final Function(Category) onSave;

  const _CategoryDialog({
    required this.category,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late bool _isExpense;

  static const List<IconData> _availableIcons = [
    Icons.restaurant, Icons.directions_car, Icons.shopping_cart, Icons.movie,
    Icons.local_hospital, Icons.school, Icons.work, Icons.trending_up,
    Icons.card_giftcard, Icons.business, Icons.emoji_events, Icons.show_chart,
    Icons.schedule, Icons.keyboard_return, Icons.home, Icons.celebration,
    Icons.casino, Icons.category, Icons.sports_esports, Icons.local_gas_station,
    Icons.phone, Icons.electric_bolt, Icons.water_drop, Icons.wifi,
    Icons.fitness_center, Icons.pets, Icons.local_grocery_store, Icons.flight,
    Icons.hotel, Icons.coffee, Icons.book, Icons.music_note,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category != null
        ? IconData(widget.category!.iconCodePoint, fontFamily: 'MaterialIcons')
        : Icons.category;
    _isExpense = widget.category?.isExpense ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category == null ? '添加类型' : '编辑类型',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '类型名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('类型：'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('支出'),
                  selected: _isExpense,
                  onSelected: (selected) {
                    setState(() {
                      _isExpense = true;
                    });
                  },
                  selectedColor: Colors.red[100],
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('收入'),
                  selected: !_isExpense,
                  onSelected: (selected) {
                    setState(() {
                      _isExpense = false;
                    });
                  },
                  selectedColor: Colors.green[100],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('选择图标：'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon.codePoint == _selectedIcon.codePoint;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.indigo[100] : null,
                          border: Border.all(
                            color: isSelected ? Colors.indigo : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      final category = Category(
                        id: widget.category?.id ?? DateTime.now().toString(),
                        name: _nameController.text,
                        iconCodePoint: _selectedIcon.codePoint,
                        isExpense: _isExpense,
                        isDefault: widget.category?.isDefault ?? false,
                      );
                      widget.onSave(category);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}