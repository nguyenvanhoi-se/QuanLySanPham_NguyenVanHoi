import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'product_api.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto(this.image, {super.key, this.size = 56});
  final String image;
  final double size;
  @override
  Widget build(BuildContext context) {
    const fallback = Center(
      child: Icon(Icons.image_outlined, size: 34, color: Color(0xff91a49a)),
    );
    Widget photo = fallback;
    if (image.isNotEmpty) {
      try {
        photo = Image.memory(
          base64Decode(image),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => fallback,
        );
      } on FormatException {
        photo = fallback;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xffedf2ee),
        child: SizedBox.square(dimension: size, child: photo),
      ),
    );
  }
}

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.product});
  final Product? product;
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.product?.name);
  late final price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final quantity = TextEditingController(
    text: widget.product?.quantity.toString(),
  );
  late String image = widget.product?.image ?? '';
  bool busy = false;
  String error = '';

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 75,
      );
      if (file == null) return;
      if (await file.length() > 1024 * 1024) {
        throw Exception('Ảnh vượt 1 MiB sau khi thu nhỏ.');
      }
      final encoded = base64Encode(await file.readAsBytes());
      if (mounted) setState(() => image = encoded);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (image.isEmpty) {
      setState(() => error = 'Vui lòng chọn ảnh sản phẩm.');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await ProductApi.save(
        Product(
          widget.product?.id ?? '',
          name.text.trim(),
          int.parse(price.text.trim()),
          int.parse(quantity.text.trim()),
          image,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
  }

  Widget numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'Số lượng'
              ? Icons.inventory_2_outlined
              : Icons.payments_outlined,
        ),
      ),
      validator: (value) {
        final n = int.tryParse((value ?? '').trim());
        return n == null || n < 0 ? 'Nhập số nguyên từ 0 trở lên.' : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: form,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product == null
                                ? 'Thông tin sản phẩm mới'
                                : 'Cập nhật thông tin',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Nhập thông tin cơ bản và hình ảnh sản phẩm.',
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xfff4f7f1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xffe3eadf),
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: ProductPhoto(image, size: 156),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ảnh được tối ưu khi tải lên.',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: busy ? null : pick,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: Text(
                                    image.isEmpty
                                        ? 'Chọn ảnh sản phẩm'
                                        : 'Thay đổi ảnh',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: name,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Tên sản phẩm',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (s) => (s ?? '').trim().isEmpty
                                ? 'Nhập tên sản phẩm.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, box) {
                              final priceField = numberField(
                                price,
                                'Giá (đồng)',
                              );
                              final quantityField = numberField(
                                quantity,
                                'Số lượng',
                              );
                              return box.maxWidth < 420
                                  ? Column(
                                      children: [
                                        priceField,
                                        const SizedBox(height: 14),
                                        quantityField,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: priceField),
                                        const SizedBox(width: 14),
                                        Expanded(child: quantityField),
                                      ],
                                    );
                            },
                          ),
                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : save,
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(busy ? 'Đang lưu…' : 'Lưu sản phẩm'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
