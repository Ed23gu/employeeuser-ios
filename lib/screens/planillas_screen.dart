import 'dart:core';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/helper/save_file_mobile.dart'
    if (dart.library.html) 'package:employee_attendance/helper/save_file_web.dart'
    as helper;
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/models/obs_model.dart';
import 'package:employee_attendance/models/user_model.dart';
import 'package:employee_attendance/screens/observaciones/observaciones_page.dart';
import 'package:employee_attendance/services/attendance_service_admin.dart';
import 'package:employee_attendance/services/db_service_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:open_document/my_files/init.dart';
import 'package:provider/provider.dart' as route;
import 'package:simple_month_year_picker/simple_month_year_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;

class PlanillaScreen extends StatefulWidget {
  const PlanillaScreen({super.key});

  @override
  State<PlanillaScreen> createState() => _PlanillaScreenState();
}

class _PlanillaScreenState extends State<PlanillaScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final bool allowFiltering;
  String selectedName = '';
  int? selectedpas;
  String selectedProyecto = '';
  String fecha = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
  int selectedOption = 246; // Opción seleccionada inicialmente
  String todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
  late EmployeeDataSource _employeeDataSource =
      EmployeeDataSource(employeeData: []);
  List<Employee> _employees = <Employee>[];
  String idSelected = 'abb73b57-f573-44b7-81cb-bf952365688b';
  final controller = ScrollController();
  final GlobalKey<SfDataGridState> _key = GlobalKey<SfDataGridState>();

  Future fetch() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    todayDate = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
    fecha = DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());
    controller.addListener(() {
      if (controller.position.maxScrollExtent == controller.offset) {
        fetch();
      }
    });
    getEmployeeDataFromSupabase().then((employeeList) {
      setState(() {
        _employees = employeeList;
        _employeeDataSource = EmployeeDataSource(employeeData: _employees);
        _employeeDataSource.addFilter(
          'Dia2',
          FilterCondition(
            value: fecha,
            filterOperator: FilterOperator.and,
            type: FilterType.equals,
          ),
        );
      });
    });
  }

  Future<List<AttendanceModel>> getAttendanceHistory(
      String fechaAsistencia) async {
    final List data = await _supabase
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
    final List obsdata = await _supabase
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
        await updateObs(titlesJoined, attendance.createdAt, attendance.id);
      } else if (dataList.length == 0) {
        await updateObs("null", attendance.createdAt, attendance.id);
      }
    }
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
      await _supabase
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

  Future<void> _exportDataGridToPdf(
      String periodo, String nombre, String proyecto) async {
    final PdfDocument document = PdfDocument();

    document.pageSettings.orientation = PdfPageOrientation.landscape;
    PdfPage pdfpage = document.pages.add();

    PdfPageTemplateElement header = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 40));

    PdfDateTimeField dateAndTimeField = PdfDateTimeField(
        font: PdfStandardFont(PdfFontFamily.timesRoman, 12),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)));

    PdfCompositeField compositefields = PdfCompositeField(
      font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      brush: PdfSolidBrush(PdfColor(0, 102, 255)),
      text:
          '                                       ArtConsgroup. Cia. Ltda. Asistencia',
    );

    compositefields.draw(header.graphics,
        Offset(0, 20 - PdfStandardFont(PdfFontFamily.helvetica, 12).height));
    header.graphics.drawString(
      'Proyecto: ' + proyecto,
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(170, 28, 200, 60),
    );
    header.graphics.drawString(
      'Periodo: ' + periodo,
      // '\n Fecha:' + DateFormat.yMMMd().format(DateTime.now()),
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(400, 28, 200, 60),
    );
    header.graphics.drawString(
      'Nombre: ' + nombre,
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 28, 200, 60),
    );

    document.template.top = header;

//Create the footer with specific bounds
    PdfPageTemplateElement footer = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50));

//Create the page number field
    PdfPageNumberField pageNumber = PdfPageNumberField(
        font: PdfStandardFont(PdfFontFamily.timesRoman, 11),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)));

//Sets the number style for page number
    pageNumber.numberStyle = PdfNumberStyle.upperRoman;

//Create the page count field
    PdfPageCountField count = PdfPageCountField(
        font: PdfStandardFont(PdfFontFamily.timesRoman, 11),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)));

