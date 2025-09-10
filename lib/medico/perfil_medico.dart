import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color gold = Color(0xFFC9B037);
const Color lightGray = Color(0xFFF4F6F9);
const Color accentBlue = Color(0xFF1E3A8A);
const Color softGold = Color(0xFFF5E6A8);

class PerfilMedicoPage extends StatefulWidget {
  const PerfilMedicoPage({super.key});

  @override
  State<PerfilMedicoPage> createState() => _PerfilMedicoPageState();
}

class _PerfilMedicoPageState extends State<PerfilMedicoPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _cedulaYaGuardada = false;
  bool _isSaving = false;

  late TextEditingController _nombreController;
  late TextEditingController _cedulaController;
  late TextEditingController _cedulaConfirmController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _cedulaController = TextEditingController();
    _cedulaConfirmController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _cargarDatosMedico();
  }

  Future<void> _cargarDatosMedico() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      String nombreDesdeRegistro = '';
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        nombreDesdeRegistro = userData['nombre'] ?? '';
      }

      DocumentSnapshot medicoDoc = await FirebaseFirestore.instance
          .collection('medicos')
          .doc(user.uid)
          .get();

      setState(() {
        _nombreController.text = nombreDesdeRegistro;

        if (medicoDoc.exists) {
          final medicoData = medicoDoc.data() as Map<String, dynamic>;
          _cedulaController.text = medicoData['cedula'] ?? '';
          _telefonoController.text = medicoData['telefono'] ?? '';
        }

        _emailController.text = user.email ?? '';
        _cedulaYaGuardada = (_cedulaController.text.trim().isNotEmpty);
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar datos: $e');
    }
  }

  // Nueva función para verificar si la cédula ya existe
  Future<bool> _verificarCedulaDuplicada(String cedula) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('medicos')
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

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!_cedulaYaGuardada &&
        _cedulaController.text.trim() != _cedulaConfirmController.text.trim()) {
      _showErrorSnackBar('La cédula y su confirmación no coinciden');
      return;
    }

    // Verificar si la cédula ya existe (solo si no está guardada previamente)
    if (!_cedulaYaGuardada) {
      final cedulaDuplicada = await _verificarCedulaDuplicada(
        _cedulaController.text,
      );
      if (cedulaDuplicada) {
        _showErrorSnackBar(
          'Número de cédula no válido, ya hay un usuario con esta cédula',
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('medicos').doc(user.uid).set({
        'nombre': _nombreController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        _cedulaYaGuardada = true;
      });

      _showSuccessSnackBar('Datos actualizados correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al guardar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    _cedulaConfirmController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    bool isEnabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? gold.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isEnabled ? gold : Colors.grey, size: 20),
      ),
      labelStyle: TextStyle(
        color: isEnabled ? darkBlue : Colors.grey,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isEnabled ? Colors.white : Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: gold.withOpacity(0.3), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: gold, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBlue, accentBlue],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold, softGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital, color: darkBlue, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perfil Médico',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualiza tu información profesional',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                decoration: _inputDecoration(label, icon, isEnabled: enabled),
                keyboardType: keyboardType,
                enabled: enabled,
                validator: validator,
                textCapitalization: textCapitalization,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [darkBlue, accentBlue],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const CircularProgressIndicator(
                    color: gold,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cargando perfil...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBlue),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: darkBlue.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: darkBlue.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 8),

                                  _buildAnimatedTextField(
                                    controller: _nombreController,
                                    label: 'Nombre Completo',
                                    icon: Icons.person_outline,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    delay: 0,
                                  ),

                                  _buildAnimatedTextField(
                                    controller: _cedulaController,
                                    label: 'Cédula',
                                    icon: Icons.badge_outlined,
                                    keyboardType: TextInputType.number,
                                    enabled: !_cedulaYaGuardada,
                                    delay: 100,
                                    validator: (value) {
                                      if (!_cedulaYaGuardada &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Por favor ingrese Cédula';
                                      }
                                      return null;
                                    },
                                  ),

                                  if (!_cedulaYaGuardada)
                                    _buildAnimatedTextField(
                                      controller: _cedulaConfirmController,
                                      label: 'Confirmar Cédula',
                                      icon: Icons.verified_outlined,
                                      keyboardType: TextInputType.number,
                                      delay: 200,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Por favor confirme la Cédula';
                                        }
                                        return null;
                                      },
                                    ),

                                  _buildAnimatedTextField(
                                    controller: _emailController,
                                    label: 'Correo Electrónico',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: false,
                                    delay: 300,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Por favor ingrese correo electrónico';
                                      }
                                      if (!RegExp(
                                        r'\S+@\S+\.\S+',
                                      ).hasMatch(value)) {
                                        return 'Ingrese un correo válido';
                                      }
                                      return null;
                                    },
                                  ),

                                  _buildAnimatedTextField(
                                    controller: _telefonoController,
                                    label: 'Teléfono',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    delay: 400,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Por favor ingrese teléfono';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 32),

                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 600),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [gold, softGold],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gold.withOpacity(0.4),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isSaving
                                                ? null
                                                : _guardarDatos,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 18,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: _isSaving
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: darkBlue,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons.save_outlined,
                                                        color: darkBlue,
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Guardar Cambios',
                                                        style: TextStyle(
                                                          color: darkBlue,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: gold.withOpacity(0.8),
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_back_ios_new,
                                          color: gold,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Volver al menú',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: gold,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
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
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
