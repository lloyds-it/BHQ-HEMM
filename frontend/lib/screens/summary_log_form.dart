import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/summary_log.dart';
import '../models/equipment.dart';
import '../models/operator.dart';
import '../models/project.dart';
import '../providers/master_provider.dart';
import '../providers/entry_provider.dart';
import '../widgets/searchable_dropdown.dart';

class SummaryLogForm extends StatefulWidget {
  final bool isEmbed;
  const SummaryLogForm({super.key, this.isEmbed = false});

  @override
  State<SummaryLogForm> createState() => _SummaryLogFormState();
}

class _SummaryLogFormState extends State<SummaryLogForm> {
  final _formKey = GlobalKey<FormState>();

  Project? _selectedProject;
  DateTime _selectedDate = DateTime.now();
  String _selectedShift = AppConstants.shifts.first;
  Equipment? _selectedEquipment;
  Operator? _selectedOperator;

  DateTime _startTimestamp = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _endTimestamp = DateTime.now();

  final _startHmrController = TextEditingController();
  final _endHmrController = TextEditingController();

  double _calculatedTotalHmr = 0.0;
  double _calculatedClockHours = 0.0;

  String _selectedActivity = AppConstants.activityRunning;
  final _workDoneController = TextEditingController();
  final _locationController = TextEditingController();

  final _dieselController = TextEditingController(text: '0');
  final _hydraulicOilController = TextEditingController(text: '0');
  final _engineOilController = TextEditingController(text: '0');
  final _transmissionOilController = TextEditingController(text: '0');
  final _gearOilController = TextEditingController(text: '0');

  final _remarksController = TextEditingController();

  // Focus nodes for keyboard sequential navigation
  late final FocusNode _projectFocus = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.tab &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _dateFocus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  final FocusNode _dateFocus = FocusNode();
  late final FocusNode _shiftFocus = FocusNode(
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
  final FocusNode _startTimeFocus = FocusNode();
  final FocusNode _endTimeFocus = FocusNode();
  final FocusNode _startHmrFocus = FocusNode();
  final FocusNode _endHmrFocus = FocusNode();
  late final FocusNode _activityFocus = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.tab &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _workDoneFocus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  final FocusNode _workDoneFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _dieselFocus = FocusNode();
  final FocusNode _hydraulicFocus = FocusNode();
  final FocusNode _engineFocus = FocusNode();
  final FocusNode _transmissionFocus = FocusNode();
  final FocusNode _gearFocus = FocusNode();
  final FocusNode _remarksFocus = FocusNode();
  final FocusNode _submitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _startHmrController.addListener(_calculateTotalHmr);
    _endHmrController.addListener(_calculateTotalHmr);
    _calculateClockHours();

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
    await masterProvider.fetchOperators();

    // Automatically focus on equipment dropdown field on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _equipmentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _startHmrController.dispose();
    _endHmrController.dispose();
    _workDoneController.dispose();
    _locationController.dispose();
    _dieselController.dispose();
    _hydraulicOilController.dispose();
    _engineOilController.dispose();
    _transmissionOilController.dispose();
    _gearOilController.dispose();
    _remarksController.dispose();

    _projectFocus.dispose();
    _dateFocus.dispose();
    _shiftFocus.dispose();
    _equipmentFocus.dispose();
    _operatorFocus.dispose();
    _startTimeFocus.dispose();
    _endTimeFocus.dispose();
    _startHmrFocus.dispose();
    _endHmrFocus.dispose();
    _activityFocus.dispose();
    _workDoneFocus.dispose();
    _locationFocus.dispose();
    _dieselFocus.dispose();
    _hydraulicFocus.dispose();
    _engineFocus.dispose();
    _transmissionFocus.dispose();
    _gearFocus.dispose();
    _remarksFocus.dispose();
    _submitFocus.dispose();

    super.dispose();
  }

  void _calculateTotalHmr() {
    final start = double.tryParse(_startHmrController.text) ?? 0.0;
    final end = double.tryParse(_endHmrController.text) ?? 0.0;
    setState(() {
      _calculatedTotalHmr = end >= start ? end - start : 0.0;
    });
  }

