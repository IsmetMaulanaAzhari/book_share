import 'dart:math';
import 'package:flutter/material.dart';
// Firebase dinonaktifkan sementara untuk testing
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/book_model.dart';

class BookProvider extends ChangeNotifier {
  // Firebase dinonaktifkan sementara
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<BookModel> _allBooks = [];
  List<BookModel> _filteredBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _selectedRadius = 5.0; // Default 5 km

  List<BookModel> get allBooks => _allBooks;
  List<BookModel> get filteredBooks => _filteredBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get selectedRadius => _selectedRadius;

  // Fetch all books - sementara pakai dummy data
  Future<void> fetchBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sementara gunakan dummy books, Firebase bisa diaktifkan nanti
      addDummyBooks();
      _filteredBooks = _allBooks;
    } catch (e) {
      _errorMessage = 'Failed to fetch books: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Stream books - placeholder (aktivkan Firebase nanti)
  Stream<List<BookModel>> streamBooks() {
    // Placeholder stream dengan dummy data
    return Stream.value(_allBooks);
  }

  // Set radius filter
  void setSelectedRadius(double radius) {
    _selectedRadius = radius;
    notifyListeners();
  }

  // Filter books by radius menggunakan Haversine formula
  void filterBooksByRadius(double userLat, double userLng, double radiusKm) {
    _selectedRadius = radiusKm;
    _filteredBooks = _allBooks.where((book) {
      double distance = _calculateHaversineDistance(
        userLat, userLng,
        book.latitude, book.longitude,
      );
      return distance <= radiusKm;
    }).toList();
    notifyListeners();
  }

  // Get books within radius
  List<BookModel> getBooksWithinRadius(double userLat, double userLng, double radiusKm) {
    return _allBooks.where((book) {
      double distance = _calculateHaversineDistance(
        userLat, userLng,
        book.latitude, book.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Haversine formula untuk menghitung jarak
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius bumi dalam km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Get distance dari user ke buku tertentu
  double getDistanceToBook(double userLat, double userLng, BookModel book) {
    return _calculateHaversineDistance(userLat, userLng, book.latitude, book.longitude);
  }

  // Add new book (simpan ke list lokal)
  Future<void> addBook(BookModel book) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allBooks.add(book);
      _filteredBooks = _allBooks;
    } catch (e) {
      _errorMessage = 'Failed to add book: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update book (update dari list lokal)
  Future<void> updateBook(BookModel book) async {
    try {
      final index = _allBooks.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _allBooks[index] = book;
        _filteredBooks = _allBooks;
      }
    } catch (e) {
      _errorMessage = 'Failed to update book: $e';
    }
    notifyListeners();
  }

  // Delete book (hapus dari list lokal)
  Future<void> deleteBook(String bookId) async {
    try {
      _allBooks.removeWhere((b) => b.id == bookId);
      _filteredBooks = _allBooks;
    } catch (e) {
      _errorMessage = 'Failed to delete book: $e';
    }
    notifyListeners();
  }

  // Search books
  void searchBooks(String query) {
    if (query.isEmpty) {
      _filteredBooks = _allBooks;
    } else {
      _filteredBooks = _allBooks.where((book) {
        return book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase()) ||
            book.genres.any((genre) => genre.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }
    notifyListeners();
  }

  // Filter by genre
  void filterByGenre(String genre) {
    if (genre == 'Semua') {
      _filteredBooks = _allBooks;
    } else {
      _filteredBooks = _allBooks.where((book) => book.genres.contains(genre)).toList();
    }
    notifyListeners();
  }

  // Add dummy books for testing (without Firebase)
  void addDummyBooks() {
    if (_allBooks.isNotEmpty) return; // Prevent duplicate additions
    
    _allBooks = [
      BookModel(
        id: '1',
        title: 'Laskar Pelangi',
        author: 'Andrea Hirata',
        description: 'Novel tentang perjuangan anak-anak di Belitung untuk mendapatkan pendidikan.',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/id/8/8e/Laskar_pelangi_sampul.jpg',
        condition: 'Bagus',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user1',
        ownerName: 'Ahmad',
        latitude: -6.2088,
        longitude: 106.8456,
        address: 'Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '2',
        title: 'Bumi Manusia',
        author: 'Pramoedya Ananta Toer',
        description: 'Novel sejarah tentang kehidupan di era kolonial.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Novel', 'Sejarah'],
        ownerId: 'user2',
        ownerName: 'Budi',
        latitude: -6.2000,
        longitude: 106.8400,
        address: 'Jakarta Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '3',
        title: 'Atomic Habits',
        author: 'James Clear',
        description: 'Cara mudah membangun kebiasaan baik.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Self-Help'],
        ownerId: 'user3',
        ownerName: 'Citra',
        latitude: -6.1850,
        longitude: 106.8500,
        address: 'Jakarta Utara',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '4',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        description: 'Panduan menulis kode yang bersih dan mudah dipelihara.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Teknologi'],
        ownerId: 'user4',
        ownerName: 'Deni',
        latitude: -6.2300,
        longitude: 106.8200,
        address: 'Jakarta Barat',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '5',
        title: 'Filosofi Teras',
        author: 'Henry Manampiring',
        description: 'Filsafat Yunani-Romawi untuk mental tangguh.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Self-Help'],
        ownerId: 'user5',
        ownerName: 'Eka',
        latitude: -6.2500,
        longitude: 106.8600,
        address: 'Jakarta Timur',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '6',
        title: 'Rich Dad Poor Dad',
        author: 'Robert Kiyosaki',
        description: 'Pelajaran keuangan dari dua perspektif ayah yang berbeda.',
        imageUrl: '',
        condition: 'Bekas',
        genres: ['Bisnis'],
        ownerId: 'user6',
        ownerName: 'Fani',
        latitude: -6.1950,
        longitude: 106.8550,
        address: 'Menteng, Jakarta',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '7',
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        description: 'Sejarah singkat umat manusia dari zaman purba hingga modern.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Sejarah'],
        ownerId: 'user7',
        ownerName: 'Gilang',
        latitude: -6.2150,
        longitude: 106.8300,
        address: 'Tanah Abang, Jakarta',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '8',
        title: 'Dilan 1990',
        author: 'Pidi Baiq',
        description: 'Novel romantis tentang kisah cinta remaja di Bandung.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user8',
        ownerName: 'Hana',
        latitude: -6.2200,
        longitude: 106.8700,
        address: 'Jatinegara, Jakarta',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
    ];
    _filteredBooks = _allBooks;
    notifyListeners();
  }
}
