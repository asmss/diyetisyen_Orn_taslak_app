import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/app/app.dart';
import 'package:mobile_app/core/bootstrap/bootstrap.dart';

Future<void> main() async {
  await initializeDateFormatting('tr_TR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrapper.ensureInitialized();
  runApp(const DietitianDemoApp());
}
