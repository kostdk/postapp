import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:postapp/style/app_style.dart";

// ignore: must_be_immutable
class NoteReaderScreen extends StatefulWidget {
  NoteReaderScreen(this.doc, {super.key});
  QueryDocumentSnapshot doc;

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    int color_id = widget.doc['color_id'];
    return Scaffold(
      
      backgroundColor: AppStyle.cardsColor[color_id],
      appBar: AppBar(
        backgroundColor: AppStyle.cardsColor[color_id],
        elevation:0.0,

        ),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.doc["note_title"],
              style: AppStyle.mainTitle,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0,),
            Text(
              widget.doc["creation_date"],
              style: AppStyle.dateTitle,
            ),
            const SizedBox(height: 28.0,),
            Text(
              widget.doc["note_content"],
              style: AppStyle.mainContent,
              overflow: TextOverflow.ellipsis,
            ),
         
          ],
        ),
      ),
       floatingActionButton: FloatingActionButton(
          //backgroundColor: AppStyle.accentColor,
          onPressed: () async {
            FirebaseFirestore.instance.collection(user!.uid).doc(widget.doc.id).delete().then((value){
              print (null);           
              Navigator.pop(context);
            // ignore: invalid_return_type_for_catch_error, avoid_print
       }).catchError((error) => print("failed to delete due $error"));
          },
          child: const Icon(Icons.delete),
    ));
  }
}