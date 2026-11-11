import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nguyen_van_hoi_gk/main.dart';
import 'package:nguyen_van_hoi_gk/product_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Đăng nhập, tìm kiếm, sửa, xóa và đăng xuất trên thiết bị', (
    tester,
  ) async {
    final requests = <http.Request>[];
    const image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXioAAAAASUVORK5CYII=';
    await http.runWithClient(
      () async {
        ProductApi.session.value = null;
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'admin@example.test',
        );
        await tester.enterText(find.byType(TextField).last, 'test-password');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.text('Đăng nhập'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đăng nhập'));
        await tester.pumpAndSettle();
        expect(find.text('Danh sách sản phẩm'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Áo');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.tap(find.byTooltip('Tìm kiếm'));
        await tester.pumpAndSettle();
        expect(requests.last.url.queryParameters['search'], 'Áo');
        await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chỉnh sửa'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Áo sơ mi mới',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.text('Lưu sản phẩm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu sản phẩm'));
        await tester.pumpAndSettle();
        expect(requests.where((r) => r.method == 'PUT').length, 1);
        await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa sản phẩm'));
        await tester.pumpAndSettle();
        expect(requests.where((r) => r.method == 'DELETE').length, 1);
        await tester.ensureVisible(find.byTooltip('Đăng xuất'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Đăng xuất'));
        await tester.pumpAndSettle();
        expect(find.text('Chào mừng trở lại'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(
          request.url.path.endsWith('/auth/login')
              ? '{"token":"integration-session"}'
              : request.method == 'GET'
              ? jsonEncode([
                  {
                    '_id': 'sample-1',
                    'name': 'Áo sơ mi cotton',
                    'price': 1250000,
                    'soluong': 15,
                    'image': image,
                  },
                ])
              : '{}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
  });
}
