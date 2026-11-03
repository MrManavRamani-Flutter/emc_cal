import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/material_product.dart';

class SearchableProductPicker extends StatefulWidget {
  final List<MaterialProduct> products;
  final MaterialProduct? selectedProduct;
  final ValueChanged<MaterialProduct> onSelected;
  final VoidCallback? onAddNew;
  final String category;

  const SearchableProductPicker({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onSelected,
    this.onAddNew,
    required this.category,
  });

  @override
  State<SearchableProductPicker> createState() => _SearchableProductPickerState();
}

class _SearchableProductPickerState extends State<SearchableProductPicker> {
  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return _ProductSearchDialog(
          products: widget.products,
          selectedProduct: widget.selectedProduct,
          category: widget.category,
          onSelected: (prod) {
            Navigator.of(ctx).pop();
            widget.onSelected(prod);
          },
          onAddNew: widget.onAddNew != null
              ? () {
                  Navigator.of(ctx).pop();
                  widget.onAddNew!();
                }
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final sel = widget.selectedProduct;

    return InkWell(
      onTap: _openSearchDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel != null ? AppTheme.primaryBlue : AppTheme.border(context),
            width: sel != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: sel != null ? AppTheme.primaryBlue : AppTheme.textMuted(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: sel != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sel.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Default Rate: ₹ ${sel.defaultRate.toStringAsFixed(2)} / ${sel.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successGreenDark,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Search & Select Product (${widget.category})...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.hintColor(context),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchDialog extends StatefulWidget {
  final List<MaterialProduct> products;
  final MaterialProduct? selectedProduct;
  final String category;
  final ValueChanged<MaterialProduct> onSelected;
  final VoidCallback? onAddNew;

  const _ProductSearchDialog({
    required this.products,
    this.selectedProduct,
    required this.category,
    required this.onSelected,
    this.onAddNew,
  });

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  static const double _kItemHeight = 64.0;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _filter = '';
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    // If an existing product is selected, find its index and highlight it
    if (widget.selectedProduct != null) {
      final initialIdx = widget.products.indexWhere((p) =>
          p.id == widget.selectedProduct!.id ||
          p.name.trim().toLowerCase() == widget.selectedProduct!.name.trim().toLowerCase());
      if (initialIdx >= 0) {
        _highlightedIndex = initialIdx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToIndex(initialIdx, center: true, animate: false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, {bool center = false, bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final double viewport = position.viewportDimension;
    final double maxScroll = position.maxScrollExtent;
    final double currentScroll = _scrollController.offset;

    if (viewport <= 0 || (maxScroll <= 0 && index > 3)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToIndex(index, center: center, animate: animate);
      });
      return;
    }

    double targetOffset;
    if (center) {
      final double itemCenter = (index * _kItemHeight) + (_kItemHeight / 2.0);
      targetOffset = (itemCenter - (viewport / 2.0)).clamp(0.0, maxScroll);
    } else {
      final double itemTop = index * _kItemHeight;
      final double itemBottom = itemTop + _kItemHeight;

      // When the selected item goes below the visible scroll viewport
      if (itemBottom > (currentScroll + viewport)) {
        targetOffset = (itemBottom - viewport + 12.0).clamp(0.0, maxScroll);
      }
      // When the selected item goes above the visible scroll viewport
      else if (itemTop < currentScroll) {
        targetOffset = (itemTop - 12.0).clamp(0.0, maxScroll);
      } else {
        return; // Already in view
      }
    }

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  void _selectHighlighted(List<MaterialProduct> filtered) {
    if (filtered.isEmpty) return;
    final idx = _highlightedIndex.clamp(0, filtered.length - 1);
    widget.onSelected(filtered[idx]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final filtered = widget.products.where((p) {
      if (_filter.trim().isEmpty) return true;
      final q = _filter.trim().toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.unit.toLowerCase().contains(q) ||
          p.defaultRate.toString().contains(q);
    }).toList();
    final activeIndex = filtered.isEmpty ? 0 : _highlightedIndex.clamp(0, filtered.length - 1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.search_rounded, size: 22, color: AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select ${widget.category} Product',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          'Use ↑ / ↓ keys and press Enter to select instantly',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Text Field with keyboard arrows & enter
              Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = (_highlightedIndex + 1).clamp(0, filtered.length - 1);
                        });
                        _scrollToIndex(_highlightedIndex);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = (_highlightedIndex - 1).clamp(0, filtered.length - 1);
                        });
                        _scrollToIndex(_highlightedIndex);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = (_highlightedIndex + 5).clamp(0, filtered.length - 1);
                        });
                        _scrollToIndex(_highlightedIndex);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = (_highlightedIndex - 5).clamp(0, filtered.length - 1);
                        });
                        _scrollToIndex(_highlightedIndex);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.home) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = 0;
                        });
                        _scrollToIndex(0);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.end) {
                      if (filtered.isNotEmpty) {
                        setState(() {
                          _highlightedIndex = filtered.length - 1;
                        });
                        _scrollToIndex(_highlightedIndex);
                        return KeyEventResult.handled;
                      }
                    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                      if (filtered.isNotEmpty) {
                        _selectHighlighted(filtered);
                        return KeyEventResult.handled;
                      }
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  onSubmitted: (_) => _selectHighlighted(filtered),
                  onChanged: (val) {
                    setState(() {
                      _filter = val;
                      _highlightedIndex = 0;
                    });
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0.0);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Type to search product name, rate, or unit... (Enter to pick)',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _filter = '';
                                _highlightedIndex = 0;
                              });
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0.0);
                              }
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Results Count & Add New button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} products available',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                  ),
                  if (widget.onAddNew != null)
                    TextButton.icon(
                      onPressed: widget.onAddNew,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Product Master', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Products List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textMuted(context)),
                            const SizedBox(height: 10),
                            Text(
                              'No matching products found',
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                            ),
                            if (widget.onAddNew != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: widget.onAddNew,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add This Product Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (ctx, i) {
                          final prod = filtered[i];
                          final isHighlighted = i == activeIndex;
                          final isSelected = widget.selectedProduct != null &&
                              (widget.selectedProduct!.id == prod.id ||
                               widget.selectedProduct!.name.trim().toLowerCase() ==
                                   prod.name.trim().toLowerCase());

                          return InkWell(
                            onTap: () => widget.onSelected(prod),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isHighlighted
                                    ? AppTheme.primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isSelected
                                        ? AppTheme.successGreenDark.withValues(alpha: 0.1)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isHighlighted
                                      ? AppTheme.primaryBlue
                                      : (isSelected
                                          ? AppTheme.successGreenDark.withValues(alpha: 0.5)
                                          : Colors.transparent),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isHighlighted
                                          ? AppTheme.primaryBlue
                                          : AppTheme.primaryBlue.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.style_rounded,
                                      size: 16,
                                      color: isHighlighted ? Colors.white : AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                prod.name,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimary(context),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isHighlighted)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  '↵ Enter',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Unit: ${prod.unit}${prod.defaultMtr > 0 ? " | ${prod.defaultMtr}m" : ""}',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreenDark.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.successGreenDark.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '₹ ${prod.defaultRate.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.successGreenDark,
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: AppTheme.successGreenDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
