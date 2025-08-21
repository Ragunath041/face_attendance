import 'dart:typed_data';
import 'dart:math' as math;

class DataAugmentationService {
  /// Applies data augmentation techniques to improve face recognition robustness
  /// Based on research paper recommendations for multi-angle face capture
  
  /// Generates augmented variations of a face image
  static List<Uint8List> generateAugmentedImages(Uint8List originalImage) {
    List<Uint8List> augmentedImages = [];
    
    // Add original image
    augmentedImages.add(originalImage);
    
    // Generate variations with different augmentations
    // Note: In a production app, you'd use proper image processing libraries
    // This is a simplified version for demonstration
    
    // 1. Brightness variations
    augmentedImages.add(_adjustBrightness(originalImage, 1.2)); // 20% brighter
    augmentedImages.add(_adjustBrightness(originalImage, 0.8)); // 20% darker
    
    // 2. Contrast variations
    augmentedImages.add(_adjustContrast(originalImage, 1.3)); // 30% more contrast
    augmentedImages.add(_adjustContrast(originalImage, 0.7)); // 30% less contrast
    
    // 3. Slight rotation variations (simulating head tilts)
    augmentedImages.add(_rotateImage(originalImage, 5)); // 5 degrees left
    augmentedImages.add(_rotateImage(originalImage, -5)); // 5 degrees right
    
    // 4. Noise addition for robustness
    augmentedImages.add(_addNoise(originalImage, 0.05)); // 5% noise
    
    return augmentedImages;
  }
  
  /// Adjusts image brightness
  static Uint8List _adjustBrightness(Uint8List image, double factor) {
    // This is a simplified brightness adjustment
    // In production, use proper image processing libraries like image package
    List<int> adjustedBytes = [];
    
    for (int i = 0; i < image.length; i++) {
      if (i % 4 == 3) {
        // Alpha channel - keep unchanged
        adjustedBytes.add(image[i]);
      } else {
        // RGB channels - adjust brightness
        int adjusted = (image[i] * factor).round().clamp(0, 255);
        adjustedBytes.add(adjusted);
      }
    }
    
    return Uint8List.fromList(adjustedBytes);
  }
  
  /// Adjusts image contrast
  static Uint8List _adjustContrast(Uint8List image, double factor) {
    // Simplified contrast adjustment
    List<int> adjustedBytes = [];
    
    for (int i = 0; i < image.length; i++) {
      if (i % 4 == 3) {
        // Alpha channel - keep unchanged
        adjustedBytes.add(image[i]);
      } else {
        // RGB channels - adjust contrast
        int adjusted = ((image[i] - 128) * factor + 128).round().clamp(0, 255);
        adjustedBytes.add(adjusted);
      }
    }
    
    return Uint8List.fromList(adjustedBytes);
  }
  
  /// Rotates image by given angle (simplified)
  static Uint8List _rotateImage(Uint8List image, double angle) {
    // This is a placeholder for rotation
    // In production, use proper image rotation libraries
    // For now, return the original image
    return image;
  }
  
  /// Adds noise to image for robustness
  static Uint8List _addNoise(Uint8List image, double noiseLevel) {
    // Simplified noise addition
    List<int> noisyBytes = [];
    math.Random random = math.Random();
    
    for (int i = 0; i < image.length; i++) {
      if (i % 4 == 3) {
        // Alpha channel - keep unchanged
        noisyBytes.add(image[i]);
      } else {
        // RGB channels - add noise
        int noise = ((random.nextDouble() - 0.5) * 2 * noiseLevel * 255).round();
        int adjusted = (image[i] + noise).clamp(0, 255);
        noisyBytes.add(adjusted);
      }
    }
    
    return Uint8List.fromList(noisyBytes);
  }
  
  /// Validates if captured images meet quality requirements
  static bool validateImageQuality(List<Uint8List> images) {
    if (images.isEmpty) return false;
    
    // Check minimum number of images (at least 3 as per research)
    if (images.length < 3) return false;
    
    // Check image sizes (should be reasonable)
    for (Uint8List image in images) {
      if (image.length < 1000) return false; // Minimum 1KB
      if (image.length > 10000000) return false; // Maximum 10MB
    }
    
    return true;
  }
  
  /// Gets recommended capture angles based on research
  static List<String> getRecommendedAngles() {
    return [
      "Front View (0°)",
      "Left 15°",
      "Left 30°", 
      "Right 15°",
      "Right 30°",
      "Slight Up (15°)",
      "Slight Down (15°)"
    ];
  }
  
  /// Calculates optimal threshold based on research findings
  static double getOptimalThreshold() {
    // Research paper recommends 0.7 for optimal balance
    // between accuracy and false rejection rate
    return 0.7;
  }
  
  /// Provides guidance for optimal face capture
  static List<String> getCaptureGuidelines() {
    return [
      "Ensure good lighting conditions",
      "Capture from multiple angles",
      "Avoid extreme shadows or glare",
      "Keep face centered in frame",
      "Maintain consistent distance",
      "Capture natural expressions",
      "Avoid motion blur"
    ];
  }
}
