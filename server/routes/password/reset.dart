import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/html_page.dart';
import 'package:ebucard_server/src/services.dart';

/// `/password/reset?token=…`: the link in the password-reset email.
///
/// * `GET` shows a form for the new password.
/// * `POST` (the form) checks the password rules, sets it, signs the
///   account out everywhere, and shows a "password changed" page.
Future<Response> onRequest(RequestContext context) async {
  final strings = ServerStrings.of(
    localeFromHeader(context.request.headers['accept-language']),
  );
  final request = context.request;
  if (request.method == HttpMethod.get) {
    return _form(strings, request.uri.queryParameters['token'] ?? '');
  }
  if (request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final fields = Uri.splitQueryString(await request.body());
  final token = fields['token'] ?? '';
  final password = fields['password'] ?? '';
  if (password != fields['repeat']) {
    return _form(strings, token, error: strings.passwordsDiffer);
  }
  try {
    final problem = await context.read<Services>().accounts.resetPassword(
      token,
      password,
    );
    if (problem != null) {
      return _form(
        strings,
        token,
        error: switch (problem) {
          PasswordProblem.tooShort ||
          PasswordProblem.tooLong => strings.passwordTooShort,
          PasswordProblem.breached => strings.passwordBreached,
        },
      );
    }
  } on ApiException {
    return htmlPage(
      strings,
      strings.linkInvalidTitle,
      bodyHtml: '<p>${escapeHtml(strings.linkInvalidBody)}</p>',
      status: HttpStatus.badRequest,
    );
  }
  return htmlPage(
    strings,
    strings.resetDoneTitle,
    bodyHtml: '<p>${escapeHtml(strings.resetDoneBody)}</p>',
  );
}

/// The new-password form, with an optional [error] above it.
Response _form(ServerStrings strings, String token, {String? error}) =>
    htmlPage(
      strings,
      strings.resetTitle,
      status: error == null ? HttpStatus.ok : HttpStatus.badRequest,
      bodyHtml:
          '''
${error == null ? '' : '<p class="error">${escapeHtml(error)}</p>'}
<form method="post" action="/password/reset">
<input type="hidden" name="token" value="${escapeHtml(token)}">
<label for="password">${escapeHtml(strings.newPassword)}</label>
<input id="password" name="password" type="password" minlength="8" maxlength="128" autocomplete="new-password" required>
<label for="repeat">${escapeHtml(strings.repeatPassword)}</label>
<input id="repeat" name="repeat" type="password" minlength="8" maxlength="128" autocomplete="new-password" required>
<button type="submit">${escapeHtml(strings.resetButton)}</button>
</form>''',
    );
