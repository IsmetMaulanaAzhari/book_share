import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  double _selectedRadius = 5.0; // Default 5 km

  final List<double> _radiusOptions = [2.0, 5.0, 10.0, 20.0];

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

    // Get current location
    await locationProvider.getCurrentLocation();
    
    // Load dummy books for testing (tanpa Firebase)
    bookProvider.addDummyBooks();

    // Update markers
    _updateMarkers();
  }

  void _updateMarkers() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    // Filter books by radius
    final booksInRadius = bookProvider.getBooksWithinRadius(
      locationProvider.latitude,
      locationProvider.longitude,
      _selectedRadius,
    );

    Set<Marker> markers = {};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(locationProvider.latitude, locationProvider.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
      ),
    );

    // Add book markers
    for (var book in booksInRadius) {
      markers.add(
        Marker(
          markerId: MarkerId(book.id),
          position: LatLng(book.latitude, book.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: book.title,
            snippet: book.author,
          ),
          onTap: () {
            _showBookBottomSheet(book);
          },
        ),
      );
    }

    // Update circle for radius
    _circles = {
      Circle(
        circleId: const CircleId('radius_circle'),
        center: LatLng(locationProvider.latitude, locationProvider.longitude),
        radius: _selectedRadius * 1000, // Convert km to meters
        fillColor: Colors.blue.withValues(alpha: 0.1),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    };

    setState(() {
      _markers = markers;
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
        height: MediaQuery.of(context).size.height * 0.45,
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
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.red,
                                  ),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Genres
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: book.genres.map((genre) => Chip(
                        label: Text(
                          genre,
                          style: const TextStyle(fontSize: 11),
                        ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.ownerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              book.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to book detail
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Detail'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // Start chat
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur chat akan datang!'),
                                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Buku di Sekitar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Consumer2<LocationProvider, BookProvider>(
        builder: (context, locationProvider, bookProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mendapatkan lokasi...'),
                ],
              ),
            );
          }

          if (locationProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    locationProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => locationProvider.getCurrentLocation(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final booksInRadius = bookProvider.getBooksWithinRadius(
            locationProvider.latitude,
            locationProvider.longitude,
            _selectedRadius,
          );

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(locationProvider.latitude, locationProvider.longitude),
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Radius Selector
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Radius Pencarian',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${booksInRadius.length} buku ditemukan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _radiusOptions.map((radius) {
                            final isSelected = _selectedRadius == radius;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedRadius = radius;
                                  });
                                  _updateMarkers();
                                },
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
                      ],
                    ),
                  ),
                ),
              ),

              // My Location Button
              Positioned(
                bottom: 100,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    await locationProvider.getCurrentLocation();
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(locationProvider.latitude, locationProvider.longitude),
                      ),
                    );
                    _updateMarkers();
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
                  height: 130,
                  child: booksInRadius.isEmpty
                      ? Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Tidak ada buku dalam radius ini',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: booksInRadius.length,
                          itemBuilder: (context, index) {
                            final book = booksInRadius[index];
                            final distance = bookProvider.getDistanceToBook(
                              locationProvider.latitude,
                              locationProvider.longitude,
                              book,
                            );
                            return _buildBookCard(book, distance);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookCard(BookModel book, double distance) {
    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(book.latitude, book.longitude)),
        );
        _showBookBottomSheet(book);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Book Cover
                Container(
                  width: 50,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    image: book.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(book.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: book.imageUrl.isEmpty
                      ? const Icon(Icons.book, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 10),
                // Book Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
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
          ),
        ),
      ),
    );
  }
}
