import 'package:flutter/material.dart';

class PromoBannerModel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> colors;

  PromoBannerModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.colors,
  });
}