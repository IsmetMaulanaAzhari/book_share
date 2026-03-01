import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../app/providers/location_provider.dart';
import '../../app/data/models/chat_model.dart';

class CODPointPicker extends StatefulWidget {
  final String chatRoomId;

  const CODPointPicker({super.key, required this.chatRoomId});

  @override
  State<CODPointPicker> createState() => _CODPointPickerState();
}

class _CODPointPickerState extends State<CODPointPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  LatLng? _selectedLocation;
  DateTime? _meetingTime;
  bool _isLoading = false;

  // Suggested COD locations near user
  final List<Map<String, dynamic>> _suggestedLocations = [
    {
      'name': 'Indomaret Tebet Timur',
      'address': 'Jl. Tebet Timur Raya No. 45, Jakarta',
      'lat': -6.2315,
      'lng': 106.8562,
    },
    {
      'name': 'Alfamart Pancoran',
      'address': 'Jl. Pancoran Barat II No. 12, Jakarta',
      'lat': -6.2445,
      'lng': 106.8432,
    },
    {
      'name': 'KFC Tebet',
      'address': 'Jl. Tebet Raya No. 78, Jakarta',
      'lat': -6.2289,
      'lng': 106.8523,
    },
    {
      'name': 'McDonalds Cikoko',
      'address': 'Jl. MT Haryono Kav. 5, Jakarta',
      'lat': -6.2401,
      'lng': 106.8678,
    },
    {
      'name': 'Stasiun Cawang',
      'address': 'Jl. Mayjen Sutoyo, Cawang, Jakarta',
      'lat': -6.2535,
      'lng': 106.8712,
    },
    {
      'name': 'Halte TransJakarta Tebet',
      'address': 'Jl. Prof. Dr. Supomo, Tebet, Jakarta',
      'lat': -6.2267,
      'lng': 106.8556,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _selectSuggestedLocation(Map<String, dynamic> location) {
    final latLng = LatLng(location['lat'], location['lng']);
    setState(() {
      _selectedLocation = latLng;
      _nameController.text = location['name'];
    });
    _mapController.move(latLng, 16);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (time != null) {
        setState(() {
          _meetingTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _confirmCODPoint() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lokasi terlebih dahulu')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama tempat')),
      );
      return;
    }

    final codPoint = CODPoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      address: _getAddressFromLocation(_selectedLocation!),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      meetingTime: _meetingTime,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      proposedBy: 'current_user', // Will be set properly by ChatProvider
      status: CODStatus.proposed,
    );

    Navigator.pop(context, codPoint);
  }

  String _getAddressFromLocation(LatLng location) {
    // Check if it matches a suggested location
    for (final suggested in _suggestedLocations) {
      if ((suggested['lat'] - location.latitude).abs() < 0.001 &&
          (suggested['lng'] - location.longitude).abs() < 0.001) {
        return suggested['address'];
      }
    }
    // Return coordinates as address for custom locations
    return 'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userLocation = locationProvider.currentLocation;
    final initialCenter = userLocation != null
        ? LatLng(userLocation.latitude, userLocation.longitude)
        : const LatLng(-6.2297, 106.8295); // Default to Central Jakarta

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik COD'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null ? _confirmCODPoint : null,
            child: Text(
              'Konfirmasi',
              style: TextStyle(
                color: _selectedLocation != null ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 14,
                    onTap: (tapPosition, latLng) => _selectLocation(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.book_share',
                    ),
                    // User location marker
                    if (userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(userLocation.latitude, userLocation.longitude),
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.person, color: Colors.blue, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Selected location marker
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    // Suggested locations markers
                    MarkerLayer(
                      markers: _suggestedLocations.map((loc) {
                        final isSelected = _selectedLocation != null &&
                            (_selectedLocation!.latitude - loc['lat']).abs() < 0.001 &&
                            (_selectedLocation!.longitude - loc['lng']).abs() < 0.001;
                        return Marker(
                          point: LatLng(loc['lat'], loc['lng']),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _selectSuggestedLocation(loc),
                            child: Icon(
                              Icons.store,
                              color: isSelected ? Colors.red : Colors.green,
                              size: 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Help text
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ketuk peta untuk memilih lokasi atau pilih tempat yang disarankan',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggested locations
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey[100],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _suggestedLocations.length,
              itemBuilder: (context, index) {
                final loc = _suggestedLocations[index];
                final isSelected = _selectedLocation != null &&
                    (_selectedLocation!.latitude - loc['lat']).abs() < 0.001 &&
                    (_selectedLocation!.longitude - loc['lng']).abs() < 0.001;
                return GestureDetector(
                  onTap: () => _selectSuggestedLocation(loc),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 14,
                              color: isSelected ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                loc['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.blue : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc['address'],
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected location info
                  if (_selectedLocation != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Name input
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Tempat *',
                      hintText: 'Contoh: Indomaret Tebet',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meeting time
                  InkWell(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _meetingTime != null
                                  ? _formatDateTime(_meetingTime!)
                                  : 'Pilih Waktu Ketemuan (Opsional)',
                              style: TextStyle(
                                color: _meetingTime != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note input
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      hintText: 'Contoh: Di depan kasir atau di parkiran motor',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.note),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedLocation != null ? _confirmCODPoint : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Konfirmasi Titik COD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${days[dateTime.weekday % 7]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
