import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilePickerDemo extends StatefulWidget {
  @override
  _FilePickerDemoState createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State<FilePickerDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _fileName;
  String? _saveAsFileName;
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isLoading = false;
  bool _userAborted = false;
  final bool _multiPick = true;
  final FileType _pickingType = FileType.any;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _extension = _controller.text);
  }

  void _pickFiles() async {
    _resetState();
    try {
      _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
      ))
          ?.files;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _paths != null ? _paths!.map((e) => e.name).toString() : '...';
      _userAborted = _paths == null;
    });
  }

  void _clearCachedFiles() async {
    _resetState();
    try {
      bool? result = await FilePicker.platform.clearTemporaryFiles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result! ? Colors.green : Colors.red,
          content: Text((result
              ? 'Temporary files removed with success.'
              : 'Failed to clean temporary files')),
        ),
      );
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  showGenericDialog({
    required BuildContext context,
    Function? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: Text(
            "Enviar anexo",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6!.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Builder(
            builder: (BuildContext context) => _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: CircularProgressIndicator(),
                  )
                : _userAborted
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          'Operação cancelada',
                        ),
                      )
                    : _directoryPath != null
                        ? ListTile(
                            title: const Text('caminho do arquivo'),
                            subtitle: Text(_directoryPath!),
                          )
                        : _paths != null
                            ? SizedBox(
                                width: 150,
                                height: 150,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          _paths != null && _paths!.isNotEmpty
                                              ? _paths!.length
                                              : 1,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final String name = _paths!
                                            .map((e) => e.name)
                                            .toList()[index];

                                        return ListTile(
                                          title: Row(
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              const Icon(
                                                Icons.picture_as_pdf,
                                                size: 20,
                                              ),
                                              IconButton(
                                                  onPressed: () {},
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    size: 20,
                                                  ))
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ))
                            : const Text(''),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        insetPadding: const EdgeInsets.all(8),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                _clearCachedFiles();
                Navigator.pop(context);
              },
              child: const Text('Fechar')),
          TextButton(
            onPressed: () {
              _pickFiles();
            },
            child: const Text('Selecionar arquivos'),
          )
        ],
      ),
    ).then((_) => {
          if (onCancel != null) {onCancel()}
        });
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _directoryPath = null;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Poc que o vini pediu'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
                    child: Column(
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () => showGenericDialog(context: context),
                          child: const Text('Enviar anexo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
