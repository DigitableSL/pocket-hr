import 'package:cn_pocket_hr/ui/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/screens/todos/devices/mobile_todos_screen.dart';

class HRTodo extends StatefulWidget {
  static const String routeName = '/todos';

  const HRTodo({super.key});

  @override
  State<HRTodo> createState() => _HRTodoState();
}

class _HRTodoState extends State<HRTodo> {
  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileTodosScreen(),
    );
  }
}
