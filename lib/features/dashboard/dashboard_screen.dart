import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_statistics.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatisticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(dashboardStatisticsNotifierProvider.notifier)
            .refresh(),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text('Failed to load statistics'),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () =>
                            ref.invalidate(dashboardStatisticsNotifierProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (stats) => _DashboardBody(stats: stats),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStatistics stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.description_outlined,
              label: 'Documents',
              value: stats.documentsTotal.toString(),
            ),
            _StatCard(
              icon: Icons.inbox_outlined,
              label: 'Inbox',
              value: stats.documentsInbox.toString(),
              onTap: (ctx) => ctx.push('/inbox'),
            ),
            _StatCard(
              icon: Icons.label_outline,
              label: 'Tags',
              value: stats.tagCount.toString(),
            ),
            _StatCard(
              icon: Icons.person_outline,
              label: 'Correspondents',
              value: stats.correspondentCount.toString(),
            ),
            _StatCard(
              icon: Icons.folder_outlined,
              label: 'Document Types',
              value: stats.documentTypeCount.toString(),
            ),
            _StatCard(
              icon: Icons.storage_outlined,
              label: 'Storage Paths',
              value: stats.storagePathCount.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final void Function(BuildContext)? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAction = onTap != null;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: hasAction ? () => onTap!(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 20),
                  if (hasAction) ...[
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant, size: 16),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
