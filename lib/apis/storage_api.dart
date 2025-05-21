// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/core/providers.dart';

final storageAPIProvider = Provider((ref) {
  return StorageAPI(
    storage: ref.watch(appwriteStorageProvider),
  );
});

class StorageAPI {
  final Storage _storage;
  StorageAPI({required Storage storage}) : _storage = storage;

  Future<List<String>> uploadImage(List<File> files) async {
    List<String> imageLinks = [];
    for (final file in files) {
      final uploadedImage = await _storage.createFile(
        bucketId: AppwriteConstants.imagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path),
      );
      imageLinks.add(
        AppwriteConstants.imageUrl(uploadedImage.$id),
      );
    }
    return imageLinks;
  }

  Future<String> uploadVideo(File file) async {
    try {
      final uploadedVideo = await _storage.createFile(
        bucketId: AppwriteConstants.videosBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path),
        onProgress: (progress) {
          print('Video upload progress: $progress%');
        },
      );
      return AppwriteConstants.videoUrl(uploadedVideo.$id);
    } catch (e) {
      print('Error uploading video: $e');
      return '';
    }
  }
  
  Future<String> uploadAudio(File file) async {
    try {
      final uploadedAudio = await _storage.createFile(
        bucketId: AppwriteConstants.audiosBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path),
      );
      return AppwriteConstants.audioUrl(uploadedAudio.$id);
    } catch (e) {
      print('Error uploading audio: $e');
      return '';
    }
  }
}
