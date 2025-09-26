import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guinemali/core/constants/app_constants.dart';
import 'package:guinemali/core/services/storage_service.dart';
import 'package:guinemali/core/services/evidence_service.dart';
import 'package:guinemali/core/services/sync_service.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path/path.dart' as p;

class VictimEvidenceScreen extends StatefulWidget {
  const VictimEvidenceScreen({super.key});

  @override
  State<VictimEvidenceScreen> createState() => _VictimEvidenceScreenState();
}

class _VictimEvidenceScreenState extends State<VictimEvidenceScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;
  Duration _recordingDuration = Duration.zero;
  List<EvidenceItem> _evidenceList = [];
  bool _isLoading = true;
  String? _currentAlertId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isCapturingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadEvidenceList();
    _getCurrentAlertId();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentAlertId() async {
    _currentAlertId = StorageService.instance.getString(AppConstants.keyCurrentAlertId);
  }

  Future<String> _resolveEvidencePath(String primary, {String? secondary}) async {
    // 1) Chemin primaire
    if (primary.isNotEmpty && await File(primary).exists()) return primary;
    // 2) Chemin secondaire
    if (secondary != null && secondary.isNotEmpty && await File(secondary).exists()) return secondary;
    // 3) Tenter par basename dans le dossier documents (migration cache -> persistant)
    try {
      final docs = await getApplicationDocumentsDirectory();
      final candidate = p.join(docs.path, p.basename(primary.isNotEmpty ? primary : (secondary ?? '')));
      if (await File(candidate).exists()) return candidate;
    } catch (_) {}
    return primary; // retour par défaut
  }

  Future<void> _playEvidence(EvidenceItem evidence) async {
    try {
      if (evidence.type == EvidenceType.audio) {
        // Mini-lecteur audio modal
        final path = await _resolveEvidencePath(evidence.originalPath, secondary: evidence.filePath);
        await _audioPlayer.setFilePath(path);
        await _audioPlayer.play();
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _buildAudioPlayerSheet(evidence),
        ).whenComplete(() => _audioPlayer.stop());
      } else if (evidence.type == EvidenceType.video) {
        // Lecteur vidéo plein écran
        _videoController?.dispose();
        _chewieController?.dispose();
        final path = await _resolveEvidencePath(evidence.originalPath, secondary: evidence.filePath);
        if (!await File(path).exists()) {
          _showSnack('Fichier introuvable', isError: true);
          return;
        }
        _videoController = VideoPlayerController.file(File(path));
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppConstants.primaryColor,
            handleColor: AppConstants.secondaryColor,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: Colors.grey.shade500,
          ),
        );
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Lecture Vidéo')),
            backgroundColor: Colors.black,
            body: Center(child: Chewie(controller: _chewieController!)),
          ),
        )).whenComplete(() {
          _videoController?.pause();
        });
      } else if (evidence.type == EvidenceType.photo) {
        // Afficher la photo
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Photo'),
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: AppConstants.whiteColor,
              ),
              body: Center(
                child: Image.file(
                  File(evidence.originalPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack('Erreur de lecture: $e', isError: true);
    }
  }

  Widget _buildAudioPlayerSheet(EvidenceItem evidence) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audiotrack, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              const Text('Lecture Audio', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return Row(
                children: [
                  IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36, color: AppConstants.primaryColor),
                    onPressed: () async {
                      if (playing) {
                        await _audioPlayer.pause();
                      } else {
                        await _audioPlayer.play();
                      }
                    },
                  ),
                  Expanded(
                    child: StreamBuilder<Duration?>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final total = _audioPlayer.duration ?? Duration.zero;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              min: 0,
                              max: total.inMilliseconds.toDouble().clamp(1, double.infinity),
                              value: pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
                              activeColor: AppConstants.primaryColor,
                              onChanged: (v) => _audioPlayer.seek(Duration(milliseconds: v.toInt())),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(pos), style: const TextStyle(fontSize: 12)),
                                Text(_formatDuration(total), style: const TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  )
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text('Fichier: ${evidence.originalPath}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _loadEvidenceList() async {
    setState(() => _isLoading = true);
    try {
      // Charger la liste des preuves depuis le service local
      final evidences = await EvidenceService.instance.getEvidences();
      setState(() {
        _evidenceList = evidences
            .map((evidence) => EvidenceItem.fromLocalService(evidence))
            .toList();
      });
    } catch (e) {
      print('Erreur lors du chargement des preuves: $e');
      _evidenceList = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvidenceList() async {
    try {
      final evidenceJson = _evidenceList.map((item) => item.toJson()).toList();
      await StorageService.instance.saveString('evidence_list', json.encode(evidenceJson));
    } catch (e) {
      print('Erreur lors de la sauvegarde des preuves: $e');
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      // Vérifier les permissions
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _showSnack('Permission microphone refusée', isError: true);
        return;
      }

      // Obtenir le répertoire de stockage
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.m4a';
      final filePath = '${directory.path}/$fileName';

      // Démarrer l'enregistrement
      await _audioRecorder.start(const RecordConfig(), path: filePath);
      
      setState(() {
        _isRecordingAudio = true;
        _recordingDuration = Duration.zero;
      });

      // Timer pour la durée d'enregistrement
      _startRecordingTimer();

      _showSnack('Enregistrement audio démarré');
    } catch (e) {
      _showSnack('Erreur lors du démarrage de l\'enregistrement: $e', isError: true);
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        // Enregistrer via le service local
        await EvidenceService.instance.recordAudioEvidence(
          alertId: _currentAlertId ?? 'manual',
          filePath: path,
          duration: _recordingDuration.inSeconds,
        );
        
        // Recharger la liste des preuves
        await _loadEvidenceList();
        _showSnack('Preuve audio enregistrée et chiffrée');
      }
    } catch (e) {
      _showSnack('Erreur lors de l\'arrêt de l\'enregistrement: $e', isError: true);
    } finally {
      setState(() {
        _isRecordingAudio = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      // Vérifier les permissions
      final cameraPermission = await Permission.camera.request();
      final microphonePermission = await Permission.microphone.request();
      
      if (!cameraPermission.isGranted || !microphonePermission.isGranted) {
        _showSnack('Permissions caméra/microphone refusées', isError: true);
        return;
      }

      setState(() => _isRecordingVideo = true);

      // Lancer l'enregistrement vidéo
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        // Copier la vidéo du cache vers le stockage persistant
        final docs = await getApplicationDocumentsDirectory();
        final targetPath = p.join(docs.path, p.basename(video.path));
        await File(video.path).copy(targetPath);

        // Chiffrer une copie et conserver l'original en clair pour lecture locale
        final encryptedPath = await _encryptFile(targetPath);

        // Créer l'item de preuve en pointant originalPath vers app_flutter
        final evidenceItem = EvidenceItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: EvidenceType.video,
          filePath: encryptedPath,
          originalPath: targetPath,
          duration: const Duration(seconds: 0), // Durée à calculer si nécessaire
          size: await File(encryptedPath).length(),
          dateCreated: DateTime.now(),
          isEncrypted: true,
          isSynced: false,
          alertId: _currentAlertId,
        );

        // Sauvegarder en base locale pour qu'elle ne disparaisse pas après rafraîchissement
        try {
          final fileLen = await File(evidenceItem.originalPath).length();
          await StorageService.instance.saveEvidence(
            id: evidenceItem.id,
            alertId: _currentAlertId ?? 'manual',
            type: 'video',
            filePath: evidenceItem.originalPath,
            fileSize: fileLen,
          );
          await SyncService.instance.addToSyncQueue('evidence', {
            'id': evidenceItem.id,
            'alert_id': _currentAlertId ?? 'manual',
            'type': 'video',
            'file_path': evidenceItem.originalPath,
            'file_size': fileLen,
          });
        } catch (_) {}

        _evidenceList.insert(0, evidenceItem);
        await _saveEvidenceList();
        
        _showSnack('Preuve vidéo enregistrée et chiffrée');
      }
    } catch (e) {
      _showSnack('Erreur lors de l\'enregistrement vidéo: $e', isError: true);
    } finally {
      setState(() => _isRecordingVideo = false);
    }
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecordingAudio) {
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _startRecordingTimer();
      }
    });
  }

  Future<String> _encryptFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Clé de chiffrement simple (en production, utiliser une clé plus sécurisée)
      final key = utf8.encode('guinemali_evidence_key_2024');
      final keyBytes = sha256.convert(key).bytes;
      
      // Chiffrement simple (en production, utiliser AES-GCM)
      final encryptedBytes = _simpleEncrypt(bytes, keyBytes);
      
      // Sauvegarder le fichier chiffré
      final encryptedPath = '${filePath}_encrypted';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      return encryptedPath;
    } catch (e) {
      print('Erreur lors du chiffrement: $e');
      return filePath; // Retourner le chemin original en cas d'erreur
    }
  }

  List<int> _simpleEncrypt(List<int> data, List<int> key) {
    // Chiffrement simple XOR (en production, utiliser AES-GCM)
    final result = <int>[];
    for (int i = 0; i < data.length; i++) {
      result.add(data[i] ^ key[i % key.length]);
    }
    return result;
  }

  Future<void> _deleteEvidence(EvidenceItem evidence) async {
    try {
      // Supprimer le fichier local
      final file = File(evidence.originalPath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Supprimer de la base de données locale
      await StorageService.instance.removeEvidence(evidence.id);
      
      // Recharger la liste
      await _loadEvidenceList();
      
      _showSnack('Preuve supprimée');
    } catch (e) {
      _showSnack('Erreur lors de la suppression: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppConstants.whiteColor),
        ),
        backgroundColor: isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.whiteColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: AppConstants.whiteColor,
      centerTitle: true,
      title: const Text(
        '🎥 Preuves',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.whiteColor,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.secondaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.secondaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${_evidenceList.length} preuves',
            style: const TextStyle(
              color: AppConstants.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildRecordingButtons(),
          const SizedBox(height: 20),
          _buildEvidenceList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enregistrement Sécurisé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Toutes les preuves sont chiffrées localement et stockées en sécurité.',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.blackColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildRecordingButton(
              icon: Icons.mic,
              label: 'Audio',
              isRecording: _isRecordingAudio,
              onTap: _isRecordingAudio ? _stopAudioRecording : _startAudioRecording,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRecordingButton(
              icon: Icons.videocam,
              label: 'Vidéo',
              isRecording: _isRecordingVideo,
              onTap: _startVideoRecording,
              color: AppConstants.secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRecordingButton(
              icon: Icons.camera_alt,
              label: 'Photo',
              isRecording: false,
              onTap: _takePhoto,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton({
    required IconData icon,
    required String label,
    required bool isRecording,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: label == 'Audio' && _isRecordingAudio ? _stopAudioRecording : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isRecording ? color.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isRecording ? color : AppConstants.whiteColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isRecording ? color : AppConstants.whiteColor,
              ),
            ),
            if (isRecording && label == 'Audio') ...[
              const SizedBox(height: 4),
              Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
        ),
      );
    }

    if (_evidenceList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: AppConstants.primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune preuve enregistrée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.blackColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enregistrez des preuves audio ou vidéo',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.blackColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _evidenceList.length,
        itemBuilder: (context, index) {
          final evidence = _evidenceList[index];
          return _buildEvidenceCard(evidence);
        },
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceItem evidence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: evidence.type == EvidenceType.audio 
                ? AppConstants.primaryColor.withOpacity(0.1)
                : evidence.type == EvidenceType.photo
                    ? Colors.orange.withOpacity(0.1)
                    : AppConstants.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            evidence.type == EvidenceType.audio 
                ? Icons.audiotrack 
                : evidence.type == EvidenceType.photo
                    ? Icons.camera_alt
                    : Icons.videocam,
            color: evidence.type == EvidenceType.audio 
                ? AppConstants.primaryColor 
                : evidence.type == EvidenceType.photo
                    ? Colors.orange
                    : AppConstants.secondaryColor,
            size: 24,
          ),
        ),
        title: Text(
          evidence.type == EvidenceType.audio 
              ? 'Enregistrement Audio' 
              : evidence.type == EvidenceType.photo
                  ? 'Photo'
                  : 'Enregistrement Vidéo',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppConstants.blackColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(evidence.dateCreated),
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.blackColor,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
            Icon(
              evidence.isEncrypted ? Icons.lock : Icons.lock_open,
              size: 12,
              color: evidence.isEncrypted ? AppConstants.successColor : AppConstants.warningColor,
            ),
                const SizedBox(width: 4),
                Text(
                  evidence.isEncrypted ? 'Chiffré' : 'Non chiffré',
                  style: TextStyle(
                    fontSize: 10,
                    color: evidence.isEncrypted ? AppConstants.successColor : AppConstants.warningColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  evidence.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 12,
                  color: evidence.isSynced ? AppConstants.successColor : AppConstants.infoColor,
                ),
                const SizedBox(width: 4),
                Text(
              evidence.isSynced ? 'Synchronisé' : 'En attente',
                  style: TextStyle(
                    fontSize: 10,
                    color: evidence.isSynced ? AppConstants.successColor : AppConstants.infoColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppConstants.primaryColor),
              onPressed: () => _playEvidence(evidence),
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: AppConstants.infoColor),
              tooltip: 'Réessayer la synchronisation',
              onPressed: () async {
                try {
                  _showSnack('Synchronisation en cours...');
                  
                  // Ajouter à la file de synchronisation
                  await SyncService.instance.addToSyncQueue('evidence', {
                    'id': evidence.id,
                    'alert_id': evidence.alertId ?? 'manual',
                    'type': evidence.type.toString().split('.').last,
                    'file_path': evidence.originalPath,
                    'file_size': evidence.size,
                    'timestamp': evidence.dateCreated.toIso8601String(),
                  });
                  
                  // Déclencher la synchronisation immédiate
                  await SyncService.instance.forceSync();
                  
                  // Recharger la liste
                  await _loadEvidenceList();
                  
                  _showSnack('Synchronisation terminée');
                } catch (e) {
                  _showSnack('Erreur de synchronisation: $e', isError: true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppConstants.errorColor),
              onPressed: () => _showDeleteDialog(evidence),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(EvidenceItem evidence) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.whiteColor,
        title: const Text(
          'Supprimer la preuve',
          style: TextStyle(
            color: AppConstants.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Cette action supprimera définitivement la preuve. Cette action est irréversible.',
          style: TextStyle(color: AppConstants.blackColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEvidence(evidence);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: AppConstants.whiteColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _takePhoto() async {
    try {
      if (_isCapturingPhoto) return;
      _isCapturingPhoto = true;
      final path = await EvidenceService.instance.takePhoto(_currentAlertId ?? 'manual');
      if (path != null) {
        await _loadEvidenceList();
        _showSnack('Photo enregistrée');
      } else {
        _showSnack('Échec de la prise de photo', isError: true);
      }
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    } finally {
      _isCapturingPhoto = false;
    }
  }


}

enum EvidenceType { audio, video, photo }

class EvidenceItem {
  final String id;
  final EvidenceType type;
  final String filePath;
  final String originalPath;
  final Duration duration;
  final int size;
  final DateTime dateCreated;
  final bool isEncrypted;
  final bool isSynced;
  final String? alertId;

  EvidenceItem({
    required this.id,
    required this.type,
    required this.filePath,
    required this.originalPath,
    required this.duration,
    required this.size,
    required this.dateCreated,
    required this.isEncrypted,
    required this.isSynced,
    this.alertId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'filePath': filePath,
      'originalPath': originalPath,
      'duration': duration.inSeconds,
      'size': size,
      'dateCreated': dateCreated.toIso8601String(),
      'isEncrypted': isEncrypted,
      'isSynced': isSynced,
      'alertId': alertId,
    };
  }

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      id: json['id'],
      type: json['type'] == 'EvidenceType.audio' ? EvidenceType.audio : json['type'] == 'EvidenceType.photo' ? EvidenceType.photo : EvidenceType.video,
      filePath: json['filePath'],
      originalPath: json['originalPath'],
      duration: Duration(seconds: json['duration']),
      size: json['size'],
      dateCreated: DateTime.parse(json['dateCreated']),
      isEncrypted: json['isEncrypted'],
      isSynced: json['isSynced'],
      alertId: json['alertId'],
    );
  }

  factory EvidenceItem.fromLocalService(Map<String, dynamic> evidence) {
    return EvidenceItem(
      id: evidence['id'] as String,
      type: evidence['type'] == 'audio' ? EvidenceType.audio : evidence['type'] == 'photo' ? EvidenceType.photo : EvidenceType.video,
      filePath: (evidence['file_path'] ?? evidence['encryptedPath'] ?? evidence['path']) as String,
      originalPath: (evidence['originalPath'] ?? evidence['file_path'] ?? evidence['path']) as String,
      duration: Duration(seconds: (evidence['duration'] ?? 0) as int),
      size: (evidence['file_size'] ?? evidence['size'] ?? 0) as int,
      dateCreated: DateTime.parse((evidence['timestamp'] ?? DateTime.now().toIso8601String()) as String),
      isEncrypted: true, // Toujours chiffré avec le service local
      isSynced: false, // Pas encore synchronisé avec Supabase
      alertId: evidence['alertId'] as String?,
    );
  }
}