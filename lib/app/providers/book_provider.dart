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
      
      // ===== BUKU DALAM RADIUS 2KM =====
      BookModel(
        id: '9',
        title: 'The Psychology of Money',
        author: 'Morgan Housel',
        description: 'Pelajaran tentang kekayaan, keserakahan, dan kebahagiaan.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Bisnis', 'Self-Help'],
        ownerId: 'user9',
        ownerName: 'Indra',
        latitude: -6.2100, // ~1.3km
        longitude: 106.8470,
        address: 'Gambir, Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '10',
        title: 'Negeri 5 Menara',
        author: 'Ahmad Fuadi',
        description: 'Kisah inspiratif tentang kehidupan di pesantren.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user10',
        ownerName: 'Joko',
        latitude: -6.2050, // ~0.8km
        longitude: 106.8420,
        address: 'Sawah Besar, Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '11',
        title: 'Start With Why',
        author: 'Simon Sinek',
        description: 'Mengapa beberapa pemimpin menginspirasi dan yang lain tidak.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Bisnis'],
        ownerId: 'user11',
        ownerName: 'Kartika',
        latitude: -6.2120, // ~1.5km
        longitude: 106.8500,
        address: 'Cikini, Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now(),
      ),
      
      // ===== BUKU DALAM RADIUS 5KM =====
      BookModel(
        id: '12',
        title: 'Thinking Fast and Slow',
        author: 'Daniel Kahneman',
        description: 'Dua sistem yang menggerakkan cara kita berpikir.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Self-Help'],
        ownerId: 'user12',
        ownerName: 'Lukman',
        latitude: -6.2400, // ~3.5km
        longitude: 106.8300,
        address: 'Palmerah, Jakarta Barat',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '13',
        title: 'Perahu Kertas',
        author: 'Dee Lestari',
        description: 'Novel tentang cinta dan mimpi seorang seniman.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user13',
        ownerName: 'Mega',
        latitude: -6.1700, // ~4.3km
        longitude: 106.8600,
        address: 'Kemayoran, Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '14',
        title: 'Zero to One',
        author: 'Peter Thiel',
        description: 'Catatan tentang startup dan cara membangun masa depan.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Bisnis', 'Teknologi'],
        ownerId: 'user14',
        ownerName: 'Nanda',
        latitude: -6.2500, // ~4.6km
        longitude: 106.8400,
        address: 'Kebayoran Lama, Jakarta Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '15',
        title: 'Pulang',
        author: 'Tere Liye',
        description: 'Novel tentang perjalanan pulang ke kampung halaman.',
        imageUrl: '',
        condition: 'Bekas',
        genres: ['Novel'],
        ownerId: 'user15',
        ownerName: 'Oscar',
        latitude: -6.1800, // ~3.2km
        longitude: 106.8200,
        address: 'Tanjung Priok, Jakarta Utara',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        updatedAt: DateTime.now(),
      ),
      
      // ===== BUKU DALAM RADIUS 10KM =====
      BookModel(
        id: '16',
        title: 'Homo Deus',
        author: 'Yuval Noah Harari',
        description: 'Sejarah singkat masa depan umat manusia.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Sejarah', 'Teknologi'],
        ownerId: 'user16',
        ownerName: 'Putri',
        latitude: -6.2800, // ~8km
        longitude: 106.8000,
        address: 'Cilandak, Jakarta Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 11)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '17',
        title: 'Ikigai',
        author: 'Hector Garcia',
        description: 'Rahasia hidup bahagia dan panjang umur dari Jepang.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Self-Help'],
        ownerId: 'user17',
        ownerName: 'Qori',
        latitude: -6.1400, // ~7.6km
        longitude: 106.8800,
        address: 'Kelapa Gading, Jakarta Utara',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '18',
        title: 'Deep Work',
        author: 'Cal Newport',
        description: 'Aturan untuk fokus dalam dunia yang terdistraksi.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Bisnis', 'Self-Help'],
        ownerId: 'user18',
        ownerName: 'Rani',
        latitude: -6.3000, // ~10km
        longitude: 106.8500,
        address: 'Pasar Minggu, Jakarta Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '19',
        title: 'Supernova: Ksatria, Puteri, dan Bintang Jatuh',
        author: 'Dee Lestari',
        description: 'Novel sains fiksi tentang cinta dan spiritualitas.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user19',
        ownerName: 'Satria',
        latitude: -6.1500, // ~6.5km
        longitude: 106.7800,
        address: 'Cengkareng, Jakarta Barat',
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '20',
        title: 'The Lean Startup',
        author: 'Eric Ries',
        description: 'Bagaimana entrepreneur menggunakan inovasi terus menerus.',
        imageUrl: '',
        condition: 'Bekas',
        genres: ['Bisnis', 'Teknologi'],
        ownerId: 'user20',
        ownerName: 'Tari',
        latitude: -6.2600, // ~5.7km
        longitude: 106.9000,
        address: 'Duren Sawit, Jakarta Timur',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      
      // ===== BUKU DALAM RADIUS 20KM =====
      BookModel(
        id: '21',
        title: 'Educated',
        author: 'Tara Westover',
        description: 'Memoar tentang kekuatan pendidikan dan transformasi diri.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Self-Help', 'Sejarah'],
        ownerId: 'user21',
        ownerName: 'Umar',
        latitude: -6.3500, // ~15.7km
        longitude: 106.8200,
        address: 'Jagakarsa, Jakarta Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 13)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '22',
        title: 'Ayat-Ayat Cinta',
        author: 'Habiburrahman El Shirazy',
        description: 'Novel islami tentang cinta dan keteguhan iman.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user22',
        ownerName: 'Vina',
        latitude: -6.0800, // ~14.3km
        longitude: 106.9000,
        address: 'Bekasi Barat',
        createdAt: DateTime.now().subtract(const Duration(days: 19)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '23',
        title: 'The Art of War',
        author: 'Sun Tzu',
        description: 'Strategi militer kuno yang relevan untuk bisnis modern.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Bisnis', 'Sejarah'],
        ownerId: 'user23',
        ownerName: 'Wawan',
        latitude: -6.1200, // ~9.9km
        longitude: 106.7300,
        address: 'Tangerang Kota',
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '24',
        title: 'Flutter in Action',
        author: 'Eric Windmill',
        description: 'Panduan lengkap membangun aplikasi mobile dengan Flutter.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Teknologi'],
        ownerId: 'user24',
        ownerName: 'Xander',
        latitude: -6.2200, // ~12.8km
        longitude: 106.9600,
        address: 'Bekasi Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '25',
        title: 'Ronggeng Dukuh Paruk',
        author: 'Ahmad Tohari',
        description: 'Novel tentang kehidupan penari ronggeng di pedesaan Jawa.',
        imageUrl: '',
        condition: 'Bekas',
        genres: ['Novel', 'Sejarah'],
        ownerId: 'user25',
        ownerName: 'Yanti',
        latitude: -6.3800, // ~19km
        longitude: 106.8700,
        address: 'Depok',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '26',
        title: 'Grit',
        author: 'Angela Duckworth',
        description: 'Kekuatan passion dan ketekunan untuk mencapai tujuan.',
        imageUrl: '',
        condition: 'Bagus',
        genres: ['Self-Help'],
        ownerId: 'user26',
        ownerName: 'Zaki',
        latitude: -6.0500, // ~17.6km
        longitude: 106.8800,
        address: 'Bekasi Utara',
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '27',
        title: 'Seribu Kunang-Kunang di Manhattan',
        author: 'Umar Kayam',
        description: 'Kumpulan cerpen tentang pengalaman di New York.',
        imageUrl: '',
        condition: 'Cukup',
        genres: ['Novel', 'Fiksi'],
        ownerId: 'user27',
        ownerName: 'Aldi',
        latitude: -6.3200, // ~12.4km
        longitude: 106.7500,
        address: 'Tangerang Selatan',
        createdAt: DateTime.now().subtract(const Duration(days: 17)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: '28',
        title: 'Outliers',
        author: 'Malcolm Gladwell',
        description: 'Kisah sukses: mengapa beberapa orang berhasil dan yang lain tidak.',
        imageUrl: '',
        condition: 'Baru',
        genres: ['Bisnis', 'Self-Help'],
        ownerId: 'user28',
        ownerName: 'Bella',
        latitude: -6.1000, // ~12.1km
        longitude: 106.7600,
        address: 'Tangerang',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
    _filteredBooks = _allBooks;
    notifyListeners();
  }
}
