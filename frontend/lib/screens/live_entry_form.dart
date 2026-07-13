import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/live_entry.dart';
import '../models/equipment.dart';
import '../models/operator.dart';
import '../models/project.dart';
import '../providers/master_provider.dart';
import '../providers/entry_provider.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/logo_header.dart';

class LiveEntryForm extends StatefulWidget {
  const LiveEntryForm({super.key});

  @override
  State<LiveEntryForm> createState() => _LiveEntryFormState();
}

class _LiveEntryFormState extends State<LiveEntryForm> {
  final _formKey = GlobalKey<FormState>();
  
  Project? _selectedProject;
  Equipment? _selectedEquipment;
  Operator? _selectedOperator;
  final _hmrController = TextEditingController();
  String _selectedActivity = AppConstants.activityRunning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() async {
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    await masterProvider.fetchProjects();
    await masterProvider.fetchEquipment();
    
    // Set default project to 'BHQ Hedri' or first available
    if (masterProvider.projects.isNotEmpty) {
      setState(() {
        _selectedProject = masterProvider.projects.firstWhere(
          (p) => p.projectName.toLowerCase() == 'bhq hedri',
          orElse: () => masterProvider.projects.first,
        );
      });
    }
  }

  @override
  void dispose() {
    _hmrController.dispose();
    super.dispose();
  }

  void _onEquipmentSelected(Equipment? equipment) async {
    setState(() {
      _selectedEquipment = equipment;
      _selectedOperator = null;
    });

    if (equipment != null) {
      final entryProvider = Provider.of<EntryProvider>(context, listen: false);
      final lastOperator = await entryProvider.getLastOperatorForEquipment(equipment.equipmentId!);
      if (lastOperator != null) {
        setState(() {
          _selectedOperator = lastOperator;
        });
      }
    }
  }

  void _reset() {
    final masterProvider = Provider.of<MasterProvider>(context, listen: false);
    setState(() {
      if (masterProvider.projects.isNotEmpty) {
        _selectedProject = masterProvider.projects.firstWhere(
          (p) => p.projectName.toLowerCase() == 'bhq hedri',
          orElse: () => masterProvider.projects.first,
        );
      }
      _selectedEquipment = null;
      _selectedOperator = null;
      _hmrController.clear();
      _selectedActivity = AppConstants.activityRunning;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.breakdown),
      );
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment'), backgroundColor: AppColors.breakdown),
      );
      return;
    }

    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an operator'), backgroundColor: AppColors.breakdown),
      );
      return;
    }

    final entry = LiveEntry(
      projectId: _selectedProject!.projectId!,
      equipmentId: _selectedEquipment!.equipmentId!,
      operatorId: _selectedOperator!.operatorId!,
      entryTimestamp: DateTime.now(),
      hmrValue: double.parse(_hmrController.text),
      activityType: _selectedActivity,
    );

    final entryProvider = Provider.of<EntryProvider>(context, listen: false);
    final success = await entryProvider.addLiveEntry(entry);

    if (success) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.running),
                SizedBox(width: 8),
                Text('Success', style: TextStyle(color: AppColors.running, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('Live Entry saved successfully!', style: TextStyle(color: AppColors.textPrimary)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) _reset();
      }
    } else {
      if (mounted) {
        final errorMsg = entryProvider.errorMessage ?? 'Failed to save live entry.';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.breakdown),
                SizedBox(width: 8),
                Text('Error', style: TextStyle(color: AppColors.breakdown, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(errorMsg, style: const TextStyle(color: AppColors.textPrimary)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final masterProvider = Provider.of<MasterProvider>(context);
    final entryProvider = Provider.of<EntryProvider>(context);
    final p = AppTheme.pagePadding;
    final fs = AppTheme.fieldSpacing;
    final labelStyle = TextStyle(fontSize: AppTheme.isCompact ? 13 : 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Row(
          children: [
            const LogoHeader(height: 24),
            const SizedBox(width: 16),
            Text('Live Data Entry', style: DesignSystem.getTextTheme(context).headlineMedium),
          ],
        ),
      ),
      body: masterProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(p),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormCard(masterProvider, entryProvider, labelStyle, fs),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard(MasterProvider masterProvider, EntryProvider entryProvider, TextStyle labelStyle, double fs) {
    final cp = AppTheme.cardPadding;
    return Container(
      decoration: DesignSystem.glassDecoration,
      padding: EdgeInsets.all(cp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Log Equipment Status',
                style: TextStyle(fontSize: AppTheme.isCompact ? 14 : 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          SizedBox(height: fs),
          const Divider(color: AppColors.divider, height: 1),
          SizedBox(height: fs),

          Text('Project Name', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<Project>(
            value: _selectedProject,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
              hintText: 'Select Project',
            ),
            items: masterProvider.projects.map((proj) {
              return DropdownMenuItem(value: proj, child: Text(proj.projectName));
            }).toList(),
            onChanged: (val) => setState(() => _selectedProject = val),
            validator: (value) => value == null ? 'Project is required' : null,
          ),
          SizedBox(height: fs),

          Text('Equipment / Truck Number', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SearchableDropdown<Equipment>(
            items: masterProvider.equipment.where((e) => e.isActive).toList(),
            label: 'Search Equipment Number',
            searchHint: 'Type to search by code...',
            selectedItem: _selectedEquipment,
            itemAsString: (eq) => eq.equipmentNumber,
            searchMatcher: (eq, query) => eq.equipmentNumber.toLowerCase().contains(query.toLowerCase()),
            onChanged: _onEquipmentSelected,
            validator: (value) => value == null ? 'Equipment is required' : null,
          ),

          Text('Operator Name', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SearchableDropdown<Operator>(
            items: masterProvider.operators.where((o) => o.isActive).toList(),
            label: 'Search Operator Name',
            searchHint: 'Search name...',
            selectedItem: _selectedOperator,
            itemAsString: (o) => o.operatorName,
            searchMatcher: (o, q) => o.operatorName.toLowerCase().contains(q.toLowerCase()),
            onChanged: (val) => setState(() => _selectedOperator = val),
            validator: (val) => val == null ? 'Operator is required' : null,
          ),
          SizedBox(height: fs),

          Text('HMR / KMR Value', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextFormField(
            controller: _hmrController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter current reading',
              prefixIcon: Icon(Icons.speed_outlined, size: 18),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Reading is required';
              if (double.tryParse(value) == null) return 'Must be a valid decimal number';
              return null;
            },
          ),
          SizedBox(height: fs),

          Text('Activity Type', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedActivity,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.pending_actions_outlined, size: 18),
            ),
            items: AppConstants.activities.map((act) {
              return DropdownMenuItem(value: act, child: Text(act));
            }).toList(),
            onChanged: (val) => setState(() => _selectedActivity = val ?? AppConstants.activityRunning),
          ),
          SizedBox(height: fs),

          // Autogenerated Time Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Timestamp auto-set to current date & time on submission.',
                    style: TextStyle(color: AppColors.primary, fontSize: AppTheme.isCompact ? 10 : 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: fs + 4),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: entryProvider.isLoading
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Save Log'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
