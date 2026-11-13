import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';

/// Data Model for Organization Node in Hierarchy Tree
class OrgNode {
  final String id;
  final String name;
  final String role;
  final String? department;
  final String? branch;
  final String? epf;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? parentId;
  final List<OrgNode> children;

  // Render layout coordinates (calculated dynamically)
  double x = 0;
  double y = 0;

  OrgNode({
    required this.id,
    required this.name,
    required this.role,
    this.department,
    this.branch,
    this.epf,
    this.email,
    this.phone,
    this.avatarUrl,
    this.parentId,
    List<OrgNode>? children,
  }) : children = children ?? [];

  /// Auto-generate OrgNode tree recursively from a raw backend JSON Map
  factory OrgNode.fromBackendJson(Map<String, dynamic> json, {String? defaultParentId}) {
    final String nodeId = (json['id'] ?? json['_id'] ?? json['uid'] ?? 'node_${DateTime.now().microsecondsSinceEpoch}').toString();
    final String nodeName = (json['name'] ?? json['fullName'] ?? json['full_name'] ?? json['username'] ?? json['email'] ?? 'Member').toString();
    final String nodeRole = (json['role'] ?? json['designation'] ?? json['title'] ?? json['position'] ?? 'Team Member').toString();
    final String? nodeDept = json['department']?.toString() ?? json['dept']?.toString();
    final String? nodeBranch = json['branch']?.toString() ?? json['location']?.toString() ?? json['branch_name']?.toString();
    final String? nodeEpf = json['epf']?.toString() ?? json['epf_no']?.toString();
    final String? nodeEmail = json['email']?.toString();
    final String? nodePhone = json['phone']?.toString() ?? json['mobile']?.toString();
    final String? pId = (json['parentId'] ?? json['manager_id'] ?? json['reports_to'] ?? defaultParentId)?.toString();

    final List<OrgNode> childNodes = [];
    final rawChildren = json['children'] ?? json['reports'] ?? json['direct_reports'] ?? json['team'];
    if (rawChildren is List) {
      for (var c in rawChildren) {
        if (c is Map<String, dynamic>) {
          childNodes.add(OrgNode.fromBackendJson(c, defaultParentId: nodeId));
        }
      }
    }

    return OrgNode(
      id: nodeId,
      name: nodeName,
      role: nodeRole,
      department: nodeDept,
      branch: nodeBranch,
      epf: nodeEpf,
      email: nodeEmail,
      phone: nodePhone,
      parentId: pId,
      children: childNodes,
    );
  }
}

class MobileOrganization extends StatefulWidget {
  const MobileOrganization({super.key});

  @override
  State<MobileOrganization> createState() => _MobileOrganizationState();
}

