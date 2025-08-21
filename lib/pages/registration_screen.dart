import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/api_services.dart';
import '../services/data_augmentation_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _userIdCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _designationCtrl = TextEditingController();
  final TextEditingController _centerCtrl = TextEditingController();
  
  bool _loading = false;
  String? _error;
  CameraController? _cameraController;
  List<Uint8List> _capturedImages = [];
  int _currentAngle = 0;
  
  // 7 different angles for comprehensive face capture
  final List<String> _angles = [
    "Front View",
    "Left 15°",
    "Left 30°", 
    "Right 15°",
    "Right 30°",
    "Slight Up",
    "Slight Down"
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      
      setState(() {
        _capturedImages.add(bytes);
        if (_currentAngle < _angles.length - 1) {
          _currentAngle++;
        }
      });
    } catch (e) {
      setState(() => _error = "Failed to capture image: $e");
    }
  }

  Future<void> _retakeImage(int index) async {
    setState(() {
      _capturedImages.removeAt(index);
      if (_currentAngle > 0) _currentAngle--;
    });
  }

  Future<void> _register() async {
    if (_userIdCtrl.text.isEmpty || _nameCtrl.text.isEmpty || _capturedImages.isEmpty) {
      setState(() => _error = "Please fill all required fields and capture at least one image");
      return;
    }

    if (_capturedImages.length < 3) {
      setState(() => _error = "Please capture at least 3 images from different angles");
      return;
    }

    // Validate image quality using data augmentation service
    if (!DataAugmentationService.validateImageQuality(_capturedImages)) {
      setState(() => _error = "Some images don't meet quality requirements. Please retake them.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Convert all captured images to base64 for registration
      final List<String> base64Images = _capturedImages.map((image) => base64Encode(image)).toList();
      
      final result = await ApiService.register(
        userId: _userIdCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        center: _centerCtrl.text.trim(),
        imagesBase64: base64Images, // Send all images
      );

      setState(() => _loading = false);

      if (result["success"] == true) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration successful with ${result["images_processed"]} images! You can now login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = result["message"] ?? "Registration failed");
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Registration failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Registration"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Information Form
            _buildUserForm(),
            const SizedBox(height: 24),
            
            // Camera Section
            _buildCameraSection(),
            const SizedBox(height: 24),
            
            // Captured Images Grid
            if (_capturedImages.isNotEmpty) _buildImagesGrid(),
            
            const SizedBox(height: 24),
            
            // Error Display
            if (_error != null) _buildErrorDisplay(),
            
            // Register Button
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "User Information",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _userIdCtrl,
          decoration: const InputDecoration(
            labelText: "User ID *",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: "Full Name *",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _designationCtrl,
          decoration: const InputDecoration(
            labelText: "Designation",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _centerCtrl,
          decoration: const InputDecoration(
            labelText: "Center",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Face Capture",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Current: ${_angles[_currentAngle]}",
          style: const TextStyle(fontSize: 16, color: Colors.blue),
        ),
        const SizedBox(height: 16),
        
        // Help Guidelines
        _buildCaptureGuidelines(),
        const SizedBox(height: 16),
        
        // Camera Preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Capture Button
        ElevatedButton.icon(
          onPressed: _captureImage,
          icon: const Icon(Icons.camera_alt),
          label: Text("Capture ${_angles[_currentAngle]}"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        const SizedBox(height: 8),
        Text(
          "Progress: ${_capturedImages.length}/${_angles.length} images",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCaptureGuidelines() {
    final guidelines = DataAugmentationService.getCaptureGuidelines();
    
    return ExpansionTile(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text("Capture Guidelines", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: guidelines.map((guideline) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guideline,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Captured Images",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _capturedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _capturedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _angles[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _retakeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _capturedImages.isNotEmpty ? _register : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Register",
                style: TextStyle(fontSize: 18),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _userIdCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _designationCtrl.dispose();
    _centerCtrl.dispose();
    super.dispose();
  }
}