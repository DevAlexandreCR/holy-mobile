import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/errors/app_error_mapper.dart';
import 'package:holyverso/core/l10n/app_localizations.dart';
import 'package:holyverso/core/theme/app_colors.dart';
import 'package:holyverso/core/theme/app_design_tokens.dart';
import 'package:holyverso/core/theme/app_text_styles.dart';
import 'package:holyverso/data/creator_profiles/creator_profiles_repository.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';
import 'package:holyverso/presentation/state/auth/auth_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotional_detail_controller.dart';
import 'package:holyverso/presentation/state/devotionals/devotionals_feed_controller.dart';

class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  ConsumerState<CreatorProfileScreen> createState() =>
      _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  CreatorProfile? _profile;
  List<Devotional> _items = const [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _loadingProfile = true;
  bool _loadingList = false;
  bool _refreshing = false;
  bool _togglingFollow = false;
  String? _errorMessage;

  bool get _isOwnProfile =>
      ref.read(authControllerProvider).user?.id == widget.creatorId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingList || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      unawaited(_loadMore());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loadingProfile = true;
      _loadingList = true;
      _errorMessage = null;
      _nextCursor = null;
      _hasMore = true;
    });

    try {
      final repository = ref.read(creatorProfilesRepositoryProvider);
      final results = await Future.wait([
        repository.getCreatorProfile(widget.creatorId),
        repository.getCreatorDevotionals(id: widget.creatorId),
      ]);

      if (!mounted) return;
      final profile = results[0] as CreatorProfile;
      final devotionals = results[1] as dynamic;
      setState(() {
        _profile = profile;
        _items = devotionals.items as List<Devotional>;
        _nextCursor = devotionals.nextCursor as String?;
        _hasMore = devotionals.hasMore as bool;
        _loadingProfile = false;
        _loadingList = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _loadingList = false;
        _errorMessage = AppErrorMapper.toMessage(
          error,
          l10n: context.l10n,
          fallbackMessage: context.l10n.devotionalsLoadError,
        );
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingList) return;

    setState(() {
      _loadingList = true;
    });

    try {
      final result = await ref
          .read(creatorProfilesRepositoryProvider)
          .getCreatorDevotionals(id: widget.creatorId, cursor: cursor);

      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _nextCursor = result.nextCursor;
        _hasMore = result.hasMore;
        _loadingList = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
    });
    try {
      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  void _syncProfile(CreatorProfile profile) {
    ref
        .read(forYouFeedControllerProvider.notifier)
        .syncCreatorProfile(
          creatorId: profile.id,
          following: profile.followedByMe,
          handle: profile.handle,
          avatarUrl: profile.avatarUrl,
        );
    ref
        .read(followingFeedControllerProvider.notifier)
        .syncCreatorProfile(
          creatorId: profile.id,
          following: profile.followedByMe,
          handle: profile.handle,
          avatarUrl: profile.avatarUrl,
        );
    ref
        .read(devotionalDetailControllerProvider.notifier)
        .syncCreatorProfile(
          creatorId: profile.id,
          following: profile.followedByMe,
          handle: profile.handle,
          avatarUrl: profile.avatarUrl,
        );
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _isOwnProfile || _togglingFollow) return;

    setState(() {
      _togglingFollow = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(creatorProfilesRepositoryProvider);
      final updated = profile.followedByMe
          ? await repository.unfollowCreator(profile.id)
          : await repository.followCreator(profile.id);

      if (!mounted) return;
      _syncProfile(updated);
      await ref.read(followingFeedControllerProvider.notifier).refresh();
      setState(() {
        _profile = updated;
        _togglingFollow = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _togglingFollow = false;
        _errorMessage = AppErrorMapper.toMessage(
          error,
          l10n: context.l10n,
          fallbackMessage: context.l10n.creatorProfileFollowError,
        );
      });
    }
  }

  Future<void> _editProfile() async {
    final updated = await context.push<CreatorProfile>(
      '/users/me/edit-profile',
    );
    if (!mounted || updated == null) return;
    _syncProfile(updated);
    setState(() {
      _profile = updated;
    });
  }

  Future<void> _openDevotional(Devotional devotional) async {
    await context.push('/devotionals/${devotional.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      appBar: AppBar(
        title: Text(l10n.creatorProfileTitle),
        actions: [
          if (_isOwnProfile)
            TextButton(
              onPressed: _editProfile,
              child: Text(l10n.creatorProfileEdit),
            ),
        ],
      ),
      body: _loadingProfile && _profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            )
          : _errorMessage != null && _profile == null
          ? _CreatorProfileError(message: _errorMessage!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  if (_profile != null)
                    _CreatorProfileHeader(
                      profile: _profile!,
                      isOwnProfile: _isOwnProfile,
                      isTogglingFollow: _togglingFollow,
                      onToggleFollow: _toggleFollow,
                      onEditProfile: _editProfile,
                    ),
                  if (_errorMessage != null && _profile != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CreatorProfileInlineError(message: _errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.creatorProfileDevotionalsSection,
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_items.isEmpty && !_loadingList)
                    _CreatorProfileEmpty(message: l10n.creatorProfileEmpty)
                  else
                    ..._items.map(
                      (devotional) => _CreatorDevotionalCard(
                        devotional: devotional,
                        onOpen: () => _openDevotional(devotional),
                      ),
                    ),
                  if (_loadingList)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.holyGold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _CreatorProfileHeader extends StatelessWidget {
  const _CreatorProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.isTogglingFollow,
    required this.onToggleFollow,
    required this.onEditProfile,
  });

  final CreatorProfile profile;
  final bool isOwnProfile;
  final bool isTogglingFollow;
  final VoidCallback onToggleFollow;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CreatorAvatar(
                imageUrl: profile.avatarUrl,
                name: profile.name,
                radius: 30,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.handle != null && profile.handle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '@${profile.handle}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.holyGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _CountPill(
                label: context.l10n.creatorProfileFollowers,
                value: profile.followersCount,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CountPill(
                label: context.l10n.creatorProfileFollowing,
                value: profile.followingCount,
              ),
              const SizedBox(width: AppSpacing.sm),
              _CountPill(
                label: context.l10n.creatorProfilePublished,
                value: profile.publishedDevotionalsCount,
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              profile.bio!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isOwnProfile)
            OutlinedButton(
              onPressed: onEditProfile,
              child: Text(context.l10n.creatorProfileEdit),
            )
          else
            ElevatedButton(
              onPressed: isTogglingFollow ? null : onToggleFollow,
              child: Text(
                profile.followedByMe
                    ? context.l10n.creatorProfileUnfollow
                    : context.l10n.creatorProfileFollow,
              ),
            ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({
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
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.midnightFaithDark,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.softMist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorDevotionalCard extends StatelessWidget {
  const _CreatorDevotionalCard({
    required this.devotional,
    required this.onOpen,
  });

  final Devotional devotional;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: AppBorderRadius.card,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                devotional.title,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                devotional.previewText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.softMist,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: AppColors.holyGold,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${devotional.estimatedReadTime} ${context.l10n.devotionalMinutesShort}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.holyGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorProfileError extends StatelessWidget {
  const _CreatorProfileError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.l10n.errorRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorProfileInlineError extends StatelessWidget {
  const _CreatorProfileInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: AppBorderRadius.card,
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureWhite),
      ),
    );
  }
}

class _CreatorProfileEmpty extends StatelessWidget {
  const _CreatorProfileEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.midnightFaith.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.softMist),
      ),
    );
  }
}
