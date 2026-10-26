import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as health;
import '../../routes/v1/cards/index.dart' as cards;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  test('GET /health responds 200 with status ok', () async {
    final response = health.onRequest(_MockRequestContext());
    expect(response.statusCode, HttpStatus.ok);
    expect(await response.json(), {'status': 'ok'});
  });

  test('stub endpoints respond 501 until implemented', () {
    final context = _MockRequestContext();
    when(
      () => context.request,
    ).thenReturn(Request.get(Uri.parse('http://localhost/v1/cards')));
    expect(cards.onRequest(context).statusCode, HttpStatus.notImplemented);
  });
}
