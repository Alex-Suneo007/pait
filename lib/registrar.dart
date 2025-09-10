import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  final _claveMedController = TextEditingController();

  String rolSeleccionado = 'Usuario Normal';
  bool mostrarPass = false;
  bool mostrarClave = false;
  String? errorClaveMed;
  static const claveMedicaValida = "1234MED";
  bool _isLoading = false;

  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _passController.dispose();
    _claveMedController.dispose();
    super.dispose();
  }

  void _onRegistrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (rolSeleccionado == 'Personal Médico' &&
        _claveMedController.text.trim() != claveMedicaValida) {
      setState(() {
        errorClaveMed = 'Clave médica incorrecta';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        errorClaveMed = null;
      });

      // Paso 1: Crear usuario en Authentication
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _correoController.text.trim(),
            password: _passController.text.trim(),
          );

      print('✅ Usuario creado en Auth: ${credential.user!.uid}');

      // Paso 2: Guardar datos en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .set({
            'nombre': _nombreController.text.trim(),
            'apellido': '',
            'correo': _correoController.text.trim(),
            'rol': rolSeleccionado,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });

      print('✅ Datos guardados en Firestore');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro exitoso como $rolSeleccionado'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Error de Authentication: ${e.code} - ${e.message}');
      String mensaje = 'Error al crear usuario';
      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico no válido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      print('❌ Error de Firestore: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar datos: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('❌ Error general: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado. Revisa la consola'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: const Text(
            'Crear Cuenta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFF1A2F5A), darkBlue, Color(0xFF061426)],
          ),
        ),
        child: Stack(
          children: [
            // Elementos decorativos de fondo
            Positioned(
              top: -50,
              right: -100,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        blueAccent.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Contenido principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 600 : double.infinity,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 35,
                                offset: const Offset(0, 20),
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: gold.withOpacity(0.1),
                                blurRadius: 40,
                                offset: const Offset(0, -10),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildHeader(),
                                      const SizedBox(height: 32),
                                      _buildNameField(),
                                      const SizedBox(height: 20),
                                      _buildEmailField(),
                                      const SizedBox(height: 20),
                                      _buildPasswordField(),
                                      const SizedBox(height: 20),
                                      _buildRoleDropdown(),
                                      const SizedBox(height: 20),
                                      if (rolSeleccionado == 'Personal Médico')
                                        Column(
                                          children: [
                                            _buildMedicalKeyField(),
                                            const SizedBox(height: 24),
                                          ],
                                        ),
                                      const SizedBox(height: 8),
                                      _buildRegisterButton(),
                                      const SizedBox(height: 24),
                                      _buildLoginButton(),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [gold.withOpacity(0.2), Colors.transparent],
            ),
            border: Border.all(color: gold.withOpacity(0.3), width: 2),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 50,
            color: gold,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Únete a nosotros',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: darkBlue,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Crea tu ',
              style: TextStyle(
                fontSize: 18,
                color: darkBlue.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'cuenta',
              style: TextStyle(
                fontSize: 18,
                color: gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gold, gold.withOpacity(0.3)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: darkBlue.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: blueAccent, size: 20),
          ),
          suffixIcon: suffixIcon != null
              ? Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
          errorText: errorText,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: gold.withOpacity(0.8), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return _buildTextField(
      controller: _nombreController,
      label: 'Nombre completo',
      icon: Icons.person_outline_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu nombre completo';
        }
        final nameRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
        if (!nameRegExp.hasMatch(value.trim())) {
          return 'Solo se permiten letras y espacios';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(
      controller: _correoController,
      label: 'Correo institucional',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa tu correo';
        }
        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'Correo inválido';
        }
        if (!value.toLowerCase().endsWith('@istpet.edu.ec')) {
          return 'El correo debe ser @istpet.edu.ec';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passController,
      label: 'Contraseña segura',
      icon: Icons.lock_outline_rounded,
      obscureText: !mostrarPass,
      suffixIcon: IconButton(
        icon: Icon(
          mostrarPass
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: blueAccent.withOpacity(0.7),
          size: 22,
        ),
        onPressed: () {
          setState(() {
            mostrarPass = !mostrarPass;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa una contraseña';
        }
        if (value.length < 8) {
          return 'Debe tener al menos 8 caracteres';
        }
        if (!RegExp(r'[A-Z]').hasMatch(value)) {
          return 'Incluye al menos una mayúscula';
        }
        if (!RegExp(r'\d').hasMatch(value)) {
          return 'Incluye al menos un número';
        }
        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
          return 'Incluye al menos un símbolo';
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: rolSeleccionado,
        items: const [
          DropdownMenuItem(
            value: 'Usuario Normal',
            child: Text('👤 Usuario Normal'),
          ),
          DropdownMenuItem(
            value: 'Personal Médico',
            child: Text('⚕️ Personal Médico'),
          ),
        ],
        onChanged: (valor) {
          setState(() {
            rolSeleccionado = valor!;
            errorClaveMed = null;
            _claveMedController.clear();
          });
        },
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkBlue,
        ),
        decoration: InputDecoration(
          labelText: 'Selecciona tu rol',
          labelStyle: TextStyle(
            color: darkBlue.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: blueAccent,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: gold.withOpacity(0.8), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalKeyField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _buildTextField(
        controller: _claveMedController,
        label: 'Clave para Personal Médico',
        icon: Icons.vpn_key_rounded,
        obscureText: !mostrarClave,
        errorText: errorClaveMed,
        suffixIcon: IconButton(
          icon: Icon(
            mostrarClave
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: blueAccent.withOpacity(0.7),
            size: 22,
          ),
          onPressed: () {
            setState(() {
              mostrarClave = !mostrarClave;
            });
          },
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ingresa la clave médica';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [gold, gold.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onRegistrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: darkBlue,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: darkBlue,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'Crear mi cuenta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: blueAccent.withOpacity(0.2), width: 1),
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: RichText(
          text: TextSpan(
            text: '¿Ya tienes cuenta? ',
            style: TextStyle(
              color: darkBlue.withOpacity(0.7),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: 'Inicia sesión',
                style: TextStyle(
                  color: blueAccent.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: blueAccent.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
