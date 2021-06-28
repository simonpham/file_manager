library file_manager;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Library Imports
import 'package:file_manager/helper/helper.dart';
export 'package:file_manager/helper/helper.dart';

typedef TileBuilder = Widget Function(
  BuildContext context,
  FileSystemEntity entity,
);

class _PathInfo {
  final String path;
  final FileStat fileStat;
  _PathInfo(this.path, this.fileStat);
}

List<_PathInfo> _pathInfo = [];

bool isFile(FileSystemEntity entity) {
  return (entity is File);
}

bool isDirectory(FileSystemEntity entity) {
  return (entity is Directory);
}

Future<List<FileSystemEntity>> _sortEntitysList(
    String path, SortBy sortType) async {
  _pathInfo.clear();
  final List<FileSystemEntity> list = await Directory(path).list().toList();
  if (sortType == SortBy.name) {
    final dirs = list.where((element) => element is Directory).toList();
    dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    final files = list.where((element) => element is File).toList();
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return [...dirs, ...files];
  } else if (sortType == SortBy.date) {
    // list.forEach((element) async =>
    //     _pathInfo.add(_PathInfo(element.path, await element.stat())));
    // final dirs = list.where((element) => element is Directory).toList();
    // dirs.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    // final files = list.where((element) => element is File).toList();
  }
  return [];
}

/// Get the basename of Directory or File.
/// ie: controller.dirName(dir);
String basename(dynamic entity, [bool showFileExtension = true]) {
  if (entity is Directory) {
    return entity.path.split('/').last;
  } else if (entity is File) {
    return (showFileExtension)
        ? entity.path.split('/').last.split('.').first
        : entity.path.split('/').last;
  } else {
    print(
        "Please provide a Object of type File, Directory or FileSystemEntity");
    return "";
  }
}

// /// Get the basename of Directory by providing Directory.
// String basenameDir(Directory dir) => dir.path.split('/').last;

// /// Get the basename of Fileby providing File.
// String basenameFle(File file, {bool showFileExtension = false}) =>
//     showFileExtension
//         ? file.path.split('/').last
//         : file.path.split('/').last.split('.').first;

Future<List<Directory>?> getStorageList() async {
  List<Directory>? storages = await getExternalStorageDirectories();
  if (Platform.isAndroid) {
    storages = storages!.map((Directory e) {
      final List<String> splitedPath = e.path.split("/");
      return Directory(splitedPath
          .sublist(0, splitedPath.indexWhere((element) => element == "Android"))
          .join("/"));
    }).toList();
    return storages;
  } else
    return [];
}

class FileManager extends StatefulWidget {
  /// Provide a custom widget for loading screen.
  final Widget? loadingScreen;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final FileManagerController controller;
  final SortBy sort;
  final TileBuilder tileBuilder;

  /// Hide the hidden file and folder.
  final bool hideHiddenEntity;

  FileManager({
    this.loadingScreen,
    this.physics,
    this.shrinkWrap = false,
    this.sort = SortBy.name,
    required this.controller,
    required this.tileBuilder,
    this.hideHiddenEntity = true,
  });

  @override
  _FileManagerState createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  final ValueNotifier<String> path = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();
    widget.controller
        .addListener(() => path.value = widget.controller.getCurrentPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>?>(
      future: getStorageList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          widget.controller.setCurrentPath = snapshot.data![0].path;
          // path.value = snapshot.data![0].path;
          return body(context);
        } else if (snapshot.hasError) {
          // print(snapshot.error);
          throw Exception(snapshot.error.toString());
          // return errorPage(snapshot.error.toString());
        } else {
          return loadingScreenWidget();
        }
      },
    );
  }

  Widget body(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: path,
      builder: (context, pathSnapshot, _) {
        return FutureBuilder<List<FileSystemEntity>>(
            // future: Directory(pathSnapshot).list(recursive: false).toList(),
            future: _sortEntitysList(pathSnapshot, widget.sort),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<FileSystemEntity> entitys = snapshot.data!;

                if (widget.hideHiddenEntity) {
                  entitys = entitys.where((element) {
                    if (basename(element) == "" ||
                        basename(element).startsWith('.')) {
                      return false;
                    } else {
                      return true;
                    }
                  }).toList();
                }

                return ListView.builder(
                  physics: widget.physics,
                  shrinkWrap: widget.shrinkWrap,
                  itemCount: entitys.length,
                  itemBuilder: (context, index) {
                    return widget.tileBuilder(context, entitys[index]);
                  },
                );
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return errorPage(snapshot.error.toString());
              } else {
                return loadingScreenWidget();
              }
            });
      },
    );
  }

  // Widget tileWidget(BuildContext context, FileSystemEntity entity) {
  //   return widget.tileBuilder(context, entity);
  // }

  Container errorPage(String error) {
    return Container(
      color: Colors.red,
      child: Center(
        child: Text("Error: $error"),
      ),
    );
  }

  Widget loadingScreenWidget() {
    if ((widget.loadingScreen == null)) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container(
        child: Center(
          child: widget.loadingScreen,
        ),
      );
    }
  }
}
