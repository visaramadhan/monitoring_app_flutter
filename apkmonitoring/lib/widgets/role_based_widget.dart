import 'package:flutter/material.dart';
import '../models/user_model.dart';

class RoleBasedWidget extends StatelessWidget {
  final UserModel? user;
  final Widget? adminWidget;
  final Widget? supervisorWidget;
  final Widget? karyawanWidget;
  final Widget? defaultWidget;

  const RoleBasedWidget({
    Key? key,
    required this.user,
    this.adminWidget,
    this.supervisorWidget,
    this.karyawanWidget,
    this.defaultWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) return defaultWidget ?? SizedBox.shrink();

    if (user!.isAdmin && adminWidget != null) {
      return adminWidget!;
    } else if (user!.isSupervisor && supervisorWidget != null) {
      return supervisorWidget!;
    } else if (user!.isKaryawan && karyawanWidget != null) {
      return karyawanWidget!;
    }

    return defaultWidget ?? SizedBox.shrink();
  }
}