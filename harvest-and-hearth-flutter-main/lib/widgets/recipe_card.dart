import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final AppProvider provider;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final isSaved = provider.isRecipeSaved(recipe.id);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe icon placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.restaurant_rounded,
                        color: cs.onPrimaryContainer, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: isSaved ? cs.primary : cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      if (isSaved) {
                        provider.unsaveRecipe(recipe.id);
                      } else {
                        provider.saveRecipe(recipe);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Meta chips
              Wrap(
                spacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label: '${recipe.prepTime + recipe.cookTime} ${t('recipes_mins')}',
                  ),
                  _MetaChip(
                    icon: Icons.people_outline_rounded,
                    label: '${recipe.servings} ${t('recipes_people')}',
                  ),
                  _MetaChip(
                    icon: Icons.local_fire_department_outlined,
                    label: '${recipe.calories} ${t('recipes_kcal')}',
                  ),
                  _DifficultyChip(
                      difficulty: recipe.difficulty, t: provider.t),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
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
        builder: (_, ctrl) => _RecipeDetailSheet(
          recipe: recipe,
          provider: provider,
          controller: ctrl,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final RecipeDifficulty difficulty;
  final String Function(String) t;

  const _DifficultyChip({required this.difficulty, required this.t});

  @override
  Widget build(BuildContext context) {
    late Color color;
    switch (difficulty) {
      case RecipeDifficulty.easy:
        color = Colors.green;
      case RecipeDifficulty.medium:
        color = Colors.orange;
      case RecipeDifficulty.hard:
        color = Colors.red;
    }
    final label = switch (difficulty) {
      RecipeDifficulty.easy => t('recipes_difficulty_easy'),
      RecipeDifficulty.medium => t('recipes_difficulty_medium'),
      RecipeDifficulty.hard => t('recipes_difficulty_hard'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RecipeDetailSheet extends StatelessWidget {
  final Recipe recipe;
  final AppProvider provider;
  final ScrollController controller;

  const _RecipeDetailSheet({
    required this.recipe,
    required this.provider,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final isSaved = provider.isRecipeSaved(recipe.id);

    return ListView(
      controller: controller,
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
        const SizedBox(height: 16),

        // Recipe name
        Text(recipe.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(recipe.description,
            style:
                TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 16),

        // Meta grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DetailStat(
                label: t('recipes_prep'),
                value: '${recipe.prepTime}',
                unit: t('recipes_mins'),
                icon: Icons.hourglass_top_rounded),
            _DetailStat(
                label: t('recipes_cook'),
                value: '${recipe.cookTime}',
                unit: t('recipes_mins'),
                icon: Icons.local_fire_department_rounded),
            _DetailStat(
                label: t('recipes_servings'),
                value: '${recipe.servings}',
                unit: t('recipes_people'),
                icon: Icons.people_rounded),
            _DetailStat(
                label: t('recipes_calories'),
                value: '${recipe.calories}',
                unit: t('recipes_kcal'),
                icon: Icons.bolt_rounded),
          ],
        ),
        const SizedBox(height: 20),

        // Ingredients
        Text(t('recipes_ingredients'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipe.ingredientsNeeded.map((ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fiber_manual_record,
                      size: 8,
                      color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
        const SizedBox(height: 20),

        // Instructions
        Text(t('recipes_steps'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recipe.instructions.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
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
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(step, style: const TextStyle(fontSize: 14))),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Save button
        FilledButton.icon(
          onPressed: () {
            if (isSaved) {
              provider.unsaveRecipe(recipe.id);
            } else {
              provider.saveRecipe(recipe);
            }
            Navigator.pop(context);
          },
          icon: Icon(
              isSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded),
          label: Text(isSaved ? t('recipes_unsave') : t('recipes_save')),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        Text('$label ($unit)',
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }
}
