import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);

class RegistrarPersonalMedicoPage extends StatefulWidget {
  const RegistrarPersonalMedicoPage({super.key});

  @override
  State<RegistrarPersonalMedicoPage> createState() =>
      _RegistrarPersonalMedicoPageState();
}

class _RegistrarPersonalMedicoPageState
    extends State<RegistrarPersonalMedicoPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  final _claveMedController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureClave = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const claveMedicaValida = "1234MED";

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación PRIMERO
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Luego inicializar las animaciones que dependen del controlador
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Iniciar la animación después de que todo esté configurado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    // Disponer el controlador de animación PRIMERO
    _animationController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _passController.dispose();
    _claveMedController.dispose();
    super.dispose();
  }

  void _registrarPersonalMedico() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final pass = _passController.text.trim();
    final clave = _claveMedController.text.trim();

    if (clave != claveMedicaValida) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Clave médica incorrecta', Icons.vpn_key);
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: pass);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .set({'nombre': nombre, 'correo': correo, 'rol': 'Personal Médico'});

      _showSuccessSnackBar('Personal médico registrado exitosamente');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar personal médico';
      IconData icon = Icons.error;

      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya está registrado';
        icon = Icons.email;
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico no válido';
        icon = Icons.email_outlined;
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil (mínimo 6 caracteres)';
        icon = Icons.lock_outline;
      }
      _showErrorSnackBar(mensaje, icon);
    } catch (e) {
      _showErrorSnackBar('Ocurrió un error inesperado', Icons.warning);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passController.text;
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    Color getColor() {
      switch (strength) {
        case 0:
        case 1:
          return Colors.red;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.yellow[700]!;
        case 4:
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    String getText() {
      switch (strength) {
        case 0:
        case 1:
          return 'Débil';
        case 2:
          return 'Regular';
        case 3:
          return 'Buena';
        case 4:
          return 'Fuerte';
        default:
          return '';
      }
    }

    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strength / 4,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                getText(),
                style: TextStyle(
                  color: getColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Debe incluir: mayúscula, número, símbolo y 8+ caracteres',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: darkBlue.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: gold),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [gold.withOpacity(0.2), Colors.transparent],
              radius: 1.5,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 3),
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            size: 60,
            color: gold,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nuevo Personal Médico',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registra al personal médico en el sistema',
          style: TextStyle(
            fontSize: 16,
            color: darkBlue.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar Personal Médico',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue, blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),

                          // Campo Nombre
                          TextFormField(
                            controller: _nombreController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre completo';
                              }
                              final nameRegExp = RegExp(
                                r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                              );
                              if (!nameRegExp.hasMatch(value.trim())) {
                                return 'Solo se permiten letras y espacios';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              'Nombre completo',
                              Icons.person_outline,
                            ),
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 20),

                          // Campo Email
                          TextFormField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese su correo';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Correo inválido';
                              }
                              if (!value.toLowerCase().endsWith(
                                '@istpet.edu.ec',
                              )) {
                                return 'El correo debe ser @istpet.edu.ec';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              'Correo electrónico',
                              Icons.email_outlined,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 20),

                          // Campo Contraseña
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese una contraseña';
                              }
                              if (value.length < 8) {
                                return 'La contraseña debe tener al menos 8 caracteres';
                              }
                              final regexMayuscula = RegExp(r'[A-Z]');
                              final regexNumero = RegExp(r'\d');
                              final regexSimbolo = RegExp(
                                r'[!@#$%^&*(),.?":{}|<>]',
                              );
                              if (!regexMayuscula.hasMatch(value)) {
                                return 'La contraseña debe incluir al menos una letra mayúscula';
                              }
                              if (!regexNumero.hasMatch(value)) {
                                return 'La contraseña debe incluir al menos un número';
                              }
                              if (!regexSimbolo.hasMatch(value)) {
                                return 'La contraseña debe incluir al menos un símbolo';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              'Contraseña',
                              Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: darkBlue.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),

                          _buildPasswordStrengthIndicator(),

                          const SizedBox(height: 20),

                          // Campo Clave Médica
                          TextFormField(
                            controller: _claveMedController,
                            obscureText: _obscureClave,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingrese la clave médica'
                                : null,
                            decoration: _buildInputDecoration(
                              'Clave para Personal Médico',
                              Icons.vpn_key_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureClave
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: darkBlue.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureClave = !_obscureClave;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 32),

                          // Botón Registrar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _registrarPersonalMedico,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: darkBlue,
                                elevation: 8,
                                shadowColor: gold.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  darkBlue,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Registrando...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.medical_services, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'Registrar Personal Médico',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Botón Volver
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: blueAccent,
                            ),
                            label: const Text(
                              'Volver al menú anterior',
                              style: TextStyle(
                                color: blueAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Info container para clave médica
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: gold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: gold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: gold,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Información importante:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: darkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Solo correos institucionales @istpet.edu.ec\n• Se requiere clave especial para personal médico',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkBlue.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
