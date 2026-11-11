import 'core/config/environment_config.dart';
import 'main.dart';

void main() async {
  await bootstrapApp(environment: Environment.prod);
}
