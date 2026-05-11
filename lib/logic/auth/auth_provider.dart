import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signUp(email: email, password: password, name: name);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Sign up failed', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Sign in failed', StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}
