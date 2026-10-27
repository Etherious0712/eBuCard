import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/services.dart';
import 'package:ebucard_server/src/web/app_links.dart';

import '../main.dart' as entrypoint;

/// Root middleware, applied to every route: logs each request, turns
/// `ApiException`s into JSON errors, and provides the [Services] created at
/// start-up (main.dart). It also answers the app-link files under
/// `/.well-known/`, whose folder name Dart Frog routes can't use.
Handler middleware(Handler handler) => handler
    .use(appLinkFiles())
    .use(errorHandler())
    .use(provider<Services>((_) => entrypoint.services))
    .use(requestLogger());
