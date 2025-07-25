import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class Visitor {
  final int id;
  final String nombre;
  final String motivo;
  final DateTime hora;
  final String? fotoUrl;

  Visitor({
    required this.id,
    required this.nombre,
    required this.motivo,
    required this.hora,
    this.fotoUrl,
  });

  factory Visitor.fromMap(Map<String, dynamic> map) {
    return Visitor(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      motivo: map['motivo'] as String,
      hora: DateTime.parse(map['hora'] as String),
      fotoUrl: map['foto_url'] as String?,
    );
  }
}

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({Key? key}) : super(key: key);

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> {
  List<Visitor> _visitors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
  }

  Future<void> _fetchVisitors() async {
    setState(() => _loading = true);
    final response = await Supabase.instance.client
        .from('visitantes')
        .select()
        .order('hora', ascending: false);
    setState(() {
      _visitors = (response as List)
          .map((v) => Visitor.fromMap(v as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
  }

  void _goToAddVisitor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVisitorPage()),
    );
    if (result == true) {
      _fetchVisitors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2196F3); // Azul claro
    final Color accentColor = const Color(0xFFBBDEFB); // Azul más claro
    final Color cardColor = Colors.white;
    final Color buttonColor = const Color(0xFF1976D2); // Azul más fuerte
    return Scaffold(
      backgroundColor: accentColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Visitantes registrados',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty
          ? const Center(child: Text('No hay visitantes registrados'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visitors.length,
              itemBuilder: (context, i) {
                final v = _visitors[i];
                return Card(
                  color: cardColor,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    leading: v.fotoUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(v.fotoUrl!),
                            radius: 28,
                          )
                        : CircleAvatar(
                            backgroundColor: accentColor,
                            radius: 28,
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF1976D2),
                              size: 32,
                            ),
                          ),
                    title: Text(
                      v.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                v.motivo,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(v.hora),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        onPressed: _goToAddVisitor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Agregar nuevo visitante',
      ),
    );
  }
}

class AddVisitorPage extends StatefulWidget {
  const AddVisitorPage({Key? key}) : super(key: key);

  @override
  State<AddVisitorPage> createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime _hora = DateTime.now();
  File? _foto;
  XFile? _pickedFileWeb;
  PlatformFile? _pickedFileDesktop;
  bool _loading = false;
  String? _error;

  Future<void> _pickImageFromCamera() async {
    // Solicitar permisos en Android
    if (!kIsWeb && Platform.isAndroid) {
      // El paquete image_picker maneja permisos automáticamente, pero puedes usar permission_handler si necesitas más control
      // Si quieres forzar el permiso, descomenta:
      // await Permission.camera.request();
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _foto = File(picked.path);
        _pickedFileWeb = null;
        _pickedFileDesktop = null;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _foto = File(picked.path);
        _pickedFileWeb = null;
        _pickedFileDesktop = null;
      });
    }
  }

  Future<String?> _uploadPhoto(dynamic file) async {
    final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    late Uint8List bytes;
    if (kIsWeb && _pickedFileDesktop != null) {
      bytes = _pickedFileDesktop!.bytes!;
    } else if (file is File) {
      bytes = await file.readAsBytes();
    } else {
      return null;
    }
    final result = await Supabase.instance.client.storage
        .from('uploads')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    if (result.isNotEmpty) {
      final url = Supabase.instance.client.storage
          .from('uploads')
          .getPublicUrl(fileName);
      return url;
    }
    return null;
  }

  Future<void> _saveVisitor() async {
    if (!_formKey.currentState!.validate() ||
        (_foto == null && _pickedFileDesktop == null)) {
      setState(() {
        if (_foto == null && _pickedFileDesktop == null) {
          _error = 'Debe subir una foto del visitante';
        } else {
          _error = 'Por favor corrige los errores del formulario.';
        }
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    String? fotoUrl;
    if (_foto != null || (kIsWeb && _pickedFileDesktop != null)) {
      fotoUrl = await _uploadPhoto(kIsWeb ? _pickedFileDesktop : _foto);
    }
    final response = await Supabase.instance.client.from('visitantes').insert({
      'nombre': _nombreController.text.trim(),
      'motivo': _motivoController.text.trim(),
      'hora': _hora.toIso8601String(),
      'foto_url': fotoUrl,
    });
    if (response is Map &&
        response.containsKey('error') &&
        response['error'] != null) {
      setState(() {
        _error = response['error']['message'] ?? 'Error al guardar visitante';
        _loading = false;
      });
    } else {
      Navigator.pop(context, true);
    }
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Debe ingresar al menos nombre y apellido';
    }
    final hasNumber = RegExp(r'[0-9]');
    for (final part in parts) {
      if (part.length < 2 || part.length == 3) {
        return 'Cada nombre debe tener más de 1 letra y no puede tener menos de 3 letras';
      }
      if (hasNumber.hasMatch(part)) {
        return 'El nombre no puede contener números';
      }
    }
    return null;
  }

  String? _validateMotivo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El motivo es obligatorio';
    }
    final onlyNumbers = RegExp(r'^\d+ *$');
    if (onlyNumbers.hasMatch(value.trim())) {
      return 'El motivo no puede ser solo números';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar visitante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del visitante',
                ),
                validator: _validateNombre,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la visita',
                ),
                validator: _validateMotivo,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Hora: ${DateFormat('yyyy-MM-dd HH:mm').format(_hora)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _hora,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_hora),
                      );
                      if (time != null) {
                        setState(() {
                          _hora = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _foto == null && _pickedFileDesktop == null
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Tomar foto'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Subir archivo'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        if (kIsWeb &&
                            _pickedFileDesktop != null &&
                            _pickedFileDesktop!.bytes != null)
                          Image.memory(_pickedFileDesktop!.bytes!, height: 120)
                        else if (_foto != null)
                          Image.file(_foto!, height: 120),
                        TextButton(
                          onPressed: () => setState(() {
                            _foto = null;
                            _pickedFileDesktop = null;
                          }),
                          child: const Text('Quitar foto'),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveVisitor,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
