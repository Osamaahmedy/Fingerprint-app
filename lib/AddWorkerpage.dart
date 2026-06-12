import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';

class AddWorkerPage extends StatefulWidget {
  const AddWorkerPage({super.key});

  @override
  State<AddWorkerPage> createState() => _AddWorkerPageState();
}

class _AddWorkerPageState extends State<AddWorkerPage> {
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedBranch;

  final List<String> _departments = ["Engineering", "Management", "Technicians", "Security"];
  final List<String> _branches = ["Main Branch - Dubai", "Sana'a Branch", "Riyadh Branch"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // الألوان الرسمية التي طلبتها
            colors: [
              Color(0xFF434141), // رمادي فحمي
              Color(0xFF02101F), // كحلي غامق جداً
              Color(0xFF0C161F), // كحلي صخري للعمق
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: _buildGlassCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // زجاج داكن خفيف
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 25),
              _buildProfileImagePicker(),
              const SizedBox(height: 25),
              _buildTextField("Full Name", Icons.person_outline, _nameController),
              const SizedBox(height: 15),
              _buildTextField("Worker ID (e.g. #B-900)", Icons.badge_outlined, _idController),
              const SizedBox(height: 15),
              _buildTextField("Phone Number", Icons.phone_android, _phoneController),
              const SizedBox(height: 15),
              _buildTextField("Email Address", Icons.email_outlined, _emailController),
              const SizedBox(height: 15),
              _buildDropdownField("Select Department", Icons.lan_outlined, _departments, _selectedDepartment, (val) {
                setState(() => _selectedDepartment = val);
              }),
              const SizedBox(height: 15),
              _buildDropdownField("Select Branch", Icons.location_on_outlined, _branches, _selectedBranch, (val) {
                setState(() => _selectedBranch = val);
              }),
              const SizedBox(height: 30),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
        ),
        const Text(
          "Worker Registration",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildProfileImagePicker() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 28),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // خلفية أغمق للحقول لزيادة التباين
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent.shade100, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, IconData icon, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Row(
            children: [
              Icon(icon, color: Colors.blueAccent.shade100, size: 20),
              const SizedBox(width: 10),
              Text(hint, style: const TextStyle(color: Colors.white30, fontSize: 14)),
            ],
          ),
          dropdownColor: const Color(0xFF1A2633), // لون القائمة المنسدلة متناسق مع الخلفية
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white30),
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () async {
              final name = _nameController.text.trim();
              final id = _idController.text.trim();
              final phone = _phoneController.text.trim();
              final email = _emailController.text.trim();
              final dept = _selectedDepartment ?? "Technicians";
              final branch = _selectedBranch ?? "Main Branch";

              if (name.isEmpty || id.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("يرجى ملء جميع الحقول المطلوبة (الاسم، المعرف، الهاتف)")),
                );
                return;
              }

              setState(() => _isLoading = true);
              final role = dept == "Management"
                  ? "Site Manager"
                  : (dept == "Technicians" ? "Field Technician" : "Site Engineer");

              final success = await FirebaseService.addWorker({
                "name": name,
                "id": id,
                "phone": phone,
                "email": email,
                "department": dept,
                "branch": branch,
                "role": role,
                "status": "Active"
              });
              setState(() => _isLoading = false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم إضافة الموظف بنجاح!")),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("حدث خطأ أثناء حفظ بيانات الموظف!")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5), // أزرق رسمي (Corporate Blue)
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("Save Worker", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}