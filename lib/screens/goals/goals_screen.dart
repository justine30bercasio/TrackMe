import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';
import 'package:track_me/screens/goals/goal_form_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Future<List<SavingsGoal>> _future;
  int _lastVersion = -1;

  Future<List<SavingsGoal>> _load() => AppRepository.instance.getGoals();

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
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            tooltip: 'Add goal',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalFormScreen()));
              _reload();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<SavingsGoal>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final goals = snapshot.data ?? [];
            if (goals.isEmpty) {
              return EmptyState(
                icon: Icons.savings_outlined,
                title: 'No savings goals',
                message: 'Set a goal like an emergency fund or a vacation and track your progress.',
                action: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalFormScreen()));
                    _reload();
                  },
                  child: const Text('Create Goal'),
                ),
              );
            }

            final currency = context.watch<AppState>().currencyCode;
            final active = goals.where((g) => g.status == 'active').toList();
            final paused = goals.where((g) => g.status == 'paused').toList();
            final completed = goals.where((g) => g.status == 'completed').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                for (final g in active) _GoalCard(goal: g, currency: currency, reload: _reload),
                if (paused.isNotEmpty) ...[
                  _SectionHeader('Paused'),
                  for (final g in paused) _GoalCard(goal: g, currency: currency, reload: _reload),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader('Completed'),
                  for (final g in completed) _GoalCard(goal: g, currency: currency, reload: _reload),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String currency;
  final VoidCallback reload;

  const _GoalCard({required this.goal, required this.currency, required this.reload});

  @override
  Widget build(BuildContext context) {
    final g = goal;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalFormScreen(goal: g)));
        reload();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  g.status == 'completed' ? Icons.celebration : g.status == 'paused' ? Icons.pause : Icons.savings,
                  color: g.status == 'completed' ? AppColors.income : g.status == 'paused' ? AppColors.warning : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (g.category != null && g.category!.isNotEmpty)
                      Text(g.category!, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color)),
                  ],
                ),
              ),
              Pill(
                '${g.progressPercentage.toStringAsFixed(0)}%',
                g.status == 'completed' ? AppColors.income : g.status == 'paused' ? AppColors.warning : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            fraction: g.progressPercentage / 100,
            color: g.status == 'completed' ? AppColors.income : AppColors.primary,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoney(g.currentAmount, currency)} of ${formatMoney(g.targetAmount, currency)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (g.targetDate != null) ...[
                Icon(Icons.event, size: 13, color: Theme.of(context).textTheme.bodySmall!.color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    formatDateShort(g.targetDate!),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}