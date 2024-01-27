import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/examples/value_notifier/warning_widget_value_notifier.dart';
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/services/obs_service.dart';
import 'package:employee_attendance/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_month_year_picker/simple_month_year_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComentariosPage extends StatefulWidget {
  const ComentariosPage({Key? key}) : super(key: key);

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _readStream;
  bool isLoading = false;
  bool isLoadingdel = false;
  TextEditingController titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ObsService obsfiltro = ObsService();
  String todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
  String todayDate2 =
      DateFormat("dd MMMM yyyy", "es_ES").format(DateTime.now());
  var margenSuperior = 5.0;
  var margenInferior = 5.0;
  var margenPanelfotos2 = 0.0;
  var anchofecha = 400.0;
  AttendanceModel? attendanceModel;

  @override
  void dispose() {
    titleController.dispose();
    supabase.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _readStream = supabase
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('id', ascending: false);
    todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
    super.initState();
  }

  void clearText() {
    titleController.clear();
  }

  List<dynamic> _filterpormes(List<dynamic> dataList, String fecha) {
    final filteredList = dataList.where((element) {
      final createdAt = DateTime.parse(element['created_at']);
      final format = DateFormat('MMMM yyyy', "ES_es");
      final monthYear = format.format(createdAt);
      return monthYear == fecha;
    }).toList();

    return filteredList;
  }

  Future insertData() async {
    setState(() {
      isLoading = true;
    });
    try {
      String userId = supabase.auth.currentUser!.id;
      await supabase.from('todos').insert({
        'title': titleController.text,
        'user_id': userId,
        'date': DateFormat("dd MMMM yyyy", "ES_es").format(DateTime.now()),
        'horain': DateFormat('HH:mm').format(DateTime.now()),
      });
      setState(() {
        isLoading = false;
      });
      clearText();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Observación guardada"),
          width: anchosmsalertaobs,
          duration: new Duration(seconds: 1),
          behavior: SnackBarBehavior.floating));
      //  Navigator.pop(context);
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Algo ha salido mal")));
    }
  }

  Future insertDataObs() async {
    String userId = supabase.auth.currentUser!.id;
    try {
      final List result = await supabase
          .from(Constants.attendancetable)
          .select()
          .eq("employee_id", userId)
          .eq('date', todayDate2);
      if (result.isNotEmpty) {
        attendanceModel = AttendanceModel.fromJson(result.first);
      } else {
        await supabase
            .from(Constants.attendancetable)
            .insert({"employee_id": userId, 'date': todayDate2});
      }
    } catch (error) {
      Utils.showSnackBar("$error", context);
    }
  }

  Future<void> _showMyDialog(int editId2) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Borrar esta observación?',
            style: TextStyle(fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Si'),
              onPressed: () {
                deleteData(editId2);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteData(int editId2) async {
    setState(() {
      isLoadingdel = true;
    });

    try {
      await supabase.from('todos').delete().match({'id': editId2});
      //Navigator.pop(context);
      isLoadingdel = false;         
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Observación borrada"),
        width: anchosmsalertaobs,
        duration: new Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      setState(() {
        isLoadingdel = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Algo ha salido mal!")));
    }
  }

  // Syntax to select data
  Future<List> readData() async {
    final result = await supabase
        .from('todos')
        .select()
        .eq(
          'user_id',
          supabase.auth.currentUser!.id,
        )
        //.eq('date', todayDate)
        .order('id', ascending: false);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Observaciones"),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _readStream = supabase
                      .from('todos')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false)
                      .eq(
                        'user_id',
                        supabase.auth.currentUser!.id,
                      );
                });
              },
              icon: const Icon(Icons.refresh_outlined)),
          gapW8
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WarningWidgetValueNotifier(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: anchoContainerobs,
              margin: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Color.fromARGB(255, 43, 41, 41),
                  boxShadow: [
                    BoxShadow(
                        color: Color.fromARGB(110, 18, 148, 255),
                        spreadRadius: 0.5,
                        blurRadius: 5,
                        offset: Offset(0, 1)),
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  gapW4,
                  ElevatedButton(
                      style: TextButton.styleFrom(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        final selectedDate = await SimpleMonthYearPicker
                            .showMonthYearPickerDialog(
                                backgroundColor:
                                    AdaptiveTheme.of(context).mode ==
                                            AdaptiveThemeMode.light
                                        ? Colors.white
                                        : Colors.black,
                                selectionColor:
                                    AdaptiveTheme.of(context).mode ==
                                            AdaptiveThemeMode.light
                                        ? Colors.blue
                                        : Colors.white,
                                context: context,
                                disableFuture: true);
                        String pickedMonth = DateFormat("MMMM yyyy", "ES_es")
                            .format(selectedDate);
                        setState(() {
                          todayDate = pickedMonth;
                        });
                      },
                      child: const Text(
                        "Seleccionar mes",
                      )),
                  gapW12,
                  Text(todayDate),
                  gapW12,
                ],
              ),
            ),
          ]),
          Expanded(
              child: StreamBuilder(
                  stream: _readStream,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Image.asset(
                              'assets/img/error.png',
                              width: imgenerror200,
                              height: imgenerror200,
                            ),
                            gapH8,
                            Text('Algo ha salido mal.',
                                textAlign: TextAlign.center),
                            gapH8,
                            Text('Recargue la pagina, por favor.',
                                textAlign: TextAlign.center),
                          ]));
                    }

                    if (snapshot.hasData) {
                      if (snapshot.data.length == 0) {
                        return const Center(
                          child: const Text("No se han agregado observaciones"),
                        );
                      }

                      final dataList = _filterpormes(snapshot.data, todayDate);
                      if (dataList.isNotEmpty) {
                        if (dataList.length == 0) {
                          return const Center(
                            child: const Text(
                                "Aun no ha subido observaciones adentro1"),
                          );
                        }

                        return ListView.builder(
                            itemCount: dataList.length,
                            itemBuilder: (context, int index) {
                              var data = dataList[index];

                              return ListTile(
                                  title: Container(
                                      padding: const EdgeInsets.all(6),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.cyan.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 4,
                                              offset: const Offset(2, 4)),
                                        ],
                                      ),
                                      child: Text(
                                        data['title'],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )),
                                  subtitle: Text(
                                      data['created_at']
                                          .split('.')[0]
                                          .replaceAll("T", "-")
                                          .toString(),
                                      style: TextStyle(
                                          color:
                                              AdaptiveTheme.of(context).mode ==
                                                      AdaptiveThemeMode.light
                                                  ? Colors.black45
                                                  : Colors.grey,
                                          fontSize: 12)),
                                  trailing: SizedBox(
                                    child: IconButton(
                                      onPressed: () {
                                        _showMyDialog(data['id']);
                                      },
                                      icon: Icon(Icons.delete_outline),
                                    ),
                                  ));
                            });
                      } else if (dataList.length == 0) {
                        return const Center(
                          child: const Text(
                              "No se han agregado observaciones en este mes"),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  })),
          Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 25.0, 15.0, 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextFormField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      controller: titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, rellene este campo.";
                        }
                        return null;
                      },
                      autofocus: false,
                      decoration: InputDecoration(
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(10),
                        hintText: "Ingrese aquí la observación del dia de hoy.",
                        hintStyle: TextStyle(fontSize: 12),
                        border: const OutlineInputBorder(),
                        suffixIcon: Align(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: IconButton(
                            icon: isLoading
                                ? CircularProgressIndicator()
                                : const Icon(Icons.send),
                            onPressed: () async {
                              FocusScopeNode currentFocus =
                                  FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                              ;
                              final isValid = _formKey.currentState?.validate();
                              if (isValid != true) {
                                return;
                              }
                              setState(() {
                                isLoading = true;
                              });
                              await insertDataObs();
                              await insertData();
                            },
                          ),
                        ),
                      ),
                    ),
                    gapH4
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
