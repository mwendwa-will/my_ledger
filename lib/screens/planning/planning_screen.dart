import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/debt_plan.dart';
import '../../models/financial_goal.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';
import '../../utils/currency_helper.dart';
import '../../utils/formatters.dart';

typedef _PlanningData = ({
  List<Account> accounts,
  List<Category> categories,
  List<FinancialGoal> goals,
  List<DebtPlan> debts,
});

enum _PayoffOrder { snowball, avalanche }

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  late Future<_PlanningData> _data;
  _PayoffOrder _payoffOrder = _PayoffOrder.avalanche;
  final TextEditingController _extraPaymentController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  @override
  void dispose() {
    _extraPaymentController.dispose();
    super.dispose();
  }

  Future<_PlanningData> _loadData() async {
    final results = await Future.wait([
      DatabaseService.instance.getAllAccounts(),
      DatabaseService.instance.getAllCategories(),
      DatabaseService.instance.getFinancialGoals(),
      DatabaseService.instance.getDebtPlans(),
    ]);
    return (
      accounts: results[0] as List<Account>,
      categories: results[1] as List<Category>,
      goals: results[2] as List<FinancialGoal>,
      debts: results[3] as List<DebtPlan>,
    );
  }

  void _reload() => setState(() => _data = _loadData());

  Future<FinancialGoal?> _goalDialog(
    List<Account> accounts, {
    required List<Category> categories,
    FinancialGoal? goal,
  }) async {
    final name = TextEditingController(text: goal?.name ?? '');
    final target = TextEditingController(
      text: goal?.targetAmount.toString() ?? '',
    );
    final current = TextEditingController(
      text: goal?.currentAmount.toString() ?? '0',
    );
    int? accountId = goal?.accountId;
    int? categoryId = goal?.categoryId;
    DateTime? targetDate = goal?.targetDate;
    final result = await showDialog<FinancialGoal>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(goal == null ? 'New savings goal' : 'Edit savings goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                ),
                TextField(
                  controller: target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Target amount'),
                ),
                TextField(
                  controller: current,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Saved so far',
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: targetDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) {
                      setDialogState(() => targetDate = selected);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    targetDate == null
                        ? 'Add target date (optional)'
                        : 'Target: ${Formatters.formatDate(targetDate!)}',
                  ),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: 'Reference account (manual progress)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        child: Text('No linked account'),),
                    ...accounts.map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => accountId = value),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Reference category (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      child: Text('No linked category'),
                    ),
                    ...categories.where((category) => !category.isArchived).map(
                          (category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => categoryId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final targetAmount = double.tryParse(target.text);
                final currentAmount = double.tryParse(current.text);
                if (name.text.trim().isEmpty ||
                    targetAmount == null ||
                    targetAmount <= 0 ||
                    currentAmount == null ||
                    currentAmount < 0) {
                  return;
                }
                Navigator.pop(
                  context,
                  FinancialGoal(
                    id: goal?.id,
                    name: name.text.trim(),
                    targetAmount: targetAmount,
                    currentAmount: currentAmount,
                    targetDate: targetDate,
                    accountId: accountId,
                    categoryId: categoryId,
                  ),
                );
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    target.dispose();
    current.dispose();
    return result;
  }

  Future<DebtPlan?> _debtDialog(List<Account> accounts,
      {DebtPlan? debt,}) async {
    final name = TextEditingController(text: debt?.name ?? '');
    final balance = TextEditingController(
      text: debt?.balance.toString() ?? '',
    );
    final rate = TextEditingController(
      text: debt?.annualInterestRate.toString() ?? '0',
    );
    final minimum = TextEditingController(
      text: debt?.minimumPayment.toString() ?? '',
    );
    final dueDay = TextEditingController(text: debt?.dueDay?.toString() ?? '');
    int? accountId = debt?.accountId;
    final result = await showDialog<DebtPlan>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(debt == null ? 'Add debt' : 'Edit debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Debt name'),
                ),
                TextField(
                  controller: balance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Balance'),
                ),
                TextField(
                  controller: rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Annual interest rate (%)',
                  ),
                ),
                TextField(
                  controller: minimum,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monthly minimum payment',
                  ),
                ),
                TextField(
                  controller: dueDay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment due day (1-31, optional)',
                  ),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: 'Linked account (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        child: Text('No linked account'),),
                    ...accounts.map(
                      (account) => DropdownMenuItem<int?>(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => accountId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final debtBalance = double.tryParse(balance.text);
                final apr = double.tryParse(rate.text);
                final payment = double.tryParse(minimum.text);
                final dueDayValue = dueDay.text.trim().isEmpty
                    ? null
                    : int.tryParse(dueDay.text);
                if (name.text.trim().isEmpty ||
                    debtBalance == null ||
                    debtBalance < 0 ||
                    apr == null ||
                    apr < 0 ||
                    payment == null ||
                    payment <= 0 ||
                    (dueDay.text.trim().isNotEmpty &&
                        (dueDayValue == null ||
                            dueDayValue < 1 ||
                            dueDayValue > 31))) {
                  return;
                }
                Navigator.pop(
                  context,
                  DebtPlan(
                    id: debt?.id,
                    name: name.text.trim(),
                    balance: debtBalance,
                    annualInterestRate: apr,
                    minimumPayment: payment,
                    dueDay: dueDayValue,
                    accountId: accountId,
                  ),
                );
              },
              child: const Text('Save debt'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    balance.dispose();
    rate.dispose();
    minimum.dispose();
    dueDay.dispose();
    return result;
  }

  Map<int, int?> _payoffMonths(List<DebtPlan> debts, double extraPayment) {
    final balances = {for (final debt in debts) debt.id!: debt.balance};
    final payoffMonths = <int, int?>{
      for (final debt in debts) debt.id!: debt.balance <= 0 ? 0 : null,
    };
    var rolledOverPayments = 0.0;

    for (var month = 1; month <= 1200; month++) {
      var newRollover = 0.0;
      for (final debt in debts) {
        final balance = balances[debt.id!]!;
        if (balance <= 0) continue;
        final afterInterest =
            balance + balance * debt.annualInterestRate / 1200;
        balances[debt.id!] =
            (afterInterest - debt.minimumPayment).clamp(0, double.infinity);
        if (balances[debt.id!]! == 0) {
          payoffMonths[debt.id!] = month;
          newRollover += debt.minimumPayment;
        }
      }

      var extra = extraPayment + rolledOverPayments;
      for (final debt in debts) {
        if (extra <= 0) break;
        final balance = balances[debt.id!]!;
        if (balance <= 0) continue;
        final payment = balance < extra ? balance : extra;
        balances[debt.id!] = balance - payment;
        extra -= payment;
        if (balances[debt.id!]! <= 0.005) {
          balances[debt.id!] = 0;
          payoffMonths[debt.id!] = month;
          newRollover += debt.minimumPayment;
        }
      }

      rolledOverPayments = newRollover;
      if (payoffMonths.values.every((months) => months != null)) break;
    }
    return payoffMonths;
  }

  Future<void> _saveGoal(
    List<Account> accounts,
    List<Category> categories, [
    FinancialGoal? goal,
  ]) async {
    final result = await _goalDialog(
      accounts,
      categories: categories,
      goal: goal,
    );
    if (result == null) return;
    try {
      await DatabaseService.instance.saveFinancialGoal(result);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save goal: $error')),
        );
      }
    }
  }

  Future<void> _saveDebt(List<Account> accounts, [DebtPlan? debt]) async {
    final result = await _debtDialog(accounts, debt: debt);
    if (result == null) return;
    try {
      await DatabaseService.instance.saveDebtPlan(result);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save debt plan: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Goals & Debt Plan')),
        body: FutureBuilder<_PlanningData>(
          future: _data,
          builder: (context, snapshot) {
            final currency = CurrencyHelper.getSymbol(
              ref.watch(currencyCodeProvider),
            );
            if (snapshot.hasError) {
              return Center(
                  child: Text('Could not load plans: ${snapshot.error}'),);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final debts = [...data.debts]..sort((a, b) =>
                _payoffOrder == _PayoffOrder.snowball
                    ? a.balance.compareTo(b.balance)
                    : b.annualInterestRate.compareTo(a.annualInterestRate),);
            final enteredExtra =
                double.tryParse(_extraPaymentController.text.trim());
            final extraIsInvalid =
                _extraPaymentController.text.trim().isNotEmpty &&
                    (enteredExtra == null || enteredExtra < 0);
            final extra = extraIsInvalid ? 0.0 : enteredExtra ?? 0.0;
            final payoffMonths = _payoffMonths(debts, extra);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Savings goals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add savings goal',
                      onPressed: () =>
                          _saveGoal(data.accounts, data.categories),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (data.goals.isEmpty)
                  const Text('Create a goal and track progress manually.')
                else
                  ...data.goals.map(
                    (goal) => Card(
                      child: ListTile(
                        title: Text(goal.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Formatters.formatCurrency(goal.currentAmount, symbol: currency)} of ${Formatters.formatCurrency(goal.targetAmount, symbol: currency)}',
                            ),
                            if (goal.targetDate != null)
                              Text(
                                'Target date: ${Formatters.formatDate(goal.targetDate!)}',
                              ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: goal.progress),
                            if (goal.accountId != null)
                              Text(
                                'Linked: ${data.accounts.where((a) => a.id == goal.accountId).firstOrNull?.name ?? 'Account unavailable'}',
                              ),
                            if (goal.categoryId != null)
                              Text(
                                'Reference category: ${data.categories.where((c) => c.id == goal.categoryId).firstOrNull?.name ?? 'Category unavailable'}',
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () =>
                            _saveGoal(data.accounts, data.categories, goal),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await DatabaseService.instance
                                .deleteFinancialGoal(goal.id!);
                            if (mounted) _reload();
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Debt payoff planner',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add debt',
                      onPressed: () => _saveDebt(data.accounts),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                DropdownButtonFormField<_PayoffOrder>(
                  initialValue: _payoffOrder,
                  decoration: const InputDecoration(labelText: 'Payoff order'),
                  items: const [
                    DropdownMenuItem(
                      value: _PayoffOrder.avalanche,
                      child: Text('Avalanche · highest interest first'),
                    ),
                    DropdownMenuItem(
                      value: _PayoffOrder.snowball,
                      child: Text('Snowball · smallest balance first'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _payoffOrder = value);
                  },
                ),
                TextField(
                  controller: _extraPaymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Extra monthly payment to prioritize',
                  ).copyWith(
                    errorText:
                        extraIsInvalid ? 'Enter a non-negative amount' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (debts.isEmpty)
                  const Text('Add a debt to estimate payoff using your inputs.')
                else
                  ...debts.map((debt) {
                    final months = payoffMonths[debt.id];
                    return Card(
                      child: ListTile(
                        title: Text(debt.name),
                        subtitle: Text(
                          '${Formatters.formatCurrency(debt.balance, symbol: currency)} · ${debt.annualInterestRate}% APR · ${months == null ? 'Minimum payment does not cover interest' : '$months months at entered payment'}${debt.dueDay == null ? '' : ' · Due on day ${debt.dueDay}'}',
                        ),
                        onTap: () => _saveDebt(data.accounts, debt),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await DatabaseService.instance.deleteDebtPlan(
                              debt.id!,
                            );
                            if (mounted) _reload();
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Text(
                  'Estimates assume a fixed interest rate and on-time monthly payments. Update balances manually; this planner does not change account balances.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      );
}
