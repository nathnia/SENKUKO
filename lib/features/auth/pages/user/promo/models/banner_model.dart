import 'package:flutter/material.dart';

enum BannerType {
  promo,
  product,
  category,
}

class BannerModel {
  final String title;
  final String subtitle;
  final String description;

  final BannerType type;
  final String keyword;

  final List<Color> colors;

  final IconData icon;

  const BannerModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.type,
    required this.keyword,
    required this.colors,
    required this.icon,
  });
}