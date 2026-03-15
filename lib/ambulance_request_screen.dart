import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/api_service.dart';

class AmbulanceRequestScreen extends StatefulWidget {
  const AmbulanceRequestScreen({super.key});

  @override
  State<AmbulanceRequestScreen> createState() => _AmbulanceRequestScreenState();
}

class _AmbulanceRequestScreenState extends State<AmbulanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientAgeController = TextEditingController();
  final _hospitalDestinationController = TextEditingController();
  final _contactNumberController = TextEditingController();
  
  String? _selectedPatientCondition;
  String? _currentLocation;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  final List<String> _patientConditions = [
    'Critical',
    'Serious',
    'Stable',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _patientAgeController.dispose();
    _hospitalDestinationController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services disabled';
          _isLocationLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission permanently denied';
          _isLocationLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentLocation = 'Unable to get location';
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select patient condition')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please wait for location to be detected')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to submit ambulance request
      final result = await ApiService.submitAmbulanceRequest(
        patientCondition: _selectedPatientCondition!,
        patientAge: int.parse(_patientAgeController.text.trim()),
        pickupLatitude: _latitude!,
        pickupLongitude: _longitude!,
        hospitalDestination: _hospitalDestinationController.text.trim().isEmpty 
            ? null 
            : _hospitalDestinationController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Show success message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text('Ambulance Requested'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your ambulance request has been submitted successfully!'),
                  SizedBox(height: 10),
                  Text('System:'),
                  SizedBox(height: 5),
                  Text('• Finding nearest ambulance'),
                  Text('• Showing ETA on map'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to home screen
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('🚨'),
            SizedBox(width: 8),
            Text('Ambulance Request'),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                Text(
                  'Screen: Ambulance Request',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 24),

                // Patient Condition Dropdown
                Text(
                  'Patient Condition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPatientCondition,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  hint: Text('Select patient condition'),
                  items: _patientConditions.map((String condition) {
                    Color? itemColor;
                    if (condition == 'Critical') {
                      itemColor = Colors.red;
                    } else if (condition == 'Serious') {
                      itemColor = Colors.orange;
                    } else {
                      itemColor = Colors.green;
                    }
                    return DropdownMenuItem<String>(
                      value: condition,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: itemColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(condition),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedPatientCondition = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select patient condition';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Patient Age
                Text(
                  'Patient Age',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _patientAgeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter patient age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter patient age';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0 || int.parse(value) > 150) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Pickup Location
                Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: _isLocationLoading
                            ? Text('Detecting location...', style: TextStyle(color: Colors.grey))
                            : Text(
                                _currentLocation ?? 'Location not available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _currentLocation != null && !_currentLocation!.contains('Unable') && !_currentLocation!.contains('denied')
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.red),
                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Hospital Destination (Optional)
                Text(
                  'Hospital Destination (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalDestinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter hospital name (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                ),
                SizedBox(height: 20),

                // Contact Number
                Text(
                  'Contact Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter contact number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Request Ambulance Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Request Ambulance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
