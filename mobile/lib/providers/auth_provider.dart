import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/career_companion_model.dart';
import 'career_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final String email;
  final String fullName;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.email = '',
    this.fullName = 'Ijul',
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? fullName,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  bool signIn({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || !email.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email address.');
      return false;
    }
    if (password.length < 4) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 4 characters.',
      );
      return false;
    }

    // Derive display name from email if not already customized
    final rawPrefix = email.split('@').first.trim();
    final formattedName = rawPrefix.isNotEmpty
        ? rawPrefix[0].toUpperCase() + rawPrefix.substring(1)
        : 'Ijul';

    _ref.read(careerProvider.notifier).updateProfileIdentity(
          name: formattedName,
        );

    state = state.copyWith(
      isAuthenticated: true,
      email: email.trim(),
      fullName: formattedName,
      clearError: true,
    );
    return true;
  }

  bool registerAccount({
    required String fullName,
    required String email,
    required String password,
    required String targetRole,
    required CareerStage initialStage,
  }) {
    if (fullName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your full name.');
      return false;
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      state = state.copyWith(errorMessage: 'Please enter a valid email address.');
      return false;
    }
    if (password.length < 4) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 4 characters.',
      );
      return false;
    }

    _ref.read(careerProvider.notifier).updateProfileIdentity(
          name: fullName.trim(),
          targetRole: targetRole.trim().isEmpty
              ? 'Global Software & Mobile Engineer'
              : targetRole.trim(),
          stage: initialStage,
        );

    state = state.copyWith(
      isAuthenticated: true,
      email: email.trim(),
      fullName: fullName.trim(),
      clearError: true,
    );
    return true;
  }

  void continueAsDemoGuest() {
    _ref.read(careerProvider.notifier).updateProfileIdentity(
          name: 'Ijul',
          targetRole: 'Global Software & Mobile Engineer',
        );
    state = state.copyWith(
      isAuthenticated: true,
      email: 'ijul@leveledup.id',
      fullName: 'Ijul',
      clearError: true,
    );
  }

  void signOut() {
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