//set the number style for page count
    count.numberStyle = PdfNumberStyle.upperRoman;

//Create the date and time field
    PdfDateTimeField dateTimeField = PdfDateTimeField(
        font: PdfStandardFont(PdfFontFamily.timesRoman, 11),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)));

//Sets the date and time format

    dateAndTimeField.date = DateTime.now();

    dateTimeField.dateFormatString = 'MM.dd.yyyy';

//Create the composite field with page number page count
    PdfCompositeField compositeField = PdfCompositeField(
        font: PdfStandardFont(PdfFontFamily.timesRoman, 11),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        text: 'Pagina: {0},  Fecha:{1}',
        fields: <PdfAutomaticField>[pageNumber, dateTimeField]);
    compositeField.bounds = footer.bounds;

//Add the composite field in footer
    compositeField.draw(footer.graphics,
        Offset(290, 50 - PdfStandardFont(PdfFontFamily.timesRoman, 11).height));

//Add the footer at the bottom of the document
    document.template.bottom = footer;
    // Calcular el ancho de las columnas

    PdfGrid pdfGrid = _key.currentState!.exportToPdfGrid(
      cellExport: (details) {
        if (details.cellType == DataGridExportCellType.columnHeader) {
          details.pdfCell.style.backgroundBrush = PdfBrushes.skyBlue;
          details.pdfCell.style.font =
              PdfStandardFont(PdfFontFamily.timesRoman, 11);
        }
        if (details.cellType == DataGridExportCellType.row) {
          details.pdfCell.style.font =
              PdfStandardFont(PdfFontFamily.timesRoman, 10);
        }
      },
      excludeColumns: const <String>['id', 'Dia2', 'TotalHoras'],
      exportTableSummaries: true,
      exportStackedHeaders: false,
      fitAllColumnsInOnePage: true,
      autoColumnWidth: true,
    );
    pdfGrid.columns[0].width = 25;
    pdfGrid.columns[1].width = 55;
    pdfGrid.columns[2].width = 60;
    pdfGrid.columns[3].width = 45;
    pdfGrid.columns[4].width = 45;
    pdfGrid.columns[5].width = 45;
    pdfGrid.columns[6].width = 60;
    pdfGrid.columns[7].width = 45;
    pdfGrid.columns[8].width = 45;
    pdfGrid.columns[9].width = 45;
    pdfGrid.columns[10].width = 45;

    pdfGrid.draw(
      page: pdfpage,
      bounds: Rect.fromLTWH(0, 0, 0, 0),
    );

    final List<int> bytes = document.saveSync();
    await helper.saveAndLaunchFile(
        bytes, 'Asis' + '_' + '$nombre' + '_' + '$periodo.pdf');
    document.dispose();
  }

