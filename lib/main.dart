import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'gallery_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Capture and save',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: const HomePage(title: 'Image Capture and Save'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Directory _directory;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    _setImageDirectory();
    _checkForImage();
  }

  Future<void> _setImageDirectory() async {
    String? dirPath = await _getImagePath();

    if (dirPath == null) throw const FileSystemException("Directory not found");

    _directory = Directory(dirPath);
  }

  void _checkForImage() {
    List ls = _directory
        .listSync()
        .map((item) => item.path)
        .where((item) => item.endsWith(".jpg"))
        .toList(growable: false);

    _hasImage = false;
    if (ls.isNotEmpty) _hasImage = true;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _hasImage
          ? DisplayImage2(
              directory: _directory,
            )
          : Center(
              child: Text(
                'No image in captured yet',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          onPressed: _takePhoto,
          tooltip: 'Open Camera',
          child: const Icon(Icons.photo_camera_outlined),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<String?> _getImagePath() async {
    final extPath = await getExternalStorageDirectory();
    if (extPath == null) return null;

    List<String> externalPathList = extPath.path.split('/');

    // getting Position of 'Android'
    int posOfAndroidDir = externalPathList.indexOf('Android');

    //Joining the List<Strings> to generate the rootPath with "/" at the end.
    String rootPath = externalPathList.sublist(0, posOfAndroidDir).join('/');
    String dirPath = "$rootPath/Photos";
    //ask for permission
    await Permission.manageExternalStorage.request();
    var status = await Permission.manageExternalStorage.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied   before but not permanently.
      return null;
    }

// You can can also directly ask the permission about its status.
    if (await Permission.storage.isRestricted) {
      // The OS restricts access, for example because of parental controls.
      return null;
    }

    await Directory(dirPath).create(recursive: true);
    return dirPath;
  }

  void _takePhoto() async {
    String? imagePath = await _getImagePath();
    if (imagePath == null) return;

    ImagePicker()
        .pickImage(source: ImageSource.camera)
        .then((XFile? recordedImage) {
      if (recordedImage != null) {
        final String filePath =
            path.join(imagePath, '${recordedImage.name}.jpg');
        recordedImage.saveTo(filePath);
        _reload();
      }
    });
  }

  void _reload() {
    String message = "Image saved successfully at Photos";

    final snackBar = SnackBar(
      content: Text(message),
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() {});
  }
}

class DisplayImage extends StatelessWidget {
  final Directory directory;

  const DisplayImage({super.key, required this.directory});

  @override
  Widget build(BuildContext context) {
    var imageList = directory
        .listSync()
        .map((item) => item.path)
        .where((item) => item.endsWith(".jpg"))
        .toList(growable: false);
    return ListView.builder(
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          File file = File(imageList[index]);
          String name = file.path.split('/').last;
          return Container(
            padding: const EdgeInsets.all(4.0),
            child: Image.file(
              File(imageList[index]),
              fit: BoxFit.cover,
            ),
          );
        });
  }
}

class DisplayImage2 extends StatelessWidget {
  final Directory directory;

  const DisplayImage2({super.key, required this.directory});

  @override
  Widget build(BuildContext context) {
    var imageList = directory
        .listSync()
        .map((item) => item.path)
        .where((item) => item.endsWith(".jpg"))
        .toList(growable: false);
    return GridView.builder(
        itemCount: imageList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 3.0 / 4.6),
        itemBuilder: (context, index) {
          File file = File(imageList[index]);
          String name = file.path.split('/').last;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: InkWell(
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GalleryPhotoViewWrapper(
                        photoItems: imageList,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        initialIndex: index,
                        scrollDirection: Axis.horizontal,
                      ),
                    ),
                  )
                },
                child: Padding(
                  padding: new EdgeInsets.all(4.0),
                  child: Image.file(
                    File(imageList[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        });
  }
}
