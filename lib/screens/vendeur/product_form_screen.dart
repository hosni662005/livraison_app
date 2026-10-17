import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/product_repository.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});
  bool get isEdit => productId != null;
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _desc = TextEditingController();
  final _prix = TextEditingController();
  final _imageUrl = TextEditingController();
  String _categorie = Category.plats.value;
  bool _disponible = true;
  bool _loading = false;
  bool _initLoading = false;
  Product? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _initLoading = true);
    try {
      final p = await ProductRepository().getById(widget.productId!);
      if (p != null && mounted) {
        _existing = p;
        _nom.text = p.nom;
        _desc.text = p.description;
        _prix.text = p.prix.toString();
        _imageUrl.text = p.imageUrl;
        _categorie = p.categorie;
        _disponible = p.disponible;
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _initLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = context.read<AuthProvider>().appUser!.id;
      if (widget.isEdit) {
        await ProductRepository().update(widget.productId!, {
          'nom': _nom.text.trim(),
          'description': _desc.text.trim(),
          'prix': double.parse(_prix.text.replaceAll(',', '.')),
          'imageUrl': _imageUrl.text.trim(),
          'categorie': _categorie,
          'disponible': _disponible,
        });
        if (!mounted) return;
        showSnack(context, 'Produit modifié');
      } else {
        final p = Product(
          id: '',
          nom: _nom.text.trim(),
          description: _desc.text.trim(),
          prix: double.parse(_prix.text.replaceAll(',', '.')),
          imageUrl: _imageUrl.text.trim(),
          categorie: _categorie,
          vendeurId: uid,
          disponible: _disponible,
          dateCreation: DateTime.now(),
        );
        await ProductRepository().create(p);
        if (!mounted) return;
        showSnack(context, 'Produit créé');
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nom.dispose(); _desc.dispose(); _prix.dispose(); _imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initLoading) {
      return Scaffold(appBar: AppBar(title: Text(widget.isEdit ? 'Modifier' : 'Nouveau produit')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Modifier produit' : 'Nouveau produit')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()), validator: (v) => Validators.required(v, field: 'Nom')),
          const SizedBox(height: 12),
          TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()), maxLines: 3, validator: (v) => Validators.required(v, field: 'Description')),
          const SizedBox(height: 12),
          TextFormField(controller: _prix, decoration: const InputDecoration(labelText: 'Prix (TND) *', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: Validators.prix),
          const SizedBox(height: 12),
          TextFormField(controller: _imageUrl, decoration: const InputDecoration(labelText: 'Image URL *', hintText: 'https://...', border: OutlineInputBorder()), validator: Validators.url),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categorie,
            decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
            items: Category.values.map((c) => DropdownMenuItem(value: c.value, child: Text(c.label))).toList(),
            onChanged: (v) => setState(() => _categorie = v!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(title: const Text('Disponible'), value: _disponible, onChanged: (v) => setState(() => _disponible = v)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.isEdit ? 'Enregistrer' : 'Créer'),
          ),
        ]),
      ),
    );
  }
}
