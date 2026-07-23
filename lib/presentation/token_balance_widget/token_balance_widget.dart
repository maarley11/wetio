import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/token_service.dart';
import './widgets/balance_indicator.dart';
import './widgets/token_history_modal.dart';

class TokenBalanceWidget extends StatefulWidget {
  const TokenBalanceWidget({Key? key}) : super(key: key);

  @override
  State<TokenBalanceWidget> createState() => _TokenBalanceWidgetState();
}

class _TokenBalanceWidgetState extends State<TokenBalanceWidget> {
  int _tokenBalance = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadTokenBalance();
  }

  Future<void> _loadTokenBalance() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final balance = await TokenService.instance.getCurrentTokenBalance();

      if (!mounted) return;

      setState(() {
        _tokenBalance = balance;
        _isLoading = false;
        _hasInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getFriendlyErrorMessage(e.toString());
        _isLoading = false;
        _hasInitialized = true;
        // Set default balance on error to prevent UI issues
        _tokenBalance = 0;
      });
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('non connecté')) {
      return 'Veuillez vous connecter';
    } else if (error.contains('réseau') || error.contains('network')) {
      return 'Problème de connexion';
    } else if (error.contains('timeout')) {
      return 'Délai d\'attente dépassé';
    } else {
      return 'Erreur de chargement';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state during initial load
    if (_isLoading && !_hasInitialized) {
      return _buildLoadingState();
    }

    // Show error state if error occurred and we haven't loaded successfully before
    if (_errorMessage != null && !_hasInitialized) {
      return _buildErrorState();
    }

    // Show main content (even if there's a background error, show last known good state)
    return Column(
      children: [
        _buildMainBalanceCard(),
        if (_tokenBalance < 10) ...[
          SizedBox(height: 12),
          _buildLowBalanceWarning(),
        ],
      ],
    );
  }

  Widget _buildMainBalanceCard() {
    final balanceColor = TokenService.getBalanceColor(_tokenBalance);
    final statusMessage = TokenService.getBalanceStatusMessage(_tokenBalance);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: _errorMessage != null ? Colors.orange : Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mes jetons',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_errorMessage != null && _hasInitialized) ...[
                    SizedBox(width: 4),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 14,
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: _isLoading ? null : _loadTokenBalance,
                child: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.refresh,
                  color: _isLoading ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Show connection warning if there's an error
          if (_errorMessage != null && _hasInitialized) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.orange[600], size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_tokenBalance',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'jetons',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      BalanceIndicator(balance: _tokenBalance),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusMessage,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Quick publication estimate
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(_tokenBalance / 10).floor()} publications',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/token_purchase_screen',
                    ).then((_) {
                      // Refresh balance when returning
                      if (mounted) {
                        _loadTokenBalance();
                      }
                    });
                  },
                  icon: Icon(Icons.add_circle_outline, size: 16),
                  label: Text(
                    'Acheter',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showTokenHistory();
                  },
                  icon: Icon(Icons.history, size: 16),
                  label: Text(
                    'Historique',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLowBalanceWarning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Solde faible ! Achetez des jetons pour continuer à publier.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.orange[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/token_purchase_screen',
              ).then((_) {
                if (mounted) {
                  _loadTokenBalance();
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange[700],
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Acheter',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.grey[400], size: 20),
          SizedBox(width: 8),
          Text(
            'Chargement du solde...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Spacer(),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red[800],
              ),
            ),
          ),
          TextButton(
            onPressed: _loadTokenBalance,
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showTokenHistory() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TokenHistoryModal(),
    );
  }
}
