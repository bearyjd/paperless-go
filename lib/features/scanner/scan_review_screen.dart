import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'crop_screen.dart';
import 'processing/crop_rotate.dart';

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
  bool _isProcessing = false;

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
        title: Text(
          'Review (${_pages.length} ${_pages.length == 1 ? 'page' : 'pages'})',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
              onPressed: _pages.isNotEmpty && !_isProcessing
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
                  child: Stack(
                    children: [
                      PageView.builder(
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
                      if (_isProcessing)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
                // Controls row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Delete
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _removePage(_currentPage),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove page',
                      ),
                      // Rotate CCW
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _rotatePage(clockwise: false),
                        icon: const Icon(Icons.rotate_left),
                        tooltip: 'Rotate left',
                      ),
                      // Rotate CW
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _rotatePage(clockwise: true),
                        icon: const Icon(Icons.rotate_right),
                        tooltip: 'Rotate right',
                      ),
                      // Crop
                      IconButton(
                        onPressed: _isProcessing ? null : _cropPage,
                        icon: const Icon(Icons.crop),
                        tooltip: 'Crop',
                      ),
                      const Spacer(),
                      // Page indicator
                      Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      // Reorder
                      IconButton(
                        onPressed: _isProcessing || _currentPage <= 0
                            ? null
                            : () => _movePage(_currentPage, _currentPage - 1),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Move left',
                      ),
                      IconButton(
                        onPressed:
                            _isProcessing || _currentPage >= _pages.length - 1
                            ? null
                            : () => _movePage(_currentPage, _currentPage + 1),
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Move right',
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
                          child: Image.file(File(_pages[i]), fit: BoxFit.cover),
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

  Future<void> _rotatePage({required bool clockwise}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final oldPath = _pages[_currentPage];
      final newPath = await CropRotate.rotateImage90(
        inputPath: oldPath,
        clockwise: clockwise,
      );
      if (!mounted) return;
      // Evict only the old image from Flutter's cache instead of clearing
      // the entire cache, which would affect unrelated screens.
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = newPath;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rotate failed: $e')));
    }
  }

  Future<void> _cropPage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(imagePath: _pages[_currentPage]),
      ),
    );
    if (result != null && mounted) {
      // Evict only the old image from Flutter's cache
      final oldPath = _pages[_currentPage];
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = result;
      });
    }
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
