class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  // 정산 비율 (서버와 동일하게 유지)
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
