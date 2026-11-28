import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'auth_controller.dart';
import 'auth_service.dart';
import 'profile_page.dart';
import 'question.dart';

/// Trang đăng nhập bằng email + mật khẩu, kèm nút "Tiếp tục với Google".
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.controller,
    this.language = QuestionLanguage.vietnamese,
  });

  final AuthController controller;
  final QuestionLanguage language;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AppStrings get s => AppStrings.of(widget.language);
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _remember = false;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.controller.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        remember: _remember,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            controller: widget.controller,
            language: widget.language,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showFailure(e.failure);
    } catch (_) {
      _showFailure(AuthFailure.unknown);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await widget.controller.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            controller: widget.controller,
            language: widget.language,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showFailure(e.failure);
    } catch (_) {
      _showFailure(AuthFailure.unknown);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showFailure(AuthFailure failure) {
    final message = authFailureMessage(failure, s);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.signInTitle)),
      body: AuthScaffold(
        children: [
          Text(
            s.signInTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.signInSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: InputDecoration(labelText: s.emailLabel),
                    validator: (value) => validateEmail(value, s),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: s.passwordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? s.showPassword
                            : s.hidePassword,
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? s.passwordRequired
                        : null,
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _remember,
                    onChanged: _loading
                        ? null
                        : (value) => setState(() => _remember = value ?? false),
                    title: Text(s.rememberMe),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(s.signInButton),
                  ),
                ],
              ),
            ),
          ),
          if (widget.controller.googleEnabled) ...[
            const SizedBox(height: 16),
            GoogleButton(
              label: s.continueWithGoogle,
              loading: _googleLoading,
              onPressed: _googleLoading ? null : _googleSignIn,
            ),
          ],
          if (widget.controller.demoEnabled &&
              widget.controller.demoEmail != null &&
              widget.controller.demoPassword != null) ...[
            const SizedBox(height: 20),
            DemoHintCard(
              title: s.demoHintTitle,
              body: s.demoHintBody(
                widget.controller.demoEmail!,
                widget.controller.demoPassword!,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AuthSwitchRow(
            prompt: s.noAccount,
            actionLabel: s.signUpLink,
            onAction: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RegisterPage(
                  controller: widget.controller,
                  language: widget.language,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trang đăng ký tài khoản mới bằng email.
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.controller,
    this.language = QuestionLanguage.vietnamese,
  });

  final AuthController controller;
  final QuestionLanguage language;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  AppStrings get s => AppStrings.of(widget.language);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.controller.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.registerSuccess)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            controller: widget.controller,
            language: widget.language,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showFailure(e.failure);
    } catch (_) {
      _showFailure(AuthFailure.unknown);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      await widget.controller.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            controller: widget.controller,
            language: widget.language,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showFailure(e.failure);
    } catch (_) {
      _showFailure(AuthFailure.unknown);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _showFailure(AuthFailure failure) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(authFailureMessage(failure, s))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.registerTitle)),
      body: AuthScaffold(
        children: [
          Text(
            s.registerTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.registerSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: s.nameLabel),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? s.nameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    decoration: InputDecoration(labelText: s.emailLabel),
                    validator: (value) => validateEmail(value, s),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: s.passwordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? s.showPassword
                            : s.hidePassword,
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.passwordRequired;
                      }
                      if (value.length < 8) return s.passwordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: s.confirmPasswordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirm
                            ? s.showPassword
                            : s.hidePassword,
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? s.passwordMismatch
                        : null,
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(s.signUpButton),
                  ),
                ],
              ),
            ),
          ),
          if (widget.controller.googleEnabled) ...[
            const SizedBox(height: 16),
            GoogleButton(
              label: s.continueWithGoogle,
              loading: _googleLoading,
              onPressed: _googleLoading ? null : _googleSignIn,
            ),
          ],
          const SizedBox(height: 24),
          AuthSwitchRow(
            prompt: s.haveAccount,
            actionLabel: s.signInLink,
            onAction: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LoginPage(
                  controller: widget.controller,
                  language: widget.language,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ánh xạ mã lỗi xác thực thành thông báo theo ngôn ngữ, không để lộ thông
/// tin nhạy cảm (không cho biết email có tồn tại hay không).
String authFailureMessage(AuthFailure failure, AppStrings s) {
  return switch (failure) {
    AuthFailure.invalidCredentials => s.authInvalidCredentials,
    AuthFailure.invalidEmail => s.emailInvalid,
    AuthFailure.missingName => s.nameRequired,
    AuthFailure.weakPassword => s.passwordTooShort,
    AuthFailure.emailInUse => s.authEmailInUse,
    AuthFailure.googleNotConfigured => s.authGoogleNotConfigured,
    AuthFailure.disabled => s.authDisabled,
    AuthFailure.unknown => s.authUnknown,
  };
}

String? validateEmail(String? value, AppStrings s) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return s.emailRequired;
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return valid ? null : s.emailInvalid;
}

/// Khung chung cho các trang xác thực: căn giữa, giới hạn độ rộng nội dung và
/// tự cuộn khi bàn phím hiện.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const maxContentWidth = 440.0;
          final basePadding = constraints.maxWidth < 380 ? 16.0 : 24.0;
          final horizontalPadding =
              constraints.maxWidth > maxContentWidth + basePadding * 2
              ? (constraints.maxWidth - maxContentWidth) / 2
              : basePadding;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        },
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const _GoogleG(),
      label: Text(label),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

class DemoHintCard extends StatelessWidget {
  const DemoHintCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class AuthSwitchRow extends StatelessWidget {
  const AuthSwitchRow({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
