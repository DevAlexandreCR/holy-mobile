import 'package:holyverso/domain/creator_profiles/creator_profile.dart';

class CreatorProfileUpdateResult {
  const CreatorProfileUpdateResult({
    required this.profile,
    this.avatarAttachmentErrorCode,
    this.avatarAttachmentErrorMessage,
  });

  final CreatorProfile profile;
  final String? avatarAttachmentErrorCode;
  final String? avatarAttachmentErrorMessage;

  factory CreatorProfileUpdateResult.fromMap(Map<String, dynamic> map) {
    final error = map['avatar_attachment_error'] as Map?;
    return CreatorProfileUpdateResult(
      profile: CreatorProfile.fromMap(map),
      avatarAttachmentErrorCode: error?['code']?.toString(),
      avatarAttachmentErrorMessage: error?['message']?.toString(),
    );
  }
}
