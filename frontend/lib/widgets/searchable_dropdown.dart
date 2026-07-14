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
  final IconData? prefixIcon;

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
    this.prefixIcon,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  bool _isOpen = false;
  late FocusNode _myFocusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final TextEditingController _textCtrl;

  List<T> _filteredItems = [];
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _myFocusNode = widget.focusNode ?? FocusNode();
    _myFocusNode.addListener(_handleFocusChange);
    
    // Set up the key listener directly on the FocusNode to handle Arrow Up/Down and Enter
    _myFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (!_isOpen) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _open();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            if (_filteredItems.isNotEmpty) {
              _focusedIndex = (_focusedIndex + 1) % _filteredItems.length;
              _overlayEntry?.markNeedsBuild();
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            if (_filteredItems.isNotEmpty) {
              _focusedIndex = (_focusedIndex - 1 + _filteredItems.length) % _filteredItems.length;
              _overlayEntry?.markNeedsBuild();
            }
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          final formFieldState = context.findAncestorStateOfType<FormFieldState<T>>();
          if (_filteredItems.isNotEmpty && _focusedIndex >= 0 && _focusedIndex < _filteredItems.length) {
            if (formFieldState != null) {
              _selectItem(_filteredItems[_focusedIndex], formFieldState);
            } else {
              widget.onChanged(_filteredItems[_focusedIndex]);
              _close();
              _updateText();
            }
          } else {
            _close();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _textCtrl = TextEditingController();
    _updateText();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _myFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _myFocusNode.dispose();
    }
    _textCtrl.dispose();
    _close();
    super.dispose();
  }

  void _updateText() {
    final text = widget.selectedItem != null ? widget.itemAsString(widget.selectedItem!) : '';
    if (_textCtrl.text != text) {
      _textCtrl.text = text;
    }
  }

  void _handleFocusChange() {
    if (_myFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isOpen) {
          _filter(_textCtrl.text);
          _open();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _close();
          _updateText(); // Revert back to actual selected item if focus is lost with invalid text
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _filter(String q) {
    if (q.isEmpty) {
      _filteredItems = widget.items;
    } else {
      final query = q.toLowerCase();
      final matching = widget.items.where((i) => widget.searchMatcher(i, q)).toList();
      
      matching.sort((a, b) {
        final strA = widget.itemAsString(a).toLowerCase();
        final strB = widget.itemAsString(b).toLowerCase();
        
        final startsA = strA.startsWith(query);
        final startsB = strB.startsWith(query);
        
        if (startsA && !startsB) return -1;
        if (!startsA && startsB) return 1;
        
        return strA.compareTo(strB);
      });
      _filteredItems = matching;
    }

    if (_focusedIndex >= _filteredItems.length) {
      _focusedIndex = 0;
    }
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
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  if (_filteredItems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No results found',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    );
                  }
                  final formFieldState = context.findAncestorStateOfType<FormFieldState<T>>();

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredItems.length,
                    itemBuilder: (ctx, i) {
                      final item = _filteredItems[i];
                      final isFocused = i == _focusedIndex;
                      final isSelected = item == widget.selectedItem;

                      return InkWell(
                        onTap: () {
                          if (formFieldState != null) {
                            _selectItem(item, formFieldState);
                          } else {
                            widget.onChanged(item);
                            _close();
                            _updateText();
                          }
                        },
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
                  );
                }
              ),
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

  void _selectItem(T item, FormFieldState<T> state) {
    widget.onChanged(item);
    state.didChange(item);
    _close();
    _updateText();
    if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    } else {
      _myFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      validator: widget.validator,
      initialValue: widget.selectedItem,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: SizedBox(
                height: 32,
                child: TextFormField(
                  focusNode: _myFocusNode,
                  controller: _textCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Type to select ${widget.label}',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    suffixIcon: Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: state.hasError
                          ? AppColors.breakdown
                          : _myFocusNode.hasFocus
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      size: 18,
                    ),
                    prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 14, color: AppColors.textSecondary) : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: state.hasError ? AppColors.breakdown : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: state.hasError ? AppColors.breakdown : AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: state.hasError ? AppColors.breakdown : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filter(val);
                      state.didChange(null);
                      widget.onChanged(null);
                      if (!_isOpen) {
                        _open();
                      } else {
                        _overlayEntry?.markNeedsBuild();
                      }
                    });
                  },
                ),
              ),
            ),
            if (state.hasError && state.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: AppColors.breakdown, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        );
      },
    );
  }
}
