import 'package:flutter/material.dart';
import 'package:flutter_application_2666/ExecusesPage.dart';
import 'package:flutter_application_2666/attandance.dart';
import 'package:flutter_application_2666/payrollPage.dart';
import 'package:flutter_application_2666/workerlist.dart';
import 'dart:ui';
import 'package:flutter_application_2666/services/firebase_service.dart';
import 'package:flutter_application_2666/login.dart' show GlassContainer;
import 'package:url_launcher/url_launcher.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  _MainDashboardState createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  int _pendingExcusesCount = 0;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchPendingExcusesCount();
  }

  Future<void> _fetchPendingExcusesCount() async {
    final excuses = await FirebaseService.getExcuses();
    int count = 0;
    excuses.forEach((key, value) {
      if (value is Map && value['status'] == 'Pending') {
        count++;
      }
    });
    if (mounted) {
      setState(() {
        _pendingExcusesCount = count;
      });
    }
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardContent(searchQuery: _searchQuery);
      case 1:
        return WorkersPage(searchQuery: _searchQuery);
      case 2:
        return const AttendancePage(); 
      case 3:
        return const PayrollPage();
      default:
        return DashboardContent(searchQuery: _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 67, 65, 65),
              Color.fromARGB(255, 2, 16, 31),
              Color.fromARGB(255, 12, 22, 31),
            ],
          ),
        ),
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
                _fetchPendingExcusesCount(); 
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard, color: Color.fromARGB(255, 131, 128, 128)), label: Text('Dashboard', style: TextStyle(color: Colors.white))),
                NavigationRailDestination(icon: Icon(Icons.people, color: Colors.white), label: Text('Workers', style: TextStyle(color: Colors.white))),
                NavigationRailDestination(icon: Icon(Icons.calendar_today, color: Colors.white), label: Text('Attendance', style: TextStyle(color: Colors.white))),
                NavigationRailDestination(icon: Icon(Icons.money, color: Colors.white), label: Text('Payroll', style: TextStyle(color: Colors.white))),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _getPage(_selectedIndex)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GlassContainer(
        height: 60,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search workers, projects...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 28),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExcusesPage()),
                      );
                      _fetchPendingExcusesCount();
                    },
                  ),
                  if (_pendingExcusesCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$_pendingExcusesCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  final String searchQuery;
  const DashboardContent({super.key, this.searchQuery = ""});

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _totalWorkers = 0;
  int _activeToday = 0;
  int _pendingExcuses = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeWorkersList = [];
  List<String> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    final workers = await FirebaseService.getWorkers();
    final attendance = await FirebaseService.getAttendance();
    final excuses = await FirebaseService.getExcuses();

    final todayDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> activeList = [];
    final List<String> activities = [];

    // Find active workers today
    attendance.forEach((key, value) {
      if (value is Map && value['date'] == todayDate) {
        final workerId = value['workerId']?.toString();
        final workerName = value['workerName']?.toString() ?? "Unknown";
        final inTime = value['inTime']?.toString() ?? "--:--";
        final status = value['status']?.toString() ?? "Present";

        activeList.add({
          "id": workerId,
          "name": workerName,
          "in": inTime,
          "status": status,
          "inLatitude": value['inLatitude'],
          "inLongitude": value['inLongitude'],
        });

        activities.add("$workerName checked in at $inTime today.");
      }
    });

    int pendingCount = 0;
    excuses.forEach((key, value) {
      if (value is Map) {
        if (value['status'] == 'Pending') {
          pendingCount++;
        }
        final workerName = value['workerName']?.toString() ?? "Unknown";
        final type = value['type']?.toString() ?? "Excuse";
        final date = value['date']?.toString() ?? "";
        activities.add("$workerName submitted a $type excuse for $date.");
      }
    });

    if (mounted) {
      setState(() {
        _totalWorkers = workers.length;
        _activeToday = activeList.length;
        _pendingExcuses = pendingCount;
        _activeWorkersList = activeList;
        _recentActivities = activities.take(5).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final double payrollTotal = (_totalWorkers * 4500) / 1000;

    final filteredActive = _activeWorkersList.where((w) {
      if (widget.searchQuery.isEmpty) return true;
      final nameLower = w['name'].toString().toLowerCase();
      final idLower = w['id'].toString().toLowerCase();
      final queryLower = widget.searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || idLower.contains(queryLower);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildStatCard("Total Workers", "$_totalWorkers", Icons.group),
                _buildStatCard("Active Today", "$_activeToday", Icons.bolt),
                _buildStatCard("Payroll (Est.)", "\$${payrollTotal.toStringAsFixed(1)}K", Icons.payments),
                _buildStatCard("Pending Excuses", "$_pendingExcuses", Icons.assignment_late),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GlassContainer(
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text("Active Workers Today", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          child: filteredActive.isEmpty
                            ? const Center(child: Text("No active workers", style: TextStyle(color: Colors.white70)))
                            : ListView.builder(
                                itemCount: filteredActive.length,
                                itemBuilder: (context, index) {
                                  final w = filteredActive[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.tealAccent,
                                      radius: 15,
                                      child: Icon(Icons.check, color: Colors.black, size: 16),
                                    ),
                                    title: Text(w['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: Text("Time: ${w['in']} | Status: ${w['status']}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    trailing: (w['inLatitude'] != null && w['inLongitude'] != null)
                                      ? Tooltip(
                                          message: "View check-in location",
                                          child: IconButton(
                                            icon: const Icon(Icons.location_on, color: Colors.cyanAccent, size: 18),
                                            onPressed: () => _openMap(w['inLatitude'], w['inLongitude']),
                                          ),
                                        )
                                      : null,
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: GlassContainer(
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text("Recent Activities", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          child: _recentActivities.isEmpty
                            ? const Center(child: Text("No recent activity", style: TextStyle(color: Colors.white70)))
                            : ListView.builder(
                                itemCount: _recentActivities.length,
                                itemBuilder: (context, index) {
                                  final act = _recentActivities[index];
                                  return ListTile(
                                    leading: const Icon(Icons.flash_on, color: Colors.amberAccent, size: 18),
                                    title: Text(act, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color.fromARGB(255, 73, 105, 94), size: 30),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}