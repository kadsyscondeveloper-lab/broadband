// lib/views/profile/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/location_service.dart';
import '../profile/delete_account_sheet.dart';
import '../../services/auth_service.dart';
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
  bool _locationLoading = false;   // ← NEW

  @override
  void initState() {
    super.initState();
    _nameController    = TextEditingController();
    _emailController   = TextEditingController();
    _houseNoController = TextEditingController();
    _addressController = TextEditingController();
    _pinCodeController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.viewModel.loadProfile();
      _populateControllers();
    });

    widget.viewModel.addListener(_onViewModelChange);
  }

  void _onViewModelChange() {
    if (widget.viewModel.imageError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.imageError!),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.viewModel.clearImageError();
    }
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
    widget.viewModel.removeListener(_onViewModelChange);
    _nameController.dispose();
    _emailController.dispose();
    _houseNoController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  // ── Auto-fill from GPS ────────────────────────────────────────────────────

  Future<void> _autoFillLocation() async {
    setState(() => _locationLoading = true);

    try {
      final result = await LocationService.fetchCurrentLocation();

      // Update text controllers
      if (result.address.isNotEmpty) _addressController.text = result.address;
      if (result.pinCode.isNotEmpty) _pinCodeController.text = result.pinCode;

      // Push into view-model (handles state/city dropdowns)
      if (result.state.isNotEmpty) widget.viewModel.updateState(result.state);
      if (result.city.isNotEmpty)  widget.viewModel.updateCity(result.city);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Location auto-filled successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ── Image source picker ───────────────────────────────────────────────────

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  widget.viewModel.pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  widget.viewModel.pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar(ProfileViewModel vm) {
    Widget image;

    if (vm.imageUploading) {
      image = Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    } else if (vm.localImageBase64 != null) {
      image = Image.memory(
        base64Decode(vm.localImageBase64!),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      final imgUrl = vm.profileImageUrl;
      if (imgUrl != null && imgUrl.isNotEmpty) {
        if (imgUrl.startsWith('data:')) {
          final base64Part =
              imgUrl.contains(',') ? imgUrl.split(',').last : imgUrl;
          image = Image.memory(
            base64Decode(base64Part),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } else {
          image = Image.network(
            imgUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2)),
            errorBuilder: (_, __, ___) => _defaultAvatarContent(vm),
          );
        }
      } else {
        image = _defaultAvatarContent(vm);
      }
    }

    return Stack(
      children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: image,
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: vm.imageUploading ? null : _showImageSourcePicker,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: vm.imageUploading
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt,
                  size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatarContent(ProfileViewModel vm) {
    final initials = vm.name.trim().isNotEmpty
        ? vm.name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '';

    if (initials.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return const Icon(Icons.person, color: AppColors.primary, size: 42);
  }

  // ── Save ──────────────────────────────────────────────────────────────────

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
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.viewModel.resetUpdateState();
    } else if (widget.viewModel.updateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.updateError!),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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

          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (vm.loadError != null && vm.profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.primary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      vm.loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await vm.loadProfile();
                        _populateControllers();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_controllersInitialized && vm.profile != null) {
            _populateControllers();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Avatar ─────────────────────────────────────────────
                Center(child: _buildAvatar(vm)),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    vm.imageUploading
                        ? 'Uploading photo…'
                        : 'Tap the camera icon to change photo',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Mobile No (read-only) ───────────────────────────────
                _ProfileField(
                  label: 'Mobile No.',
                  controller: TextEditingController(text: vm.phone),
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // ── Email ───────────────────────────────────────────────
                _ProfileField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // ── Full Name ───────────────────────────────────────────
                _ProfileField(
                  label: 'Full Name',
                  controller: _nameController,
                ),
                const SizedBox(height: 24),

                // ── Primary Address header + GPS button ─────────────────
                Row(
                  children: [
                    const Text(
                      'Primary Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    // ── USE MY LOCATION BUTTON ──────────────────────────
                    _locationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: _autoFillLocation,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.4),
                                ),
                              ),
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.06),
                            ),
                            icon: const Icon(Icons.my_location_rounded,
                                size: 15),
                            label: const Text(
                              'Use My Location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── State dropdown ──────────────────────────────────────
                const _FieldLabel(text: 'State'),
                const SizedBox(height: 8),
                _DropdownField(
                  value: vm.state,
                  items: vm.states,
                  onChanged: vm.updateState,
                  isLoading: vm.statesLoading,
                  hint: 'Select State',
                ),
                const SizedBox(height: 16),

                // ── City dropdown ───────────────────────────────────────
                const _FieldLabel(text: 'City'),
                const SizedBox(height: 8),
                _DropdownField(
                  value: vm.city,
                  items: vm.cities,
                  onChanged: vm.updateCity,
                  isLoading: vm.citiesLoading,
                  hint: 'Select City',
                ),
                const SizedBox(height: 16),

                // ── House No ────────────────────────────────────────────
                _ProfileField(
                  label: 'House/Flat No.',
                  controller: _houseNoController,
                ),
                const SizedBox(height: 16),

                // ── Address ─────────────────────────────────────────────
                _ProfileField(
                  label: 'Address',
                  controller: _addressController,
                ),
                const SizedBox(height: 16),

                // ── PIN Code ────────────────────────────────────────────
                _ProfileField(
                  label: 'PIN Code',
                  controller: _pinCodeController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),

                // ── Update Profile Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: vm.isUpdating ? null : _update,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.6),
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
                            'Update Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                const _DangerZoneDivider(),
                const SizedBox(height: 16),

                _DeleteAccountButton(
                  onDeleted: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
              ],
            ),
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
            color: readOnly ? AppColors.background : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              color: readOnly ? AppColors.textGrey : AppColors.textDark,
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
  final bool isLoading;
  final String hint;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
    this.hint = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: isLoading
            ? const SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text('Loading…',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textGrey)),
                  ],
                ),
              )
            : DropdownButton<String>(
                value: effectiveValue,
                isExpanded: true,
                hint: Text(hint,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textGrey)),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textGrey),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              )),
                        ))
                    .toList(),
                onChanged: items.isEmpty
                    ? null
                    : (v) => v != null ? onChanged(v) : null,
              ),
      ),
    );
  }
}


// ── Danger zone divider ─────────────────────────────────────────────

class _DangerZoneDivider extends StatelessWidget {
  const _DangerZoneDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.red.shade100)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade300,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.red.shade100)),
      ],
    );
  }
}

// ── Delete account button ───────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onDeleted;

  const _DeleteAccountButton({
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          DeleteAccountSheet.show(
            context,
            onDeleted: onDeleted,
          );
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          Icons.delete_forever_rounded,
          size: 20,
          color: Colors.red.shade600,
        ),
        label: Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}