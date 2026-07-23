import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProductFormWidget extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String? selectedCategory;
  final String? selectedCondition;
  final String? selectedSize;
  final String? selectedColor;
  final Function(String?) onCategoryChanged;
  final Function(String?) onConditionChanged;
  final Function(String?) onSizeChanged;
  final Function(String?) onColorChanged;
  final bool isWantedProduct;

  const ProductFormWidget({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.selectedCategory,
    required this.selectedCondition,
    required this.selectedSize,
    required this.selectedColor,
    required this.onCategoryChanged,
    required this.onConditionChanged,
    required this.onSizeChanged,
    required this.onColorChanged,
    required this.isWantedProduct,
  });

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final List<Map<String, dynamic>> _categories = [
    {
      "value": "vetements",
      "label": "Vêtements",
      "hasSize": true,
      "hasColor": true,
    },
    {
      "value": "vetements_fetes",
      "label": "Vêtements de fêtes",
      "hasSize": true,
      "hasColor": true,
    },
    {
      "value": "chaussures",
      "label": "Chaussures",
      "hasSize": true,
      "hasColor": true,
    },
    {"value": "jeux", "label": "Jeux", "hasSize": false, "hasColor": false},
    {"value": "livres", "label": "Livres", "hasSize": false, "hasColor": false},
    {
      "value": "services",
      "label": "Services",
      "hasSize": false,
      "hasColor": false
    },
    {"value": "autres", "label": "Autres", "hasSize": false, "hasColor": false},
  ];

  final List<String> _conditions = [
    "Neuf",
    "Très bon état",
    "Bon état",
    "État correct",
    "À réparer",
  ];

  final List<String> _sizes = [
    "XS",
    "S",
    "M",
    "L",
    "XL",
    "XXL",
    "36",
    "37",
    "38",
    "39",
    "40",
    "41",
    "42",
    "43",
    "44",
    "45",
  ];

  final List<String> _colors = [
    "Noir",
    "Blanc",
    "Gris",
    "Rouge",
    "Bleu",
    "Vert",
    "Jaune",
    "Orange",
    "Rose",
    "Violet",
    "Marron",
    "Beige",
    "Multicolore",
  ];

  bool get _showSizeField {
    if (widget.selectedCategory == null) return false;
    final category = _categories.firstWhere(
      (cat) => cat["value"] == widget.selectedCategory,
      orElse: () => {"hasSize": false},
    );
    return category["hasSize"] == true;
  }

  bool get _showColorField {
    if (widget.selectedCategory == null) return false;
    final category = _categories.firstWhere(
      (cat) => cat["value"] == widget.selectedCategory,
      orElse: () => {"hasColor": false},
    );
    return category["hasColor"] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleField(),
        SizedBox(height: 25.5),
        _buildCategoryField(),
        SizedBox(height: 25.5),
        if (!widget.isWantedProduct) ...[
          _buildConditionField(),
          SizedBox(height: 25.5),
          _buildPriceField(),
          SizedBox(height: 25.5),
        ],
        if (_showSizeField) ...[_buildSizeField(), SizedBox(height: 25.5)],
        if (_showColorField) ...[_buildColorField(), SizedBox(height: 25.5)],
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isWantedProduct ? 'Que recherchez-vous ?' : 'Titre du produit',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: widget.titleController,
          maxLength: 50,
          decoration: InputDecoration(
            hintText: widget.isWantedProduct
                ? 'Ex: Chaussures de sport Nike taille 42'
                : 'Ex: T-shirt Nike taille M',
            counterText: '${widget.titleController.text.length}/50',
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        DropdownButtonFormField<String>(
          initialValue: widget.selectedCategory,
          decoration: const InputDecoration(
            hintText: 'Sélectionner une catégorie',
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category["value"],
              child: Text(category["label"]),
            );
          }).toList(),
          onChanged: (value) {
            widget.onCategoryChanged(value);
            // Reset size and color when category changes
            if (!_showSizeField) widget.onSizeChanged(null);
            if (!_showColorField) widget.onColorChanged(null);
          },
        ),
      ],
    );
  }

  Widget _buildConditionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du produit',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        Column(
          children: _conditions.map((condition) {
            return RadioListTile<String>(
              title: Text(
                condition,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              value: condition,
              groupValue: widget.selectedCondition,
              onChanged: widget.onConditionChanged,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taille',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        DropdownButtonFormField<String>(
          initialValue: widget.selectedSize,
          decoration: const InputDecoration(
            hintText: 'Sélectionner une taille',
          ),
          items: _sizes.map((size) {
            return DropdownMenuItem<String>(value: size, child: Text(size));
          }).toList(),
          onChanged: widget.onSizeChanged,
        ),
      ],
    );
  }

  Widget _buildColorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        DropdownButtonFormField<String>(
          initialValue: widget.selectedColor,
          decoration: const InputDecoration(
            hintText: 'Sélectionner une couleur',
          ),
          items: _colors.map((color) {
            return DropdownMenuItem<String>(
              value: color,
              child: Text(color),
            );
          }).toList(),
          onChanged: widget.onColorChanged,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: widget.descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: widget.isWantedProduct
                ? 'Décrivez précisément ce que vous recherchez...'
                : 'Décrivez votre produit en détail...',
            counterText: '${widget.descriptionController.text.length}/500',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prix (FCFA)',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.5),
        TextFormField(
          controller: widget.priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ex: 5000',
            suffixText: 'FCFA',
          ),
        ),
      ],
    );
  }
}
