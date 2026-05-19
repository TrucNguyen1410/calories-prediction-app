import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? userData;
  final String? token;

  AuthState({
    this.status = AuthStatus.unknown,
    this.userData,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? userData,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      userData: userData ?? this.userData,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState()) {
    ApiService.onUnauthorized = () {
      state = AuthState(status: AuthStatus.unauthenticated);
    };
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await _apiService.getToken();
      final user = await _apiService.getUserData();
      if (token != null && user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          userData: user,
          token: token,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.loginUser(email: email, password: password);
    if (response['success'] == true) {
      state = AuthState(
        status: AuthStatus.authenticated,
        userData: response['user'],
        token: response['token'],
      );
    }
    return response;
  }

  Future<void> loginWithGoogle(Map<String, dynamic> user, String token) async {
    state = AuthState(
      status: AuthStatus.authenticated,
      userData: user,
      token: token,
    );
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  // Update dynamic user profile information on backend and local state
  Future<Map<String, dynamic>> updateProfile({
    required double height,
    required double weight,
    required String gender,
    required int age,
  }) async {
    final result = await _apiService.updateProfile(
      height: height,
      weight: weight,
      gender: gender,
      age: age,
    );
    if (result['success'] == true) {
      state = state.copyWith(userData: result['user']);
    }
    return result;
  }

  // Force update user data in state (e.g. when updating BMI height/weight)
  Future<void> refreshUserData() async {
    final user = await _apiService.getUserData();
    if (user != null) {
      state = state.copyWith(userData: user);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
