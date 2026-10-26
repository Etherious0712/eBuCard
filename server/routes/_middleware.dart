import 'package:dart_frog/dart_frog.dart';

/// Root middleware, applied to every route: logs each request (method,
/// path, status, duration) to stdout. Auth middleware will be added under
/// `routes/v1/` when sign-in is implemented.
Handler middleware(Handler handler) => handler.use(requestLogger());
