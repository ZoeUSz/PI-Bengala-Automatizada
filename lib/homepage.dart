import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MqttServerClient? client;
  Map<String, bool> deviceStatus = {};
  Map<String, Timer?> deviceTimers = {};
  late StreamController<String> validationController;
  late Stream<String> validationStream;

  @override
  void initState() {
    super.initState();
    connect();
    validationController = StreamController<String>();
    validationStream = validationController.stream.asBroadcastStream();
  }

  Future<void> connect() async {
    client = MqttServerClient('io.adafruit.com', '');
    client!.logging(on: true);
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.onUnsubscribed = onUnsubscribed;
    client!.pongCallback = pong;

    final connMessage = MqttConnectMessage()
        .authenticateAs('offBurso', 'aio_qQpG53Qtbau5lh2vy9unrk6YGCoZ')
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client!.connectionMessage = connMessage;

    try {
      await client!.connect();
    } catch (e) {
      print('Exception: $e');
      disconnect();
    }

    if (client!.connectionStatus?.state == MqttConnectionState.connected) {
      print('Connected to Adafruit IO');
      // Listen for updates
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String topic = c[0].topic;

        setState(() {
          deviceStatus[topic] = message == 'ON';
        });

        // Process validation response
        if (topic.endsWith('/validation')) {
          validationController.add(message);
        }

        // Cancel previous timer if exists
        deviceTimers[topic]?.cancel();
        // Set a new timer to mark as 'Offline' if no new message is received in 5 seconds
        deviceTimers[topic] = Timer(const Duration(seconds: 5), () {
          setState(() {
            deviceStatus[topic] = false;
          });
        });

        print('Received message: $message from topic: $topic');
      });

      // Subscribe to all registered device topics
      FirebaseFirestore.instance
          .collection('arduinos')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get()
          .then((snapshot) {
        for (var document in snapshot.docs) {
          String macAddress = document['macAddress'];
          subscribeToTopic('offBurso/feeds/$macAddress');
        }
      });
    } else {
      print('Connection failed - status: ${client!.connectionStatus?.state}');
      disconnect();
    }
  }

  void subscribeToTopic(String topic) {
    client!.subscribe(topic, MqttQos.atMostOnce);
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void disconnect() {
    client!.disconnect();
  }

  void _showAddArduinoDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _macAddressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Arduino'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: "Nome do Arduino"),
                ),
                TextField(
                  controller: _macAddressController,
                  decoration: const InputDecoration(hintText: "Endereço MAC"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () {
                _saveArduinoDetails(_nameController.text, _macAddressController.text)
                    .then((result) {
                  if (result == 'VALID') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Arduino registrado com sucesso!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Falha ao validar o Arduino: sem resposta.")),
                    );
                  }
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _saveArduinoDetails(String name, String macAddress) async {
    if (name.isEmpty || macAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos os campos devem ser preenchidos.")),
      );
      return 'ERROR';
    }

    // Send validation request to the device
    final validationTopic = 'offBurso/feeds/$macAddress/validation';
    subscribeToTopic(validationTopic);
    client!.publishMessage(
      validationTopic,
      MqttQos.atMostOnce,
      MqttClientPayloadBuilder().addString('VALIDATE').payload!,
    );

    try {
      final response = await validationStream
          .firstWhere((response) => response == 'VALID')
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => 'TIMEOUT',
      );

      if (response == 'VALID') {
        // Save the device to Firestore
        await FirebaseFirestore.instance.collection('arduinos').add({
          'name': name,
          'macAddress': macAddress,
          'timestamp': Timestamp.now(),
          'userId': FirebaseAuth.instance.currentUser?.uid, // associar o dispositivo ao usuário
        });
        return 'VALID';
      } else {
        return 'TIMEOUT';
      }
    } catch (e) {
      return 'ERROR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Dispositivos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('arduinos')
                .where('userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return const Text('No devices registered.');
              }

              return Column(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
                  String deviceName = data['name'] ?? 'Unnamed Device';
                  String macAddress = data['macAddress'] ?? '';
                  String topic = 'offBurso/feeds/$macAddress';
                  bool isOnline = deviceStatus[topic] ?? false;

                  return DeviceCard(
                    deviceName: deviceName,
                    isOnline: isOnline,
                    onDelete: () => _deleteDevice(document.id),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDevice(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('arduinos')
          .doc(documentId)
          .delete();
      print('Device deleted: $documentId');
    } catch (e) {
      print('Error deleting device: $e');
    }
  }
}

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final bool isOnline;
  final VoidCallback onDelete;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.isOnline,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: isOnline ? Colors.yellow : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    deviceName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOnline ? 'Status: Online' : '',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
