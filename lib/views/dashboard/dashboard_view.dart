import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/news_provider.dart';
import '../../models/transaction.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final newsAsyncValue = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.pushNamed(context, '/analysis');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // refresh data
            ref.invalidate(newsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Balance Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6200EA), Color(0xFFB388FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6200EA).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Atual',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        financeState.isLoading
                          ? _buildSkeleton(150, 40)
                          : Text(
                              currencyFormat.format(financeState.balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIncomeExpense(
                              'Receitas',
                              financeState.isLoading ? null : currencyFormat.format(financeState.totalIncome),
                              Icons.arrow_upward,
                              Colors.greenAccent,
                            ),
                            _buildIncomeExpense(
                              'Despesas',
                              financeState.isLoading ? null : currencyFormat.format(financeState.totalExpense),
                              Icons.arrow_downward,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Transações Recentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Transações
                if (financeState.isLoading)
                  ...List.generate(3, (index) => _buildTransactionSkeleton())
                else if (financeState.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Nenhuma transação encontrada.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: min(financeState.transactions.length, 5),
                    itemBuilder: (context, index) {
                      final transaction = financeState.transactions[index];
                      final isIncome = transaction.type == TransactionType.income;
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome 
                              ? Colors.greenAccent.withValues(alpha: 0.2) 
                              : Colors.redAccent.withValues(alpha: 0.2),
                            child: Icon(
                              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isIncome ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          title: Text(
                            transaction.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            transaction.category,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                            style: TextStyle(
                              color: isIncome ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Feed de Notícias
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Dicas Financeiras (Nuvem)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                newsAsyncValue.when(
                  data: (newsList) => SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        final news = newsList[index];
                        return Container(
                          width: 250,
                          margin: const EdgeInsets.only(right: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                news.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 250,
                        margin: const EdgeInsets.only(right: 16.0),
                        child: _buildSkeleton(250, 160),
                      ),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Erro ao carregar dicas da rede.', style: TextStyle(color: Colors.redAccent.shade100))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6200EA),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddTransactionSheet(context, ref);
        },
      ),
    );
  }

  Widget _buildIncomeExpense(String title, String? amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            amount == null 
              ? _buildSkeleton(80, 20)
              : Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  Widget _buildTransactionSkeleton() {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: _buildSkeleton(40, 40),
        title: _buildSkeleton(120, 16),
        subtitle: _buildSkeleton(80, 12),
        trailing: _buildSkeleton(60, 16),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Alimentação';
    TransactionType type = TransactionType.expense;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nova Transação', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Título'),
                      validator: (v) => v == null || v.isEmpty ? 'Informe o título' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Valor'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o valor';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ignore: deprecated_member_use
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Categoria'),
                      items: ['Alimentação', 'Saúde', 'Contas', 'Salário', 'Lazer', 'Outros']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => category = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          // ignore: deprecated_member_use
                          child: RadioListTile<TransactionType>(
                            title: const Text('Despesa', style: TextStyle(color: Colors.white)),
                            value: TransactionType.expense,
                            // ignore: deprecated_member_use
                            groupValue: type,
                            activeColor: Colors.redAccent,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => type = v!),
                          ),
                        ),
                        Expanded(
                          // ignore: deprecated_member_use
                          child: RadioListTile<TransactionType>(
                            title: const Text('Receita', style: TextStyle(color: Colors.white)),
                            value: TransactionType.income,
                            // ignore: deprecated_member_use
                            groupValue: type,
                            activeColor: Colors.greenAccent,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => type = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6200EA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final tx = TransactionItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleController.text.trim(),
                              amount: double.parse(amountController.text.replaceAll(',', '.')),
                              date: DateTime.now(),
                              type: type,
                              category: category,
                            );
                            ref.read(financeProvider.notifier).addTransaction(tx);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Adicionar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
