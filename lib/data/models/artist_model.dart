import 'package:equatable/equatable.dart';

class ArtistModel extends Equatable {
  final String id;
  final String name;
  final String thumbnail;
  final String subscribers;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.subscribers,
  });

  ArtistModel copyWith({
    String? id,
    String? name,
    String? thumbnail,
    String? subscribers,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnail: thumbnail ?? this.thumbnail,
      subscribers: subscribers ?? this.subscribers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail': thumbnail,
      'subscribers': subscribers,
    };
  }

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String,
      subscribers: json['subscribers'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name, thumbnail, subscribers];
}
