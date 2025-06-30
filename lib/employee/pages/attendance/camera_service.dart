import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  
  // Initialize cameras
  static Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      debugPrint('Cameras initialized: ${_cameras?.length ?? 0} cameras found');
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      rethrow; // Re-throw to handle permission errors upstream
    }
  }
  
  // Get front camera
  static CameraDescription? getFrontCamera() {
    if (_cameras == null || _cameras!.isEmpty) return null;
    
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      debugPrint('Front camera not found: $e');
      // Return the first available camera if front camera is not found
      return _cameras!.isNotEmpty ? _cameras!.first : null;
    }
  }
  
  // Get back camera
  static CameraDescription? getBackCamera() {
    if (_cameras == null || _cameras!.isEmpty) return null;
    
    try {
      return _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
    } catch (e) {
      debugPrint('Back camera not found: $e');
      return _cameras!.isNotEmpty ? _cameras!.first : null;
    }
  }
  
  // Save image to device storage
  static Future<String?> saveImageToStorage(XFile imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = join(appDir.path, 'attendance_photos');
      
      // Create directory if it doesn't exist
      final Directory imageDir = Directory(imagePath);
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'attendance_$timestamp.jpg';
      final String finalPath = join(imagePath, fileName);
      
      // Copy file to new location
      final File newImage = await File(imageFile.path).copy(finalPath);
      
      return newImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }
  
  // Check if camera permission is available (simplified approach)
  static Future<bool> checkCameraPermission() async {
    try {
      await initializeCameras();
      return _cameras != null && _cameras!.isNotEmpty;
    } catch (e) {
      debugPrint('Camera permission check failed: $e');
      return false;
    }
  }

  // Delete old photos to manage storage
  static Future<void> cleanupOldPhotos({int maxFiles = 10}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = join(appDir.path, 'attendance_photos');
      final Directory imageDir = Directory(imagePath);
      
      if (await imageDir.exists()) {
        final List<FileSystemEntity> files = imageDir.listSync();
        
        // Filter and sort image files by modification time
        final List<File> imageFiles = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.jpeg'))
            .toList();
        
        imageFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        // Delete old files if we exceed the limit
        if (imageFiles.length > maxFiles) {
          for (int i = maxFiles; i < imageFiles.length; i++) {
            try {
              await imageFiles[i].delete();
              debugPrint('Deleted old photo: ${imageFiles[i].path}');
            } catch (e) {
              debugPrint('Failed to delete old photo: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old photos: $e');
    }
  }

  // Get the size of attendance photos directory
  static Future<double> getStorageUsage() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = join(appDir.path, 'attendance_photos');
      final Directory imageDir = Directory(imagePath);
      
      if (!await imageDir.exists()) {
        return 0.0;
      }

      double totalSize = 0;
      final List<FileSystemEntity> files = imageDir.listSync(recursive: true);
      
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize / (1024 * 1024); // Return size in MB
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0.0;
    }
  }
}