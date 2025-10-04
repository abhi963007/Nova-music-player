import 'package:equatable/equatable.dart';
import 'song_model.dart';

class PlaylistModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final int songCount;
  final List<SongModel> songs;

  const PlaylistModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.songCount,
    required this.songs,
  });

  PlaylistModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnail,
    int? songCount,
    List<SongModel>? songs,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      songCount: songCount ?? this.songCount,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'songCount': songCount,
      'songs': songs.map((song) => song.toJson()).toList(),
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnail: json['thumbnail'] as String,
      songCount: json['songCount'] as int,
      songs: (json['songs'] as List<dynamic>?)
              ?.map((song) => SongModel.fromJson(song as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, title, description, thumbnail, songCount, songs];
}
