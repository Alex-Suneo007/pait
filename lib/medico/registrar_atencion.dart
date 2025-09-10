import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pait_4to/medico/medico.dart';

const List<String> opcionesTriaje = ['Verde', 'Amarillo', 'Rojo'];

class RegistrarAtencionPage extends StatefulWidget {
  const RegistrarAtencionPage({super.key});

  @override
  State<RegistrarAtencionPage> createState() => _RegistrarAtencionPageState();
}

class _RegistrarAtencionPageState extends State<RegistrarAtencionPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  String? _triaje;
  List<Map<String, String>> _pacientesList = [];
  String? _selectedPacienteId;
  String? _selectedPacienteNombre;

  List<String> _horasOcupadas = [];
  bool _isLoading = false;
  bool _isSaving = false;

  late AnimationController _animationController;
  late AnimationController _formAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargarPacientes();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _formAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'Usuario Normal')
          .get();

      final pacientes = snapshot.docs
          .map((doc) => {'id': doc.id, 'nombre': '${doc['nombre']}'})
          .toList();

      if (pacientes.isNotEmpty) {
        setState(() {
          _pacientesList = pacientes;
          _selectedPacienteId = pacientes.first['id'];
          _selectedPacienteNombre = pacientes.first['nombre'];
        });

        _formAnimationController.forward();
      }
    } catch (e) {
      _mostrarSnack('Error al cargar pacientes: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarHorasOcupadas(String fecha) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('atenciones')
          .where('fecha', isEqualTo: fecha)
          .get();

      final ocupadas = snapshot.docs
          .map((doc) => doc['hora'] as String)
          .toList();

      setState(() {
        _horasOcupadas = ocupadas;
        _horaController.clear();
      });
    } catch (e) {
      _mostrarSnack('Error al cargar horas disponibles', Colors.orange);
    }
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
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: (day) =>
          day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final fechaSeleccionada = picked.toIso8601String().split('T').first;
      _fechaController.text = fechaSeleccionada;
      _cargarHorasOcupadas(fechaSeleccionada);
      _mostrarSnack('Fecha seleccionada correctamente', Colors.green);
    }
  }

  void _seleccionarHora() async {
    if (_fechaController.text.isEmpty) {
      _mostrarSnack('Primero seleccione una fecha', Colors.orange);
      return;
    }

    final fechaSeleccionada = DateTime.parse(_fechaController.text);
    final ahora = DateTime.now();

    // Generar horas disponibles (08:00 a 17:00)
    List<String> horasDisponibles = List.generate(9, (i) {
      return '${(i + 8).toString().padLeft(2, '0')}:00';
    });

    // Si la fecha es hoy, filtrar horas pasadas
    if (fechaSeleccionada.year == ahora.year &&
        fechaSeleccionada.month == ahora.month &&
        fechaSeleccionada.day == ahora.day) {
      horasDisponibles = horasDisponibles.where((hora) {
        final horaInt = int.parse(hora.split(':')[0]);
        return horaInt > ahora.hour;
      }).toList();
    }

    // Quitar las horas ya ocupadas
    horasDisponibles = horasDisponibles
        .where((hora) => !_horasOcupadas.contains(hora))
        .toList();

    if (horasDisponibles.isEmpty) {
      _mostrarSnack('No hay horas disponibles para esta fecha', Colors.red);
      return;
    }

    final horaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Hora',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF051932),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: horasDisponibles.length,
              itemBuilder: (context, index) {
                final hora = horasDisponibles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, hora),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF051932),
                      side: const BorderSide(
                        color: Color(0xFFD4AF37),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          hora,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (horaSeleccionada != null) {
      _horaController.text = horaSeleccionada;
      _mostrarSnack('Hora seleccionada: $horaSeleccionada', Colors.green);
    }
  }

  void _guardarAtencion() async {
    if (_formKey.currentState!.validate()) {
      if (_horasOcupadas.contains(_horaController.text)) {
        _mostrarSnack('La hora seleccionada ya está ocupada', Colors.red);
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        await FirebaseFirestore.instance.collection('atenciones').add({
          'paciente_id': _selectedPacienteId,
          'paciente': _selectedPacienteNombre,
          'fecha': _fechaController.text,
          'hora': _horaController.text,
          'motivo': _motivoController.text,
          'triaje': _triaje,
          'timestamp': FieldValue.serverTimestamp(),
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Éxito',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF051932),
                  ),
                ),
              ],
            ),
            content: const Text(
              'La atención médica ha sido registrada correctamente en el sistema.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MedicoPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        _mostrarSnack('Error al guardar atención: $e', Colors.red);
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _mostrarSnack(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getTriajeColor(String? triaje) {
    switch (triaje) {
      case 'Verde':
        return Colors.green;
      case 'Amarillo':
        return Colors.amber[700]!;
      case 'Rojo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2C57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F8F8)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF051932),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Registrar Atención',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF051932),
                          ),
                        ),
                        Text(
                          'Nueva cita médica',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Color(0xFFD4AF37),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: _isLoading
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFD4AF37),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Cargando información...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FadeTransition(
                                opacity: _formAnimation,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header del formulario
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFD4AF37,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.assignment_add,
                                              color: Color(0xFFD4AF37),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Datos de la Atención',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF051932),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 32),

                                      // Campos del formulario
                                      PacienteDropdown(
                                        pacientes: _pacientesList,
                                        selectedId: _selectedPacienteId,
                                        onChanged: (id) {
                                          setState(() {
                                            _selectedPacienteId = id;
                                            _selectedPacienteNombre =
                                                _pacientesList.firstWhere(
                                                  (pac) => pac['id'] == id,
                                                )['nombre'];
                                          });
                                        },
                                      ),

                                      CustomInput(
                                        label: 'Fecha de Atención',
                                        controller: _fechaController,
                                        readOnly: true,
                                        onTap: _seleccionarFecha,
                                        icon: Icons.calendar_today,
                                        hint: 'Seleccione una fecha',
                                      ),

                                      CustomInput(
                                        label: 'Hora de Atención',
                                        controller: _horaController,
                                        readOnly: true,
                                        onTap: _seleccionarHora,
                                        icon: Icons.access_time,
                                        hint: 'Seleccione una hora',
                                      ),

                                      CustomInput(
                                        label: 'Motivo de Consulta',
                                        controller: _motivoController,
                                        icon: Icons.description,
                                        hint:
                                            'Describa el motivo de la consulta',
                                        maxLines: 3,
                                      ),

                                      TriajeDropdown(
                                        value: _triaje,
                                        onChanged: (value) =>
                                            setState(() => _triaje = value),
                                      ),

                                      const SizedBox(height: 32),

                                      // Botones de acción
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFFD4AF37),
                                                    Color(0xFFB8941F),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFD4AF37,
                                                    ).withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: _isSaving
                                                    ? null
                                                    : _guardarAtencion,
                                                icon: _isSaving
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.black),
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.save,
                                                        size: 22,
                                                      ),
                                                label: Text(
                                                  _isSaving
                                                      ? 'Guardando...'
                                                      : 'Guardar Atención',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  foregroundColor: Colors.black,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: _isSaving
                                                  ? null
                                                  : () =>
                                                        Navigator.pop(context),
                                              icon: const Icon(
                                                Icons.close,
                                                size: 22,
                                              ),
                                              label: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                foregroundColor:
                                                    Colors.grey[700],
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
            );
          },
        ),
      ),
    );
  }
}

