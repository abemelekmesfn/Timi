import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../providers/user_provider.dart';
import '../../providers/note_provider.dart';
import 'auth_provider.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final controller = TextEditingController();

  Future<void> signIn() async {
    if (controller.text.length != 6) return;

    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final success = await LoginController().login(controller.text);

      if (!mounted) return;
      ref.read(authLoadingProvider.notifier).state = false;

      if (success) {
        ref.invalidate(userProvider);
        ref.invalidate(noteProvider);
        context.go("/dashboard");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "invalidCode")))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ref.read(authLoadingProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")))
      );
    }
  }

  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authLoadingProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Text(
                S.of(context, "appName"),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                S.of(context, "appTagline"),
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false), // Ensures number keyboard
                textAlign: TextAlign.center,
                obscureText: _obscureText,
                obscuringCharacter: '•',
                maxLength: 6,
                style: const TextStyle(fontSize: 28, letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "••••••",
                  counterText: "",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: loading ? null : signIn,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(S.of(context, "login")),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
