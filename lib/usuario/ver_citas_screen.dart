import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class VerCitasScreen extends StatelessWidget {
  const VerCitasScreen({super.key});

  final Color azulMarino = const Color(0xFF001f3f);
  final Color dorado = const Color(0xFFD4AF37);
  final Color fondo = const Color(0xFFF8FAFC);
  final Color blanco = Colors.white;

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: fondo,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: azulMarino.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.red.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_off, size: 40, color: Colors.red),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Usuario no autenticado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: fondo,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('atenciones')
            .where('paciente_id', isEqualTo: uid)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              // Header premium con estadísticas
              _buildPremiumHeader(context, snapshot),

              // Contenido principal
              if (snapshot.hasError)
                _buildErrorState()
              else if (snapshot.connectionState == ConnectionState.waiting)
                _buildLoadingState()
              else if (snapshot.data!.docs.isEmpty)
                _buildEmptyState()
              else
                _buildCitasList(snapshot.data!.docs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snapshot,
  ) {
    final totalCitas = snapshot.hasData ? snapshot.data!.docs.length : 0;
    final citasAtendidas = snapshot.hasData
        ? snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['estado'] ?? '').toLowerCase() == 'atendido';
          }).length
        : 0;

    return SliverToBoxAdapter(
      child: Container(
        height: 280,
        child: Stack(
          children: [
            // Fondo con gradiente y formas
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    azulMarino,
                    azulMarino.withOpacity(0.9),
                    const Color(0xFF0a2f5f),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Formas decorativas
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: dorado.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: dorado.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del header
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Barra superior con botón back
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: dorado.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: dorado.withOpacity(0.3)),
                          ),
                          child: const Text(
                            '✨ Historial Médico',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título principal
                  const Text(
                    'Mis Citas Médicas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Tarjetas de estadísticas flotantes
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total de Citas',
                      totalCitas.toString(),
                      Icons.calendar_month,
                      dorado,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Atendidas',
                      citasAtendidas.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pendientes',
                      (totalCitas - citasAtendidas).toString(),
                      Icons.pending,
                      Colors.orange,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: azulMarino,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
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
                  colors: [
                    Colors.red.withOpacity(0.2),
                    Colors.red.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error al cargar las citas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, verifica tu conexión e intenta nuevamente',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(dorado),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando tus citas...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: azulMarino,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        dorado.withOpacity(0.1),
                        dorado.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: dorado.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medical_services, size: 40, color: dorado),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes citas registradas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Cuando tengas citas médicas programadas\naparecerán en esta sección',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: dorado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dorado.withOpacity(0.3)),
              ),
              child: Text(
                '💡 Consulta en recepción para agendar una cita',
                style: TextStyle(
                  color: dorado.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitasList(List<QueryDocumentSnapshot> citas) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final citaDoc = citas[index];
          final data = citaDoc.data() as Map<String, dynamic>;

          DateTime fechaDate;
          if (data['fecha'] is Timestamp) {
            fechaDate = (data['fecha'] as Timestamp).toDate();
          } else if (data['fecha'] is String) {
            fechaDate = DateTime.tryParse(data['fecha']) ?? DateTime.now();
          } else {
            fechaDate = DateTime.now();
          }

          final fechaStr =
              '${fechaDate.day.toString().padLeft(2, '0')} '
              '${_nombreMes(fechaDate.month)} ${fechaDate.year}';

          final motivo = data['motivo'] ?? 'Sin motivo';
          final estado = data['estado'] ?? 'Pendiente';
          final modificadoPor = data['modificado_por'];
          final hora = data['hora'] ?? 'Sin hora';

          return _buildPremiumCitaCard(
            context,
            data,
            fechaStr,
            hora,
            motivo,
            estado,
            modificadoPor,
            fechaDate,
          );
        }, childCount: citas.length),
      ),
    );
  }

  Widget _buildPremiumCitaCard(
    BuildContext context,
    Map<String, dynamic> data,
    String fechaStr,
    String hora,
    String motivo,
    String estado,
    String? modificadoPor,
    DateTime fechaDate,
  ) {
    final bool isAtendido = estado.toLowerCase() == 'atendido';
    final bool isPendiente = estado.toLowerCase() == 'pendiente';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isAtendido) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completada';
    } else if (isPendiente) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Pendiente';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.info;
      statusText = estado;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => _mostrarDetalleCita(
          context,
          data,
          fechaStr,
          hora,
          estado,
          modificadoPor,
          fechaDate,
        ),
        child: Container(
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
              // Header de la tarjeta
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.1),
                      statusColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            motivo,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: azulMarino,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido de la tarjeta
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Fecha
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.calendar_today,
                            label: 'Fecha',
                            value: fechaStr,
                            color: dorado,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Hora
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.access_time,
                            label: 'Hora',
                            value: hora,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botón de acción
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [azulMarino, azulMarino.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: azulMarino.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _mostrarDetalleCita(
                            context,
                            data,
                            fechaStr,
                            hora,
                            estado,
                            modificadoPor,
                            fechaDate,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility, color: dorado, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Ver Detalles Completos',
                                  style: TextStyle(
                                    color: dorado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: azulMarino,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleCita(
    BuildContext context,
    Map<String, dynamic> data,
    String fechaStr,
    String hora,
    String estado,
    String? modificadoPor,
    DateTime fechaDate,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: azulMarino.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle y header
            Container(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header del modal premium
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [azulMarino.withOpacity(0.05), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [dorado, dorado.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: dorado.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Cita',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: azulMarino,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Información médica completa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Información principal en grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: fondo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCard(
                                  '📅',
                                  'Fecha',
                                  fechaStr,
                                  dorado,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailCard(
                                  '🕒',
                                  'Hora',
                                  hora,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailCard(
                                  '📝',
                                  'Motivo',
                                  data['motivo'] ?? 'Sin motivo',
                                  Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailCard(
                                  '📌',
                                  'Estado',
                                  estado,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (modificadoPor != null &&
                              modificadoPor.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailCard(
                              '👤',
                              'Modificado por',
                              modificadoPor,
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón de acción principal
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [azulMarino, azulMarino.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: azulMarino.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final pdf = await _crearPDF(
                              data,
                              fechaStr,
                              hora,
                              estado,
                              modificadoPor,
                            );
                            await Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async =>
                                  pdf.save(),
                            );
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print, color: dorado, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Descargar PDF',
                                  style: TextStyle(
                                    color: dorado,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón cerrar
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cerrar',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String emoji,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: azulMarino,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _crearPDF(
    Map<String, dynamic> data,
    String fechaStr,
    String hora,
    String estado,
    String? modificadoPor,
  ) async {
    final pdf = pw.Document();
    final istpetColor = PdfColor.fromHex('#001f3f');
    final goldColor = PdfColor.fromHex('#D4AF37');
    final greyLight = PdfColor.fromHex('#F4F4F4');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'INSTITUTO SUPERIOR TECNOLÓGICO ISTPET',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: istpetColor,
              ),
            ),
            pw.Divider(color: goldColor, thickness: 2),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado por ISTPET',
              style: pw.TextStyle(fontSize: 10, color: greyLight),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: greyLight),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            'Detalle de la Cita Médica',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: [
              'Fecha',
              'Hora',
              'Paciente',
              'Motivo',
              'Triaje',
              'Estado',
              'Modificado por',
            ],
            data: [
              [
                fechaStr,
                hora,
                data['paciente'] ?? '',
                data['motivo'] ?? '',
                data['triaje'] ?? '',
                estado,
                modificadoPor ?? '-',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: istpetColor,
            ),
            cellStyle: pw.TextStyle(fontSize: 11),
            headerDecoration: pw.BoxDecoration(color: greyLight),
            cellHeight: 25,
            columnWidths: {
              0: pw.FractionColumnWidth(0.15),
              1: pw.FractionColumnWidth(0.09),
              2: pw.FractionColumnWidth(0.16),
              3: pw.FractionColumnWidth(0.19),
              4: pw.FractionColumnWidth(0.12),
              5: pw.FractionColumnWidth(0.12),
              6: pw.FractionColumnWidth(0.17),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Diagnóstico Presuntivo:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: greyLight,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              data['diagnostico'] ?? '-',
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Tratamiento o Procedimiento:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: greyLight,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              data['tratamiento'] ?? '-',
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Observaciones:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: greyLight,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              data['observaciones'] ?? '-',
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  String _nombreMes(int mes) {
    const meses = [
      '',
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
    ];
    return meses[mes];
  }
}
