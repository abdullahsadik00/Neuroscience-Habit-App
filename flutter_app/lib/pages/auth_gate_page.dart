// TODO SETUP — Before this screen works you need:
//
// 1. Create a Supabase project at https://supabase.com
//    - Project name: neurosync (or anything you like)
//    - Choose a region close to your users
//
// 2. Enable Email (magic link) auth:
//    Dashboard → Authentication → Providers → Email
//    - Enable Email provider: ON
//    - "Confirm email": OFF (so magic link logs in immediately)
//    - "Enable email OTP": ON
//
// 3. For deep-link redirect (so the magic link opens the app):
//    Dashboard → Authentication → URL Configuration
//    - Add to "Redirect URLs": com.neuroflow://login-callback/
//    - For web: http://localhost:62728
//
//    In flutter_app/android/app/src/main/AndroidManifest.xml add inside <activity>:
//      <intent-filter>
//        <action android:name="android.intent.action.VIEW" />
//        <category android:name="android.intent.category.DEFAULT" />
//        <category android:name="android.intent.category.BROWSABLE" />
//        <data android:scheme="com.neuroflow" android:host="login-callback" />
//      </intent-filter>
//
//    In flutter_app/ios/Runner/Info.plist add:
//      <key>CFBundleURLTypes</key>
//      <array>
//        <dict>
//          <key>CFBundleURLSchemes</key>
//          <array><string>com.neuroflow</string></array>
//        </dict>
//      </array>
//
// 4. Copy your project URL and anon key from:
//    Dashboard → Project Settings → API
//    Then run with:
//      flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//                  --dart-define=SUPABASE_ANON_KEY=eyJxxxx
//    Or add them to a .env file (never commit to git).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'com.neuroflow://login-callback/',
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                'NeuroSync',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
              ).animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                'Your personal habit recovery system.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textSecondary,
                    ),
              ).animate().fadeIn(delay: 100.ms),
              const Spacer(),
              if (!_sent) ...[
                Text(
                  'Sign in with email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendMagicLink(),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    filled: true,
                    fillColor: context.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    errorText: _error,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _sendMagicLink,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send magic link', style: TextStyle(fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 250.ms),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF6366F1)),
                      const SizedBox(height: 16),
                      Text(
                        'Check your inbox',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a magic link to ${_emailController.text.trim()}. Tap it to sign in.',
                        style: TextStyle(color: context.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _sent = false;
                      _emailController.clear();
                    }),
                    child: Text('Use a different email', style: TextStyle(color: context.textSecondary)),
                  ),
                ),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
