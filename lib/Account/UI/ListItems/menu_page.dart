import 'package:deliq_delivery/Auth/MobileNumber/UI/phone_number.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/OrderMap/UI/order_page.dart';
import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Menu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header User Profil
            const UserProfileHeader(),
            const SizedBox(height: 12),

            // Section Group: Layanan Utama
            _buildSectionTitle(context, 'Layanan & Aktivitas'),

            _buildMenuItem(
              context,
              icon: Icons.insights_rounded,
              title: "Wawasan",
              onTap: () => Navigator.pushNamed(context, PageRoutes.insightPage),
            ),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Deposit',
              onTap: () => Navigator.pushNamed(context, PageRoutes.deposit),
            ),
            _buildMenuItem(
              context,
              icon: Icons.wallet_outlined,
              title: "Dompet",
              onTap: () => Navigator.pushNamed(context, PageRoutes.walletPage),
            ),
            // _buildMenuItem(
            //   context,
            //   icon: Icons.receipt_long_outlined,
            //   title: 'Transaksi Pembelian',
            //   onTap: () =>
            //       Navigator.pushNamed(context, PageRoutes.transactionPurchase),
            // ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(),
            ),

            // Section Group: Informasi & Bantuan
            _buildSectionTitle(context, 'Bantuan & Ketentuan'),
            _buildMenuItem(
              context,
              icon: Icons.description_outlined,
              title: "Ketentuan & Syarat",
              onTap: () => Navigator.pushNamed(context, PageRoutes.tncPage),
            ),
            _buildMenuItem(
              context,
              icon: Icons.support_agent_rounded,
              title: "Bantuan",
              onTap: () => Navigator.pushNamed(context, PageRoutes.supportPage),
            ),

            const SizedBox(height: 16),

            // Tombol Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.red.withOpacity(0.08),
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text(
                  "Logout",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(icon, color: kMainColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PhoneNumber()),
                (route) => false,
              );
            }
            if (state is AuthFailed) {
              showCustomSnackbar(context, 'Gagal Logout');
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.loggingOut!),
              content: Text(AppLocalizations.of(context)!.areYouSure!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.no!),
                ),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogout());
                  },
                  child: Text(
                    AppLocalizations.of(context)!.yes!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Visual Profil User Atas
class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String name = '';
    String email = '';
    String nohp = '';
    String imageUrl = '';

    if (authState is AuthSuccess) {
      final driver = authState.user;
      name = driver.name ?? '';
      email = driver.email ?? '';
      nohp = driver.nohp ?? '';
      imageUrl = driver.image ?? '';
    }

    return InkWell(
      onTap: () => Navigator.pushNamed(context, PageRoutes.editProfile),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: kMainColor.withOpacity(0.1),
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Icon(Icons.person, color: kMainColor, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Nama User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nohp,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: kMainColor, size: 20),
          ],
        ),
      ),
    );
  }
}
