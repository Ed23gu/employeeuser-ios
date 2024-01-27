import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_month_year_picker/simple_month_year_picker.dart';

class CalenderScreen extends StatefulWidget {
  const CalenderScreen({super.key});

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  var padd0 = 0.0;
  var padd4 = 4.0;
  var padd8 = 8.0;
  var padd12 = 12.0;
  var padd16 = 16.0;
  var padd20 = 20.0;
  var altoContainer = 90.0;
  var anchoDia = 42.0;
  var sizeicono = 22.0;
  var fontSizetitulo = 15.0;
  var fontSizeinfo = 12.0;

  @override
  Widget build(BuildContext context) {
    final attendanceService = Provider.of<AttendanceService>(context);
    return Scaffold(
        body: Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(padd16, padd4, padd16, padd4),
          alignment: Alignment.centerLeft,
          child: const Text(
            "Registro de Asitencias",
            style: const TextStyle(
                fontSize: fontsize22, fontWeight: FontWeight.bold),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          gapW16,
          ElevatedButton(
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
                        disableFuture: true
                        );

                String pickedMonth =
                    DateFormat("MMMM yyyy", "ES_es").format(selectedDate);
                attendanceService.attendanceHistoryMonth = pickedMonth;
              },
              child: const Text(
                "Seleccionar mes",
                style: const TextStyle(fontSize: 16),
              )),
          Container(
            padding: EdgeInsets.fromLTRB(padd16, padd4, padd16, padd4),
            child: Text(
              attendanceService.attendanceHistoryMonth,
              style: const TextStyle(fontSize: sizecomentarios16),
            ),
          ),
        ]),
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
                            return Container(
                              margin: EdgeInsets.only(
                                  top: padd8,
                                  left: padd16,
                                  right: padd16,
                                  bottom: padd8),
                              height: altoContainer,
                              decoration: BoxDecoration(
                                  color: AdaptiveTheme.of(context).mode ==
                                          AdaptiveThemeMode.light
                                      ? Colors.white
                                      //  color: Colors.white,
                                      : Color.fromARGB(255, 43, 41, 41),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Color.fromARGB(110, 18, 148, 255),
                                        blurRadius: 5,
                                        offset: Offset(2, 2)),
                                  ],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: anchoDia,
                                    decoration: BoxDecoration(
                                      color: AdaptiveTheme.of(context).mode ==
                                              AdaptiveThemeMode.light
                                          ? Color(0xFFCDE5FF)
                                          : Color(0xFF00639A),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        DateFormat("EE \n dd", "es_ES")
                                            .format(attendanceData.createdAt),
                                        style: TextStyle(
                                            fontSize: sizesalin,
                                            color: AdaptiveTheme.of(context)
                                                        .mode ==
                                                    AdaptiveThemeMode.light
                                                ? Color(0xFF006689)
                                                : Color(0xFFFFFFFF),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(children: [
                                      Expanded(
                                          child: Row(children: [
                                        Expanded(
                                            child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                                child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.apartment_sharp,
                                                  size: sizeicono,
                                                ),
                                                Container(
                                                    height: padd20,
                                                    margin: EdgeInsets.fromLTRB(
                                                        padd8,
                                                        padd8,
                                                        padd8,
                                                        padd8),
                                                    child: Text(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: false,
                                                      attendanceData.obra
                                                              ?.toString() ??
                                                          '--/--',
                                                      style: TextStyle(
                                                        fontSize: fontSizeinfo,
                                                      ),
                                                    )),
                                              ],
                                            )),
                                            linea,
                                            Expanded(
                                                child: Row(children: [
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  gapH4,
                                                  Text(
                                                    "Ingreso",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: fontSizetitulo,
                                                    ),
                                                  ),
                                                  gapH4,
                                                  Text(
                                                    attendanceData.checkIn
                                                            ?.toString() ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontSizeinfo,
                                                    ),
                                                  )
                                                ],
                                              )),
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  gapH4,
                                                  Text(
                                                    "Salida",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: fontSizetitulo,
                                                    ),
                                                  ),
                                                  gapH4,
                                                  Text(
                                                    attendanceData.checkOut
                                                            ?.toString() ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontSizeinfo,
                                                    ),
                                                  )
                                                ],
                                              )),
                                            ])),
                                          ],
                                        )),
                                        gapW4,
                                        Expanded(
                                            child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                                child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.apartment_sharp,
                                                  size: sizeicono,
                                                ),
                                                Container(
                                                  height: padd20,
                                                  margin: EdgeInsets.fromLTRB(
                                                      padd8,
                                                      padd8,
                                                      padd8,
                                                      padd8),
                                                  child: Text(
                                                    attendanceData.obra2
                                                            ?.toString() ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontSizeinfo,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )),
                                            linea,
                                            Expanded(
                                                child: Row(children: [
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  gapH4,
                                                  Text(
                                                    "Ingreso",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: fontSizetitulo,
                                                    ),
                                                  ),
                                                  gapH4,
                                                  Text(
                                                    attendanceData.checkIn2
                                                            ?.toString() ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontSizeinfo,
                                                    ),
                                                  ),
                                                  gapH4,
                                                ],
                                              )),
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  gapH4,
                                                  Text(
                                                    "Salida",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: fontSizetitulo,
                                                    ),
                                                  ),
                                                  gapH4,
                                                  Text(
                                                    attendanceData.checkOut2
                                                            ?.toString() ??
                                                        '--/--',
                                                    style: TextStyle(
                                                      fontSize: fontSizeinfo,
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
                                ],
                              ),
                            );
                          });
                    } else {
                      return const Center(
                        child: Text(
                          "Datos no disponibles",
                          style: TextStyle(fontSize: fontsize22),
                        ),
                      );
                    }
                  }
                  return const LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    color: Colors.grey,
                  );
                })),

        // comentarios
      ],
    ));
  }
}
