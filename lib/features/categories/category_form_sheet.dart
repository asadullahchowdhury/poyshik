import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/palette_picker.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'categories_repository.dart';

/// Add a category of [kind], or edit [category] when given.
Future<void> showCategoryFormSheet(
  BuildContext context, {
  required CategoryKind kind,
  Category? category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategoryFormSheet(kind: kind, category: category),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({required this.kind, this.category});

  final CategoryKind kind;
  final Category? category;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _icon;
  late int _colorIndex;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.icon ?? 'more';
    _colorIndex = widget.category?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(categoriesRepositoryProvider);
    if (_isEdit) {
      await repo.update(
        widget.category!.id,
        name: _name.text,
        icon: _icon,
        colorIndex: _colorIndex,
      );
    } else {
      await repo.create(
        name: _name.text,
        kind: widget.kind,
        icon: _icon,
        colorIndex: _colorIndex,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleArchive() async {
    final cat = widget.category!;
    await ref
        .read(categoriesRepositoryProvider)
        .setArchived(cat.id, archived: !cat.isArchived);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final label = AppType.label.copyWith(color: c.inkMuted);
    final color = PoyshikColors.categoryPalette[_colorIndex];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.xxl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIcon(icon: AppIcons.of(_icon), color: color),
                  const SizedBox(width: Space.md),
                  Text(
                    _isEdit ? l10n.categoryEdit : l10n.categoryNew,
                    style: AppType.titleLarge.copyWith(color: c.ink),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: l10n.categoryNameHint,
                  counterText: '',
                ),
                style: AppType.bodyStrong.copyWith(color: c.ink),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.categoryNameRequired
                    : null,
              ),
              const SizedBox(height: Space.xl),
              Text(l10n.accountColor, style: label),
              const SizedBox(height: Space.sm),
              PalettePicker(
                selected: _colorIndex,
                onChanged: (i) => setState(() => _colorIndex = i),
              ),
              const SizedBox(height: Space.xl),
              Text(l10n.categoryIcon, style: label),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final key in AppIcons.categoryKeys)
                    GestureDetector(
                      onTap: () => setState(() => _icon = key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.md),
                          border: Border.all(
                            color: _icon == key ? c.brand : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CategoryIcon(
                          icon: AppIcons.of(key),
                          color: _icon == key ? color : c.inkMuted,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.xxl),
              PrimaryButton(
                label: l10n.categorySave,
                icon: Icons.check_rounded,
                onPressed: _saving ? null : () => unawaited(_save()),
              ),
              if (_isEdit) ...[
                const SizedBox(height: Space.md),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_toggleArchive()),
                  icon: Icon(
                    widget.category!.isArchived
                        ? Icons.unarchive_rounded
                        : Icons.archive_rounded,
                    size: 20,
                  ),
                  label: Text(
                    widget.category!.isArchived
                        ? l10n.categoryUnarchive
                        : l10n.categoryArchive,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  l10n.categoryArchiveHint,
                  style: AppType.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
