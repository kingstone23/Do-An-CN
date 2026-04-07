import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../services/recipe_search_service.dart';
import '../services/translate_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGenerating = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipes() async {
    final provider = context.read<AppProvider>();
    if (provider.inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.t('recipes_no_inventory'))),
      );
      return;
    }
    setState(() {
      _isGenerating = true;
      _errorMsg = null;
    });
    try {
      final recipes = await AiService.instance.generateRecipes(
        provider.inventory,
        provider.language,
      );
      if (mounted) {
        provider.setRecipeCache(recipes);
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = provider.t('recipes_error'));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('recipes_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              text: t('recipes_all'),
            ),
            Tab(
              icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
              text: t('recipes_saved'),
            ),
            Tab(
              icon: const Icon(Icons.explore_outlined, size: 18),
              text: t('explore_title'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllRecipesTab(
            isGenerating: _isGenerating,
            errorMsg: _errorMsg,
            onGenerate: _generateRecipes,
            provider: provider,
          ),
          _SavedRecipesTab(provider: provider),
          _ExploreTab(provider: provider),
        ],
      ),
    );
  }
}

// ── AI recipes tab ────────────────────────────────────────────────────────────

class _AllRecipesTab extends StatelessWidget {
  final bool isGenerating;
  final String? errorMsg;
  final VoidCallback onGenerate;
  final AppProvider provider;

  const _AllRecipesTab({
    required this.isGenerating,
    required this.errorMsg,
    required this.onGenerate,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final recipes = provider.recipeCache;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: cs.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      t('recipes_ai_chef'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t('recipes_ai_subtitle'),
                  style: TextStyle(
                      color: cs.onPrimaryContainer.withAlpha(179),
                      fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (errorMsg != null) ...[
                  Text(errorMsg!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isGenerating ? null : onGenerate,
                    icon: isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_rounded),
                    label: Text(isGenerating
                        ? t('recipes_generating')
                        : t('recipes_generate')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (recipes.isEmpty && !isGenerating)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(t('recipes_empty_saved'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    t('recipes_empty_saved_sub'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (_, i) =>
                RecipeCard(recipe: recipes[i], provider: provider),
          ),
      ],
    );
  }
}

// ── Saved recipes tab ─────────────────────────────────────────────────────────

class _SavedRecipesTab extends StatelessWidget {
  final AppProvider provider;
  const _SavedRecipesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final saved = provider.savedRecipes;

    if (saved.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(t('recipes_empty_saved'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              t('recipes_empty_saved_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: saved.length,
      itemBuilder: (context, i) =>
          RecipeCard(recipe: saved[i], provider: provider),
    );
  }
}

// ── Explore tab ───────────────────────────────────────────────────────────────

class _ExploreTab extends StatefulWidget {
  final AppProvider provider;
  const _ExploreTab({required this.provider});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _searchCtrl = TextEditingController();

  List<MealSummary> _vietnameseDishes = [];
  List<Recipe> _mealDbResults = [];
  List<DdgResult> _ddgResults = [];

  bool _loadingViet = true;
  bool _searching = false;
  bool _hasSearched = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadVietnameseDishes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVietnameseDishes() async {
    try {
      final dishes =
          await RecipeSearchService.instance.getVietnameseDishes();
      if (mounted) setState(() => _vietnameseDishes = dishes);
    } catch (_) {
      if (mounted) setState(() => _loadError = widget.provider.t('explore_load_error'));
    } finally {
      if (mounted) setState(() => _loadingViet = false);
    }
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _mealDbResults = [];
      _ddgResults = [];
    });

    final futures = await Future.wait([
      RecipeSearchService.instance.searchMealDB(q).catchError((_) => <Recipe>[]),
      RecipeSearchService.instance
          .searchDuckDuckGo(q)
          .catchError((_) => <DdgResult>[]),
    ]);

    if (mounted) {
      setState(() {
        _mealDbResults = futures[0] as List<Recipe>;
        _ddgResults = futures[1] as List<DdgResult>;
        _searching = false;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _hasSearched = false;
      _mealDbResults = [];
      _ddgResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.provider.t;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchBar(
            controller: _searchCtrl,
            hintText: t('explore_search_hint'),
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSearch,
                ),
            ],
            onSubmitted: _search,
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Content
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : _hasSearched
                  ? _buildSearchResults(t)
                  : _buildDefaultView(t),
        ),
      ],
    );
  }

  Widget _buildDefaultView(String Function(String) t) {
    if (_loadingViet) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(t('explore_loading')),
          ],
        ),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(_loadError!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loadingViet = true;
                  _loadError = null;
                });
                _loadVietnameseDishes();
              },
              child: Text(t('common_retry')),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(
          t('explore_vietnamese'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._vietnameseDishes
            .map((dish) => _MealSummaryCard(
                  summary: dish,
                  provider: widget.provider,
                )),
      ],
    );
  }

