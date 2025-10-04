import 'package:equatable/equatable.dart';

class SongModel extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final String duration;
  final String? album;
  final String? albumId;
  final String? year;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.duration,
    this.album,
    this.albumId,
    this.year,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnail,
    String? duration,
    String? album,
    String? albumId,
    String? year,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnail': thumbnail,
      'duration': duration,
      'album': album,
      'albumId': albumId,
      'year': year,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnail: json['thumbnail'] as String,
      duration: json['duration'] as String,
      album: json['album'] as String?,
      albumId: json['albumId'] as String?,
      year: json['year'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, artist, thumbnail, duration, album, albumId, year];
}
