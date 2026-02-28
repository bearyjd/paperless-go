import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Review scanned pages before uploading.
class ScanReviewScreen extends StatefulWidget {
  final List<String> imagePaths;
  const ScanReviewScreen({super.key, required this.imagePaths});

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  late List<String> _pages;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.imagePaths);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_pages.length} ${_pages.length == 1 ? 'page' : 'pages'})'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
              ),
              onPressed: _pages.isNotEmpty
                  ? () => context.push('/scan/enhance', extra: _pages)
                  : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages'))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        child: Image.file(
                          File(_pages[i]),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                // Page indicator + controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete page
                      IconButton(
                        onPressed: () => _removePage(_currentPage),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove page',
                      ),
                      // Page indicator
                      Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      // Reorder
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 0
                                ? () => _movePage(_currentPage, _currentPage - 1)
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Move left',
                          ),
                          IconButton(
                            onPressed: _currentPage < _pages.length - 1
                                ? () => _movePage(_currentPage, _currentPage + 1)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            tooltip: 'Move right',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Thumbnail strip
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: i == _currentPage
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(_pages[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  void _removePage(int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last page')),
      );
      return;
    }
    setState(() {
      _pages.removeAt(index);
      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentPage < _pages.length) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  void _movePage(int from, int to) {
    setState(() {
      final page = _pages.removeAt(from);
      _pages.insert(to, page);
      _currentPage = to;
    });
    _pageController.animateToPage(
      to,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
