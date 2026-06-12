import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_2666/dashboard.dart';
import 'package:flutter_application_2666/worker.dart';
import 'package:flutter_application_2666/services/firebase_service.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLogin = true;
  bool _isAdminLogin = true;
  bool _isLoading = false;

  // تعريف المتحكمات لاستخراج النصوص من الحقول
  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _workerIdController = TextEditingController();
  final TextEditingController _workerPhoneController = TextEditingController();
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminUserController = TextEditingController();
  final TextEditingController _adminPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _workerIdController.dispose();
    _workerPhoneController.dispose();
    _adminNameController.dispose();
    _adminUserController.dispose();
    _adminPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF434141), Color(0xFF02101F), Color(0xFF0C161F)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: GlassContainer(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    const Icon(Icons.lock_open_rounded, size: 60, color: Colors.white70),
                    const SizedBox(height: 20),
                    Text(
                      _tabController.index == 0 ? "Worker Portal" : "Admin Panel",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF49695E),
                      tabs: const [Tab(text: "Worker"), Tab(text: "Admin")],
                    ),
                    const SizedBox(height: 30),
                    // تبديل الواجهات بناءً على التبويب المختار
                    _tabController.index == 0 ? _buildWorkerFields() : _buildAdminFields(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- واجهة العامل مع الشرط المطلوب ---
  Widget _buildWorkerFields() {
    return Column(
      children: [
        if (!_isLogin) _buildTextField("Full Name", Icons.person, _workerNameController),
        if (!_isLogin) const SizedBox(height: 15),
        _buildTextField("Worker ID", Icons.badge, _workerIdController),
        const SizedBox(height: 15),
        _buildTextField("Phone Number", Icons.phone, _workerPhoneController),
        const SizedBox(height: 25),
        _buildActionButton(_isLogin ? "Login" : "Sign Up", () async {
          if (_isLogin) {
            // Worker Login
            final workerId = _workerIdController.text.trim();
            final workerPhone = _workerPhoneController.text.trim();

            if (workerId.isEmpty || workerPhone.isEmpty) {
              _showErrorSnackBar("يرجى ملء جميع الحقول!");
              return;
            }

            // Fallback for testing
            if (workerId == "123" && workerPhone == "00000") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Start(workerData: {
                  "name": "John Doe",
                  "id": "123",
                  "phone": "00000",
                  "role": "Software Developer",
                  "department": "Engineering"
                })),
              );
              return;
            }

            setState(() => _isLoading = true);
            final workers = await FirebaseService.getWorkers();
            setState(() => _isLoading = false);

            bool found = false;
            Map<String, dynamic>? loggedInWorker;
            workers.forEach((key, value) {
              if (value['id']?.toString().trim() == workerId &&
                  value['phone']?.toString().trim() == workerPhone) {
                found = true;
                loggedInWorker = value;
              }
            });

            if (found && loggedInWorker != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Start(workerData: loggedInWorker)),
              );
            } else {
              _showErrorSnackBar("ID أو رقم الهاتف غير صحيح!");
            }
          } else {
            // Worker Sign Up
            final name = _workerNameController.text.trim();
            final id = _workerIdController.text.trim();
            final phone = _workerPhoneController.text.trim();

            if (name.isEmpty || id.isEmpty || phone.isEmpty) {
              _showErrorSnackBar("يرجى ملء جميع الحقول!");
              return;
            }

            setState(() => _isLoading = true);
            final success = await FirebaseService.addWorker({
              "name": name,
              "id": id,
              "phone": phone,
              "email": "",
              "department": "Technicians",
              "branch": "Main Branch",
              "role": "Field Technician",
              "status": "Active"
            });
            setState(() => _isLoading = false);

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم تسجيل الموظف بنجاح! يمكنك الدخول الآن.")),
              );
              setState(() => _isLogin = true);
            } else {
              _showErrorSnackBar("حدث خطأ أثناء التسجيل!");
            }
          }
        }),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
            style: const TextStyle(color: Colors.white60),
          ),
        )
      ],
    );
  }

  // --- واجهة المدير مع الشرط المطلوب ---
  Widget _buildAdminFields() {
    return Column(
      children: [
        if (!_isAdminLogin) _buildTextField("Admin Name", Icons.person, _adminNameController),
        if (!_isAdminLogin) const SizedBox(height: 15),
        _buildTextField("Admin Username", Icons.admin_panel_settings, _adminUserController),
        const SizedBox(height: 15),
        _buildTextField("Password", Icons.lock, _adminPassController, isPassword: true),
        const SizedBox(height: 25),
        _buildActionButton(_isAdminLogin ? "Access Dashboard" : "Register Admin", () async {
          final username = _adminUserController.text.trim();
          final password = _adminPassController.text.trim();

          if (username.isEmpty || password.isEmpty) {
            _showErrorSnackBar("يرجى ملء جميع الحقول!");
            return;
          }

          if (_isAdminLogin) {
            // Admin Login
            if ((username == "admin" && password == "4444") || (username == "" && password == "")) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainDashboard()),
              );
              return;
            }

            setState(() => _isLoading = true);
            final admins = await FirebaseService.getAdmins();
            setState(() => _isLoading = false);

            bool found = false;
            admins.forEach((key, value) {
              if (value['username']?.toString().trim() == username &&
                  value['password']?.toString().trim() == password) {
                found = true;
              }
            });

            if (found) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainDashboard()),
              );
            } else {
              _showErrorSnackBar("بيانات المدير غير صحيحة!");
            }
          } else {
            // Admin Sign Up
            final name = _adminNameController.text.trim();
            if (name.isEmpty) {
              _showErrorSnackBar("يرجى إدخال اسم المدير!");
              return;
            }

            setState(() => _isLoading = true);
            final success = await FirebaseService.addAdmin({
              "username": username,
              "password": password,
              "name": name,
            });
            setState(() => _isLoading = false);

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم تسجيل المدير بنجاح! يمكنك الدخول الآن.")),
              );
              setState(() => _isAdminLogin = true);
            } else {
              _showErrorSnackBar("حدث خطأ أثناء تسجيل المدير!");
            }
          }
        }),
        TextButton(
          onPressed: () => setState(() => _isAdminLogin = !_isAdminLogin),
          child: Text(
            _isAdminLogin ? "Don't have an Admin account? Sign Up" : "Already have an account? Login",
            style: const TextStyle(color: Colors.white60),
          ),
        )
      ],
    );
  }

  // دالة لإظهار رسالة خطأ بسيطة
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF49695E)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF49695E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- الكلاسات الخارجية (تأكد من وجودها في مشروعك) ---

// class Start extends StatelessWidget {
//   const Start({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF02101F),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.fingerprint, size: 100, color: Colors.blueAccent),
//             const SizedBox(height: 20),
//             const Text("Welcome to Start Page", style: TextStyle(color: Colors.white, fontSize: 22)),
//             TextButton(
//               onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const AuthPage())),
//               child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class MainDashboard extends StatelessWidget {
//   const MainDashboard({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Admin Dashboard"), backgroundColor: const Color(0xFF49695E)),
//       body: const Center(child: Text("Main Dashboard Content")),
//     );
//   }
// }

// كلاس الزجاج GlassContainer (كما هو في كودك)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  const GlassContainer({super.key, required this.child, this.width, this.height, this.constraints});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width, height: height, constraints: constraints,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}