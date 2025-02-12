import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String content;
  final int receiverId;
  final int senderId;
  final DateTime time;

  Message({
    required this.content,
    required this.receiverId,
    required this.senderId,
    required this.time,
  });

  factory Message.fromFirestore(Map<String, dynamic> data) {
    return Message(
      content: data['Content'],
      receiverId: data['ReceiverID'],
      senderId: data['SenderID'],
      time: (data['Time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'Content': content,
      'ReceiverID': receiverId,
      'SenderID': senderId,
      'Time': time,
    };
  }
}
