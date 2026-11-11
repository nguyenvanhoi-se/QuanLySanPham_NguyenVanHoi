import 'package:flutter/material.dart';

import 'product_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool obscure = true;
  String error = '';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Nhập email và mật khẩu quản trị.');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await ProductApi.login(email.text, password.text);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: LayoutBuilder(
              builder: (context, box) {
                final mobile = box.maxWidth < 820;
                final form = Padding(
                  padding: EdgeInsets.all(mobile ? 24 : 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xff176b52),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'GREENLY',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              color: Color(0xff176b52),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Chào mừng trở lại',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: mobile ? 27 : 30),
                      ),
                      const SizedBox(height: 8),
                      const Text('Đăng nhập để quản lý cửa hàng của bạn.'),
                      const SizedBox(height: 28),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: .4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Đăng nhập'),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 15,
                            color: Color(0xff627369),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Dành cho quản trị viên cửa hàng',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: mobile
                      ? form
                      : Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 590,
                                decoration: const BoxDecoration(
                                  color: Color(0xff174f3d),
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -32,
                                      bottom: -56,
                                      child: Icon(
                                        Icons.eco_rounded,
                                        size: 320,
                                        color: Color(0xff28634a),
                                      ),
                                    ),
                                    const Positioned(
                                      left: 36,
                                      right: 32,
                                      top: 54,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.eco_rounded,
                                            color: Color(0xffbdd9a5),
                                            size: 36,
                                          ),
                                          SizedBox(height: 32),
                                          Text(
                                            'GỌN GÀNG HƠN. HIỆU QUẢ HƠN.',
                                            style: TextStyle(
                                              color: Color(0xffbdd9a5),
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'Tăng trưởng\nbắt đầu từ\nquản lý tốt.',
                                            style: TextStyle(
                                              color: Color(0xfff4f6ed),
                                              fontSize: 38,
                                              height: 1.16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Một không gian gọn gàng cho mọi sản phẩm của bạn.',
                                            style: TextStyle(
                                              color: Color(0xffc2d5c8),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: form),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
