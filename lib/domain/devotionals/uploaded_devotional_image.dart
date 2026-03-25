class UploadedDevotionalImage {
  const UploadedDevotionalImage({
    required this.assetId,
    required this.imageModerationStatus,
    required this.attachable,
    required this.previewImageUrl,
    required this.width,
    required this.height,
  });

  final String assetId;
  final String imageModerationStatus;
  final bool attachable;
  final String? previewImageUrl;
  final int? width;
  final int? height;

  factory UploadedDevotionalImage.fromMap(Map<String, dynamic> map) {
    return UploadedDevotionalImage(
      assetId: map['asset_id']?.toString() ?? '',
      imageModerationStatus:
          map['image_moderation_status']?.toString() ?? 'PENDING',
      attachable: map['attachable'] == true,
      previewImageUrl: map['preview_image_url']?.toString(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
    );
  }
}
