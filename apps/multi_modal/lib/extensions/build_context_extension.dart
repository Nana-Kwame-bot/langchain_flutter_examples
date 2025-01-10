import "dart:io";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:multi_modal/utils/either.dart";

typedef ImageCaptionDialogResult = ({XFile image, String caption});

extension BuildContextExtension on BuildContext {
  void showErrorMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );

    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  Future<Either<String, ImageCaptionDialogResult>> showImageCaptionDialog(
    XFile image,
  ) async {
    final TextEditingController captionController = TextEditingController();

    final result = await showDialog<ImageCaptionDialogResult>(
      context: this,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Preview & Add Caption",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Image preview with constrained height
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(image.path),
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    controller: captionController,
                    decoration: const InputDecoration(
                      hintText: "Add a caption...",
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            (
                              image: image,
                              caption: captionController.text,
                            ),
                          );
                        },
                        child: const Text("Send"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return switch (result) {
      (image: XFile image, caption: String caption) => Right(
          (
            image: image,
            caption: caption,
          ),
        ),
      _ => Left("Operation Cancelled"),
    };
  }
}
