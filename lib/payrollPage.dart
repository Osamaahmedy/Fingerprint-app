import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  List<Map<String, dynamic>> _payrollData = [];
  bool _isLoading = true;

  double _totalPayout = 0.0;
  double _totalBonuses = 0.0;
  double _totalDeductions = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchPayroll();
  }

  Future<void> _fetchPayroll() async {
    setState(() => _isLoading = true);
    final workers = await FirebaseService.getWorkers();
    final attendance = await FirebaseService.getAttendance();

    final List<Map<String, dynamic>> temp = [];
    double totalPayout = 0;
    double totalBonuses = 0;
    double totalDeductions = 0;

    final Map<String, int> lateCounts = {};
    final Map<String, int> checkInCounts = {};

    attendance.forEach((key, value) {
      if (value is Map) {
        final workerId = value['workerId']?.toString();
        final status = value['status']?.toString();
        if (workerId != null) {
          checkInCounts[workerId] = (checkInCounts[workerId] ?? 0) + 1;
          if (status == "Late") {
            lateCounts[workerId] = (lateCounts[workerId] ?? 0) + 1;
          }
        }
      }
    });

    workers.forEach((key, value) {
      if (value is Map) {
        final name = value['name']?.toString() ?? "Unknown";
        final id = value['id']?.toString() ?? "";
        final role = value['role']?.toString() ?? "";

        double base = 4000.0;
        if (value.containsKey('salary')) {
          base = double.tryParse(value['salary'].toString()) ?? 4000.0;
        } else if (role.toLowerCase().contains("manager")) {
          base = 5500.0;
        } else if (role.toLowerCase().contains("technician")) {
          base = 3500.0;
        }

        int checkIns = checkInCounts[id] ?? 0;
        double bonus = checkIns * 50.0;
        if (bonus > 1000) bonus = 1000;

        int lates = lateCounts[id] ?? 0;
        double deduct = lates * 100.0;

        totalPayout += (base + bonus - deduct);
        totalBonuses += bonus;
        totalDeductions += deduct;

        temp.add({
          "key": key,
          "name": name,
          "base": base.toInt(),
          "bonus": bonus.toInt(),
          "deduct": deduct.toInt(),
          "status": deduct > 200 ? "Pending" : "Paid"
        });
      }
    });

    setState(() {
      _payrollData = temp;
      _totalPayout = totalPayout;
      _totalBonuses = totalBonuses;
      _totalDeductions = totalDeductions;
      _isLoading = false;
    });
  }

  Future<void> _editSalaryDialog(BuildContext context, String key, String name, double currentSalary) async {
    final controller = TextEditingController(text: currentSalary.toInt().toString());
    final newSalary = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001D3D),
        title: Text("Edit Base Salary for $name", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Base Salary (\$)",
            labelStyle: TextStyle(color: Colors.cyanAccent),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withOpacity(0.2), foregroundColor: Colors.cyanAccent),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newSalary != null && newSalary.isNotEmpty) {
      final salaryVal = double.tryParse(newSalary);
      if (salaryVal != null) {
        setState(() => _isLoading = true);
        final success = await FirebaseService.updateWorkerSalary(key, salaryVal);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Salary updated successfully")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update salary")),
          );
        }
        _fetchPayroll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchPayroll,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (!_isLoading) _buildPayrollSummary(),
              if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),
              const SizedBox(height: 25),
              _buildHeader(),
              const SizedBox(height: 15),
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _buildPayrollTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayrollSummary() {
    return Row(
      children: [
        _statBox("Total Payout", "\$${_totalPayout.toInt()}", Colors.cyanAccent),
        _statBox("Total Bonuses", "\$${_totalBonuses.toInt()}", Colors.greenAccent),
        _statBox("Deductions", "\$${_totalDeductions.toInt()}", Colors.redAccent),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Employee Payroll", 
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        ElevatedButton.icon(
          onPressed: _fetchPayroll,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text("Refresh"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
            foregroundColor: Colors.cyanAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollTable() {
    if (_payrollData.isEmpty) {
      return const Center(child: Text("No payroll records found", style: TextStyle(color: Colors.white70)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _tableHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: _payrollData.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  itemBuilder: (context, index) {
                    final item = _payrollData[index];
                    double total = (item['base'] + item['bonus'] - item['deduct']).toDouble();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                          Expanded(
                            flex: 2, 
                            child: Row(
                              children: [
                                Text("\$${item['base']}", style: const TextStyle(color: Colors.white70)),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _editSalaryDialog(context, item['key'], item['name'], item['base'].toDouble()),
                                  child: const Icon(Icons.edit, color: Colors.cyanAccent, size: 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text("+\$${item['bonus']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 13))),
                          Expanded(flex: 2, child: Text("-\$${item['deduct']}", style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                          Expanded(
                            flex: 2, 
                            child: Text("\$$total", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
                          ),
                          _statusBadge(item['status']),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white.withOpacity(0.08),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Worker", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Base", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Bonus", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Deduct", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Net Total", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          SizedBox(width: 80, child: Text("Status", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == "Paid" ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          status, 
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}