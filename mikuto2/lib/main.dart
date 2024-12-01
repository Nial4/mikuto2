import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tray_manager/tray_manager.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(300, 200),
    minimumSize: Size(300, 200),
    center: true,
    skipTaskbar: false, // ensure show in dock
    titleBarStyle: TitleBarStyle.normal,
  );

  // prevent window close
  await windowManager.setPreventClose(true);

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // set tray icon
  await trayManager.setIcon('assets/toilet-paper.png');

  // set initial text
  await trayManager.setTitle('Loading...');

  // init tray menu
  Menu menu = Menu(
    items: [
      MenuItem(
        label: '退出',
        onClick: (_) async {
          await trayManager.destroy();
          exit(0);
        },
      ),
    ],
  );
  await trayManager.setContextMenu(menu);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener, WindowListener {
  String vacancyStatus = "Loading...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _fetchVacancyStatus();
    // update every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchVacancyStatus();
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _timer?.cancel();
    super.dispose();
  }

  // handle window close event
  @override
  void onWindowClose() async {
    await windowManager.minimize();
    await windowManager.setPreventClose(true);
  }

  // handle tray double click event
  @override
  void onTrayIconMouseUp() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.minimize();
    } else {
      await windowManager.restore();
      await windowManager.focus();
    }
  }

  Future<void> _fetchVacancyStatus() async {
    try {
      final response = await http.get(Uri.parse('your throne api url'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final String countText = data[0]['countText'];
          // convert free count to used count
          final parts = countText.split('/');
          if (parts.length == 2) {
            final total = int.parse(parts[1]);
            final free = int.parse(parts[0]);
            final used = total - free;
            final newCountText = '$used/$total';

            setState(() {
              vacancyStatus = newCountText;
            });

            await trayManager.setTitle(newCountText);
          }
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        await trayManager.setTitle('Error');
      }
    } catch (e) {
      print('Error details: $e');
      await trayManager.setTitle('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🚽',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Have Good Time',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vacancyStatus,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 10,
              bottom: 10,
              child: Text(
                'by Nial4',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
