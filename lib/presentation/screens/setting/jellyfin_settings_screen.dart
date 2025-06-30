import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/providers/jellyfin/jellyfin_auth_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models/jellyfin_models.dart';

class JellyfinSettingsScreen extends StatefulWidget {
  const JellyfinSettingsScreen({super.key});

  @override
  State<JellyfinSettingsScreen> createState() => _JellyfinSettingsScreenState();
}

class _JellyfinSettingsScreenState extends State<JellyfinSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberCredentials = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  final bool _autoFillFromSaved = true;
  Map<String, dynamic>? serverInfo;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _loadSavedCredentials();
    _loadServerInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadSavedCredentials() {
    final provider = context.read<JellyfinAuthProvider>();
    final savedCredentials = provider.savedCredentials;

    if (savedCredentials != null && _autoFillFromSaved) {
      setState(() {
        _serverUrlController.text = savedCredentials.serverUrl;
        _usernameController.text = savedCredentials.username;
        _passwordController.text = savedCredentials.password;
      });
    }
  }

  void _loadServerInfo() async {
    final provider = context.read<JellyfinAuthProvider>();
    serverInfo = await provider.getServerInfo();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildConnectionStatus(),
                      const SizedBox(height: 32),
                      _buildLoginForm(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                      _buildServerInfo(),
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

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      leading: IconButton(
        onPressed: () => context.go('/'),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: theme.colorScheme.onSurface,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Jellyfin Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.accentBlue.withOpacity(0.1),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.settings_remote_rounded,
              size: 48,
              color: AppTheme.accentBlue.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<JellyfinAuthProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final isLoggedIn = provider.isLoggedIn;

        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (isLoggedIn) {
          statusColor = Colors.greenAccent;
          statusIcon = Icons.cloud_done_rounded;
          statusText = 'Connected to ${provider.serverUrl}';
        } else if (isLoggedIn) {
          statusColor = Colors.orange;
          statusIcon = Icons.cloud_off_rounded;
          statusText = 'Pure connection';
        } else {
          statusColor = theme.colorScheme.outline;
          statusIcon = Icons.cloud_outlined;
          statusText = 'Not connected';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
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
                      isLoggedIn ? 'Connected' : 'Disconnected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      statusText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (isLoggedIn) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showLogoutDialog(),
                  icon: Icon(Icons.logout_rounded, color: Colors.red.shade400),
                  tooltip: 'Logout',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Server Configuration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Server URL Field
            TextFormField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://jellyfin.example.com:8096',
                prefixIcon: Icon(Icons.dns_rounded),
                suffixIcon:
                    _isTestingConnection
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          onPressed: _testConnection,
                          icon: Icon(Icons.wifi_find_rounded),
                          tooltip: 'Test Connection',
                        ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter server URL';
                }
                if (!value.contains('.') || value.length < 5) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Username Field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 20),

            // Remember Credentials Switch
            SwitchListTile(
              title: Text(
                'Remember Credentials',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                'Save login details securely on this device',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              value: _rememberCredentials,
              onChanged: (value) {
                setState(() {
                  _rememberCredentials = value;
                });
              },
              activeColor: AppTheme.accentBlue,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Login Button
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child:
              _isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded),
                      const SizedBox(width: 8),
                      Text(
                        'Connect to Jellyfin',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
        ),
        const SizedBox(height: 12),

        // Clear Credentials Button
        Consumer<JellyfinAuthProvider>(
          builder: (context, provider, child) {
            if (provider.savedCredentials == null)
              return const SizedBox.shrink();

            return OutlinedButton(
              onPressed: _clearCredentials,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.red.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Clear Saved Credentials',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerInfo() {
    return Consumer<JellyfinAuthProvider>(
      builder: (context, provider, child) {
        if (serverInfo == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_rounded, color: AppTheme.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Server Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                'Server Name',
                serverInfo?['ServerName'] ?? 'Unknown',
              ),
              _buildInfoRow('Version', serverInfo?['Version'] ?? 'Unknown'),
              _buildInfoRow(
                'Operating System',
                serverInfo?['OperatingSystem'] ?? 'Unknown',
              ),

              if (provider.currentUser != null) ...[
                const Divider(height: 24),
                _buildInfoRow('Logged in as', provider.getSuggestedUsername()),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_serverUrlController.text.isEmpty) {
      _showSnackBar('Please enter a server URL', isError: true);
      return;
    }

    setState(() {
      _isTestingConnection = true;
    });

    try {
      final provider = context.read<JellyfinAuthProvider>();
      final isConnected = await provider.testConnection(
        _serverUrlController.text,
      );

      if (isConnected) {
        _showSnackBar('Connection successful!', isError: false);
      } else {
        _showSnackBar('Cannot connect to server', isError: true);
      }
    } catch (e) {
      _showSnackBar('Connection failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<JellyfinAuthProvider>();
      final success = await provider.login(
        serverUrl: _serverUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        rememberCredentials: _rememberCredentials,
      );

      if (success) {
        _showSnackBar('Successfully connected to Jellyfin!', isError: false);
      } else {
        _showSnackBar(
          'Login failed. Please check your credentials.',
          isError: true,
        );
      }
    } on JellyfinAuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Login failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCredentials() async {
    final confirmed = await _showConfirmDialog(
      'Clear Credentials',
      'Are you sure you want to clear saved credentials? You will need to enter them again next time.',
    );

    if (confirmed == true) {
      final provider = context.read<JellyfinAuthProvider>();
      await provider.logout(clearCredentials: true);
      _showSnackBar('Credentials cleared', isError: false);
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await _showConfirmDialog(
      'Logout',
      'Are you sure you want to logout from Jellyfin?',
    );

    if (confirmed == true) {
      final provider = context.read<JellyfinAuthProvider>();
      await provider.logout();
      _showSnackBar('Logged out successfully', isError: false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
