import 'package:employee_attendance/examples/value_notifier/warning_widget_value_notifier.dart';
import 'package:employee_attendance/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _esoculto;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _esoculto = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: WarningWidgetValueNotifier(),
          titleTextStyle: TextStyle(fontSize: 12)),
      // resizeToAvoidBottomInset: false
      body: Center(
          child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image(image: AssetImage('assets/images/arts.png'), height: 100),
                const SizedBox(
                  height: 50,
                ),
                TextField(
                  decoration: const InputDecoration(
                    label: Text("Email"),
                    prefixIcon: Icon(Icons.person),
                  ),
                  controller: _emailController,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  decoration: InputDecoration(
                    label: Text("Contraseña"),

                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _esoculto = !_esoculto;
                          });
                        },
                        icon: _esoculto
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off_outlined)),
                    prefixIcon: Icon(Icons.lock),
                    //  border: OutlineInputBorder(),
                  ),
                  controller: _passwordController,
                  obscureText: _esoculto,
                ),
                const SizedBox(
                  height: 25,
                ),
                Consumer<AuthService>(
                  builder: (context, authServiceProvider, child) {
                    return SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: authServiceProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                authServiceProvider.loginEmployee(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    context);
                              },
                              child: const Text(
                                "LOGIN",
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                /*TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("Eres Nuevo? Registrate aquí")) */
              ],
            ),
          ),
        ),
      )),
    );
  }
}
