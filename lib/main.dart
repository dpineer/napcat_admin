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

  Future<dynamic> _postWithResponse(String endpoint, Map<String, dynamic> data) async {
    try {
      isLoading = true;
      notifyListeners();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      isLoading = false;
      if (response.statusCode == 200) {
        notifyListeners();
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        errorMessage = 'Failed: ${response.body}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Actions
  Future<void> fetchSystemConfig() async {
    final res = await _get('/api/config');
    if (res != null && res['data'] != null) {
      systemConfig = res['data'];
    }
  }

  Future<void> updateSystemConfig(Map<String, dynamic> newConfig) async {
    final res = await _postWithResponse('/api/config', newConfig);
    if (res != null) {
      await fetchSystemConfig();
    }
  }

  Future<void> fetchKnowledge(String query) async {
    String endpoint = '/api/knowledge/list';
    if (query.isNotEmpty) {
      endpoint = '/api/knowledge?query=$query&limit=20';
    }
    final res = await _get(endpoint);
    if (res != null && res['data'] != null) {
      knowledgeDocs = res['data'] is List ? res['data'] : [];
    }
  }

  Future<void> addKnowledge(String content) async {
    final res = await _postWithResponse('/api/knowledge', {'content': content});
    if (res != null) {
      await fetchKnowledge('');
    }
  }
  
  Future<void> fetchPrompts() async {
    final res = await _get('/api/prompts');
    if (res != null && res['data'] != null) {
      prompts = res['data'];
    }
  }

  Future<void> updatePrompt(String type, Map<String, dynamic> template) async {
     final res = await _postWithResponse('/api/prompts', {'type': type, 'template': template});
     if (res != null) {
       await fetchPrompts();
     }
  }

  Future<void> deleteKnowledge(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/knowledge/$id'),
    );
    if (response.statusCode == 200) {
      await fetchKnowledge('');
    }
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
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.fetchSystemConfig();
    });
  }

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
              _StatusCard(
                title: 'LLM 模型',
                value: state.systemConfig['llm_model'] ?? '未配置', // 从API获取实际模型名称
                color: Colors.blue,
                icon: PhosphorIconsFill.brain,
              ),
              const SizedBox(width: 16),
              _StatusCard(
                title: '知识条目',
                value: state.knowledgeDocs.length.toString() + ' 条', // 显示实际知识条目数量
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
    _dbUrlCtrl.text = config['llm_base_url'] != null ? config['llm_base_url'] : config['database_url'] ?? '';
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
class PromptManagerPage extends StatefulWidget {
  const PromptManagerPage({super.key});

  @override
  State<PromptManagerPage> createState() => _PromptManagerPageState();
}

class _PromptManagerPageState extends State<PromptManagerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.fetchPrompts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    // 从state.prompts中提取数据
    Map<String, dynamic> templates = {};
    if (state.prompts['available_types'] != null && state.prompts['available_types'] is List) {
      // 根据可用类型构建模板数据
      for (String type in state.prompts['available_types']) {
        templates[type] = {
          'desc': _getDescriptionForType(type),
          'system': '系统提示词模板',
        };
      }
    }

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
          if (state.isLoading && templates.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (templates.isEmpty)
            const Center(child: Text('暂无提示词模板', style: TextStyle(color: Colors.grey)))
          else
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
                      onTap: () => _showEditDialog(context, key, data, state),
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

  String _getDescriptionForType(String type) {
    switch (type) {
      case 'Chat':
        return '标准聊天模式';
      case 'Analyze':
        return '深度分析模式';
      case 'Creative':
        return '创意写作模式';
      case 'Professional':
        return '专业助手模式';
      case 'Learn':
        return '学习助手模式';
      case 'Friendly':
        return '友好聊天模式';
      default:
        return '自定义模式';
    }
  }

  void _showEditDialog(BuildContext context, String type, Map<String, String> data, AppState state) {
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
          FilledButton(
            onPressed: () {
              // 更新提示词模板
              state.updatePrompt(type, {
                'system': sysCtrl.text,
                'description': data['desc'] ?? _getDescriptionForType(type),
              });
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// 4. Knowledge Base Page
class KnowledgeBasePage extends StatefulWidget {
  const KnowledgeBasePage({super.key});

  @override
  State<KnowledgeBasePage> createState() => _KnowledgeBasePageState();
}

class _KnowledgeBasePageState extends State<KnowledgeBasePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    state.fetchKnowledge(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton.small(
                onPressed: () => _showAddDialog(context, state),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: state.knowledgeDocs.isEmpty
                ? const Center(
                    child: Text('暂无知识库条目', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: state.knowledgeDocs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final doc = state.knowledgeDocs[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.article, size: 16)),
                        title: Text(doc['content'] != null 
                            ? doc['content'].toString().length > 50 
                              ? '${doc['content'].toString().substring(0, 50)}...' 
                              : doc['content'].toString()
                            : '未知内容'),
                        subtitle: Text(
                          'ID: ${doc['id'] ?? 'N/A'} • ${doc['created_at'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline), 
                          onPressed: () => _deleteKnowledge(context, state, doc['id']),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, AppState state) {
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
              if (ctrl.text.trim().isNotEmpty) {
                state.addKnowledge(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _deleteKnowledge(BuildContext context, AppState state, String? id) async {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个知识库条目吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              // 调用后端API删除知识库条目
              try {
                final response = await http.delete(
                  Uri.parse('${state.baseUrl}/api/knowledge/$id'),
                );
                if (response.statusCode == 200) {
                  // 删除成功，刷新列表
                  state.fetchKnowledge(_searchQuery);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('知识库条目删除成功')),
                  );
                } else {
                  // 删除失败
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: ${response.body}')),
                  );
                }
              } catch (e) {
                // 网络错误
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
