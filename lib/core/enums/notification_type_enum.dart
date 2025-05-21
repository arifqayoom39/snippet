enum NotificationType {
  like('like'),
  reply('reply'),
  follow('follow'),
  retweet('retweet'),
  quoteRetweet('quoteRetweet'); // Add this new type

  final String type;
  const NotificationType(this.type);
}

extension Converttweet on String {
  NotificationType toNotificationTypeEnum() {
    switch (this) {
      case 'retweet':
        return NotificationType.retweet;
      case 'follow':
        return NotificationType.follow;
      case 'reply':
        return NotificationType.reply;
      case 'quoteRetweet': // Add this case
        return NotificationType.quoteRetweet;
      default:
        return NotificationType.like;
    }
  }
}
