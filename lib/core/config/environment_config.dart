enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static Environment environment = Environment.dev;

  static bool get isDev => environment == Environment.dev;
  static bool get isStaging => environment == Environment.staging;
  static bool get isProd => environment == Environment.prod;
}
