import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class GoalFormScreen extends StatefulWidget {
  final SavingsGoal? goal;
  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  final _categoryController = TextEditingController();

  List<Category> _categories = [];
  String? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    if (g != null) {
      _titleController.text = g.title;
      _descController.text = g.description;
      _targetController.text = g.targetAmount.toStringAsFixed(2);
      _currentController.text = g.currentAmount.toStringAsFixed(2);
      _categoryController.text = g.category ?? '';
      _targetDate = g.targetDate;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await AppRepository.instance.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate() == false) return;
    setState(() => _saving = true);
    try {
      await AppRepository.instance.saveGoal(
        id: widget.goal?.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        targetAmount: double.parse(_targetController.text.replaceAll(',', '')),
        currentAmount: double.tryParse(_currentController.text.replaceAll(',', '')) ?? 0,
        targetDate: _targetDate,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      );
      context.read<AppState>().bumpData();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addAmount() async {
    final goal = widget.goal;
    if (goal?.id == null) return;
    final controller = TextEditingController();
    final amount = await _amountDialog('Add to savings', controller);
    if (amount != null && amount > 0) {
      await AppRepository.instance.addGoalAmount(goal!.id!, amount);
      context.read<AppState>().bumpData();
      if (mounted) await _reloadCurrent(goal);
    }
  }

  Future<void> _subtractAmount() async {
    final goal = widget.goal;
    if (goal?.id == null) return;
    final controller = TextEditingController();
    final amount = await _amountDialog('Withdraw from savings', controller);
    if (amount != null && amount > 0) {
      await AppRepository.instance.subtractGoalAmount(goal!.id!, amount);
      context.read<AppState>().bumpData();
      if (mounted) await _reloadCurrent(goal);
    }
  }

  Future<void> _reloadCurrent(SavingsGoal goal) async {
    final updated = await AppRepository.instance.getGoal(goal.id!);
    if (updated != null && mounted) {
      setState(() => _currentController.text = updated.currentAmount.toStringAsFixed(2));
    }
  }

  Future<double?> _amountDialog(String title, TextEditingController controller) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.replaceAll(',', '')) ?? 0),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final isEdit = goal != null;
    final cur = context.watch<AppState>().currencyCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Goal' : 'New Goal'),
        actions: [
          if (isEdit && goal.status == 'active')
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: () async {
                await AppRepository.instance.pauseGoal(goal.id!);
                context.read<AppState>().bumpData();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          if (isEdit && goal.status == 'paused')
            IconButton(
              tooltip: 'Resume',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () async {
                await AppRepository.instance.resumeGoal(goal.id!);
                context.read<AppState>().bumpData();
                if (mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (isEdit) ...[
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saved so far', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
                              const SizedBox(height: 4),
                              Text(formatMoney(goal.currentAmount, cur), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Target', style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
                              const SizedBox(height: 4),
                              Text(formatMoney(goal.targetAmount, cur), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProgressBar(fraction: goal.progressPercentage / 100, color: AppColors.primary),
                    if (goal.isCompleted) ...[
                      const SizedBox(height: 8),
                      const Text('Goal completed!', style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: goal.isCompleted ? null : _addAmount,
                      icon: const Icon(Icons.add),
                      label: const Text('Add money'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _subtractAmount,
                      icon: const Icon(Icons.remove),
                      label: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ],
            Text('Goal title', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Emergency fund'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 18),
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
            const SizedBox(height: 18),
            Text('Target amount', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: '${currencySymbol(cur)} '),
              validator: (v) {
                final val = double.tryParse((v ?? '').replaceAll(',', ''));
                if (val == null || val <= 0) return 'Enter a valid target';
                return null;
              },
            ),
            if (!isEdit) ...[
              const SizedBox(height: 18),
              Text('Current amount', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _currentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: '0.00', prefixText: '${currencySymbol(cur)} '),
              ),
            ],
            const SizedBox(height: 18),
            Text('Target date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_targetDate ?? '') ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _targetDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(_targetDate != null ? formatDateShort(_targetDate!) : 'No target date'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(hintText: 'Optional: tag a goal'),
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _categories.take(8))
                    ActionChip(
                      label: Text(c.name),
                      onPressed: () => setState(() => _categoryController.text = c.name),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving...' : isEdit ? 'Update Goal' : 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }
}