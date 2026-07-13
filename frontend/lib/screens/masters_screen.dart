import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/master_provider.dart';
import '../models/project.dart';
import '../models/equipment.dart';
import '../models/operator.dart';
import '../widgets/logo_header.dart';

class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _refreshAll() {
    final provider = Provider.of<MasterProvider>(context, listen: false);
    provider.fetchProjects();
    provider.fetchEquipment();
    provider.fetchOperators();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Row(
          children: [
            const LogoHeader(height: 24),
            const SizedBox(width: 16),
            const Text('Master Data Management'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.location_city_rounded, size: 16), text: 'Projects'),
            Tab(icon: Icon(Icons.local_shipping_rounded, size: 16), text: 'Equipment'),
            Tab(icon: Icon(Icons.people_rounded, size: 16), text: 'Operators'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProjectsMasterTab(refresh: _refreshAll),
          _EquipmentMasterTab(refresh: _refreshAll),
          _OperatorsMasterTab(refresh: _refreshAll),
        ],
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

BoxDecoration _cardDecor() => DesignSystem.glassDecoration;

void _showMessageDialog(BuildContext context, bool success, String action, {String? error}) {
  final title = success ? 'Success' : 'Error';
  final msg = success ? '$action successfully.' : (error ?? 'Failed to $action.');
  final icon = success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;
  final color = success ? AppColors.running : AppColors.breakdown;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
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

// 1. Projects Master Tab
class _ProjectsMasterTab extends StatelessWidget {
  final VoidCallback refresh;
  const _ProjectsMasterTab({required this.refresh});

  void _showAddEditDialog(BuildContext context, Project? project) {
    final nameController = TextEditingController(text: project?.projectName ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(project == null ? 'Add Project' : 'Edit Project',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Project Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final provider = Provider.of<MasterProvider>(context, listen: false);
                bool success;
                if (project == null) {
                  success = await provider.addProject(name);
                } else {
                  success = await provider.updateProject(project.projectId!, name);
                }
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  refresh();
                  _showMessageDialog(context, true, project == null ? 'Project added' : 'Project updated');
                } else if (!success && dialogContext.mounted) {
                  _showMessageDialog(context, false, project == null ? 'add project' : 'update project', error: provider.errorMessage);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MasterProvider>(context);
    final p = AppTheme.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(context, null),
        child: const Icon(Icons.add, size: 20),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : provider.projects.isEmpty
                  ? const Center(child: Text('No projects configured.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                  : ListView.separated(
                      padding: EdgeInsets.all(p),
                      itemCount: provider.projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final proj = provider.projects[index];
                        return Container(
                          decoration: _cardDecor(),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 14),
                            ),
                            title: Text(proj.projectName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                            subtitle: Text('ID: ${proj.projectId}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _iconBtn(Icons.edit_rounded, AppColors.primary, () => _showAddEditDialog(context, proj)),
                                _iconBtn(Icons.delete_outline_rounded, AppColors.breakdown, () async {
                                  final success = await provider.deleteProject(proj.projectId!);
                                  if (success) {
                                    refresh();
                          if (context.mounted) _showMessageDialog(context, true, 'Project deleted');
                                  } else {
                          if (context.mounted) _showMessageDialog(context, false, 'delete project', error: provider.errorMessage);
                                  }
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

// 2. Equipment Master Tab
class _EquipmentMasterTab extends StatefulWidget {
  final VoidCallback refresh;
  const _EquipmentMasterTab({required this.refresh});

  @override
  State<_EquipmentMasterTab> createState() => _EquipmentMasterTabState();
}

class _EquipmentMasterTabState extends State<_EquipmentMasterTab> {
  final _searchController = TextEditingController();

  void _showAddEditDialog(BuildContext context, Equipment? eq) {
    final numberController = TextEditingController(text: eq?.equipmentNumber ?? '');
    final provider = Provider.of<MasterProvider>(context, listen: false);
    Project? selectedProject = eq != null
        ? provider.projects.firstWhere((p) => p.projectId == eq.projectId, orElse: () => provider.projects.first)
        : provider.projects.isNotEmpty ? provider.projects.first : null;
    bool isActive = eq?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text(eq == null ? 'Add Equipment' : 'Edit Equipment',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: numberController,
                        decoration: const InputDecoration(labelText: 'Equipment Number'), autofocus: true),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Project>(
                      value: selectedProject,
                      decoration: const InputDecoration(labelText: 'Project'),
                      items: provider.projects.map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.projectName))).toList(),
                      onChanged: (val) => setDialogState(() => selectedProject = val),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isActive,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      dense: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                ElevatedButton(
                  onPressed: () async {
                    final numStr = numberController.text.trim();
                    if (numStr.isEmpty || selectedProject == null) return;
                    bool success;
                    if (eq == null) {
                      success = await provider.addEquipment(numStr, selectedProject!.projectId!);
                    } else {
                      success = await provider.updateEquipment(eq.equipmentId!, numStr, selectedProject!.projectId!, isActive);
                    }
                    if (success && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      widget.refresh();
                      _showMessageDialog(context, true, eq == null ? 'Equipment added' : 'Equipment updated');
                    } else if (!success && dialogContext.mounted) {
                      _showMessageDialog(context, false, eq == null ? 'add equipment' : 'update equipment', error: provider.errorMessage);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MasterProvider>(context);
    final p = AppTheme.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(context, null),
        child: const Icon(Icons.add, size: 20),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(p, p, p, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.fetchEquipment(searchQuery: val),
                  decoration: InputDecoration(
                    hintText: 'Search Equipment...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () { _searchController.clear(); provider.fetchEquipment(); },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : provider.equipment.isEmpty
                        ? const Center(child: Text('No equipment configured.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: p, vertical: 4),
                            itemCount: provider.equipment.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final eq = provider.equipment[index];
                              return Container(
                                decoration: _cardDecor(),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: (eq.isActive ? AppColors.running : AppColors.breakdown).withOpacity(0.1),
                                    child: Icon(Icons.local_shipping_rounded,
                                        color: eq.isActive ? AppColors.running : AppColors.breakdown, size: 14),
                                  ),
                                  title: Text(eq.equipmentNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                                  subtitle: Text('${eq.project?.projectName ?? "N/A"}  ·  ${eq.isActive ? "Active" : "Inactive"}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _iconBtn(Icons.edit_rounded, AppColors.primary, () => _showAddEditDialog(context, eq)),
                                      _iconBtn(Icons.delete_outline_rounded, AppColors.breakdown, () async {
                                        final success = await provider.deleteEquipment(eq.equipmentId!);
                                        if (success) {
                                          widget.refresh();
                          if (context.mounted) _showMessageDialog(context, true, 'Equipment deleted');
                                        } else {
                          if (context.mounted) _showMessageDialog(context, false, 'delete equipment', error: provider.errorMessage);
                                        }
                                      }),
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

// 3. Operators Master Tab
class _OperatorsMasterTab extends StatefulWidget {
  final VoidCallback refresh;
  const _OperatorsMasterTab({required this.refresh});

  @override
  State<_OperatorsMasterTab> createState() => _OperatorsMasterTabState();
}

class _OperatorsMasterTabState extends State<_OperatorsMasterTab> {
  final _searchController = TextEditingController();

  void _showAddEditDialog(BuildContext context, Operator? op) {
    final nameController = TextEditingController(text: op?.operatorName ?? '');
    final mobileController = TextEditingController(text: op?.mobile ?? '');
    bool isActive = op?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text(op == null ? 'Add Operator' : 'Edit Operator',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController,
                        decoration: const InputDecoration(labelText: 'Operator Name'), autofocus: true),
                    const SizedBox(height: 12),
                    TextField(controller: mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile Number'),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isActive,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      dense: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final mobile = mobileController.text.trim();
                    if (name.isEmpty) return;
                    final provider = Provider.of<MasterProvider>(context, listen: false);
                    bool success;
                    if (op == null) {
                      success = await provider.addOperator(name, mobile.isEmpty ? null : mobile);
                    } else {
                      success = await provider.updateOperator(op.operatorId!, name, mobile.isEmpty ? null : mobile, isActive);
                    }
                    if (success && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      widget.refresh();
                      _showMessageDialog(context, true, op == null ? 'Operator added' : 'Operator updated');
                    } else if (!success && dialogContext.mounted) {
                      _showMessageDialog(context, false, op == null ? 'add operator' : 'update operator', error: provider.errorMessage);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MasterProvider>(context);
    final p = AppTheme.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(context, null),
        child: const Icon(Icons.add, size: 20),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(p, p, p, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.fetchOperators(searchQuery: val),
                  decoration: InputDecoration(
                    hintText: 'Search Operators...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () { _searchController.clear(); provider.fetchOperators(); },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : provider.operators.isEmpty
                        ? const Center(child: Text('No operators configured.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: p, vertical: 4),
                            itemCount: provider.operators.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final op = provider.operators[index];
                              return Container(
                                decoration: _cardDecor(),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: (op.isActive ? AppColors.running : AppColors.breakdown).withOpacity(0.1),
                                    child: Icon(Icons.person_rounded,
                                        color: op.isActive ? AppColors.running : AppColors.breakdown, size: 14),
                                  ),
                                  title: Text(op.operatorName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                                  subtitle: Text('${op.mobile ?? "No mobile"}  ·  ${op.isActive ? "Active" : "Inactive"}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _iconBtn(Icons.edit_rounded, AppColors.primary, () => _showAddEditDialog(context, op)),
                                      _iconBtn(Icons.delete_outline_rounded, AppColors.breakdown, () async {
                                        final success = await provider.deleteOperator(op.operatorId!);
                                        if (success) {
                                          widget.refresh();
                          if (context.mounted) _showMessageDialog(context, true, 'Operator deleted');
                                        } else {
                          if (context.mounted) _showMessageDialog(context, false, 'delete operator', error: provider.errorMessage);
                                        }
                                      }),
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

// Shared compact icon button helper
Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
  icon: Icon(icon, color: color, size: 18),
  onPressed: onTap,
  visualDensity: VisualDensity.compact,
  padding: const EdgeInsets.all(4),
  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
);
