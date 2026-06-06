import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';

class AnalysisView extends ConsumerStatefulWidget {
  const AnalysisView({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends ConsumerState<AnalysisView> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Análise Financeira', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 0.5)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: financeState.transactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    Text('Sem dados para análise.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            const Text('Balanço Geral', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 16),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: CircularProgressIndicator(
                                    value: financeState.totalIncome > 0 ? financeState.totalIncome / (financeState.totalIncome + financeState.totalExpense) : 0,
                                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                    color: Colors.greenAccent,
                                    strokeWidth: 16,
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text('Sobrando', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                                    Text(
                                      '${((financeState.balance / (financeState.totalIncome == 0 ? 1 : financeState.totalIncome)) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildIndicator('Receitas', currencyFormat.format(financeState.totalIncome), Colors.greenAccent),
                                Container(width: 1, height: 40, color: Colors.white24),
                                _buildIndicator('Despesas', currencyFormat.format(financeState.totalExpense), Colors.redAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Text('Todas as Transações', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = financeState.transactions[index];
                        final isIncome = tx.type == TransactionType.income;
                        return Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24.0),
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                          ),
                          onDismissed: (_) {
                            ref.read(financeProvider.notifier).deleteTransaction(tx.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transação apagada com sucesso'),
                                backgroundColor: const Color(0xFF6200EA),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(tx.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.date), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: isIncome ? Colors.greenAccent : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: financeState.transactions.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
