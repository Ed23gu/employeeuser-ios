import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/models/department_model.dart';
import 'package:employee_attendance/models/obs_model.dart';
import 'package:employee_attendance/models/user_model.dart';
import 'package:employee_attendance/services/location_service.dart';
import 'package:employee_attendance/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceServiceadmin extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  DepartmentModel? depModel2;
  DepartmentModel? depModel22;
  var ubiModel;
  AttendanceModel? attendanceModel;
  String? employeename;
  String? obra2;
  String? employeename2;
  String? obra22;
  UserModel? userModel;
  UserModel? userModel2;
  UserModel? userModel22;
  AttendanceModel? userModel3;
  int? employeeDepartment;
  int? employeeDepartment2;

  String todayDate = DateFormat("dd MMMM yyyy", "es_ES").format(DateTime.now());

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _attendanceusuario = 'abb73b57-f573-44b7-81cb-bf952365688b';

  String get attendanceusuario => _attendanceusuario;

  set attendanceusuario(String value) {
    _attendanceusuario = value;
    notifyListeners();
  }

  String _attendanceHistoryMonth =
      DateFormat("MMMM yyyy", "es_ES").format(DateTime.now());

  String get attendanceHistoryMonth => _attendanceHistoryMonth;

  set attendanceHistoryMonth(String value) {
    _attendanceHistoryMonth = value;
    notifyListeners();
  }

  Future getTodayAttendance() async {
    final List result = await _supabase
        .from(Constants.attendancetable)
        .select()
        .eq("employee_id", "$attendanceusuario")
        .eq('date', todayDate);
    if (result.isNotEmpty) {
      attendanceModel = AttendanceModel.fromJson(result.first);
    }
    notifyListeners();
  }

//////////////////////
  Future<UserModel> getUserData() async {
    final userData = await _supabase
        .from(Constants.employeeTable)
        .select()
        .eq('id', "$attendanceusuario")
        .single();
    userModel = UserModel.fromJson(userData);
    // Since this function can be called multiple times, then it will reset the dartment value
    // That is why we are using condition to assign only at the first time
    employeeDepartment == null
        ? employeeDepartment = userModel?.department
        : null;
    return userModel!;
  }

  Future markAttendance(BuildContext context) async {
    final userData = await _supabase
        .from(Constants.employeeTable)
        .select()
        .eq('id', _attendanceusuario)
        .single();
    userModel = UserModel.fromJson(userData);
    // Since this function can be called multiple times, then it will reset the dartment value
    // That is why we are using condition to assign only at the first time
    employeeDepartment == null
        ? employeeDepartment = userModel?.department
        : null;
    employeename == null ? employeename = userModel?.name : null;

    final List result2 = await _supabase
        .from(Constants.departmentTable)
        .select()
        .eq("id", employeeDepartment);
    depModel2 = DepartmentModel.fromJson(result2.first);

    Map? getLocation =
        await LocationService().initializeAndGetLocation(context);
    // print("Location Data :");
    //print(getLocation);
    if (getLocation != null) {
      if (attendanceModel?.checkIn == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              //'employee_id': _supabase.auth.currentUser!.id,
              //'date': todayDate,
              'check_in': DateFormat('HH:mm').format(DateTime.now()),
              'check_in_location': getLocation,
              'obraid': depModel2!.title,
              'nombre_asis': userModel!.name,
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else if (attendanceModel?.checkOut == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_out': DateFormat('HH:mm').format(DateTime.now()),
              'check_out_location': getLocation,
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else {
        Utils.showSnackBar("Hora de Salida ya Resgistrada !", context);
      }
      getTodayAttendance();
    } else {
      Utils.showSnackBar("No se puede obtener su ubicacion", context,
          color: Colors.blue);
      getTodayAttendance();
    }
  }

  Future markAttendance3(BuildContext context) async {
    getTodayAttendance();
  }

  Future markAttendance2(BuildContext context) async {
    final userData2 = await _supabase
        .from(Constants.employeeTable)
        .select()
        .eq('id', _supabase.auth.currentUser!.id)
        .single();
    userModel2 = UserModel.fromJson(userData2);
    // Since this function can be called multiple times, then it will reset the dartment value
    // That is why we are using condition to assign only at the first time
    employeeDepartment2 == null
        ? employeeDepartment2 = userModel2?.department
        : null;
    employeename2 == null ? employeename2 = userModel2?.name : null;

    final List result32 = await _supabase
        .from(Constants.departmentTable)
        .select()
        .eq("id", employeeDepartment2);
    depModel22 = DepartmentModel.fromJson(result32.first);

    Map? getLocation =
        await LocationService().initializeAndGetLocation(context);
    //print("Location Data2 :");
    // print(getLocation);
    if (getLocation != null) {
      if (attendanceModel?.checkIn2 == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_in2': DateFormat('HH:mm').format(DateTime.now()),
              'check_in_location2': getLocation,
              'obraid2': depModel22!.title,
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else if (attendanceModel?.checkOut2 == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_out2': DateFormat('HH:mm').format(DateTime.now()),
              'check_out_location2': getLocation,
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else {
        Utils.showSnackBar("Hora de Salida ya Resgistrada !", context);
      }
      getTodayAttendance();
    } else {
      Utils.showSnackBar("No se puede obtener su ubicacion", context,
          color: Colors.blue);
      getTodayAttendance();
    }
  }

  Future<List<AttendanceModel>> getAttendanceHistory() async {
    final List data = await _supabase
        .from(Constants.attendancetable)
        .select()
        // .eq('employee_id', _supabase.auth.currentUser!.id)
        .eq('employee_id', "$attendanceusuario")
        .textSearch('date', "'$attendanceHistoryMonth'")
        .order('created_at', ascending: false);
    return data
        .map((attendance) => AttendanceModel.fromJson(attendance))
        .toList();
  }

  Future<List<ObsModel>> getObsHistory(String fecha) async {
    final List obsdata = await _supabase
        .from(Constants.obstable)
        .select()
        .eq('user_id', "$attendanceusuario")
        .textSearch('date', "'$fecha'")
        .order('created_at', ascending: false);

    //getTodayAttendance();
    return obsdata.map((obs) => ObsModel.fromJson(obs)).toList();
  }

  Future<List<ObsModel>> getObsHistoryParaActualizar(String fecha) async {
    final List obsdata = await _supabase
        .from(Constants.obstable)
        .select()
        .eq('user_id', "$attendanceusuario")
        //.textSearch('date', '23 October 2023', config: 'english')
        .textSearch('date', "'$fecha'")
        .order('created_at', ascending: false);

    //getTodayAttendance();
    return obsdata.map((obs) => ObsModel.fromJson(obs)).toList();
  }
}
