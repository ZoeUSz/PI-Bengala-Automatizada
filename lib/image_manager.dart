import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pi/app_colors.dart';
import 'package:flutter_pi/profileImageService.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:permission_handler/permission_handler.dart';

class ImageScreen extends StatefulWidget {
  final Function(String imageUrl)? onImageUploaded;
  const ImageScreen({super.key, this.onImageUploaded});

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  XFile? _image;
  String? _downloadUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchProfileImage();
  }

  Future<void> pickImage() async {
    await requestPermissions();
    final ImagePicker picker = ImagePicker();
    final XFile? selectedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
        _isUploading = false;
      });
    }
  }

  Future<void> uploadImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _image != null) {
      setState(() {
        _isUploading = true;
      });
      try {
        String filePath = 'profiles/${user.uid}/profile.jpg';
        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref().child(filePath);
        firebase_storage.UploadTask task = ref.putFile(File(_image!.path));
        firebase_storage.TaskSnapshot snapshot = await task;
        String imageUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _downloadUrl = imageUrl;
          _isUploading = false;
        });
        if (widget.onImageUploaded != null) {
          widget.onImageUploaded!(imageUrl);
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      print("Usuário não está logado ou imagem não selecionada!");
    }
  }

  Future<void> saveImage(XFile image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      File imageFile = File(image.path);
      ProfileImageService imageService = ProfileImageService();
      String? imageUrl =
          await imageService.uploadProfileImage(user.uid, imageFile);
      if (imageUrl != null) {
        widget.onImageUploaded?.call(imageUrl);
        setState(() {
          _downloadUrl = imageUrl;
        });
      }
    }
  }

  Future<void> fetchProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String filePath = 'profiles/${user.uid}/profile.jpg';
      try {
        String imageUrl = await firebase_storage.FirebaseStorage.instance
            .ref(filePath)
            .getDownloadURL();
        setState(() {
          _downloadUrl = imageUrl;
        });
      } catch (e) {
        print("Erro ao carregar a imagem de perfil: $e");
      }
    } else {
      print("Usuário não está logado.");
    }
  }

  Future<void> requestPermissions() async {
    var cameraStatus = await Permission.camera.status;
    var storageStatus = await Permission.storage.status;

    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }

    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_image != null)
                  SizedBox(
                    height: 300, // Define uma altura fixa para a nova imagem
                    width: double.infinity,
                    child: Image.file(File(_image!.path), fit: BoxFit.contain),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isUploading ? null : uploadImage,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Enviar Imagem'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: pickImage,
                  child: const Text('Selecionar Imagem'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Imagem Atual:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_downloadUrl != null)
                  Image.network(_downloadUrl!,
                      height: 200,
                      fit: BoxFit.contain), // Ajusta a imagem atual
              ],
            ),
          ),
        ),
      ),
    );
  }
}
