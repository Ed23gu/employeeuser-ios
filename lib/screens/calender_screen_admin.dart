import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/models/obs_model.dart';
import 'package:employee_attendance/models/ubi_model.dart';
import 'package:employee_attendance/services/attendance_service_admin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as prove;
import 'package:readmore/readmore.dart';
import 'package:simple_month_year_picker/simple_month_year_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../services/db_service_admin.dart';

class CalenderScreenAdmin extends StatefulWidget {
  const CalenderScreenAdmin({super.key});

  @override
  State<CalenderScreenAdmin> createState() => _CalenderScreenStateAdmin();
}

Future<void> _openmap(String lat, String lon) async {
  Uri googleUrl =
      Uri.parse('https://www.google.com.ec/maps/search/?api=1&query=$lat,$lon');
  await canLaunchUrl(googleUrl)
      ? await launchUrl(googleUrl)
      : throw 'No se puede abrir $googleUrl';
}

class _CalenderScreenStateAdmin extends State<CalenderScreenAdmin> {
  final AttendanceServiceadmin obtenerObs = AttendanceServiceadmin();
  final SupabaseClient supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _readStream;

  final controller = ScrollController();
  String todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
  var sizeicono = 20.0;
  var sizeletra = 12.0;
  String idSelected = 'abb73b57-f573-44b7-81cb-bf952365688b';
  UserModel? userModel;
  int? employeeDepartment;

  @override
  void initState() {
    super.initState();
    _readStream = supabase
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', "$idSelected")
        .order('id', ascending: false);
    todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
    controller.addListener(() {
      if (controller.position.maxScrollExtent == controller.offset) {
        fetch();
      }
    });
  }

  Future fetch() async {
    setState(() {});
  }
////////////////////////

  Future<List<AttendanceModel>> getAttendanceHistory(
      String fechaAsistencia) async {
    final List data = await supabase
        .from(Constants.attendancetable)
        .select()
        .eq('employee_id', "$idSelected")
        .textSearch('date', "'$fechaAsistencia'")
        .order('created_at', ascending: false);
    return data
        .map((attendance) => AttendanceModel.fromJson(attendance))
        .toList();
  }

  Future<List<ObsModel>> getObsHistory(String fecha) async {
    final List obsdata = await supabase
        .from(Constants.obstable)
        .select()
        .eq('user_id', "$idSelected")
        .textSearch('date', "'$fecha'")
        .order('created_at', ascending: false);
    ;
    return obsdata.map((obs) => ObsModel.fromJson(obs)).toList();
  }

  Future obtenerHistorialAsistencia(String fecha) async {
    List<AttendanceModel> historialAsistencia =
        await getAttendanceHistory(fecha);
    for (AttendanceModel attendance in historialAsistencia) {
      List<ObsModel> obsHistory = await getObsHistory(fecha);
      var dataList = _filterpormes2(obsHistory, attendance.createdAt);
      if (dataList.isNotEmpty) {
        if (dataList.length == 0) {
          print('no hay datos');
        }
        var titlesJoined = "";
        for (int j = 0; j < dataList.length; j++) {
          titlesJoined += dataList[j].title.toString();
          if (j != dataList.length - 1) {
            titlesJoined += ", ";
          }
        }
        updateObs(titlesJoined, attendance.createdAt, attendance.id);
      } else if (dataList.length == 0) {
        updateObs("null", attendance.createdAt, attendance.id);
      }
    }
  }

  List<dynamic> _filterpormes(List<dynamic> datalist, DateTime fecha) {
    final filteredList = datalist.where((element) {
      final createdAt = DateTime.parse(element['created_at']);
      final format = DateFormat('dd MMMM yyyy', "ES_es");
      final fechaObs = format.format(createdAt);
      final fechaAsistencia = format.format(fecha);
      return fechaObs == fechaAsistencia;
    }).toList();
    print('{---------------------------------}');
    print(filteredList);
    return filteredList;
  }

  List<ObsModel> _filterpormes2(List<ObsModel> datalistEn, DateTime fecha) {
    final filteredList = datalistEn.where((element) {
      final createdAt = DateTime.parse(element.create_at.toString());
      final format = DateFormat('dd MMMM yyyy', "ES_es");
      final fechaObs = format.format(createdAt);
      final fechaAsistencia = format.format(fecha);
      return fechaObs == fechaAsistencia;
    }).toList();

    return filteredList;
  }

