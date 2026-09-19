class BankAccount {
  const BankAccount({
    required this.hasBankAccount,
    this.bankName = '',
    this.bankAccount = '',
    this.bankAccountName = '',
  });

  final bool hasBankAccount;
  final String bankName;
  final String bankAccount;
  final String bankAccountName;

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      hasBankAccount: json['has_bank_account'] as bool? ?? false,
      bankName: json['bank_name'] as String? ?? '',
      bankAccount: json['bank_account'] as String? ?? '',
      bankAccountName: json['bank_account_name'] as String? ?? '',
    );
  }

  static const empty = BankAccount(hasBankAccount: false);
}
