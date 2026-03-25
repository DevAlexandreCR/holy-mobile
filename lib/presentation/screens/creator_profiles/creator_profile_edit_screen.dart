import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/creator_profiles/creator_profiles_repository.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';

class CreatorProfileEditScreen extends ConsumerStatefulWidget {
  const CreatorProfileEditScreen({super.key});

  @override
  ConsumerState<CreatorProfileEditScreen> createState() =>
      _CreatorProfileEditScreenState();
}

class _CreatorProfileEditScreenState
    extends ConsumerState<CreatorProfileEditScreen> {
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _avatarFile;
  String? _currentAvatarUrl;
  bool _loading = true;
  bool _saving = false;
  bool _clearAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(authControllerProvider).user?.id;
    if (userId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final profile = await ref
          .read(creatorProfilesRepositoryProvider)
          .getCreatorProfile(userId);

      if (!mounted) return;
      setState(() {
        _handleController.text = profile.handle ?? '';
        _bioController.text = profile.bio ?? '';
        _currentAvatarUrl = profile.avatarUrl;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.toMessage(
              error,
              l10n: context.l10n,
              fallbackMessage: context.l10n.creatorProfileLoadError,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (file == null || !mounted) return;
    setState(() {
      _avatarFile = File(file.path);
      _clearAvatar = false;
    });
  }

  void _removeAvatar() {
    setState(() {
      _avatarFile = null;
      _currentAvatarUrl = null;
      _clearAvatar = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(creatorProfilesRepositoryProvider);
      String? avatarAssetId;
      String? avatarWarningMessage;

      if (_avatarFile != null) {
        final uploaded = await repository.uploadAvatar(_avatarFile!);
        if (uploaded.attachable) {
          avatarAssetId = uploaded.assetId;
        } else {
          avatarWarningMessage =
              uploaded.moderationReason ?? l10n.creatorAvatarRejected;
        }
      }

      final result = await repository.updateMyCreatorProfile(
        handle: _handleController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        avatarAssetId: avatarAssetId,
        clearAvatar: _clearAvatar && _avatarFile == null,
      );

      if (!mounted) return;

      final warning =
          result.avatarAttachmentErrorMessage ?? avatarWarningMessage;
      if (warning != null && warning.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(warning)));
      }

      Navigator.of(context).pop<CreatorProfile>(result.profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.toMessage(
              error,
              l10n: l10n,
              fallbackMessage: l10n.creatorProfileSaveError,
              businessCodeMessages: {
                'HANDLE_ALREADY_TAKEN': l10n.creatorHandleTaken,
                'INVALID_HANDLE': l10n.creatorHandleInvalid,
              },
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.pureWhite,
        title: Text(l10n.creatorProfileEditTitle),
      ),
      body: Stack(
        children: [
          const _EditProfileBackground(),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            )
          else
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: _EditableAvatar(
                      file: _avatarFile,
                      imageUrl: _currentAvatarUrl,
                      name: _handleController.text.trim().isNotEmpty
                          ? _handleController.text.trim()
                          : l10n.creatorProfileAvatarFallback,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    children: [
                      TextButton(
                        onPressed: _pickAvatar,
                        child: Text(l10n.creatorProfileChangeAvatar),
                      ),
                      if (_avatarFile != null || _currentAvatarUrl != null)
                        TextButton(
                          onPressed: _removeAvatar,
                          child: Text(l10n.creatorProfileRemoveAvatar),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FormLabel(text: l10n.creatorHandleLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileInputCard(
                    trailing: Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.holyGold.withValues(alpha: 0.72),
                    ),
                    child: TextField(
                      controller: _handleController,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.pureWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.creatorHandleHint,
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.softMist.withValues(alpha: 0.48),
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FormLabel(text: l10n.creatorBioLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileInputCard(
                    child: TextField(
                      controller: _bioController,
                      minLines: 5,
                      maxLines: 6,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.pureWhite,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.creatorBioHint,
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.softMist.withValues(alpha: 0.48),
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.holyGold,
                      foregroundColor: AppColors.midnightFaithDark,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.full,
                        ),
                      ),
                      textStyle: AppTextStyles.button.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    child: Text(
                      _saving
                          ? l10n.creatorProfileSaving.toUpperCase()
                          : l10n.saveAction.toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '"${l10n.creatorProfileEditFootnote}"',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.62),
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EditProfileBackground extends StatelessWidget {
  const _EditProfileBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.midnightGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100,
            left: -40,
            child: _GlowCircle(
              size: 190,
              color: AppColors.holyGold.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: 220,
            right: -60,
            child: _GlowCircle(
              size: 170,
              color: AppColors.morningLight.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -10,
            child: _GlowCircle(
              size: 160,
              color: AppColors.holyGold.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.file,
    required this.imageUrl,
    required this.name,
  });

  final File? file;
  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final avatar = file != null
        ? CircleAvatar(radius: 50, backgroundImage: FileImage(file!))
        : imageUrl != null && imageUrl!.isNotEmpty
        ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl!))
        : CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.inputBackground,
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.holyGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.holyGold.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: avatar,
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.holyGold.withValues(alpha: 0.74),
        letterSpacing: 1.6,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfileInputCard extends StatelessWidget {
  const _ProfileInputCard({required this.child, this.trailing});

  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
