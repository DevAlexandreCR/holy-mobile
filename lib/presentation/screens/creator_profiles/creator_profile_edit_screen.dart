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
      appBar: AppBar(title: Text(l10n.creatorProfileEditTitle)),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: _avatarFile != null
                        ? CircleAvatar(
                            radius: 44,
                            backgroundImage: FileImage(_avatarFile!),
                          )
                        : _EditableAvatar(
                            imageUrl: _currentAvatarUrl,
                            name: _handleController.text.trim().isNotEmpty
                                ? _handleController.text.trim()
                                : l10n.creatorProfileAvatarFallback,
                            radius: 44,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _pickAvatar,
                        child: Text(l10n.creatorProfileChangeAvatar),
                      ),
                      if (_avatarFile != null || _currentAvatarUrl != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        TextButton(
                          onPressed: _removeAvatar,
                          child: Text(l10n.creatorProfileRemoveAvatar),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _handleController,
                    decoration: InputDecoration(
                      labelText: l10n.creatorHandleLabel,
                      hintText: l10n.creatorHandleHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _bioController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.creatorBioLabel,
                      hintText: l10n.creatorBioHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? l10n.creatorProfileSaving : l10n.saveAction,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.holyGold.withValues(alpha: 0.18),
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.holyGold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
