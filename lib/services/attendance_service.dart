import 'dart:io';

import 'package:employee_attendance/constants/constants.dart';
import 'package:employee_attendance/models/attendance_model.dart';
import 'package:employee_attendance/models/department_model.dart';
import 'package:employee_attendance/models/user_model.dart';
import 'package:employee_attendance/services/app_exceptions.dart';
import 'package:employee_attendance/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService extends ChangeNotifier {
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

  String address = " ";

  String todayDate = DateFormat("dd MMMM yyyy", "es_ES").format(DateTime.now());

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _attendanceusuario = ' ';

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
    try {
      final List result = await _supabase
          .from(Constants.attendancetable)
          .select()
          .eq("employee_id", _supabase.auth.currentUser!.id)
          .eq('date', todayDate);
      if (result.isNotEmpty) {
        attendanceModel = AttendanceModel.fromJson(result.first);
      }
      notifyListeners();
    } on SocketException {
      throw FetchDataException('mensaje enviado');
    } on PostgrestException {
      return Future.error("No se pudo conectar al servidor");
    } catch (e) {
      return Future.error("Error inesperado");
    }
  }

//////////////////////
  Future<UserModel> getUserData() async {
    final userData = await _supabase
        .from(Constants.employeeTable)
        .select()
        .eq('id', _supabase.auth.currentUser!.id)
        .single();
    userModel = UserModel.fromJson(userData);

    employeeDepartment == null
        ? employeeDepartment = userModel?.department
        : null;
    return userModel!;
  }

  Future markAttendance(BuildContext context) async {
    try {
      final userData = await _supabase
          .from(Constants.employeeTable)
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      userModel = UserModel.fromJson(userData);
      employeeDepartment == null
          ? employeeDepartment = userModel?.department
          : null;
      employeename == null ? employeename = userModel?.name : null;

      final List result2 = await _supabase
          .from(Constants.departmentTable)
          .select()
          .eq("id", employeeDepartment);
      depModel2 = DepartmentModel.fromJson(result2.first);

      Position? getLocation = await _determinePosition();
      String ubicacion = await obtenerNombreUbicacion(getLocation);

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
              'lugar_1': ubicacion
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else if (attendanceModel?.checkOut == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_out': DateFormat('HH:mm').format(DateTime.now()),
              'check_out_location': getLocation,
              'lugar_2': ubicacion
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else {
        Utils.showSnackBar("Hora de Salida ya Resgistrada !", context);
      }

      getTodayAttendance();
    } on SocketException {
      Utils.showSnackBar(
          "Hubo un problema de conexión, Por favor intentelo nuevamente.",
          context,
          color: Colors.red);
    } on PostgrestException {
      Utils.showSnackBar(
          "Algo ha salido mal, Por favor intentelo nuevamente.", context,
          color: Colors.red);
    } catch (e) {
      Utils.showSnackBar(
          "Algo ha salido mal, Por favor intentelo nuevamente.", context,
          color: Colors.red);
    }
  }

  Future markAttendance3(BuildContext context) async {
    getTodayAttendance();
  }

  Future markAttendance2(BuildContext context) async {
    try {
      final userData2 = await _supabase
          .from(Constants.employeeTable)
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      userModel2 = UserModel.fromJson(userData2);
      employeeDepartment2 == null
          ? employeeDepartment2 = userModel2?.department
          : null;
      employeename2 == null ? employeename2 = userModel2?.name : null;
      final List result32 = await _supabase
          .from(Constants.departmentTable)
          .select()
          .eq("id", employeeDepartment2);
      depModel22 = DepartmentModel.fromJson(result32.first);

      Position? getLocation = await _determinePosition();

      String ubicacion = await obtenerNombreUbicacion(getLocation);
      if (attendanceModel?.checkIn2 == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_in2': DateFormat('HH:mm').format(DateTime.now()),
              'check_in_location2': getLocation,
              'obraid2': depModel22!.title,
              'lugar_3': ubicacion
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else if (attendanceModel?.checkOut2 == null) {
        await _supabase
            .from(Constants.attendancetable)
            .update({
              'check_out2': DateFormat('HH:mm').format(DateTime.now()),
              'check_out_location2': getLocation,
              'lugar_4': ubicacion
            })
            .eq('employee_id', _supabase.auth.currentUser!.id)
            .eq('date', todayDate);
      } else {
        Utils.showSnackBar("Hora de Salida ya Resgistrada !", context);
      }
      getTodayAttendance();
    } on SocketException {
      Utils.showSnackBar(
          "Hubo un problema de conexión, Por favor intentelo nuevamente.",
          context,
          color: Colors.red);
    } on PostgrestException {
      Utils.showSnackBar(
          "Algo ha salido mal, Por favor intentelo nuevamente.", context,
          color: Colors.red);
    } catch (e) {
      Utils.showSnackBar(
          "Algo ha salido mal, Por favor intentelo nuevamente.", context,
          color: Colors.red);
    }
  }

  Future<List<AttendanceModel>> getAttendanceHistory() async {
    try {
      final List data = await _supabase
          .from(Constants.attendancetable)
          .select()
          .eq('employee_id', _supabase.auth.currentUser!.id)
          .textSearch('date', "'$attendanceHistoryMonth'")
          .order('created_at', ascending: false);
      return data
          .map((attendance) => AttendanceModel.fromJson(attendance))
          .toList();
    } on PostgrestException {
      return Future.error("Algo ha salido mal, intentelo nuevamente");
    } catch (e) {
      return Future.error("Algo ha salido mal, intentelo nuevamente");
    }
  }

  Future<String> obtenerNombreUbicacion(Position position) async {
    String posicion = position.toString().replaceAll(",", "");
    var lat = double.parse(posicion.split(' ')[1]);
    var log = double.parse(posicion.split(' ')[3]);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, log);
      if (placemarks.isNotEmpty) {
        Placemark placeMark = placemarks[4];
        Placemark placeMark2 = placemarks[0];
        String? subLocality = placeMark.subLocality;
        String? locality = placeMark.locality;
        //String? administrativeArea = placeMark.administrativeArea;
        String? subadministrativeArea = placeMark.subAdministrativeArea;
        // String? postalCode = placeMark.postalCode;
        //String? country = placeMark.country;
        String? thoroughfare = placeMark.thoroughfare;
        String? street = placeMark2.street;

        address =
            "$street,$thoroughfare,$subLocality,$locality,$subadministrativeArea";
      } else {
        address = 'No se pudo obtener el nombre de la ubicación.';
      }
    } catch (e) {
      address = 'Error de conexión.';
    }
    return address;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("El servicio de Ubicación esta desabilitada");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('El permiso de ubicación esta denegada');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos. Otorgue permisos manualmente');
    }

    return await Geolocator.getCurrentPosition();
  }
}
