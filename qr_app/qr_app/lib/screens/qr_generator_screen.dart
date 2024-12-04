import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final TextEditingController textController = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();
  String qrData = "";
  String selectedType = "text";
  final Map<String, TextEditingController> controllers = {
    "name": TextEditingController(),
    "phone": TextEditingController(),
    "email": TextEditingController(),
    "url": TextEditingController(),
  };

  String generateQRData() {
    switch (selectedType) {
      case "contact":
        return '''BEGIN VCARD 
      VERSION:3.0 
      FN:${controllers["name"]?.text}
      TEL:${controllers["phone"]?.text}
      EMAIL:${controllers["email"]?.text}
      END:VCARD''';

      case "url":
        String url = controllers["url"]?.text ?? "";
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
          url = "https://$url";
        }
        return url;

      default:
        return textController.text;
    }
  }

  Future<void> shareQRCode() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/qrcode.png';
    final capture = await screenshotController.capture();
    if (capture == null) return null;

    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(capture);
    await Share.shareXFiles([XFile(imagePath)], text: "Share QR Code");
  }

  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (_) {
          setState(() {
            qrData = generateQRData();
          });
        },
      ),
    );
  }

  Widget buildInputFields() {
    switch (selectedType) {
      case "contact":
        return Column(
          children: [
            buildTextField(controllers["name"]!, "Name"),
            buildTextField(controllers["phone"]!, "Phone"),
            buildTextField(controllers["email"]!, "Email"),
          ],
        );

      case "url":
        return buildTextField(controllers["url"]!, "URL");

      default:
        return TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: "Enter Text",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              qrData = value;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 145),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 196, 145),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Generate QR Code",
          style: GoogleFonts.poppins(),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(children: [
                    SegmentedButton<String>(
                      selected: {selectedType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          selectedType = selection.first;
                          qrData = "";
                        });
                      },
                      segments: const [
                        ButtonSegment(
                          value: "text",
                          label: Text("Text"),
                          icon: Icon(Icons.text_fields),
                        ),
                        ButtonSegment(
                          value: "url",
                          label: Text("URL"),
                          icon: Icon(Icons.link),
                        ),
                        ButtonSegment(
                          value: "contact",
                          label: Text("Contact"),
                          icon: Icon(Icons.contact_page),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    buildInputFields()
                  ]),
                ),
              ),
              SizedBox(
                height: 24,
              ),
              if (qrData.isNotEmpty)
                Column(
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Screenshot(
                                controller: screenshotController,
                                child: Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.all(16),
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 200,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: shareQRCode,
                      icon: Icon(Icons.share),
                      label: Text("Share QR Code"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
