import 'package:logger/logger.dart';

// ProductionFilter, not the package default (DevelopmentFilter): that
// default wraps its check in an `assert()`, which Dart's release compiler
// strips out entirely — every log call would silently no-op on a release
// build (`flutter build apk --release`), the exact build users actually
// run. ProductionFilter's check isn't inside an assert, so it behaves the
// same in debug and release.
final appLogger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);
