import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';
import '../models/supplier.dart';
import '../providers/production_provider.dart';
import '../screens/materials/add_edit_supplier_dialog.dart';

class SearchableSupplierPicker extends StatefulWidget {
  final List<Supplier> suppliers;
  final String selectedSupplierName;
  final ValueChanged<Supplier> onSelected;
  final VoidCallback? onAddNew;
  final TextEditingController? controller;

  const SearchableSupplierPicker({
    super.key,
    required this.suppliers,
    required this.selectedSupplierName,
    required this.onSelected,
    this.onAddNew,
    this.controller,
  });

  @override
  State<SearchableSupplierPicker> createState() => _SearchableSupplierPickerState();
}

class _SearchableSupplierPickerState extends State<SearchableSupplierPicker> {
  void _openSearchDialog() {
    showDialog<Supplier?>(
      context: context,
      builder: (ctx) {
        return _SupplierSearchDialog(
          suppliers: widget.suppliers,
          selectedName: widget.selectedSupplierName,
          onSelected: (supplier) {
            Navigator.of(ctx).pop(supplier);
            widget.onSelected(supplier);
          },
          onAddNew: () async {
            final newSupplier = await showDialog<Supplier?>(
              context: ctx,
              builder: (_) => const AddEditSupplierDialog(),
            );
            if (newSupplier != null && ctx.mounted) {
              Navigator.of(ctx).pop(newSupplier);
              widget.onSelected(newSupplier);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    String lang = 'en';
    try {
      lang = context.watch<ProductionProvider?>()?.settings.appLanguage ?? 'en';
    } catch (_) {
      lang = 'en';
    }
    final hasSelection = widget.selectedSupplierName.trim().isNotEmpty && widget.selectedSupplierName.trim() != '-';

    return InkWell(
      onTap: _openSearchDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasSelection ? AppTheme.primaryBlue : AppTheme.border(context),
            width: hasSelection ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 20,
              color: hasSelection ? AppTheme.primaryBlue : AppTheme.textMuted(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: hasSelection
                  ? Text(
                      widget.selectedSupplierName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      AppStrings.t(lang, en: 'Search & Select Supplier...', gu: 'સપ્લાયર શોધો અને પસંદ કરો...', hi: 'सप्लायर खोजें और चुनें...'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.hintColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  Text('Search', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
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

class _SupplierSearchDialog extends StatefulWidget {
  final List<Supplier> suppliers;
  final String selectedName;
  final ValueChanged<Supplier> onSelected;
  final VoidCallback? onAddNew;

  const _SupplierSearchDialog({
    required this.suppliers,
    required this.selectedName,
    required this.onSelected,
    this.onAddNew,
  });

  @override
  State<_SupplierSearchDialog> createState() => _SupplierSearchDialogState();
}

class _SupplierSearchDialogState extends State<_SupplierSearchDialog> {
  static const double _kItemHeight = 58.0;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _filter = '';
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    // If an existing supplier is selected, find its index and highlight it
    if (widget.selectedName.trim().isNotEmpty) {
      final initialIdx = widget.suppliers.indexWhere((s) =>
          s.name.trim().toLowerCase() == widget.selectedName.trim().toLowerCase());
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

  List<Supplier> _getFiltered() {
    if (_filter.trim().isEmpty) {
      return widget.suppliers;
    }
    final q = _filter.trim().toLowerCase();
    return widget.suppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q);
    }).toList();
  }

  void _selectHighlighted(List<Supplier> filtered) {
    if (filtered.isNotEmpty) {
      final index = _highlightedIndex.clamp(0, filtered.length - 1);
      widget.onSelected(filtered[index]);
    } else if (_filter.trim().isNotEmpty) {
      widget.onSelected(Supplier(name: _filter.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();
    final isDark = AppTheme.isDark(context);
    final activeIndex = filtered.isEmpty ? 0 : _highlightedIndex.clamp(0, filtered.length - 1);
    String lang = 'en';
    try {
      lang = context.read<ProductionProvider?>()?.settings.appLanguage ?? 'en';
    } catch (_) {
      lang = 'en';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardBg(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 20, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(lang, en: 'Select Supplier / Party', gu: 'સપ્લાયર / પાર્ટી પસંદ કરો', hi: 'सप्लायर / पार्टी चुनें'),
                          style: TextStyle(
                            fontSize: 16,
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

              // Search Text Field with keyboard listener & auto-scroll
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
                    hintText: 'Type to search supplier name or phone... (Press Enter to pick)',
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
              const SizedBox(height: 10),

              // Results Count & Add New button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} suppliers found',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted(context)),
                  ),
                  if (widget.onAddNew != null)
                    TextButton.icon(
                      onPressed: widget.onAddNew,
                      icon: const Icon(Icons.add_business_rounded, size: 16),
                      label: const Text('New Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Suppliers List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 44, color: AppTheme.textMuted(context)),
                            const SizedBox(height: 10),
                            Text(
                              AppStrings.t(lang, en: 'No suppliers found', gu: 'કોઈ સપ્લાયર મળ્યા નથી', hi: 'कोई सप्लायर नहीं मिला'),
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                            ),
                            if (widget.onAddNew != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: widget.onAddNew,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add This Supplier Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                            if (_filter.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => widget.onSelected(Supplier(name: _filter.trim())),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: Text('Use "${_filter.trim()}" directly (↵ Enter)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary(context),
                                  side: BorderSide(color: AppTheme.border(context)),
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
                          final supplier = filtered[i];
                          final isHighlighted = i == activeIndex;
                          final isSelected = widget.selectedName.trim().toLowerCase() ==
                              supplier.name.trim().toLowerCase();

                          return InkWell(
                            onTap: () => widget.onSelected(supplier),
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
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isHighlighted
                                        ? AppTheme.primaryBlue
                                        : AppTheme.primaryBlue.withValues(alpha: 0.15),
                                    child: Text(
                                      supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isHighlighted ? Colors.white : AppTheme.primaryBlue,
                                      ),
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
                                                supplier.name,
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
                                        if (supplier.phone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_outlined,
                                                  size: 13, color: AppTheme.textMuted(context)),
                                              const SizedBox(width: 4),
                                              Text(
                                                supplier.phone,
                                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check_circle_rounded,
                                          size: 18, color: AppTheme.successGreenDark),
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
