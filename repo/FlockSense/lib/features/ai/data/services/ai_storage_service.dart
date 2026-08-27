import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/ai/data/models/ai_attachment_model.dart';
import 'package:path_provider/path_provider.dart';

class AiStorageService {
  AiStorageService._();

  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<AiAttachmentModel> uploadFile({
    required File file,
    required String conversationId,
    required AiAttachmentType type,
  }) async {
    final user = _auth.currentUser;
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSizeKb = (await file.length()) / 1024.0;
    final fileId = 'att_${DateTime.now().millisecondsSinceEpoch}';

    String downloadUrl = '';

    if (user != null) {
      try {
        final storagePath =
            'users/${user.uid}/ai_uploads/$conversationId/$fileId-$fileName';
        final ref = _storage.ref().child(storagePath);

        final uploadTask = await ref.putFile(
          file,
          SettableMetadata(
            contentType: _getMimeType(fileName),
            customMetadata: {
              'conversationId': conversationId,
              'uploadedAt': DateTime.now().toIso8601String(),
              'ownerUid': user.uid,
            },
          ),
        );

        downloadUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('[AiStorageService] Storage upload fallback: $e');
      }
    }

    // Local copy if storage fails or offline
    if (downloadUrl.isEmpty) {
      final appDir = await getTemporaryDirectory();
      final localSavedFile = await file.copy(
        '${appDir.path}/$fileId-$fileName',
      );
      downloadUrl = 'file://${localSavedFile.path}';
    }

    return AiAttachmentModel(
      id: fileId,
      fileName: fileName,
      fileSizeKb: fileSizeKb,
      fileType: type,
      downloadUrl: downloadUrl,
      localPath: file.path,
      mimeType: _getMimeType(fileName),
    );
  }

  static String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
