import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Tipo de conta selecionado
  String _role = 'PASSENGER'; // 'PASSENGER' ou 'DRIVER'

  // Controllers - Dados do Usuário
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controllers - Exclusivos do Motorista
  final _cnhController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isLoading = false;

  // Método de envio do formulário
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Cadastra o Usuário Base no NestJS
      // ⚠️ Use o IP apropriado: 10.0.2.2 (Emulador Android) ou o IP local / Tailscale
      final userResponse = await http.post(
        Uri.parse('http://192.168.31.54:3000/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'role': _role,
        }),
      );

      if (userResponse.statusCode != 201 && userResponse.statusCode != 200) {
        final error = jsonDecode(userResponse.body);
        throw Exception(error['message'] ?? 'Erro ao criar usuário');
      }

      final userData = jsonDecode(userResponse.body);
      final String userId = userData['id'];

      // 2. Se for Motorista, cadastra o Perfil e o Carro
      if (_role == 'DRIVER') {
        // Cadastra o Driver com a CNH e o userId gerado
        final driverResponse = await http.post(
          Uri.parse('http://192.168.31.54:3000/drivers'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'cnh': _cnhController.text}),
        );

        if (driverResponse.statusCode != 201 &&
            driverResponse.statusCode != 200) {
          throw Exception(
            'Usuário criado, mas ocorreu um erro no cadastro do perfil de motorista.',
          );
        }

        final driverData = jsonDecode(driverResponse.body);
        final String driverId = driverData['id'];

        // Cadastra o Carro com o driverId retornado
        await http.post(
          Uri.parse('http://192.168.31.54:3000/cars'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'driverId': driverId,
            'brand': _brandController.text,
            'model': _modelController.text,
            'plate': _plateController.text,
            'color': _colorController.text,
            'year': int.parse(_yearController.text),
          }),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso! Faça seu login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Volta para a LoginScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = _role == 'DRIVER';

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tipo de Conta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Seletor entre Passageiro e Motorista
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'PASSENGER',
                      label: Text('Passageiro'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 'DRIVER',
                      label: Text('Motorista'),
                      icon: Icon(Icons.directions_car),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _role = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // --- SEÇÃO 1: DADOS PESSOAIS ---
                const Text(
                  'Dados Pessoais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe seu telefone' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),

                // --- SEÇÃO 2: DADOS DO MOTORISTA E VEÍCULO (Exibidos se _role == 'DRIVER') ---
                if (isDriver) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Dados da Habilitação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cnhController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número da CNH',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => isDriver && (v == null || v.isEmpty)
                        ? 'Informe a CNH'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dados do Veículo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Marca (ex: Toyota)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => isDriver && (v == null || v.isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Modelo (ex: Corolla)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => isDriver && (v == null || v.isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _plateController,
                          decoration: const InputDecoration(
                            labelText: 'Placa (ex: ABC1D23)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => isDriver && (v == null || v.isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _colorController,
                          decoration: const InputDecoration(
                            labelText: 'Cor (ex: Prata)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => isDriver && (v == null || v.isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ano de Fabricação (ex: 2021)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => isDriver && (v == null || v.isEmpty)
                        ? 'Informe o ano'
                        : null,
                  ),
                ],

                const SizedBox(height: 32),

                // Botão de Cadastrar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isDriver
                              ? 'Cadastrar como Motorista'
                              : 'Cadastrar como Passageiro',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
