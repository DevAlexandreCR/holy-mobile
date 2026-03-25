class UploadedCreatorAvatar {
  const UploadedCreatorAvatar({
    required this.assetId,
    required this.imageModerationStatus,
    required this.attachable,
    required this.previewImageUrl,
    required this.width,
    required this.height,
    required this.moderationReason,
  });

  final String assetId;
  final String imageModerationStatus;
  final bool attachable;
  final String? previewImageUrl;
  final int? width;
  final int? height;
  final String? moderationReason;

  factory UploadedCreatorAvatar.fromMap(Map<String, dynamic> map) {
    return UploadedCreatorAvatar(
      assetId: map['asset_id']?.toString() ?? '',
      imageModerationStatus:
          map['image_moderation_status']?.toString() ?? 'PENDING',
      attachable: map['attachable'] == true,
      previewImageUrl: map['preview_image_url']?.toString(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      moderationReason: map['moderation_reason']?.toString(),
    );
  }
}
