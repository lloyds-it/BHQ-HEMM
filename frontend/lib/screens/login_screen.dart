import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../widgets/logo_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isObscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
      _rememberMe,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials. Please check and try again.'),
          backgroundColor: AppColors.breakdown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: isWide
          ? _buildWideLayout(authProvider, size)
          : _buildNarrowLayout(authProvider),
    );
  }

  Widget _buildWideLayout(AuthProvider auth, Size size) {
    return Row(
      children: [
        // Left panel — branding
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LogoHeader(height: 48),
                    const SizedBox(height: 32),
                    Text('Equipment Running\nLog System',
                      style: TextStyle(fontSize: 24, color: AppColors.textPrimary, height: 1.3, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text('Streamline your heavy earth moving machinery operations with real-time tracking and powerful analytics.',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5)),
                    const SizedBox(height: 36),
                    _featureRow(Icons.bolt_rounded, 'Live Equipment Tracking'),
                    const SizedBox(height: 12),
                    _featureRow(Icons.assignment_rounded, 'Shift Summary Logs'),
                    const SizedBox(height: 12),
                    _featureRow(Icons.bar_chart_rounded, 'Reports & Export'),
                    const SizedBox(height: 12),
                    _featureRow(Icons.lock_rounded, 'Role-Based Access'),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right panel — login form
        Expanded(
          flex: 3,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _buildForm(auth),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(AuthProvider auth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top brand strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
            color: Colors.white,
            child: const Column(
              children: [
                LogoHeader(height: 36),
                SizedBox(height: 24),
                Text('Equipment Running Log System',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildForm(auth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    final fs = AppTheme.fieldSpacing;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Welcome back',
              style: DesignSystem.getTextTheme(context).headlineLarge),
          const SizedBox(height: 3),
          Text('Sign in to your account',
              style: DesignSystem.getTextTheme(context).bodyMedium),
          SizedBox(height: fs + 8),

          // Username
          Text('Username', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              hintText: 'Enter your username',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Username is required' : null,
          ),
          SizedBox(height: fs),

          // Password
          Text('Password', style: DesignSystem.getTextTheme(context).labelMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),

          // Remember me
          Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Remember me', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          SizedBox(height: fs + 4),

          // Login button
          if (auth.isLoading)
            Container(
              height: AppTheme.buttonHeight,
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            )
          else
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Sign In'),
            ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          const Center(
            child: Text('BHQ Heavy Earth Moving Machinery  ·  v1.0',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 15),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
