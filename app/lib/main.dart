import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

/// App entry point. [ProviderScope] holds every Riverpod provider
/// (database, repositories, services) for the lifetime of the app.
void main() {
  runApp(const ProviderScope(child: EBuCardApp()));
}
