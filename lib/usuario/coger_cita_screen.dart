import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CogerCitaScreen extends StatefulWidget {
  const CogerCitaScreen({super.key});

  @override
  State<CogerCitaScreen> createState() => _CogerCitaScreenState();
}

class _CogerCitaScreenState extends State<CogerCitaScreen>
    with TickerProviderStateMixin {
  final Color darkBlue = const Color.fromRGBO(11, 29, 58, 1);
  final Color gold = const Color(0xFFC9B037);
  final Color background = const Color(0xFFF4F6F9);

  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  final _formKey = GlobalKey<FormState>();

  String? _servicio;
  String? _hora;
  DateTime? _fecha;
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();

  List<String> _horasDisponibles = [];
  final List<String> _horasPosibles = List.generate(9, (index) {
    int hour = 8 + index;
    return hour.toString().padLeft(2, '0') + ':00';
  });

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  void _seleccionarFecha() async {
    DateTime now = DateTime.now();
    DateTime initial = now;

    if (initial.weekday == DateTime.saturday) {
      initial = initial.add(const Duration(days: 2));
    } else if (initial.weekday == DateTime.sunday) {
      initial = initial.add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      selectableDayPredicate: (day) =>
          day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: gold,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fecha = picked;
        _fechaController.text = picked.toIso8601String().split('T').first;
        _hora = null;
        _horaController.text = '';
        _cargarHorasDisponibles();
      });
    }
  }

  Future<void> _cargarHorasDisponibles() async {
    if (_fecha == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fechaStr = _fechaController.text;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('atenciones')
          .where('fecha', isEqualTo: fechaStr)
          .get();

      final horasOcupadas = querySnapshot.docs
          .map((doc) => (doc.data()['hora'] as String?) ?? '')
          .toSet();

      DateTime now = DateTime.now();
      bool esHoy =
          _fecha!.year == now.year &&
          _fecha!.month == now.month &&
          _fecha!.day == now.day;

      _horasDisponibles = _horasPosibles.where((hora) {
        if (horasOcupadas.contains(hora)) return false;

        if (esHoy) {
          int horaInt = int.parse(hora.split(':')[0]);
          if (horaInt <= now.hour) return false;
        }

        return true;
      }).toList();

      if (_horasDisponibles.isEmpty) {
        _mostrarSnackBar(
          'No hay horarios disponibles para esta fecha',
          Icons.warning_rounded,
          Color.fromRGBO(11, 29, 58, 1),
        );
      }
    } catch (e) {
      _mostrarSnackBar(
        'Error al cargar horarios disponibles',
        Icons.error_rounded,
        Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _seleccionarHora() async {
    if (_fecha == null) {
      _mostrarSnackBar(
        'Primero seleccione una fecha',
        Icons.calendar_today_rounded,
        Colors.orange,
      );
      return;
    }

    if (_horasDisponibles.isEmpty) {
      _mostrarSnackBar(
        'No hay horarios disponibles para esta fecha',
        Icons.access_time_rounded,
        Colors.orange,
      );
      return;
    }

    final String? horaElegida = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gold, gold.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Seleccionar Horario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _horasDisponibles.map((hora) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, hora),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: gold.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.blue.shade50.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  hora,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: darkBlue.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (horaElegida != null) {
      setState(() {
        _hora = horaElegida;
        _horaController.text = _hora!;
      });
    }
  }

  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate() ||
        _fecha == null ||
        _hora == null ||
        _servicio == null) {
      _mostrarSnackBar(
        'Por favor complete todos los campos',
        Icons.warning_rounded,
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarSnackBar(
        'Usuario no autenticado',
        Icons.error_rounded,
        Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final nombreCompleto = '${doc['nombre']} ${doc['apellido']}';

      final fechaHora = DateTime.parse('${_fechaController.text}T$_hora:00');

      await FirebaseFirestore.instance.collection('atenciones').add({
        'paciente_id': user.uid,
        'paciente': nombreCompleto,
        'fecha': _fechaController.text,
        'hora': _hora,
        'motivo': _servicio,
        'estado': 'Pendiente',
        'timestamp': Timestamp.fromDate(fechaHora),
      });

      _mostrarSnackBar(
        'Cita guardada correctamente',
        Icons.check_circle_rounded,
        Colors.green,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    } catch (e) {
      _mostrarSnackBar(
        'Error al guardar cita: $e',
        Icons.error_rounded,
        Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarSnackBar(String mensaje, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value * 15),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.1), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -80,
          left: -50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingAnimation.value * 10, 0),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.shade200.withOpacity(0.15),
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

  @override
  Widget build(BuildContext context) {
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
            _buildBackgroundShapes(),
            SafeArea(
              child: Column(
                children: [
                  // Header personalizado
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade100],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: darkBlue,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agendar Cita',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                                Text(
                                  'Reserve su consulta médica',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: darkBlue.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [gold, gold.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Formulario
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
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
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: ListView(
                                  children: [
                                    _buildSectionTitle(
                                      'Tipo de Servicio',
                                      Icons.medical_services_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDropdownField(),
                                    const SizedBox(height: 24),

                                    _buildSectionTitle(
                                      'Fecha de la Cita',
                                      Icons.calendar_today_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDateField(),
                                    const SizedBox(height: 24),

                                    _buildSectionTitle(
                                      'Horario Disponible',
                                      Icons.access_time_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTimeField(),
                                    const SizedBox(height: 32),

                                    _buildConfirmButton(),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gold.withOpacity(0.2), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: gold, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        value: _servicio,
        hint: Text(
          'Seleccione el tipo de consulta',
          style: TextStyle(color: darkBlue.withOpacity(0.5)),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Atención General',
            child: Text('Atención General'),
          ),
          DropdownMenuItem(
            value: 'Suministro de Medicamentos',
            child: Text('Suministro de Medicamentos'),
          ),
        ],
        onChanged: (value) => setState(() => _servicio = value),
        validator: (value) => value == null ? 'Seleccione un servicio' : null,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: gold),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        readOnly: true,
        controller: _fechaController,
        onTap: _seleccionarFecha,
        decoration: InputDecoration(
          hintText: 'Toque para seleccionar fecha',
          hintStyle: TextStyle(color: darkBlue.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: Icon(Icons.calendar_today_rounded, color: gold),
        ),
        validator: (_) => _fecha == null ? 'Seleccione una fecha' : null,
      ),
    );
  }

  Widget _buildTimeField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        readOnly: true,
        controller: _horaController,
        onTap: _seleccionarHora,
        decoration: InputDecoration(
          hintText: 'Toque para seleccionar horario',
          hintStyle: TextStyle(color: darkBlue.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: _isLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(gold),
                    ),
                  ),
                )
              : Icon(Icons.access_time_rounded, color: gold),
        ),
        validator: (_) => _hora == null ? 'Seleccione una hora' : null,
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _guardarCita,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Guardando...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confirmar Cita',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
