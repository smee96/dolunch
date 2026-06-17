import '../config/app_config.dart';

class ApiConstants {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static const depositRatio = 0.20;
  static const platformFeeRatio = 0.30;
  static const withholdingTaxRate = 0.033;

  static int calcDeposit(int pricePerPerson) =>
      (pricePerPerson * depositRatio).ceil();

  static int calcPlatformFee(int pricePerPerson) =>
      (pricePerPerson * platformFeeRatio).ceil();

  static int calcHostRevenue(int pricePerPerson) =>
      pricePerPerson - calcPlatformFee(pricePerPerson);
}
