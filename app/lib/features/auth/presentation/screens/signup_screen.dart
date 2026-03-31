import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/core/utils/validators.dart';
import 'package:imjang_app/features/auth/presentation/providers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    // Use the part before @ as display name, or fallback
    final displayName = email.split('@').first;

    await ref.read(authControllerProvider.notifier).signUp(
          email: email,
          password: _passwordController.text,
          displayName: displayName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SignupScreen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message from auth state
                if (authState is AsyncError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authState.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                // Email field
                TextFormField(
                  key: const Key('signup_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  key: const Key('signup_password_field'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // Password confirm field
                TextFormField(
                  key: const Key('signup_password_confirm_field'),
                  controller: _passwordConfirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                  ),
                  validator: (value) => Validators.validatePasswordConfirm(
                    _passwordController.text,
                    value,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  key: const Key('signup_submit_button'),
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
