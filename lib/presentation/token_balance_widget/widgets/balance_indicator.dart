import 'package:flutter/material.dart';
import '../../../services/token_service.dart';

class BalanceIndicator extends StatelessWidget {
  final int balance;

  const BalanceIndicator({
    Key? key,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balanceColor = TokenService.getBalanceColor(balance);

    Color indicatorColor;
    switch (balanceColor) {
      case TokenBalanceColor.green:
        indicatorColor = Colors.green;
        break;
      case TokenBalanceColor.orange:
        indicatorColor = Colors.orange;
        break;
      case TokenBalanceColor.red:
        indicatorColor = Colors.red;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
