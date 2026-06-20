import 'package:flutter/material.dart';

import 'app/dimensional_app.dart';
import 'core/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.restore();
  runApp(const DimensionalApp());
}
