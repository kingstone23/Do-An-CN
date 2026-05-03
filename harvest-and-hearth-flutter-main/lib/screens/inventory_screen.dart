import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../widgets/food_item_card.dart';
import '../widgets/add_food_modal.dart';

enum _SortBy { name, expiry, added }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  _SortBy _sortBy = _SortBy.expiry;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodItem> _filter(List<FoodItem> items) {
    var result = _query.isEmpty
        ? items.toList()
        : items.where((i) => i.name.toLowerCase().contains(_query)).toList();
    switch (_sortBy) {
      case _SortBy.name:
        result.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.expiry:
        result.sort((a, b) {
          final da = a.daysUntilExpiry;
          final db = b.daysUntilExpiry;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db); // Đồ gần hết hạn (ít ngày) lên trên
        });
      case _SortBy.added:
        result.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    }
    return result;
  }

  void _openEdit(BuildContext context, FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddFoodModal(editItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use select to avoid rebuilding when unrelated provider fields change
    // (e.g. recipeCache, savedRecipes)
    final fridgeItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.fridgeItems);
    final freezerItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.freezerItems);
    final pantryItems =
        context.select<AppProvider, List<FoodItem>>((p) => p.pantryItems);
    final language = context.select<AppProvider, String>((p) => p.language);
    final t = context.select<AppProvider, String Function(String)>((p) => p.t);

    final filteredFridge = _filter(fridgeItems);
    final filteredFreezer = _filter(freezerItems);
    final filteredPantry = _filter(pantryItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('inventory_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: t('inventory_search'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // Sort chips + Tabs
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.kitchen_rounded, size: 18),
                          text: t('inventory_fridge'),
                        ),
                        Tab(
                          icon: const Icon(Icons.ac_unit_rounded, size: 18),
                          text: t('inventory_freezer'),
                        ),
                        Tab(
                          icon: const Icon(Icons.inventory_2_rounded, size: 18),
                          text: t('inventory_pantry'),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_SortBy>(
                    icon: const Icon(Icons.sort_rounded),
                    onSelected: (v) => setState(() => _sortBy = v),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _SortBy.name,
                        child: Text(t('inventory_sort_name')),
                      ),
                      PopupMenuItem(
                        value: _SortBy.expiry,
                        child: Text(t('inventory_sort_expiry')),
                      ),
                      PopupMenuItem(
                        value: _SortBy.added,
                        child: Text(t('inventory_sort_added')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ItemList(
            items: filteredFridge,
            t: t,
            language: language,
            onEdit: (item) => _openEdit(context, item),
          ),
          _ItemList(
            items: filteredFreezer,
            t: t,
            language: language,
            onEdit: (item) => _openEdit(context, item),
          ),
          _ItemList(
            items: filteredPantry,
            t: t,
            language: language,
            onEdit: (item) => _openEdit(context, item),
          ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<FoodItem> items;
  final String Function(String) t;
  final String language;
  final void Function(FoodItem) onEdit;

  const _ItemList({
    required this.items,
    required this.t,
    required this.language,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.kitchen_outlined,
                size: 64, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(t('inventory_empty'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(t('inventory_empty_sub'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => FoodItemCard(
        item: items[i],
        language: language,
        onEdit: () => onEdit(items[i]),
        onDelete: () => _confirmDelete(context, items[i], t),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FoodItem item, String Function(String) t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('inventory_delete_confirm')),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppProvider>().removeFood(item.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('common_delete')),
          ),
        ],
      ),
    );
  }
}
