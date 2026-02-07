import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postapp/services/auth_check.dart';
import 'package:postapp/style/app_style.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final supabase = Supabase.instance.client;
  User? user;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null || user == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _image!.readAsBytes();
      final filePath = 'profile_images/${user!.id}.png';

      //print('User ID: ${user!.id}');
      //print('Uploading to path: $filePath');

      // Загружаем изображение в Supabase Storage
      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      //print('Upload successful');

      // Генерируем публичный URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      //print('Public URL: $publicUrl');

      // Обновляем профиль пользователя
      await supabase.auth.updateUser(UserAttributes(
        data: {'avatar_url': publicUrl},
      ));

      // ВАЖНО: Получаем обновленного пользователя ДО вызова setState
      final updatedUser = supabase.auth.currentUser;

      // Принудительно обновляем UI
      setState(() {
        user = updatedUser;
        _image = null; // Очищаем временное изображение
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      //print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheck()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    // Добавляем timestamp к URL чтобы избежать кеширования
    final avatarUrlWithCache = avatarUrl != null 
        ? '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}' 
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: signOut,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: avatarUrlWithCache != null
                              ? NetworkImage(avatarUrlWithCache)
                              : const AssetImage('assets/images/placeholder.png')
                                  as ImageProvider,
                          // Добавляем ключ для принудительного обновления
                          key: ValueKey(avatarUrlWithCache),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Your e-mail: ${user?.email}', style: AppStyle.mainContent),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: signOut,
                    child: Text('Exit', style: AppStyle.mainContent),
                  ),
                ],
              ),
      ),
    );
  }
}