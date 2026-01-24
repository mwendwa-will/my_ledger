import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';

class BackupService {
  static Future<void> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    
    // Check if file exists
    if (!await File(path).exists()) {
      throw Exception('Database file not found');
    }

    // Share the file
await SharePlus.instance.share(
  ShareParams(
    files: [XFile(path)], 
    text: 'MyLedger Database Backup',
  ),
);  }

  static Future<bool> importDatabase() async {
    // Pick file
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);
      
      // Close DB before overwriting?
      // Ideally yes, but hot reload might be tricky. 
      // We assume user will restart or we trigger a full reload.
      
      await sourceFile.copy(path);
      return true;
    }
    return false;
  }
}
