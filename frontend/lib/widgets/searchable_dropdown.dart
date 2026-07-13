import 'package:flutter/material.dart';
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
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _SearchSheetBody<T>(
          items: widget.items,
          searchHint: widget.searchHint,
          itemAsString: widget.itemAsString,
          searchMatcher: widget.searchMatcher,
          onSelected: (item) {
            widget.onChanged(item);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0),
        FormField<T>(
          validator: widget.validator,
          initialValue: widget.selectedItem,
          builder: (state) {
            return InkWell(
              onTap: () => _showSearchSheet(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.inputHorizontalPadding,
                  vertical: AppTheme.inputVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.hasError ? AppColors.breakdown : AppColors.border,
                    width: state.hasError ? 1.5 : 1,
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
                          fontSize: AppTheme.isCompact ? 12 : 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _SearchSheetBody<T> extends StatefulWidget {
  final List<T> items;
  final String searchHint;
  final String Function(T) itemAsString;
  final bool Function(T, String) searchMatcher;
  final ValueChanged<T> onSelected;

  const _SearchSheetBody({
    required this.items,
    required this.searchHint,
    required this.itemAsString,
    required this.searchMatcher,
    required this.onSelected,
  });

  @override
  State<_SearchSheetBody<T>> createState() => _SearchSheetBodyState<T>();
}

class _SearchSheetBodyState<T> extends State<_SearchSheetBody<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget.searchMatcher(item, query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      height: MediaQuery.of(context).size.height * 0.55 + bottomInset,
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TextField(
            controller: _searchController,
            onChanged: _filterItems,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Text('No results found',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        dense: true,
                        title: Text(widget.itemAsString(item),
                            style: TextStyle(fontSize: AppTheme.isCompact ? 13 : 14)),
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}
