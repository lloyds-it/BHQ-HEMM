import 'package:flutter/material.dart';
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
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiClient _apiClient = ApiClient();

  String _selectedReportType = 'Live Entry Report';
  DateTime? _startDate;
  DateTime? _endDate;
  Project? _selectedProject;
  Equipment? _selectedEquipment;
  Operator? _selectedOperator;
  String? _selectedActivity;
  String? _selectedShift;
  bool _isExporting = false;

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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
    }
  }

  void _clearFilters() => setState(() {
    _startDate = null; _endDate = null;
    _selectedProject = null; _selectedEquipment = null;
    _selectedOperator = null; _selectedActivity = null; _selectedShift = null;
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
      case 'Equipment Report':   return 'equipment';
      case 'Operator Report':    return 'operators';
      default:                   return 'live-entries';
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);
    try {
      final params = _buildQueryParams(format);
      final endpoint = _endpointFor(_selectedReportType);
      final url = _apiClient.getReportUrl(endpoint, params);
      final filename = '${_selectedReportType.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.$format';

      if (kIsWeb) {
        FileDownloader.download(url, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.download_done_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$filename download started', style: const TextStyle(fontSize: 12)),
              ]),
              backgroundColor: AppColors.running,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        _showDownloadDialog(url, filename, format);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.breakdown),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showDownloadDialog(String url, String filename, String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(format == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded,
              color: format == 'pdf' ? AppColors.breakdown : AppColors.running, size: 20),
          const SizedBox(width: 8),
          Text('Export to ${format.toUpperCase()}', style: const TextStyle(fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report: $_selectedReportType', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(url, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open in Browser'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = Provider.of<MasterProvider>(context);
    final p = AppTheme.pagePadding;
    final fs = AppTheme.fieldSpacing;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Row(
          children: [
            const LogoHeader(height: 24),
            const SizedBox(width: 16),
            const Text('Reports & Exports'),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(p),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report type card
                _buildCard(
                  title: 'Report Type',
                  icon: Icons.assessment_rounded,
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.folder_special_rounded, size: 18),
                      hintText: 'Select report type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Live Entry Report', child: Text('Live Entry Report')),
                      DropdownMenuItem(value: 'Summary Log Report', child: Text('Summary Log Report')),
                      DropdownMenuItem(value: 'Equipment Report', child: Text('Equipment Report')),
                      DropdownMenuItem(value: 'Operator Report', child: Text('Operator Report')),
                    ],
                    onChanged: (v) => setState(() => _selectedReportType = v ?? 'Live Entry Report'),
                  ),
                ),
                SizedBox(height: p),

                // Filters card
                _buildCard(
                  title: 'Filter Criteria',
                  icon: Icons.tune_rounded,
                  trailing: TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 14),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.breakdown),
                  ),
                  child: Column(children: [
                    // Date range
                    GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.inputHorizontalPadding, vertical: AppTheme.inputVerticalPadding),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _startDate != null ? AppColors.primary : AppColors.border),
                        ),
                        child: Row(children: [
                          Icon(Icons.date_range_rounded, size: 18,
                              color: _startDate != null ? AppColors.primary : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd MMM yy').format(_startDate!)}  →  ${DateFormat('dd MMM yy').format(_endDate!)}'
                                : 'Select Date Range  (All dates)',
                            style: TextStyle(
                              color: _startDate != null ? AppColors.textPrimary : AppColors.textMuted,
                              fontSize: AppTheme.isCompact ? 12 : 13,
                            ),
                          )),
                          if (_startDate != null)
                            GestureDetector(
                              onTap: () => setState(() { _startDate = null; _endDate = null; }),
                              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                            ),
                        ]),
                      ),
                    ),
                    SizedBox(height: fs),

                    // Project + Equipment row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Project>(
                            value: _selectedProject,
                            decoration: const InputDecoration(labelText: 'Project', prefixIcon: Icon(Icons.location_city_rounded, size: 16)),
                            items: [
                              const DropdownMenuItem<Project>(value: null, child: Text('All Projects')),
                              ...master.projects.map((p) => DropdownMenuItem(value: p, child: Text(p.projectName))),
                            ],
                            onChanged: (v) => setState(() => _selectedProject = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<Equipment>(
                            value: _selectedEquipment,
                            decoration: const InputDecoration(labelText: 'Equipment', prefixIcon: Icon(Icons.local_shipping_rounded, size: 16)),
                            items: [
                              const DropdownMenuItem<Equipment>(value: null, child: Text('All Equipment')),
                              ...master.equipment.map((e) => DropdownMenuItem(value: e, child: Text(e.equipmentNumber))),
                            ],
                            onChanged: (v) => setState(() => _selectedEquipment = v),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fs),

                    // Operator + Activity row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Operator>(
                            value: _selectedOperator,
                            decoration: const InputDecoration(labelText: 'Operator', prefixIcon: Icon(Icons.person_rounded, size: 16)),
                            items: [
                              const DropdownMenuItem<Operator>(value: null, child: Text('All Operators')),
                              ...master.operators.map((o) => DropdownMenuItem(value: o, child: Text(o.operatorName))),
                            ],
                            onChanged: (v) => setState(() => _selectedOperator = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedActivity,
                            decoration: const InputDecoration(labelText: 'Activity', prefixIcon: Icon(Icons.pending_actions_rounded, size: 16)),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All Activities')),
                              ...AppConstants.activities.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                            ],
                            onChanged: (v) => setState(() => _selectedActivity = v),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: fs),

                    // Shift
                    DropdownButtonFormField<String>(
                      value: _selectedShift,
                      decoration: const InputDecoration(labelText: 'Shift', prefixIcon: Icon(Icons.schedule_rounded, size: 16)),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Shifts')),
                        ...AppConstants.shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) => setState(() => _selectedShift = v),
                    ),
                  ]),
                ),
                SizedBox(height: p),

                // Export buttons
                if (_isExporting)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ))
                else
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.running,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, AppTheme.buttonHeight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.table_chart_rounded, size: 16),
                        label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _exportReport('excel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.breakdown,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, AppTheme.buttonHeight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _exportReport('pdf'),
                      ),
                    ),
                  ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final cp = AppTheme.cardPadding;
    return Container(
      decoration: DesignSystem.glassDecoration,
      padding: EdgeInsets.all(cp),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, color: AppColors.primary, size: 15)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: AppTheme.isCompact ? 13 : 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (trailing != null) ...[const Spacer(), trailing],
        ]),
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
