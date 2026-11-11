import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nguyen_van_hoi_gk/main.dart';
import 'package:nguyen_van_hoi_gk/product_api.dart';
import 'package:nguyen_van_hoi_gk/product_form.dart';

void main() {
  setUp(() => ProductApi.session.value = null);
  test('Dùng địa chỉ máy chủ phù hợp khi chạy trên giả lập Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(Uri.parse(ProductApi.base).host, kIsWeb ? '127.0.0.1' : '10.0.2.2');
  });

  testWidgets('Yêu cầu đăng nhập trước khi quản lý sản phẩm', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Thêm sản phẩm'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Nhập email và mật khẩu quản trị.'), findsOneWidget);
  });

  testWidgets('Tìm kiếm lên lịch tải lại danh sách trong chế độ debug', (
    tester,
  ) async {
    final queries = <String?>[];
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: ProductListPage()));
        await tester.enterText(find.byType(TextField), 'Áo');
        await tester.tap(find.byTooltip('Tìm kiếm'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(queries.last, 'Áo');
        expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
      },
      () => MockClient((request) async {
        queries.add(request.url.queryParameters['search']);
        return http.Response('[]', 200);
      }),
    );
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(700, 600),
    const Size(1440, 900),
    const Size(844, 390),
  ]) {
    testWidgets('Bố cục danh sách và biểu mẫu tại $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await http.runWithClient(
        () async {
          await tester.pumpWidget(const MyApp());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Đăng nhập'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Đăng nhập'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          ProductApi.session.value = 'test-session';
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Thêm sản phẩm'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Thêm sản phẩm'));
          await tester.pumpAndSettle();
          expect(find.text('Thông tin sản phẩm mới'), findsOneWidget);
          await tester.ensureVisible(find.text('Lưu sản phẩm'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Lưu sản phẩm'));
          await tester.pumpAndSettle();
          expect(find.text('Nhập tên sản phẩm.'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode([
              {
                '_id': 'product-1',
                'name': 'Sản phẩm có tên dài để kiểm tra bố cục trên nhiều kích thước màn hình',
                'price': 1250000,
                'soluong': 15,
                'image': '',
              },
              {
                '_id': 'product-2',
                'name': 'Sản phẩm hết hàng',
                'price': 25000,
                'soluong': 0,
                'image': 'invalid-image',
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
    });
  }

  testWidgets('Tìm kiếm khi bàn phím mở và chữ lớn không tràn', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const ProductListPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Không có');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('[]', 200)));
  });

  testWidgets('Lỗi tải danh sách có thể thử lại', (tester) async {
    var requests = 0;
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: ProductListPage()));
        await tester.pumpAndSettle();
        expect(find.text('Không tải được sản phẩm'), findsOneWidget);
        await tester.ensureVisible(find.text('Thử lại'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.text('Chưa có sản phẩm'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (_) async => ++requests == 1
            ? http.Response('{"message":"Không thể kết nối máy chủ"}', 500)
            : http.Response('[]', 200),
      ),
    );
  });

  testWidgets('Sửa và xóa giữ nguyên yêu cầu API', (tester) async {
    final requests = <http.Request>[];
    const image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXioAAAAASUVORK5CYII=';
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MyApp());
        ProductApi.session.value = 'test-session';
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chỉnh sửa'));
        await tester.pumpAndSettle();
        expect(find.byType(ProductForm), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).first, 'Tên đã sửa');
        await tester.ensureVisible(find.text('Lưu sản phẩm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu sản phẩm'));
        await tester.pumpAndSettle();
        final saved = requests.singleWhere((r) => r.method == 'PUT');
        expect(jsonDecode(saved.body), {
          'name': 'Tên đã sửa',
          'price': 1250000,
          'soluong': 15,
          'image': image,
        });
        await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Giữ lại'));
        await tester.pumpAndSettle();
        expect(requests.where((r) => r.method == 'DELETE'), isEmpty);
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Xóa sản phẩm'));
        await tester.pumpAndSettle();
        expect(requests.where((r) => r.method == 'DELETE').length, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(
          request.method == 'GET'
              ? jsonEncode([
                  {
                    '_id': 'product-1',
                    'name': 'Sản phẩm thử',
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
