import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/master_provider.dart';
import 'live_entry_form.dart';
import 'summary_log_form.dart';
import 'masters_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import '../widgets/logo_header.dart';
import '../widgets/dashboard_charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  void initState() {
    super.initState();
    _loadActiveTab();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchStats();
    });
  }

  void _loadActiveTab() async {
    try {
      final savedIndex = await _secureStorage.read(key: 'active_tab_index');
      if (savedIndex != null) {
        final index = int.tryParse(savedIndex);
        if (index != null && index >= 0 && index <= 4) {
          setState(() {
            _selectedIndex = index;
          });
        }
      }
    } catch (_) {}
  }

  void _updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _secureStorage.write(key: 'active_tab_index', value: index.toString());
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await _secureStorage.delete(key: 'active_tab_index');
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _getCurrentPage(bool isAdmin) {
    switch (_selectedIndex) {
      case 0:
        return _DashboardContent(
          onLogout: _logout,
          onNavigate: _updateSelectedIndex,
        );
      case 1:
        return const LiveEntryForm(isEmbed: true);
      case 2:
        return const SummaryLogForm(isEmbed: true);
      case 3:
        return isAdmin ? const ReportsScreen(isEmbed: true) : const Text('Access Denied');
      case 4:
        return isAdmin ? const MastersScreen(isEmbed: true) : const Text('Access Denied');
      default:
        return const Text('Page not found');
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Live Entry';
      case 2:
        return 'Summary Log';
      case 3:
        return 'Reports';
      case 4:
        return 'Master Data';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.role == 'Admin';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 950;

          if (isDesktop) {
            return Row(
              children: [
                _buildSideNav(isAdmin),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      // Top Header Bar
                      _buildTopHeader(auth),
                      Container(height: 1, color: AppColors.border),
                      // Main Content Area
                      Expanded(
                        child: ClipRect(
                          child: _getCurrentPage(isAdmin),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildTopHeader(auth),
                Container(height: 1, color: AppColors.border),
                Expanded(
                  child: _getCurrentPage(isAdmin),
                ),
                _buildBottomNav(isAdmin),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTopHeader(AuthProvider auth) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          const LogoHeader(height: 20),
          const SizedBox(width: 12),
          Text(
            _getPageTitle(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            '${auth.username ?? ''} (${auth.role ?? ''})',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 18),
            onPressed: () {
              Provider.of<DashboardProvider>(context, listen: false).fetchStats();
              if (_selectedIndex == 4) {
                final m = Provider.of<MasterProvider>(context, listen: false);
                m.fetchProjects();
                m.fetchEquipment();
                m.fetchOperators();
              }
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav(bool isAdmin) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _updateSelectedIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 20),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary, size: 24),
        ),
      ),
      destinations: [
        const NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Home')),
        const NavigationRailDestination(icon: Icon(Icons.bolt_rounded), label: Text('Live Entry')),
        const NavigationRailDestination(icon: Icon(Icons.assignment_rounded), label: Text('Summary')),
        if (isAdmin)
          const NavigationRailDestination(icon: Icon(Icons.bar_chart_rounded), label: Text('Reports')),
        if (isAdmin)
          const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Masters')),
      ],
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _updateSelectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 18), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded, size: 18), label: 'Live'),
        const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded, size: 18), label: 'Summary'),
        if (isAdmin)
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded, size: 18), label: 'Reports'),
        if (isAdmin)
          const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded, size: 18), label: 'Masters'),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback onLogout;
  final ValueChanged<int> onNavigate;
  const _DashboardContent({required this.onLogout, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<DashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.role == 'Admin';
    const p = 10.0;

    if (stats.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 950;

        if (isDesktop) {
          return Padding(
            padding: const EdgeInsets.all(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context, auth),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Live Status & Quick Actions
                      SizedBox(
                        width: 250,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Live Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            _buildLeftOverview(stats),
                            const SizedBox(height: 12),
                            const Text('Quick Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            _buildLeftActions(isAdmin),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Column: Charts & Scrollable logs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isAdmin) ...[
                              const Text('Analytics & Trends', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              DashboardAnalyticsGrid(stats: stats),
                              const SizedBox(height: 12),
                            ],
                            const Text('Recent Live Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: _buildScrollableRecentEntries(stats),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile single vertical scroll
          return RefreshIndicator(
            onRefresh: () => stats.fetchStats(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(context, auth),
                  const SizedBox(height: 10),
                  const Text('Live Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  _buildMobileStatsGrid(stats),
                  const SizedBox(height: 12),
                  if (isAdmin) ...[
                    const Text('Analytics & Trends', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DashboardAnalyticsGrid(stats: stats),
                    const SizedBox(height: 12),
                  ],
                  _buildMobileActions(isAdmin),
                  const SizedBox(height: 12),
                  _buildMobileRecentEntries(stats),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.precision_manufacturing_rounded, color: Colors.white.withOpacity(0.7), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${auth.username ?? 'User'}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${auth.role ?? ''} • ${_formattedDate()}',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('BHQ HEMM',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // Left column metric list
  Widget _buildLeftOverview(DashboardProvider stats) {
    return Column(
      children: [
        _buildCompactStatTile("Today's Entries", stats.todayLiveEntriesCount.toString(), Icons.receipt_long_rounded, AppColors.primary),
        const SizedBox(height: 4),
        _buildCompactStatTile('Running', stats.runningEquipmentCount.toString(), Icons.play_circle_rounded, AppColors.running),
        const SizedBox(height: 4),
        _buildCompactStatTile('Idle', stats.idleEquipmentCount.toString(), Icons.pause_circle_rounded, AppColors.idle),
        const SizedBox(height: 4),
        _buildCompactStatTile('Breakdown', stats.breakdownEquipmentCount.toString(), Icons.warning_rounded, AppColors.breakdown),
        const SizedBox(height: 4),
        _buildCompactStatTile('Stoppage', stats.stoppageEquipmentCount.toString(), Icons.do_not_disturb_on_rounded, AppColors.stoppage),
      ],
    );
  }

  Widget _buildCompactStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // Left column quick actions
  Widget _buildLeftActions(bool isAdmin) {
    final actions = [
      _buildCompactActionBtn('Live Entry', Icons.bolt_rounded, AppColors.accent, () => onNavigate(1)),
      _buildCompactActionBtn('Summary Log', Icons.assignment_rounded, AppColors.primary, () => onNavigate(2)),
      if (isAdmin) _buildCompactActionBtn('Reports', Icons.bar_chart_rounded, AppColors.running, () => onNavigate(3)),
      if (isAdmin) _buildCompactActionBtn('Masters', Icons.settings_rounded, AppColors.stoppage, () => onNavigate(4)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 2.8,
      children: actions,
    );
  }

  Widget _buildCompactActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  // Scrollable logs inside right column
  Widget _buildScrollableRecentEntries(DashboardProvider stats) {
    if (stats.recentEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 24, color: AppColors.textMuted),
            SizedBox(height: 6),
            Text('No entries logged yet today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ListView.separated(
          padding: const EdgeInsets.all(6),
          itemCount: stats.recentEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (ctx, i) => _EntryCard(entry: stats.recentEntries[i]),
        ),
      ),
    );
  }

  // Mobile layout components
  Widget _buildMobileStatsGrid(DashboardProvider stats) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildMobileStatCard("Today's Entries", stats.todayLiveEntriesCount.toString(), Icons.receipt_long_rounded, AppColors.primary),
        _buildMobileStatCard('Running', stats.runningEquipmentCount.toString(), Icons.play_circle_rounded, AppColors.running),
        _buildMobileStatCard('Idle', stats.idleEquipmentCount.toString(), Icons.pause_circle_rounded, AppColors.idle),
        _buildMobileStatCard('Breakdown', stats.breakdownEquipmentCount.toString(), Icons.warning_rounded, AppColors.breakdown),
        _buildMobileStatCard('Stoppage', stats.stoppageEquipmentCount.toString(), Icons.do_not_disturb_on_rounded, AppColors.stoppage),
      ],
    );
  }

  Widget _buildMobileStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMobileActions(bool isAdmin) {
    final actions = [
      _buildCompactActionBtn('Live Entry', Icons.bolt_rounded, AppColors.accent, () => onNavigate(1)),
      _buildCompactActionBtn('Summary Log', Icons.assignment_rounded, AppColors.primary, () => onNavigate(2)),
      if (isAdmin) _buildCompactActionBtn('Reports', Icons.bar_chart_rounded, AppColors.running, () => onNavigate(3)),
      if (isAdmin) _buildCompactActionBtn('Masters', Icons.settings_rounded, AppColors.stoppage, () => onNavigate(4)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: actions.map((a) => SizedBox(width: 100, height: 32, child: a)).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileRecentEntries(DashboardProvider stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Live Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () => onNavigate(3),
              child: const Text('View All →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (stats.recentEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('No logs recorded yet today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.recentEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (ctx, i) => _EntryCard(entry: stats.recentEntries[i]),
          ),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _EntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _EntryCard({required this.entry});

  Color _color(String? a) {
    switch (a) {
      case 'Running':   return AppColors.running;
      case 'Idle':      return AppColors.idle;
      case 'Breakdown': return AppColors.breakdown;
      case 'Stoppage':  return AppColors.stoppage;
      default: return AppColors.primary;
    }
  }

  IconData _icon(String? a) {
    switch (a) {
      case 'Running':   return Icons.play_circle_rounded;
      case 'Idle':      return Icons.pause_circle_rounded;
      case 'Breakdown': return Icons.warning_rounded;
      case 'Stoppage':  return Icons.do_not_disturb_on_rounded;
      default: return Icons.help_rounded;
    }
  }

  String _time(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final act = entry['activityType'] as String?;
    final c = _color(act);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: Icon(_icon(act), color: c, size: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry['equipmentNumber'] ?? 'N/A',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Text('${entry['operatorName'] ?? ''} • ${entry['projectName'] ?? ''}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(act ?? '', style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text('${entry['hmrValue']} HMR',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(_time(entry['entryTimestamp']),
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
