import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../config/themes.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _liveJobs = [];
  bool _isLoadingLive = false;
  String _searchQuery = 'Software Engineer India';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLiveJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveJobs() async {
    setState(() => _isLoadingLive = true);
    final apiKey = dotenv.env['JSEARCH_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      setState(() {
        _liveJobs = _mockJobs();
        _isLoadingLive = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://jsearch.p.rapidapi.com/search?query=${Uri.encodeComponent(_searchQuery)}&num_pages=1'),
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'jsearch.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobs = (data['data'] as List?)?.take(12).map((j) => {
              'title': j['job_title'] ?? '',
              'company': j['employer_name'] ?? '',
              'location':
                  j['job_city'] ?? j['job_country'] ?? 'Remote',
              'type': j['job_employment_type'] ?? 'Full Time',
              'url': j['job_apply_link'] ?? '',
              'isRemote': j['job_is_remote'] ?? false,
              'description':
                  (j['job_description'] ?? '').toString().length > 100
                      ? j['job_description'].toString().substring(0, 100) + '...'
                      : j['job_description'] ?? '',
            }).toList() ?? [];

        setState(() {
          _liveJobs = List<Map<String, dynamic>>.from(jobs);
          _isLoadingLive = false;
        });
      } else {
        setState(() {
          _liveJobs = _mockJobs();
          _isLoadingLive = false;
        });
      }
    } catch (e) {
      setState(() {
        _liveJobs = _mockJobs();
        _isLoadingLive = false;
      });
    }
  }

  List<Map<String, dynamic>> _mockJobs() => [
        {
          'title': 'Software Engineer',
          'company': 'TCS',
          'location': 'Bangalore',
          'type': 'Full Time',
          'url': '',
          'isRemote': false,
          'description': 'Join our growing engineering team...',
        },
        {
          'title': 'Data Analyst',
          'company': 'Infosys',
          'location': 'Hyderabad',
          'type': 'Full Time',
          'url': '',
          'isRemote': false,
          'description': 'Analyse business data and drive insights...',
        },
        {
          'title': 'Python Developer',
          'company': 'Wipro',
          'location': 'Remote',
          'type': 'Full Time',
          'url': '',
          'isRemote': true,
          'description': 'Build scalable backend systems...',
        },
        {
          'title': 'ML Intern',
          'company': 'Zoho',
          'location': 'Chennai',
          'type': 'Internship',
          'url': '',
          'isRemote': false,
          'description': 'Work on production ML models...',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightMuted,
          tabs: const [
            Tab(text: 'Campus Jobs'),
            Tab(text: 'Live Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CampusJobsTab(),
          _LiveJobsTab(
            jobs: _liveJobs,
            isLoading: _isLoadingLive,
            searchCtrl: _searchCtrl,
            onSearch: () {
              _searchQuery = _searchCtrl.text.trim().isNotEmpty
                  ? _searchCtrl.text.trim()
                  : 'Software Engineer India';
              _fetchLiveJobs();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Campus Jobs ──────────────────────────────────
class _CampusJobsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('postedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline_rounded,
                    size: 64, color: AppColors.lightMuted),
                SizedBox(height: 16),
                Text('No jobs posted yet',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Recruiters will post jobs here',
                    style: TextStyle(
                        color: AppColors.lightMuted,
                        fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final data = snapshot.data!.docs[i].data()
                as Map<String, dynamic>;
            final jobId = snapshot.data!.docs[i].id;
            return _CampusJobCard(jobId: jobId, data: data)
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 80))
                .slideY(begin: 0.1);
          },
        );
      },
    );
  }
}

class _CampusJobCard extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> data;
  const _CampusJobCard({required this.jobId, required this.data});

  @override
  Widget build(BuildContext context) {
    final skills =
        List<String>.from(data['requiredSkills'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? '',
                        style: const TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(
                        '${data['company']} · ${data['location']}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      AppColors.recruiterColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['package'] ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.recruiterColor),
                ),
              ),
            ],
          ),

          if (skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills
                  .take(4)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Text('CGPA ≥ ${data['minCgpa'] ?? 0}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightMuted)),
              const Spacer(),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () => _applyDialog(context, jobId,
                      data['title'] ?? ''),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16)),
                  child: const Text('Apply',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyDialog(
      BuildContext context, String jobId, String jobTitle) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ApplyDialog(
          jobId: jobId, jobTitle: jobTitle),
    );
  }
}

class _ApplyDialog extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  const _ApplyDialog(
      {required this.jobId, required this.jobTitle});

  @override
  State<_ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<_ApplyDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Apply for ${widget.jobTitle}',
          style: const TextStyle(
              fontFamily: 'Syne', fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 10),
          TextField(
              controller: _emailCtrl,
              decoration:
                  const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(
            controller: _whyCtrl,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Why this role?'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () async {
            setState(() => _isSubmitting = true);
            await FirebaseFirestore.instance
                .collection('applications')
                .add({
              'jobId': widget.jobId,
              'jobTitle': widget.jobTitle,
              'studentName': _nameCtrl.text.trim(),
              'studentEmail': _emailCtrl.text.trim(),
              'whyRole': _whyCtrl.text.trim(),
              'status': 'pending',
              'appliedAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Application submitted!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            }
          },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}

// ─── Live Jobs Tab ────────────────────────────────
class _LiveJobsTab extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final bool isLoading;
  final TextEditingController searchCtrl;
  final VoidCallback onSearch;

  const _LiveJobsTab({
    required this.jobs,
    required this.isLoading,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Data Analyst Bangalore',
                    prefixIcon:
                        const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14)),
                child:
                    const Icon(Icons.search_rounded, size: 20),
              ),
            ],
          ),
        ),

        if (isLoading)
          const Expanded(
              child:
                  Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: jobs.length,
              itemBuilder: (context, i) {
                final job = jobs[i];
                return _LiveJobCard(job: job)
                    .animate()
                    .fadeIn(
                        delay:
                            Duration(milliseconds: i * 80))
                    .slideY(begin: 0.1);
              },
            ),
          ),
      ],
    );
  }
}

class _LiveJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _LiveJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job['title'] ?? '',
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              if (job['isRemote'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Remote',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${job['company']} · ${job['location']}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.lightMuted)),
          const SizedBox(height: 8),
          Text(job['description'] ?? '',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightMuted,
                  height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(job['type'] ?? 'Full Time',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary)),
              ),
              const Spacer(),
              if (job['url'] != null &&
                  job['url'].toString().isNotEmpty)
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14)),
                    child: const Text('Apply →',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
