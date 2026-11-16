import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career_companion_model.dart';
import '../../providers/auth_provider.dart';

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
        child: Column(
          children: [
            // 1. Top Dark Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          children: [
                            TextSpan(
                              text: 'Leveled',
                              style: TextStyle(color: AppColors.white),
                            ),
                            TextSpan(
                              text: 'Up',
                              style: TextStyle(color: AppColors.terracotta),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey<bool>(_isLoginMode),
                      children: [
                        Text(
                          _isLoginMode
                              ? 'Welcome Back, Challenger'
                              : 'Start Your Global Journey',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoginMode
                              ? 'Sign in to access your ATS scans, STAR rewrites & career quests.'
                              : 'Create your profile to scan resumes and track your global career XP.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Curved Sheet Container for Login / Register Form
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Segmented Toggle Pill (Sign In vs Register)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isLoginMode = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isLoginMode
                                        ? AppColors.terracotta
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Sign In',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
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
                                onTap: () =>
                                    setState(() => _isLoginMode = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode
                                        ? AppColors.terracotta
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Register',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
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

                      // Animated Form Switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: Offset(_isLoginMode ? -0.06 : 0.06, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: _isLoginMode
                            ? _buildLoginForm()
                            : _buildRegisterForm(),
                      ),

                      if (authState.errorMessage != null) ...[
                        const SizedBox(height: 14),
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
                                size: 18,
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

                      // Primary Submit Pill Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _isLoginMode
                                ? 'Sign In to LeveledUp'
                                : 'Create Career Account',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 1-Tap Guest / Demo Access
                      Center(
                        child: TextButton(
                          onPressed: () => ref
                              .read(authProvider.notifier)
                              .continueAsDemoGuest(),
                          child: Text(
                            'Continue with Instant Demo Account →',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.terracottaBright,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                size: 19,
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
        const SizedBox(height: 14),
        const Text(
          'Target Global Role',
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
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
                size: 19,
              ),
            ),
            hintText: 'Create a password',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Starting Career Stage',
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
                    ? 'Hunting for a Job (Pre-Job)'
                    : 'Already Hired (Career Companion)',
              ),
              selected: isSel,
              onSelected: (_) =>
                  setState(() => _selectedInitialStage = stage),
              selectedColor: AppColors.terracotta.withValues(alpha: 0.25),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSel
                    ? AppColors.terracottaBright
                    : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

