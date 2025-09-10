import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);

class RegistrarPacientePage extends StatefulWidget {
  const RegistrarPacientePage({super.key});

  @override
  State<RegistrarPacientePage> createState() => _RegistrarPacientePageState();
}

class _RegistrarPacientePageState extends State<RegistrarPacientePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _registrarPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final pass = _passController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: correo, password: pass);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .set({
            'nombre': nombre,
            'apellido': '',
            'correo': correo,
            'rol': 'Usuario Normal',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Paciente registrado exitosamente')),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar paciente';
      IconData icon = Icons.error;

      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya está registrado';
        icon = Icons.email;
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico no válido';
        icon = Icons.email_outlined;
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña debe tener al menos 6 caracteres';
        icon = Icons.lock_outline;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Ocurrió un error inesperado')),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
          child: const Icon(Icons.person_add_outlined, size: 60, color: gold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nuevo Paciente',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registra los datos del paciente en el sistema',
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
          'Registrar Paciente',
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
                                return 'Ingresa el nombre completo';
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
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingrese el correo electrónico';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Correo electrónico no válido';
                              }
                              if (!value.trim().toLowerCase().endsWith(
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
                            obscureText: _obscureText,
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
                                return 'Debe incluir al menos una letra mayúscula';
                              }
                              if (!regexNumero.hasMatch(value)) {
                                return 'Debe incluir al menos un número';
                              }
                              if (!regexSimbolo.hasMatch(value)) {
                                return 'Debe incluir al menos un símbolo';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              'Contraseña',
                              Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: darkBlue.withOpacity(0.7),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),

                          _buildPasswordStrengthIndicator(),

                          const SizedBox(height: 32),

                          // Botón Registrar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registrarPaciente,
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
                                        Icon(Icons.person_add, size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'Registrar Paciente',
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
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: gold, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Solo correos institucionales @istpet.edu.ec',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: darkBlue.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
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
