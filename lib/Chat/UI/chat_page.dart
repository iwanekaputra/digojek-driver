import 'dart:convert';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:deliq_delivery/Locale/locales.dart';
import 'package:deliq_delivery/Themes/colors.dart';
import 'package:deliq_delivery/blocs/auth/auth_bloc.dart';
import 'package:deliq_delivery/models/user_model.dart';
import 'package:deliq_delivery/services/auth_service.dart';
import 'package:deliq_delivery/shared/shared_methods.dart';
import 'package:deliq_delivery/shared/shared_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const ChatPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ChatWidget(
      order: order,
    );
  }
}

class ChatWidget extends StatefulWidget {
  final Map<String, dynamic> order;

  const ChatWidget({super.key, required this.order});

  @override
  ChatWidgetState createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<MessageStreamState> _streamKey =
      GlobalKey<MessageStreamState>();

  Map? customer;
  UserModel? driver;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }

    customer = widget.order['customer'];
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // LOGIC ASLI DIBIARKAN UTUH: Kirim pesan ke API Laravel
  Future<void> addMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final token = await AuthService().getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/driver/orders/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'order_id': widget.order['order_id'],
        'sender_type': 'driver',
        'sender_id': driver!.id,
        'message': _messageController.text,
      }),
    );

    if (res.statusCode == 201) {
      _messageController.clear();
      _streamKey.currentState?.fetchChats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8B3C5),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('images/profile.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer == null ? 'loading..' : customer!['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Pelanggan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.phone_rounded, color: kMainColor, size: 20),
              onPressed: () async {
                final url =
                    "whatsapp://send?phone=${formatPhoneNumber(widget.order['order_customers'][0]['customer']['nohp'])}&text=p";
                await launchUrl(Uri.parse(Uri.encodeFull(url)));
              },
            ),
          ),
        ],
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/chat_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // Chat List Stream
              Expanded(
                child: MessageStream(
                  key: _streamKey,
                  order: widget.order,
                ),
              ),

              // Modern Floating Input Bar
              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.enterMessage,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: kMainColor,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            await addMessage();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// LOGIC ASLI DIBIARKAN UTUH: Stateful Fetch dari API Laravel
class MessageStream extends StatefulWidget {
  final Map<String, dynamic> order;
  const MessageStream({super.key, required this.order});

  @override
  State<MessageStream> createState() => MessageStreamState();
}

class MessageStreamState extends State<MessageStream> {
  UserModel? driver;
  List<dynamic> chatList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      driver = authState.user;
    }
    fetchChats();
  }

  // Fungsi mengambil data dari API Laravel `chats/{order_id}`
  Future<void> fetchChats() async {
    try {
      final token = await AuthService().getToken();
      final res = await http.get(
        Uri.parse(
            '$baseUrl/driver/orders/chats/${widget.order['order_id'].toString()}'),
        headers: {
          'Authorization': token ?? '',
        },
      );
      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        setState(() {
          chatList = responseData['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching chats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatList.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: chatList.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
      itemBuilder: (context, index) {
        final chat = chatList[index];

        String formattedTime = '';
        try {
          DateTime parsedDate = DateTime.parse(chat['created_at']);
          formattedTime = DateFormat("HH:mm").format(parsedDate.toLocal());
        } catch (e) {
          formattedTime = "--:--";
        }

        bool isMe = chat['sender_type'] == 'driver' &&
            chat['sender_id'].toString() == driver!.id.toString();

        return MessageBubble(
          sender: chat['sender_type'],
          text: chat['message'],
          time: formattedTime,
          isDelivered: chat['is_read'] == 1,
          isMe: isMe,
        );
      },
    );
  }
}

// Komponen Modern Bubble
class MessageBubble extends StatelessWidget {
  final bool? isMe;
  final String? text;
  final String? sender;
  final String? time;
  final bool? isDelivered;

  const MessageBubble({
    super.key,
    this.sender,
    this.text,
    this.time,
    this.isMe,
    this.isDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final bool me = isMe ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment:
            me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
              color: me ? kMainColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(me ? 16 : 4),
                bottomRight: Radius.circular(me ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text ?? '',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: me ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      time ?? '',
                      style: TextStyle(
                        fontSize: 10.0,
                        color: me
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (me) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        color: isDelivered ?? false
                            ? Colors.lightBlueAccent
                            : Colors.white60,
                        size: 14.0,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
