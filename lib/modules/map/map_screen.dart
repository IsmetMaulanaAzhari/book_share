import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/providers/location_provider.dart';
import '../../app/providers/book_provider.dart';
import '../../app/data/models/book_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  double _selectedRadius = 5.0; // Default 5 km
  bool _isInitialized = false;
  bool _showMap = true;
  bool _showFilters = false;
  
  // Smart Search State
  String _searchQuery = '';
  String _selectedGenre = 'Semua';
  String _selectedCondition = 'Semua';
  String _sortBy = 'distance'; // distance, title, newest

  final List<double> _radiusOptions = [2.0, 5.0, 10.0, 20.0];
  final List<String> _genres = ['Semua', 'Novel', 'Fiksi', 'Bisnis', 'Self-Help', 'Teknologi', 'Sejarah'];
  final List<String> _conditions = ['Semua', 'Baru', 'Bagus', 'Cukup', 'Bekas'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);

    // Load dummy books for testing
    bookProvider.addDummyBooks();

    // Get current location
    try {
      await locationProvider.getCurrentLocation();
    } catch (e) {
      debugPrint('Location error: $e');
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _showBookBottomSheet(BookModel book) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final distance = bookProvider.getDistanceToBook(
      locationProvider.latitude,
      locationProvider.longitude,
      book,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Image and Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover
                        Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: book.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(book.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: book.imageUrl.isEmpty
                              ? const Icon(Icons.book, size: 40, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Book Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'oleh ${book.author}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Condition Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getConditionColor(book.condition),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  book.condition,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Distance
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distance.toStringAsFixed(1)} km dari Anda',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    const Text(
                      'Deskripsi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    // Genres
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: book.genres.map((genre) => Chip(
                        label: Text(genre, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Owner Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            book.ownerName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.ownerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              book.address,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Detail'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur chat akan datang!')),
                              );
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Hubungi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Baru':
        return Colors.green;
      case 'Bagus':
        return Colors.blue;
      case 'Cukup':
        return Colors.orange;
      case 'Bekas':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Smart Search: Filter dan sort buku
  List<BookModel> _applySmartSearch(List<BookModel> books, BookProvider bookProvider, LocationProvider locationProvider) {
    var filtered = books;

    // 1. Filter by search query (title, author, genre)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               book.genres.any((g) => g.toLowerCase().contains(query));
      }).toList();
    }

    // 2. Filter by genre
    if (_selectedGenre != 'Semua') {
      filtered = filtered.where((book) => book.genres.contains(_selectedGenre)).toList();
    }

    // 3. Filter by condition
    if (_selectedCondition != 'Semua') {
      filtered = filtered.where((book) => book.condition == _selectedCondition).toList();
    }

    // 4. Sort results
    switch (_sortBy) {
      case 'distance':
        filtered.sort((a, b) {
          final distA = bookProvider.getDistanceToBook(locationProvider.latitude, locationProvider.longitude, a);
          final distB = bookProvider.getDistanceToBook(locationProvider.latitude, locationProvider.longitude, b);
          return distA.compareTo(distB);
        });
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Buku di Sekitar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'Tampilan List' : 'Tampilan Peta',
          ),
        ],
      ),
      body: Consumer2<LocationProvider, BookProvider>(
        builder: (context, locationProvider, bookProvider, child) {
          if (!_isInitialized && locationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data buku...'),
                ],
              ),
            );
          }

          final booksInRadius = bookProvider.getBooksWithinRadius(
            locationProvider.latitude,
            locationProvider.longitude,
            _selectedRadius,
          );

          // Apply smart search filters
          final filteredBooks = _applySmartSearch(booksInRadius, bookProvider, locationProvider);

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              
              // Filter Panel (collapsible)
              if (_showFilters) _buildFilterPanel(),
              
              // Radius Selector Card
              _buildRadiusSelector(filteredBooks.length, booksInRadius.length, locationProvider),
              const Divider(height: 1),
              
              // Main content
              Expanded(
                child: _showMap
                    ? _buildMapView(locationProvider, bookProvider, filteredBooks)
                    : _buildListView(locationProvider, bookProvider, filteredBooks),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadiusSelector(int filteredCount, int totalCount, LocationProvider locationProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '$filteredCount dari $totalCount buku',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _radiusOptions.map((radius) {
              final isSelected = _selectedRadius == radius;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRadius = radius),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${radius.toInt()} km',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (locationProvider.currentAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationProvider.currentAddress,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari judul, penulis, atau genre...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort By
          Row(
            children: [
              const Icon(Icons.sort, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Urutkan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('distance', 'Terdekat', Icons.near_me),
                      _buildSortChip('title', 'Judul A-Z', Icons.sort_by_alpha),
                      _buildSortChip('newest', 'Terbaru', Icons.access_time),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Genre Filter
          Row(
            children: [
              const Icon(Icons.category, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Genre:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _genres.map((genre) => _buildGenreChip(genre)).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Condition Filter
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Kondisi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _conditions.map((cond) => _buildConditionChip(cond)).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          // Reset Button
          if (_searchQuery.isNotEmpty || _selectedGenre != 'Semua' || _selectedCondition != 'Semua')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedGenre = 'Semua';
                    _selectedCondition = 'Semua';
                    _sortBy = 'distance';
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Filter'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey[700])),
          ],
        ),
        onSelected: (_) => setState(() => _sortBy = value),
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = _selectedGenre == genre;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(genre, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey[700])),
        onSelected: (_) => setState(() => _selectedGenre = genre),
        selectedColor: Colors.green,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    final isSelected = _selectedCondition == condition;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(condition, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey[700])),
        onSelected: (_) => setState(() => _selectedCondition = condition),
        selectedColor: _getConditionColor(condition),
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }

  Widget _buildMapView(LocationProvider locationProvider, BookProvider bookProvider, List<BookModel> booksInRadius) {
    final userLocation = LatLng(locationProvider.latitude, locationProvider.longitude);

    return Stack(
      children: [
        // OpenStreetMap (GRATIS!)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 13,
          ),
          children: [
            // Map tiles from OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.book_share',
            ),
            
            // Radius circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userLocation,
                  radius: _selectedRadius * 1000, // Convert km to meters
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.1),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            
            // Markers
            MarkerLayer(
              markers: [
                // User location marker
                Marker(
                  point: userLocation,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
                // Book markers
                ...booksInRadius.map((book) => Marker(
                  point: LatLng(book.latitude, book.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showBookBottomSheet(book),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.book, color: Colors.white, size: 18),
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),

        // My Location Button
        Positioned(
          bottom: 140,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'my_location',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () async {
              await locationProvider.getCurrentLocation();
              _mapController.move(
                LatLng(locationProvider.latitude, locationProvider.longitude),
                13,
              );
            },
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),

        // Book List Preview
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 120,
            child: booksInRadius.isEmpty
                ? Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Text('Tidak ada buku dalam radius ini', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: booksInRadius.length,
                    itemBuilder: (context, index) {
                      final book = booksInRadius[index];
                      final distance = bookProvider.getDistanceToBook(
                        locationProvider.latitude, locationProvider.longitude, book);
                      return _buildBookCard(book, distance);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(LocationProvider locationProvider, BookProvider bookProvider, List<BookModel> booksInRadius) {
    if (booksInRadius.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada buku dalam radius ${_selectedRadius.toInt()} km',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: booksInRadius.length,
      itemBuilder: (context, index) {
        final book = booksInRadius[index];
        final distance = bookProvider.getDistanceToBook(
          locationProvider.latitude, locationProvider.longitude, book);
        return _buildBookListTile(book, distance);
      },
    );
  }

  Widget _buildBookCard(BookModel book, double distance) {
    return GestureDetector(
      onTap: () {
        _mapController.move(LatLng(book.latitude, book.longitude), 15);
        _showBookBottomSheet(book);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    image: book.imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(book.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: book.imageUrl.isEmpty ? const Icon(Icons.book, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.red[400]),
                          const SizedBox(width: 2),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookListTile(BookModel book, double distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookBottomSheet(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: book.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(book.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: book.imageUrl.isEmpty ? const Icon(Icons.book, size: 30, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(book.author, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConditionColor(book.condition),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(book.condition, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, size: 14, color: Colors.red[400]),
                        Text(' ${distance.toStringAsFixed(1)} km', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue[100],
                          child: Text(book.ownerName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                        ),
                        const SizedBox(width: 6),
                        Text(book.ownerName, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
