import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'screens/recipe_home_page.dart';
// ignore: unused_import
import 'services/recipe_service.dart'; // Adjust import according to your project structure
import 'providers/recipe_provider.dart'; // Adjust import according to your project structure

void main() {
  // Set up logging
  Logger.root.level = Level.ALL; // Set the log level to ALL
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: const RecipeApp(),
    ),
  );
}

class RecipeApp extends StatelessWidget {
  // ignore: use_super_parameters
  const RecipeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecipeHomePage(),
    );
  }
}