////////////////////////////////////
  Future<void> _exportDataGridToExcel(
      String periodo, String nombre, String proyecto) async {
    final Workbook workbook = _key.currentState!.exportToExcelWorkbook(
        excludeColumns: const <String>['id', 'Dia2', 'TotalHoras'],
        exportStackedHeaders: true);
    final Worksheet sheet = workbook.worksheets[0];
    final Style style = workbook.styles.add('style');
    final Style style2 = workbook.styles.add('style2');
    style2.borders.bottom.color = '#829193';
    style.bold = true;
    style.hAlign = HAlignType.center;
    style2.borders.all.lineStyle = LineStyle.thick;
    style2.borders.bottom.lineStyle = LineStyle.thin;
    sheet.getRangeByName('A1:K1').cellStyle = style;
    sheet.getRangeByName('A1:K1').text = 'Nomina de Asistencias';
    sheet.insertRow(2, 1, ExcelInsertOptions.formatAsAfter);

    sheet.getRangeByName('A2').cellStyle = style;
    sheet.getRangeByName('D2').cellStyle = style;
    sheet.getRangeByName('G2').cellStyle = style;
    sheet.getRangeByName('A3:K3').cellStyle = style2;
    sheet.getRangeByName('A3:K3').cellStyle = style;
    sheet.getRangeByName('B2:C2').merge();
    sheet.getRangeByName('E2:F2').merge();
    sheet.getRangeByName('H2:I2').merge();
    sheet.getRangeByName('A2').text = 'Nombre:';
    sheet.getRangeByName('B2').text = '$nombre';
    sheet.getRangeByName('D2').text = 'Proyecto';
    sheet.getRangeByName('E2').text = '$proyecto';
    sheet.getRangeByName('G2').text = 'Periodo';
    sheet.getRangeByName('H2').text = '$periodo';

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    await helper.saveAndLaunchFile(
        bytes, 'Asis' + '_' + '$nombre' + '_' + '$periodo.xlsx');
  }

  Future<List<Employee>> getEmployeeDataFromSupabase() async {
    try {
      final response = await _supabase
          .from(Constants.attendancetable)
          .select()
          .order('created_at', ascending: false);
      if (response != null) {
        final data = response as List<dynamic>;
        final employeeList = data
            .map((e) => Employee(
                  e['employee_id'].toString(),
                  e['date'].toString(),
                  e['created_at'].toString() != "null"
                      ? e['created_at']
                      : "null",
                  e['obraid'].toString(),
                  e['check_in'].toString() != "null" ? e['check_in'] : "null",
                  e['check_out'].toString() != "null" ? e['check_out'] : "null",
                  e['obraid2'].toString(),
                  e['check_in2'].toString() != "null" ? e['check_in2'] : "null",
                  e['check_out2'].toString() != "null"
                      ? e['check_out2']
                      : "null",
                  e['obs'].toString(),
                ))
            .toList();
        return employeeList;
      } else {
        throw Exception('Error al obtener los datos de empleados');
      }
    } catch (error) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceService =
        route.Provider.of<AttendanceServiceadmin>(context);
    final dbService = route.Provider.of<DbServiceadmin>(context);
    dbService.allempleados.isEmpty ? dbService.getAllempleados() : null;
    dbService.allDepartments.isEmpty ? dbService.getAllDepartments() : null;

    return Scaffold(
        body: Column(
          children: [
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 20, top: 15, bottom: 5),
              child: const Text(
                "Resumen de Asistencias",
                style: TextStyle(fontSize: 17),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                dbService.allempleados.isEmpty
                    ? SizedBox(
                        width: 60, child: const LinearProgressIndicator())
                    : Container(
                        height: 50,
                        width: 240,
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          value: dbService.empleadolista,
                          items: dbService.allempleados.map((UserModel item) {
                            return DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name.toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (selectedValue) {
                            fetch();
                            getEmployeeDataFromSupabase().then((employeeList) {
                              setState(() {
                                _employees = employeeList;
                                _employeeDataSource = EmployeeDataSource(
                                    employeeData: _employees);
                                _employeeDataSource.addFilter(
                                  'Dia2',
                                  FilterCondition(
                                    value: fecha,
                                    filterOperator: FilterOperator.and,
                                    type: FilterType.equals,
                                  ),
                                );
                                _employeeDataSource.addFilter(
                                    'id',
                                    FilterCondition(
                                        type: FilterType.equals,
                                        value: dbService.empleadolista));
                              });
                            });

                            setState(() {
                              dbService.empleadolista =
                                  selectedValue.toString();
                              idSelected = selectedValue.toString();
                              _employeeDataSource.clearFilters();
                              _employeeDataSource.addFilter(
                                  'id',
                                  FilterCondition(
                                      type: FilterType.equals,
                                      value: dbService.empleadolista));

                              selectedName = dbService.allempleados
                                  .firstWhere(
                                      (element) => element.id == selectedValue)
                                  .name
                                  .toString();
                              selectedpas = dbService.allempleados
                                  .firstWhere(
                                      (element) => element.id == selectedValue)
                                  .department;
                              selectedProyecto = dbService.allDepartments
                                  .firstWhere(
                                      (element) => element.id == selectedpas)
                                  .title;
                            });
                            obtenerHistorialAsistencia(fecha);
                            fetch();
                          },
                        ),
                      ),
                Container(
                  width: 40,
                ),
                Text(
                  fecha == '' ? "--/--" : fecha,
                  style: const TextStyle(fontSize: 15),
                ),
                Container(
                  width: 40,
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
                          DateFormat('MMMM yyyy', "es_ES").format(selectedDate);
                      setState(() {
                        fecha = pickedMonth;
                        _employeeDataSource.clearFilters();
                        _employeeDataSource.addFilter(
                          'id',
                          FilterCondition(
                            value: dbService.empleadolista,
                            // filterOperator: FilterOperator.and,
                            type: FilterType.equals,
                          ),
                        );
                        _employeeDataSource.addFilter(
                          'Dia2',
                          FilterCondition(
                            value: fecha,
                            filterOperator: FilterOperator.and,
                            type: FilterType.equals,
                          ),
                        );
                      });
                    },
                    child: const Text("Mes",
                        style: const TextStyle(fontSize: 15))),
                Container(
                  width: 40,
                ),
                Container(
                  margin: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        height: 40.0,
                        width: 150.0,
                        child: MaterialButton(
                            color: Colors.blue,
                            onPressed: () async {
                              await _exportDataGridToExcel(
                                  attendanceService.attendanceHistoryMonth,
                                  selectedName,
                                  selectedProyecto);
                            },
                            child: const Center(
                                child: Text(
                              'Export to Excel',
                              style: TextStyle(color: Colors.white),
                            ))),
                      ),
                      const Padding(padding: EdgeInsets.all(20)),
                      SizedBox(
                        height: 40.0,
                        width: 150.0,
                        child: MaterialButton(
                            color: Colors.blue,
                            onPressed: () async {
                              await _exportDataGridToPdf(
                                  fecha, selectedName, selectedProyecto);
                            },
                            child: const Center(
                                child: Text(
                              'Exportar a PDF',
                              style: TextStyle(color: Colors.white),
                            ))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
                child: SfDataGridTheme(
              data: SfDataGridThemeData(),
              child: SfDataGrid(
                key: _key,
                source: _employeeDataSource,
                rowHeight: 50,
                headerRowHeight: 30,
                tableSummaryRows: [
                  GridTableSummaryRow(
                      showSummaryInRow: false,
                      title: 'Dias trabajados: {Count2}',
                      titleColumnSpan: 6,
                      columns: [
                        GridSummaryColumn(
                            name: 'Count2',
                            columnName: 'TotalHoras',
                            summaryType: GridSummaryType.count),
                      ],
                      position: GridTableSummaryRowPosition.bottom),
                ],

                columnWidthCalculationRange:
                    ColumnWidthCalculationRange.allRows,
                //allowFiltering: true,
                allowSorting: true,
                allowMultiColumnSorting: true,
                columnWidthMode: ColumnWidthMode.fill,
                //  gridLinesVisibility: GridLinesVisibility.both,
                headerGridLinesVisibility: GridLinesVisibility.both,
                //allowTriStateSorting: true,
                columns: [
                  GridColumn(
                      columnName: 'id',
                      visible: false,
                      label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ID',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Dia2',
                      visible: false,
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dia2',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Dia',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dia',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Fecha',
                      allowFiltering: false,
                      allowSorting: true,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Fecha',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Proyecto',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Proyecto',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'HoraIn',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ingreso',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'HoraOut',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Salida',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'SubTH1',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'subHoras',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Proyecto2',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Proyecto',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'HoraIn2',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ingreso',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'HoraOut2',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Salida',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'SubTH2',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'subHoras',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'TotalHoras',
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total Horas',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Total',
                      visible: false,
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total de Horas',
                            overflow: TextOverflow.ellipsis,
                          ))),
                  GridColumn(
                      columnName: 'Observacion',
                      // visible: false,
                      width: 500,
                      allowFiltering: false,
                      allowSorting: false,
                      label: Container(

                          // padding: EdgeInsets.symmetric(horizontal: 5.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Observación',
                            overflow: TextOverflow.ellipsis,
                          ))),
                ],
                stackedHeaderRows: <StackedHeaderRow>[
                  StackedHeaderRow(cells: [
                    StackedHeaderCell(
                        columnNames: [
                          'id',
                          'Dia2',
                          'Dia',
                          'Fecha',
                          'Proyecto',
                          'HoraIn',
                          'HoraOut',
                          'SubTH1',
                          'Proyecto2',
                          'HoraIn2',
                          'HoraOut2',
                          'SubTH2',
                          'TotalHoras',
                          'Total',
                          'Observacion'
                        ],
                        child: Container(
                            // color: Colors.cyan[200],
                            child: const Center(
                                child: Text('NOMINA DE ASISTENCIA')))),
                  ])
                ],
                selectionMode: SelectionMode.multiple,
              ),
            )),
          ],
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

            //add more menu item childs here
          ],
        ));
  }
}

