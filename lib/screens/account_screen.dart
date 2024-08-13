import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postapp/services/auth_check.dart';
import 'package:postapp/style/app_style.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final user = FirebaseAuth.instance.currentUser;
  File? _image;
  final ImagePicker _picker = ImagePicker();

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
    if (_image != null && user != null) {
      try {
        // Загрузка изображения в Firebase Storage
        String filePath = 'profile_images/${user!.uid}.png';
        Reference storageReference =
            FirebaseStorage.instance.ref().child(filePath);
        UploadTask uploadTask = storageReference.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

        // Получение URL загруженного изображения
        String photoUrl = await taskSnapshot.ref.getDownloadURL();

        // Обновление профиля пользователя
        await user!.updatePhotoURL(photoUrl);

        // Обновление UI
        setState(() {
          // UI автоматически обновится, так как мы уже вызвали setState
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Profile photo updated!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')) );
      }
    }
  }

  Future<void> signOut() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();

    //navigator.pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthCheck()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        //   icon: const Icon(
        //     Icons.arrow_back_ios, // add custom icons also
        //   ),
        // ),
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage, // Открываем галерею по нажатию на аватар
              child: CircleAvatar(
                radius: 70,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : const AssetImage('assets/images/placeholder.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            Text('Your e-mail: ${user?.email}',style:(AppStyle.mainContent)),
            TextButton(
              onPressed: () => signOut(),
              child:  Text('Exit',style:(AppStyle.mainContent)),
            ),
          ],
        ),
      ),
    );
  }
}
