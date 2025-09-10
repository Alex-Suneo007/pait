import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteAtencionesPage extends StatefulWidget {
  const ReporteAtencionesPage({super.key});
  @override
  State<ReporteAtencionesPage> createState() => _ReporteAtencionesPageState();
}

class _ReporteAtencionesPageState extends State<ReporteAtencionesPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<Map<String, dynamic>> _resultados = [];
  List<Map<String, String>> _pacientesList = [];
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() => _isLoading = true);
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('rol', isEqualTo: 'Usuario Normal')
        .get();
    final list = snap.docs.map((doc) {
      return {'id': doc.id, 'nombre': '${doc['nombre']}'};
    }).toList();
    if (list.isNotEmpty) {
      setState(() {
        _pacientesList = list;
        _pacienteSeleccionadoId = list[0]['id'];
        _pacienteSeleccionadoNombre = list[0]['nombre'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _filtrarDatos() async {
    if (_fechaInicio == null ||
        _fechaFin == null ||
        _pacienteSeleccionadoId == null)
      return;

    setState(() => _isLoading = true);

    final query = FirebaseFirestore.instance
        .collection('atenciones')
        .where('paciente_id', isEqualTo: _pacienteSeleccionadoId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!))
        .orderBy('timestamp', descending: true);

    final snap = await query.get();
    print("Documentos encontrados: ${snap.docs.length}");

    setState(() {
      _resultados = snap.docs.map((doc) => doc.data()).toList();
      _isLoading = false;
    });
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (esInicio)
          _fechaInicio = picked;
        else
          _fechaFin = picked;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0f2c57), const Color(0xFF051932)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.medical_information,
            color: Color(0xFFD4AF37),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            "Centro Médico ISTPET",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Reporte de Atenciones Médicas",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      color: Color(0xFF051932),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Filtros de Búsqueda",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF051932),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dropdown de pacientes mejorado
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _pacienteSeleccionadoId,
                    items: _pacientesList
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['id'],
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Color(0xFFD4AF37),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(p['nombre']!),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _pacienteSeleccionadoId = v;
                        _pacienteSeleccionadoNombre = _pacientesList.firstWhere(
                          (p) => p['id'] == v,
                        )['nombre'];
                      });
                    },
                    validator: (v) =>
                        v == null ? 'Selecciona un paciente' : null,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Paciente',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.person_search,
                        color: Color(0xFF051932),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Selectores de fecha mejorados
                Row(
                  children: [
                    Expanded(
                      child: _buildDateSelector(
                        "Fecha Inicio",
                        _fechaInicio,
                        Icons.calendar_today,
                        () => _seleccionarFecha(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateSelector(
                        "Fecha Fin",
                        _fechaFin,
                        Icons.event,
                        () => _seleccionarFecha(context, false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón de generar reporte mejorado
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shadowColor: const Color(0xFFD4AF37).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _filtrarDatos,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text("Generando..."),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assessment, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Generar Reporte",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? fecha,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF051932), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF051932),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fecha == null
                    ? "Seleccionar"
                    : "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}",
                style: TextStyle(
                  fontSize: 16,
                  color: fecha == null ? Colors.grey[600] : Colors.black,
                  fontWeight: fecha == null
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_chart,
                    color: Color(0xFF051932),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Resultados del Reporte",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF051932),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_resultados.length} registros",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(200),
                      1: FixedColumnWidth(120),
                      2: FixedColumnWidth(100),
                      3: FixedColumnWidth(250),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        children: [
                          _buildTableHeader('Paciente', Icons.person),
                          _buildTableHeader('Fecha', Icons.calendar_today),
                          _buildTableHeader('Triaje', Icons.medical_services),
                          _buildTableHeader('Diagnóstico', Icons.assignment),
                        ],
                      ),
                      ..._resultados.asMap().entries.map((entry) {
                        final index = entry.key;
                        final r = entry.value;
                        final f = r['timestamp'] as Timestamp?;
                        final fecha = f != null
                            ? "${f.toDate().day.toString().padLeft(2, '0')}/${f.toDate().month.toString().padLeft(2, '0')}/${f.toDate().year}"
                            : r['fecha'];

                        return TableRow(
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? Colors.grey[50]
                                : Colors.white,
                          ),
                          children: [
                            _buildTableCell(r['paciente'] ?? ''),
                            _buildTableCell(fecha ?? ''),
                            _buildTableCell(r['triaje'] ?? ''),
                            _buildTableCell(r['diagnostico'] ?? ''),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildNoResultsWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.amber[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 64, color: Color(0xFFD4AF37)),
            const SizedBox(height: 16),
            const Text(
              "Sin Resultados",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF051932),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "No se encontraron atenciones para el rango de fechas seleccionado.",
              style: TextStyle(color: Color(0xFF051932), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f2c57),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF051932),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          "Reporte de Atenciones - ISTPET",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFormCard(),
            const SizedBox(height: 24),
            if (_resultados.isNotEmpty)
              _buildResultsCard()
            else if (_fechaInicio != null && _fechaFin != null && !_isLoading)
              _buildNoResultsWidget(),
          ],
        ),
      ),
    );
  }
}
