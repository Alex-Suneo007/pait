import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);
const Color lightBlue = Color(0xFF0F2C57);

class CitasDelDiaPage extends StatefulWidget {
  const CitasDelDiaPage({super.key});

  @override
  State<CitasDelDiaPage> createState() => _CitasDelDiaPageState();
}

class _CitasDelDiaPageState extends State<CitasDelDiaPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

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
    final today = DateTime.now().toIso8601String().split('T').first;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Citas del Día',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: gold, size: 28),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightBlue, darkBlue, const Color(0xFF061426)],
          ),
        ),
        child: Stack(
          children: [
            // Formas decorativas de fondo
            _buildBackgroundShapes(),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeaderInfo(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('atenciones')
                          .where('fecha', isEqualTo: today)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingState();
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState('No hay citas para hoy.');
                        }

                        final citas = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['estado'] == 'Atendido' &&
                              data['timestamp_estado'] != null) {
                            final ts = (data['timestamp_estado'] as Timestamp)
                                .toDate();
                            final diff = DateTime.now().difference(ts);
                            return diff < const Duration(minutes: 30);
                          }
                          return true;
                        }).toList();

                        if (citas.isEmpty) {
                          return _buildEmptyState(
                            'No hay citas activas para hoy.',
                          );
                        }

                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: citas.length,
                            itemBuilder: (_, index) {
                              return AnimatedBuilder(
                                animation: _fadeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      (1 - _fadeAnimation.value) * 30,
                                    ),
                                    child: Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: CitaCard(
                                        citaDoc: citas[index],
                                        index: index,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
        // Forma médica principal
        Positioned(
          top: -80,
          right: -60,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value * 25),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.1), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(125),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma secundaria
        Positioned(
          bottom: 100,
          left: -40,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingAnimation.value * 20, 0),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.shade300.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(90),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma pequeña flotante
        Positioned(
          top: 200,
          left: 60,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -_floatingAnimation.value * 15,
                  _floatingAnimation.value * 12,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    final now = DateTime.now();
    final dayName = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ][now.weekday - 1];
    final monthName = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ][now.month - 1];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gold, gold.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dayName, ${now.day} de $monthName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agenda médica del día',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [gold, gold.withOpacity(0.7)]),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cargando citas...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gold.withOpacity(0.3), gold.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Las citas aparecerán aquí cuando estén disponibles',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CitaCard extends StatefulWidget {
  final DocumentSnapshot citaDoc;
  final int index;

  const CitaCard({super.key, required this.citaDoc, this.index = 0});

  @override
  State<CitaCard> createState() => _CitaCardState();
}