class EmployeeDataSource extends DataGridSource {
  /// Creates the employee data source class with required details.
  String obtenerSumaDeTiempo(
      String HoraOut, String HoraIn, String HoraOut2, String HoraIn2) {
    if (HoraIn == "null" || HoraOut == "null") {
      if (HoraIn2 == "null" || HoraOut2 == "null") {
        return Tiempo2('00:00', '00:00', '00:00', '00:00')
            .obtenerSumadeTiempo()
            .toString();
      } else {
        return Tiempo2('00:00', '00:00', HoraOut2, HoraIn2)
            .obtenerSumadeTiempo()
            .toString();
      }
    } else {
      if (HoraIn2 == "null" || HoraOut2 == "null") {
        return Tiempo2(HoraOut, HoraIn, '00:00', '00:00')
            .obtenerSumadeTiempo()
            .toString();
      } else {
        return Tiempo2(HoraOut, HoraIn, HoraOut2, HoraIn2)
            .obtenerSumadeTiempo()
            .toString();
      }
    }
  }

  String obtenerSumaDeTiempo2(
      String HoraOut, String HoraIn, String HoraOut2, String HoraIn2) {
    if (HoraIn == "null" || HoraOut == "null") {
      if (HoraIn2 == "null" || HoraOut2 == "null") {
        return Tiempo3('00:00', '00:00', '00:00', '00:00')
            .obtenerSumadeTiempoenminutos()
            .toString();
      } else {
        return Tiempo3('00:00', '00:00', HoraOut2, HoraIn2)
            .obtenerSumadeTiempoenminutos()
            .toString();
      }
    } else {
      if (HoraIn2 == "null" || HoraOut2 == "null") {
        return Tiempo3(HoraOut, HoraIn, '00:00', '00:00')
            .obtenerSumadeTiempoenminutos()
            .toString();
      } else {
        return Tiempo3(HoraOut, HoraIn, HoraOut2, HoraIn2)
            .obtenerSumadeTiempoenminutos()
            .toString();
      }
    }
  }

