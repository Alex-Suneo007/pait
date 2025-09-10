import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final Color azulMarino = const Color(0xFF001f3f);
  final Color dorado = const Color(0xFFD4AF37);

  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _cedulaConfirmController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  List<Map<String, dynamic>> _carrerasList = [];
  String? _selectedCarreraId;
  bool _soyDocente = false;

  bool _cargando = true;
  bool _cedulaYaGuardada = false;
  bool _carreraYaGuardada = false;

  @override
  void initState() {
    super.initState();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('carreras')
        .orderBy('fecha_registro', descending: false)
        .get();

    _carrerasList = snapshot.docs
        .map(
          (doc) => {'id': doc.id, 'nombre': (doc.data())['nombre'] as String},
        )
        .toList();

    await _cargarDatosUsuario(); // Espera carreras antes de cargar perfil
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final data = doc.data();

    if (data != null) {
      final carreraNombre = data['carrera'] ?? '';

      final filtered = _carrerasList
          .where((c) => c['nombre'] == carreraNombre)
          .toList();

      final carreraEncontrada = filtered.isNotEmpty
          ? filtered.first
          : <String, dynamic>{};

      setState(() {
        _nombreController.text = data['nombre'] ?? '';
        _cedulaController.text = data['cedula'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _emailController.text = data['correo'] ?? '';
        _cedulaYaGuardada = (data['cedula'] ?? '').isNotEmpty;
        _soyDocente = data['soyDocente'] ?? false;

        if (carreraEncontrada.isNotEmpty) {
          _selectedCarreraId = carreraEncontrada['id'] as String;
        } else {
          _selectedCarreraId = null;
        }

        _cargando = false;
      });
    } else {
      setState(() {
        _cargando = false;
      });
    }
  }

  // Nueva función para verificar si la cédula ya existe
  Future<bool> _verificarCedulaDuplicada(String cedula) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('cedula', isEqualTo: cedula.trim())
          .get();

      // Si hay documentos y no es el usuario actual, es duplicado
      for (var doc in snapshot.docs) {
        if (doc.id != user.uid) {
          return true; // Encontró duplicado
        }
      }
      return false; // No hay duplicado
    } catch (e) {
      return false; // En caso de error, permite continuar
    }
  }

  Future<void> _guardarPerfil() async {
    if (_formKey.currentState!.validate()) {
      if (!_cedulaYaGuardada) {
        if (_cedulaController.text.trim() !=
            _cedulaConfirmController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('La cédula y la confirmación no coinciden'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        // Verificar si la cédula ya existe
        final cedulaDuplicada = await _verificarCedulaDuplicada(
          _cedulaController.text,
        );
        if (cedulaDuplicada) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Número de cédula no válido, ya hay un usuario con esta cédula',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        String? nombreCarrera;
        if (!_soyDocente && _selectedCarreraId != null) {
          nombreCarrera = _carrerasList.firstWhere(
            (c) => c['id'] == _selectedCarreraId,
          )['nombre'];
        }

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
              'nombre': _nombreController.text.trim(),
              'cedula': _cedulaController.text.trim(),
              'telefono': _telefonoController.text.trim(),
              'correo': _emailController.text.trim(),
              'carrera': nombreCarrera ?? '',
              'soyDocente': _soyDocente,
            });

        setState(() {
          _cedulaYaGuardada = true;
          if (!_soyDocente && nombreCarrera != null) {
            _carreraYaGuardada = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Perfil actualizado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al actualizar perfil: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _cedulaConfirmController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: azulMarino.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(dorado),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(
                      color: azulMarino,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // AppBar personalizado
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: azulMarino,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [azulMarino, azulMarino.withOpacity(0.8)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: dorado.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            top: 30,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: dorado.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Contenido principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Avatar y información básica
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: azulMarino.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [dorado, dorado.withOpacity(0.7)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: azulMarino,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  _nombreController.text.isEmpty
                                      ? 'Completa tu perfil'
                                      : _nombreController.text,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: azulMarino,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _soyDocente ? 'Docente' : 'Estudiante',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: dorado,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Formulario
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: azulMarino.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información Personal',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: azulMarino,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildInput(
                                  'Nombre Completo',
                                  _nombreController,
                                  Icons.person,
                                ),
                                _buildInput(
                                  'Cédula',
                                  _cedulaController,
                                  Icons.credit_card,
                                  enabled: !_cedulaYaGuardada,
                                  keyboardType: TextInputType.number,
                                ),
                                if (!_cedulaYaGuardada)
                                  _buildInput(
                                    'Confirmar Cédula',
                                    _cedulaConfirmController,
                                    Icons.verified_user,
                                    keyboardType: TextInputType.number,
                                  ),
                                _buildInput(
                                  'Teléfono',
                                  _telefonoController,
                                  Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildInput(
                                  'Email',
                                  _emailController,
                                  Icons.email,
                                  enabled: false,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tipo de usuario y carrera
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: azulMarino.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información Académica',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: azulMarino,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Checkbox docente
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: _soyDocente
                                        ? dorado.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _soyDocente
                                          ? dorado
                                          : Colors.grey.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: _soyDocente,
                                          onChanged: (bool? value) {
                                            final nuevoValor = value ?? false;
                                            setState(() {
                                              _soyDocente = nuevoValor;
                                              if (_soyDocente) {
                                                _selectedCarreraId = null;
                                              }
                                            });

                                            if (nuevoValor) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warning,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Advertencia: Si no eres docente y marcas esta opción,\nestarías incurriendo en una falta grave.',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                    seconds: 5,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          activeColor: dorado,
                                          checkColor: azulMarino,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.school,
                                        color: _soyDocente
                                            ? dorado
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Soy docente',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _soyDocente
                                              ? azulMarino
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),
                                _dropdownCarreras(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Botón guardar
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [dorado, dorado.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: dorado.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _guardarPerfil,
                              icon: const Icon(Icons.save, size: 24),
                              label: const Text(
                                'Guardar cambios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: azulMarino,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: azulMarino,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: azulMarino.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: enabled ? dorado : Colors.grey,
                size: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dorado, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: enabled
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: keyboardType ?? TextInputType.text,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? azulMarino : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _dropdownCarreras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carrera',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: azulMarino,
          ),
        ),
        const SizedBox(height: 8),
        _carrerasList.isNotEmpty
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: azulMarino.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCarreraId,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.school,
                      color: (_soyDocente || _carreraYaGuardada)
                          ? Colors.grey
                          : dorado,
                      size: 22,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dorado, width: 2),
                    ),
                    filled: true,
                    fillColor: (_soyDocente || _carreraYaGuardada)
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: _carrerasList.map((carrera) {
                    return DropdownMenuItem<String>(
                      value: carrera['id'],
                      child: Text(
                        carrera['nombre'],
                        style: TextStyle(fontSize: 16, color: azulMarino),
                      ),
                    );
                  }).toList(),
                  onChanged: (_soyDocente || _carreraYaGuardada)
                      ? null
                      : (valor) async {
                          setState(() {
                            _selectedCarreraId = valor;
                          });

                          // Guardar carrera automáticamente
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null && valor != null) {
                            final nombreCarrera = _carrerasList.firstWhere(
                              (c) => c['id'] == valor,
                            )['nombre'];
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(user.uid)
                                .update({'carrera': nombreCarrera});

                            setState(() {
                              _carreraYaGuardada = true;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      'Carrera registrada y no se puede modificar.',
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                  validator: (valor) {
                    if (!_soyDocente && valor == null) {
                      return 'Debe seleccionar una carrera';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: (_soyDocente || _carreraYaGuardada)
                        ? Colors.grey
                        : dorado,
                  ),
                  style: TextStyle(fontSize: 16, color: azulMarino),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'No hay carreras disponibles',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }
}
