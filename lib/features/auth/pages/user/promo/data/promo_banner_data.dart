import 'package:flutter/material.dart';
import '../models/promo_banner_model.dart';

final List<PromoBannerModel> promoBanners = [
  PromoBannerModel(
    title: "Belanja Rp150.000",
    subtitle: "GRATIS PIRING CANTIK",
    description: "Promo sampai 31 Juli",
    icon: Icons.restaurant,
    colors: [
      Color(0xff34A853),
      Color(0xff0F9D58),
    ],
  ),

  PromoBannerModel(
    title: "Beli 2 Aqua",
    subtitle: "GRATIS 1 AQUA",
    description: "Selama persediaan masih ada",
    icon: Icons.local_drink,
    colors: [
      Color(0xff4285F4),
      Color(0xff1A73E8),
    ],
  ),

  PromoBannerModel(
    title: "Paket Hemat",
    subtitle: "CHITATO + TEH BOTOL",
    description: "Hemat Rp5.000",
    icon: Icons.fastfood,
    colors: [
      Color(0xffFB8C00),
      Color(0xffF4511E),
    ],
  ),

  PromoBannerModel(
    title: "Voucher Spesial",
    subtitle: "VOUCHER10",
    description: "Potongan Rp10.000",
    icon: Icons.card_giftcard,
    colors: [
      Color(0xff8E24AA),
      Color(0xff6A1B9A),
    ],
  ),
];