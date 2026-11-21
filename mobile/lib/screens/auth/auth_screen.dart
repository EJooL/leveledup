import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/leveledup_arrow.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  // Controllers
  final _nameCtrl = TextEditingController(text: 'Ijul');
  final _roleCtrl = TextEditingController(
    text: 'Global Software & Mobile Engineer',
  );
  final _emailCtrl = TextEditingController(text: 'ijul@leveledup.id');
  final _passwordCtrl = TextEditingController(text: 'leveledup2026');
  CareerStage _selectedInitialStage = CareerStage.jobHunting;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    final notifier = ref.read(authProvider.notifier);
    if (_isLoginMode) {
      notifier.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
    } else {
      notifier.registerAccount(
        fullName: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        targetRole: _roleCtrl.text,
        initialStage: _selectedInitialStage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Main Hero Brand Logo with Warm Orange Glow Behind It
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: OverflowBox(
                              maxWidth: 380,
                              maxHeight: 220,
                              child: Container(
                                width: 340,
                                height: 192,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.56,
                                    colors: [
                                      AppColors.accentGoldBright
                                          .withValues(alpha: 0.42),
                                      AppColors.terracottaBright
                                          .withValues(alpha: 0.28),
                                      AppColors.terracotta
                                          .withValues(alpha: 0.12),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.34, 0.66, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LeveledUpArrow(width: 24, height: 36),
                          SizedBox(width: 12),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Leveled',
                                  style: TextStyle(color: AppColors.white),
                                ),
                                TextSpan(
                                  text: 'Up',
                                  style: TextStyle(
                                    color: AppColors.terracotta,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // 2. Headline & Professional Living CV Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey<bool>(_isLoginMode),
                      children: [
                        Text(
                          _isLoginMode ? 'Welcome back' : 'Create your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Track your ATS progress, log work wins, and keep your CV updated.'
                              : 'Set up your profile to track ATS progress, log work wins, and keep your CV updated.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Harmonized Segmented Control (Active tab: Main Terracotta Orange)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLoginMode = true),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isLoginMode
                                    ? AppColors.terracotta
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _isLoginMode
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLoginMode = false),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isLoginMode
                                    ? AppColors.terracotta
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Register',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: !_isLoginMode
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Animated Form Fields Directly on #09090B Canvas
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: Offset(_isLoginMode ? -0.05 : 0.05, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _isLoginMode
                        ? _buildLoginForm()
                        : _buildRegisterForm(),
                  ),

                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.crimson),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.crimson,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 5. Primary CTA Button (Main Terracotta Orange, 12px radius)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isLoginMode ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Subtle "or" Divider
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 7. Full-Width 48px Outlined Secondary Button (Neutral Light Text)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(authProvider.notifier)
                          .continueAsDemoGuest(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Instant Demo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            hintText: 'you@example.com',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            hintText: 'Enter your password',
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            hintText: 'e.g. Ijul',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Target Role',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _roleCtrl,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.work_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            hintText: 'e.g. Global Software & Mobile Engineer',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            hintText: 'you@example.com',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            hintText: 'Create a password',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Current Stage',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CareerStage.jobHunting,
            CareerStage.onboarding,
          ].map((stage) {
            final isSel = stage == _selectedInitialStage;
            return ChoiceChip(
              label: Text(
                stage == CareerStage.jobHunting
                    ? 'Job Hunting'
                    : 'Already Hired',
              ),
              selected: isSel,
              showCheckmark: false,
              onSelected: (_) =>
                  setState(() => _selectedInitialStage = stage),
              selectedColor: AppColors.border,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSel ? AppColors.borderBright : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? AppColors.white : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

