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
import 'package:holyverso/presentation/widgets/common/holy_child_app_bar.dart';
import 'package:holyverso/presentation/widgets/notifications/notification_inbox_bell_button.dart';

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
          fallbackMessage: context.l10n.creatorProfileLoadError,
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
    final updated = await context.push<CreatorProfile>('/profile/edit');
    if (!mounted || updated == null) return;
    _syncProfile(updated);
    setState(() {
      _profile = updated;
    });
  }

  Future<void> _openInsights() async {
    await context.push('/profile/insights');
  }

  Future<void> _openSettings() async {
    await context.push('/profile/settings');
  }

  Future<void> _openDevotional(Devotional devotional) async {
    await context.push('/devotionals/${devotional.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightFaith,
      extendBodyBehindAppBar: _isOwnProfile,
      appBar: _isOwnProfile
          ? null
          : HolyChildAppBar(
              title: _profile?.name ?? context.l10n.creatorProfileTitle,
              actions: const [NotificationInboxBellButton()],
            ),
      body: Stack(
        children: [
          const _ProfileBackground(),
          if (_loadingProfile && _profile == null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.holyGold),
            )
          else if (_errorMessage != null && _profile == null)
            _CreatorProfileError(message: _errorMessage!, onRetry: _load)
          else
            RefreshIndicator(
              color: AppColors.holyGold,
              backgroundColor: AppColors.midnightFaith,
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  _isOwnProfile ? 68 : AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  if (_isOwnProfile) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const NotificationInboxBellButton(),
                          const SizedBox(width: AppSpacing.sm),
                          _IconActionButton(
                            icon: Icons.insights_outlined,
                            tooltip: 'Insights',
                            onPressed: _openInsights,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _IconActionButton(
                            icon: Icons.menu_rounded,
                            tooltip: context.l10n.settingsTooltip,
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeading(
                    title: context.l10n.creatorProfileDevotionalsSection,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_items.isEmpty && !_loadingList)
                    _CreatorProfileEmpty(
                      message: context.l10n.creatorProfileEmpty,
                    )
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
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.midnightGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _BlurCircle(
              size: 220,
              color: AppColors.holyGold.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: _BlurCircle(
              size: 190,
              color: AppColors.morningLight.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -30,
            child: _BlurCircle(
              size: 170,
              color: AppColors.holyGold.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

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
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 30),
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
    final bio = profile.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;
    final handle = profile.handle?.trim();

    return Column(
      children: [
        _CreatorAvatar(
          imageUrl: profile.avatarUrl,
          name: profile.name,
          radius: 46,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline2.copyWith(
            color: AppColors.holyGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (handle != null && handle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@$handle',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.82),
            ),
          ),
        ],
        if (hasBio) ...[
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.softMist.withValues(alpha: 0.9),
                height: 1.65,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (isOwnProfile)
          SizedBox(
            width: 176,
            child: FilledButton(
              onPressed: onEditProfile,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.holyGold,
                foregroundColor: AppColors.midnightFaithDark,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                ),
                textStyle: AppTextStyles.button.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(context.l10n.creatorProfileEdit),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: profile.followedByMe
                ? OutlinedButton(
                    onPressed: isTogglingFollow ? null : onToggleFollow,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.holyGold.withValues(alpha: 0.78),
                      ),
                      foregroundColor: AppColors.holyGold,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.full,
                        ),
                      ),
                    ),
                    child: Text(context.l10n.creatorProfileUnfollow),
                  )
                : FilledButton(
                    onPressed: isTogglingFollow ? null : onToggleFollow,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.holyGold,
                      foregroundColor: AppColors.midnightFaithDark,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.full,
                        ),
                      ),
                    ),
                    child: Text(context.l10n.creatorProfileFollow),
                  ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.midnightFaith.withValues(alpha: 0.72),
            borderRadius: AppBorderRadius.card,
            border: Border.all(
              color: AppColors.holyGold.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  value: profile.followersCount,
                  label: context.l10n.creatorProfileFollowers,
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _ProfileStat(
                  value: profile.followingCount,
                  label: context.l10n.creatorProfileFollowing,
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _ProfileStat(
                  value: profile.publishedDevotionalsCount,
                  label: context.l10n.creatorProfilePublished,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: AppSizes.buttonHeight,
        height: AppSizes.buttonHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.midnightFaith.withValues(alpha: 0.6),
                border: Border.all(
                  color: AppColors.holyGold.withValues(alpha: 0.34),
                ),
              ),
              child: Icon(icon, color: AppColors.holyGold),
            ),
          ),
        ),
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
    final avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? CircleAvatar(
            radius: radius,
            backgroundImage: CachedNetworkImageProvider(imageUrl!),
          )
        : CircleAvatar(
            radius: radius,
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
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.holyGold.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: avatar,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final int value;
  final String label;

  String _formatCount(int amount) {
    if (amount >= 1000000) {
      final value = amount / 1000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}M';
    }
    if (amount >= 1000) {
      final value = amount / 1000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}k';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Text(
            _formatCount(value),
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.holyGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.softMist.withValues(alpha: 0.62),
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 72,
      color: AppColors.holyGold.withValues(alpha: 0.16),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.holyGold,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.holyGold.withValues(alpha: 0.16),
          ),
        ),
      ],
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

  String _tag() {
    if (devotional.primaryReferences.isNotEmpty) {
      return devotional.primaryReferences.first.book.toUpperCase();
    }
    if (devotional.verseReferences.isNotEmpty) {
      return devotional.verseReferences.first.book.toUpperCase();
    }
    return 'DEVOCIONAL';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = devotional.previewImageUrl ?? devotional.coverImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.9),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: AppBorderRadius.card,
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.lg),
              ),
              child: SizedBox(
                height: 172,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment(0, devotional.coverImageFocusY),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.holyGold.withValues(alpha: 0.16),
                              AppColors.morningLight.withValues(alpha: 0.2),
                              AppColors.midnightFaithDark,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.holyGold,
                            size: 34,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tag(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.holyGold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    devotional.previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.softMist.withValues(alpha: 0.82),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.devotionalOpenDetail,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.holyGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.holyGold,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.holyGold,
                foregroundColor: AppColors.midnightFaithDark,
              ),
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
        color: AppColors.inputBackground.withValues(alpha: 0.84),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.holyGold.withValues(alpha: 0.14)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.softMist.withValues(alpha: 0.88),
          height: 1.6,
        ),
      ),
    );
  }
}
