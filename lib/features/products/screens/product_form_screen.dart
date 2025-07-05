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

  // Contrôleurs persistants
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _reorderThresholdController = TextEditingController(text: '5');

  String _unit = 'pièce';
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _units = ['pièce', 'kg', 'litre', 'paquet', 'autre'];

  // Pour stocker les valeurs lors du onSaved
  String _name = '';
  String _category = '';
  int _quantity = 0;
  double _price = 0;
  String _description = '';
  int _reorderThreshold = 5;
  String _supplier = '';

  String? _validateNumber(String? value, String label, {bool allowZero = false}) {
    if (value == null || value.isEmpty) return 'Champ requis';
    final numValue = num.tryParse(value);
    if (numValue == null) return '$label invalide';
    if (!allowZero && numValue <= 0) return '$label doit être > 0';
    return null;
  }

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
      await provider.addProduct(
        _name,
        _category,
        _quantity,
        _price,
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
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _reorderThresholdController.dispose();
    super.dispose();
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
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nom du produit',
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                    onSaved: (val) => _name = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _categoryController,
                    label: 'Catégorie',
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                    onSaved: (val) => _category = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 2,
                    onSaved: (val) => _description = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _supplierController,
                    label: 'Fournisseur',
                    onSaved: (val) => _supplier = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildQuantityPriceRow(),
                  const SizedBox(height: 16),
                  _buildReorderThresholdRow(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildQuantityPriceRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantité'),
            keyboardType: TextInputType.number,
            validator: (val) => _validateNumber(val, 'Quantité', allowZero: false),
            onSaved: (val) => _quantity = int.tryParse(val ?? '0') ?? 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Prix'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (val) => _validateNumber(val, 'Prix', allowZero: false),
            onSaved: (val) => _price = double.tryParse(val ?? '0') ?? 0,
          ),
        ),
      ],
    );
  }

  Widget _buildReorderThresholdRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _reorderThresholdController,
            decoration: const InputDecoration(labelText: 'Seuil de réapprovisionnement'),
            keyboardType: TextInputType.number,
            validator: (val) => _validateNumber(val, 'Seuil de réapprovisionnement', allowZero: true),
            onSaved: (val) => _reorderThreshold = int.tryParse(val ?? '5') ?? 5,
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
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
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
          );
  }
}
