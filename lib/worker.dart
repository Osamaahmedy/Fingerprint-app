import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';

class Start extends StatefulWidget {
  final Map<String, dynamic>? workerData;
  const Start({super.key, this.workerData});
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final Color navyDeep = const Color(0xFF000814); 
  final Color navyRoyal = const Color(0xFF001D3D);
  
  late Map<String, dynamic> worker;
  String status = "Absent";
  Color statusColor = const Color(0xFFE63946); 
  IconData statusIcon = Icons.cancel_outlined;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    worker = widget.workerData ?? {
      "name": "John Doe",
      "id": "123",
      "phone": "00000",
      "role": "Software Developer",
      "department": "Engineering"
    };
    _fetchTodayAttendance();
  }

  Future<void> _fetchTodayAttendance() async {
    setState(() => _isLoadingStatus = true);
    try {
      final todayDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final recordId = "${worker['id']}_$todayDate";
      final response = await FirebaseService.getAttendanceById(recordId);
      
      if (response != null) {
        final record = response;
        final originalStatus = record['status'] ?? "Present";
        setState(() {
          if (record['outTime'] != null && record['outTime'] != "--:--") {
            // Show original status (Late/Present) along with checkout info
            if (originalStatus == "Late") {
              status = "Checked Out (Late)";
              statusColor = Colors.orangeAccent;
              statusIcon = Icons.exit_to_app;
            } else {
              status = "Checked Out";
              statusColor = Colors.greenAccent;
              statusIcon = Icons.exit_to_app;
            }
          } else {
            status = originalStatus;
            statusColor = originalStatus == "Late" ? Colors.orangeAccent : Colors.greenAccent;
            statusIcon = Icons.check_circle_outline;
          }
        });
      } else {
        setState(() {
          status = "Absent";
          statusColor = const Color(0xFFE63946);
          statusIcon = Icons.cancel_outlined;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch attendance status.")),
        );
      }
    }
    setState(() => _isLoadingStatus = false);
  }
  
  void showFingerprintScanner({required bool isCheckingIn}) {
    bool isScanning = false;
    bool isVerified = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return FadeTransition(
                opacity: anim1,
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                  child: AlertDialog(
                    backgroundColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    content: Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
                      decoration: BoxDecoration(
                        color: navyDeep.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("BIOMETRIC SCAN", style: TextStyle(fontWeight: FontWeight.w300, fontSize: 13, color: Colors.white, letterSpacing: 4)),
                          const SizedBox(height: 50),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.white.withOpacity(0.05)))),
                              if (isScanning && !isVerified)
                                TweenAnimationBuilder(
                                  tween: Tween(begin: -40.0, end: 40.0),
                                  duration: const Duration(milliseconds: 1000),
                                  builder: (context, double value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, value),
                                      child: Container(width: 70, height: 2, decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 12)])),
                                    );
                                  },
                                  onEnd: () => setDialogState(() {}),
                                ),
                              GestureDetector(
                                onTap: () {
                                  if (!isScanning && !isVerified) {
                                    setDialogState(() => isScanning = true);
                                    Timer(const Duration(seconds: 2), () {
                                      setDialogState(() { isScanning = false; isVerified = true; });
                                      Timer(const Duration(milliseconds: 800), () {
                                        Navigator.pop(context);
                                        isCheckingIn ? confirmCheckIn() : confirmCheckOut();
                                      });
                                    });
                                  }
                                },
                                child: Icon(isVerified ? Icons.check_circle_rounded : Icons.fingerprint_rounded, size: 70, color: isVerified ? Colors.greenAccent : Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(isScanning ? "VERIFYING..." : (isVerified ? "SUCCESS" : "TOUCH TO SCAN"), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> confirmCheckIn() async {
    setState(() => _isLoadingStatus = true);
    
    Position? position;
    try {
      position = await _determinePosition();
    } catch (e) {
      setState(() => _isLoadingStatus = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location Error: $e")),
      );
      return;
    }

    final todayDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final now = DateTime.now();
    final inTime = _formatTime(now);
    
    // Check if already checked in today
    final recordId = "${worker['id']}_$todayDate";
    final existingRecord = await FirebaseService.getAttendanceById(recordId);
    if (existingRecord != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already checked in today!")),
      );
      setState(() => _isLoadingStatus = false);
      return;
    }

    String newStatus = "Present";
    if (now.hour > 8 || (now.hour == 8 && now.minute > 0)) {
      newStatus = "Late";
    }

    final success = await FirebaseService.saveAttendance(recordId, {
      "workerId": worker['id'],
      "workerName": worker['name'],
      "date": todayDate,
      "inTime": inTime,
      "outTime": "--:--",
      "status": newStatus,
      "inLatitude": position.latitude,
      "inLongitude": position.longitude,
    });

    if (success) {
      setState(() {
        status = newStatus;
        statusColor = newStatus == "Late" ? Colors.orangeAccent : Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Checked In Successfully as $newStatus!")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to Check In. Please try again.")),
      );
    }
    setState(() => _isLoadingStatus = false);
  }

  Future<void> confirmCheckOut() async {
    setState(() => _isLoadingStatus = true);

    Position? position;
    try {
      position = await _determinePosition();
    } catch (e) {
      setState(() => _isLoadingStatus = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location Error: $e")),
      );
      return;
    }

    final todayDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final recordId = "${worker['id']}_$todayDate";
    
    final record = await FirebaseService.getAttendanceById(recordId);
    if (record == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must check in first before checking out!")),
      );
      setState(() => _isLoadingStatus = false);
      return;
    }

    if (record['outTime'] != null && record['outTime'] != "--:--") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already checked out for today!")),
      );
      setState(() => _isLoadingStatus = false);
      return;
    }

    final now = DateTime.now();
    final outTime = _formatTime(now);
    final originalStatus = record['status'] ?? "Present";

    // Preserve original status (Late/Present) - don't overwrite with "Completed"
    final success = await FirebaseService.saveAttendance(recordId, {
      "workerId": worker['id'],
      "workerName": worker['name'],
      "date": todayDate,
      "inTime": record['inTime'],
      "outTime": outTime,
      "status": originalStatus,
      "inLatitude": record['inLatitude'],
      "inLongitude": record['inLongitude'],
      "outLatitude": position.latitude,
      "outLongitude": position.longitude,
    });

    if (success) {
      setState(() {
        if (originalStatus == "Late") {
          status = "Checked Out (Late)";
          statusColor = Colors.orangeAccent;
        } else {
          status = "Checked Out";
          statusColor = Colors.greenAccent;
        }
        statusIcon = Icons.exit_to_app;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checked Out Successfully!")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to Check Out. Please try again.")),
      );
    }
    setState(() => _isLoadingStatus = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: Icon(Icons.grid_view_rounded, color: navyRoyal),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: navyRoyal),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTodayAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(worker['name'] ?? 'John Doe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: navyRoyal)),
              Text(worker['role'] ?? 'Software Developer', style: TextStyle(fontSize: 14, color: navyRoyal.withOpacity(0.5))),
              const SizedBox(height: 35),
              _buildInfoTile(Icons.calendar_today_outlined, "Today", _getFormattedToday()),
              const SizedBox(height: 20),
              _buildInfoTile(Icons.access_time_rounded, "Shift Start", "08:00 AM"),
              const SizedBox(height: 30),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: navyRoyal, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: navyRoyal.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]),
                child: _isLoadingStatus
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Row(children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 15),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("Today's Status", style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      ])
                    ]),
              ),
              const SizedBox(height: 35),
              _actionCard("Check In", "Verify identity to start", Icons.login_rounded, () => showFingerprintScanner(isCheckingIn: true)),
              _actionCard("Check Out", "Verify identity to end", Icons.logout_rounded, () => showFingerprintScanner(isCheckingIn: false)),
              _actionCard("Upload Excuse", "Submit absence excuse", Icons.note_add_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => UploadExcusePage(worker: worker)))),
              _actionCard("Excuse Status", "Review submitted excuses", Icons.feedback_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorkerExcusesPage(worker: worker)))),
              _actionCard("History", "View past records", Icons.history_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage(worker: worker)))),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedToday() {
    final now = DateTime.now();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  Widget _buildInfoTile(IconData i, String t, String st) => Row(children: [Icon(i, color: navyRoyal.withOpacity(0.4), size: 20), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)), Text(st, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: navyRoyal))])]);

  Widget _actionCard(String t, String s, IconData i, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.black.withOpacity(0.02))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: navyRoyal.withOpacity(0.05), shape: BoxShape.circle), child: Icon(i, color: navyRoyal, size: 22)),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: navyRoyal, fontWeight: FontWeight.bold, fontSize: 16)), Text(s, style: TextStyle(color: Colors.grey.shade400, fontSize: 11))]),
        const Spacer(), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.black12)
      ]),
    ),
  );
}

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> worker;
  const HistoryPage({super.key, required this.worker});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  int _presentCount = 0;
  int _lateCount = 0;
  int _absentCount = 0;
  int _excusedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final data = await FirebaseService.getAttendance();
    final List<Map<String, dynamic>> temp = [];
    int present = 0;
    int lateVal = 0;
    int absent = 0;
    int excused = 0;

    data.forEach((key, value) {
      if (value is Map && value['workerId']?.toString() == widget.worker['id']?.toString()) {
        temp.add({
          "date": value["date"] ?? "",
          "inTime": value["inTime"] ?? "",
          "outTime": value["outTime"] ?? "",
          "status": value["status"] ?? "",
        });

        final statusVal = value["status"]?.toString().toLowerCase();
        if (statusVal == "present") {
          present++;
        } else if (statusVal == "late") {
          lateVal++;
        } else if (statusVal == "absent") {
          absent++;
        } else if (statusVal == "excused") {
          excused++;
        }
      }
    });

    temp.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      _records = temp;
      _presentCount = present;
      _lateCount = lateVal;
      _absentCount = absent;
      _excusedCount = excused;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: const BackButton(color: Color(0xFF001D3D)), 
        title: const Text("History", style: TextStyle(color: Color(0xFF001D3D), fontWeight: FontWeight.bold))
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF001D3D)))
        : RefreshIndicator(
            onRefresh: _fetchHistory,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(25),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("SUMMARY", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _sumItem(_presentCount.toString(), "Present", Colors.green),
                  _sumItem(_lateCount.toString(), "Late", Colors.orange),
                  _sumItem(_absentCount.toString(), "Absent", Colors.red),
                  _sumItem(_excusedCount.toString(), "Excused", Colors.blue),
                ]),
                const SizedBox(height: 40),
                const Text("RECENT RECORDS", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                const SizedBox(height: 15),
                if (_records.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("No records found", style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ..._records.map((rec) {
                    final statusVal = rec['status'] ?? "";
                    Color color = Colors.green;
                    if (statusVal.toLowerCase() == "late") {
                      color = Colors.orange;
                    } else if (statusVal.toLowerCase() == "absent") {
                      color = Colors.red;
                    } else if (statusVal.toLowerCase() == "excused") {
                      color = Colors.blue;
                    }
                    return _historyCard(rec['date'], rec['inTime'], rec['outTime'], statusVal, color);
                  }),
              ]),
            ),
          ),
    );
  }

  Widget _sumItem(String n, String l, Color c) => Column(children: [Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)), Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey))]);

  Widget _historyCard(String d, String cin, String cout, String s, Color c) => Container(
    margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(s, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))),
      ]),
      const Divider(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _timeBox("IN", cin),
        _timeBox("OUT", cout),
      ])
    ]),
  );
  Widget _timeBox(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]);
}

