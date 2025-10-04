import 'package:equatable/equatable.dart';
import 'song_model.dart';

class AlbumModel extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final String year;
  final List<SongModel> songs;

  const AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.year,
    required this.songs,
  });

  AlbumModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnail,
    String? year,
    List<SongModel>? songs,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnail: thumbnail ?? this.thumbnail,
      year: year ?? this.year,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnail': thumbnail,
      'year': year,
      'songs': songs.map((song) => song.toJson()).toList(),
    };
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnail: json['thumbnail'] as String,
      year: json['year'] as String,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((song) => SongModel.fromJson(song as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, title, artist, thumbnail, year, songs];
}
