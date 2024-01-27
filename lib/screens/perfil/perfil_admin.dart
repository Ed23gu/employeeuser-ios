import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/models/department_model.dart';
import 'package:employee_attendance/screens/perfil/avatar.dart';
import 'package:employee_attendance/services/auth_service.dart';
import 'package:employee_attendance/services/db_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as route;
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPageAdmin extends StatefulWidget {
  const AccountPageAdmin({super.key});

  @override
  State<AccountPageAdmin> createState() => _AccountPageStateAdmin();
}

class _AccountPageStateAdmin extends State<AccountPageAdmin> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _websiteController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final focusNode = FocusNode();
  final focusNode2 = FocusNode();

  String? _avatarUrl;
  var _loading = true;
  var anchoPerfil = 80.0;
  var altoPerfil = 80.0;
  var altoBoton50 = 50.0;
  var anchoBoton200 = 200.0;
  var pad16 = 16.0;
  var pad6 = 6.0;

  /// Called once a user id is received within `onAuthenticated()`
  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('employees')
          .select<Map<String, dynamic>>()
          .eq('id', userId)
          .single();
      setState(() {
        nameController.text = (data['name'] ?? '') as String;
        _websiteController.text = (data['website'] ?? '') as String;
        _avatarUrl = (data['avatar_url'] ?? '') as String;
      });
    } on PostgrestException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Ocurrio un error inesperado.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Called when image has been uploaded to Supabase storage from within Avatar widget
  Future<void> _onUpload(String imageUrl) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('employees').upsert({
        'id': userId,
        'avatar_url': imageUrl,
      });
      if (mounted) {
        const SnackBar(
          content: Text('Imagen de perfil actualizada.'),
        );
      }
    } on PostgrestException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Ocurrio un error inesperado'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _avatarUrl = imageUrl;
    });
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = route.Provider.of<DbService>(context);
    dbService.allDepartments.isEmpty ? dbService.getAllDepartments() : null;
    nameController.text.isEmpty
        ? nameController.text = dbService.userModel?.name ?? ''
        : null;
    return RefreshIndicator(
        onRefresh: () async {
          await _getProfile();
        },
        child: Scaffold(
            body: (_loading == true || dbService.userModel == null)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      gapH52,
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                      gapH52,
                      Container(
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                dbService.allDepartments.isEmpty
                                    ? dbService.getAllDepartments()
                                    : null;
                                nameController.text.isEmpty
                                    ? nameController.text =
                                        dbService.userModel?.name ?? ''
                                    : null;
                              });
                            },
                            icon: const Icon(
                              Icons.refresh_outlined,
                              size: widthSize50,
                            )),
                      ),
                      /*  ExpansionTile(
                    leading: Icon(Icons.brightness_6_outlined),
                    title: Text(
                      "Tema",
                      textAlign: TextAlign.left,
                    ),
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.wb_sunny),
                        title: Text("Claro"),
                        onTap: () {
                          AdaptiveTheme.of(context).setLight();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.brightness_2_outlined),
                        title: Text("Oscuro"),
                        onTap: () {
                          AdaptiveTheme.of(context).setDark();
                        },
                      )
                    ],
                  ), */
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(pad16, 6, pad16, pad16),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          // padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          children: [
                            Avatar(imageUrl: _avatarUrl, onUpload: _onUpload),
                            gapH16,
                            Text("Email: ${dbService.userModel?.email}"),
                            gapH16,
                            TextFormField(
                              onTapOutside: (event) async {
                                FocusScopeNode currentFocus =
                                    FocusScope.of(context);
                                if (!currentFocus.hasPrimaryFocus) {
                                  currentFocus.unfocus();
                                }
                              },
                              // autofocus: false,
                              controller: nameController,
                              decoration: const InputDecoration(
                                  label: Text("Nombre"),
                                  border: OutlineInputBorder()),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Por favor, rellene este campo.";
                                }
                                return null;
                              },
                            ),
                            gapH16,
                            TextFormField(
                              onTapOutside: (event) async {
                                FocusScopeNode currentFocus =
                                    FocusScope.of(context);
                                if (!currentFocus.hasPrimaryFocus) {
                                  currentFocus.unfocus();
                                }
                              },
                              // autofocus: false,
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                  label: Text("Cargo"),
                                  border: OutlineInputBorder()),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Por favor, rellene este campo.";
                                }
                                return null;
                              },
                            ),
                            gapH16,
                            dbService.allDepartments.isEmpty
                                ? const LinearProgressIndicator()
                                : SizedBox(
                                    width: double.infinity,
                                    child: DropdownButtonFormField(
                                      decoration: const InputDecoration(
                                          labelText: 'Departamento',
                                          border: OutlineInputBorder()),
                                      value: dbService.employeeDepartment ??
                                          dbService.allDepartments.first.id,
                                      items: dbService.allDepartments
                                          .map((DepartmentModel item) {
                                        return DropdownMenuItem(
                                            value: item.id,
                                            child: Text(
                                              item.title,
                                            ));
                                      }).toList(),
                                      onChanged: (selectedValue) {
                                        dbService.employeeDepartment =
                                            selectedValue;
                                      },
                                    ),
                                  ),
                            gapH8,
                            ElevatedButton(
                              onPressed: () {
                                final isValid =
                                    _formKey.currentState?.validate();
                                if (isValid != true) {
                                  return;
                                }
                                ;
                                dbService.updateProfile(
                                    nameController.text.trim(),
                                    _websiteController.text.trim(),
                                    context);
                              },
                              // onPressed: _loading ? null : _updateProfile,
                              child: Text(_loading
                                  ? 'Guardando...'
                                  : 'Actualizar Perfil'),
                            ),
                            Divider(),
                            ExpansionTile(
                              leading: Icon(Icons.brightness_6_outlined),
                              title: Text(
                                "Tema",
                                textAlign: TextAlign.left,
                              ),
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.wb_sunny),
                                  title: Text("Claro"),
                                  onTap: () {
                                    AdaptiveTheme.of(context).setLight();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.brightness_2_outlined),
                                  title: Text("Oscuro"),
                                  onTap: () {
                                    AdaptiveTheme.of(context).setDark();
                                  },
                                )
                              ],
                            ),
                            Divider(),
                            Container(
                              padding: EdgeInsets.only(left: pad6),
                              alignment: Alignment.topLeft,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      route.Provider.of<AuthService>(context,
                                              listen: false)
                                          .signOut();
                                    },
                                    icon: const Icon(Icons.logout),
                                  ),
                                  gapW16,
                                  Text(
                                    "Salir",
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )));
  }
}
