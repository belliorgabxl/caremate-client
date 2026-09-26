import 'package:flutter/material.dart';

/// A Thai bank offering retail deposit accounts — used as the fixed option
/// list for the bank-account dropdown so refund destinations always name a
/// real bank instead of free-text.
///
/// [logoAssetCode] keys into `assets/images/banks/<code>.svg` (white marks
/// from github.com/omise/banks-logo, MIT-licensed) drawn on a [brandColor]
/// circle; null for the two banks that pack doesn't cover, which fall back
/// to a generic icon.
class ThaiBank {
  const ThaiBank({
    required this.name,
    required this.brandColor,
    this.logoAssetCode,
  });

  final String name;
  final Color brandColor;
  final String? logoAssetCode;
}

const thaiBanks = [
  ThaiBank(
    name: 'ธนาคารกรุงเทพ',
    logoAssetCode: 'bbl',
    brandColor: Color(0xFF1E4598),
  ),
  ThaiBank(
    name: 'ธนาคารกสิกรไทย',
    logoAssetCode: 'kbank',
    brandColor: Color(0xFF138F2D),
  ),
  ThaiBank(
    name: 'ธนาคารกรุงไทย',
    logoAssetCode: 'ktb',
    brandColor: Color(0xFF1BA5E1),
  ),
  ThaiBank(
    name: 'ธนาคารไทยพาณิชย์',
    logoAssetCode: 'scb',
    brandColor: Color(0xFF4E2E7F),
  ),
  ThaiBank(
    name: 'ธนาคารกรุงศรีอยุธยา',
    logoAssetCode: 'bay',
    brandColor: Color(0xFFFEC43B),
  ),
  ThaiBank(
    name: 'ธนาคารทหารไทยธนชาต',
    logoAssetCode: 'ttb',
    brandColor: Color(0xFF00539F),
  ),
  ThaiBank(
    name: 'ธนาคารออมสิน',
    logoAssetCode: 'gsb',
    brandColor: Color(0xFFEB198D),
  ),
  ThaiBank(
    name: 'ธนาคารเพื่อการเกษตรและสหกรณ์การเกษตร',
    logoAssetCode: 'baac',
    brandColor: Color(0xFF4B9B1D),
  ),
  ThaiBank(
    name: 'ธนาคารอาคารสงเคราะห์',
    logoAssetCode: 'ghb',
    brandColor: Color(0xFFF57D23),
  ),
  ThaiBank(
    name: 'ธนาคารซีไอเอ็มบี ไทย',
    logoAssetCode: 'cimb',
    brandColor: Color(0xFF7E2F36),
  ),
  ThaiBank(
    name: 'ธนาคารยูโอบี',
    logoAssetCode: 'uob',
    brandColor: Color(0xFF0B3979),
  ),
  ThaiBank(
    name: 'ธนาคารแลนด์ แอนด์ เฮ้าส์',
    logoAssetCode: 'lhb',
    brandColor: Color(0xFF6D6E71),
  ),
  ThaiBank(
    name: 'ธนาคารทิสโก้',
    logoAssetCode: 'tisco',
    brandColor: Color(0xFF12549F),
  ),
  ThaiBank(
    name: 'ธนาคารเกียรตินาคินภัทร',
    logoAssetCode: 'kk',
    brandColor: Color(0xFF199CC5),
  ),
  ThaiBank(
    name: 'ธนาคารไทยเครดิต',
    logoAssetCode: 'tcrb',
    brandColor: Color(0xFF0A4AB3),
  ),
  ThaiBank(name: 'ธนาคารแห่งประเทศจีน (ไทย)', brandColor: Color(0xFF757575)),
  ThaiBank(
    name: 'ธนาคารไอซีบีซี (ไทย)',
    logoAssetCode: 'icbc',
    brandColor: Color(0xFFC50F1C),
  ),
  ThaiBank(
    name: 'ธนาคารอิสลามแห่งประเทศไทย',
    logoAssetCode: 'ibank',
    brandColor: Color(0xFF184615),
  ),
  ThaiBank(
    name: 'ธนาคารซิตี้แบงก์',
    logoAssetCode: 'citi',
    brandColor: Color(0xFF1583C7),
  ),
  ThaiBank(
    name: 'ธนาคารสแตนดาร์ดชาร์เตอร์ด (ไทย)',
    logoAssetCode: 'sc',
    brandColor: Color(0xFF0F6EA1),
  ),
  ThaiBank(
    name: 'ธนาคารพัฒนาวิสาหกิจขนาดกลางและขนาดย่อมแห่งประเทศไทย',
    brandColor: Color(0xFF757575),
  ),
];
