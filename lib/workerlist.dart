import 'dart:ui';
import 'package:flutter/material.dart';
import 'AddWorkerpage.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';

class WorkersPage extends StatefulWidget {
  final String searchQuery;
  const WorkersPage({super.key, this.searchQuery = ""});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  int _currentFilterIndex = 0; 
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    setState(() => _isLoading = true);
    final data = await FirebaseService.getWorkers();
    final List<Map<String, dynamic>> temp = [];
    data.forEach((key, value) {
      if (value is Map) {
        temp.add({
          "key": key,
          "name": value["name"] ?? "",
          "id": value["id"] ?? "",
          "phone": value["phone"] ?? "",
          "email": value["email"] ?? "",
          "department": value["department"] ?? "",
          "branch": value["branch"] ?? "",
          "role": value["role"] ?? "",
          "status": value["status"] ?? "Active",
        });
      }
    });
    setState(() {
      _workers = temp;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(BuildContext context, String key, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001D3D),
        title: const Text("Delete Worker", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete worker $name?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await FirebaseService.deleteWorker(key);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Worker deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete worker")),
        );
      }
      _fetchWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    // Apply filters
    final filteredList = _workers.where((worker) {
      if (_currentFilterIndex == 1 && !worker['role'].toString().toLowerCase().contains("manager")) return false;
      if (_currentFilterIndex == 2 && !worker['role'].toString().toLowerCase().contains("technician")) return false;

      if (widget.searchQuery.isNotEmpty) {
        final nameLower = worker['name'].toString().toLowerCase();
        final idLower = worker['id'].toString().toLowerCase();
        final queryLower = widget.searchQuery.toLowerCase();
        return nameLower.contains(queryLower) || idLower.contains(queryLower);
      }
      return true;
    }).toList();

    Color themeColor = _currentFilterIndex == 1 ? Colors.cyanAccent : Colors.tealAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 25),
      child: Column(
        children: [
          Wrap(
            spacing: 10, 
            runSpacing: 10, 
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _navButton("All Workers", 0, isMobile),
              _navButton("Managers", 1, isMobile), 
              _navButton("Technicians", 2, isMobile),
              if (!isMobile) const SizedBox(width: 20), 
              _buildAddButton(context, isMobile),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildListView(filteredList, themeColor, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String title, int index, bool isMobile) {
    bool isSelected = _currentFilterIndex == index;
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 15 : 25, 
          vertical: isMobile ? 15 : 20
        ),
        backgroundColor: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        setState(() {
          _currentFilterIndex = index;
        });
      },
      child: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isSelected ? Colors.white : Colors.white38,
          fontSize: isMobile ? 12 : 14, 
        )
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, bool isMobile) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 107, 109, 111),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 15 : 25, 
          vertical: isMobile ? 15 : 20
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddWorkerPage()),
        );
        _fetchWorkers();
      },
      icon: Icon(Icons.add, color: Colors.white, size: isMobile ? 18 : 22),
      label: Text(
        isMobile ? "Add" : "Add New Worker", 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> filteredList, Color themeColor, bool isMobile) {
    if (filteredList.isEmpty) {
      return const Center(child: Text("No workers found", style: TextStyle(color: Colors.white70)));
    }
    return _glassContainer(
      key: ValueKey(_currentFilterIndex),
      child: RefreshIndicator(
        onRefresh: _fetchWorkers,
        child: ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: filteredList.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final worker = filteredList[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20),
              leading: CircleAvatar(
                radius: isMobile ? 20 : 25,
                backgroundColor: themeColor.withOpacity(0.1),
                child: Icon(Icons.person, color: themeColor, size: isMobile ? 20 : 28),
              ),
              title: Text(
                worker['name'] ?? "", 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                )
              ),
              subtitle: Text(
                "ID: ${worker['id']} | ${worker['role']} | ${worker['status']}", 
                style: TextStyle(color: Colors.white38, fontSize: isMobile ? 10 : 12)
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, worker['key'], worker['name']),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child, Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: child,
        ),
      ),
    );
  }
}