import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileViewModel viewModel;
  final VoidCallback? onNavigateToHome;

  const ProfileScreen({
    super.key,
    required this.viewModel,
    this.onNavigateToHome,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _houseNoController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinCodeController;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController    = TextEditingController();
    _emailController   = TextEditingController();
    _houseNoController = TextEditingController();
    _addressController = TextEditingController();
    _pinCodeController = TextEditingController();

    // Load profile then populate controllers
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.viewModel.loadProfile();
      _populateControllers();
    });
  }

  void _populateControllers() {
    final vm = widget.viewModel;
    _nameController.text    = vm.name;
    _emailController.text   = vm.email;
    _houseNoController.text = vm.houseNo;
    _addressController.text = vm.address;
    _pinCodeController.text = vm.pinCode;
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _houseNoController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    widget.viewModel.updateName(_nameController.text);
    widget.viewModel.updateEmail(_emailController.text);
    widget.viewModel.updateHouseNo(_houseNoController.text);
    widget.viewModel.updateAddress(_addressController.text);
    widget.viewModel.updatePinCode(_pinCodeController.text);
    await widget.viewModel.updateProfile();

    if (!mounted) return;
    if (widget.viewModel.updateSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.viewModel.resetUpdateState();
    } else if (widget.viewModel.updateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.updateError!),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (widget.onNavigateToHome != null) {
              widget.onNavigateToHome!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;

          // Loading state
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Error state
          if (vm.loadError != null && vm.profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
                    const SizedBox(height: 16),
                    Text(vm.loadError!, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textGrey)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await vm.loadProfile();
                        _populateControllers();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Populate controllers once after load (guards against rebuild overwrite)
          if (!_controllersInitialized && vm.profile != null) {
            _populateControllers();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.tv, color: AppColors.primary, size: 40),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: AppColors.textDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Mobile No (read-only)
                      _ProfileField(
                        label: 'Mobile No.',
                        controller: TextEditingController(text: vm.phone),
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _ProfileField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      _ProfileField(
                        label: 'Full Name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 24),

                      // Primary Address section
                      const Text(
                        'Primary Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // State dropdown
                      const _FieldLabel(text: 'State'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        value: vm.state,
                        items: vm.states,
                        onChanged: vm.updateState,
                      ),
                      const SizedBox(height: 16),

                      // City dropdown
                      const _FieldLabel(text: 'City'),
                      const SizedBox(height: 8),
                      _DropdownField(
                        value: vm.city,
                        items: vm.cities,
                        onChanged: vm.updateCity,
                      ),
                      const SizedBox(height: 16),

                      // House No
                      _ProfileField(
                        label: 'House/Flat No.',
                        controller: _houseNoController,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _ProfileField(
                        label: 'Address',
                        controller: _addressController,
                      ),
                      const SizedBox(height: 16),

                      // PIN Code
                      _ProfileField(
                        label: 'PIN Code',
                        controller: _pinCodeController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Update button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isUpdating ? null : _update,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: vm.isUpdating
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared field widgets ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textGrey,
    ),
  );
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // If the current value isn't in the list, fall back to first item
    final effectiveValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}