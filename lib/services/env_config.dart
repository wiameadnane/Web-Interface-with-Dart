import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EnvConfig {
  static late DotEnv _env;
  static bool _initialized = false;

  static Future<void> load() async {
    if (_initialized) return;

    _env = DotEnv();

    // Try to load from .env file
    final envFile = File('.env');
    if (await envFile.exists()) {
      _env.load();
      _initialized = true;
      print('✓ Environment variables loaded from .env file');
    } else {
      throw Exception('.env file not found!');
    }
  }

  static String get databaseUrl {
    if (!_initialized) {
      throw Exception('Environment not initialized. Call EnvConfig.load() first.');
    }

    final url = _env['DATABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('DATABASE_URL not found in .env file');
    }

    return url;
  }
}
