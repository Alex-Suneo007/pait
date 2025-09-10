import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔸 Importación para Firestore

const Color darkBlue = Color(0xFF0B1D3A);
const Color blueAccent = Color(0xFF123C69);
const Color gold = Color(0xFFC9B037);

class AgregarMaterialesPage extends StatefulWidget {
  const AgregarMaterialesPage({super.key});

  @override
  State<AgregarMaterialesPage> createState() => _AgregarMaterialesPageState();
}

class _AgregarMaterialesPageState extends State<AgregarMaterialesPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  AnimationController? _animationController;
  AnimationController? _floatingController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _slideAnimation;
  Animation<double>? _floatingAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController!, curve: Curves.easeInOut),
    );

    _animationController?.forward();
    _floatingController?.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _floatingController?.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _guardarMaterial() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;

      try {
        await FirebaseFirestore.instance.collection('materiales').add({
          'nombre': nombre,
          'descripcion': descripcion,
          'stock': stock,
          'fecha_registro': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text('Material "$nombre" agregado correctamente.'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        _nombreController.clear();
        _descripcionController.clear();
        _stockController.clear();
        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Error al guardar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Agregar Materiales',
          style: TextStyle(
            color: darkBlue,
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              const Color(0xFFF4F6F9),
              Colors.white,
            ],
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
                  child: AnimatedBuilder(
                    animation:
                        _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation?.value ?? 0.0),
                        child: Opacity(
                          opacity: _fadeAnimation?.value ?? 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildHeaderSection(),
                              const SizedBox(height: 40),
                              _buildFormCard(),
                            ],
                          ),
                        ),
                      );
                    },
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
        // Forma azul principal
        Positioned(
          top: -100,
          right: -80,
          child: AnimatedBuilder(
            animation: _floatingAnimation ?? const AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (_floatingAnimation?.value ?? 0.0) * 20),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.15), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(140),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma dorada mediana
        Positioned(
          bottom: 150,
          left: -60,
          child: AnimatedBuilder(
            animation: _floatingAnimation ?? const AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset((_floatingAnimation?.value ?? 0.0) * 15, 0),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.shade200.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            },
          ),
        ),

        // Forma pequeña decorativa
        Positioned(
          top: 200,
          left: 50,
          child: AnimatedBuilder(
            animation: _floatingAnimation ?? const AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -(_floatingAnimation?.value ?? 0.0) * 10,
                  (_floatingAnimation?.value ?? 0.0) * 8,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [darkBlue.withOpacity(0.1), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Column(
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nuevo Material Médico',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Registra un nuevo material en el inventario del centro médico',
            style: TextStyle(
              fontSize: 15,
              color: darkBlue.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 20,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Material',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nombreController,
              label: 'Nombre del material',
              icon: Icons.medical_services_rounded,
              hint: 'Ej: Jeringas, Vendas, Alcohol, etc.',
            ),

            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              icon: Icons.description_rounded,
              hint: 'Describe las características del material',
              maxLines: 3,
            ),

            _buildTextField(
              controller: _stockController,
              label: 'Stock inicial',
              icon: Icons.inventory_2_rounded,
              inputType: TextInputType.number,
              hint: 'Cantidad disponible',
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: darkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: gold.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(darkBlue),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Guardar Material',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(color: darkBlue, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.2), gold.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: gold, size: 24),
          ),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          labelStyle: TextStyle(
            color: darkBlue.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: darkBlue.withOpacity(0.4), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          if (inputType == TextInputType.number &&
              int.tryParse(value.trim()) == null) {
            return 'Ingresa un número válido';
          }
          return null;
        },
      ),
    );
  }
}
