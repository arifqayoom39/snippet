enum TweetType {
  text('text'),
  image('image'),
  video('video'),
  gif('gif'),
  poll('poll'),
  audio('audio'),
  location('location'),
  thread('thread'),
  audioRoom('audioRoom');

  final String type;
  const TweetType(this.type);
}

extension ConvertTweet on String {
  TweetType toTweetTypeEnum() {
    switch (this) {
      case 'text':
        return TweetType.text;
      case 'image':
        return TweetType.image;
      case 'video':
        return TweetType.video;
      case 'gif':
        return TweetType.gif;
      case 'poll':
        return TweetType.poll;
      case 'audio':
        return TweetType.audio;
      case 'location':
        return TweetType.location;
      case 'thread':
        return TweetType.thread;
      case 'audioRoom':
        return TweetType.audioRoom;
      default:
        return TweetType.text;
    }
  }
}