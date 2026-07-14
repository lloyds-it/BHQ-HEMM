import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/project.dart';
import '../models/equipment.dart';
import '../models/operator.dart';
import '../providers/master_provider.dart';
import '../core/file_downloader.dart';
import '../widgets/logo_header.dart';

class ReportsScreen extends StatefulWidget {
  final bool isEmbed;
  const ReportsScreen({super.key, this.isEmbed = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiClient _apiClient = ApiClient();
  final _fmt = DateFormat('dd MMM yy');

  String _selectedReportType = 'Live Entry Report';
  DateTime? _startDate;
  DateTime? _endDate;
  Project? _selectedProject;
  Equipment? _selectedEquipment;
  Operator? _selectedOperator;
  String? _selectedActivity;
  String? _selectedShift;
  bool _isExporting = false;
  bool _isLoadingPreview = false;

  // Inline preview data
  List<Map<String, dynamic>> _previewRows = [];
  List<String> _previewColumns = [];
  String? _previewError;
  bool _hasPreview = false;

  // Focus nodes for keyboard support
  final FocusNode _reportTypeFocus = FocusNode();
  final FocusNode _startFocus = FocusNode();
  final FocusNode _endFocus = FocusNode();
  final FocusNode _projectFocus = FocusNode();
  final FocusNode _equipmentFocus = FocusNode();
  final FocusNode _operatorFocus = FocusNode();
  final FocusNode _activityFocus = FocusNode();
  final FocusNode _shiftFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = Provider.of<MasterProvider>(context, listen: false);
      m.fetchProjects();
      m.fetchEquipment();
      m.fetchOperators();
    });
  }

  @override
  void dispose() {
    _reportTypeFocus.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    _projectFocus.dispose();
    _equipmentFocus.dispose();
    _operatorFocus.dispose();
    _activityFocus.dispose();
    _shiftFocus.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _endFocus.requestFocus();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _projectFocus.requestFocus();
    }
  }

  void _clearFilters() => setState(() {
        _startDate = null;
        _endDate = null;
        _selectedProject = null;
        _selectedEquipment = null;
        _selectedOperator = null;
        _selectedActivity = null;
        _selectedShift = null;
        _previewRows = [];
        _previewColumns = [];
        _hasPreview = false;
        _previewError = null;
      });

  Map<String, String> _buildQueryParams(String format) {
    final p = <String, String>{'format': format};
    if (_startDate != null) p['startDate'] = _startDate!.toIso8601String();
    if (_endDate != null) p['endDate'] = _endDate!.toIso8601String();
    if (_selectedProject != null) p['projectId'] = _selectedProject!.projectId!.toString();
    if (_selectedEquipment != null) p['equipmentId'] = _selectedEquipment!.equipmentId!.toString();
    if (_selectedOperator != null) p['operatorId'] = _selectedOperator!.operatorId!.toString();
    if (_selectedActivity != null) p['activityType'] = _selectedActivity!;
    if (_selectedShift != null) p['shift'] = _selectedShift!;
    return p;
  }

  String _endpointFor(String reportType) {
    switch (reportType) {
      case 'Summary Log Report': return 'summary-logs';
      case 'Equipment Report': return 'equipment';
      case 'Operator Report': return 'operators';
      default: return 'live-entries';
    }
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoadingPreview = true;
      _previewError = null;
    });
    try {
      final params = _buildQueryParams('json');
      final endpoint = _endpointFor(_selectedReportType);
      final data = await _apiClient.getReportData(endpoint, params);
      if (data is List) {
        if (data.isNotEmpty) {
          final cols = (data.first as Map<String, dynamic>).keys.toList();
          setState(() {
            _previewColumns = cols;
            _previewRows = data.cast<Map<String, dynamic>>();
            _hasPreview = true;
          });
        } else {
          setState(() {
            _previewColumns = [];
            _previewRows = [];
            _hasPreview = true;
          });
        }
      } else {
        throw Exception('Response is not a list structure');
      }
    } catch (e) {
      setState(() {
        _previewError = e.toString();
        _hasPreview = true;
      });
    } finally {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);
    try {
      final params = _buildQueryParams(format);
      final endpoint = _endpointFor(_selectedReportType);
      final url = _apiClient.getReportUrl(endpoint, params);
      final filename =
          '${_selectedReportType.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.$format';
      if (kIsWeb) {
        FileDownloader.download(url, filename);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$filename download started'),
          backgroundColor: AppColors.running,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.breakdown));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final master = Provider.of<MasterProvider>(context);

    final mainLayout = Column(
      children: [
        // ── Filter panel ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildFilterPanel(master),
        ),
        Container(height: 1, color: AppColors.border),
        // ── Result area ──
        Expanded(
          child: _buildResultArea(),
        ),
      ],
    );

    if (widget.isEmbed) {
      return mainLayout;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        toolbarHeight: 44,
        titleSpacing: 8,
        title: Row(children: [
          const LogoHeader(height: 20),
          const SizedBox(width: 10),
          const Text('Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: mainLayout,
    );
  }

  Widget _buildFilterPanel(MasterProvider master) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Report type + dates + action buttons
        Row(
          children: [
            // Report Type
            _label('Report'),
            const SizedBox(width: 4),
            SizedBox(
              width: 140,
              height: 30,
              child: DropdownButtonFormField<String>(
                focusNode: _reportTypeFocus,
                value: _selectedReportType,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: const [
                  DropdownMenuItem(value: 'Live Entry Report', child: Text('Live Entry', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'Summary Log Report', child: Text('Summary Log', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'Equipment Report', child: Text('Equipment', style: TextStyle(fontSize: 11))),
                  DropdownMenuItem(value: 'Operator Report', child: Text('Operator', style: TextStyle(fontSize: 11))),
                ],
                onChanged: (v) {
                  setState(() => _selectedReportType = v ?? 'Live Entry Report');
                  _startFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 10),

            // Date From
            _label('From'),
            const SizedBox(width: 4),
            _datePicker(
              node: _startFocus,
              value: _startDate,
              hint: 'Start Date',
              onTap: _pickStartDate,
              onClear: () => setState(() => _startDate = null),
            ),
            const SizedBox(width: 6),

            // Date To
            _label('To'),
            const SizedBox(width: 4),
            _datePicker(
              node: _endFocus,
              value: _endDate,
              hint: 'End Date',
              onTap: _pickEndDate,
              onClear: () => setState(() => _endDate = null),
            ),
            const SizedBox(width: 10),

            // Project
            _label('Project'),
            const SizedBox(width: 4),
            SizedBox(
              width: 120,
              height: 30,
              child: DropdownButtonFormField<Project>(
                focusNode: _projectFocus,
                value: _selectedProject,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: [
                  const DropdownMenuItem<Project>(value: null, child: Text('All', style: TextStyle(fontSize: 11))),
                  ...master.projects.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.projectName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) {
                  setState(() => _selectedProject = v);
                  _equipmentFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 8),

            // Action Buttons
            const Spacer(),
            _btn(
              label: 'View',
              icon: Icons.search_rounded,
              color: AppColors.primary,
              onTap: _isLoadingPreview ? null : _loadPreview,
            ),
            const SizedBox(width: 6),
            if (_isExporting)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.running))
            else ...[
              _btn(
                label: 'Excel',
                icon: Icons.table_chart_rounded,
                color: AppColors.running,
                onTap: () => _exportReport('excel'),
              ),
              const SizedBox(width: 4),
              _btn(
                label: 'PDF',
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.breakdown,
                onTap: () => _exportReport('pdf'),
              ),
            ],
            const SizedBox(width: 4),
            _btn(
              label: 'Clear',
              icon: Icons.clear_rounded,
              color: AppColors.textSecondary,
              onTap: _clearFilters,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Row 2: Equipment + Operator + Activity + Shift
        Row(
          children: [
            _label('Equipment'),
            const SizedBox(width: 4),
            SizedBox(
              width: 130,
              height: 30,
              child: DropdownButtonFormField<Equipment>(
                focusNode: _equipmentFocus,
                value: _selectedEquipment,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: [
                  const DropdownMenuItem<Equipment>(value: null, child: Text('All', style: TextStyle(fontSize: 11))),
                  ...master.equipment.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.equipmentNumber, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) {
                  setState(() => _selectedEquipment = v);
                  _operatorFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 10),

            _label('Operator'),
            const SizedBox(width: 4),
            SizedBox(
              width: 130,
              height: 30,
              child: DropdownButtonFormField<Operator>(
                focusNode: _operatorFocus,
                value: _selectedOperator,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: [
                  const DropdownMenuItem<Operator>(value: null, child: Text('All', style: TextStyle(fontSize: 11))),
                  ...master.operators.map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o.operatorName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) {
                  setState(() => _selectedOperator = v);
                  _activityFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 10),

            _label('Activity'),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              height: 30,
              child: DropdownButtonFormField<String>(
                focusNode: _activityFocus,
                value: _selectedActivity,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('All', style: TextStyle(fontSize: 11))),
                  ...AppConstants.activities.map((a) => DropdownMenuItem(
                      value: a, child: Text(a, style: const TextStyle(fontSize: 11)))),
                ],
                onChanged: (v) {
                  setState(() => _selectedActivity = v);
                  _shiftFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(width: 10),

            _label('Shift'),
            const SizedBox(width: 4),
            SizedBox(
              width: 80,
              height: 30,
              child: DropdownButtonFormField<String>(
                focusNode: _shiftFocus,
                value: _selectedShift,
                isExpanded: true,
                isDense: true,
                decoration: _dec(),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('All', style: TextStyle(fontSize: 11))),
                  ...AppConstants.shifts.map((s) => DropdownMenuItem(
                      value: s, child: Text(s, style: const TextStyle(fontSize: 11)))),
                ],
                onChanged: (v) => setState(() => _selectedShift = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultArea() {
    if (_isLoadingPreview) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!_hasPreview) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_view_rounded, size: 48, color: AppColors.primary.withOpacity(0.25)),
            const SizedBox(height: 10),
            const Text('Select filters and click  View  to load report data inline',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Text('Use Excel / PDF buttons to download.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
    }
    if (_previewError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.breakdown),
            const SizedBox(height: 8),
            Text(_previewError!, style: const TextStyle(fontSize: 12, color: AppColors.breakdown)),
          ],
        ),
      );
    }
    if (_previewRows.isEmpty) {
      return const Center(
        child: Text('No data matching the filter criteria found.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    return Column(
      children: [
        // Table info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: AppColors.primary.withOpacity(0.04),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$_selectedReportType  •  ${_previewRows.length} record${_previewRows.length == 1 ? '' : 's'} loaded',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              if (_startDate != null && _endDate != null) ...[
                const Text('  |  ', style: TextStyle(color: AppColors.border)),
                Text('${_fmt.format(_startDate!)} → ${_fmt.format(_endDate!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        // Data Preview Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: _buildDataTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    final visibleCols = _previewColumns.where((c) => !c.toLowerCase().contains('id')).toList();

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.5),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // Table Header
        TableRow(
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08)),
          children: visibleCols.map((col) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              _formatHeader(col),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          )).toList(),
        ),
        // Table Body Rows
        ..._previewRows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return TableRow(
            decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFFAFAFA)),
            children: visibleCols.map((col) {
              final val = entry.value[col];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  _formatValue(col, val),
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  String _formatHeader(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatValue(String col, dynamic val) {
    if (val == null) return '-';
    final colLower = col.toLowerCase();
    if (colLower.contains('timestamp') || colLower.contains('date')) {
      try {
        final dt = DateTime.parse(val.toString()).toLocal();
        return DateFormat('dd MMM yy HH:mm').format(dt);
      } catch (_) {}
    }
    if (val is double) {
      return val.toStringAsFixed(2);
    }
    return val.toString();
  }

  // Helpers
  InputDecoration _dec() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      );

  Widget _datePicker({
    required FocusNode node,
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Focus(
      focusNode: node,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: node.hasFocus ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 12,
                  color: value != null ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                value != null ? _fmt.format(value) : hint,
                style: TextStyle(
                    fontSize: 11,
                    color: value != null ? AppColors.textPrimary : AppColors.textMuted),
              ),
              if (value != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade100 : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: onTap == null ? AppColors.border : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: onTap == null ? AppColors.textMuted : color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: onTap == null ? AppColors.textMuted : color)),
          ],
        ),
      ),
    );
  }
}
