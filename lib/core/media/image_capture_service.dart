import 'package:image_picker/image_picker.dart';

class ImageCaptureService {
  ImageCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<XFile?> captureOutletPhoto() => _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 80,
    maxWidth: 1600,
  );
}
