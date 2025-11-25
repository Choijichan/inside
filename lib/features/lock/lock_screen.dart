import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/pin_lock.dart';
import '../../root_scaffold.dart'; // ✅ RootScaffold를 여기서 가져옴

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  String? _error;

  void _submit() {
    final pinLock = context.read<PinLockController>();
    final input = _controller.text.trim();

    if (pinLock.verify(input)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootScaffold()),
      );
    } else {
      setState(() {
        _error = 'PIN이 올바르지 않습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'PIN을 입력하세요',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: '4자리 PIN',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
