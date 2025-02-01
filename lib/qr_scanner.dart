import 'dart:convert';
import 'dart:developer';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  String? action;
  String? id;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiBarcodeScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (BarcodeCapture barcodeCapture) {
          Map<String, dynamic> data =
              jsonDecode(barcodeCapture.barcodes.first.rawValue!);
          if (data.keys.contains("join")) {
            action = "join";
            id = data["join"];
          } else {}
          setState(() {});
          debugPrint("${barcodeCapture.barcodes.first.rawValue}");
        },
        hideGalleryButton: true,
        hideSheetDragHandler: true,
        hideGalleryIcon: true,
        hideSheetTitle: true,
        actions: [
          if (action != null && id != null)
            InkWell(
              onTap: () async {
                var classData =
                    await _firestore.collection('classes').doc(id).get();
                log("class data: ${classData.data()}");
                List<String> studentsInClass =
                    (classData.data()!['students'] as List).cast<String>();
                String me = _auth.currentUser!.uid;
                if (!studentsInClass.contains(me)) {
                  studentsInClass.add(me);
                  _firestore
                      .collection("classes")
                      .doc(id)
                      .update({"students": studentsInClass});
                }

                //todo:  show if class joined successfully or not
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                margin: EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(action!.toUpperCase()),
              ),
            )
        ],
      ),
    );
  }
}
