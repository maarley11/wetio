import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/available_product_card.dart';
import './widgets/delivery_method_section.dart';
import './widgets/message_input_section.dart';
import './widgets/selected_products_section.dart';
import './widgets/target_product_card.dart';

class ExchangeProposal extends StatefulWidget {
  const ExchangeProposal({super.key});

  @override
  State<ExchangeProposal> createState() => _ExchangeProposalState();
}

class _ExchangeProposalState extends State<ExchangeProposal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _selectedProducts = [];
  DeliveryMethod _selectedDeliveryMethod = DeliveryMethod.handToHand;
  bool _isLoading = false;

  // Mode detection: creating new proposal or viewing received proposal
  bool _isViewingReceivedProposal = false;
  String? _exchangeId;
  Map<String, dynamic>? _exchangeData;

  // Target product will be received from navigation arguments
  Map<String, dynamic>? _targetProduct;

  // Real data for user's available products
  List<Map<String, dynamic>> _availableProducts = [];
  bool _isLoadingAvailableProducts = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Retrieve the data passed from the previous screen
    if (_targetProduct == null && _exchangeData == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // Check if this is a received proposal (has exchangeId)
        if (args.containsKey('exchangeId')) {
          _exchangeId = args['exchangeId'] as String;
          _isViewingReceivedProposal = true;
          _loadExchangeProposalDetails();
        } else {
          // Creating new proposal - product data passed
          setState(() {
            _targetProduct = args;
          });
        }
      }
    }
  }

  Future<void> _loadExchangeProposalDetails() async {
    if (_exchangeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data =
          await SupabaseService.getExchangeProposalDetails(_exchangeId!);
      if (data != null && mounted) {
        setState(() {
          _exchangeData = data;
          _messageController.text = data['message'] ?? '';
          _selectedDeliveryMethod = data['exchange_method'] == 'livraison'
              ? DeliveryMethod.delivery
              : DeliveryMethod.handToHand;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Erreur lors du chargement de la proposition');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMyAvailableProducts();
  }

  Future<void> _loadMyAvailableProducts() async {
    final user = SupabaseService.getCurrentUser();
    if (user == null) return;

    setState(() {
      _isLoadingAvailableProducts = true;
    });

    try {
      final products = await SupabaseService.getUserProducts(user.id);
      setState(() {
        _availableProducts = products;
        _isLoadingAvailableProducts = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvailableProducts = false;
        });
        _showErrorToast('Erreur lors du chargement de vos produits');
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleProductSelection(Map<String, dynamic> product) {
    setState(() {
      final isSelected = _selectedProducts.any((p) => p["id"] == product["id"]);
      if (isSelected) {
        _selectedProducts.removeWhere((p) => p["id"] == product["id"]);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  void _removeSelectedProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProducts.removeWhere((p) => p["id"] == product["id"]);
    });
  }

  bool _isProductSelected(Map<String, dynamic> product) {
    return _selectedProducts.any((p) => p["id"] == product["id"]);
  }

  void _onDeliveryMethodChanged(DeliveryMethod method) {
    setState(() {
      _selectedDeliveryMethod = method;
    });
  }

  bool _validateProposal() {
    if (_selectedProducts.isEmpty) {
      _showErrorToast("Veuillez sélectionner au moins un produit");
      return false;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorToast("Veuillez ajouter un message à votre proposition");
      return false;
    }

    return true;
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.successGreen,
      textColor: Colors.white,
    );
  }

  Future<void> _sendProposal() async {
    if (!_validateProposal()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetProductId = _targetProduct?['id']?.toString();
      final ownerId = _targetProduct?['owner_id']?.toString() ?? 
                      _targetProduct?['owner']?['id']?.toString() ??
                      _targetProduct?['user_id']?.toString() ??
                      _targetProduct?['userId']?.toString() ??
                      _targetProduct?['ownerId']?.toString() ?? '';
      final requesterProductId = _selectedProducts.first['id']?.toString();

      if (targetProductId == null || requesterProductId == null) {
        throw Exception("Informations du produit manquantes");
      }

      await SupabaseService.createExchangeProposal(
        targetProductId: targetProductId,
        ownerId: ownerId,
        requesterProductId: requesterProductId,
        message: _messageController.text,
        exchangeMethod: _selectedDeliveryMethod == DeliveryMethod.delivery ? 'livraison' : 'direct',
      );

      // Show success message
      _showSuccessToast("Proposition envoyée avec succès!");

      // Navigate back after short delay
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('DEBUG: Error sending proposal: $e');
      _showErrorToast("Erreur lors de l'envoi : $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptProposal() async {
    if (_exchangeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.acceptExchangeProposal(_exchangeId!);

      _showSuccessToast("Proposition acceptée!");

      // Small delay to let the user see the success message
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        // Redirect directly to the exchange chat/actions screen
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.exchangeConversationActions,
          arguments: {
            'exchangeId': _exchangeId,
            'targetProduct': _targetProduct,
            'proposedProduct': _selectedProducts.isNotEmpty ? _selectedProducts.first : null,
          },
        );
      }
    } catch (e) {
      _showErrorToast("Erreur lors de l'acceptation. Veuillez réessayer.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refuseProposal() async {
    if (_exchangeId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Refuser la proposition"),
        content: const Text(
            "Êtes-vous sûr de vouloir refuser cette proposition d'échange?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Refuser"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.refuseExchangeProposal(_exchangeId!);

      _showSuccessToast("Proposition refusée");

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorToast("Erreur lors du refus. Veuillez réessayer.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelProposal() {
    if (_selectedProducts.isNotEmpty ||
        _messageController.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Annuler la proposition"),
          content: const Text(
              "Êtes-vous sûr de vouloir annuler? Vos modifications seront perdues."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Continuer"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Annuler"),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
                0, _slideAnimation.value * MediaQuery.of(context).size.height),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, theme, colorScheme),
                    Expanded(
                      child: _isLoading && _exchangeData == null
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTargetProductSection(
                                      theme, colorScheme),
                                  SizedBox(height: 25.5),
                                  if (_isViewingReceivedProposal) ...[
                                    _buildRequesterInfoSection(
                                        theme, colorScheme),
                                    SizedBox(height: 25.5),
                                    _buildProposedProductSection(
                                        theme, colorScheme),
                                    SizedBox(height: 25.5),
                                    _buildMessageSection(theme, colorScheme),
                                    SizedBox(height: 25.5),
                                    _buildDeliveryInfoSection(
                                        theme, colorScheme),
                                  ] else ...[
                                    _buildAvailableProductsSection(
                                        theme, colorScheme),
                                    SizedBox(height: 25.5),
                                    SelectedProductsSection(
                                      selectedProducts: _selectedProducts,
                                      onRemoveProduct: _removeSelectedProduct,
                                    ),
                                    if (_selectedProducts.isNotEmpty)
                                      SizedBox(height: 25.5),
                                    MessageInputSection(
                                      messageController: _messageController,
                                    ),
                                    SizedBox(height: 25.5),
                                    DeliveryMethodSection(
                                      selectedMethod: _selectedDeliveryMethod,
                                      onMethodChanged: _onDeliveryMethodChanged,
                                    ),
                                  ],
                                  SizedBox(height: 85.0),
                                ],
                              ),
                            ),
                    ),
                    _buildBottomActions(context, theme, colorScheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                size: 24,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Text(
              _isViewingReceivedProposal
                  ? "Proposition reçue"
                  : "Proposition d'échange",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetProductSection(ThemeData theme, ColorScheme colorScheme) {
    Map<String, dynamic>? productToShow;

    if (_isViewingReceivedProposal && _exchangeData != null) {
      productToShow = _exchangeData!['target_product'];
    } else {
      productToShow = _targetProduct;
    }

    if (productToShow == null) {
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            SizedBox(height: 17.0),
            Text(
              'Produit non trouvé',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isViewingReceivedProposal ? "Votre produit" : "Produit souhaité",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        TargetProductCard(targetProduct: productToShow),
      ],
    );
  }

  Widget _buildRequesterInfoSection(ThemeData theme, ColorScheme colorScheme) {
    if (_exchangeData == null) return const SizedBox.shrink();

    final requester = _exchangeData!['requester'] as Map<String, dynamic>?;
    if (requester == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Proposé par",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: requester['avatar_url'] != null
                    ? NetworkImage(requester['avatar_url'])
                    : null,
                child: requester['avatar_url'] == null
                    ? Text(
                        (requester['full_name'] ?? 'U')[0].toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requester['pseudo'] ??
                          requester['full_name'] ??
                          'Utilisateur',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (requester['location'] != null) ...[
                      SizedBox(height: 4.3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            requester['location'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProposedProductSection(
      ThemeData theme, ColorScheme colorScheme) {
    if (_exchangeData == null) return const SizedBox.shrink();

    final requesterProduct =
        _exchangeData!['requester_product'] as Map<String, dynamic>?;
    if (requesterProduct == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Produit proposé en échange",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        TargetProductCard(targetProduct: requesterProduct),
      ],
    );
  }

  Widget _buildMessageSection(ThemeData theme, ColorScheme colorScheme) {
    if (_exchangeData == null || _exchangeData!['message'] == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Message",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _exchangeData!['message'],
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfoSection(ThemeData theme, ColorScheme colorScheme) {
    if (_exchangeData == null) return const SizedBox.shrink();

    final deliveryMethod = _exchangeData!['exchange_method'] ?? 'direct';
    final deliveryAddress = _exchangeData!['delivery_address'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mode de livraison",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                deliveryMethod == 'livraison'
                    ? Icons.local_shipping_outlined
                    : Icons.handshake_outlined,
                color: colorScheme.primary,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryMethod == 'livraison'
                          ? "Avec livreur"
                          : "En main propre",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (deliveryAddress != null) ...[
                      SizedBox(height: 4.3),
                      Text(
                        deliveryAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableProductsSection(
      ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sélectionner mes produits disponibles",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        if (_isLoadingAvailableProducts)
          const Center(child: CircularProgressIndicator())
        else if (_availableProducts.isEmpty)
          Container(
            padding: EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 32),
                SizedBox(height: 8.5),
                Text(
                  "Vous n'avez aucun produit à échanger",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                SizedBox(height: 17.0),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to add product or profile
                    Navigator.pushNamed(context, AppRoutes.homeFeed); 
                  },
                  child: const Text("Ajouter un produit"),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableProducts.length,
              itemBuilder: (context, index) {
                final product = _availableProducts[index];
                return AvailableProductCard(
                  product: product,
                  isSelected: _isProductSelected(product),
                  onTap: () => _toggleProductSelection(product),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActions(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _isViewingReceivedProposal
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _refuseProposal,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 25.5),
                        side: BorderSide(color: colorScheme.error),
                        foregroundColor: colorScheme.error,
                      ),
                      child: Text(
                        "Refuser",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _acceptProposal,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 25.5),
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Accepter",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _cancelProposal,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 25.5),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: Text(
                        "Annuler",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendProposal,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 25.5),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              "Envoyer la proposition",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
