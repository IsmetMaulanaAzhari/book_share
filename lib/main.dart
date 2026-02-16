import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/providers/location_provider.dart';
import 'app/providers/book_provider.dart';
import 'modules/map/map_screen.dart';

void main() {
  runApp(const BookShareApp());
}

class BookShareApp extends StatelessWidget {
  const BookShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: MaterialApp(
        title: 'Book Share',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const MapScreen(),
      ),
    );
  }
}
