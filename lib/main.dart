import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Badawi Control IoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: IoTControllerPage(),
    );
  }
}

class IoTControllerPage extends StatefulWidget {
  @override
  _IoTControllerPageState createState() => _IoTControllerPageState();
}

class _IoTControllerPageState extends State<IoTControllerPage>
    with TickerProviderStateMixin {
  MqttServerClient? client;
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  // MQTT Configuration
  String broker = '172.16.93.92';
  int port = 1883;
  String clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  String username = '';
  String password = '';

  // Topics
  String ledTopic = 'esp32/led';
  String sensorTopic = 'esp32/sensor';
  String statusTopic = 'esp32/status';

  // Device States
  bool ledState = false;
  double temperature = 0.0;
  double humidity = 0.0;
  String deviceStatus = 'Offline';
  int uptime = 0;

  // Controllers
  TextEditingController brokerController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    brokerController.text = broker;
    setupMqttClient();
    client!.logging(on: true);

    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _slideController.forward();
  }

  void setupMqttClient() {
    client = MqttServerClient(broker, clientId);
    client!.port = port;
    client!.keepAlivePeriod = 30;
    client!.onDisconnected = onDisconnected;
    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('clients/flutter')
        .withWillMessage('Flutter client disconnected')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (username.isNotEmpty && password.isNotEmpty) {
      connMess.authenticateAs(username, password);
    }

    client!.connectionMessage = connMess;
  }

  Future<void> connectToMqtt() async {
    setState(() {
      connectionStatus = 'Connecting...';
    });

    broker = brokerController.text;
    username = usernameController.text;
    password = passwordController.text;

    setupMqttClient();

    try {
      await client!.connect();
    } catch (e) {
      print('Exception: $e');
      client!.disconnect();
      setState(() {
        connectionStatus = 'Connection failed: ${e.toString()}';
        isConnected = false;
      });
    }
  }

  void onConnected() {
    setState(() {
      connectionStatus = 'Connected';
      isConnected = true;
    });

    client!.subscribe(sensorTopic, MqttQos.atMostOnce);
    client!.subscribe(statusTopic, MqttQos.atMostOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      handleIncomingMessage(c[0].topic, message);
    });

    print('Connected to MQTT broker');
  }

  void onDisconnected() {
    setState(() {
      connectionStatus = 'Disconnected';
      isConnected = false;
      deviceStatus = 'Offline';
    });
    print('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void handleIncomingMessage(String topic, String message) {
    print('Received message: $message from topic: $topic');

    setState(() {
      if (topic == sensorTopic) {
        try {
          final data = json.decode(message);
          temperature = data['temperature']?.toDouble() ?? 0.0;
          humidity = data['humidity']?.toDouble() ?? 0.0;
        } catch (e) {
          print('Error parsing sensor data: $e');
        }
      } else if (topic == statusTopic) {
        try {
          final data = json.decode(message);
          deviceStatus = data['status'] ?? 'Offline';
          uptime = data['uptime']?.toInt() ?? 0;
        } catch (e) {
          print('Error parsing status data: $e');
          deviceStatus = message;
        }
      }
    });
  }

  void publishMessage(String topic, String message) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
      print('Published message: $message to topic: $topic');
    }
  }

  void toggleLED() {
    ledState = !ledState;
    final message = json.encode({'led': ledState});
    publishMessage(ledTopic, message);
    setState(() {});
  }

  void disconnect() {
    client!.disconnect();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    client?.disconnect();
    brokerController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    topicController.dispose();
    super.dispose();
  }

  Widget _buildGradientCard({
    required Widget child,
    required List<Color> colors,
    double? height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAnimatedStatusIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isConnected ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.greenAccent : Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.red).withOpacity(
                    0.5,
                  ),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF667eea)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.router,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IoT Controller',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Smart Home Dashboard',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    Spacer(),
                    _buildAnimatedStatusIndicator(),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Connection Section
                        _buildGradientCard(
                          colors: [Colors.white, Colors.white.withOpacity(0.9)],
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.wifi,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'MQTT Connection',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                _buildStylishTextField(
                                  controller: brokerController,
                                  label: 'MQTT Broker',
                                  icon: Icons.dns,
                                  onChanged: (value) => broker = value,
                                ),
                                SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStylishTextField(
                                        controller: usernameController,
                                        label: 'Username',
                                        icon: Icons.person,
                                        onChanged: (value) => username = value,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _buildStylishTextField(
                                        controller: passwordController,
                                        label: 'Password',
                                        icon: Icons.lock,
                                        obscureText: true,
                                        onChanged: (value) => password = value,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGradientButton(
                                        text: 'Connect',
                                        colors: [
                                          Colors.green,
                                          Colors.greenAccent,
                                        ],
                                        onPressed:
                                            isConnected ? null : connectToMqtt,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: _buildGradientButton(
                                        text: 'Disconnect',
                                        colors: [Colors.red, Colors.redAccent],
                                        onPressed:
                                            isConnected ? disconnect : null,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),
                                Row(
                                  children: [
                                    _buildAnimatedStatusIndicator(),
                                    SizedBox(width: 10),
                                    Text(
                                      connectionStatus,
                                      style: TextStyle(
                                        color:
                                            isConnected
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Device Status & Control Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildGradientCard(
                                colors: [
                                  deviceStatus.toLowerCase() == 'online'
                                      ? Colors.green
                                      : Colors.red,
                                  deviceStatus.toLowerCase() == 'online'
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ],
                                height: 120,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        deviceStatus.toLowerCase() == 'online'
                                            ? Icons.cloud_done
                                            : Icons.cloud_off,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        deviceStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (uptime > 0)
                                        Text(
                                          _formatUptime(uptime),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: _buildGradientCard(
                                colors: [
                                  ledState ? Colors.amber : Colors.grey,
                                  ledState ? Colors.yellow : Colors.grey[400]!,
                                ],
                                height: 120,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: isConnected ? toggleLED : null,
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale:
                                                    ledState
                                                        ? _pulseAnimation.value
                                                        : 1.0,
                                                child: Icon(
                                                  Icons.lightbulb,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'LED ${ledState ? "ON" : "OFF"}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Sensor Data Section
                        _buildGradientCard(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.95),
                          ],
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.sensors,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Sensor Data',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSensorCard(
                                        icon: Icons.thermostat,
                                        value:
                                            '${temperature.toStringAsFixed(1)}°C',
                                        label: 'Temperature',
                                        color: Colors.red,
                                        gradientColors: [
                                          Colors.red,
                                          Colors.orange,
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: _buildSensorCard(
                                        icon: Icons.water_drop,
                                        value:
                                            '${humidity.toStringAsFixed(1)}%',
                                        label: 'Humidity',
                                        color: Colors.blue,
                                        gradientColors: [
                                          Colors.blue,
                                          Colors.cyan,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylishTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required List<Color> colors,
    VoidCallback? onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient:
            onPressed != null
                ? LinearGradient(colors: colors)
                : LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(15),
        boxShadow:
            onPressed != null
                ? [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
