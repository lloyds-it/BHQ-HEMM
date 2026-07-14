import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class LiveEntryForm extends StatefulWidget {
  final bool isEmbed;
  const LiveEntryForm({super.key, this.isEmbed = false});

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

  // Keyboard navigation focus nodes
  late final FocusNode _projectFocus = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.tab &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _equipmentFocus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  final FocusNode _equipmentFocus = FocusNode();
  final FocusNode _operatorFocus = FocusNode();
  final FocusNode _hmrFocus = FocusNode();
  late final FocusNode _activityFocus = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.tab &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _submitFocus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  final FocusNode _submitFocus = FocusNode();

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
    
    if (masterProvider.projects.isNotEmpty && _selectedProject == null) {
      setState(() {
        _selectedProject = masterProvider.projects.firstWhere(
          (p) => p.projectName.toLowerCase() == 'bhq hedri',
          orElse: () => masterProvider.projects.first,
        );
      });
    }

    await masterProvider.fetchEquipment();
    await masterProvider.fetchOperators(); // Fetch operators so they load correctly
  }

  @override
  void dispose() {
    _hmrController.dispose();
    _projectFocus.dispose();
    _equipmentFocus.dispose();
    _operatorFocus.dispose();
    _hmrFocus.dispose();
    _activityFocus.dispose();
    _submitFocus.dispose();
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
    _projectFocus.requestFocus();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProject == null) {
      _showSnackbar('Please select a project', AppColors.breakdown);
      return;
    }
    if (_selectedEquipment == null) {
      _showSnackbar('Please select equipment', AppColors.breakdown);
      return;
    }
    if (_selectedOperator == null) {
      _showSnackbar('Please select an operator', AppColors.breakdown);
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
      _showSnackbar('Live Entry saved successfully!', AppColors.running);
      _reset();
    } else {
      final errorMsg = entryProvider.errorMessage ?? 'Failed to save live entry.';
      _showSnackbar(errorMsg, AppColors.breakdown);
    }
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterProvider = Provider.of<MasterProvider>(context);
    final entryProvider = Provider.of<EntryProvider>(context);
    const p = 12.0;



    final content = CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _reset,
      },
      child: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: DesignSystem.glassDecoration,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Log Equipment Status',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),

                // Project
                _label('Project Name'),
                const SizedBox(height: 3),
                DropdownButtonFormField<Project>(
                  focusNode: _projectFocus,
                  value: _selectedProject,
                  isDense: true,
                  decoration: _inputDecor(Icons.location_on_outlined),
                  items: masterProvider.projects.map((proj) {
                    return DropdownMenuItem(
                        value: proj,
                        child: Text(proj.projectName, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProject = val),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 8),

                // Equipment Searchable Dropdown
                _label('Equipment / Truck Number'),
                const SizedBox(height: 3),
                SearchableDropdown<Equipment>(
                  focusNode: _equipmentFocus,
                  nextFocusNode: _operatorFocus,
                  items: masterProvider.equipment.where((e) => e.isActive).toList(),
                  label: 'Search Equipment Number',
                  searchHint: 'Type code...',
                  selectedItem: _selectedEquipment,
                  itemAsString: (eq) => eq.equipmentNumber,
                  searchMatcher: (eq, query) => eq.equipmentNumber.toLowerCase().contains(query.toLowerCase()),
                  onChanged: _onEquipmentSelected,
                  validator: (value) => value == null ? 'Required' : null,
                  prefixIcon: Icons.fire_truck_outlined,
                ),
                const SizedBox(height: 8),

                // Operator Searchable Dropdown
                _label('Operator Name'),
                const SizedBox(height: 3),
                SearchableDropdown<Operator>(
                  focusNode: _operatorFocus,
                  nextFocusNode: _hmrFocus,
                  items: masterProvider.operators.where((o) => o.isActive).toList(),
                  label: 'Search Operator Name',
                  searchHint: 'Search name...',
                  selectedItem: _selectedOperator,
                  itemAsString: (o) => o.operatorName,
                  searchMatcher: (o, q) => o.operatorName.toLowerCase().contains(q.toLowerCase()),
                  onChanged: (val) => setState(() => _selectedOperator = val),
                  validator: (val) => val == null ? 'Required' : null,
                  prefixIcon: Icons.engineering_outlined,
                ),
                const SizedBox(height: 8),

                // HMR Value
                _label('HMR / KMR Value'),
                const SizedBox(height: 3),
                TextFormField(
                  focusNode: _hmrFocus,
                  controller: _hmrController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 12),
                  decoration: _inputDecor(Icons.speed_outlined).copyWith(hintText: 'Enter current reading'),
                  onFieldSubmitted: (_) => _activityFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid decimal';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Activity Dropdown
                _label('Activity Type'),
                const SizedBox(height: 3),
                SearchableDropdown<String>(
                  focusNode: _activityFocus,
                  nextFocusNode: _submitFocus,
                  items: AppConstants.activities,
                  label: 'Activity Type',
                  searchHint: 'Search activity...',
                  selectedItem: _selectedActivity,
                  itemAsString: (act) => act,
                  searchMatcher: (act, q) => act.toLowerCase().contains(q.toLowerCase()),
                  onChanged: (val) => setState(() => _selectedActivity = val ?? AppConstants.activityRunning),
                  prefixIcon: Icons.pending_actions_outlined,
                ),
                const SizedBox(height: 10),

                // Timestamp Alert
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 12),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Timestamp will be auto-set on submission.',
                          style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Actions row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Reset (Ctrl+R)'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: entryProvider.isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : ElevatedButton(
                                focusNode: _submitFocus,
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Save Log (Ctrl+S)'),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

    if (widget.isEmbed) {
      return Padding(
        padding: const EdgeInsets.all(p),
        child: SingleChildScrollView(child: content),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Live Data Entry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: masterProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(p),
              child: content,
            ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  InputDecoration _inputDecor(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 14, color: AppColors.textSecondary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: AppColors.breakdown),
      ),
    );
  }
}
