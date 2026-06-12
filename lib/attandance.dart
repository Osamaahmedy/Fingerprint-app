import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final List<Map<String, dynamic>> _allAttendanceRecords = [];
  List<Map<String, dynamic>> _filteredAttendanceRecords = [];
  String _searchQuery = "";
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    
    final workersData = await FirebaseService.getWorkers();
    final attendanceData = await FirebaseService.getAttendance();
    
    final selectedDateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final List<Map<String, dynamic>> temp = [];

    // Step 1: Create a map of workerId -> attendance record for the selected date
    final Map<String, Map<String, dynamic>> activeAttendance = {};
    attendanceData.forEach((key, value) {
      if (value is Map && value['date'] == selectedDateStr) {
        final workerId = value['workerId']?.toString();
        if (workerId != null) {
          activeAttendance[workerId] = Map<String, dynamic>.from(value);
        }
      }
    });

    // Step 2: Iterate over all workers and build records
    workersData.forEach((key, value) {
      if (value is Map) {
        final workerId = value['id']?.toString();
        final workerName = value['name']?.toString() ?? "Unknown";
        final workerRole = value['role']?.toString() ?? "";
        
        if (workerId != null) {
          if (activeAttendance.containsKey(workerId)) {
            final record = activeAttendance[workerId]!;
            final status = record['status'] ?? "Present";
            Color color = Colors.greenAccent;
            if (status == "Late") {
              color = Colors.orangeAccent;
            } else if (status == "Completed" || status == "Checked Out") {
              color = Colors.blueAccent;
            } else if (status == "Absent") {
              color = Colors.redAccent;
            }
            
            temp.add({
              "name": workerName,
              "id": workerId,
              "role": workerRole,
              "in": record['inTime'] ?? "--:--",
              "out": record['outTime'] ?? "--:--",
              "status": status,
              "color": color,
            });
          } else {
            temp.add({
              "name": workerName,
              "id": workerId,
              "role": workerRole,
              "in": "--:--",
              "out": "--:--",
              "status": "Absent",
              "color": Colors.redAccent,
            });
          }
        }
      }
    });

    setState(() {
      _allAttendanceRecords.clear();
      _allAttendanceRecords.addAll(temp);
      _filterRecords(_searchQuery);
      _isLoading = false;
    });
  }

  void _filterRecords(String query) {
    setState(() {
      _searchQuery = query;
      _filteredAttendanceRecords = _allAttendanceRecords.where((record) {
        final nameLower = record['name'].toString().toLowerCase();
        final idLower = record['id'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) || idLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchAttendance,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 15 : 25, 
            vertical: 15
          ),
          child: Column(
            children: [
              // 1. Stats Dashboard
              if (!_isLoading) _buildStatsDashboard(isMobile),
              if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),
              const SizedBox(height: 25),
              
              // 2. Control Bar
              _buildControlBar(context, isMobile),
              const SizedBox(height: 15),
              
              // 3. Attendance Table
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _buildAttendanceTable(isMobile, screenWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard(bool isMobile) {
    int presentCount = _allAttendanceRecords.where((e) => e['status'] == 'Present' || e['status'] == 'Completed' || e['status'] == 'Checked Out').length;
    int lateCount = _allAttendanceRecords.where((e) => e['status'] == 'Late').length;
    int absentCount = _allAttendanceRecords.where((e) => e['status'] == 'Absent').length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _statCard("Present", presentCount.toString(), Icons.check_circle_outline, Colors.greenAccent, isMobile),
        _statCard("Late", lateCount.toString(), Icons.access_time, Colors.orangeAccent, isMobile),
        _statCard("Absent", absentCount.toString(), Icons.cancel_outlined, Colors.redAccent, isMobile),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isMobile) {
    double screenWidth = MediaQuery.of(context).size.width;
    double width = isMobile ? (screenWidth - 40) / 1 : (screenWidth / 4);

    return Container(
      width: isMobile ? null : width,
      constraints: BoxConstraints(minWidth: isMobile ? screenWidth : 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, bool isMobile) {
    return isMobile 
    ? Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildDateBtn(), const SizedBox(width: 10), _buildDownloadBtn()],
          )
        ],
      )
    : Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 10),
          _buildDateBtn(),
          const SizedBox(width: 10),
          _buildDownloadBtn(),
        ],
      );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        onChanged: _filterRecords,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.cyanAccent, size: 20),
          hintText: "Search name or ID...",
          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateBtn() => GestureDetector(
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2101),
      );
      if (date != null) {
        setState(() {
          _selectedDate = date;
        });
        _fetchAttendance();
      }
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: const Icon(Icons.calendar_today_outlined, color: Colors.cyanAccent, size: 20),
    ),
  );

  Widget _buildDownloadBtn() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
    child: const Icon(Icons.file_download_outlined, color: Colors.cyanAccent, size: 20),
  );

  Widget _buildAttendanceTable(bool isMobile, double screenWidth) {
    if (_filteredAttendanceRecords.isEmpty) {
      return const Center(child: Text("No records found for this date", style: TextStyle(color: Colors.white70)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildTableHeader(isMobile),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _filteredAttendanceRecords.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  itemBuilder: (context, index) => _buildAttendanceRow(_filteredAttendanceRecords[index], isMobile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white.withOpacity(0.08),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text("Employee", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(flex: 2, child: Text("In", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          if (!isMobile) const Expanded(flex: 2, child: Text("Out", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("Status", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(Map<String, dynamic> item, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (!isMobile) CircleAvatar(
                  radius: 16,
                  backgroundColor: item['color'].withOpacity(0.1),
                  child: Text(item['name'] != null && item['name'].isNotEmpty ? item['name'][0] : "?", style: TextStyle(color: item['color'], fontSize: 12)),
                ),
                if (!isMobile) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                      Text("ID: ${item['id']}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(item['in'], style: const TextStyle(color: Colors.white70, fontSize: 12))),
          if (!isMobile) Expanded(flex: 2, child: Text(item['out'], style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['status'],
                textAlign: TextAlign.center,
                style: TextStyle(color: item['color'], fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}