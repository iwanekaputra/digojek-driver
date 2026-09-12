import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Components/entry_field.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  static const String id = 'support_page';
  final String? number;

  const SupportPage({super.key, this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.support!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Stack(
          children: [
            ListView(
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                // --- HERO HEADER / LOGO CONTAINER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FadedScaleAnimation(
                      scaleDuration: const Duration(milliseconds: 400),
                      fadeDuration: const Duration(milliseconds: 400),
                      child: const Image(
                        image: AssetImage("images/logos/logo.png"),
                        height: 110.0,
                        width: 110.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // --- CONTENT SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24.0, horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.orWrite!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        AppLocalizations.of(context)!.yourWords!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // --- CONTACT CARDS ---
                      _buildContactTile(
                        context,
                        iconAsset: 'images/icons/whatsapp.png',
                        title: 'WhatsApp Support',
                        subtitle: number ?? '+62 812-3456-7890',
                      ),
                      const SizedBox(height: 12.0),
                      _buildContactTile(
                        context,
                        iconAsset: 'images/icons/ic_mail.png',
                        title: 'Email Support',
                        subtitle: 'digojek@gmail.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
              ],
            ),
            // PositionedDirectional(
            //   bottom: 0,
            //   start: 0,
            //   end: 0,
            //   child: BottomBar(
            //     text: AppLocalizations.of(context)!.submit,
            //     onTap: () {
            //       /*............*/
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET UNTUK KARTU KONTAK ---
  Widget _buildContactTile(
    BuildContext context, {
    required String iconAsset,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconAsset,
              height: 36,
              width: 36,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.contact_support, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  subtitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
