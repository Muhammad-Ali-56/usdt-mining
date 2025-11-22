import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:usdtmining/services/mining_service.dart';

import '../widgets/app_loading_indicator.dart';
import '../widgets/mining_background.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedWallet = 'TRC20';
  bool _isLoading = false;

  final List<String> _walletTypes = ['TRC20', 'ERC20', 'BEP20'];

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _fetchAllAmount() {
    final miningService = Provider.of<MiningService>(context, listen: false);
    _amountController.text = miningService.currentBalance.toStringAsFixed(5);
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final address = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un importo valido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final miningService = Provider.of<MiningService>(context, listen: false);
    final balance = miningService.currentBalance;

    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importo superiore al balance disponibile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importo minimo: 100 USDT'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simula richiesta di prelievo
    await Future.delayed(const Duration(seconds: 2));

    await miningService.creditBalance(-amount, forceSync: true);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Prelievo di ${amount.toStringAsFixed(5)} USDT richiesto'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw USDT'),
      ),
      body: Stack(
        children: [
          MiningBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Consumer<MiningService>(
                        builder: (context, miningService, child) {
                          final balance = miningService.currentBalance;
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF00D9FF).withOpacity(0.2),
                                  const Color(0xFF00D9FF).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Available Balance',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  NumberFormat.currency(
                                          symbol: '', decimalDigits: 5)
                                      .format(balance),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: const Color(0xFF00D9FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const Text(
                                  'USDT',
                                  style: TextStyle(
                                    color: Color(0xFFB0B8C4),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(delay: 200.ms);
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Wallet Network',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2749),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedWallet,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: const Color(0xFF1E2749),
                          style: const TextStyle(color: Colors.white),
                          items: _walletTypes.map((wallet) {
                            return DropdownMenuItem(
                              value: wallet,
                              child: Text(wallet),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedWallet = value!;
                            });
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      Text(
                        'Wallet Address',
                        style: Theme.of(context).textTheme.titleLarge,
                      ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter your wallet address',
                          filled: true,
                          fillColor: const Color(0xFF1E2749),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid address';
                          }
                          if (value.length < 26) {
                            return 'Invalid address';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: _fetchAllAmount,
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            label: const Text('All'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00D9FF),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          suffixText: 'USDT',
                          filled: true,
                          fillColor: const Color(0xFF1E2749),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Invalid amount';
                          }
                          if (amount < 100) {
                            return 'Minimum amount: 100 USDT';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 1400.ms, duration: 600.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D9FF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _withdraw,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: const Color(0xFF00D9FF),
                          ),
                          child: const Text(
                            'Withdraw',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1600.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const AppLoadingIndicator(
                  text: 'Processing withdrawal...',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
