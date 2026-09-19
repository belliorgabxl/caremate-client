import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/thai_banks.dart';

/// Bank identity badge for the bank-account dropdown: the bank's real logo
/// mark (a white SVG from `assets/images/banks/`) on its brand-color circle
/// — same colored-shadow-plus-ring treatment as [CircleIconAvatar] elsewhere
/// in the app. Falls back to a generic bank icon for the couple of banks
/// [ThaiBank.logoAssetCode] doesn't cover.
class BankLogoAvatar extends StatelessWidget {
  const BankLogoAvatar({super.key, required this.bank, this.radius = 16});

  final ThaiBank bank;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final assetCode = bank.logoAssetCode;

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bank.brandColor,
        boxShadow: [
          BoxShadow(
            color: bank.brandColor.withValues(alpha: 0.30),
            offset: Offset(0, radius * 0.16),
            blurRadius: radius * 0.55,
          ),
        ],
      ),
      child: assetCode == null
          ? Icon(
              Icons.account_balance_outlined,
              color: Colors.white,
              size: radius,
            )
          : Padding(
              padding: EdgeInsets.all(radius * 0.3),
              child: SvgPicture.asset('assets/images/banks/$assetCode.svg'),
            ),
    );
  }
}
