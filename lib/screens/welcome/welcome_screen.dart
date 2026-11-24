
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color verde = Color(0xFF245C45);
  static const Color verdeClaro = Color(0xFF4D9470);
  static const Color crema = Color(0xFFF8F7F0);
  static const Color texto = Color(0xFF263B31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: crema,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ENCABEZADO
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: verde.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: verde,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'HUELLITAS',
                          style: TextStyle(
                            color: verde,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFE78B83),
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // PORTADA
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [verde, Color(0xFF397B5B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: verde.withOpacity(0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              '🐾  AMOR EN CADA HUELLA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          const Text(
                            'Un mundo mejor\npara sus patitas.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Todo lo que tu mascota necesita, '
                                'con el cariño y cuidado que merece.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.13),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // PRESENTACIÓN
                    const Text(
                      '¡Bienvenido a Huellitas!',
                      style: TextStyle(
                        color: texto,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Descubre productos para consentir a tu mejor amigo '
                          'y forma parte de una comunidad que ama a los animales.',
                      style: TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTÓN CATÁLOGO
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/catalogo'),
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text(
                          'Explorar catálogo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTÓN LOGIN
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: verde,
                          side: const BorderSide(
                            color: verde,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SECCIÓN SOLIDARIA
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F1E9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD6E5D8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  color: verde,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '¡También puedes ayudar!',
                                  style: TextStyle(
                                    color: verde,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 13),

                          const Text(
                            'Cada pequeña acción puede cambiar una vida. '
                                'Únete como voluntario o apoya con donaciones '
                                'para ayudar a nuestros amigos de cuatro patas.',
                            style: TextStyle(
                              color: Color(0xFF53685B),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 17),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/login'),
                              icon: const Icon(
                                Icons.favorite_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'Quiero ayudar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: verde,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PIE DE PÁGINA
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            color: Color(0xFF9BAA9E),
                            size: 20,
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Hecho con amor para quienes no tienen voz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF89968E),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'HUELLITAS © 2026',
                            style: TextStyle(
                              color: Color(0xFF9BAA9E),
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
