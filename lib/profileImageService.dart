import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileImageService {
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      String filePath = 'profiles/$userId/profile.jpg';
      firebase_storage.Reference ref = storage.ref().child(filePath);
      firebase_storage.UploadTask task = ref.putFile(imageFile);
      firebase_storage.TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Erro no upload: $e");
      return null;
    }
  }

  Future<String?> fetchProfileImageUrl(String userId) async {
    try {
      String filePath = 'profiles/$userId/profile.jpg';
      return await storage.ref(filePath).getDownloadURL();
    } catch (e) {
      print("Erro ao carregar a imagem de perfil: $e");
      return null;
    }
  }
}
