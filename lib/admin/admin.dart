import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carreras.dart';

// Importa todas las pantallas a las que se va a navegar
import 'citas_del_dia.dart';
import 'ver_materiales.dart';
import 'registrar_atencion.dart';
import 'reporte_atenciones.dart';
import 'perfil_medico.dart';
import 'agregar_materiales.dart';
import 'registrar_paciente.dart';
import 'registrar_personal_medico.dart';
import 'consultar_pacientes.dart';
import 'consultar_personal.dart';
import '../login.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);
const Color background = Color(0xFFF4F6F9);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late List<Animation<double>> _slideAnimations;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimations = List.generate(11, (index) {
      double start = 0.1 + (index * 0.05);
      double end = math.min(0.7 + (index * 0.05), 1.0);

      return Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final nombreAdmin = usuario?.email?.split('@')[0] ?? 'Admin';

    final List<Map<String, dynamic>> opciones = [
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Citas del día',
        'subtitle': 'Supervisar agenda médica',
        'colors': [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        'route': const CitasDelDiaPage(),
      },
      {
        'icon': Icons.inventory_rounded,
        'title': 'Ver materiales',
        'subtitle': 'Consultar inventario médico',
        'colors': [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
        'route': const VerMaterialesScreen(),
      },
      {
        'icon': Icons.add_box_rounded,
        'title': 'Registrar atención',
        'subtitle': 'Documentar consultas médicas',
        'colors': [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
        'route': const RegistrarAtencionPage(),
      },
      {
        'icon': Icons.insert_chart_rounded,
        'title': 'Reporte de atenciones',
        'subtitle': 'Análisis y estadísticas',
        'colors': [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
        'route': const ReporteAtencionesPage(),
      },
      {
        'icon': Icons.person_rounded,
        'title': 'Perfil médico',
        'subtitle': 'Gestionar información personal',
        'colors': [const Color(0xFF607D8B), const Color(0xFF78909C)],
        'route': const PerfilMedicoPage(),
      },
      {
        'icon': Icons.library_add_rounded,
        'title': 'Agregar materiales',
        'subtitle': 'Añadir suministros médicos',
        'colors': [const Color(0xFF00BCD4), const Color(0xFF26C6DA)],
        'route': const AgregarMaterialesPage(),
      },
      {
        'icon': Icons.person_add_rounded,
        'title': 'Registrar pacientes',
        'subtitle': 'Añadir nuevos pacientes',
        'colors': [const Color(0xFF8BC34A), const Color(0xFF9CCC65)],
        'route': const RegistrarPacientePage(),
      },
      {
        'icon': Icons.medical_information_rounded,
        'title': 'Registrar personal médico',
        'subtitle': 'Añadir doctores y personal',
        'colors': [const Color(0xFFE91E63), const Color(0xFFF06292)],
        'route': const RegistrarPersonalMedicoPage(),
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Consultar pacientes',
        'subtitle': 'Base de datos de pacientes',
        'colors': [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
        'route': const ConsultarPacientesPage(),
      },
      {
        'icon': Icons.group_rounded,
        'title': 'Consultar personal médico',
        'subtitle': 'Directorio del personal',
        'colors': [const Color(0xFF795548), const Color(0xFF8D6E63)],
        'route': const ConsultarPersonalPage(),
      },
      {
        'icon': Icons.school_rounded,
        'title': 'Administrar Carreras',
        'subtitle': 'Gestionar programas académicos',
        'colors': [const Color(0xFFFF5722), const Color(0xFFFF7043)],
        'route': const CarrerasPage(),
      },
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, background],
          ),
        ),
        child: Stack(
          children: [
            // Formas decorativas de fondo
            _buildBackgroundShapes(),

            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(nombreAdmin),
                      const SizedBox(height: 40),
                      _buildWelcomeSection(nombreAdmin),
                      const SizedBox(height: 32),
                      _buildServicesGrid(opciones),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // Forma dorada grande (tema administrativo)
        Positioned(
          top: -100,
          right: -80,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value * 20),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.3), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(150),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma azul mediana
        Positioned(
          top: 200,
          left: -60,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingAnimation.value * 15, 0),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [darkBlue.withOpacity(0.2), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma púrpura pequeña
        Positioned(
          bottom: 100,
          right: -40,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -_floatingAnimation.value * 10,
                  _floatingAnimation.value * 10,
                ),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.shade200.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(75),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String nombreAdmin) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro Médico',
                style: TextStyle(
                  fontSize: 16,
                  color: darkBlue.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'ISTPET - Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold, gold.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _mostrarDialogoCerrarSesion,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(String nombreAdmin) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gold, gold.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido ${nombreAdmin.isNotEmpty ? 'Admin' : ''}!',

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panel de control administrativo',
                        style: TextStyle(
                          fontSize: 14,
                          color: darkBlue.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Administra todo el sistema médico: gestiona el personal, pacientes, materiales, carreras académicas y supervisa las operaciones diarias del centro médico.',
              style: TextStyle(
                fontSize: 15,
                color: darkBlue.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(List<Map<String, dynamic>> opciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'Panel Administrativo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBlue,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            // Determinar número de columnas basado en el ancho de la pantalla
            int crossAxisCount = 2;
            double childAspectRatio = 1;

            if (constraints.maxWidth > 1400) {
              crossAxisCount = 5;
              childAspectRatio = 1;
            } else if (constraints.maxWidth > 1200) {
              crossAxisCount = 4;
              childAspectRatio = 1;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
              childAspectRatio = 1;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 2;
              childAspectRatio = 1;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: opciones.length,
              itemBuilder: (context, index) {
                // Verificar que el índice no exceda el rango de animaciones
                return AnimatedBuilder(
                  animation: _slideAnimations[index % _slideAnimations.length],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _slideAnimations[index % _slideAnimations.length].value,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildServiceCard(opciones[index]),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> opcion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => opcion['route']),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 15,
                offset: const Offset(-3, -3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
          ),
          child: Stack(
            children: [
              // Forma decorativa más sutil
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (opcion['colors'][0] as Color).withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono más compacto
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: opcion['colors'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (opcion['colors'][0] as Color).withOpacity(
                              0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        opcion['icon'],
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Título más compacto
                    Text(
                      opcion['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtítulo más pequeño
                    Expanded(
                      child: Text(
                        opcion['subtitle'],
                        style: TextStyle(
                          fontSize: 11,
                          color: darkBlue.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCerrarSesion() async {
    final confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: darkBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión del panel administrativo?',
          style: TextStyle(fontSize: 16, color: darkBlue, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: darkBlue.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmacion ?? false) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
