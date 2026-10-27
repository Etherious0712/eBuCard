import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as health;

/// Stand-in for the request context Dart Frog passes to each route.
class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  test('GET /health responds 200 with status ok', () async {
    final response = health.onRequest(_MockRequestContext());
    expect(response.statusCode, HttpStatus.ok);
    expect(await response.json(), {'status': 'ok'});
  });
}
