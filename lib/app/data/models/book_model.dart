import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String condition; // 'Baru', 'Bagus', 'Cukup', 'Bekas'
  final List<String> genres;
  final String ownerId;
  final String ownerName;
  final double latitude;
  final double longitude;
  final String address;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.imageUrl = '',
    required this.condition,
    required this.genres,
    required this.ownerId,
    required this.ownerName,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      condition: data['condition'] ?? 'Bagus',
      genres: List<String>.from(data['genres'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'imageUrl': imageUrl,
      'condition': condition,
      'genres': genres,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    String? condition,
    List<String>? genres,
    String? ownerId,
    String? ownerName,
    double? latitude,
    double? longitude,
    String? address,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      condition: condition ?? this.condition,
      genres: genres ?? this.genres,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