  Future updateObs(String cadenaUnida, DateTime fechaDeAsis, String id) async {
    final format = DateFormat('dd MMMM yyyy', "ES_es");
    final fechaAsistenciaO = format.format(fechaDeAsis);
    try {
      await supabase
          .from(Constants.attendancetable)
          .update({
            'obs': cadenaUnida,
          })
          .eq("employee_id", id)
          .eq('date', fechaAsistenciaO)
          .select();
      if (mounted) {}
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }



  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceService =
        prove.Provider.of<AttendanceServiceadmin>(context);
    final dbService = prove.Provider.of<DbServiceadmin>(context);
    dbService.allempleados.isEmpty ? dbService.getAllempleados() : null;
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: const Text(
            "Mi Asistencia",
            style: TextStyle(fontSize: 22),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            dbService.allempleados.isEmpty
                ? SizedBox(width: 60, child: const LinearProgressIndicator())
                : Container(
                    margin: const EdgeInsets.only(
                        left: 5, top: 5, bottom: 10, right: 10),
                    height: widthSize50,
                    width: widthsize300,
                    child: DropdownButtonFormField(
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      value: dbService.empleadolista,
                      items: dbService.allempleados.map((UserModel item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.name.toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedValue) {
                        setState(() {
                          attendanceService.attendanceusuario =
                              selectedValue.toString();
                          idSelected = selectedValue.toString();
                          _readStream = supabase
                              .from('todos')
                              .stream(primaryKey: ['id'])
                              .eq('user_id', "$idSelected")
                              .order('id', ascending: false);
                        });
                      },
                    ),
                  ),
            Text(
              attendanceService.attendanceHistoryMonth,
              style: const TextStyle(fontSize: fontsize25),
            ),
            OutlinedButton(
                onPressed: () async {
                  final selectedDate =
                      await SimpleMonthYearPicker.showMonthYearPickerDialog(
                          backgroundColor: AdaptiveTheme.of(context).mode ==
                                  AdaptiveThemeMode.light
                              ? Colors.white
                              : Colors.black,
                          selectionColor: AdaptiveTheme.of(context).mode ==
                                  AdaptiveThemeMode.light
                              ? Colors.blue
                              : Colors.white,
                          context: context,
                          disableFuture: true);
                  String pickedMonth =
                      DateFormat("MMMM yyyy", "ES_es").format(selectedDate);
                  attendanceService.attendanceHistoryMonth = pickedMonth;
                },
                child: const Text("Seleccionar mes")),
            ElevatedButton(
              onPressed: () {
                obtenerHistorialAsistencia(
                    attendanceService.attendanceHistoryMonth);
              },
              child: Text(
                'Generar',
                style: TextStyle(
                  fontSize: 16, // Puedes ajustar el tamaño del texto
                ),
              ),
            )
          ],
        ),
        Expanded(
            child: FutureBuilder(
                future: attendanceService.getAttendanceHistory(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.length > 0) {
                      return ListView.builder(
                          itemCount: snapshot.data.length,
                          itemBuilder: (context, index) {
                            AttendanceModel attendanceData =
                                snapshot.data[index];
                            return Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(
                                      top: 12, left: 20, right: 20, bottom: 10),
                                  height: heightContainer,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.white
                                          //  color: Colors.white,
                                          : Color.fromARGB(255, 43, 41, 41),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Color.fromARGB(
                                                110, 18, 148, 255),
                                            blurRadius: 10,
                                            offset: Offset(2, 2)),
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                          child: Container(
                                        width: widthSize50,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            DateFormat("EE \n dd", "es_ES")
                                                .format(
                                                    attendanceData.createdAt),
                                            style: const TextStyle(
                                                fontSize: fontsize18,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )),
                                      Expanded(
                                        child: Column(children: [
                                          Container(
                                            height: 20,
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Nombre:",
                                                    style: TextStyle(
                                                      decorationThickness: 2.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: fontsize15,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.light
                                                          ? Colors.black
                                                          //  color: Colors.white,
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: heightSize10,
                                                  ),
                                                  Text(
                                                    attendanceData.usuario ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontsize15,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.light
                                                          ? Colors.black
                                                          //  color: Colors.white,
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ]),
                                          ),
                                          const SizedBox(
                                            child: Divider(),
                                          ),
                                          Expanded(
                                              child: Row(children: [
                                            Expanded(
                                                child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.apartment_sharp,
                                                      size: sizeicono,
                                                    ),
                                                    Text(
                                                      attendanceData.obra
                                                              ?.toString() ??
                                                          '--/--',
                                                      style: TextStyle(
                                                        fontSize: fontsize12,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.light
                                                            ? Colors.black
                                                            //  color: Colors.white,
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: heightSize10,
                                                  child: Divider(),
                                                ),
                                                Expanded(
                                                    child: Row(children: [
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "Ingreso: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  fontsize13,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                          Text(
                                                            attendanceData
                                                                    .checkIn
                                                                    ?.toString() ??
                                                                '--/--',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  fontsize12,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: heightSize10,
                                                        width: heightSize80,
                                                        child: Divider(),
                                                      ),
                                                      Expanded(
                                                        child: ReadMoreText(
                                                          attendanceData.lugar_1
                                                                  ?.toString() ??
                                                              '--/--',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  sizeletra),
                                                          trimLines: 5,
                                                          // colorClickableText: Colors.pink,
                                                          trimMode:
                                                              TrimMode.Line,
                                                          trimCollapsedText:
                                                              '...Leer mas',
                                                          trimExpandedText:
                                                              ' Menos',
                                                        ),
                                                      ),
                                                    ],
                                                  )),

                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(
                                                            Icons.location_on,
                                                            size: sizeicono,
                                                          ),
                                                          onPressed: () {
                                                            var lat = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkInLocation!)
                                                                .latitude;
                                                            var lon = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkInLocation!)
                                                                .longitude;

                                                            _openmap(
                                                                lat.toString(),
                                                                lon.toString());
                                                          }),
                                                      Container(
                                                        child: attendanceData
                                                                    .pic_in ==
                                                                null
                                                            ? Icon(Icons.photo)
                                                            : attendanceData
                                                                        .pic_in ==
                                                                    "NULL"
                                                                ? const CircularProgressIndicator()
                                                                : Container(
                                                                    height:
                                                                        heightImage115,
                                                                    width:
                                                                        heightImage90,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(15)),
                                                                      image:
                                                                          DecorationImage(
                                                                        fit: BoxFit
                                                                            .fill,
                                                                        image:
                                                                            CachedNetworkImageProvider(
                                                                          attendanceData
                                                                              .pic_in
                                                                              .toString(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                      ),
                                                    ],
                                                  )),

                                                  /////////
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "Salida: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  fontsize13,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                          Text(
                                                            attendanceData
                                                                    .checkOut
                                                                    ?.toString() ??
                                                                '--/--',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  fontsize12,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                        width: 80,
                                                        child: Divider(),
                                                      ),
                                                      Expanded(
                                                        child: ReadMoreText(
                                                          attendanceData.lugar_2
                                                                  ?.toString() ??
                                                              '--/--',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  sizeletra),
                                                          trimLines: 5,
                                                          // colorClickableText: Colors.pink,
                                                          trimMode:
                                                              TrimMode.Line,
                                                          trimCollapsedText:
                                                              '...Leer mas',
                                                          trimExpandedText:
                                                              ' Menos',
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(
                                                            Icons.location_on,
                                                            size: sizeicono,
                                                          ),
                                                          onPressed: () {
                                                            var lat = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkOutLocation!)
                                                                .latitude;
                                                            var lon = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkOutLocation!)
                                                                .longitude;

                                                            _openmap(
                                                                lat.toString(),
                                                                lon.toString());
                                                          }),
                                                      Container(
                                                        child: attendanceData
                                                                    .pic_out ==
                                                                null
                                                            ? Icon(Icons.photo)
                                                            : attendanceData
                                                                        .pic_out ==
                                                                    "NULL"
                                                                ? const CircularProgressIndicator()
                                                                : Container(
                                                                    height:
                                                                        heightImage115,
                                                                    width:
                                                                        heightImage90,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(15)),
                                                                      image:
                                                                          DecorationImage(
                                                                        fit: BoxFit
                                                                            .fill,
                                                                        image:
                                                                            CachedNetworkImageProvider(
                                                                          attendanceData
                                                                              .pic_out
                                                                              .toString(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                      ),
                                                    ],
                                                  )),
                                                ])),
                                              ],
                                            )),
                                            const SizedBox(
                                              height: 10,
                                              width: 5,
                                            ),
                                            Expanded(
                                                child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.apartment_sharp,
                                                      size: sizeicono,
                                                    ),
                                                    Text(
                                                      attendanceData.obra2
                                                              ?.toString() ??
                                                          '--/--',
                                                      style: TextStyle(
                                                        fontSize: fontsize12,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.light
                                                            ? Colors.black
                                                            //  color: Colors.white,
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                  child: Divider(),
                                                ),
                                                Expanded(
                                                    child: Row(children: [
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "Ingreso: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  fontsize13,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                          Text(
                                                            attendanceData
                                                                    .checkIn2
                                                                    ?.toString() ??
                                                                '--/--',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  fontsize12,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                        width: 80,
                                                        child: Divider(),
                                                      ),
                                                      Expanded(
                                                        child: ReadMoreText(
                                                          attendanceData.lugar_3
                                                                  ?.toString() ??
                                                              '--/--',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  sizeletra),
                                                          trimLines: 5,
                                                          // colorClickableText: Colors.pink,
                                                          trimMode:
                                                              TrimMode.Line,
                                                          trimCollapsedText:
                                                              '...Leer mas',
                                                          trimExpandedText:
                                                              ' Menos',
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(
                                                            Icons.location_on,
                                                            size: sizeicono,
                                                          ),
                                                          onPressed: () {
                                                            var lat = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkInLocation2!)
                                                                .latitude;
                                                            var lon = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkInLocation2!)
                                                                .longitude;

                                                            _openmap(
                                                                lat.toString(),
                                                                lon.toString());
                                                          }),
                                                      Container(
                                                        child: attendanceData
                                                                    .pic_in2 ==
                                                                null
                                                            ? Icon(Icons.photo)
                                                            : attendanceData
                                                                        .pic_in2 ==
                                                                    "NULL"
                                                                ? const CircularProgressIndicator()
                                                                : Container(
                                                                    height:
                                                                        heightImage115,
                                                                    width:
                                                                        heightImage90,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(15)),
                                                                      image:
                                                                          DecorationImage(
                                                                        fit: BoxFit
                                                                            .fill,
                                                                        image:
                                                                            CachedNetworkImageProvider(
                                                                          attendanceData
                                                                              .pic_in2
                                                                              .toString(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                      ),
                                                    ],
                                                  )),
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "Salida: ",
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  fontsize13,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                          Text(
                                                            attendanceData
                                                                    .checkOut2
                                                                    ?.toString() ??
                                                                '--/--',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  fontsize12,
                                                              color: Theme.of(context)
                                                                          .brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors.black
                                                                  //  color: Colors.white,
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                        width: 80,
                                                        child: Divider(),
                                                      ),
                                                      Expanded(
                                                        child: ReadMoreText(
                                                          attendanceData.lugar_4
                                                                  ?.toString() ??
                                                              '--/--',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  sizeletra),
                                                          trimLines: 5,
                                                          // colorClickableText: Colors.pink,
                                                          trimMode:
                                                              TrimMode.Line,
                                                          trimCollapsedText:
                                                              '...Leer mas',
                                                          trimExpandedText:
                                                              ' Menos',
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                                  Expanded(
                                                      child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                          icon: Icon(
                                                            Icons.location_on,
                                                            size: sizeicono,
                                                          ),
                                                          onPressed: () {
                                                            var lat = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkOutLocation2!)
                                                                .latitude;
                                                            var lon = UbiModel.fromJson(
                                                                    attendanceData
                                                                        .checkOutLocation2!)
                                                                .longitude;

                                                            _openmap(
                                                                lat.toString(),
                                                                lon.toString());
                                                          }),
                                                      Container(
                                                        child: attendanceData
                                                                    .pic_out2 ==
                                                                null
                                                            ? Icon(Icons.photo)
                                                            : attendanceData
                                                                        .pic_out2 ==
                                                                    "NULL"
                                                                ? const CircularProgressIndicator()
                                                                : Container(
                                                                    height:
                                                                        heightImage115,
                                                                    width:
                                                                        heightImage90,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .rectangle,
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                              Radius.circular(15)),
                                                                      image:
                                                                          DecorationImage(
                                                                        fit: BoxFit
                                                                            .fill,
                                                                        image:
                                                                            CachedNetworkImageProvider(
                                                                          attendanceData
                                                                              .pic_out2
                                                                              .toString(),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                      ),
                                                    ],
                                                  )),
                                                ])),
                                              ],
                                            )),
                                          ])),
                                        ]),
                                      ),
                                      Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          width: widthObs,
                                          child: Column(
                                            children: [
                                              Text(
                                                ' Observaciones',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: fontsize15,
                                                ),
                                              ),

                                              ///////////////
                                              Expanded(
                                                  child: StreamBuilder(
                                                      stream: _readStream,
                                                      builder:
                                                          (BuildContext context,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        if (snapshot.hasError) {
                                                          return Center(
                                                            child: Text(
                                                                'Error:' +
                                                                    snapshot
                                                                        .error
                                                                        .toString() +
                                                                    '\nRecargue la pagina, por favor.',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center),
                                                          );
                                                        }

                                                        if (snapshot.hasData) {
                                                          if (snapshot.data
                                                                  .length ==
                                                              0) {
                                                            return const Center(
                                                              child: const Text(
                                                                  "No se han agregado observaciones"),
                                                            );
                                                          }

                                                          final dataList =
                                                              _filterpormes(
                                                                  snapshot.data,
                                                                  attendanceData
                                                                      .createdAt);

                                                          if (dataList
                                                              .isNotEmpty) {
                                                            if (dataList
                                                                    .length ==
                                                                0) {
                                                              return const Center(
                                                                child: const Text(
                                                                    "Aun no ha subido observaciones adentro."),
                                                              );
                                                            }

                                                            var titlesJoined =
                                                                "";
                                                            for (int i = 0;
                                                                i <
                                                                    dataList
                                                                        .length;
                                                                i++) {
                                                              titlesJoined +=
                                                                  dataList[i]
                                                                      ['title'];
                                                              if (i !=
                                                                  dataList.length -
                                                                      1) {
                                                                titlesJoined +=
                                                                    ", ";
                                                              }
                                                            }

                                                            updateObs(
                                                                titlesJoined,
                                                                attendanceData
                                                                    .createdAt,
                                                                attendanceData
                                                                    .id);

                                                            return ListView
                                                                .builder(
                                                                    itemCount:
                                                                        dataList
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            int index) {
                                                                      var data =
                                                                          dataList[
                                                                              index];
                                                                      return ListTile(
                                                                        title: Container(
                                                                            padding: const EdgeInsets.all(2),
                                                                            margin: const EdgeInsets.symmetric(
                                                                              vertical: 2,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color: Colors.lightBlue.withOpacity(0.2),
                                                                              borderRadius: BorderRadius.circular(10),
                                                                            ),
                                                                            child: Text(
                                                                              data['title'] ?? '',
                                                                              overflow: TextOverflow.visible,
                                                                              style: TextStyle(fontSize: fontsize15),
                                                                            )),
                                                                        subtitle: Text(
                                                                            data['horain'] ??
                                                                                '',
                                                                            style:
                                                                                TextStyle(fontSize: fontsize10)),
                                                                      );
                                                                    });
                                                          } else if (dataList
                                                                  .length ==
                                                              0) {
                                                            updateObs(
                                                                "null",
                                                                attendanceData
                                                                    .createdAt,
                                                                attendanceData
                                                                    .id);

                                                            return const Center(
                                                              child: const Text(
                                                                  "No se han agregado observaciones en este día"),
                                                            );
                                                          }
                                                          return const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          );
                                                        }
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      })),

                                              /////////////
                                            ],
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          });
                    } else {
                      return const Center(
                        child: Text(
                          "Datos no disponibles",
                          style: TextStyle(fontSize: fontsize25),
                        ),
                      );
                    }
                  }
                  return const LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    color: Colors.grey,
                  );
                })),

///////////

////
      ],
    );
  }
}