// ---------- Widgets Reutilizables ---------- //

class CustomInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? hint;
  final int maxLines;

  const CustomInput({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.onTap,
    this.icon,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF051932),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo obligatorio' : null,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: icon != null
                  ? Icon(icon, color: const Color(0xFFD4AF37), size: 22)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 16 : 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class TriajeDropdown extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;

  const TriajeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Color _getTriajeColor(String? triaje) {
    switch (triaje) {
      case 'Verde':
        return Colors.green;
      case 'Amarillo':
        return Colors.amber[700]!;
      case 'Rojo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nivel de Triaje',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF051932),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.local_hospital,
                color: Color(0xFFD4AF37),
                size: 22,
              ),
            ),
            hint: Text(
              'Seleccione nivel de triaje',
              style: TextStyle(color: Colors.grey[500]),
            ),
            items: opcionesTriaje.map((op) {
              final color = _getTriajeColor(op);
              return DropdownMenuItem(
                value: op,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      op,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'Seleccione un triaje' : null,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class PacienteDropdown extends StatelessWidget {
  final List<Map<String, String>> pacientes;
  final String? selectedId;
  final void Function(String?) onChanged;

  const PacienteDropdown({
    super.key,
    required this.pacientes,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paciente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF051932),
          ),
        ),
        const SizedBox(height: 8),
        pacientes.isNotEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedId,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Color(0xFFD4AF37),
                      size: 22,
                    ),
                  ),
                  hint: Text(
                    'Seleccione un paciente',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  items: pacientes
                      .map(
                        (paciente) => DropdownMenuItem<String>(
                          value: paciente['id'],
                          child: Text(
                            paciente['nombre'] ?? 'Paciente',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                  validator: (valor) =>
                      valor == null ? 'Debe seleccionar un paciente' : null,
                ),
              )
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay pacientes disponibles',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 20),
      ],
    );
  }
}
