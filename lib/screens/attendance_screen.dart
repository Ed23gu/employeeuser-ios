import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/models/department_model.dart';
import 'package:employee_attendance/models/user_model.dart';
import 'package:employee_attendance/screens/observaciones/observaciones_page.dart';
import 'package:employee_attendance/services/attendance_service.dart';
import 'package:employee_attendance/services/db_service.dart';
import 'package:employee_attendance/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as route;
import 'package:slide_to_act/slide_to_act.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey<SlideActionState> key = GlobalKey<SlideActionState>();
  final GlobalKey<SlideActionState> key2 = GlobalKey<SlideActionState>();
  String todayDate = DateFormat("dd MMMM yyyy", "es_ES").format(DateTime.now());
  final SupabaseClient supabase = Supabase.instance.client;
  final AttendanceService subirubi = AttendanceService();
  bool _estacargandofoto = false;
  String getUrl = "INICIAL";
  final pad8 = 8.0;
  final pad16 = 16.0;
  final pad4 = 4.0;
  final lineSizeancho = 60.0;
  final linearSizeAlto = 20.0;
  final grosorDivider = 1.0;
  final margenSuperior = 5.0;
  final margenInferior = 5.0;
  final margenPanelfotos2 = 0.0;
  final anchoSizedivider = 80.0;
  final altoSlider = 55.0;
  final elevacion = 3.0;
  final altoImagen = 126.0;
  final anchoImagen = 100.0;
  final int imagenQuality = 100;
  final int calidadFoto = 85;
  final int porcentajeDeCalidad = 15;
  final picker = ImagePicker();
  dynamic _images;
  Uint8List webImage = Uint8List(8);
  String noPictureUpload = "Foto no cargada, intentelo nuevamente por favor.";

  Future deleteImage(String tipoimagen, String imageName) async {
    String folderFecha = imageName.split('/')[9].toString();
    String fileName = imageName.split('/')[10].toString();
    String folderFechaLimpio = folderFecha.replaceAll("%20", " ");
    try {
      await supabase.storage.from('imageip').remove(
          ["${supabase.auth.currentUser!.id}/$folderFechaLimpio/$fileName"]);
      await supabase
          .from('attendance')
          .update({
            '$tipoimagen': null,
          })
          .eq('employee_id', supabase.auth.currentUser!.id)
          .eq('date', todayDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Algo ha salido mal, intentelo nuevamente.")));
    }
  }

  Future<File> customCompressed({
    @required File? imagePathToCompress,
    quality = 100,
    percentage = 15,
  }) async {
    var path = await FlutterNativeImage.compressImage(
      imagePathToCompress!.absolute.path,
      quality: calidadFoto,
      percentage: porcentajeDeCalidad,
    );
    return path;
  }

  Future choiceImage() async {
    setState(() => _estacargandofoto = true);
    String fileName =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()) + '.jpg';
    String fecharuta =
        DateFormat("MMMM yyyy", "es_ES").format(DateTime.now()).toString();

    if (!kIsWeb) {
      var pickedFile = await picker.pickImage(
          source: ImageSource.camera, imageQuality: imagenQuality);
      if (pickedFile != null) {
        _images = File(pickedFile.path);
        File? imagescom = await customCompressed(imagePathToCompress: _images);
        _images = File(imagescom.path);

        try {
          String uploadedUrl = await supabase.storage.from('imageip').upload(
              "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
              _images!);
          String urllisto = uploadedUrl.replaceAll("imageip/", "");
          getUrl = supabase.storage.from('imageip').getPublicUrl(urllisto);
          await updateOrInsertAttendanceRecord(getUrl);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Foto cargada correctamente."),
            backgroundColor: Colors.green,
          ));
        } on PostgrestException {
          return Future.error("Algo ha salido mal, intentelo nuevamente");
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(noPictureUpload),
            backgroundColor: Colors.red,
          ));
        } // update basededatos
      }
    } else if (kIsWeb) {
      var pickedFileweb = await picker.pickImage(
          source: ImageSource.camera, imageQuality: imagenQuality);
      if (pickedFileweb != null) {
        var f = await pickedFileweb.readAsBytes();
        _images = File('a');
        setState(() {
          webImage = f;
        });
        var pickedFile = webImage;
        try {
          String uploadedUrl = await supabase.storage
              .from('imageip')
              .uploadBinary(
                  "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                  pickedFile);
          String urllisto = uploadedUrl.replaceAll("imageip/", "");
          final getUrl =
              supabase.storage.from('imageip').getPublicUrl(urllisto);
          await updateOrInsertAttendanceRecord(getUrl);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Foto cargada correctamente."),
            backgroundColor: Colors.green,
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(noPictureUpload),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
    setState(() => _estacargandofoto = false);
  }

  Future<void> updateOrInsertAttendanceRecord(String imageUrl) async {
    final result = await supabase
        .from(Constants.attendancetable)
        .select()
        .eq('employee_id', supabase.auth.currentUser!.id)
        .eq('date', todayDate);
    if (result.isNotEmpty) {
      await supabase
          .from('attendance')
          .update({
            'pic_in': imageUrl,
          })
          .eq('employee_id', supabase.auth.currentUser!.id)
          .eq('date', todayDate);
    } else {
      await supabase.from('attendance').insert({
        'employee_id': supabase.auth.currentUser!.id,
        'date': todayDate,
        'pic_in': imageUrl,
      });
    }
  }

  Future<void> updatePicture(String imageUrl, String tipoRegistro) async {
    final result = await supabase
        .from(Constants.attendancetable)
        .select()
        .eq('employee_id', supabase.auth.currentUser!.id)
        .eq('date', todayDate);
    if (result.isNotEmpty) {
      await supabase
          .from('attendance')
          .update({
            '$tipoRegistro': imageUrl,
          })
          .eq('employee_id', supabase.auth.currentUser!.id)
          .eq('date', todayDate);
    } else {
      await supabase.from('attendance').insert({
        'employee_id': supabase.auth.currentUser!.id,
        'date': todayDate,
        '$tipoRegistro': imageUrl,
      });
    }
  }

  Future<void> choiceImage2() async {
    String fileName =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()) + '.jpg';
    String fecharuta =
        DateFormat("MMMM yyyy", "es_ES").format(DateTime.now()).toString();
    var pickedFile;
    pickedFile = await picker.pickImage(
        source: ImageSource.camera, imageQuality: imagenQuality);

    if (pickedFile != null) {
      _images = File(pickedFile.path); //file

      if (!kIsWeb) {
        File? imagescom = await customCompressed(imagePathToCompress: _images);
        _images = File(imagescom.path);
      } else {
        webImage = await pickedFile.readAsBytes();
        _images = File('a');
      }
      try {
        String uploadedUrl = kIsWeb
            ? await supabase.storage.from('imageip').uploadBinary(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                webImage)
            : await supabase.storage.from('imageip').upload(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                _images!);
        String urllisto = uploadedUrl.replaceAll("imageip/", "");
        final getUrl = supabase.storage.from('imageip').getPublicUrl(urllisto);
        await updatePicture(getUrl, 'pic_out');

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Foto cargada correctamente."),
          backgroundColor: Colors.green,
        ));
      } on SocketException {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Foto no cargada, Error en la conección'),
          backgroundColor: Colors.red,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(noPictureUpload),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> choiceImage3() async {
    String fileName =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()) + '.jpg';
    String fecharuta =
        DateFormat("MMMM yyyy", "es_ES").format(DateTime.now()).toString();
    var pickedFile;
    pickedFile = await picker.pickImage(
        source: ImageSource.camera, imageQuality: imagenQuality);
    if (pickedFile != null) {
      _images = File(pickedFile.path);
      if (!kIsWeb) {
        File? imagescom = await customCompressed(imagePathToCompress: _images);
        _images = File(imagescom.path);
      } else {
        webImage = await pickedFile.readAsBytes();
        _images = File('a');
      }
      try {
        String uploadedUrl = kIsWeb
            ? await supabase.storage.from('imageip').uploadBinary(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                webImage)
            : await supabase.storage.from('imageip').upload(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                _images!);

        String urllisto = uploadedUrl.replaceAll("imageip/", "");
        final getUrl = supabase.storage.from('imageip').getPublicUrl(urllisto);
        await updatePicture(getUrl, 'pic_in2');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Foto cargada correctamente."),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(noPictureUpload),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> choiceImage4() async {
    String fileName =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now()) + '.jpg';
    String fecharuta =
        DateFormat("MMMM yyyy", "es_ES").format(DateTime.now()).toString();
    var pickedFile;
    pickedFile = await picker.pickImage(
        source: ImageSource.camera, imageQuality: imagenQuality);

    if (pickedFile != null) {
      _images = File(pickedFile.path); //file

      if (!kIsWeb) {
        File? imagescom = await customCompressed(imagePathToCompress: _images);
        _images = File(imagescom.path);
      } else {
        webImage = await pickedFile.readAsBytes();
        _images = File('a');
      }

      try {
        String uploadedUrl = kIsWeb
            ? await supabase.storage.from('imageip').uploadBinary(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                webImage)
            : await supabase.storage.from('imageip').upload(
                "${supabase.auth.currentUser!.id}/$fecharuta/$fileName",
                _images!);

        String urllisto = uploadedUrl.replaceAll("imageip/", "");
        final getUrl = supabase.storage.from('imageip').getPublicUrl(urllisto);

        await updatePicture(getUrl, 'pic_out2');

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Foto cargada correctamente."),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(noPictureUpload),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void initState() {
    route.Provider.of<AttendanceService>(context, listen: false)
        .getTodayAttendance();
    super.initState();
  }

  

  @override
  Widget build(BuildContext context) {
    final attendanceService = route.Provider.of<AttendanceService>(context);
    return Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad16, pad4, pad16, pad4),
          child: Column(
            children: [
              route.Consumer<DbService>(builder: (context, dbServie, child) {
                return FutureBuilder(
                    future: dbServie.getUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        UserModel user = snapshot.data!;
                        return Row(
                          children: [
                            gapH32,
                            userName(user: user),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          gapH32,
                          SizedBox(
                            width: lineSizeancho,
                            child: LinearProgressIndicator(),
                          )
                        ],
                      );
                    });
              }),
              gapH8,
              route.Consumer<DbService>(builder: (context, dbServie, child) {
                return FutureBuilder(
                    future: dbServie.getTodaydep(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        DepartmentModel user2 = snapshot.data!;
                        return Row(
                          children: [
                            gapH24,
                            userId(user2),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          gapH24,
                          SizedBox(
                            width: lineSizeancho,
                            child: LinearProgressIndicator(),
                          )
                        ],
                      );
                    });
              }), //
              Divider(),
              StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Container(
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat("HH:mm:ss").format(DateTime.now()),
                        style: TextStyle(
                            fontSize: sizeiconobar27,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    );
                  }),
              Container(
                alignment: Alignment.center,
                child: Text(
                  DateFormat("dd MMMM yyyy", "es_ES").format(DateTime.now()),
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ),

              gapH4,
              Container(
                margin: EdgeInsets.only(
                    top: margenSuperior,
                    bottom: margenInferior,
                    left: margenPanelfotos2,
                    right: margenPanelfotos2),
                height: altoContainer,
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        //  color: Colors.white,
                        : Color.fromARGB(255, 43, 41, 41),
                    boxShadow: [
                      BoxShadow(
                          color: Color.fromARGB(110, 18, 148, 255),
                          blurRadius: 5,
                          offset: Offset(1, 1)),
                    ],
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Ingreso:  ",
                                style: TextStyle(
                                  fontSize: sizesalin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                attendanceService.attendanceModel?.checkIn ??
                                    '--/--',
                                style: TextStyle(fontSize: sizeresul17),
                              ),
                            ],
                          ),
                          gapH4,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      onPressed: _estacargandofoto
                                          ? null
                                          : () async {
                                              try {
                                                if (attendanceService
                                                            .attendanceModel
                                                            ?.checkIn ==
                                                        null &&
                                                    attendanceService
                                                            .attendanceModel
                                                            ?.pic_in ==
                                                        null) {
                                                  await choiceImage();
                                                } else {
                                                  await attendanceService
                                                      .markAttendance3(context);
                                                }
                                                await attendanceService
                                                    .markAttendance3(context);
                                              } catch (e) {
                                                Utils.showSnackBar(
                                                    "$e", context,
                                                    color: Colors.red);
                                              }
                                            }),
                                  IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.grey,
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkIn ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_in !=
                                                  null) {
                                            await deleteImage(
                                                'pic_in',
                                                attendanceService
                                                    .attendanceModel!.pic_in
                                                    .toString());
                                          }
                                          setState(() {
                                            attendanceService
                                                .markAttendance3(context);
                                          });
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.blue);
                                        }
                                      }),
                                ],
                              ),
                              mostrarImagenDeBase(
                                  attendanceService.attendanceModel?.pic_in),
                            ],
                          )
                          //container
                        ],
                      )), //expanded
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Salida:  ",
                                style: TextStyle(
                                  fontSize: sizesalin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                attendanceService.attendanceModel?.checkOut ??
                                    '--/--',
                                style: TextStyle(fontSize: sizeresul17),
                              ),
                            ],
                          ),
                          gapH4,
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkIn !=
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.checkOut ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_out ==
                                                  null) {
                                            await choiceImage2();
                                          } else {
                                            attendanceService
                                                .markAttendance3(context);
                                          }
                                          attendanceService
                                              .markAttendance3(context);
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      }),
                                  IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.grey,
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkOut ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_out !=
                                                  null) {
                                            await deleteImage(
                                                'pic_out',
                                                attendanceService
                                                    .attendanceModel!.pic_out
                                                    .toString());
                                          }
                                          setState(() {
                                            attendanceService
                                                .markAttendance3(context);
                                          });
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      }),
                                ],
                              ),
                              mostrarImagenDeBase(
                                  attendanceService.attendanceModel?.pic_out),
                            ],
                          ),
                        ],
                      )),
                    ]),
              ),

              gapH4,
              Container(
                margin: EdgeInsets.only(bottom: margenInferior),
                child: Builder(builder: (context) {
                  return SlideAction(
                    sliderButtonIconSize: slideiconsize15,
                    innerColor: Theme.of(context).colorScheme.primary,
                    elevation: elevacion,
                    height: altoSlider,
                    text: (attendanceService.attendanceModel?.checkIn != null &&
                            attendanceService.attendanceModel?.checkOut != null)
                        ? "Registro completo"
                        : (attendanceService.attendanceModel?.checkIn == null)
                            ? "Registre el ingreso"
                            : "Registre la salida",
                    //alignment: Alignment.topCenter,
                    animationDuration: Duration(milliseconds: 200),
                    textStyle: TextStyle(
                        fontSize: sizecomentarios16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white),
                    outerColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Color(0xFF2B2929),
                    //   innerColor: Colors.red,
                    key: key,
                    onSubmit: () async {
                      try {
                        if (attendanceService.attendanceModel?.checkIn !=
                                null &&
                            attendanceService.attendanceModel?.checkOut !=
                                null) {
                          showDialogBox(
                              context, "Asistencia registrada", "Gracias");
                        } else if (attendanceService.attendanceModel?.checkIn ==
                                null &&
                            attendanceService.attendanceModel?.pic_in != null) {
                          await attendanceService.markAttendance(context);
                        } else if (attendanceService.attendanceModel?.pic_in ==
                            null) {
                          showDialogBox(context, "Foto no encontrada",
                              "Suba una foto por favor.");
                        } else if (attendanceService.attendanceModel?.pic_out !=
                            null) {
                          await attendanceService.markAttendance(context);
                        } else {
                          showDialogBox(context, "Foto no encontrada",
                              "Suba una foto por favor.");
                        }
                        key.currentState!.reset();
                      } catch (e) {
                        Utils.showSnackBar("$e", context);
                      }
                    },
                  );
                }),
              ),
              gapH4,
              Container(
                margin: EdgeInsets.only(
                    top: margenSuperior,
                    bottom: margenInferior,
                    left: margenPanelfotos2,
                    right: margenPanelfotos2),
                height: altoContainer,
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white //  color: Colors.white,
                        : Color.fromARGB(255, 43, 41, 41),
                    boxShadow: [
                      BoxShadow(
                          color: Color.fromARGB(110, 18, 148, 255),
                          blurRadius: 5,
                          offset: Offset(1, 1)),
                    ],
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Ingreso:  ",
                                style: TextStyle(
                                  fontSize: sizesalin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                attendanceService.attendanceModel?.checkIn2 ??
                                    '--/--',
                                style: TextStyle(fontSize: sizeresul17),
                              ),
                            ],
                          ),
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel?.checkOut != null &&
                                              attendanceService.attendanceModel
                                                      ?.checkIn2 ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_in2 ==
                                                  null) {
                                            await choiceImage3();
                                          } else {
                                            attendanceService
                                                .markAttendance3(context);
                                          }
                                          attendanceService
                                              .markAttendance3(context);
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      }),
                                  IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.grey,
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkIn2 ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_in2 !=
                                                  null) {
                                            await deleteImage(
                                                'pic_in2',
                                                attendanceService
                                                    .attendanceModel!.pic_in2
                                                    .toString());
                                          }
                                          setState(() {
                                            attendanceService
                                                .markAttendance3(context);
                                          });
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      })
                                ],
                              ),
                              mostrarImagenDeBase(
                                  attendanceService.attendanceModel?.pic_in2)
                            ],
                          )
                        ],
                      )),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Salida:  ",
                                style: TextStyle(
                                  fontSize: sizesalin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                attendanceService.attendanceModel?.checkOut2 ??
                                    '--/--',
                                style: TextStyle(fontSize: sizeresul17),
                              ),
                            ],
                          ),
                          gapH4,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkIn2 !=
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.checkOut2 ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_out2 ==
                                                  null) {
                                            await choiceImage4();
                                          } else {
                                            attendanceService
                                                .markAttendance3(context);
                                          }
                                          attendanceService
                                              .markAttendance3(context);
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      }),
                                  IconButton(
                                      icon: Icon(Icons.delete),
                                      color: Colors.grey,
                                      onPressed: () async {
                                        try {
                                          if (attendanceService.attendanceModel
                                                      ?.checkOut2 ==
                                                  null &&
                                              attendanceService.attendanceModel
                                                      ?.pic_out2 !=
                                                  null) {
                                            await deleteImage(
                                                'pic_out2',
                                                attendanceService
                                                    .attendanceModel!.pic_out2
                                                    .toString());
                                          }
                                          setState(() {
                                            attendanceService
                                                .markAttendance3(context);
                                          });
                                        } catch (e) {
                                          Utils.showSnackBar("$e", context,
                                              color: Colors.red);
                                        }
                                      })
                                ],
                              ),
                              mostrarImagenDeBase(
                                  attendanceService.attendanceModel?.pic_out2),
                            ],
                          )
                        ],
                      )),
                    ]),
              ),

              gapH4,
              Container(
                margin: EdgeInsets.only(bottom: margenInferior),
                child: Builder(builder: (context) {
                  return SlideAction(
                    elevation: elevacion,
                    innerColor: Theme.of(context).colorScheme.primary,
                    sliderButtonIconSize: slideiconsize15,
                    animationDuration: Duration(milliseconds: 200),
                    text: (attendanceService.attendanceModel?.checkIn2 !=
                                null &&
                            attendanceService.attendanceModel?.checkOut2 !=
                                null)
                        ? "Registro completo"
                        : (attendanceService.attendanceModel?.checkIn2 == null)
                            ? "Registre el ingreso"
                            : "Registre la salida",
                    //alignment: Alignment.topCenter,
                    height: altoSlider,
                    textStyle: TextStyle(
                        fontSize: sizecomentarios16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white),
                    outerColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Color(0xFF2B2929),
                    // innerColor: ,
                    key: key2,
                    onSubmit: () async {
                      try {
                        if (attendanceService.attendanceModel?.checkIn2 !=
                                null &&
                            attendanceService.attendanceModel?.checkOut2 !=
                                null) {
                          showDialogBox(
                              context, "Asistencia registrada", "Gracias");
                        } else if (attendanceService
                                    .attendanceModel?.checkIn2 ==
                                null &&
                            attendanceService.attendanceModel?.pic_in2 !=
                                null) {
                          await attendanceService.markAttendance2(context);
                        } else if (attendanceService.attendanceModel?.pic_in2 ==
                            null) {
                          showDialogBox(context, "Foto no encontrada",
                              "Suba una foto por favor.");
                        } else if (attendanceService
                                .attendanceModel?.pic_out2 !=
                            null) {
                          await attendanceService.markAttendance2(context);
                        } else {
                          showDialogBox(context, "Foto no encontrada",
                              "Suba una foto por favor.");
                        }
                        key2.currentState!.reset();
                      } catch (e) {
                        Utils.showSnackBar("$e", context);
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButton: SpeedDial(
          //Speed dial menus
          // marginBottom: 10, //margin bottom
          icon: Icons.message_outlined, //icon on Floating action button
          activeIcon: Icons.close, //icon when menu is expanded on button
          //backgroundColor: Colors.deepOrangeAccent, //background color of button
          // foregroundColor: Colors.white, //font color, icon color in button
          activeBackgroundColor:
              Colors.deepPurpleAccent, //background color when menu is expanded
          activeForegroundColor: Colors.white,
          //buttonSize: Size(45, 45), //button size
          visible: true,
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          elevation: 8.0, //shadow elevation of button
          shape: CircleBorder(), //shape of button

          children: [
            SpeedDialChild(
              //speed dial child
              child: Icon(Icons.message),
              //  backgroundColor: Colors.red,
              // foregroundColor: Colors.white,
              label:
                  '¿Has tenido inconvenientes \n al momento de registrarte? \n Dejanoslo saber.',
              labelStyle: TextStyle(fontSize: inconvenientessize18),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ComentariosPage()));
              },
            ),
          ],
        ));
  }

  Container mostrarImagenDeBase(pictureInOrOut) {
    return Container(
      alignment: Alignment.center,
      height: altoImagen,
      width: anchoImagen,
      child: Stack(
        children: [
          if (pictureInOrOut == null)
            Icon(Icons.photo)
          else
            CachedNetworkImage(
              imageUrl: pictureInOrOut.toString(),
              height: altoImagen,
              progressIndicatorBuilder: (context, url, error) =>
                  Center(child: const CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
        ],
      ),
    );
  }

  Container userId(DepartmentModel user2) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        user2.title != "" ? user2.title.toString() : " ",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class userName extends StatelessWidget {
  const userName({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        user.name != '' ? 'Hola ${user.name},' : 'Hola #${user.employeeId},',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

showDialogBox(BuildContext context, String titulo, String content) =>
    showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.pop(context, 'Cancel');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