class UploadExcusePage extends StatefulWidget {
  final Map<String, dynamic> worker;
  const UploadExcusePage({super.key, required this.worker});
  @override
  State<UploadExcusePage> createState() => _UploadExcusePageState();
}

class _UploadExcusePageState extends State<UploadExcusePage> {
  DateTime selectedDate = DateTime.now();
  String? selectedType;
  final TextEditingController _reasonController = TextEditingController();
  String? _fileName;
  bool isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() {
        _fileName = result.files.single.name;
        isUploading = true;
      });
    }
  }

  Future<void> _onSubmit() async {
    final reason = _reasonController.text.trim();
    if (selectedType == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields (Type and Reason)!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    
    final success = await FirebaseService.addExcuse({
      "workerId": widget.worker['id'],
      "workerName": widget.worker['name'],
      "date": dateStr,
      "type": selectedType,
      "reason": reason,
      "attachment": isUploading ? (_fileName ?? "medical_report.pdf") : "None",
      "status": "Pending"
    });
    setState(() => _isSubmitting = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excuse submitted successfully!")),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit excuse. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Color(0xFF001D3D)), title: const Text("Upload Excuse", style: TextStyle(color: Color(0xFF001D3D), fontWeight: FontWeight.bold))),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF001D3D)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label("DATE"),
              _fakeInput("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", Icons.calendar_month, onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2101));
                if (date != null) setState(() => selectedDate = date);
              }),
              const SizedBox(height: 25),
              _label("EXCUSE TYPE"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: InputBorder.none),
                  items: ["Sick Leave", "Personal", "Emergency"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) => setState(() => selectedType = val),
                  hint: const Text("Select type"),
                ),
              ),
              const SizedBox(height: 25),
              _label("REASON"),
              TextField(
                controller: _reasonController,
                maxLines: 3, 
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), hintText: "Details...")
              ),
              const SizedBox(height: 25),
              _label("ATTACHMENT"),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isUploading ? Colors.greenAccent : Colors.transparent)),
                  child: Column(children: [
                    Icon(isUploading ? Icons.check_circle : Icons.cloud_upload_outlined, size: 35, color: isUploading ? Colors.green : Colors.grey),
                    const SizedBox(height: 10),
                    Text(isUploading ? (_fileName ?? "medical_report.pdf") : "Upload File", style: TextStyle(color: isUploading ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, 
                height: 60, 
                child: ElevatedButton(
                  onPressed: _onSubmit, 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001D3D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), 
                  child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))
                )
              ),
            ]),
          ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.bold)));
  
  Widget _fakeInput(String t, IconData i, {VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t), Icon(i, size: 20, color: const Color(0xFF001D3D))]),
    ),
  );
}

