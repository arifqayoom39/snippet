class AppwriteConstants {
  static const String databaseId = '------';
  static const String projectId = '------';
  static const String endPoint = 'https://cloud.appwrite.io/v1';

  static const String usersCollection = '------';
  static const String tweetsCollection = '------';
  static const String notificationsCollection = '------';
  static const String bookmarksCollection = '------';

  static const String imagesBucket = '------';
  static const String videosBucket = '------';
  static const String audiosBucket = '------';

  static String imageUrl(String imageId) =>
      '$endPoint/storage/buckets/$imagesBucket/files/$imageId/view?project=$projectId';
  
  static String videoUrl(String videoId) =>
      '$endPoint/storage/buckets/$videosBucket/files/$videoId/view?project=$projectId';
  
  static String audioUrl(String audioId) =>
      '$endPoint/storage/buckets/$audiosBucket/files/$audioId/view?project=$projectId';
}
