import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

//Config Variables
const String kDefaultBaseUrl = 'http://127.0.0.1:8082';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const NapCatAdminApp(),
    ),
  );
}

class NapCatAdminApp extends StatelessWidget {
  const NapCatAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NapCat Backend Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark, // 默认暗色主题，适合开发者
        ),
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainLayout(),
    );
  }
}

// --- State Management ---

class AppState extends ChangeNotifier {
  String baseUrl = kDefaultBaseUrl;
  bool isLoading = false;
  String? errorMessage;

  // Data Caches
  Map<String, dynamic> systemConfig = {};
  List<dynamic> knowledgeDocs = [];
  Map<String, dynamic> prompts = {};

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('api_url') ?? kDefaultBaseUrl;
    notifyListeners();
    fetchSystemConfig(); // Initial Fetch
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
    notifyListeners();
    fetchSystemConfig();
  }

  // Generic API Helper
  Future<dynamic> _get(String endpoint) async {
    try {
      isLoading = true;
      notifyListeners();
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        isLoading = false;
        notifyListeners();
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      isLoading = true;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      isLoading = false;
      if (response.statusCode != 200) {
        errorMessage = 'Failed: ${response.body}';
      }
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Actions
  Future<void> fetchSystemConfig() async {
    final res = await _get('/api/config');
    if (res != null) systemConfig = res;
  }

  Future<void> updateSystemConfig(Map<String, dynamic> newConfig) async {
    await _post('/api/config', newConfig);
    await fetchSystemConfig();
  }

  Future<void> fetchKnowledge(String query) async {
    // 模拟搜索，实际应调用 Rust 的 /api/knowledge?q=...
    // 这里假设返回最近的学习记录
    final res = await _get('/api/knowledge?limit=20'); 
    if (res != null) knowledgeDocs = res is List ? res : [];
  }

  Future<void> addKnowledge(String content) async {
    await _post('/api/knowledge', {'content': content});
    await fetchKnowledge('');
  }
  
  // 模拟提示词获取，对应 Rust 的 PromptManager
  Future<void> fetchPrompts() async {
    // 假设后端返回类似 {"Chat": {...}, "Learn": {...}}
    final res = await _get('/api/prompts');
    if (res != null) prompts = res;
  }

  Future<void> updatePrompt(String type, Map<String, dynamic> template) async {
     await _post('/api/prompts', {'type': type, 'template': template});
     await fetchPrompts();
  }
}

// --- UI Layout ---

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ConfigurationPage(),
    const PromptManagerPage(),
    const KnowledgeBasePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(PhosphorIcons.robot(PhosphorIconsStyle.fill), size: 32, color: Theme.of(context).colorScheme.primary),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(PhosphorIconsRegular.chartLineUp),
                selectedIcon: Icon(PhosphorIconsFill.chartLineUp),
                label: Text('概览'),
              ),
              NavigationRailDestination(
                icon: Icon(PhosphorIconsRegular.gear),
                selectedIcon: Icon(PhosphorIconsFill.gear),
                label: Text('配置'),
              ),
              NavigationRailDestination(
                icon: Icon(PhosphorIconsRegular.chatText),
                selectedIcon: Icon(PhosphorIconsFill.chatText),
                label: Text('提示词'),
              ),
              NavigationRailDestination(
                icon: Icon(PhosphorIconsRegular.books),
                selectedIcon: Icon(PhosphorIconsFill.books),
                label: Text('知识库'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// --- Pages ---

// 1. Dashboard Page
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('系统状态', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatusCard(
                title: '后端连接',
                value: state.isLoading ? '检测中...' : (state.errorMessage == null ? '在线' : '离线'),
                color: state.errorMessage == null ? Colors.green : Colors.red,
                icon: PhosphorIconsFill.plugsConnected,
              ),
              const SizedBox(width: 16),
              const _StatusCard(
                title: 'LLM 模型',
                value: 'DeepSeek-V3', // 这里的实际值应从 API 获取
                color: Colors.blue,
                icon: PhosphorIconsFill.brain,
              ),
              const SizedBox(width: 16),
              const _StatusCard(
                title: '知识条目',
                value: '124 条', // 这里的实际值应从 API 获取
                color: Colors.orange,
                icon: PhosphorIconsFill.database,
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (state.errorMessage != null)
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
               child: Text('错误: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
             ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// 2. Configuration Page (Replaces Hardcoded .env)
class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _dbUrlCtrl = TextEditingController();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _baseUrlCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 延迟加载数据填入表单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      _loadData(state.systemConfig);
    });
  }

  void _loadData(Map<String, dynamic> config) {
    _dbUrlCtrl.text = config['database_url'] ?? '';
    _apiKeyCtrl.text = config['llm_api_key'] ?? '';
    _baseUrlCtrl.text = config['llm_base_url'] ?? '';
    _modelCtrl.text = config['llm_model'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            state.updateSystemConfig({
              'database_url': _dbUrlCtrl.text,
              'llm_api_key': _apiKeyCtrl.text,
              'llm_base_url': _baseUrlCtrl.text,
              'llm_model': _modelCtrl.text,
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('配置已保存，请重启后端服务生效')));
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('保存配置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('系统配置', style: Theme.of(context).textTheme.headlineMedium),
              const Text('这些设置将替代 Rust 后端的硬编码配置'),
              const SizedBox(height: 24),
              
              _buildSectionHeader('API 连接设置'),
              _buildTextField('后端地址 (Flutter连接用)', controller: TextEditingController(text: state.baseUrl), onChanged: (v) => state.setBaseUrl(v)),
              
              const SizedBox(height: 24),
              _buildSectionHeader('LLM 设置 (DeepSeek 等)'),
              _buildTextField('API Base URL', controller: _baseUrlCtrl, hint: 'https://api.deepseek.com'),
              const SizedBox(height: 16),
              _buildTextField('API Key', controller: _apiKeyCtrl, obscureText: true),
              const SizedBox(height: 16),
              _buildTextField('Model Name', controller: _modelCtrl, hint: 'deepseek-chat'),

              const SizedBox(height: 24),
              _buildSectionHeader('数据库'),
              _buildTextField('PostgreSQL URL', controller: _dbUrlCtrl, hint: 'postgresql://user:pass@localhost:5432/db'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller, String? hint, bool obscureText = false, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
      validator: (value) => value == null || value.isEmpty ? '此项不能为空' : null,
    );
  }
}

// 3. Prompt Manager Page
class PromptManagerPage extends StatelessWidget {
  const PromptManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 这里使用模拟数据，实际应从 state.prompts 获取
    final templates = {
      'Chat': {'desc': '标准聊天模式', 'system': '你是一个AI助手...'},
      'Learn': {'desc': '学习模式', 'system': '你是一个知识管理助手...'},
      'Creative': {'desc': '创意模式', 'system': '你是一个富有创意的AI...'},
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('提示词工程', style: Theme.of(context).textTheme.headlineMedium),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.add), 
                label: const Text('新建模板')
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: templates.length,
              itemBuilder: (ctx, index) {
                final key = templates.keys.elementAt(index);
                final data = templates[key]!;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showEditDialog(context, key, data),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                                child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit, size: 16),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(data['desc']!, style: Theme.of(context).textTheme.bodyMedium),
                          const Spacer(),
                          Text(
                            data['system']!, 
                            maxLines: 3, 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String type, Map<String, String> data) {
    final sysCtrl = TextEditingController(text: data['system']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('编辑模板: $type'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sysCtrl,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('保存')),
        ],
      ),
    );
  }
}

// 4. Knowledge Base Page
class KnowledgeBasePage extends StatelessWidget {
  const KnowledgeBasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('知识库管理', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: '搜索知识库...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton.small(
                onPressed: () => _showAddDialog(context),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: 10, // 模拟数据
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.article, size: 16)),
                    title: Text('关于 Rust 所有权机制的解释 #$index'),
                    subtitle: Text('2026-02-18 20:30 • 相似度 0.98', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加新知识'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '输入文本内容，系统将自动向量化...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              context.read<AppState>().addKnowledge(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}