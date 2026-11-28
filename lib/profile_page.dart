import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_strings.dart';
import 'auth_controller.dart';
import 'auth_pages.dart';
import 'auth_user.dart';
import 'question.dart';

/// Trang "Thông tin thành viên": chỉ người đã đăng nhập mới truy cập được.
///
/// Khi người dùng đăng xuất (hoặc phiên bị xoá), trang tự chuyển về trang
/// đăng nhập nhờ lắng nghe [AuthController].
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    this.language = QuestionLanguage.vietnamese,
  });

  final AuthController controller;
  final QuestionLanguage language;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppStrings get s => AppStrings.of(widget.language);
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.controller.isAuthenticated) {
        _redirectToLogin();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (!widget.controller.isAuthenticated) {
      _redirectToLogin();
    } else {
      setState(() {});
    }
  }

  void _redirectToLogin() {
    if (_redirecting || !mounted) return;
    _redirecting = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            LoginPage(controller: widget.controller, language: widget.language),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _signOut() async {
    await widget.controller.signOut();
    // Việc chuyển về trang đăng nhập do listener _onAuthChanged xử lý.
  }

  Future<void> _editName() async {
    final user = widget.controller.user;
    if (user == null) return;
    var value = user.name;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.editName),
        content: TextFormField(
          initialValue: user.name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: s.nameLabel),
          onChanged: (text) => value = text,
          onFieldSubmitted: (text) => Navigator.pop(context, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: Text(s.saveButton),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    await widget.controller.updateProfile(user.copyWith(name: newName));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.profileNameSaved)));
    }
  }

  Future<void> _showAvatarOptions() async {
    final user = widget.controller.user;
    if (user == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.editAvatar),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            if (user.hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(s.removeAvatar),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final user = widget.controller.user;
    if (user == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await widget.controller.updateProfile(
        user.copyWith(avatarBase64: base64Encode(bytes)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.avatarPickFailed)));
      }
    }
  }

  Future<void> _removeAvatar() async {
    final user = widget.controller.user;
    if (user == null) return;
    await widget.controller.updateProfile(user.copyWith(clearAvatar: true));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.controller.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxContentWidth = 520.0;
            final basePadding = constraints.maxWidth < 380 ? 16.0 : 24.0;
            final horizontalPadding =
                constraints.maxWidth > maxContentWidth + basePadding * 2
                ? (constraints.maxWidth - maxContentWidth) / 2
                : basePadding;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                32,
              ),
              children: [
                Center(
                  child: _Avatar(user: user, onEdit: _showAvatarOptions),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: s.editName,
                      onPressed: _editName,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ],
                ),
                if (widget.controller.isDemoAccount) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.science_outlined, size: 18),
                      label: Text(s.demoBadge),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(s.emailLabel),
                        subtitle: Text(user.email),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: Text(s.memberSince),
                        subtitle: Text(_formatDate(user.joinedAt)),
                      ),
                    ],
                  ),
                ),
                if (widget.controller.isDemoAccount) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.demoBadgeNote,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(s.logout),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onEdit});

  final AuthUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: colors.primaryContainer,
          backgroundImage: user.hasAvatar
              ? _safeImage(user.avatarBase64!)
              : null,
          child: user.hasAvatar
              ? null
              : Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
        ),
        Material(
          color: colors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _safeImage(String base64) {
    try {
      return MemoryImage(base64Decode(base64));
    } catch (_) {
      return null;
    }
  }
}
