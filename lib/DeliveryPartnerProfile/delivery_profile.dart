import 'dart:convert';
import 'dart:io';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Components/bottom_bar.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String? phoneNumber;

  const ProfilePage({super.key, this.phoneNumber});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context)!.editProfile!,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: RegisterForm(widget.phoneNumber),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final String? phoneNumber;

  const RegisterForm(this.phoneNumber, {super.key});

  @override
  RegisterFormState createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final nameController = TextEditingController(text: '');
  final nohpController = TextEditingController(text: '');
  final emailController = TextEditingController(text: '');

  XFile? selectedProfile;
  UserModel? driver;
  String? image = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      nameController.text = authState.user.name ?? '';
      emailController.text = authState.user.email ?? '';
      nohpController.text = authState.user.nohp ?? '';
      image = authState.user.image ?? '';
      driver = authState.user;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    nohpController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailed) {
                showCustomSnackbar(context, state.e.toString());
              }
              if (state is AuthSuccess) {
                showCustomSnackbarSuccess(context, 'Berhasil Update Driver');
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16.0),

                    // 1. Avatar Profile + Edit Button Icon Overlay
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final pickedImage = await selectImage();
                              if (pickedImage != null) {
                                setState(() {
                                  selectedProfile = pickedImage;
                                });
                              }
                            },
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: kMainColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(55),
                                child: selectedProfile != null
                                    ? Image.file(
                                        File(selectedProfile!.path),
                                        fit: BoxFit.cover,
                                      )
                                    : (image != null && image!.isNotEmpty)
                                        ? Image.network(
                                            image!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 50,
                                                        color: Colors.grey),
                                          )
                                        : const Icon(Icons.person,
                                            size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final pickedImage = await selectImage();
                                if (pickedImage != null) {
                                  setState(() {
                                    selectedProfile = pickedImage;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: kMainColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28.0),

                    // 2. Card Pembungkus Input Informasi Profil
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .profileInfo!
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kHintColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Name Input
                          _buildModernTextField(
                            context,
                            controller: nameController,
                            label: AppLocalizations.of(context)!.fullName!,
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16.0),

                          // Phone Number Input (Read-only)
                          _buildModernTextField(
                            context,
                            controller: nohpController,
                            label: AppLocalizations.of(context)!.mobileNumber!,
                            icon: Icons.phone_android_rounded,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16.0),

                          // Email Input
                          _buildModernTextField(
                            context,
                            controller: emailController,
                            label: AppLocalizations.of(context)!.emailAddress!,
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24.0),
                  ],
                ),
              );
            },
          ),
        ),

        // 3. Bottom Bar Tombol Update
        BottomBar(
          text: 'Update',
          onTap: () {
            if (driver == null) return;

            if (selectedProfile == null) {
              context.read<AuthBloc>().add(
                    AuthUserUpdate(
                      driver!.id.toString(),
                      nameController.text,
                      "",
                      emailController.text,
                    ),
                  );
            } else {
              context.read<AuthBloc>().add(
                    AuthUserUpdate(
                      driver!.id.toString(),
                      nameController.text,
                      base64Encode(
                        File(selectedProfile!.path).readAsBytesSync(),
                      ),
                      emailController.text,
                    ),
                  );
            }
          },
        ),
      ],
    );
  }

  // Widget Pembantu untuk Text Field Modern & Clean
  Widget _buildModernTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: kMainColor, size: 20),
        filled: true,
        fillColor: readOnly
            ? Colors.grey.withOpacity(0.08)
            : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kMainColor, width: 1.5),
        ),
      ),
    );
  }
}
