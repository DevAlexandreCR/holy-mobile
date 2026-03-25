import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holyverso/data/creator_profiles/creator_profiles_api_client.dart';
import 'package:holyverso/domain/core/cursor_paged_result.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile.dart';
import 'package:holyverso/domain/creator_profiles/creator_profile_update_result.dart';
import 'package:holyverso/domain/creator_profiles/uploaded_creator_avatar.dart';
import 'package:holyverso/domain/devotionals/devotional.dart';

class CreatorProfilesRepository {
  CreatorProfilesRepository(this._client);

  final CreatorProfilesApiClient _client;

  Future<CreatorProfile> getCreatorProfile(String id) {
    return _client.getCreatorProfile(id);
  }

  Future<CursorPagedResult<Devotional>> getCreatorDevotionals({
    required String id,
    String? cursor,
    int limit = 20,
  }) {
    return _client.getCreatorDevotionals(id: id, cursor: cursor, limit: limit);
  }

  Future<CreatorProfile> followCreator(String id) {
    return _client.followCreator(id);
  }

  Future<CreatorProfile> unfollowCreator(String id) {
    return _client.unfollowCreator(id);
  }

  Future<CreatorProfileUpdateResult> updateMyCreatorProfile({
    String? handle,
    String? bio,
    String? avatarAssetId,
    bool clearAvatar = false,
  }) {
    return _client.updateMyCreatorProfile(
      handle: handle,
      bio: bio,
      avatarAssetId: avatarAssetId,
      clearAvatar: clearAvatar,
    );
  }

  Future<UploadedCreatorAvatar> uploadAvatar(File file) {
    return _client.uploadAvatar(file);
  }
}

final creatorProfilesRepositoryProvider = Provider<CreatorProfilesRepository>((
  ref,
) {
  return CreatorProfilesRepository(ref.watch(creatorProfilesApiClientProvider));
});
