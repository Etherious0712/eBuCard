// Everything the routes need, created once at start-up (see main.dart) and
// handed to each request by the root middleware. Tests build their own
// with fakes for email, storage and the identity providers.

import 'package:ebucard_server/src/auth/access_tokens.dart';
import 'package:ebucard_server/src/auth/account_service.dart';
import 'package:ebucard_server/src/auth/email_tokens.dart';
import 'package:ebucard_server/src/auth/identity_providers.dart';
import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:ebucard_server/src/auth/sessions.dart';
import 'package:ebucard_server/src/auth/users.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/db/database.dart';
import 'package:ebucard_server/src/email/email_sender.dart';
import 'package:ebucard_server/src/http/rate_limiter.dart';
import 'package:ebucard_server/src/storage/image_storage.dart';
import 'package:ebucard_server/src/storage/images.dart';
import 'package:ebucard_server/src/sync/share_links.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';
import 'package:http/http.dart' as http;

/// The server's services.
class Services {
  /// Creates services from parts; most callers use [Services.create].
  Services({
    required this.config,
    required this.database,
    required this.accounts,
    required this.apple,
    required this.google,
    required this.sync,
    required this.images,
    required this.authLimiter,
    required this.shareLinks,
    required this.linkLimiter,
  });

  /// Wires up real services for [config]. Unset SMTP logs emails; unset
  /// storage keeps images in memory (development only).
  factory Services.create(
    Config config, {
    Database? database,
    EmailSender? email,
    ImageStorage? storage,
    BreachChecker? breaches,
    PasswordHasher passwords = const PasswordHasher(),
    http.Client? httpClient,
    DateTime Function()? now,
  }) {
    final client = httpClient ?? http.Client();
    final db = database ?? Database.connect(config.database);
    final pool = db.pool;
    final users = Users(pool);
    final smtp = config.smtp;
    final bucket = config.storage;
    return Services(
      config: config,
      database: db,
      accounts: AccountService(
        db: pool,
        users: users,
        sessions: Sessions(pool, now: now),
        emailTokens: EmailTokens(pool, now: now),
        accessTokens: AccessTokens(config.jwtSecret, now: now),
        passwords: passwords,
        breaches:
            breaches ??
            (config.breachCheckEnabled
                ? HibpBreachChecker(client)
                : const NoBreachChecker()),
        email:
            email ?? (smtp == null ? LogEmailSender() : SmtpEmailSender(smtp)),
        publicBaseUrl: config.publicBaseUrl,
        now: now,
      ),
      apple: IdentityTokenVerifier(
        IdentityProvider.apple(config.appleClientIds),
        client,
        now: now,
      ),
      google: IdentityTokenVerifier(
        IdentityProvider.google(config.googleClientIds),
        client,
        now: now,
      ),
      sync: SyncStore(pool),
      images: Images(
        pool,
        storage ??
            (bucket == null
                ? MemoryImageStorage()
                : S3ImageStorage(bucket, client, now: now)),
        config.publicBaseUrl,
      ),
      authLimiter: RateLimiter(
        limit: 20,
        window: const Duration(minutes: 10),
        now: now,
      ),
      shareLinks: ShareLinks(pool),
      linkLimiter: RateLimiter(
        limit: 120,
        window: const Duration(minutes: 1),
        now: now,
      ),
    );
  }

  /// Settings.
  final Config config;

  /// Database.
  final Database database;

  /// Accounts and sign-in.
  final AccountService accounts;

  /// Sign in with Apple.
  final IdentityTokenVerifier apple;

  /// Google sign-in.
  final IdentityTokenVerifier google;

  /// Card and Inbox sync.
  final SyncStore sync;

  /// Card images.
  final Images images;

  /// Rate limit for sign-in, registration and email requests, per address.
  final RateLimiter authLimiter;

  /// Public card links.
  final ShareLinks shareLinks;

  /// Rate limit for opening card links, per address, so slugs can't be
  /// tried in bulk.
  final RateLimiter linkLimiter;

  /// Erases accounts whose 30-day deletion grace has ended, with their
  /// images. Run daily (main.dart) and safe to run any time.
  Future<int> purgeDeletedAccounts(DateTime now) async {
    final imageIds = await accounts.users.purgeExpired(now);
    for (final id in imageIds) {
      await images.storage.delete(Images.key(id));
    }
    return imageIds.length;
  }
}