  void _calculateClockHours() {
    final diff = _endTimestamp.difference(_startTimestamp);
    setState(() {
      _calculatedClockHours = diff.inMinutes > 0 ? diff.inMinutes / 60.0 : 0.0;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _shiftFocus.requestFocus();
    }
  }

  Future<void> _selectDateTimePicker(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startTimestamp : _endTimestamp;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newTimestamp = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            _startTimestamp = newTimestamp;
          } else {
            _endTimestamp = newTimestamp;
          }
          _calculateClockHours();
        });

        if (isStart) {
          _endTimeFocus.requestFocus();
        } else {
          _startHmrFocus.requestFocus();
        }
      }
    }
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

    if (_endTimestamp.isBefore(_startTimestamp)) {
      _showSnackbar('End time cannot be before start time', AppColors.breakdown);
      return;
    }

    final startHmr = double.tryParse(_startHmrController.text) ?? 0.0;
    final endHmr = double.tryParse(_endHmrController.text) ?? 0.0;
    if (endHmr < startHmr) {
      _showSnackbar('End HMR cannot be less than Start HMR', AppColors.breakdown);
      return;
    }

    final log = SummaryLog(
      projectId: _selectedProject!.projectId!,
      date: _selectedDate,
      shift: _selectedShift,
      equipmentId: _selectedEquipment!.equipmentId!,
      operatorId: _selectedOperator!.operatorId!,
      startTimestamp: _startTimestamp,
      endTimestamp: _endTimestamp,
      startHmr: startHmr,
      endHmr: endHmr,
      activityType: _selectedActivity,
      workDone: _workDoneController.text.trim(),
      location: _locationController.text.trim(),
      diesel: double.tryParse(_dieselController.text) ?? 0.0,
      hydraulicOil: double.tryParse(_hydraulicOilController.text) ?? 0.0,
      engineOil: double.tryParse(_engineOilController.text) ?? 0.0,
      transmissionOil: double.tryParse(_transmissionOilController.text) ?? 0.0,
      gearOil: double.tryParse(_gearOilController.text) ?? 0.0,
      remarks: _remarksController.text.trim(),
    );

    final entryProvider = Provider.of<EntryProvider>(context, listen: false);
    final success = await entryProvider.addSummaryLog(log);

    if (success) {
      _showSnackbar('Summary Log saved successfully!', AppColors.running);
      _reset();
    } else {
      final errorMsg = entryProvider.errorMessage ?? 'Failed to save summary log.';
      _showSnackbar(errorMsg, AppColors.breakdown);
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
      _startHmrController.clear();
      _endHmrController.clear();
      _workDoneController.clear();
      _locationController.clear();
      _dieselController.text = '0';
      _hydraulicOilController.text = '0';
      _engineOilController.text = '0';
      _transmissionOilController.text = '0';
      _gearOilController.text = '0';
      _remarksController.clear();
      _selectedActivity = AppConstants.activityRunning;
      _startTimestamp = DateTime.now().subtract(const Duration(hours: 8));
      _endTimestamp = DateTime.now();
    });
    _equipmentFocus.requestFocus();
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



    final content = Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyR &&
              HardwareKeyboard.instance.isControlPressed) {
            _reset();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              HardwareKeyboard.instance.isControlPressed) {
            _submit();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: DesignSystem.glassDecoration,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1 Header
                    _sectionHeader('General & Crew Details', Icons.engineering_rounded),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                validator: (val) => val == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Log Date'),
                              const SizedBox(height: 3),
                              _dateTile(_selectedDate, () => _selectDate(context), _dateFocus),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Shift'),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 32,
                                child: DropdownButtonFormField<String>(
                                  focusNode: _shiftFocus,
                                  value: _selectedShift,
                                  isDense: true,
                                  decoration: _inputDecor(Icons.work_history_outlined),
                                  items: AppConstants.shifts.map((s) {
                                    return DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedShift = val ?? 'Day'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Equipment / Truck Number'),
                              const SizedBox(height: 3),
                              SearchableDropdown<Equipment>(
                                focusNode: _equipmentFocus,
                                nextFocusNode: _operatorFocus,
                                items: masterProvider.equipment.where((e) => e.isActive).toList(),
                                label: 'Search Equipment',
                                searchHint: 'Type code...',
                                selectedItem: _selectedEquipment,
                                itemAsString: (e) => e.equipmentNumber,
                                searchMatcher: (e, q) => e.equipmentNumber.toLowerCase().contains(q.toLowerCase()),
                                onChanged: (val) => setState(() => _selectedEquipment = val),
                                validator: (val) => val == null ? 'Required' : null,
                                prefixIcon: Icons.fire_truck_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Operator Name'),
                              const SizedBox(height: 3),
                              SearchableDropdown<Operator>(
                                focusNode: _operatorFocus,
                                nextFocusNode: _startTimeFocus,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section 2: Hours & Readings
                    _sectionHeader('Hours & Readings', Icons.timer_outlined),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Start Time'),
                              const SizedBox(height: 3),
                              _timeTile(_startTimestamp, () => _selectDateTimePicker(context, true), _startTimeFocus),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('End Time'),
                              const SizedBox(height: 3),
                              _timeTile(_endTimestamp, () => _selectDateTimePicker(context, false), _endTimeFocus),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Start HMR'),
                              const SizedBox(height: 3),
                              TextFormField(
                                focusNode: _startHmrFocus,
                                controller: _startHmrController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 12),
                                decoration: _inputDecor(Icons.speed_outlined).copyWith(hintText: 'Start'),
                                onFieldSubmitted: (_) => _endHmrFocus.requestFocus(),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('End HMR'),
                              const SizedBox(height: 3),
                              TextFormField(
                                focusNode: _endHmrFocus,
                                controller: _endHmrController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 12),
                                decoration: _inputDecor(Icons.speed_outlined).copyWith(hintText: 'End'),
                                onFieldSubmitted: (_) => _activityFocus.requestFocus(),
                                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Auto calculation results banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Calculated Total HMR:  ${_calculatedTotalHmr.toStringAsFixed(2)} hrs',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 11),
                          ),
                          Container(width: 1, height: 12, color: AppColors.border),
                          Text(
                            'Clock Hours:  ${_calculatedClockHours.toStringAsFixed(2)} hrs',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 3: Activities & Details
                    _sectionHeader('Activity & Details', Icons.description_outlined),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Activity Type'),
                              const SizedBox(height: 3),
                              SearchableDropdown<String>(
                                focusNode: _activityFocus,
                                nextFocusNode: _workDoneFocus,
                                items: AppConstants.activities,
                                label: 'Activity Type',
                                searchHint: 'Search activity...',
                                selectedItem: _selectedActivity,
                                itemAsString: (a) => a,
                                searchMatcher: (a, q) => a.toLowerCase().contains(q.toLowerCase()),
                                onChanged: (val) => setState(() => _selectedActivity = val ?? AppConstants.activityRunning),
                                prefixIcon: Icons.pending_actions,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Work Done'),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 32,
                                child: TextFormField(
                                  focusNode: _workDoneFocus,
                                  controller: _workDoneController,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _inputDecor(Icons.edit_note_outlined).copyWith(hintText: 'Coal excavation...'),
                                  onFieldSubmitted: (_) => _locationFocus.requestFocus(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Location'),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 32,
                                child: TextFormField(
                                  focusNode: _locationFocus,
                                  controller: _locationController,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _inputDecor(Icons.map_outlined).copyWith(hintText: 'Bench L3 / Pit B'),
                                  onFieldSubmitted: (_) => _dieselFocus.requestFocus(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section 4: Fuel & Consumables
                    _sectionHeader('Fuel & Consumables Issued', Icons.local_gas_station_outlined),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(child: _compactTextForm('Diesel (L)', _dieselController, _dieselFocus, _hydraulicFocus)),
                        const SizedBox(width: 8),
                        Expanded(child: _compactTextForm('Hydraulic Oil (L)', _hydraulicOilController, _hydraulicFocus, _engineFocus)),
                        const SizedBox(width: 8),
                        Expanded(child: _compactTextForm('Engine Oil (L)', _engineOilController, _engineFocus, _transmissionFocus)),
                        const SizedBox(width: 8),
                        Expanded(child: _compactTextForm('Transmission (L)', _transmissionOilController, _transmissionFocus, _gearFocus)),
                        const SizedBox(width: 8),
                        Expanded(child: _compactTextForm('Gear Oil (L)', _gearOilController, _gearFocus, _remarksFocus)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section 5: Remarks
                    _sectionHeader('Shift Remarks', Icons.comment_bank_outlined),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 48,
                      child: TextFormField(
                        focusNode: _remarksFocus,
                        controller: _remarksController,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        decoration: _inputDecor(Icons.comment_outlined).copyWith(hintText: 'Enter shift observations...'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Actions
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
                                    child: const Text('Save Summary Log (Ctrl+S)'),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
        title: const Text('Summary Log Entry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    );
  }

  Widget _dateTile(DateTime date, VoidCallback onTap, FocusNode node) {
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: node.hasFocus ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTile(DateTime dt, VoidCallback onTap, FocusNode node) {
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: node.hasFocus ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM, HH:mm').format(dt),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
              const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactTextForm(String title, TextEditingController ctrl, FocusNode focus, FocusNode nextFocus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        const SizedBox(height: 3),
        TextFormField(
          focusNode: focus,
          controller: ctrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 12),
          decoration: _inputDecor(Icons.oil_barrel_outlined),
          onFieldSubmitted: (_) => nextFocus.requestFocus(),
        ),
      ],
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
