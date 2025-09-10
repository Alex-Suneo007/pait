import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color darkBlue = Color(0xFF0B1D3A);
const Color gold = Color(0xFFC9B037);
const Color lightGray = Color(0xFFF4F6F9);
const Color accentBlue = Color(0xFF1E3A8A);
const Color softGold = Color(0xFFF5E6A8);

class ConsultarPacientesPage extends StatefulWidget {
  const ConsultarPacientesPage({super.key});

  @override
  State<ConsultarPacientesPage> createState() => _ConsultarPacientesPageState();
}

class _ConsultarPacientesPageState extends State<ConsultarPacientesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Controllers para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  bool _soyDocente = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _carreraController.dispose();
    super.dispose();
  }

  // Método para limpiar el formulario
  void _limpiarFormulario() {
    _nombreController.clear();
    _cedulaController.clear();
    _telefonoController.clear();
    _correoController.clear();
    _carreraController.clear();
    _soyDocente = false;
  }

  // Método para actualizar usuario
  Future<void> _actualizarUsuario(String userId) async {
    if (_nombreController.text.trim().isEmpty ||
        _cedulaController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Por favor completa los campos obligatorios',
        isError: true,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .update({
            'nombre': _nombreController.text.trim(),
            'cedula': _cedulaController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'correo': _correoController.text.trim(),
            'soyDocente': _soyDocente,
            'carrera': _soyDocente ? null : _carreraController.text.trim(),
            'fechaModificacion': FieldValue.serverTimestamp(),
          });

      _limpiarFormulario();
      Navigator.pop(context);
      _mostrarMensaje('Usuario actualizado exitosamente');
    } catch (e) {
      _mostrarMensaje('Error al actualizar usuario: $e', isError: true);
    }
  }

  // Método para eliminar usuario
  Future<void> _eliminarUsuario(String userId, String nombre) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .delete();
      _mostrarMensaje('Usuario "$nombre" eliminado exitosamente');
    } catch (e) {
      _mostrarMensaje('Error al eliminar usuario: $e', isError: true);
    }
  }

  // Método para mostrar mensajes
  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Método para confirmar eliminación
  void _confirmarEliminarUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[400], size: 28),
              const SizedBox(width: 12),
              const Text('Confirmar eliminación'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar a "${usuario['nombre']}"?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarUsuario(usuario['id'], usuario['nombre']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Método para editar usuario
  void _editarUsuario(Map<String, dynamic> usuario) {
    _nombreController.text = usuario['nombre'] ?? '';
    _cedulaController.text = usuario['cedula'] ?? '';
    _telefonoController.text = usuario['telefono'] ?? '';
    _correoController.text = usuario['correo'] ?? '';
    _carreraController.text = usuario['carrera'] ?? '';
    _soyDocente = usuario['soyDocente'] ?? false;

    _mostrarFormularioUsuario(isEditing: true, userId: usuario['id']);
  }

  // Método para mostrar el formulario
  void _mostrarFormularioUsuario({bool isEditing = false, String? userId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildFormModal(isEditing: isEditing, userId: userId),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar por cédula o nombre...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search, color: gold, size: 22),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBlue, accentBlue],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Gestión de Usuarios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gold, softGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.people, color: darkBlue, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Gestiona información de docentes y estudiantes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> usuario,
    int index,
    bool isTeacher,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: darkBlue.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _mostrarDetalleUsuario(context, usuario),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTeacher
                                  ? [
                                      accentBlue.withOpacity(0.8),
                                      accentBlue.withOpacity(0.6),
                                    ]
                                  : [gold.withOpacity(0.8), softGold],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: (isTeacher ? accentBlue : gold)
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isTeacher ? Icons.school : Icons.person,
                            color: isTeacher ? Colors.white : darkBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usuario['nombre'] ?? 'Sin nombre',
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
                                    Icons.email_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      usuario['correo'] ?? 'Sin correo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTeacher
                                          ? accentBlue.withOpacity(0.1)
                                          : gold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isTeacher ? 'Docente' : 'Estudiante',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isTeacher ? accentBlue : gold,
                                      ),
                                    ),
                                  ),
                                  if (!isTeacher &&
                                      usuario['carrera'] != null) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: darkBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          usuario['carrera'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: darkBlue,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: gold,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormModal({bool isEditing = false, String? userId}) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          darkBlue.withOpacity(0.1),
                          accentBlue.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit, color: darkBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Editar Usuario',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _limpiarFormulario();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildFormField(
                          controller: _nombreController,
                          label: 'Nombre completo',
                          icon: Icons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _cedulaController,
                          label: 'Cédula',
                          icon: Icons.badge,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _correoController,
                          label: 'Correo electrónico',
                          icon: Icons.email,
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        // Switch para docente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gold.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: darkBlue),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Es docente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _soyDocente,
                                onChanged: (value) {
                                  setModalState(() {
                                    _soyDocente = value;
                                  });
                                },
                                activeColor: gold,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Campo carrera (solo si no es docente)
                        if (!_soyDocente)
                          _buildFormField(
                            controller: _carreraController,
                            label: 'Carrera',
                            icon: Icons.school_outlined,
                          ),
                        const SizedBox(height: 24),
                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _limpiarFormulario();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: Colors.grey[400]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _actualizarUsuario(userId!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: darkBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Actualizar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: gold, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue.withOpacity(0.1), accentBlue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold, softGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: darkBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                Text(
                  '$count ${count == 1 ? 'registro' : 'registros'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerExpansionTile(
    String carrera,
    List<Map<String, dynamic>> estudiantes,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: accentBlue, size: 25),
          ),
          title: Text(
            carrera,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          subtitle: Text(
            '${estudiantes.length} ${estudiantes.length == 1 ? 'estudiante' : 'estudiantes'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          children: estudiantes.asMap().entries.map((entry) {
            final index = entry.key;
            final estudiante = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildUserCard(estudiante, index, false),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers(
    List<QueryDocumentSnapshot> usuarios,
  ) {
    final filtered = <Map<String, dynamic>>[];

    for (var doc in usuarios) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      if (_searchQuery.isEmpty) {
        filtered.add(data);
      } else {
        final nombre = (data['nombre'] ?? '').toString().toLowerCase();
        final cedula = (data['cedula'] ?? '').toString().toLowerCase();

        if (nombre.contains(_searchQuery) || cedula.contains(_searchQuery)) {
          filtered.add(data);
        }
      }
    }

    return filtered;
  }

  void _mostrarDetalleUsuario(
    BuildContext context,
    Map<String, dynamic> usuario,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailModal(usuario),
    );
  }

  Widget _buildDetailModal(Map<String, dynamic> usuario) {
    final bool isTeacher = usuario['soyDocente'] ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Header with action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      darkBlue.withOpacity(0.1),
                      accentBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTeacher
                                  ? [accentBlue, accentBlue.withOpacity(0.7)]
                                  : [gold, softGold],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: (isTeacher ? accentBlue : gold)
                                    .withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isTeacher ? Icons.school : Icons.person,
                            color: isTeacher ? Colors.white : darkBlue,
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usuario['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isTeacher ? accentBlue : gold,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  isTeacher ? 'Docente' : 'Estudiante',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editarUsuario(usuario);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmarEliminarUsuario(usuario);
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInfoSection(
                      'Información Personal',
                      Icons.person_outline,
                      [
                        _buildInfoRow('Nombre', usuario['nombre']),
                        _buildInfoRow('Cédula', usuario['cedula']),
                        _buildInfoRow('Teléfono', usuario['telefono']),
                        _buildInfoRow('Correo', usuario['correo']),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      'Información Académica',
                      Icons.school_outlined,
                      [
                        _buildInfoRow(
                          'Es docente',
                          (usuario['soyDocente'] ?? false) ? 'Sí' : 'No',
                        ),
                        if (!isTeacher)
                          _buildInfoRow('Carrera', usuario['carrera']),
                      ],
                    ),
                    if (usuario['fechaCreacion'] != null ||
                        usuario['fechaModificacion'] != null) ...[
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        'Información del Sistema',
                        Icons.info_outline,
                        [
                          if (usuario['fechaCreacion'] != null)
                            _buildInfoRow(
                              'Fecha de creación',
                              _formatTimestamp(usuario['fechaCreacion']),
                            ),
                          if (usuario['fechaModificacion'] != null)
                            _buildInfoRow(
                              'Última modificación',
                              _formatTimestamp(usuario['fechaModificacion']),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No disponible';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Formato no válido';
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Error al formatear fecha';
    }
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.1), softGold.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: darkBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value?.toString() ?? 'No especificado',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error al cargar usuarios',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor, intenta nuevamente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Recargar
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: darkBlue,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: darkBlue.withOpacity(0.1),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              color: gold,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Cargando usuarios...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final usuarios = snapshot.data!.docs;
                  final filteredUsers = _filterUsers(usuarios);

                  if (usuarios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: gold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.groups_outlined,
                              size: 50,
                              color: gold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No hay usuarios registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay usuarios disponibles en el sistema',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Separar docentes y estudiantes
                  final docentes = <Map<String, dynamic>>[];
                  final estudiantesPorCarrera =
                      <String, List<Map<String, dynamic>>>{};

                  for (var userData in filteredUsers) {
                    final bool soyDocente = userData['soyDocente'] ?? false;
                    final String carrera = (userData['carrera'] ?? '')
                        .toString();

                    if (soyDocente) {
                      docentes.add(userData);
                    } else if (carrera.isNotEmpty) {
                      estudiantesPorCarrera.putIfAbsent(carrera, () => []);
                      estudiantesPorCarrera[carrera]!.add(userData);
                    }
                  }

                  if (filteredUsers.isEmpty ||
                      (docentes.isEmpty && estudiantesPorCarrera.isEmpty)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No se encontraron resultados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros términos de búsqueda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Text('Limpiar búsqueda'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      // Mostrar docentes agrupados
                      if (docentes.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Docentes',
                          Icons.school,
                          docentes.length,
                        ),
                        ...docentes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final docente = entry.value;
                          return _buildUserCard(docente, index, true);
                        }),
                        const SizedBox(height: 20),
                      ],

                      // Mostrar estudiantes agrupados por carrera
                      if (estudiantesPorCarrera.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Estudiantes por Carrera',
                          Icons.groups,
                          estudiantesPorCarrera.values.fold(
                            0,
                            (total, list) => total + list.length,
                          ),
                        ),
                        ...estudiantesPorCarrera.entries.map((entry) {
                          final carrera = entry.key;
                          final estudiantes = entry.value;
                          return _buildCareerExpansionTile(
                            carrera,
                            estudiantes,
                          );
                        }),
                      ],

                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
