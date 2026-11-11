import 'package:flutter/material.dart';

import 'login_page.dart';
import 'product_api.dart';
import 'product_form.dart';

const _ink = Color(0xff18231f);
const _muted = Color(0xff627369);
const _canvas = Color(0xfff4f6f2);
const _green = Color(0xff176b52);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: ProductApi.session,
    builder: (context, token, _) => MaterialApp(
      key: ValueKey(token != null),
      debugShowCheckedModeBanner: false,
      title: 'Greenly Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _canvas,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: _muted, height: 1.45),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe5ebe7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe5ebe7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIconColor: _muted,
          suffixIconColor: _muted,
          errorMaxLines: 3,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _green,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: Color(0xffcedbd1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xffe9eeeb)),
          ),
        ),
      ),
      home: token == null ? const LoginPage() : const ProductListPage(),
    ),
  );
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final search = TextEditingController();
  late Future<List<Product>> items = ProductApi.list('');
  String keyword = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {
      items = ProductApi.list(keyword);
    });
  }

  void submitSearch() {
    keyword = search.text.trim();
    refresh();
  }

  Future<void> edit([Product? product]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductForm(product: product)),
    );
    if (mounted && saved == true) {
      refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Đã thêm sản phẩm' : 'Đã cập nhật sản phẩm',
          ),
        ),
      );
    }
  }

  Future<void> remove(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline,
          color: Color(0xffc44747),
          size: 30,
        ),
        title: const Text('Xóa sản phẩm này?'),
        content: Text(
          '“${product.name}” sẽ bị xóa khỏi danh sách.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffb63f3f),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa sản phẩm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProductApi.remove(product.id);
      if (mounted) {
        refresh();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> logout() async {
    try {
      await ProductApi.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxWidth < 640;
              final inset = compact ? 16.0 : 40.0;
              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, 24, inset, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _green,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GREENLY',
                                      style: TextStyle(
                                        color: _green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      'Không gian quản trị',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Đăng xuất',
                                onPressed: logout,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _green,
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 28 : 40),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(compact ? 22 : 30),
                            decoration: BoxDecoration(
                              color: const Color(0xffe6eee3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xffdce6d8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DANH MỤC CỬA HÀNG',
                                        style: TextStyle(
                                          color: _green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Sản phẩm của bạn',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontSize: compact ? 26 : 34,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mọi sản phẩm, một nơi quản lý.',
                                        style: TextStyle(
                                          color: Color(0xff4e6756),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!compact) ...[
                                  const SizedBox(width: 24),
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .6),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: _green,
                                      size: 42,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Danh sách sản phẩm',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tìm kiếm, thêm mới và cập nhật sản phẩm.',
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, toolbar) {
                              final searchField = TextField(
                                controller: search,
                                onSubmitted: (_) => submitSearch(),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Tìm theo tên sản phẩm',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: 'Tìm kiếm',
                                    onPressed: submitSearch,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              );
                              final addButton = FilledButton.icon(
                                onPressed: () => edit(),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Thêm sản phẩm'),
                              );
                              return toolbar.maxWidth < 540
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        searchField,
                                        const SizedBox(height: 12),
                                        addButton,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: searchField),
                                        const SizedBox(width: 16),
                                        addButton,
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                  FutureBuilder<List<Product>>(
                    future: items,
                    builder: (context, snapshot) {
                      Widget state;
                      if (snapshot.connectionState != ConnectionState.done) {
                        state = const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        state = _StatePanel(
                          icon: Icons.cloud_off_outlined,
                          title: 'Không tải được sản phẩm',
                          message: snapshot.error.toString(),
                          action: TextButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        );
                      } else {
                        final products = snapshot.data ?? [];
                        if (products.isNotEmpty) {
                          final width = box.maxWidth - inset * 2;
                          final columns = width >= 960
                              ? 3
                              : width >= 600
                              ? 2
                              : 1;
                          Widget card(int index) => _ProductCard(
                            product: products[index],
                            compact: columns == 1,
                            onEdit: () => edit(products[index]),
                            onDelete: () => remove(products[index]),
                          );
                          return SliverPadding(
                            padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                            sliver: columns == 1
                                ? SliverList.separated(
                                    itemCount: products.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, index) => card(index),
                                  )
                                : SliverGrid.builder(
                                    itemCount: products.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20,
                                          mainAxisExtent:
                                              330 +
                                              (MediaQuery.textScalerOf(context)
                                                          .scale(14) -
                                                      14) *
                                                  4,
                                        ),
                                    itemBuilder: (_, index) => card(index),
                                  ),
                          );
                        }
                        state = _StatePanel(
                          icon: keyword.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off_rounded,
                          title: keyword.isEmpty
                              ? 'Chưa có sản phẩm'
                              : 'Không tìm thấy sản phẩm',
                          message: keyword.isEmpty
                              ? 'Thêm sản phẩm đầu tiên để bắt đầu quản lý cửa hàng.'
                              : 'Thử tìm bằng tên khác.',
                        );
                      }
                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
                        sliver: SliverToBoxAdapter(child: state),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });
  final Product product;
  final VoidCallback onEdit, onDelete;
  final bool compact;
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: hovered
            ? (Matrix4.identity()..translateByDouble(0, -3, 0, 1))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hovered ? const Color(0xffc9ded2) : const Color(0xffe9eeeb),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: .08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: widget.compact
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ProductPhoto(p.image, size: 76),
                    const SizedBox(width: 12),
                    Expanded(child: _productInfo(p)),
                    _actions(),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductPhoto(p.image, size: double.infinity),
                          Positioned(top: 12, right: 12, child: _actions()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _productInfo(p),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _productInfo(Product p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        p.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 7),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${p.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ₫',
            style: const TextStyle(
              color: _green,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.quantity == 0
                  ? const Color(0xfffff2e5)
                  : const Color(0xffedf3ec),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.quantity == 0 ? 'Hết hàng' : 'Kho: ${p.quantity}',
              style: TextStyle(
                color: p.quantity == 0 ? const Color(0xff8a5426) : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _actions() => PopupMenuButton<String>(
    tooltip: 'Thao tác với ${widget.product.name}',
    onSelected: (value) =>
        value == 'edit' ? widget.onEdit() : widget.onDelete(),
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'edit',
        child: ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Chỉnh sửa'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text('Xóa'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        shape: BoxShape.circle,
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Icon(Icons.more_horiz_rounded, size: 20),
      ),
    ),
  );
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xffedf3ec),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: _green),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 10), action!],
            ],
          ),
        ),
      ),
    ),
  );
}