class _CitaCardState extends State<CitaCard>
    with SingleTickerProviderStateMixin {
  late String estado;
  DateTime? timestampEstado;
  AnimationController? _cardAnimationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final data = widget.citaDoc.data() as Map<String, dynamic>;
    estado = data['estado'] ?? 'Pendiente';
    timestampEstado = data['timestamp_estado'] != null
        ? (data['timestamp_estado'] as Timestamp).toDate()
        : null;

    // Inicializar el controlador de animación de manera segura
    try {
      _cardAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _cardAnimationController!,
          curve: Curves.easeInOut,
        ),
      );
    } catch (e) {
      // Si hay algún error en la inicialización, establecer valores por defecto
      _cardAnimationController = null;
      _scaleAnimation = null;
    }
  }

  @override
  void dispose() {
    _cardAnimationController?.dispose();
    super.dispose();
  }

  Color getColor() {
    switch (estado) {
      case 'Confirmado':
        return const Color(0xFF2ECC71);
      case 'Cancelado':
        return const Color(0xFFE74C3C);
      case 'Atendido':
        return const Color(0xFF3498DB);
      default:
        return Colors.grey;
    }
  }

  IconData getIcon() {
    switch (estado) {
      case 'Confirmado':
        return Icons.check_circle_rounded;
      case 'Cancelado':
        return Icons.cancel_rounded;
      case 'Atendido':
        return Icons.medical_services_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Future<void> cambiarEstado(String nuevo) async {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? 'ADMINISTRADOR';

    setState(() {
      estado = nuevo;
      timestampEstado = DateTime.now();
    });

    try {
      await FirebaseFirestore.instance
          .collection('atenciones')
          .doc(widget.citaDoc.id)
          .update({
            'estado': nuevo,
            'modificado_por': nombre,
            'timestamp_estado': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Error al actualizar estado: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void mostrarDetalles(BuildContext context) {
    final data = widget.citaDoc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, gold.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Detalles de la Cita',
              style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Paciente', data['paciente'] ?? '-'),
              _buildDetailRow('Fecha', data['fecha'] ?? '-'),
              _buildDetailRow('Hora', data['hora'] ?? '-'),
              _buildDetailRow('Motivo', data['motivo'] ?? '-'),
              _buildDetailRow('Triaje', data['triaje'] ?? '-'),
              _buildDetailRow('Diagnóstico', data['diagnostico'] ?? '-'),
              _buildDetailRow('Tratamiento', data['tratamiento'] ?? '-'),
              _buildDetailRow('Observaciones', data['observaciones'] ?? '-'),
              _buildDetailRow('Estado', estado),
              _buildDetailRow(
                'Modificado por',
                data['modificado_por'] ?? 'No registrado',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: gold.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkBlue.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: darkBlue)),
          ),
        ],
      ),
    );
  }

  void mostrarDialogoMateriales(BuildContext context) async {
    final materialesSnapshot = await FirebaseFirestore.instance
        .collection('materiales')
        .get();

    final materiales = materialesSnapshot.docs;
    final Map<String, int> materialesSeleccionados = {};

    final TextEditingController diagnosticoController = TextEditingController();
    final TextEditingController tratamientoController = TextEditingController();
    final TextEditingController observacionesController =
        TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gold, gold.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Materiales Utilizados',
                    style: TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: materiales.map((materialDoc) {
                            final data = materialDoc.data();
                            final nombre = data['nombre'];
                            final stock = data['stock'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darkBlue,
                                          ),
                                        ),
                                        Text(
                                          'Stock disponible: $stock',
                                          style: TextStyle(
                                            color: darkBlue.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red.shade400,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if ((materialesSeleccionados[nombre] ??
                                                    0) >
                                                0) {
                                              materialesSeleccionados[nombre] =
                                                  (materialesSeleccionados[nombre] ??
                                                      0) -
                                                  1;
                                            }
                                          });
                                        },
                                      ),
                                      Container(
                                        width: 40,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: gold.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${materialesSeleccionados[nombre] ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: darkBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green.shade400,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if ((materialesSeleccionados[nombre] ??
                                                    0) <
                                                stock) {
                                              materialesSeleccionados[nombre] =
                                                  (materialesSeleccionados[nombre] ??
                                                      0) +
                                                  1;
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Diagnóstico', diagnosticoController),
                      const SizedBox(height: 16),
                      _buildTextField('Tratamiento', tratamientoController),
                      const SizedBox(height: 16),
                      _buildTextField('Observaciones', observacionesController),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final materialesUsados = materialesSeleccionados.entries
                          .where((e) => e.value > 0)
                          .toList();

                      if (materialesUsados.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Selecciona al menos un material.'),
                              ],
                            ),
                            backgroundColor: Colors.orange.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }

                      // Descontar stock de cada material
                      for (final entry in materialesUsados) {
                        final materialDoc = materiales.firstWhere(
                          (doc) => doc['nombre'] == entry.key,
                        );
                        final nuevoStock =
                            (materialDoc['stock'] ?? 0) - entry.value;

                        await FirebaseFirestore.instance
                            .collection('materiales')
                            .doc(materialDoc.id)
                            .update({'stock': nuevoStock});
                      }

                      // Actualizar estado de la cita
                      await cambiarEstado('Atendido');

                      // Guardar materiales utilizados y datos clínicos en la cita
                      await FirebaseFirestore.instance
                          .collection('atenciones')
                          .doc(widget.citaDoc.id)
                          .update({
                            'materiales_utilizados': materialesSeleccionados,
                            'diagnostico': diagnosticoController.text,
                            'tratamiento': tratamientoController.text,
                            'observaciones': observacionesController.text,
                          });

                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Error: $e')),
                              ],
                            ),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Guardar y Atender',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: gold, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 15,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar del paciente
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gold, gold.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del paciente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.citaDoc['paciente'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: darkBlue.withOpacity(0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.citaDoc['hora'] ?? 'No definida',
                            style: TextStyle(
                              color: darkBlue.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getColor(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: getColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getIcon(), color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        estado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_rounded,
                        color: darkBlue.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Motivo de consulta:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.citaDoc['motivo'] ?? 'No registrado',
                    style: TextStyle(
                      color: darkBlue.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            if (estado != 'Atendido') ...[
              const SizedBox(height: 20),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      'Confirmar',
                      Icons.check_circle_rounded,
                      Colors.green,
                      () => cambiarEstado('Confirmado'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      'Cancelar',
                      Icons.cancel_rounded,
                      Colors.red,
                      () => cambiarEstado('Cancelado'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _actionButton(
                  'Marcar como Atendido',
                  Icons.medical_services_rounded,
                  gold,
                  () => mostrarDialogoMateriales(context),
                  isPrimary: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Si tenemos animación disponible, aplicar el efecto de escala
    if (_scaleAnimation != null && _cardAnimationController != null) {
      return GestureDetector(
        onTapDown: (_) => _cardAnimationController!.forward(),
        onTapUp: (_) => _cardAnimationController!.reverse(),
        onTapCancel: () => _cardAnimationController!.reverse(),
        onTap: () => mostrarDetalles(context),
        child: ScaleTransition(scale: _scaleAnimation!, child: cardContent),
      );
    }

    // Si no hay animación disponible, devolver el contenido sin efecto de escala
    return GestureDetector(
      onTap: () => mostrarDetalles(context),
      child: cardContent,
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : color.withOpacity(0.1),
        foregroundColor: isPrimary ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        elevation: isPrimary ? 4 : 0,
        shadowColor: isPrimary ? color.withOpacity(0.3) : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
