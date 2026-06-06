import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/news_provider.dart';
import '../../models/transaction.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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
    final marketAsyncValue = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 80,
            floating: true,
            title: FadeTransition(
              opacity: _fadeController,
              child: const Text(
                'Dashboard', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
                onPressed: () => Navigator.pushNamed(context, '/analysis'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 26),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pushReplacementNamed(context, '/auth');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _buildBalanceCard(financeState, currencyFormat),
                    
                    const SizedBox(height: 32),
                    
                    // Market Indicators
                    const Text(
                      'Indicadores de Mercado',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),
                    _buildMarketIndicators(marketAsyncValue),
                    
                    const SizedBox(height: 32),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transações Recentes',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/analysis'),
                          child: const Text('Ver todas', style: TextStyle(color: Color(0xFFB388FF))),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          
          // Transactions List
          if (financeState.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTransactionSkeleton(),
                childCount: 3,
              ),
            )
          else if (financeState.transactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('Nenhuma transação encontrada.', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final transaction = financeState.transactions[index];
                  final isIncome = transaction.type == TransactionType.income;
                  return _buildTransactionItem(transaction, isIncome, currencyFormat, index);
                },
                childCount: min(financeState.transactions.length, 5),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6200EA),
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddTransactionSheet(context, ref),
      ),
    );
  }

  Widget _buildBalanceCard(FinanceState state, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EA), Color(0xFF9D46FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EA).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Atual',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          state.isLoading
            ? _buildSkeleton(150, 40)
            : Text(
                format.format(state.balance),
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpense('Receitas', state.isLoading ? null : format.format(state.totalIncome), Icons.arrow_upward_rounded, Colors.greenAccent),
              _buildIncomeExpense('Despesas', state.isLoading ? null : format.format(state.totalExpense), Icons.arrow_downward_rounded, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpense(String title, String? amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            const SizedBox(height: 2),
            amount == null 
              ? _buildSkeleton(80, 16)
              : Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketIndicators(AsyncValue<List<MarketIndicator>> marketAsyncValue) {
    return marketAsyncValue.when(
      data: (indicators) => SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: indicators.length,
          itemBuilder: (context, index) {
            final ind = indicators[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(ind.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        Icon(ind.isPositive ? Icons.trending_up : Icons.trending_down, 
                             color: ind.isPositive ? Colors.greenAccent : Colors.redAccent, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('R\$ ${ind.value}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${ind.variation} hoje', style: TextStyle(color: ind.isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: _buildSkeleton(160, 120, radius: 20),
          ),
        ),
      ),
      error: (e, s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16)),
        child: const Text('Falha ao conectar com o mercado.', style: TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionItem tx, bool isIncome, NumberFormat format, int index) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncome ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              size: 24,
            ),
          ),
          title: Text(tx.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(tx.category, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${format.format(tx.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(DateFormat('dd MMM', 'pt_BR').format(tx.date), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
        ),
      );
  }

  Widget _buildSkeleton(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
  
  Widget _buildTransactionSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _buildSkeleton(48, 48, radius: 24),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSkeleton(100, 16),
            const SizedBox(height: 8),
            _buildSkeleton(60, 12),
          ]),
          const Spacer(),
          _buildSkeleton(80, 20),
        ],
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
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 32,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    const Text('Nova Transação', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => type = TransactionType.expense),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == TransactionType.expense ? Colors.redAccent.withValues(alpha: 0.1) : Colors.transparent,
                                border: Border.all(color: type == TransactionType.expense ? Colors.redAccent : Colors.white12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Despesa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => type = TransactionType.income),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == TransactionType.income ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.transparent,
                                border: Border.all(color: type == TransactionType.income ? Colors.greenAccent : Colors.white12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Receita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Título (ex: Mercado)'),
                      validator: (v) => v == null || v.isEmpty ? 'Informe o título' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Valor (R\$)'),
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
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Categoria'),
                      items: ['Alimentação', 'Saúde', 'Contas', 'Salário', 'Lazer', 'Outros']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => category = v!),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6200EA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        child: const Text('Confirmar Transação', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 32),
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
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6200EA), width: 2),
      ),
    );
  }
}