  EmployeeDataSource({required List<Employee> employeeData}) {
    _employeeData = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: e.id),
              DataGridCell<String>(
                  columnName: 'Dia2', value: e.Dia2.toString().substring(3)),
              DataGridCell<String>(
                  columnName: 'Dia',
                  value: Diadelasemana(e.Fecha).obtenerdia().toString()),
              DataGridCell<String>(
                  columnName: 'Fecha', value: e.Fecha.split('T')[0].toString()),
              DataGridCell<String>(columnName: 'Proyecto', value: e.Proyecto),
              DataGridCell<String>(columnName: 'HoraIn', value: e.HoraIn),
              DataGridCell<String>(columnName: 'HoraOut', value: e.HoraOut),
              DataGridCell<String>(
                  columnName: 'SubTH1',
                  value: (e.HoraIn == "null" || e.HoraOut == "null")
                      ? "00:00"
                      : Tiempo(e.HoraOut, e.HoraIn)
                          .obtenerDiferenciaTiempo()
                          .toString()),
              DataGridCell<String>(columnName: 'Proyecto2', value: e.Proyecto2),
              DataGridCell<String>(columnName: 'HoraIn2', value: e.HoraIn2),
              DataGridCell<String>(columnName: 'HoraOut2', value: e.HoraOut2),
              DataGridCell<String>(
                  columnName: 'SubTH2',
                  value: (e.HoraIn2 == "null" || e.HoraOut2 == "null")
                      ? "00:00"
                      : Tiempo(e.HoraOut2, e.HoraIn2)
                          .obtenerDiferenciaTiempo()
                          .toString()),
              DataGridCell<String>(
                  columnName: 'Total',
                  value: obtenerSumaDeTiempo(
                      e.HoraOut, e.HoraIn, e.HoraOut2, e.HoraIn2)),
              DataGridCell<int>(
                  columnName: 'TotalHoras',
                  value: int.parse(obtenerSumaDeTiempo2(
                      e.HoraOut, e.HoraIn, e.HoraOut2, e.HoraIn2))),
              DataGridCell<String>(columnName: 'Observacion', value: e.lugar_1),
            ]))
        .toList();
  }

  List<DataGridRow> _employeeData = [];

  @override
  List<DataGridRow> get rows => _employeeData;
  @override
  Widget? buildTableSummaryCellWidget(
    GridTableSummaryRow summaryRow,
    GridSummaryColumn? summaryColumn,
    RowColumnIndex rowColumnIndex,
    String summaryValue,
  ) {
    return Container(
      padding: EdgeInsets.all(15.0),
      child: Text(summaryValue),
    );
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }
}

