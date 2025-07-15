import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng location, String address) onLocationSelected;
  final String? initialAddress;

  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    this.initialAddress,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _selectedLocation = const LatLng(-23.5505, -46.6333); // São Paulo default
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _permissionDenied = false;
  
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
    
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
      _searchController.text = widget.initialAddress!;
    }
    
    _addMarker(_selectedLocation);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Localização Selecionada',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
          ),
        ),
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _permissionDenied = true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _permissionDenied = true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _permissionDenied = true);
        return;
      }

      setState(() => _isLoading = true);
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      // Se não há localização inicial definida, usa a localização atual
      if (widget.initialLocation == null) {
        _updateLocation(newLocation);
      }
      
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      setState(() => _permissionDenied = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);
        _updateLocation(newLocation);
        
        // Move o mapa para a nova localização
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 15.0),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Endereço não encontrado: $query'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });
    
    _addMarker(location);
    
    // Geocoding reverso para obter o endereço
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        
        setState(() {
          _selectedAddress = address;
          _searchController.text = address;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
        _searchController.text = _selectedAddress;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street?.isNotEmpty == true) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      addressParts.add(placemark.subLocality!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      addressParts.add(placemark.administrativeArea!);
    }
    
    return addressParts.join(', ');
  }

  void _onMapTap(LatLng location) {
    _updateLocation(location);
  }

  void _confirmSelection() {
    widget.onLocationSelected(_selectedLocation, _selectedAddress);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: const Text(
              'Confirmar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar endereço...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _isLoading 
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(LucideIcons.navigation),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Usar localização atual',
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchLocation,
            ),
          ),
          
          // Mapa
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  onTap: _onMapTap,
                  myLocationEnabled: !_permissionDenied,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                
                // Indicador de permissão negada
                if (_permissionDenied)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(32),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 48,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Permissão de Localização',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Para uma melhor experiência, permita o acesso à sua localização nas configurações do dispositivo.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  await Geolocator.openAppSettings();
                                },
                                child: const Text('Abrir Configurações'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Informações da localização selecionada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Localização Selecionada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress.isNotEmpty 
                          ? _selectedAddress 
                          : 'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _confirmSelection,
                  icon: const Icon(LucideIcons.check),
                  label: const Text('Confirmar Localização'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
 