  Widget _buildSearchResults(String Function(String) t) {
    final hasResults = _mealDbResults.isNotEmpty || _ddgResults.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(t('explore_empty')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (_mealDbResults.isNotEmpty) ...[
          Text(
            t('explore_mealdb_results'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._mealDbResults.map(
              (r) => RecipeCard(recipe: r, provider: widget.provider)),
          const SizedBox(height: 16),
        ],
        if (_ddgResults.isNotEmpty) ...[
          Text(
            t('explore_ddg_results'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._ddgResults.map(
              (r) => _DdgResultCard(result: r, provider: widget.provider)),
        ],
      ],
    );
  }
}

// ── MealSummary card (list view, loads details on tap) ────────────────────────

class _MealSummaryCard extends StatefulWidget {
  final MealSummary summary;
  final AppProvider provider;
  const _MealSummaryCard({required this.summary, required this.provider});

  @override
  State<_MealSummaryCard> createState() => _MealSummaryCardState();
}

class _MealSummaryCardState extends State<_MealSummaryCard> {
  bool _loadingDetail = false;

  Future<void> _openDetail(BuildContext context) async {
    setState(() => _loadingDetail = true);
    try {
      final recipe = await RecipeSearchService.instance
          .getMealById(widget.summary.mealDbId);
      if (recipe != null && context.mounted) {
        _showRecipeDetail(context, recipe);
      }
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, ctrl) => _MealDetailSheet(
          recipe: recipe,
          provider: widget.provider,
          controller: ctrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = widget.provider.t;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _loadingDetail ? null : () => _openDetail(context),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 88,
              height: 88,
              child: Image.network(
                widget.summary.thumbnailUrl,
                fit: BoxFit.cover,
                // Decode at ~2× thumbnail size to save memory & CPU on list scroll.
                cacheWidth: 200,
                cacheHeight: 200,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primaryContainer,
                  child: Icon(Icons.restaurant_rounded,
                      color: cs.onPrimaryContainer, size: 36),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.summary.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('explore_tap_for_details'),
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // Action
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _loadingDetail
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal detail bottom sheet (TheMealDB, with translate) ──────────────────────

class _MealDetailSheet extends StatefulWidget {
  final Recipe recipe;
  final AppProvider provider;
  final ScrollController controller;

  const _MealDetailSheet({
    required this.recipe,
    required this.provider,
    required this.controller,
  });

  @override
  State<_MealDetailSheet> createState() => _MealDetailSheetState();
}

class _MealDetailSheetState extends State<_MealDetailSheet> {
  String? _translatedName;
  String? _translatedDesc;
  bool _translating = false;
  bool _showingTranslated = false;

  Future<void> _translate() async {
    if (_translatedName != null) {
      setState(() => _showingTranslated = !_showingTranslated);
      return;
    }
    setState(() => _translating = true);
    final lang = widget.provider.language;
    final results = await Future.wait([
      TranslateService.instance.translate(widget.recipe.name, lang),
      TranslateService.instance.translate(widget.recipe.description, lang),
    ]);
    if (mounted) {
      setState(() {
        _translatedName = results[0];
        _translatedDesc = results[1];
        _showingTranslated = true;
        _translating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.provider.t;
    final cs = Theme.of(context).colorScheme;
    final recipe = widget.recipe;
    final isSaved = widget.provider.isRecipeSaved(recipe.id);

    final displayName =
        (_showingTranslated && _translatedName != null) ? _translatedName! : recipe.name;
    final displayDesc =
        (_showingTranslated && _translatedDesc != null) ? _translatedDesc! : recipe.description;

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Thumbnail
        if (recipe.imageKeyword.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              recipe.imageKeyword,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 1200,
              cacheHeight: 600,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),

        // Name + translate button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _translating ? null : _translate,
              icon: _translating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate_rounded, size: 18),
              label: Text(
                _translating
                    ? t('explore_translating')
                    : _showingTranslated
                        ? t('explore_show_original')
                        : t('explore_translate'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),

        if (displayDesc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(displayDesc,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ],
        const SizedBox(height: 8),

        // Source link
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(recipe.sourceUrl),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: Text(t('explore_open_web'),
              style: const TextStyle(fontSize: 13)),
        ),
        const Divider(height: 24),

        // Ingredients
        Text(t('recipes_ingredients'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipe.ingredientsNeeded.map((ing) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(ing, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
        const SizedBox(height: 20),

        // Steps
        Text(t('recipes_steps'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipe.instructions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          Text(e.value, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
        const SizedBox(height: 16),

        // Save button
        FilledButton.icon(
          onPressed: () {
            if (isSaved) {
              widget.provider.unsaveRecipe(recipe.id);
            } else {
              widget.provider.saveRecipe(recipe);
            }
            Navigator.pop(context);
          },
          icon: Icon(isSaved
              ? Icons.bookmark_remove_rounded
              : Icons.bookmark_add_rounded),
          label: Text(isSaved ? t('recipes_unsave') : t('recipes_save')),
        ),
      ],
    );
  }
}

// ── DuckDuckGo result card ────────────────────────────────────────────────────

class _DdgResultCard extends StatefulWidget {
  final DdgResult result;
  final AppProvider provider;
  const _DdgResultCard({required this.result, required this.provider});

  @override
  State<_DdgResultCard> createState() => _DdgResultCardState();
}

class _DdgResultCardState extends State<_DdgResultCard> {
  String? _translatedTitle;
  String? _translatedSnippet;
  bool _translating = false;
  bool _showingTranslated = false;

  Future<void> _translate() async {
    if (_translatedTitle != null) {
      setState(() => _showingTranslated = !_showingTranslated);
      return;
    }
    setState(() => _translating = true);
    final lang = widget.provider.language;
    final results = await Future.wait([
      TranslateService.instance.translate(widget.result.title, lang),
      TranslateService.instance.translate(widget.result.snippet, lang),
    ]);
    if (mounted) {
      setState(() {
        _translatedTitle = results[0];
        _translatedSnippet = results[1];
        _showingTranslated = true;
        _translating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = widget.provider.t;
    final r = widget.result;

    final displayTitle =
        (_showingTranslated && _translatedTitle != null) ? _translatedTitle! : r.title;
    final displaySnippet =
        (_showingTranslated && _translatedSnippet != null) ? _translatedSnippet! : r.snippet;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DuckDuckGo',
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(displayTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              displaySnippet,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _translating ? null : _translate,
                  icon: _translating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate_rounded, size: 16),
                  label: Text(
                    _translating
                        ? t('explore_translating')
                        : _showingTranslated
                            ? t('explore_show_original')
                            : t('explore_translate'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(r.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(t('explore_open_web'),
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
