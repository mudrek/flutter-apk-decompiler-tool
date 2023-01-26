import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';

class Decompiler {
  File? guiInterface;
  File? apkTool;
  File? dexTool;
  final shell = Shell();

  void initTools() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    await rootBundle.load('assets/tools/apktool_2.7.0.jar').then((value) async {
      final file = File('$tempPath/apktool.jar');
      file.writeAsBytesSync(value.buffer.asUint8List());
      apkTool = file;
      debugPrint(value.toString());
    });

    await rootBundle.load('assets/tools/jd-gui-1.6.6.jar').then((value) async {
      final file = File('$tempPath/gui_interface.jar');
      file.writeAsBytesSync(value.buffer.asUint8List());
      guiInterface = file;
      debugPrint(value.toString());
    });

    await rootBundle.load('assets/tools/dex.zip').then((value) async {
      final file = File('$tempPath/dex.zip');
      file.writeAsBytesSync(value.buffer.asUint8List());
      dexTool = file;
      debugPrint(value.toString());

      // Lê os bytes do arquivo
      final List<int> bytes = await file.readAsBytes();

      // Cria um arquivo zip
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      // Extrai os arquivos para o diretório
      for (final ArchiveFile archiveFile in archive) {
        final String filename = archiveFile.name;
        final List<int> data = archiveFile.content;
        final String path = '$tempPath/$filename';
        if (archiveFile.isFile) {
          final File newFile = File(path);
          await newFile.create(recursive: true);
          await newFile.writeAsBytes(data);
        } else {
          final Directory newDir = Directory(path);
          await newDir.create(recursive: true);
        }
      }
    });

    debugPrint('>>>>> Ferramentas carregadas <<<<<');
  }

  Future<void> decompile1(String path) async {
    await shell.run('''
      java -jar ${apkTool!.path} d $path/cache.apk -f -o $path/cache.apk.out
      ''');
  }

  Future<void> decompile2(String path) async {
    // verify if windows
    if (Platform.isWindows) {
      await shell.run('''

      $path/d2j-dex2jar.bat --force $path/cache.apk -o $path/cache-dex2jar.jar

      ''');
    } else {
      await shell.run('''

      sh $path/d2j-dex2jar.sh --force $path/cache.apk -o $path/cache-dex2jar.jar

      ''');
    }
  }

  void cancelShell() async {
    shell.kill();
  }

  void openJavaGUI() {
    shell.run('''
      java -jar ${guiInterface!.path}
      ''');
  }

  Future<String> conversionToZip(String pathCache) async {
    final file1 = Directory('$pathCache/cache.apk.out');
    final file2 = File('$pathCache/cache-dex2jar.jar');
    final outputFile = File('$pathCache/files.zip');

    final bytes2 = await file2.readAsBytes();

    final archive = Archive();
    archive.addFile(ArchiveFile('file2.jar', bytes2.length, bytes2));

    await for (final file in file1.list(recursive: true)) {
      if (file is File) {
        final bytes = await file.readAsBytes();
        final path = file.path.replaceAll('$pathCache/cache.apk.out/', '');
        archive.addFile(ArchiveFile(path, bytes.length, bytes));
      }
    }

    final output = ZipEncoder().encode(archive);

    await outputFile.writeAsBytes(output!);

    debugPrint('>>>>> Arquivo gerado <<<<<');

    return outputFile.path;
  }
}
