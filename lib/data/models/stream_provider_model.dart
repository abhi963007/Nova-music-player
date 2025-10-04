import 'package:equatable/equatable.dart';

class StreamProviderModel extends Equatable {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnail;
  final Duration duration;
  final List<AudioStreamInfo> audioStreams;

  const StreamProviderModel({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.duration,
    required this.audioStreams,
  });

  @override
  List<Object?> get props => [videoId, title, artist, thumbnail, duration, audioStreams];
}

class AudioStreamInfo extends Equatable {
  final String url;
  final int bitrate;
  final String codec;
  final int size;

  const AudioStreamInfo({
    required this.url,
    required this.bitrate,
    required this.codec,
    required this.size,
  });

  @override
  List<Object?> get props => [url, bitrate, codec, size];
}
