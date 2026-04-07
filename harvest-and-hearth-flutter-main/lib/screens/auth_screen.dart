import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// Sign-in / sign-up UI provided by Clerk (email, OAuth per Clerk Dashboard).
///
/// **Mã xác thực email (OTP):** bật chiến lược *Email verification code* trong
/// [Clerk Dashboard](https://dashboard.clerk.com) → *User & Authentication* →
/// *Email, Phone, Username* (và/hoặc *Sign-in / Sign-up*). Dán HTML trong
/// `clerk/email-templates/verification-code.html` (markup **Revolvapp** `re-*`, không phải HTML bảng thường)
/// vào template **Verification code** — xem `clerk/email-templates/README.md`.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final testEmail = dotenv.env['TEST_ACCOUNT_EMAIL']?.trim() ?? '';
    final testPassword = dotenv.env['TEST_ACCOUNT_PASSWORD'] ?? '';
    final showTestHint =
        testEmail.isNotEmpty && testPassword.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.eco_rounded, size: 44, color: cs.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Harvest & Hearth',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
              ),
              Text(
                t('auth_tagline'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              const ClerkAuthentication(),
              if (showTestHint) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showTestAccountSheet(
                    context,
                    testEmail,
                    testPassword.trim(),
                  ),
                  icon: const Icon(Icons.person_outline_rounded),
                  label: Text(t('auth_test_account')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void _showTestAccountSheet(
    BuildContext context,
    String email,
    String password,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tài khoản thử',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập hoặc đăng ký thủ công trên form phía trên bằng thông tin dưới đây (user phải tồn tại trong Clerk).',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Email:\n$email\n\nMật khẩu:\n$password',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '$email\n$password'),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép email và mật khẩu'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Sao chép email + mật khẩu'),
              ),
            ],
          ),
        );
      },
    );
  }
}
