import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String label;
  final String searchHint;
  final T? selectedItem;
  final String Function(T) itemAsString;
  final bool Function(T, String) searchMatcher;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.label,
    required this.searchHint,
    this.selectedItem,
    required this.itemAsString,
    required this.searchMatcher,
    required this.onChanged,
    this.validator,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  bool _isOpen = false;
  late FocusNode _myFocusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _myFocusNode = widget.focusNode ?? FocusNode();
    _myFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _myFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _myFocusNode.dispose();
    }
    _close();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_myFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpen) {
          _open();
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _open() {
    if (_isOpen) return;
    setState(() => _isOpen = true);

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(6),
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(0.2),
            child: _DropdownList<T>(
              items: widget.items,
              searchHint: widget.searchHint,
              itemAsString: widget.itemAsString,
              searchMatcher: widget.searchMatcher,
              selectedItem: widget.selectedItem,
              onSelected: (item) {
                widget.onChanged(item);
                _close();
                // Request focus for next field if available
                if (widget.nextFocusNode != null) {
                  widget.nextFocusNode!.requestFocus();
                } else {
                  _myFocusNode.requestFocus();
                }
              },
              onClose: () {
                _close();
                _myFocusNode.requestFocus();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _close() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: widget.validator,
      initialValue: widget.selectedItem,
      builder: (state) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
            focusNode: _myFocusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.tab) {
                  if (!HardwareKeyboard.instance.isShiftPressed) {
                    if (widget.nextFocusNode != null) {
                      widget.nextFocusNode!.requestFocus();
                      return KeyEventResult.handled;
                    }
                  }
                }
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (!_isOpen) {
                    _open();
                    return KeyEventResult.handled;
                  }
                }
              }
              return KeyEventResult.ignored;
            },
            child: InkWell(
              onTap: _isOpen ? _close : _open,
              borderRadius: BorderRadius.circular(6),
              canRequestFocus: false,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: state.hasError
                        ? AppColors.breakdown
                        : _myFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.border,
                    width: _myFocusNode.hasFocus || state.hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.selectedItem != null
                            ? widget.itemAsString(widget.selectedItem!)
                            : 'Select ${widget.label}',
                        style: TextStyle(
                          color: widget.selectedItem != null
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: _myFocusNode.hasFocus ? AppColors.primary : AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DropdownList<T> extends StatefulWidget {
  final List<T> items;
  final String searchHint;
  final String Function(T) itemAsString;
  final bool Function(T, String) searchMatcher;
  final T? selectedItem;
  final ValueChanged<T> onSelected;
  final VoidCallback onClose;

  const _DropdownList({
    required this.items,
    required this.searchHint,
    required this.itemAsString,
    required this.searchMatcher,
    this.selectedItem,
    required this.onSelected,
    required this.onClose,
  });

  @override
  State<_DropdownList<T>> createState() => _DropdownListState<T>();
}

class _DropdownListState<T> extends State<_DropdownList<T>> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<T> _filtered = [];
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    if (widget.selectedItem != null) {
      final idx = widget.items.indexOf(widget.selectedItem!);
      if (idx != -1) _focusedIndex = idx;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.items;
      } else {
        final query = q.toLowerCase();
        // 1. Filter matching items
        final matching = widget.items.where((i) => widget.searchMatcher(i, q)).toList();
        
        // 2. Sort: nearest startsWith matches first, then contains matches
        matching.sort((a, b) {
          final strA = widget.itemAsString(a).toLowerCase();
          final strB = widget.itemAsString(b).toLowerCase();
          
          final startsA = strA.startsWith(query);
          final startsB = strB.startsWith(query);
          
          if (startsA && !startsB) return -1;
          if (!startsA && startsB) return 1;
          
          // Secondary alphabetical sort
          return strA.compareTo(strB);
        });
        
        _filtered = matching;
      }
      _focusedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              if (_filtered.isNotEmpty) {
                _focusedIndex = (_focusedIndex + 1) % _filtered.length;
              }
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              if (_filtered.isNotEmpty) {
                _focusedIndex = (_focusedIndex - 1 + _filtered.length) % _filtered.length;
              }
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
            if (_filtered.isNotEmpty && _focusedIndex >= 0 && _focusedIndex < _filtered.length) {
              widget.onSelected(_filtered[_focusedIndex]);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onClose();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            SizedBox(
              height: 30,
              child: TextField(
                controller: _ctrl,
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: _filter,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 14, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: _filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No results found',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = _filtered[i];
                        final isFocused = i == _focusedIndex;
                        final isSelected = item == widget.selectedItem;

                        return InkWell(
                          onTap: () => widget.onSelected(item),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 28),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? AppColors.primary.withOpacity(0.08)
                                  : isSelected
                                      ? AppColors.primary.withOpacity(0.04)
                                      : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.itemAsString(item),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isFocused || isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: isFocused || isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, size: 12, color: AppColors.primary),
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
    );
  }
}
