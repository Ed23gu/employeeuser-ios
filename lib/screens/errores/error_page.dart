import 'package:employee_attendance/constants/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final hasConnection = ConnectionNotifier.of(context).value;
    //final asset = hasConnection ? 'no-image' : 'illustration_wrong';
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // WarningWidgetValueNotifier(),
          SvgPicture.asset(
            'assets/nocone22.svg',
            width: imgenerror300,
            height: imgenerror300,
          ),
          gapH4,
          const Text('Sin Conexión.\n',
              style: TextStyle(
                //  color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: sizeresul17,
              )),
          RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                  style: TextStyle(
                      fontSize: fontsize13,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer),
                  children: <TextSpan>[
                    const TextSpan(text: 'Asegurese de:\n \n'),
                    const TextSpan(
                      text:
                          '     - Activar sus Datos mobiles o Wifi.\n     - Buscar un lugar con mejor cobertura. \n \n',
                    ),
                    const TextSpan(text: 'y vuelva a '),
                    const TextSpan(
                        text: 'intentarlo por favor.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ])),
        ],
      ),
    ));
  }
}
