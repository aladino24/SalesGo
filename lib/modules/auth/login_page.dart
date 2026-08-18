import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/constants/app_constants.dart';
import 'login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.storefront_rounded, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mobile Sales Force Automation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (value) => controller.username.value = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onChanged: (value) => controller.password.value = value,
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: controller.isLoading.value ? null : controller.login,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        controller.isLoading.value ? 'Masuk...' : 'Login',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'App Version ${AppConstants.appVersion}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
