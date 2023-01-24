import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apk_decompiler/services/decompiler.dart';
import 'package:flutter_apk_decompiler/widgets/circle_error.dart';
import 'package:flutter_apk_decompiler/widgets/circle_success.dart';
import 'package:path_provider/path_provider.dart';

import 'states.dart';
import 'widgets/circle_loading.dart';

class DecompressPage extends StatefulWidget {
  const DecompressPage({super.key});

  @override
  State<DecompressPage> createState() => _DecompressPageState();
}

class _DecompressPageState extends State<DecompressPage> {
  final Decompiler decompiler = Decompiler();
  States state1 = InitialState();
  States state2 = InitialState();
  States state3 = InitialState();

  String? pathZip;

  @override
  initState() {
    super.initState();
    decompiler.initTools();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'É necessário ter pelo meno Java 8 na máquina',
              ),
              const Text(
                  'Caso alguma etapa ocorra algum erro será gerado o zip mas incompleto'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _onClickPickFile,
                    child: const Text('Escolher APK'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                      onPressed: () {
                        decompiler.openJavaGUI();
                      },
                      child: const Text('Abrir visualizador de .jar'))
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Primeira descompilação'),
                  const SizedBox(width: 16),
                  state1 is Step1State
                      ? (state1 as Step1State).loading
                          ? const CircleLoading()
                          : (state1 as Step1State).success
                              ? const CircleSuccess()
                              : const CircleError()
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Segunda descompilação'),
                  const SizedBox(width: 16),
                  state2 is Step2State
                      ? (state2 as Step2State).loading
                          ? const CircleLoading()
                          : (state2 as Step2State).success
                              ? const CircleSuccess()
                              : const CircleError()
                      : const SizedBox(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gerando um zip'),
                  const SizedBox(width: 16),
                  state3 is Step3State
                      ? (state3 as Step3State).loading
                          ? const CircleLoading()
                          : (state3 as Step3State).success
                              ? const CircleSuccess()
                              : const CircleError()
                      : const SizedBox(),
                ],
              ),
              state3 is Step3State
                  ? (state3 as Step3State).success
                      ? Column(
                          children: [
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await showSaveDialog();
                              },
                              child: const Text(
                                'Baixar o zip',
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink()
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  _onClickPickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowedExtensions: ['apk'], type: FileType.custom);

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      final tempDirectory = await getTemporaryDirectory();

      File cacheFile = File('${tempDirectory.path}/cache.apk');

      await file.copy(cacheFile.path);

      await _step1(tempDirectory);

      await _step2(tempDirectory);

      await step3(tempDirectory);
    }
  }

  Future<void> step3(Directory tempDirectory) async {
    setState(() {
      state3 = Step3State(false, true);
    });

    try {
      pathZip = await decompiler.conversionToZip(tempDirectory.path);

      setState(() {
        state3 = Step3State(true, false);
      });
    } catch (e) {
      setState(() {
        state3 = Step3State(false, false);
      });
    }
  }

  Future<void> _step2(Directory tempDirectory) async {
    setState(() {
      state2 = Step2State(false, true);
    });

    try {
      await decompiler.decompile2(tempDirectory.path);
      setState(() {
        state2 = Step2State(true, false);
      });
    } catch (e) {
      setState(() {
        state2 = Step2State(false, false);
      });
    }
  }

  Future<void> _step1(Directory tempDirectory) async {
    setState(() {
      state1 = Step1State(false, true);
    });
    try {
      await decompiler.decompile1(tempDirectory.path);
      setState(() {
        state1 = Step1State(true, false);
      });
    } catch (e) {
      setState(() {
        state1 = Step1State(false, false);
      });
    }
  }

  Future<void> showSaveDialog() async {
    //Mostra o dialog de salvar arquivo
    final filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar arquivo',
        type: FileType.any,
        fileName: 'files.zip');

    if (filePath != null && pathZip != null && pathZip != '') {
      final file = File(pathZip!);
      final bytes = await file.readAsBytes();
      final outputFile = File(filePath);
      await outputFile.writeAsBytes(bytes);
    }
  }
}
