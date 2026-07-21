import 'package:flutter/material.dart';
import '../models/banner_model.dart';

final List<BannerModel> bannerData = [
  BannerModel(
    title: "PROMO SPESIAL",
    subtitle: "Belanja Lebih Hemat",
    description: "Diskon hingga 50% • Cashback • Hadiah Langsung",
    type: BannerType.promo,
    keyword: "",
    icon: Icons.local_offer_rounded,
    colors: [Color(0xff22c55e), Color(0xff15803d)],
  ),

  BannerModel(
    title: "AQUA",
    subtitle: "Segarkan Harimu",
    description: "Promo Beli 2 Gratis 1 • Air Mineral Pilihan Keluarga",
    type: BannerType.product,
    keyword: "AQUA",
    icon: Icons.water_drop,
    colors: [Color(0xff38bdf8), Color(0xff2563eb)],
  ),

  BannerModel(
    title: "INDOMIE",
    subtitle: "Mie Favorit Indonesia",
    description: "Nikmati Promo Paket Hemat & Harga Terbaik Hari Ini",
    type: BannerType.product,
    keyword: "INDOMIE",
    icon: Icons.ramen_dining,
    colors: [Color(0xffef4444), Color(0xffb91c1c)],
  ),
];
