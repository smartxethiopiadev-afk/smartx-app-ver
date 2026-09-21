import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/package_model.dart';

class PackageService {
  static List<PackageModel> getFallbackPackages(int grade, {String? subject}) {
    return PackageModel.getPackagesForGrade(grade, subject: subject);
  }

  static Future<List<PackageModel>> getAvailablePackages({int grade = 12, String? subject}) async {
    return fetchPackagesForGrade(grade, subject: subject);
  }

  static Future<List<PackageModel>> fetchPackagesForGrade(int grade, {String? subject}) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('packages')
          .select()
          .eq('grade', grade)
          .order('price_etb', ascending: true);

      if (response.isNotEmpty) {
        final List<PackageModel> list = (response as List<dynamic>)
            .map((item) => PackageModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('[PackageService] Error fetching packages online: $e');
    }

    return getFallbackPackages(grade, subject: subject);
  }
}
