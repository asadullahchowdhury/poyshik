import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const PoyshikApp());
}

/// Root widget. Theme, router and localization arrive in steps 0.2–0.4.
class PoyshikApp extends StatelessWidget {
  const PoyshikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Poyshik',
      debugShowCheckedModeBanner: false,
      home: _PlaceholderScreen(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Poyshik',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
