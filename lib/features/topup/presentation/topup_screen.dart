import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _customController = TextEditingController();
  final _imagePicker = ImagePicker();

  int? _selectedAmount;
  double? _paymentAmount;
  Uint8List? _proofBytes;
  String? _proofFileName;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  void _continueToPayment() {
    final custom = double.tryParse(_customController.text);
    final amount = custom ?? _selectedAmount?.toDouble();
    if (amount == null || amount < 1000) {
      _showMessage('Masukkan nominal top-up minimal Rp1.000.', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _paymentAmount = amount;
      _proofBytes = null;
      _proofFileName = null;
    });
  }

  Future<void> _pickProof() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        _showMessage('Ukuran bukti maksimal 5 MB.', isError: true);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _proofBytes = bytes;
      _proofFileName = image.name;
    });
  }

  Future<void> _submit() async {
    if (_paymentAmount == null) return;
    if (_proofBytes == null || _proofFileName == null) {
      _showMessage('Pilih bukti pembayaran terlebih dahulu.', isError: true);
      return;
    }

    final success = await context.read<AppController>().submitTopUp(
      amount: _paymentAmount!,
      proofBytes: _proofBytes!,
      proofFileName: _proofFileName!,
    );
    if (!mounted) return;

    final controller = context.read<AppController>();
    _showMessage(
      success
          ? 'Permintaan top-up terkirim dan menunggu persetujuan.'
          : controller.errorMessage ?? 'Top-up gagal dikirim.',
      isError: !success,
    );
    if (success) {
      setState(() {
        _paymentAmount = null;
        _selectedAmount = null;
        _proofBytes = null;
        _proofFileName = null;
        _customController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_paymentAmount == null ? 'Top Up Balance' : 'Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PagePadding(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _paymentAmount == null
                    ? _AmountStep(
                        key: const ValueKey('amount'),
                        controller: controller,
                        selectedAmount: _selectedAmount,
                        customController: _customController,
                        onAmountSelected: (amount) {
                          setState(() {
                            _selectedAmount = amount;
                            _customController.clear();
                          });
                        },
                        onCustomChanged: () =>
                            setState(() => _selectedAmount = null),
                        onContinue: _continueToPayment,
                      )
                    : _PaymentStep(
                        key: const ValueKey('payment'),
                        amount: _paymentAmount!,
                        proofBytes: _proofBytes,
                        proofFileName: _proofFileName,
                        isSubmitting: controller.isSubmitting,
                        onBack: () => setState(() => _paymentAmount = null),
                        onPickProof: _pickProof,
                        onSubmit: _submit,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    super.key,
    required this.controller,
    required this.selectedAmount,
    required this.customController,
    required this.onAmountSelected,
    required this.onCustomChanged,
    required this.onContinue,
  });

  final AppController controller;
  final int? selectedAmount;
  final TextEditingController customController;
  final ValueChanged<int> onAmountSelected;
  final VoidCallback onCustomChanged;
  final VoidCallback onContinue;

  static const _amounts = [10000, 20000, 50000, 100000];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'topup-wallet-card',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'RFID BALANCE',
                          style: TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      StatusBadge(
                        status: controller.profile?.rfidStatus ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatCurrency(controller.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _WalletDetail(
                          label: 'CARD ID',
                          value: controller.profile?.rfidUid ?? '-',
                        ),
                      ),
                      Expanded(
                        child: _WalletDetail(
                          label: 'PLATE NUMBER',
                          value: controller.profile?.plateNumber ?? '-',
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Pilih nominal'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _amounts.length,
          itemBuilder: (_, index) {
            final amount = _amounts[index];
            final selected = amount == selectedAmount;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: InkWell(
                onTap: () => onAmountSelected(amount),
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    formatCurrency(amount),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: customController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onCustomChanged(),
          decoration: const InputDecoration(
            labelText: 'Nominal lainnya',
            hintText: 'Masukkan nominal',
            prefixText: 'Rp ',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text('Lanjut ke Pembayaran'),
        ),
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    super.key,
    required this.amount,
    required this.proofBytes,
    required this.proofFileName,
    required this.isSubmitting,
    required this.onBack,
    required this.onPickProof,
    required this.onSubmit,
  });

  final double amount;
  final Uint8List? proofBytes;
  final String? proofFileName;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onPickProof;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final qrData =
        'MY-PARKING|QRIS-DUMMY|AMOUNT=${amount.round()}|REF=${DateTime.now().millisecondsSinceEpoch ~/ 60000}';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isSubmitting ? null : onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Ubah nominal'),
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'SCAN QRIS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(amount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 210,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.text,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'QRIS DUMMY - BELUM UNTUK PEMBAYARAN ASLI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bukti pembayaran',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: isSubmitting ? null : onPickProof,
              child: SizedBox(
                width: double.infinity,
                child: proofBytes == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: AppColors.primary,
                              size: 38,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Pilih bukti dari galeri',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'JPG atau PNG, maksimal 5 MB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                proofBytes!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  proofFileName ?? 'Bukti pembayaran',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                'Ganti',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Kirim Bukti Top Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletDetail extends StatelessWidget {
  const _WalletDetail({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFDBEAFE),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