class WorkerExcusesPage extends StatefulWidget {
  final Map<String, dynamic> worker;
  const WorkerExcusesPage({super.key, required this.worker});

  @override
  State<WorkerExcusesPage> createState() => _WorkerExcusesPageState();
}

class _WorkerExcusesPageState extends State<WorkerExcusesPage> {
  List<Map<String, dynamic>> _excuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyExcuses();
  }

  Future<void> _fetchMyExcuses() async {
    setState(() => _isLoading = true);
    final data = await FirebaseService.getExcuses();
    final List<Map<String, dynamic>> temp = [];
    data.forEach((key, value) {
      if (value is Map && value['workerId']?.toString() == widget.worker['id']?.toString()) {
        temp.add({
          "key": key,
          "date": value["date"] ?? "",
          "type": value["type"] ?? "",
          "reason": value["reason"] ?? "",
          "status": value["status"] ?? "Pending",
          "attachment": value["attachment"] ?? "None",
        });
      }
    });

    temp.sort((a, b) => b['date'].compareTo(a['date']));

    setState(() {
      _excuses = temp;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color navyRoyal = const Color(0xFF001D3D);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: navyRoyal),
        title: Text("Excuse Statuses", style: TextStyle(color: navyRoyal, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: navyRoyal))
        : RefreshIndicator(
            onRefresh: _fetchMyExcuses,
            child: _excuses.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: Text("No excuses submitted yet.", style: TextStyle(color: Colors.grey))),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(25),
                  itemCount: _excuses.length,
                  itemBuilder: (context, index) {
                    final excuse = _excuses[index];
                    Color statusColor = Colors.orange;
                    if (excuse['status'] == 'Accepted') statusColor = Colors.green;
                    if (excuse['status'] == 'Rejected') statusColor = Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(excuse['type'], style: TextStyle(color: navyRoyal, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  excuse['status'],
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("Reason: ${excuse['reason']}", style: const TextStyle(color: Colors.black87, fontSize: 14)),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Date: ${excuse['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              if (excuse['attachment'] != 'None')
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file, size: 14, color: Colors.blue),
                                    const SizedBox(width: 3),
                                    Text(excuse['attachment'], style: const TextStyle(color: Colors.blue, fontSize: 12)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }
}