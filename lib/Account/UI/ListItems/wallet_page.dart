import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Account/UI/account_page.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/services/shared_services.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AccountPageBody(),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          AppLocalizations.of(context)!.wallet!,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: const Wallet(),
      ),
    );
  }
}

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  List listTransactions = [];
  int? saldo;
  UserModel? driver;
  bool isLoading = false;

  @override
  void initState() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      saldo = authState.user.balance;
      driver = authState.user;
    }
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initData());
  }

  Future<void> initData() async {
    setState(() {
      isLoading = true;
    });

    UserModel user = await AuthService().getCurrentUser();
    await getTransaction();

    if (mounted) {
      setState(() {
        isLoading = false;
        driver = user;
      });
    }
  }

  Future<void> getTransaction() async {
    if (driver == null) return;
    List getListTransactions =
        await SharedServices().getTransactions(driver!.id.toString());

    if (mounted) {
      setState(() {
        listTransactions = getListTransactions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || driver == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CARD SALDO DAN ACTION BUTTONS ---
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kMainColor, kMainColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: kMainColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.availableBalance!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                formatCurrency(driver!.balance),
                style: const TextStyle(
                  fontSize: 30.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Tambah',
                    onTap: () =>
                        Navigator.pushNamed(context, PageRoutes.addMoney),
                  ),
                  _buildActionButton(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Tarik',
                    onTap: () {
                      //  Navigator.pushNamed(context, PageRoutes.tarikSaldo)
                    },
                  ),
                  _buildActionButton(
                      icon: Icons.send_outlined,
                      label: 'Kirim',
                      onTap: () {
                        // Navigator.pushNamed(context, PageRoutes.sendSaldo),
                      }),
                ],
              ),
            ],
          ),
        ),

        // --- SUBTITLE RIWAYAT TRANSAKSI ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)!.recent!,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                ),
          ),
        ),

        // --- LIST RIWAYAT TRANSAKSI ---
        Expanded(
          child: listTransactions.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada transaksi',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: listTransactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8.0),
                  itemBuilder: (context, index) {
                    final item = listTransactions[index];
                    final bool isKeluar = item['mode'] == 'keluar';

                    return Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // Icon Indikator Mode
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isKeluar
                                ? kRedColor.withOpacity(0.1)
                                : kGreenColor.withOpacity(0.1),
                            child: Icon(
                              isKeluar
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: isKeluar ? kRedColor : kGreenColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14.0),

                          // Tipe Transaksi & Tanggal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['type'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  item['created_at'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nominal & Status Mode
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(item['price']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item['mode'] ?? '',
                                style: TextStyle(
                                  color: isKeluar ? kRedColor : kGreenColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Helper Widget Tombol Aksi Saldo
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
