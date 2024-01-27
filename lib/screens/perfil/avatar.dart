import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.imageUrl,
    required this.onUpload,
  });

  final String? imageUrl;
  final void Function(String imageUrl) onUpload;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  var altoPerfil = 130.0;
  var anchoPerfil = 120.0;
  var altoBoton50 = 50.0;
  var altofoto = 130.0;
  var anchofoto = 120.0;
  var tamanoDeicono = 110.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (widget.imageUrl == null || widget.imageUrl!.isEmpty)
          Center(child: _sinFoto())
        else
          Center(child: _buildFoto()),
      ],
    );
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 320,
      maxHeight: 320,
    );
    if (imageFile == null) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final userId = _supabase.auth.currentUser!.id;
      final filePath = '$userId/profile.$fileExt';
      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions:
                FileOptions(upsert: true, contentType: 'image/$fileExt'),
          );

      String imageUrl =
          await _supabase.storage.from('avatars').getPublicUrl(filePath);
      imageUrl = Uri.parse(imageUrl).replace(queryParameters: {
        't': DateTime.now().millisecondsSinceEpoch.toString()
      }).toString();
      //final imageUrl = await _supabase.storage
      //  .from('avatars')
      //.createSignedUrl(filePath, 60 * 60 * 24 * 365 * 10);
      widget.onUpload(imageUrl);
    } on StorageException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocurrio un error inesperado'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _sinFoto() => Stack(
        alignment: const Alignment(0.6, 0.6),
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 80,
          ),
          Positioned(
            bottom: 3,
            right: 0,
            child: CircleAvatar(
              maxRadius: 25,
              child: IconButton(
                onPressed: _isLoading ? null : _upload,
                icon: Icon(Icons.add_a_photo_outlined),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            right: 35,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 90,
            ),
          ),
        ],
      );
  // #docregion Stack
  Widget _buildFoto() => Stack(
        alignment: const Alignment(0.6, 0.6),
        children: [
          CircleAvatar(
            backgroundColor: Color.fromARGB(0, 0, 0, 0),
            backgroundImage: NetworkImage(widget.imageUrl!),
            radius: 80,
          ),
          Positioned(
            bottom: 5,
            right: 0,
            child: CircleAvatar(
              maxRadius: 25,
              child: IconButton(
                onPressed: _isLoading ? null : _upload,
                icon: Icon(Icons.add_a_photo_outlined),
              ),
            ),
          ),
        ],
      );
}
