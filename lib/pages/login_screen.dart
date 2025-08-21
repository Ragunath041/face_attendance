import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_services.dart';
import 'home_page.dart';
import 'registration_screen.dart';
import 'live_camera_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _doLogin() async {
    final id = _userIdCtrl.text.trim();
    if (id.isEmpty) {
      setState(() {
        _error = "Please enter User ID";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Validate user
      final validateRes = await ApiService.validateUser(id);
      
      if (validateRes["success"] != true) {
        setState(() {
          _loading = false;
          _error = validateRes["message"] ?? "User not found";
        });
        return;
      }

      // Check camera permission
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        setState(() {
          _loading = false;
          _error = status.isPermanentlyDenied
              ? "Camera permission denied. Please enable in settings."
              : "Camera permission is required.";
        });
        if (status.isPermanentlyDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Please enable camera permission in settings."),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }

      // Open camera
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const LiveCameraPage()),
      );

      if (result == null) {
        setState(() => _loading = false);
        return;
      }

      final base64 = result['base64'] as String;

      // Verify face
      final loginRes = await ApiService.login(id, imageBase64: base64);
      
      setState(() => _loading = false);

      if (loginRes["success"] == true) {
        // Backend now returns user data along with verification success
        final user = loginRes["user"] ?? {};
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: user["user_id"] ?? id,
              name: user["name"] ?? "",
              email: user["email"] ?? "",
              designation: user["designation"] ?? "",
              center: user["center"] ?? "",
            ),
          ),
          (route) => false,
        );
      } else {
        String errorMsg = loginRes["message"] ?? "Login failed";
        if (loginRes["similarity"] != null) {
          errorMsg += " (Similarity: ${(loginRes["similarity"] * 100).toStringAsFixed(1)}%)";
        }
        setState(() => _error = errorMsg);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Network error: $e";
      });
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Attendance Login"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.face,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              "Welcome to Face Attendance",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _userIdCtrl,
              decoration: const InputDecoration(
                labelText: "User ID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
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
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _doLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _navigateToRegister,
              child: const Text(
                "Don't have an account? Register here",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }
}