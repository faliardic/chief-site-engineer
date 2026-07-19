import 'dart:io';

import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

abstract interface class MobileBackupFileGateway {
  Future<String?> pickPackage();
  Future<void> sharePackage(String absolutePath);
}

class DeviceMobileBackupFileGateway implements MobileBackupFileGateway {
  const DeviceMobileBackupFileGateway({required this.directories});

  final AppDirectories directories;

  @override
  Future<String?> pickPackage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.custom,
      allowedExtensions: const ['csebackup'],
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    final selectedPath = selected.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) return null;
    final file = File(selectedPath);
    if (!await file.exists()) return null;
    return path.normalize(path.absolute(file.path));
  }

  @override
  Future<void> sharePackage(String absolutePath) async {
    final file = File(path.normalize(path.absolute(absolutePath)));
    if (!await file.exists() ||
        path.extension(file.path).toLowerCase() != '.csebackup') {
      throw StateError('backup package is unavailable');
    }
    await SharePlus.instance.share(
      ShareParams(
        title: 'CSE Mobil Tam Yedek',
        subject: 'CSE Mobil Tam Yedek',
        text: 'Parola korumalı CSE mobil yedeği',
        files: [XFile(file.path, mimeType: 'application/vnd.cse.backup')],
      ),
    );
  }
}
