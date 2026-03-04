import 'dart:io';
import 'package:outcall/core/utils/app_logger.dart';

/// Service for managing user profile avatars.
///
/// Handles image picking, upload to Firebase Storage,
/// and URL retrieval for display.
class AvatarService {
  AvatarService._();

  /// Upload a profile picture and return its download URL.
  /// 
  /// Usage:
  /// ```dart
  /// final picker = ImagePicker();
  /// final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
  /// if (image != null) {
  ///   final url = await AvatarService.uploadAvatar(userId, File(image.path));
  ///   await profileRepo.updateProfile(userId, avatarUrl: url);
  /// }
  /// ```
  static Future<String?> uploadAvatar(String userId, File imageFile) async {
    try {
      // TODO: Wire to Firebase Storage when ready:
      // final ref = FirebaseStorage.instance
      //     .ref()
      //     .child('avatars')
      //     .child('$userId.jpg');
      // await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      // return await ref.getDownloadURL();

      AppLogger.d('AvatarService: Upload requested for $userId (pending Firebase Storage setup)');
      return null;
    } catch (e) {
      AppLogger.d('AvatarService: Upload failed: $e');
      return null;
    }
  }

  /// Delete the user's avatar from storage.
  static Future<void> deleteAvatar(String userId) async {
    try {
      // TODO: Wire to Firebase Storage
      // await FirebaseStorage.instance.ref().child('avatars/$userId.jpg').delete();
      AppLogger.d('AvatarService: Delete requested for $userId');
    } catch (e) {
      AppLogger.d('AvatarService: Delete failed: $e');
    }
  }

  /// Generate a default avatar URL from initials (Gravatar-style).
  static String defaultAvatarUrl(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return 'https://ui-avatars.com/api/?name=$initials&background=1B5E20&color=fff&size=128&bold=true';
  }
}
