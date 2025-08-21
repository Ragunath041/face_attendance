import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  final String userId, name, email, designation, center;

  const HomePage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.designation,
    required this.center,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> _logout(BuildContext context) async {
    if (!mounted) return;
    
    // Store the context before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Call logout API to remove attendance record from database
      final result = await ApiService.logout(widget.userId);
      
      if (mounted) {
        if (result["success"] == true) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(result["data"]?["message"] ?? "Logged out successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("Logout warning: ${result["message"] ?? "Unknown error"}"),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Small delay to show the snackbar
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Handle any network or other errors
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Logout error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Small delay to show the snackbar
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // Always navigate to login page, regardless of API success/failure
    if (mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Clear navigation stack
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStoredImages() async {
    try {
      final result = await ApiService.getUserImages(widget.userId);
      
      if (mounted) {
        if (result["success"] == true) {
          final totalImages = result["total_images"] ?? 0;
          final imageKeys = result["image_keys"] ?? [];
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Stored Images"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Images: $totalImages"),
                  const SizedBox(height: 8),
                  const Text("Image Files:"),
                  ...imageKeys.map((key) => Text("• $key")),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to get images: ${result["message"]}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Attendance marked successfully",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              "Your Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildDetailCard(
                    icon: Icons.badge,
                    title: "User ID",
                    value: widget.userId,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    icon: Icons.person,
                    title: "Name",
                    value: widget.name,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    icon: Icons.email,
                    title: "Email",
                    value: widget.email,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    icon: Icons.work,
                    title: "Designation",
                    value: widget.designation,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailCard(
                    icon: Icons.location_on,
                    title: "Center",
                    value: widget.center,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  
                  // Check Stored Images Button
                  ElevatedButton.icon(
                    onPressed: _checkStoredImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Check Stored Images"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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