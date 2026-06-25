import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nesd/ui/common/rom_tile.dart';

class PaginatedGrid extends HookConsumerWidget {
  const PaginatedGrid({
    this.tileWidth = gameTileWidth,
    this.tileHeight = gameTileHeight,
    this.skipRows = 0,
    this.children = const [],
    super.key,
  });

  final List<Widget> children;
  final int skipRows;

  final double tileWidth;
  final double tileHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(0);
    final pageController = useMemoized(() => PageController(), []);

    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(mediaQuery.size.width, constraints.maxWidth) - 80;
        final height = min(mediaQuery.size.height, constraints.maxHeight);

        final columnCount = max(1, width ~/ tileWidth);
        final rowCount = max(1, height ~/ tileHeight - skipRows);

        final count = columnCount * rowCount;

        final pages = count > 0 ? (children.length / count).ceil() : 1;

        final currentPage = page.value.clamp(0, pages - 1);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 40,
              height: rowCount * tileHeight,
              child: currentPage > 0
                  ? InkWell(
                      onTap: () {
                        final newPage = currentPage - 1;
                        page.value = newPage;
                        pageController.animateToPage(
                          newPage,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_back_ios),
                    )
                  : const SizedBox(),
            ),
            Expanded(
              child: SizedBox(
                height: rowCount * tileHeight,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: pages,
                  onPageChanged: (index) => page.value = index,
                  itemBuilder: (context, pageIndex) {
                    final romPaths = children
                        .skip(pageIndex * count)
                        .take(count)
                        .toList();
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final row in romPaths.slices(columnCount))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: row,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: 40,
              height: rowCount * tileHeight,
              child: currentPage < pages - 1
                  ? InkWell(
                      onTap: () {
                        final newPage = currentPage + 1;
                        page.value = newPage;
                        pageController.animateToPage(
                          newPage,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_forward_ios),
                    )
                  : const SizedBox(),
            ),
          ],
        );
      },
    );
  }
}
