// Sends the verification and password-reset emails.

import 'dart:developer' as developer;

import 'package:ebucard_server/src/config.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Sends plain-text emails. An interface so development and tests can
/// swap in [LogEmailSender] or a fake.
// ignore: one_member_abstracts
abstract class EmailSender {
  /// Sends [body] with [subject] to [to].
  Future<void> send({
    required String to,
    required String subject,
    required String body,
  });
}

/// Sends through an SMTP server (see [SmtpConfig]).
class SmtpEmailSender implements EmailSender {
  /// Creates a sender for [config].
  SmtpEmailSender(this.config);

  /// SMTP settings.
  final SmtpConfig config;

  @override
  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    final server = SmtpServer(
      config.host,
      port: config.port,
      username: config.username,
      password: config.password,
      ssl: config.ssl,
    );
    final message = mailer.Message()
      ..from = _parseFrom(config.from)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;
    await mailer.send(message, server);
  }

  /// Turns `Name <address>` into a mailer address.
  static mailer.Address _parseFrom(String from) {
    final match = RegExp(r'^(.*)<(.+)>$').firstMatch(from.trim());
    if (match == null) return mailer.Address(from.trim());
    return mailer.Address(match.group(2)!.trim(), match.group(1)!.trim());
  }
}

/// Development sender: writes emails to the server log instead of sending.
class LogEmailSender implements EmailSender {
  @override
  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    developer.log('Email to $to: $subject\n$body', name: 'email');
    // ignore: avoid_print
    print('--- email to $to ---\n$subject\n\n$body\n---');
  }
}
