import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/finance_view_model.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final financeViewModel = Provider.of<FinanceViewModel>(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    // Calcula o progresso do orçamento (exemplo fixo: Orçamento de R$ 2000.0)
    const budget = 2000.0;
    final expenses = financeViewModel.totalExpense;
    final progress = (expenses / budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Análise e Resultados', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumo de Orçamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gasto Atual', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(currencyFormat.format(expenses), style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Orçamento Limite', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(currencyFormat.format(budget), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: progress > 0.8 ? Colors.redAccent : const Color(0xFF6200EA),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}% utilizado',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Todas as Movimentações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: financeViewModel.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = financeViewModel.transactions[index];
                    final isIncome = transaction.type == TransactionType.income;
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        child: Icon(
                          _getIconForCategory(transaction.category),
                          color: isIncome ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                      title: Text(
                        transaction.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(transaction.date),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                        style: TextStyle(
                          color: isIncome ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Alimentação':
        return Icons.restaurant;
      case 'Contas':
        return Icons.receipt;
      case 'Salário':
        return Icons.attach_money;
      case 'Saúde':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}
