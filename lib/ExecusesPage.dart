import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';

class ExcusesPage extends StatefulWidget {
  const ExcusesPage({super.key});

  @override
  State<ExcusesPage> createState() => _ExcusesPageState();
}

class _ExcusesPageState extends State<ExcusesPage> {
  List<Map<String, dynamic>> _excusesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExcuses();
  }

  Future<void> _fetchExcuses() async {
    setState(() => _isLoading = true);
    final data = await FirebaseService.getExcuses();
    final List<Map<String, dynamic>> temp = [];
    data.forEach((key, value) {
      if (value is Map) {
        temp.add({
          "key": key,
          "workerId": value["workerId"] ?? "",
          "workerName": value["workerName"] ?? "Unknown",
          "reason": value["reason"] ?? "",
          "date": value["date"] ?? "",
          "type": value["type"] ?? "Absence",
          "status": value["status"] ?? "Pending",
          "attachment": value["attachment"] ?? "None",
        });
      }
    });

    // Sort by status "Pending" first, then by date descending
    temp.sort((a, b) {
      if (a['status'] == 'Pending' && b['status'] != 'Pending') return -1;
      if (a['status'] != 'Pending' && b['status'] == 'Pending') return 1;
      return b['date'].compareTo(a['date']);
    });

    setState(() {
      _excusesList = temp;
      _isLoading = false;
    });
  }

  bool _isUpdating = false;

  Future<void> _updateExcuseStatus(BuildContext context, String key, Map<String, dynamic> excuse, String newStatus) async {
    if (_isUpdating) return; // Prevent double-tap
    setState(() => _isUpdating = true);

    try {
      final success = await FirebaseService.updateExcuseStatus(key, newStatus);
      
      if (success) {
        // If accepted, also save attendance record as Excused
        if (newStatus == "Accepted") {
          final workerId = excuse['workerId']?.toString();
          final workerName = excuse['workerName']?.toString();
          final date = excuse['date']?.toString();
          if (workerId != null && date != null) {
            final recordId = "${workerId}_$date";
            await FirebaseService.saveAttendance(recordId, {
              "workerId": workerId,
              "workerName": workerName ?? "Unknown",
              "date": date,
              "inTime": "--:--",
              "outTime": "--:--",
              "status": "Excused",
            });
          }
        }

        // Update local list optimistically instead of full refetch
        setState(() {
          final index = _excusesList.indexWhere((e) => e['key'] == key);
          if (index != -1) {
            _excusesList[index]['status'] = newStatus;
          }
        });
        if (mounted) _showSnackBar(context, "Request updated to $newStatus!");
      } else {
        if (mounted) _showSnackBar(context, "Failed to update request. Please try again.");
      }
    } catch (e) {
      if (mounted) _showSnackBar(context, "Network error. Please check your connection.");
    }

    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Excuses & Requests Management", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              // List of excuses
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _excusesList.isEmpty
                    ? const Center(child: Text("No excuses or requests found", style: TextStyle(color: Colors.white70)))
                    : RefreshIndicator(
                        onRefresh: _fetchExcuses,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _excusesList.length,
                          itemBuilder: (context, index) => _buildExcuseCard(context, _excusesList[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcuseCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['workerName'] ?? "", 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        data['type'] ?? "Absence", 
                        style: const TextStyle(color: Colors.white, fontSize: 12)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Reason: ${data['reason']}", 
                  style: const TextStyle(color: Colors.white70, fontSize: 15)
                ),
                const SizedBox(height: 5),
                Text(
                  "Date: ${data['date']}", 
                  style: const TextStyle(color: Colors.white38, fontSize: 12)
                ),
                if (data['attachment'] != null && data['attachment'] != 'None')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          data['attachment'].toString(), 
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, decoration: TextDecoration.underline)
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (data['status'] == 'Pending')
                  Row(
                    children: [
                      // Accept Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUpdating ? null : () => _updateExcuseStatus(context, data['key'], data, "Accepted"),
                          child: _isUpdating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Accept", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Reject Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isUpdating ? null : () => _updateExcuseStatus(context, data['key'], data, "Rejected"),
                          child: _isUpdating
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Reject", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: data['status'] == 'Accepted' ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        data['status'] == 'Accepted' ? "Accepted" : "Rejected",
                        style: TextStyle(
                          color: data['status'] == 'Accepted' ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.black87, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}