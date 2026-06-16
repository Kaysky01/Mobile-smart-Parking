import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _npmController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _npmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<AppController>().login(
      _npmController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Deep indigo
              Color(0xFF2563EB), // Primary blue
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _BrandHeader(),
                              const SizedBox(height: 28),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 32.0,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome Back',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.text,
                                                fontSize: 22,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Sign in to manage your smart parking account.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        TextFormField(
                                          controller: _npmController,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            labelText: 'NPM',
                                            hintText: 'Enter your NPM',
                                            prefixIcon: Icon(
                                              Icons.badge_outlined,
                                            ),
                                          ),
                                          validator: (value) =>
                                              value == null ||
                                                  value.trim().isEmpty
                                              ? 'NPM is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            hintText: 'Enter your password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                            suffixIcon: IconButton(
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                              ),
                                            ),
                                          ),
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                              ? 'Password is required'
                                              : null,
                                        ),
                                        if (controller.errorMessage !=
                                            null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.danger
                                                    .withValues(alpha: 0.20),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: AppColors.danger,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    controller.errorMessage!,
                                                    style: const TextStyle(
                                                      color: AppColors.danger,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 24),
                                        FilledButton(
                                          onPressed: controller.isSubmitting
                                              ? null
                                              : _submit,
                                          child: controller.isSubmitting
                                              ? const SizedBox.square(
                                                  dimension: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Text('Login'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'RFID Smart Parking for Students',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            color: AppColors.primary,
            size: 38,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MyParking',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
