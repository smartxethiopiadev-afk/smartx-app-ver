import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Smart X';
  static const String appTagline = 'Ethiopian National Curriculum Study Platform';
  static const String appVersion = '1.0.2';
  
  // Telegram Community Link
  static const String telegramChannelUrl = 'https://t.me/smartx_ethiopia';
  static const String telegramBotUrl = 'https://t.me/smartx_ethiopia_bot';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://nxyggytcmvlyfquptwrd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54eWdneXRjbXZseWZxdXB0d3JkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzODk1ODIsImV4cCI6MjA1NTk2NTU4Mn0.fE16_P_k1o0mQy7q_L4V-bVwH7K8P9n3Z4j4l3q-Vz0';

  // Google Analytics (GA4) Configuration for Ethiopian Active Users
  static const String ga4MeasurementId = 'G-SMARTXETH01';
  static const String ga4ApiSecret = 'ga4_smartx_eth_sec_2026';
  static const String ga4StreamId = '9876543210';

  // Primary Theme Colors (Emerald Green, Warm Amber, Dark Slate)
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenDark = Color(0xFF059669);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSurface = Color(0xFF334155);
}

enum LanguageCode { en, am }

class SubjectConfig {
  final String id;
  final String code;
  final String enTitle;
  final String amTitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final int totalUnits;

  const SubjectConfig({
    required this.id,
    required this.code,
    required this.enTitle,
    required this.amTitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.totalUnits,
  });
}

final List<SubjectConfig> allSubjects = [
  const SubjectConfig(
    id: 'mathematics',
    code: 'MATH',
    enTitle: 'Mathematics',
    amTitle: 'ሒሳብ',
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF1D4ED8),
    icon: Icons.calculate_outlined,
    totalUnits: 7,
  ),
  const SubjectConfig(
    id: 'biology',
    code: 'BIO',
    enTitle: 'Biology',
    amTitle: 'ሥነ-ሕይወት',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF047857),
    icon: Icons.biotech_outlined,
    totalUnits: 6,
  ),
  const SubjectConfig(
    id: 'physics',
    code: 'PHY',
    enTitle: 'Physics',
    amTitle: 'ፊዚክስ',
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFF6D28D9),
    icon: Icons.electric_bolt_outlined,
    totalUnits: 6,
  ),
  const SubjectConfig(
    id: 'chemistry',
    code: 'CHEM',
    enTitle: 'Chemistry',
    amTitle: 'ኬሚስትሪ',
    primaryColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFBE185D),
    icon: Icons.science_outlined,
    totalUnits: 6,
  ),
  const SubjectConfig(
    id: 'history',
    code: 'HIST',
    enTitle: 'History',
    amTitle: 'ታሪክ',
    primaryColor: Color(0xFFD97706),
    secondaryColor: Color(0xFF92400E),
    icon: Icons.account_balance_outlined,
    totalUnits: 7,
  ),
  const SubjectConfig(
    id: 'geography',
    code: 'GEO',
    enTitle: 'Geography',
    amTitle: 'ጆግራፊ',
    primaryColor: Color(0xFF06B6D4),
    secondaryColor: Color(0xFF0E7490),
    icon: Icons.public_outlined,
    totalUnits: 6,
  ),
  const SubjectConfig(
    id: 'economics',
    code: 'ECON',
    enTitle: 'Economics',
    amTitle: 'ኢኮኖሚክስ',
    primaryColor: Color(0xFF6366F1),
    secondaryColor: Color(0xFF4338CA),
    icon: Icons.trending_up_outlined,
    totalUnits: 6,
  ),
];
