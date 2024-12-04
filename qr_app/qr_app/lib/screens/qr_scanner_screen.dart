import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as contacts;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool hasPermission = false;
  bool isFlashOn = false;

  late MobileScannerController scannerController;

  @override
  void initState() {
    super.initState();
    scannerController = MobileScannerController();
    checkPermission();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status.isGranted;
    });
  }

  Future<void> processScannedData(String? data) async {
    if (data == null) return;

    scannerController.stop();

    String type = "text";
    if (data.startsWith('BEGIN:VCARD')) {
      type = "contact";
    } else if (data.startsWith('https://') || data.startsWith('http://')) {
      type = "url";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              "Scanned Result:",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Text(
              "Type: ${type.toUpperCase()}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      data,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 24),
                    if (type == "url")
                      ElevatedButton.icon(
                        onPressed: () {
                          launchURL(data);
                        },
                        icon: Icon(Icons.open_in_new),
                        label: Text("Open URL"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(50),
                        ),
                      ),
                    if (type == "contact")
                      ElevatedButton.icon(
                        onPressed: () {
                          saveContact(data);
                        },
                        icon: Icon(Icons.open_in_new),
                        label: Text("Save Contact"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(50),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(data);
                    },
                    icon: Icon(Icons.share),
                    label: Text(
                      "Share",
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      scannerController.start();
                    },
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text(
                      "Scan Again",
                    ),
                  ),
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }

  Future<void> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot launch URL")),
      );
    }
  }

  Future<void> saveContact(String vcardData) async {
    final lines = vcardData.split('\n');
    String? name, phone, email;

    for (var line in lines) {
      if (line.startsWith('FN:')) name = line.substring(3);
      if (line.startsWith('TEL:')) phone = line.substring(4);
      if (line.startsWith('EMAIL:')) email = line.substring(5);
    }
    final contact = contacts.Contact()
      ..name.first = name ?? ''
      ..phones = [contacts.Phone(phone ?? '')]
      ..emails = [contacts.Email(email ?? '')];

    try {
      await contact.insert();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Contact saved")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save contact")));
    }
  }

  Future<void> scanFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // QR kodunu analiz et
      final result = await scannerController.analyzeImage(image.path);

      // Eğer result null değil ve QR kodu bulunduysa
      if (result != null && result) {
        // QR kodu bulundu, işlemi başlat
        print("QR Code found!");
        processScannedData(result
            as String?); // result burada QR kodu verisini içeriyor olabilir
      } else {
        // QR kodu bulunamadı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No QR Code found in the image")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 196, 145),
        appBar: AppBar(
          title: Text("QR Scanner"),
          backgroundColor: Color.fromARGB(255, 255, 196, 145),
          foregroundColor: Colors.white,
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  height: 350,
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text("Camera Permission is Required"),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: checkPermission,
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 255, 196, 145),
                                foregroundColor: Colors.white),
                            child: Text("Grant Permission"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ]),
      );
    } else {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 196, 145),
        appBar: AppBar(
          title: Text("Scan QR Code"),
          backgroundColor: Color.fromARGB(255, 255, 196, 145),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  isFlashOn = !isFlashOn;
                  scannerController.toggleTorch();
                });
              },
              icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            ),
            IconButton(
              onPressed: scanFromGallery,
              icon: Icon(Icons.image),
            ),
          ],
        ),
        body: Stack(children: [
          MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  final String code = barcode.rawValue!;
                  processScannedData(code);
                }
              }),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "Point your camera at a QR code",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ]),
      );
    }
  }
}
