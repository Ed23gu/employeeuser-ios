import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:employee_attendance/constants/gaps.dart';
import 'package:employee_attendance/examples/value_notifier/warning_widget_value_notifier.dart';
import 'package:employee_attendance/screens/attendance_screen.dart';
import 'package:employee_attendance/screens/calender_screen.dart';
import 'package:employee_attendance/screens/perfil/perfil_admin.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _page = 1;
  var pad16 = 16.0;
  var pad8 = 8.0;
  var pad4 = 4.0;
  var anchodeart = 40.0;

  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        leading: Builder(builder: (BuildContext context) {
          return Row(
            children: [
              gapW16,
              SizedBox(
                  child: Center(
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: anchodeart,
                ),
              )),
            ],
          );
        }),
        title: const Text(
          "ArtconsGroup.",
          style: TextStyle(
            fontSize: fontsize28,
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _page,
            children: const [
              CalenderScreen(),
              AttendanceScreen(),
              AccountPageAdmin()
            ],
          ),
          WarningWidgetValueNotifier(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 1,
        height: altoBar55,
        items: <Widget>[
          Icon(Icons.calendar_today, size: sizeiconobar27),
          Icon(Icons.list, size: sizeiconobar27),
          Icon(Icons.person_outline_sharp, size: sizeiconobar27),
        ],
        color: Theme.of(context).colorScheme.tertiaryContainer,
        buttonBackgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
