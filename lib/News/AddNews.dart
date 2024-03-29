import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:varnaboomapp/Detail.dart';
import 'package:varnaboomapp/base.dart';

class AddNews extends StatefulWidget {
  AddNews({Key? key}) : super(key: key);

  @override
  State<AddNews> createState() => _AddNewsState();
}

class _AddNewsState extends State<AddNews> {
  final _formKey = GlobalKey<FormState>();
  String titleCategory = 'دسته بندی';
  int _value = 0;
  XFile? image = null;
  XFile? video = null;
  bool loadBackButton = true;
  late int intIdCategory;
  dio.Dio _dio = dio.Dio();

  TextEditingController titrController = TextEditingController();
  TextEditingController textController = TextEditingController();

  Future<void> getImage() async {
    final ImagePicker _picker = ImagePicker();
    image = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);

    setState(() {});
  }

  Future<void> getVideo() async {
    final ImagePicker _picker = ImagePicker();
    video = await _picker.pickVideo(source: ImageSource.gallery);

    // Video
    if (video != null) {
      File file = File(video!.path);
      int sizeInBytes = file.lengthSync();
      int sizeInMb = sizeInBytes ~/ (1024 * 1024);
      print('sizzzeeeee movieeeeee $sizeInMb');

      if (sizeInMb <= 5) {
        setState(() {});
      } else {
        print('nooo');
        video = null;
        setState(() {});
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    'فایل وارد شده باید کمتر از ۵ مگ باشد',
                    textAlign: TextAlign.right,
                  ),
                ));
      }
    }

    //Video
  }

  Future<int?> submitNews() async {
    loadBackButton = false;
    EasyLoading.show(status: 'منتظر بمانید ...');
    updateToken(context);
    var boxToken = await Hive.openBox('token');
    String access = boxToken.get('access');
    String fileNameImage = image?.path.split('/').last as String;

    Map<String, dynamic> data = {
      'titr': titrController.text,
      'text': textController.text,
      'image': await MultipartFile.fromFile(image?.path as String,
          filename: fileNameImage.toEnglishDigit()),
      'category': intIdCategory
    };

    if (video != null) {
      String fileNameVideo = video?.path.split('/').last as String;
      data['video'] = await MultipartFile.fromFile(video?.path as String,
          filename: fileNameVideo.toEnglishDigit());
    }

    dio.FormData formdata = dio.FormData.fromMap(data);
    _dio.options.headers['content-Type'] = 'application/json';
    _dio.options.headers['Authorization'] = 'Bearer $access';

    var response = await _dio.post("$host/api/CreateNews/", data: formdata);

    EasyLoading.dismiss();

    return response.statusCode;
  }

  Future<List> getCategoryNews() async {
    await updateToken(context);
    var boxToken = await Hive.openBox('token');
    String access = boxToken.get('access');
    http.Response response = await http.get(
        Uri.parse('$host/api/GetCategoryNews/'),
        headers: <String, String>{'Authorization': 'Bearer $access'});

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  late Future<List> getCategory;

  @override
  void initState() {
    super.initState();
    getCategory = getCategoryNews();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (loadBackButton == true) {
          return true;
        } else {
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: secColor,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: flColor,
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (image == null) {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(
                            'لطفا تصویر وارد بکنید',
                            textDirection: TextDirection.rtl,
                          ),
                        ));
              } else if (titleCategory == 'دسته بندی') {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(
                            'لطفا دسته بندی خبر وارد بکنید',
                            textDirection: TextDirection.rtl,
                          ),
                        ));
              } else {
                int? statuscode = await submitNews();
                if (statuscode == 201) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: baseWidget())));
                } else {
                  showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: Text(
                              'لطفا چند دقیقه بعد دوباره امتحان کنید',
                              textDirection: TextDirection.rtl,
                            ),
                          ));
                }
              }
            }
          },
          child: Icon(Icons.done),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                flex: 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            IconButton(
                                onPressed: getImage,
                                icon: Icon(
                                  Icons.photo,
                                  color: image == null
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  size: 4.h,
                                )),
                            Text(
                              'تصویر',
                              style: TextStyle(
                                  color: image == null
                                      ? Colors.redAccent
                                      : Colors.green),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                          child: Column(
                        children: [
                          IconButton(
                            onPressed: getVideo,
                            icon: Icon(
                              Icons.movie,
                              size: 4.h,
                              color: video == null
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                          Text(
                            'فیلم',
                            style: TextStyle(
                              color: video == null
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                            ),
                          )
                        ],
                      )),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List>(
                  future: getCategory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return new Center(
                        child: new CircularProgressIndicator(
                          color: secColor,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return new Text('Error: ${snapshot.error}');
                    } else {
                      return Expanded(
                          flex: 0,
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 30, left: 50, right: 50),
                              child: OutlinedButton(
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(content:
                                            StatefulBuilder(
                                                builder: (context, stat) {
                                          return SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                for (int i = 0;
                                                    i < snapshot.data!.length;
                                                    i++)
                                                  ListTile(
                                                    title: Text(snapshot
                                                        .data![i]['name']),
                                                    leading: Radio<int>(
                                                      focusColor: secColor,
                                                      activeColor: secColor,
                                                      value: i,
                                                      groupValue: _value,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _value = value as int;
                                                          titleCategory =
                                                              snapshot.data![
                                                                      _value]
                                                                  ['name'];
                                                          intIdCategory =
                                                              snapshot.data![
                                                                  _value]['id'];

                                                          print(intIdCategory);
                                                          print(titleCategory);
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                    ),
                                                  )
                                              ],
                                            ),
                                          );
                                        }))),
                                child: Text(
                                  titleCategory,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ));
                    }
                  }),
              Expanded(
                flex: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: titrController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "این فیلد نمتواند خالی باشد";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'تیتر',
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: textController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "این فیلد نمتواند خالی باشد";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  decoration: InputDecoration(
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    labelText: 'متن خبر',
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