class Diadelasemana {
  String inghora;

  Diadelasemana(this.inghora);

  String obtenerdia() {
    /* DateTime horaOutDateTime = DateFormat('EEE').parse();
    String resultado =  horaOutDateTime.toString();*/

    DateTime dateTime = DateTime.parse(inghora);
    DateFormat dateFormat = DateFormat('E', "es_ES");
    String resultado = dateFormat.format(dateTime);

    return resultado;
  }
}

class Minutosahoras {
  String inhora;

  Minutosahoras(this.inhora);

  String obtenerhoras() {
    int i = int.parse(inhora);
    Duration duracion = Duration(minutes: i);
    String horasf = '${duracion.inHours}';
    String minuf =
        '${duracion.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    String resultados = horasf + ":" + minuf;
    return resultados;
  }
}

class Tiempo {
  String horaOut;
  String horaIn;

  Tiempo(this.horaOut, this.horaIn);

  String obtenerDiferenciaTiempo() {
    DateTime horaOutDateTime = DateFormat('HH:mm').parse(horaOut);
    DateTime horaInDateTime = DateFormat('HH:mm').parse(horaIn);
    Duration diferenciaTiempo = horaOutDateTime.difference(horaInDateTime);
    String horas = '${diferenciaTiempo.inHours}';
    String minutos =
        '${diferenciaTiempo.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    String resultado = horas + ":" + minutos;
    return resultado;
  }
}

class Tiempo3 {
  String horaOut;
  String horaIn;
  String horaOut2;
  String horaIn2;

  Tiempo3(this.horaOut, this.horaIn, this.horaOut2, this.horaIn2);

  String obtenerSumadeTiempoenminutos() {
    DateTime horaOutDateTime = DateFormat('HH:mm').parse(horaOut);
    DateTime horaInDateTime = DateFormat('HH:mm').parse(horaIn);
    DateTime horaOutDateTime2 = DateFormat('HH:mm').parse(horaOut2);
    DateTime horaInDateTime2 = DateFormat('HH:mm').parse(horaIn2);
    Duration diferenciaTiempo = horaOutDateTime.difference(horaInDateTime);
    Duration diferenciaTiempo2 = horaOutDateTime2.difference(horaInDateTime2);
    Duration sumaHoras = diferenciaTiempo + diferenciaTiempo2;

    String sumaminutos1 = '${sumaHoras.inMinutes}';

    return sumaminutos1;
  }
}

class Tiempo2 {
  String horaOut;
  String horaIn;
  String horaOut2;
  String horaIn2;

  Tiempo2(this.horaOut, this.horaIn, this.horaOut2, this.horaIn2);

  String obtenerSumadeTiempo() {
    DateTime horaOutDateTime = DateFormat('HH:mm').parse(horaOut);
    DateTime horaInDateTime = DateFormat('HH:mm').parse(horaIn);
    DateTime horaOutDateTime2 = DateFormat('HH:mm').parse(horaOut2);
    DateTime horaInDateTime2 = DateFormat('HH:mm').parse(horaIn2);
    Duration diferenciaTiempo = horaOutDateTime.difference(horaInDateTime);
    Duration diferenciaTiempo2 = horaOutDateTime2.difference(horaInDateTime2);
    Duration sumaHoras = diferenciaTiempo + diferenciaTiempo2;
    String sumahoras = '${sumaHoras.inHours}';
    String sumaminutos =
        '${sumaHoras.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    String resultado = sumahoras + ":" + sumaminutos;
    return resultado;
  }
}

class Employee {
  /// Creates the employee class with required details.
  Employee(this.id, this.Dia2, this.Fecha, this.Proyecto, this.HoraIn,
      this.HoraOut, this.Proyecto2, this.HoraIn2, this.HoraOut2, this.lugar_1);

  final String id;
  final String Dia2;
  final String Fecha;
  final String Proyecto;
  final String HoraIn;
  final String HoraOut;
  final String Proyecto2;
  final String HoraIn2;
  final String HoraOut2;
  final String lugar_1;
}
