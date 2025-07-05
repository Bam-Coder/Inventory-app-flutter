import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../controllers/product_provider.dart';
import '../../stock/models/stock_log_model.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _category = '';
  int _quantity = 0;
  double _price = 0;
  String _description = '';
  int _reorderThreshold = 5;
  String _unit = 'pièce';
  String _supplier = '';
  File? _imageFile;

  bool _isLoading = false;

  final List<String> _units = ['pièce', 'kg', 'litre', 'paquet', 'autre'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.addProduct(_name, _category, _quantity, _price,
        description: _description,
        reorderThreshold: _reorderThreshold,
        unit: _unit,
        supplier: _supplier,
        imagePath: _imageFile?.path,
      );
      if (!mounted) return;
      if (provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit ajouté avec succès')),
        );
        await provider.loadProducts(forceRefresh: true);
        Navigator.pop(context); // Retour à la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(provider.error))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${extractErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Center(
                      child: _imageFile == null
                          ? Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom du produit'),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                    onSaved: (val) => _name = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                    onSaved: (val) => _category = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    onSaved: (val) => _description = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Fournisseur'),
                    onSaved: (val) => _supplier = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Quantité'),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Champ requis';
                            if (int.tryParse(val) == null) return 'Nombre invalide';
                            return null;
                          },
                          onSaved: (val) => _quantity = int.parse(val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Prix'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Champ requis';
                            final parsed = double.tryParse(val);
                            if (parsed == null) return 'Nombre invalide';
                            if (parsed <= 0) return 'Le prix doit être > 0';
                            return null;
                          },
                          onSaved: (val) => _price = double.parse(val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Seuil de réapprovisionnement'),
                          initialValue: '5',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Champ requis';
                            if (int.tryParse(val) == null) return 'Nombre invalide';
                            return null;
                          },
                          onSaved: (val) => _reorderThreshold = int.parse(val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unit,
                          decoration: const InputDecoration(labelText: 'Unité'),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => _unit = val ?? 'pièce'),
                          onSaved: (val) => _unit = val ?? 'pièce',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isLoading ? null : _submitForm,
                            child: const Text('Ajouter'),
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
