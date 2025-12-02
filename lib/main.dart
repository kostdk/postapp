import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 1. Импорт делегатов
import 'package:intl/date_symbol_data_local.dart'; // 2. Импорт функции инициализации
import 'package:postapp/services/auth_check.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // --- ДОБАВЛЕНО ---
  // Инициализация данных локали для русского языка
  // 'ru' берется из supportedLocales ниже
  await initializeDateFormatting('ru', null); 
  // ------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthCheck(),
      
      // --- ДОБАВЛЕНО ---
      // Регистрация делегатов локализации для поддержки Material и Cupertino виджетов на русском
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Определение списка поддерживаемых языков
      supportedLocales: [
        Locale('en', ''), // English
        Locale('ru', ''), // Russian
      ],
      // ------------------
    );
  }
}
