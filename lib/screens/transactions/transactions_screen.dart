import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/transactions/expense_form_screen.dart';
import 'package:track_me/screens/transactions/income_form_screen.dart';
import 'package:track_me/screens/transactions/transaction_filters.dart';
import 'package:track_me/screens/transactions/trash_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _tab = 0; // 0 expenses, 1 income
  String _search = '';
  int? _categoryFilter;
  String? _dateFrom;
  String? _dateTo;
  double? _amountMin;
  double? _amountMax;
  String? _paymentFilter;
  String? _sourceFilter;

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppState>().dataVersion;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            tooltip: 'Trash',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrashScreen())),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : const Color(0xFFEFF1F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: (_hasAnyFilter)
                        ? AppColors.primary
                        : Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : const Color(0xFFEFF1F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    tooltip: 'Filters',
                    onPressed: () async {
                      final filters = await showModalBottomSheet<TransactionFilters>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TransactionFiltersSheet(
                          tab: _tab,
                          initialCategoryId: _categoryFilter,
                          initialDateFrom: _dateFrom,
                          initialDateTo: _dateTo,
                          initialAmountMin: _amountMin,
                          initialAmountMax: _amountMax,
                          initialPayment: _paymentFilter,
                          initialSource: _sourceFilter,
                        ),
                      );
                      if (filters != null) {
                        setState(() {
                          _categoryFilter = filters.categoryId;
                          _dateFrom = filters.dateFrom;
                          _dateTo = filters.dateTo;
                          _amountMin = filters.amountMin;
                          _amountMax = filters.amountMax;
                          _paymentFilter = filters.paymentMethod;
                          _sourceFilter = filters.source;
                        });
                      }
                    },
                    icon: Icon(_hasAnyFilter ? Icons.filter_alt : Icons.filter_alt_outlined),
                    color: _hasAnyFilter ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark2 : const Color(0xFFECEEF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _TabButton(label: 'Expenses', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _TabButton(label: 'Income', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _ExpensesList(
                    version: version,
                    search: _search,
                    categoryId: _categoryFilter,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    amountMin: _amountMin,
                    amountMax: _amountMax,
                    paymentMethod: _paymentFilter,
                    onChanged: () => setState(() {}),
                  )
                : _IncomeList(
                    version: version,
                    search: _search,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    amountMin: _amountMin,
                    amountMax: _amountMax,
                    paymentMethod: _paymentFilter,
                    source: _sourceFilter,
                    onChanged: () => setState(() {}),
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasAnyFilter =>
      _categoryFilter != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _amountMin != null ||
      _amountMax != null ||
      (_paymentFilter?.isNotEmpty ?? false) ||
      (_sourceFilter?.isNotEmpty ?? false);
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : Theme.of(context).textTheme.bodySmall!.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpensesList extends StatefulWidget {
  final int version;
  final String search;
  final int? categoryId;
  final String? dateFrom;
  final String? dateTo;
  final double? amountMin;
  final double? amountMax;
  final String? paymentMethod;
  final VoidCallback onChanged;

  const _ExpensesList({
    required this.version,
    required this.search,
    required this.categoryId,
    required this.dateFrom,
    required this.dateTo,
    required this.amountMin,
    required this.amountMax,
    required this.paymentMethod,
    required this.onChanged,
  });

  @override
  State<_ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<_ExpensesList> {
  List<Expense> _expenses = [];
  bool _loading = true;
  String _currency = 'USD';
  final Set<int> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ExpensesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final repo = AppRepository.instance;
    final user = await repo.getUser();
    final list = await repo.getExpenses(
      search: widget.search,
      categoryId: widget.categoryId,
      dateFrom: widget.dateFrom,
      dateTo: widget.dateTo,
      amountMin: widget.amountMin,
      amountMax: widget.amountMax,
      paymentMethod: widget.paymentMethod,
    );
    if (!mounted) return;
    setState(() {
      _expenses = list;
      _loading = false;
      _currency = user.preferredCurrency;
      _selected.removeWhere((id) => !list.any((e) => e.id == id));
    });
  }

  Future<void> _openForm(Expense? expense) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExpenseFormScreen(expense: expense),
    ));
    widget.onChanged();
    _load();
  }

  Future<void> _delete(Expense expense) async {
    final confirmed = await _confirmDelete('Delete this expense?');
    if (confirmed == true) {
      await AppRepository.instance.softDeleteExpenses([expense.id!]);
      _load();
    }
  }

  Future<bool?> _confirmDelete(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
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
  }

  void _toggleSelect(Expense expense) {
    setState(() {
      if (!_selected.add(expense.id!)) {
        _selected.remove(expense.id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final confirmed = await _confirmDelete('Move ${_selected.length} expense${_selected.length == 1 ? '' : 's'} to trash?');
    if (confirmed == true) {
      await AppRepository.instance.softDeleteExpenses(_selected.toList());
      setState(_selected.clear);
      _load();
    }
  }

  void _selectAll() {
    setState(() {
      for (final e in _expenses) {
        _selected.add(e.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_expenses.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses yet',
        message: widget.search.isNotEmpty
            ? 'No expenses match your search.'
            : 'Tap + and choose Expense to log your first transaction.',
      );
    }

    final grouped = <String, List<Expense>>{};
    for (final e in _expenses) {
      grouped.putIfAbsent(e.expenseDate, () => []).add(e);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        if (_selectionMode)
          _SelectionBar(
            count: _selected.length,
            onSelectAll: _selectAll,
            onDelete: _bulkDelete,
            onCancel: () => setState(_selected.clear),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final date = dates[i];
              final dayTotal = grouped[date]!.fold(0.0, (s, e) => s + e.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(formatDate(date), style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodySmall!.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(formatMoney(dayTotal, _currency), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.expense), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  ...grouped[date]!.map((e) => _ExpenseTile(
                        expense: e,
                        currency: _currency,
                        selected: _selected.contains(e.id),
                        selectionMode: _selectionMode,
                        onTap: _selectionMode ? () => _toggleSelect(e) : () => _openForm(e),
                        onLongPress: () => _toggleSelect(e),
                        onEdit: () => _openForm(e),
                        onDelete: () => _delete(e),
                      )),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  const _SelectionBar({required this.count, required this.onSelectAll, required this.onDelete, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(onPressed: onCancel, icon: const Icon(Icons.close, color: Colors.white), tooltip: 'Clear selection'),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$count selected',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              IconButton(onPressed: onSelectAll, icon: const Icon(Icons.select_all, color: Colors.white), tooltip: 'Select all'),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.white), tooltip: 'Move to trash'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.currency,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      onLongPress: onLongPress,
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : null,
                size: 22,
              ),
            ),
          CategoryAvatar(name: expense.categoryName, color: expense.categoryColor, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    PaymentMethodBadge(code: expense.paymentMethod, size: 15),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${expense.categoryName ?? 'Uncategorized'} · ${paymentShape(expense.paymentMethod)}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${formatMoney(expense.amount, expense.currencyCode.isEmpty ? currency : expense.currencyCode)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.expense),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete')])),
                ],
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

class _IncomeList extends StatefulWidget {
  final int version;
  final String search;
  final String? dateFrom;
  final String? dateTo;
  final double? amountMin;
  final double? amountMax;
  final String? paymentMethod;
  final String? source;
  final VoidCallback onChanged;

  const _IncomeList({
    required this.version,
    required this.search,
    required this.dateFrom,
    required this.dateTo,
    required this.amountMin,
    required this.amountMax,
    required this.paymentMethod,
    required this.source,
    required this.onChanged,
  });

  @override
  State<_IncomeList> createState() => _IncomeListState();
}

class _IncomeListState extends State<_IncomeList> {
  List<Income> _incomes = [];
  bool _loading = true;
  String _currency = 'USD';
  final Set<int> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _IncomeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final user = await AppRepository.instance.getUser();
    final list = await AppRepository.instance.getIncomes(
      search: widget.search,
      dateFrom: widget.dateFrom,
      dateTo: widget.dateTo,
      amountMin: widget.amountMin,
      amountMax: widget.amountMax,
      paymentMethod: widget.paymentMethod,
      source: widget.source,
    );
    if (!mounted) return;
    setState(() {
      _incomes = list;
      _loading = false;
      _currency = user.preferredCurrency;
      _selected.removeWhere((id) => !list.any((e) => e.id == id));
    });
  }

  void _toggleSelect(Income inc) {
    setState(() {
      if (!_selected.add(inc.id!)) {
        _selected.remove(inc.id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text('Move ${_selected.length} income item${_selected.length == 1 ? '' : 's'} to trash?'),
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
    if (confirmed == true) {
      await AppRepository.instance.softDeleteIncomes(_selected.toList());
      setState(_selected.clear);
      _load();
    }
  }

  Future<void> _openForm(Income? income) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => IncomeFormScreen(income: income)));
    widget.onChanged();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_incomes.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        title: 'No income recorded',
        message: widget.search.isNotEmpty ? 'No income matches your search.' : 'Add income like salary, freelance or bonuses.',
      );
    }
    final user = _currency;
    return Column(
      children: [
        if (_selectionMode)
          _SelectionBar(
            count: _selected.length,
            onSelectAll: () {
              setState(() {
                for (final e in _incomes) {
                  _selected.add(e.id!);
                }
              });
            },
            onDelete: _bulkDelete,
            onCancel: () => setState(_selected.clear),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: _incomes.length,
            itemBuilder: (context, i) {
              final inc = _incomes[i];
              final selected = _selected.contains(inc.id);
              return AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                onTap: _selectionMode ? () => _toggleSelect(inc) : () => _openForm(inc),
                onLongPress: () => _toggleSelect(inc),
                color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
                child: Row(
                  children: [
                    if (_selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? AppColors.primary : null,
                          size: 22,
                        ),
                      ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.south_west, color: AppColors.income),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc.source, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(formatDate(inc.incomeDate), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                        ],
                      ),
                    ),
                    if (!_selectionMode)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        onSelected: (v) {
                          if (v == 'edit') _openForm(inc);
                          if (v == 'delete') _confirmAndDelete(inc);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete')])),
                        ],
                      ),
                    Flexible(
                      child: Text(
                        '+${formatMoney(inc.amount, inc.currencyCode.isEmpty ? user : inc.currencyCode)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.income),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(Income inc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Delete this income?'),
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
    if (confirmed == true) {
      await AppRepository.instance.softDeleteIncomes([inc.id!]);
      _load();
    }
  }
}