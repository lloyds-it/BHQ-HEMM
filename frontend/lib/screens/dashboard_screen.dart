import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchStats();
    });
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;
    
    // Index 0: Dashboard (stay)
    // Index 1: Live Entry
    // Index 2: Summary Log
    // Index 3: Reports
    // Index 4: Masters
    
    Widget? target;
    if (index == 1) target = const LiveEntryForm();
    if (index == 2) target = const SummaryLogForm();
    if (index == 3) target = const ReportsScreen();
    if (index == 4) target = const MastersScreen();
    
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target!)).then((_) {
        Provider.of<DashboardProvider>(context, listen: false).fetchStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.role == 'Admin';
    final isSupervisor = auth.role == 'Supervisor';
    
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          
          if (isDesktop) {
            return Row(
              children: [
                _buildSideNav(isAdmin),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(child: _DashboardContent(onLogout: _logout)),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: _DashboardContent(onLogout: _logout)),
                _buildBottomNav(isAdmin),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSideNav(bool isAdmin) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onNavTapped,
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.bgCard,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: DesignSystem.getTextTheme(context).labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: DesignSystem.getTextTheme(context).labelMedium?.copyWith(color: AppColors.textSecondary),
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text('BHQ HEMM', style: DesignSystem.getTextTheme(context).titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      destinations: [
        const NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
        const NavigationRailDestination(icon: Icon(Icons.bolt_rounded), label: Text('Live Entry')),
        const NavigationRailDestination(icon: Icon(Icons.assignment_rounded), label: Text('Summary')),
        if (isAdmin)
          const NavigationRailDestination(icon: Icon(Icons.bar_chart_rounded), label: Text('Reports')),
        if (isAdmin)
          const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Masters')),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onNavTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: 'Live'),
        const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Summary'),
        if (isAdmin)
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        if (isAdmin)
          const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Masters'),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback onLogout;
  const _DashboardContent({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<DashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.role == 'Admin';
    final isSupervisor = auth.role == 'Supervisor';
    final p = AppTheme.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        title: const LogoHeader(height: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: () => stats.fetchStats(),
            tooltip: 'Refresh',
          ),
          if (MediaQuery.of(context).size.width <= 800)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              onPressed: onLogout,
              tooltip: 'Logout',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => stats.fetchStats(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(context, auth),
                    SizedBox(height: AppTheme.sectionSpacing),
                    _buildStatsGrid(context, stats),
                    if (isAdmin) ...[
                      SizedBox(height: AppTheme.sectionSpacing),
                      Text('Analytics & Trends', style: DesignSystem.getTextTheme(context).titleLarge),
                      const SizedBox(height: 12),
                      DashboardAnalyticsGrid(stats: stats),
                    ],
                    SizedBox(height: AppTheme.sectionSpacing),
                    _buildQuickActions(context, isAdmin),
                    SizedBox(height: AppTheme.sectionSpacing),
                    _buildRecentEntries(context, stats),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: DesignSystem.softShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.waves, size: 100, color: Colors.white.withOpacity(0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (auth.role ?? 'Operator').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  Text(_formattedDate(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                auth.username ?? 'User',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardProvider stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Overview', style: DesignSystem.getTextTheme(context).titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 800 ? 5 : constraints.maxWidth > 500 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _StatCard(title: "Today's Entries", value: stats.todayLiveEntriesCount.toString(),
                    icon: Icons.receipt_long_rounded, color: AppColors.primary),
                _StatCard(title: 'Running', value: stats.runningEquipmentCount.toString(),
                    icon: Icons.play_circle_rounded, color: AppColors.running),
                _StatCard(title: 'Idle', value: stats.idleEquipmentCount.toString(),
                    icon: Icons.pause_circle_rounded, color: AppColors.idle),
                _StatCard(title: 'Breakdown', value: stats.breakdownEquipmentCount.toString(),
                    icon: Icons.warning_rounded, color: AppColors.breakdown),
                _StatCard(title: 'Stoppage', value: stats.stoppageEquipmentCount.toString(),
                    icon: Icons.do_not_disturb_on_rounded, color: AppColors.stoppage),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: DesignSystem.getTextTheme(context).titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _ActionCard(label: 'Live Entry', icon: Icons.bolt_rounded, color: AppColors.accent,
                    onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveEntryForm()))
                        .then((_) => Provider.of<DashboardProvider>(context, listen: false).fetchStats()); }),
                _ActionCard(label: 'Summary Log', icon: Icons.assignment_rounded, color: AppColors.primary,
                    onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryLogForm()))
                        .then((_) => Provider.of<DashboardProvider>(context, listen: false).fetchStats()); }),
                if (isAdmin)
                  _ActionCard(label: 'Reports', icon: Icons.bar_chart_rounded, color: AppColors.running,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                if (isAdmin)
                  _ActionCard(label: 'Masters', icon: Icons.settings_rounded, color: AppColors.stoppage,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MastersScreen()))),
              ],
            );
          }
        ),
      ],
    );
  }

  Widget _buildRecentEntries(BuildContext context, DashboardProvider stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Live Entries', style: DesignSystem.getTextTheme(context).titleLarge),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              child: const Text('View All →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (stats.recentEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No entries logged yet today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.recentEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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

// ─── Interactive Cards ────────────────────────────────────────────────────────

class _StatCard extends StatefulWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: _isHovered ? DesignSystem.hoverShadow : DesignSystem.softShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                Text(widget.value, style: DesignSystem.getTextTheme(context).headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            Text(widget.title, style: DesignSystem.getTextTheme(context).bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -2.0 : 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: _isHovered ? DesignSystem.hoverShadow : DesignSystem.softShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.label, style: DesignSystem.getTextTheme(context).bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icon(act), color: c, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['equipmentNumber'] ?? 'N/A', style: DesignSystem.getTextTheme(context).bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${entry['operatorName'] ?? 'No operator'} • ${entry['projectName'] ?? ''}', 
                  style: DesignSystem.getTextTheme(context).bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(act ?? '', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Text('${entry['hmrValue']} HMR', style: DesignSystem.getTextTheme(context).bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(_time(entry['entryTimestamp']), style: DesignSystem.getTextTheme(context).labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
