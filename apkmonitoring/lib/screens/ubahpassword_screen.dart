import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class UbahPasswordPage extends StatefulWidget {
  const UbahPasswordPage({super.key});

  @override
  _UbahPasswordPageState createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldUsernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _emailController = TextEditingController(); // Kolom email

  bool _isLoading = false;

  Future<Map<String, String?>> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username'),
      'password': prefs.getString('password'),
    };
  }

  Future<bool> _saveNewCredentials(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateOldCredentials() async {
    final stored = await _loadStoredCredentials();

    if (stored['username'] == null || stored['password'] == null) {
      return true;
    }

    return stored['username'] == _oldUsernameController.text &&
        stored['password'] == _oldPasswordController.text;
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email reset password telah dikirim ke $email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim email: $e')));
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        bool isOldCredentialsValid = await _validateOldCredentials();

        if (!isOldCredentialsValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username atau password lama tidak sesuai!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Kirim email reset password
        await _sendPasswordResetEmail(_emailController.text);

        // Simpan username dan password baru
        bool isSaved = await _saveNewCredentials(
          _newUsernameController.text,
          _newPasswordController.text,
        );

        if (isSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perubahan berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );

          // Kosongkan semua controller
          _oldUsernameController.clear();
          _oldPasswordController.clear();
          _newUsernameController.clear();
          _newPasswordController.clear();
          _emailController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan perubahan. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _oldUsernameController.dispose();
    _oldPasswordController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _emailController.dispose(); // Dispose email controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Atur Ulang Username & Password')),
      endDrawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Data Lama",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _oldUsernameController,
                decoration: InputDecoration(
                  labelText: 'Username Lama',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Lama',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isLoading,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              SizedBox(height: 20),
              Text(
                "Data Baru",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _newUsernameController,
                decoration: InputDecoration(
                  labelText: 'Username Baru',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
                validator: (value) {
                  if (value!.isEmpty) return 'Wajib diisi';
                  if (value.length < 3) return 'Username minimal 3 karakter';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isLoading,
                validator: (value) {
                  if (value!.isEmpty) return 'Wajib diisi';
                  if (value.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Menyimpan...'),
                        ],
                      )
                    : Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}