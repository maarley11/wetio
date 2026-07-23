import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../services/token_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingPayments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = SupabaseService.instance.client;
      final response = await client
          .from('payment_transactions')
          .select('*, user_profiles(pseudo, phone)')
          .or('payment_status.eq.awaiting_verification,payment_status.eq.pending')
          .eq('payment_method', 'wave')
          .order('created_at', ascending: false);

      setState(() {
        _pendingPayments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _validatePayment(Map<String, dynamic> payment) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la validation'),
        content: Text(
            'Voulez-vous vraiment créditer ${payment['tokens_purchased']} jetons à ${payment['user_profiles']['pseudo']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Valider', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.instance.client;
      
      // 1. Add tokens using RPC
      final rpcResponse = await client.rpc('add_tokens_after_payment', params: {
        'user_uuid': payment['user_id'],
        'tokens_to_add': payment['tokens_purchased'],
        'payment_reference': payment['payment_intent_id'],
      });

      if (rpcResponse['success'] == true) {
        // 2. Update payment status
        await client
            .from('payment_transactions')
            .update({
              'payment_status': 'completed',
              'verified_at': DateTime.now().toIso8601String(),
              'admin_notes': 'Validé manuellement par l\'admin'
            })
            .eq('id', payment['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement validé avec succès !'), backgroundColor: Colors.green),
        );
        _loadPendingPayments();
      } else {
        throw Exception(rpcResponse['message'] ?? 'Erreur inconnue lors de l\'ajout des jetons');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la validation: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Administrateur', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadPendingPayments),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.red[50],
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  ),
                Expanded(
                  child: _pendingPayments.isEmpty
                      ? Center(child: Text('Aucun paiement en attente'))
                      : ListView.builder(
                          itemCount: _pendingPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _pendingPayments[index];
                            final user = payment['user_profiles'];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text('${user['pseudo'] ?? 'Anonyme'} - ${payment['amount_fcfa']} FCFA'),
                                subtitle: Text(
                                    '${payment['tokens_purchased']} jetons • ${user['phone']}\n${DateTime.parse(payment['created_at']).toLocal()}'),
                                trailing: ElevatedButton(
                                  onPressed: () => _validatePayment(payment),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: Text('Valider'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
