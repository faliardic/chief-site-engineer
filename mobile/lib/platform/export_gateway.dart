import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:path/path.dart' as path;

abstract interface class ExportSharePort {
  Future<void> share(String absoluteFilePath);
}

class LocalExportStager {
  const LocalExportStager(this.directories);

  final AppDirectories directories;

  Future<File> stage(String fileName, Uint8List bytes) async {
    if (fileName.isEmpty || path.basename(fileName) != fileName) {
      throw const PathContractViolation('export file name must be a basename');
    }
    directories.validate();
    await directories.ensureCreated();
    final temporary = File(
      path.join(directories.staging.path, '$fileName.part'),
    );
    final destination = File(
      path.join(directories.exportsBackups.path, fileName),
    );
    if (await temporary.exists() || await destination.exists()) {
      throw const PathContractViolation('export destination already exists');
    }
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      return await temporary.rename(destination.path);
    } on Object {
      if (await temporary.exists()) {
        await temporary.delete();
      }
      rethrow;
    }
  }
}
