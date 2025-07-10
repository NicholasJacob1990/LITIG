import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String text;
  final bool isUser;

  const Message(this.text, {this.isUser = false});

  @override
  List<Object> get props => [text, isUser];
} 