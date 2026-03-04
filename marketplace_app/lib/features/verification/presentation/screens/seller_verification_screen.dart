import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/verification_service.dart';

class SellerVerificationScreen extends ConsumerStatefulWidget {
  const SellerVerificationScreen({super.key});

  @override
  ConsumerState<SellerVerificationScreen> createState() => _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends ConsumerState<SellerVerificationScreen> {
  PlatformFile? _idCardFrontFile;
  PlatformFile? _idCardBackFile;
  PlatformFile? _bankCertificateFile;
  bool _isLoading = false;

  Future<void> _pickFile(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          if (type == 'idFront') {
            _idCardFrontFile = result.files.first;
          } else if (type == 'idBack') {
            _idCardBackFile = result.files.first;
          } else {
            _bankCertificateFile = result.files.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_idCardFrontFile == null || _idCardBackFile == null || _bankCertificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les trois documents requis')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(verificationServiceProvider).submitVerification(
        idCardFrontBytes: _idCardFrontFile!.bytes!,
        idCardFrontFileName: _idCardFrontFile!.name,
        idCardBackBytes: _idCardBackFile!.bytes!,
        idCardBackFileName: _idCardBackFile!.name,
        bankCertificateBytes: _bankCertificateFile!.bytes!,
        bankCertificateFileName: _bankCertificateFile!.name,
      );
      if (mounted) {
        ref.invalidate(userProfileProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents envoyés avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du compte'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.cloviGreen,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Erreur'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(user),
                const SizedBox(height: 32),
                if (user.sellerStatus == SellerStatus.approved || user.sellerStatus == SellerStatus.pending) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          user.sellerStatus == SellerStatus.approved ? Icons.verified_user : Icons.schedule_outlined,
                          size: 80,
                          color: user.sellerStatus == SellerStatus.approved ? AppColors.cloviGreen : Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.sellerStatus == SellerStatus.approved 
                            ? 'Votre compte est déjà vérifié' 
                            : 'Votre demande est en cours de traitement',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.sellerStatus == SellerStatus.approved 
                            ? 'Vous pouvez maintenant profiter de toutes les fonctionnalités de vente.' 
                            : 'Un administrateur examine vos documents. Vous recevrez une notification bientôt.',
                          style: const TextStyle(color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Documents requis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cloviGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez fournir des photos claires de votre pièce d\'identité (recto et verso) ainsi qu\'un RIB.',
                    style: TextStyle(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 32),
                  _buildFilePickerField(
                    title: "Carte d'identité (Recto)",
                    subtitle: "Face avant de votre CIN",
                    selectedFile: _idCardFrontFile,
                    onTap: () => _pickFile('idFront'),
                  ),
                  const SizedBox(height: 20),
                  _buildFilePickerField(
                    title: "Carte d'identité (Verso)",
                    subtitle: "Face arrière de votre CIN",
                    selectedFile: _idCardBackFile,
                    onTap: () => _pickFile('idBack'),
                  ),
                  const SizedBox(height: 20),
                  _buildFilePickerField(
                    title: "Certificat Bancaire (RIB)",
                    subtitle: "Pour recevoir vos revenus de vente",
                    selectedFile: _bankCertificateFile,
                    onTap: () => _pickFile('rib'),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cloviGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Envoyer pour vérification',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildFilePickerField({
    required String title,
    required String subtitle,
    required PlatformFile? selectedFile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedFile != null ? AppColors.cloviGreen : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selectedFile != null ? AppColors.cloviGreen.withOpacity(0.05) : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                  color: selectedFile != null ? AppColors.cloviGreen : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFile != null ? selectedFile.name : "Choisir un fichier",
                        style: TextStyle(
                          color: selectedFile != null ? AppColors.cloviGreen : Colors.grey.shade600,
                          fontWeight: selectedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedFile != null)
                        Text(
                          '${(selectedFile.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (selectedFile != null)
                  const Icon(Icons.edit_outlined, size: 20, color: AppColors.cloviGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(UserModel user) {
    Color bannerColor;
    String statusText;
    IconData icon;

    switch (user.sellerStatus) {
      case SellerStatus.approved:
        bannerColor = AppColors.cloviGreen;
        statusText = 'Compte vérifié';
        icon = Icons.verified;
        break;
      case SellerStatus.pending:
        bannerColor = Colors.orange;
        statusText = 'Vérification en cours';
        icon = Icons.hourglass_empty;
        break;
      case SellerStatus.rejected:
        bannerColor = AppColors.error;
        statusText = 'Vérification rejetée';
        icon = Icons.error_outline;
        break;
      default:
        bannerColor = Colors.grey;
        statusText = 'Non soumis';
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                if (user.verificationComment != null)
                  Text(
                    user.verificationComment!,
                    style: TextStyle(fontSize: 12, color: bannerColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
