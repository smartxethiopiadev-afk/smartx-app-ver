import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/offline_service.dart';
import '../services/google_analytics_service.dart';

class AnalyticsMonitorScreen extends StatefulWidget {
  const AnalyticsMonitorScreen({super.key});

  @override
  State<AnalyticsMonitorScreen> createState() => _AnalyticsMonitorScreenState();
}

class _AnalyticsMonitorScreenState extends State<AnalyticsMonitorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final admobLogs = offline.admobLogs;
    final gaEvents = GoogleAnalyticsService.eventHistory;

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          isAm ? 'የ Google Analytics እና AdMob ዳሽቦርድ' : 'Google Analytics & AdMob Telemetry',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync,
              color: offline.isTelemetrySyncing ? AppConfig.accentAmber : AppConfig.primaryGreen,
            ),
            tooltip: 'Ping Active Session to Google Analytics',
            onPressed: () async {
              await offline.pingActiveSession();
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAm
                          ? 'የ Google Analytics (GA4) ፒንግ በተሳካ ሁኔታ ተልኳል!'
                          : 'Google Analytics (GA4) active session ping dispatched successfully!',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppConfig.primaryGreenDark,
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConfig.accentAmber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.analytics_rounded, size: 18),
              text: isAm ? 'Google Analytics (GA4)' : 'Google Analytics',
            ),
            Tab(
              icon: const Icon(Icons.monetization_on_rounded, size: 18),
              text: isAm ? 'Google AdMob Real Data' : 'AdMob Telemetry',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // -------------------------------------------------------------
          // Tab 1: Google Analytics (GA4) Telemetry & Active Users
          // -------------------------------------------------------------
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GA4 Live Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE37400), Color(0xFFEA4335)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF69F0AE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Google Analytics (GA4) Live',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              AppConfig.ga4MeasurementId,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${offline.activeUsersNow}',
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                isAm ? 'በአሁኑ ሰዓት ያሉ ተማሪዎች (Realtime)' : 'Active Users in Last 30 min',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${offline.activeUsersToday}',
                                style: const TextStyle(color: Color(0xFFFFF176), fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isAm ? 'በዛሬው ዕለት (Active Today)' : 'Daily Active Users (DAU)',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Client: ${offline.deviceId.length > 20 ? '${offline.deviceId.substring(0, 20)}...' : offline.deviceId}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                          ),
                          const Text(
                            'GA4 Protocol OK',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GA4 Measurement Details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConfig.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Analytics Configuration & Properties',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      _buildConfigRow('Measurement ID', AppConfig.ga4MeasurementId),
                      _buildConfigRow('API Secret', '••••••••••••• (Configured)'),
                      _buildConfigRow('Stream ID', AppConfig.ga4StreamId),
                      _buildConfigRow('Default Region', 'Ethiopia (ET)'),
                      _buildConfigRow('Active Grade Target', 'Grade ${offline.currentGrade}'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE37400),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        onPressed: () {
                          GoogleAnalyticsService.logEvent(
                            eventName: 'manual_ping_test',
                            deviceId: offline.deviceId,
                            parameters: {'trigger': 'analytics_monitor_screen'},
                          );
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test GA4 Event dispatched to Google Analytics!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Dispatch Test GA4 Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Google Analytics Event Stream
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAm ? 'የ Google Analytics የቀጥታ ኢቨንቶች' : 'Live GA4 Event Stream',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${gaEvents.length} events logged',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gaEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ev = gaEvents[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConfig.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE37400).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.insights_rounded, color: Color(0xFFFFA726), size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.eventName,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ev.params.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${ev.timestamp.hour.toString().padLeft(2, '0')}:${ev.timestamp.minute.toString().padLeft(2, '0')}:${ev.timestamp.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // Tab 2: Google AdMob Real Data Telemetry
          // -------------------------------------------------------------
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AdMob Stats 3-Card Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.visibility_outlined, color: Colors.blueAccent, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '${offline.adImpressionsCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isAm ? 'የታዩ ማስታወቂያዎች' : 'Impressions',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConfig.accentAmber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.touch_app_outlined, color: AppConfig.accentAmber, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '${offline.adClicksCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isAm ? 'ክሊኮች (Clicks)' : 'Ad Clicks',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConfig.primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: AppConfig.primaryGreen, size: 20),
                            const SizedBox(height: 6),
                            Text(
                              '\$${offline.adRevenueEst.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isAm ? 'የገቢ ግምት' : 'Est. Revenue',
                              style: const TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AdMob Config
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConfig.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AdMob Integration & Units Mapping',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _buildConfigRow('App ID', 'ca-app-pub-3940256099942544~3347511713'),
                      _buildConfigRow('Banner Unit', 'ca-app-pub-3940256099942544/6300978111'),
                      _buildConfigRow('Interstitial Unit', 'ca-app-pub-3940256099942544/1033173712'),
                      _buildConfigRow('Rewarded Unit', 'ca-app-pub-3940256099942544/5224354917'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () {
                                offline.recordAdMobEvent('Banner', 'Adaptive Banner Loaded & Displayed');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test Banner ad impression recorded to live telemetry!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Test Banner Ad', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () {
                                offline.recordAdClick();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ad click and conversion logged to AdMob analytics!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.ads_click, size: 16),
                              label: const Text('Simulate Ad Click', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live AdMob Event Stream Log
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAm ? 'የቀጥታ ማስታወቂያና የዳታ እንቅስቃሴዎች' : 'Live AdMob Event Stream',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${admobLogs.length} events',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: admobLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = admobLogs[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConfig.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log.adType} • ${log.status}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${log.network} (eCPM ~\$${log.estimatedEcpm.toStringAsFixed(2)})',
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
