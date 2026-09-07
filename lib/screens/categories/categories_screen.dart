import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Category>> _future;
  int _lastVersion = -1;

  Future<List<Category>> _load() => AppRepository.instance.getCategories();

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    if (_lastVersion != version) {
      _lastVersion = version;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories',
              message: 'Create categories to organize your expenses.',
              action: ElevatedButton(onPressed: () => _openEditor(), child: const Text('Add Category')),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              return AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                onTap: () => _openEditor(category: c),
                child: Row(
                  children: [
                    CategoryAvatar(name: c.name, color: c.color, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (c.description.isNotEmpty)
                            Text(c.description, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (v) {
                        if (v == 'edit') _openEditor(category: c);
                        if (v == 'delete') _delete(c);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete')])),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppRepository.instance.deleteCategory(category.id!);
      context.read<AppState>().bumpData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    _reload();
  }

  Future<void> _openEditor({Category? category}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _CategoryEditorScreen(category: category)));
    _reload();
  }
}

class _CategoryEditorScreen extends StatefulWidget {
  final Category? category;
  const _CategoryEditorScreen({this.category});

  @override
  State<_CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<_CategoryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _color = c?.color ?? AppColors.categoryColorPool[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate() == false) return;
    setState(() => _saving = true);
    try {
      if (widget.category == null) {
        await AppRepository.instance.addCategory(_nameController.text.trim(), description: _descController.text.trim(), color: _color);
      } else {
        final updated = Category(id: widget.category!.id, name: _nameController.text.trim(), description: _descController.text.trim(), color: _color);
        await AppRepository.instance.updateCategory(updated);
      }
      context.read<AppState>().bumpData();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category == null ? 'New Category' : 'Edit Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Travel'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 18),
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
            const SizedBox(height: 18),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final hex in AppColors.categoryColorPool)
                  GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.colorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == hex ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _color == hex
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : widget.category == null ? 'Create Category' : 'Update Category'),
            ),
          ],
        ),
      ),
    );
  }
}