class _MobileOrganizationState extends State<MobileOrganization>
    with SingleTickerProviderStateMixin {
  // Toggle tab state: 0 = Your Team, 1 = Other Organization
  int _selectedTabIndex = 0;

  // Search & Filter state for "Other Organization" tab
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSearchFilter = 'All'; // 'All', 'Users', 'Branches'

  // Selected Team Node ID for line color highlighting
  String? _selectedTeamNodeId;
  String? _selectedTeamNodeName;

  final APIService _apiService = APIService();
  bool _loadingBackendData = false;

  // Root of the organizational hierarchy tree
  late OrgNode _rootOrgNode;
  List<OrgNode> _flatOrgMembers = [];

  @override
  void initState() {
    super.initState();
    _loadBackendOrgData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Automatically fetches or generates flow chart from backend response object structure
  Future<void> _loadBackendOrgData() async {
    setState(() {
      _loadingBackendData = true;
    });

    try {
      final response = await _apiService.getMyTeam();
      if (response['success'] == true && response['data'] != null) {
        final rawData = response['data'];
        if (rawData is Map<String, dynamic>) {
          _rootOrgNode = OrgNode.fromBackendJson(rawData);
        } else if (rawData is List && rawData.isNotEmpty) {
          _rootOrgNode = _buildTreeFromFlatList(rawData);
        } else {
          _initSampleOrgObject();
        }
      } else {
        _initSampleOrgObject();
      }
    } catch (_) {
      _initSampleOrgObject();
    } finally {
      _calculateHorizontalTreePositions(_rootOrgNode);
      _flatOrgMembers = [];
      _collectNodes(_rootOrgNode, _flatOrgMembers);
      if (mounted) {
        setState(() {
          _loadingBackendData = false;
        });
      }
    }
  }

  /// Constructs parent-child tree from a flat list of backend employee objects
  OrgNode _buildTreeFromFlatList(List<dynamic> list) {
    final Map<String, OrgNode> nodeMap = {};
    for (var item in list) {
      if (item is Map<String, dynamic>) {
        final node = OrgNode.fromBackendJson(item);
        nodeMap[node.id] = node;
      }
    }

    OrgNode? rootCandidate;
    for (var node in nodeMap.values) {
      if (node.parentId != null && nodeMap.containsKey(node.parentId)) {
        nodeMap[node.parentId]!.children.add(node);
      } else if (rootCandidate == null) {
        rootCandidate = node;
      }
    }

    return rootCandidate ?? _generateSampleBackendObject();
  }

  /// Sample Backend JSON Object mimicking real API tree response
  void _initSampleOrgObject() {
    final sampleBackendJsonObject = _generateSampleBackendObjectJson();
    _rootOrgNode = OrgNode.fromBackendJson(sampleBackendJsonObject);
  }

  OrgNode _generateSampleBackendObject() {
    return OrgNode.fromBackendJson(_generateSampleBackendObjectJson());
  }

  Map<String, dynamic> _generateSampleBackendObjectJson() {
    return {
      'id': 'root_1',
      'name': 'John Smith',
      'role': 'GM',
      'department': 'Executive Management',
      'branch': 'Head Office (HQ)',
      'epf': 'EPF-001',
      'email': 'john.smith@company.com',
      'phone': '+1 555-0001',
      'children': [
        {
          'id': 'dir_1',
          'name': 'Sarah Thompson',
          'role': 'Sales Director',
          'department': 'Sales & Marketing',
          'branch': 'Colombo Branch',
          'epf': 'EPF-301',
          'email': 'sarah.t@company.com',
          'phone': '+1 555-0301',
          'children': [
            {
              'id': 'mgr_1',
              'name': 'Michael Wilson',
              'role': 'Marketing Manager',
              'department': 'Marketing',
              'branch': 'Colombo Branch',
              'epf': 'EPF-201',
              'email': 'michael.w@company.com',
              'phone': '+1 555-0201',
              'children': [
                {
                  'id': 'spec_1',
                  'name': 'Jennifer Lee',
                  'role': 'Marketing Specialist',
                  'department': 'Marketing',
                  'branch': 'Colombo Branch',
                  'epf': 'EPF-101',
                  'email': 'jennifer.l@company.com',
                  'phone': '+1 555-0101',
                },
                {
                  'id': 'spec_2',
                  'name': 'Emily Davis',
                  'role': 'Marketing Specialist',
                  'department': 'Marketing',
                  'branch': 'Kandy Branch',
                  'epf': 'EPF-102',
                  'email': 'emily.d@company.com',
                  'phone': '+1 555-0102',
                },
              ],
            },
            {
              'id': 'mgr_2',
              'name': 'Jessica Martinez',
              'role': 'Sales Manager',
              'department': 'Sales',
              'branch': 'Galle Branch',
              'epf': 'EPF-202',
              'email': 'jessica.m@company.com',
              'phone': '+1 555-0202',
              'children': [
                {
                  'id': 'spec_3',
                  'name': 'Matthew Taylor',
                  'role': 'Sales Specialist',
                  'department': 'Sales',
                  'branch': 'Galle Branch',
                  'epf': 'EPF-103',
                  'email': 'matthew.t@company.com',
                  'phone': '+1 555-0103',
                },
                {
                  'id': 'spec_4',
                  'name': 'Samantha Clark',
                  'role': 'Sales Specialist',
                  'department': 'Sales',
                  'branch': 'Colombo Branch',
                  'epf': 'EPF-104',
                  'email': 'samantha.c@company.com',
                  'phone': '+1 555-0104',
                },
              ],
            },
          ],
        },
        {
          'id': 'dir_2',
          'name': 'Christopher Turner',
          'role': 'Operations Director',
          'department': 'Operations & Finance',
          'branch': 'Head Office (HQ)',
          'epf': 'EPF-302',
          'email': 'christopher.t@company.com',
          'phone': '+1 555-0302',
          'children': [
            {
              'id': 'mgr_3',
              'name': 'Robert Anderson',
              'role': 'Project Manager',
              'department': 'Operations',
              'branch': 'Kandy Branch',
              'epf': 'EPF-203',
              'email': 'robert.a@company.com',
              'phone': '+1 555-0203',
              'children': [
                {
                  'id': 'spec_5',
                  'name': 'Ron White',
                  'role': 'Business Analyst',
                  'department': 'Operations',
                  'branch': 'Kandy Branch',
                  'epf': 'EPF-105',
                  'email': 'ron.w@company.com',
                  'phone': '+1 555-0105',
                },
                {
                  'id': 'spec_6',
                  'name': 'Ava Clark',
                  'role': 'Data Analyst',
                  'department': 'Operations',
                  'branch': 'Colombo Branch',
                  'epf': 'EPF-106',
                  'email': 'ava.c@company.com',
                  'phone': '+1 555-0106',
                },
              ],
            },
            {
              'id': 'mgr_4',
              'name': 'Daniel Hernandez',
              'role': 'Finance Manager',
              'department': 'Finance',
              'branch': 'Head Office (HQ)',
              'epf': 'EPF-204',
              'email': 'daniel.h@company.com',
              'phone': '+1 555-0204',
              'children': [
                {
                  'id': 'spec_7',
                  'name': 'Erin Mitchell',
                  'role': 'Financial Analyst',
                  'department': 'Finance',
                  'branch': 'Head Office (HQ)',
                  'epf': 'EPF-107',
                  'email': 'erin.m@company.com',
                  'phone': '+1 555-0107',
                },
                {
                  'id': 'spec_8',
                  'name': 'Adrian Collins',
                  'role': 'Accounting Specialist',
                  'department': 'Finance',
                  'branch': 'Galle Branch',
                  'epf': 'EPF-108',
                  'email': 'adrian.c@company.com',
                  'phone': '+1 555-0108',
                },
              ],
            },
          ],
        },
      ],
    };
  }

  void _collectNodes(OrgNode node, List<OrgNode> list) {
    list.add(node);
    for (var child in node.children) {
      _collectNodes(child, list);
    }
  }

  /// Calculates positions for horizontal tree rendering
  void _calculateHorizontalTreePositions(OrgNode root) {
    const double cardWidth = 150.0;
    const double cardHeight = 58.0;
    const double horizontalGap = 70.0;
    const double verticalGap = 20.0;

    final List<OrgNode> leaves = [];
    void findLeaves(OrgNode node) {
      if (node.children.isEmpty) {
        leaves.add(node);
      } else {
        for (var child in node.children) {
          findLeaves(child);
        }
      }
    }

    findLeaves(root);

    double currentY = 30.0;
    for (var leaf in leaves) {
      leaf.y = currentY;
      currentY += cardHeight + verticalGap;
    }

    double assignInternalY(OrgNode node, int depth) {
      node.x = 30.0 + depth * (cardWidth + horizontalGap);
      if (node.children.isEmpty) {
        return node.y;
      }

      double sumY = 0;
      for (var child in node.children) {
        sumY += assignInternalY(child, depth + 1);
      }
      node.y = sumY / node.children.length;
      return node.y;
    }

    assignInternalY(root, 0);
  }

  bool _isDescendantOf(OrgNode current, String targetId, String ancestorId) {
    if (current.id == targetId) return false;
    OrgNode? target = _findNodeById(_rootOrgNode, targetId);
    if (target == null) return false;

    String? parentId = target.parentId;
    while (parentId != null) {
      if (parentId == ancestorId) return true;
      OrgNode? parent = _findNodeById(_rootOrgNode, parentId);
      parentId = parent?.parentId;
    }
    return false;
  }

  OrgNode? _findNodeById(OrgNode node, String id) {
    if (node.id == id) return node;
    for (var child in node.children) {
      final found = _findNodeById(child, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Tapping a node in flow chart:
  /// - End Users (leaf nodes with no children): Show ONLY "User Details" button!
  /// - Non-end users (with direct reports): Show BOTH "User Details" and "Select Team" buttons.
  void _onNodeTapped(OrgNode node) {
    final bool isEndUser = node.children.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: HRColors.orangeColor.withOpacity(0.15),
              child: Text(
                node.name.isNotEmpty ? node.name[0] : 'U',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: HRColors.orangeColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              node.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              node.role,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
        content: Text(
          isEndUser
              ? 'View organization member details:'
              : 'Select an action for this organization member:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          // Button 1: User Details
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEndUser ? HRColors.orangeColor : HRColors.white,
              foregroundColor: isEndUser ? Colors.white : HRColors.black,
              side: BorderSide(color: isEndUser ? HRColors.orangeColor : Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showUserDetailsModal(node);
            },
            icon: Icon(Icons.info_outline, size: 18, color: isEndUser ? Colors.white : HRColors.orangeColor),
            label: Text(AppLocalizations.of(context)!.userDetails, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          // Button 2: Select Team (ONLY shown for non-end users with children!)
          if (!isEndUser)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: HRColors.orangeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedTeamNodeId = node.id;
                  _selectedTeamNodeName = node.name;
                });
                DesignConfig.showTopToast(
                  context,
                  'Selected team: ${node.name}. Chart lines highlighted under user.',
                  background: Colors.green,
                );
              },
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.selectTeam, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  /// Show User Details Modal
  void _showUserDetailsModal(OrgNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: HRColors.orangeColor.withOpacity(0.15),
                  child: Text(
                    node.name.isNotEmpty ? node.name[0] : 'U',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: HRColors.orangeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: HRColors.black,
                        ),
                      ),
                      Text(
                        node.role,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (node.department != null || node.branch != null)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (node.department != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: HRColors.orangeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  node.department!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HRColors.orangeColor,
                                  ),
                                ),
                              ),
                            if (node.branch != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  node.branch!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_city_outlined, 'Branch', node.branch ?? 'Main Branch'),
            _buildDetailRow(Icons.badge_outlined, 'EPF Number', node.epf ?? 'N/A'),
            _buildDetailRow(Icons.email_outlined, 'Email', node.email ?? 'N/A'),
            _buildDetailRow(Icons.phone_outlined, 'Phone', node.phone ?? 'N/A'),
            _buildDetailRow(
              Icons.account_tree_outlined,
              'Direct Reports',
              '${node.children.length} members',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HRColors.orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HRColors.flavorIconBackgroundColor ?? Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.navigate_before,
                          color: HRColors.flavorIconBackgroundColor != null
                              ? HRColors.flavorIconColor
                              : HRColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Organization',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedTeamNodeName != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTeamNodeId = null;
                          _selectedTeamNodeName = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                      label: Text(AppLocalizations.of(context)!.resetLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Reduced border radius toggle menu (BorderRadius.circular(8) outer, circular(6) inner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? HRColors.orangeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Your Team',
                            style: TextStyle(
                              color: _selectedTabIndex == 0
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? HRColors.orangeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Other Organization',
                            style: TextStyle(
                              color: _selectedTabIndex == 1
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Active Tab Content
            Expanded(
              child: _loadingBackendData
                  ? const Center(child: CircularProgressIndicator())
                  : (_selectedTabIndex == 0
                      ? _buildYourTeamOrgChartView()
                      : _buildOtherOrganizationView()),
            ),
          ],
        ),
      ),
    );
  }

  /// View 1: Your Team (Horizontal Organizational Structure Flow Chart)
  Widget _buildYourTeamOrgChartView() {
    const double canvasWidth = 900.0;
    const double canvasHeight = 650.0;

    return Column(
      children: [
        if (_selectedTeamNodeName != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected Team: $_selectedTeamNodeName (lines under this user highlighted)',
                    style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 2.5,
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              color: Colors.white,
              child: Stack(
                children: [
                  // Layer 1: Custom Painter for Connecting Tree Lines
                  CustomPaint(
                    size: const Size(canvasWidth, canvasHeight),
                    painter: OrgChartPainter(
                      root: _rootOrgNode,
                      selectedTeamNodeId: _selectedTeamNodeId,
                    ),
                  ),
                  // Layer 2: Interactive Person Node Cards
                  ..._buildNodeWidgets(_rootOrgNode),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Flatten and build node card widgets positioned on canvas
  List<Widget> _buildNodeWidgets(OrgNode node) {
    final List<Widget> widgets = [];

    void traverse(OrgNode n) {
      bool isSelected = _selectedTeamNodeId == n.id;
      bool isInSelectedSubtree = false;
      if (_selectedTeamNodeId != null) {
        if (_selectedTeamNodeId == n.id ||
            _isDescendantOf(_rootOrgNode, n.id, _selectedTeamNodeId!)) {
          isInSelectedSubtree = true;
        }
      }

      widgets.add(
        Positioned(
          left: n.x,
          top: n.y,
          width: 150,
          height: 58,
          child: GestureDetector(
            onTap: () => _onNodeTapped(n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? HRColors.orangeColor
                      : (isInSelectedSubtree
                          ? Colors.blue
                          : Colors.grey.shade400),
                  width: isSelected || isInSelectedSubtree ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isSelected
                        ? HRColors.orangeColor
                        : (isInSelectedSubtree
                            ? Colors.blue
                            : Colors.blueGrey.shade100),
                    child: Text(
                      n.name.isNotEmpty ? n.name[0] : 'U',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected || isInSelectedSubtree
                            ? Colors.white
                            : Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          n.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? HRColors.orangeColor
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          n.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      for (var child in n.children) {
        traverse(child);
      }
    }

    traverse(node);
    return widgets;
  }

  /// View 2: Other Organization (Search user, branch, all)
  Widget _buildOtherOrganizationView() {
    final filtered = _flatOrgMembers.where((m) {
      // Apply search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = m.name.toLowerCase().contains(q);
        final matchRole = m.role.toLowerCase().contains(q);
        final matchDept = m.department?.toLowerCase().contains(q) ?? false;
        final matchBranch = m.branch?.toLowerCase().contains(q) ?? false;
        final matchEpf = m.epf?.toLowerCase().contains(q) ?? false;

        if (!matchName && !matchRole && !matchDept && !matchBranch && !matchEpf) {
          return false;
        }
      }

      // Apply category chip filter ('All', 'Users', 'Branches')
      if (_selectedSearchFilter == 'Users') {
        return m.children.isEmpty; // End-user individual members
      } else if (_selectedSearchFilter == 'Branches') {
        return m.branch != null && m.branch!.isNotEmpty;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // Name & Branch Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search user, branch, role or department...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13.5),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Filter chips: All | Users | Branches
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Users'),
              const SizedBox(width: 8),
              _buildFilterChip('Branches'),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Filtered Members List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No record found matching search',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final member = filtered[idx];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: HRColors.orangeColor.withOpacity(0.15),
                          child: Text(
                            member.name.isNotEmpty ? member.name[0] : 'U',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: HRColors.orangeColor,
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              member.role,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (member.department != null)
                                  Text(
                                    member.department!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: HRColors.orangeColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (member.department != null && member.branch != null)
                                  const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                if (member.branch != null)
                                  Text(
                                    member.branch!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.info_outline, color: HRColors.orangeColor),
                          onPressed: () => _showUserDetailsModal(member),
                        ),
                        onTap: () => _onNodeTapped(member),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedSearchFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSearchFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? HRColors.orangeColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for rendering horizontal tree connection lines
class OrgChartPainter extends CustomPainter {
  final OrgNode root;
  final String? selectedTeamNodeId;

  OrgChartPainter({
    required this.root,
    this.selectedTeamNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cardWidth = 150.0;
    const double cardHeight = 58.0;

    final Paint defaultPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint highlightedPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    void drawConnections(OrgNode parent) {
      final pRight = Offset(parent.x + cardWidth, parent.y + cardHeight / 2);

      for (var child in parent.children) {
        final cLeft = Offset(child.x, child.y + cardHeight / 2);

        // Check if this connection line is under selected user subtree
        bool isHighlighted = false;
        if (selectedTeamNodeId != null) {
          if (parent.id == selectedTeamNodeId ||
              _isNodeInSubtree(root, parent.id, selectedTeamNodeId!)) {
            isHighlighted = true;
          }
        }

        final paint = isHighlighted ? highlightedPaint : defaultPaint;

        // Orthogonal connecting line path (horizontal -> vertical -> horizontal)
        final midX = pRight.dx + (cLeft.dx - pRight.dx) / 2;
        final Path path = Path();
        path.moveTo(pRight.dx, pRight.dy);
        path.lineTo(midX, pRight.dy);
        path.lineTo(midX, cLeft.dy);
        path.lineTo(cLeft.dx, cLeft.dy);

        canvas.drawPath(path, paint);

        // Draw child connections recursively
        drawConnections(child);
      }
    }

    drawConnections(root);
  }

  bool _isNodeInSubtree(OrgNode current, String targetId, String ancestorId) {
    if (targetId == ancestorId) return true;
    OrgNode? ancestor = _findNode(current, ancestorId);
    if (ancestor == null) return false;
    return _findNode(ancestor, targetId) != null;
  }

  OrgNode? _findNode(OrgNode node, String id) {
    if (node.id == id) return node;
    for (var child in node.children) {
      final res = _findNode(child, id);
      if (res != null) return res;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant OrgChartPainter oldDelegate) {
    return oldDelegate.selectedTeamNodeId != selectedTeamNodeId ||
        oldDelegate.root != root;
  }
}
