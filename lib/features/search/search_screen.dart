import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../shared/widgets/document_card.dart';
import 'search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
      _onTextChanged(_searchController.text);
    });
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(autocompleteNotifierProvider.notifier).suggest(text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _focusNode.unfocus();
      ref.read(autocompleteNotifierProvider.notifier).clear();
      ref.read(searchNotifierProvider.notifier).search(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final suggestions = ref.watch(autocompleteNotifierProvider);
    final showSuggestions = _focusNode.hasFocus &&
        suggestions.isNotEmpty &&
        searchState is SearchIdle;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search documents...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchNotifierProvider.notifier).clear();
                ref.read(autocompleteNotifierProvider.notifier).clear();
                _focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: showSuggestions
          ? _buildSuggestions(suggestions)
          : searchState.when(
              idle: () => _buildIdleView(context),
              loading: () => const Center(child: CircularProgressIndicator()),
              results: (documents, totalCount, query) {
                final tags = tagsAsync.valueOrNull ?? {};
                final correspondents = correspondentsAsync.valueOrNull ?? {};
                final docTypes = docTypesAsync.valueOrNull ?? {};
                final api = ref.watch(paperlessApiProvider);

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No results for "$query"',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '$totalCount result${totalCount == 1 ? '' : 's'} for "$query"',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return DocumentCard(
                          document: doc,
                          tags: tags,
                          correspondents: correspondents,
                          documentTypes: docTypes,
                          thumbnailUrl: api.thumbnailUrl(doc.id),
                          authToken: api.authToken,
                          onTap: () => context.push('/documents/${doc.id}'),
                        );
                      },
                    ),
                  ],
                );
              },
              error: (message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Search failed: $message'),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, size: 20),
          title: Text(suggestion),
          onTap: () {
            _searchController.text = suggestion;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: suggestion.length),
            );
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildIdleView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Search your documents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Full-text search across all documents',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
