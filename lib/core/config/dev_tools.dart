/// Developer-only tooling (GitHub-token "on-demand price refresh") that must
/// never reach end users. Off in every build — debug and release — unless
/// explicitly enabled with `--dart-define=SHOW_DEV_TOOLS=true`.
const bool kShowDevTools = bool.fromEnvironment('SHOW_DEV_TOOLS');
