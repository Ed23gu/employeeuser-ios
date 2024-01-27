import 'package:employee_attendance/services/db_service.dart';
import 'package:employee_attendance/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DbService _dbService = DbService();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future registerEmployee(
      String email, String password, BuildContext context) async {
    try {
      setIsLoading = true;
      if (email == "" || password == "") {
        throw ("Llene todos los campos");
      }
      final AuthResponse response =
          await _supabase.auth.signUp(email: email, password: password);
      await _dbService.insertNewUser(email, response.user!.id);

      Utils.showSnackBar("Registro Exitoso !", context, color: Colors.green);
      await loginEmployee(email, password, context);
      Navigator.pop(context);
    } catch (e) {
      setIsLoading = false;
      Utils.showSnackBar(
          "Asegurese de ingresar los datos correctamente", context,
          color: Colors.red);
    }
  }

  Future loginEmployee(
      String email, String password, BuildContext context) async {
    try {
      setIsLoading = true;
      if (email == "" || password == "") {
        throw ("Llene todos los campos");
      }
      await _supabase.auth.signInWithPassword(email: email, password: password);
      setIsLoading = false;
    } catch (e) {
      setIsLoading = false;
      Utils.showSnackBar(
          "Asegurese de ingresar los datos correctamente", context,
          color: Colors.red);
    }
  }

  Future signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
