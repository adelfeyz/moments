import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models/moment.dart';
import 'create_memory_page.dart';
import 'moment_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/token_storage_service.dart';
import 'login_page.dart';
import 'dart:io';
import 'timeline_page.dart'; // add this import

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool isGridView = true;

  Future<void> _refreshMoments() async {
    // This will force the FutureProvider to reload
    await ref.read(syncServiceProvider).pullFromServer();
    ref.refresh(momentsProvider);
    // Optionally, you can await the new data:
    await ref.read(momentsProvider.future);
  }

  Future<void> _logout() async {
    Navigator.of(context).pop(); // close drawer
    try {
      await TokenStorageService.clearTokens();
      // Attempt cognito sign out but ignore errors
      try {
        await Amplify.Auth.signOut();
      } catch (e) {
        debugPrint('Error during signOut: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  Future<void> _testApiCall() async {
    final syncService = ref.read(syncServiceProvider);

    if (syncService.isSyncing) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync already in progress…')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting sync…')),
    );

    await syncService.syncMoments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync finished.')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when coming back to this page
    _refreshMoments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFEEF2FF), // Left color
              Color(0xFFEDE9FE), // Right color
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF3730A3)),
              title: Text(
                'Moments',
                style: GoogleFonts.inter(
                  color: Color(0xFF3730A3),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
                  color: Color(0xFF3730A3),
                  onPressed: () {
                    setState(() {
                      isGridView = !isGridView;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  color: const Color(0xFF3730A3),
                  tooltip: 'Test API',
                  onPressed: _testApiCall,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMoments,
                child: Consumer(
                  builder: (context, ref, _) {
                    final momentsAsync = ref.watch(momentsProvider);
                    return momentsAsync.when(
                      data: (moments) {
                        if (moments.isEmpty) {
                          return const Center(child: Text('No moments yet. Tap "+" to create one.'));
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: isGridView
                              ? GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: moments.length,
                                  itemBuilder: (ctx, i) => _MomentTile(moment: moments[i], isGrid: true),
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: moments.length,
                                  itemBuilder: (ctx, i) => _MomentTile(moment: moments[i]),
                                ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4F46E5)),
              child: Text('Moments Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => /* push settings */ null,
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMemoryPage()),
          );
        },
        backgroundColor: const Color(0xFF3730A3),
        child: Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TimelinePage()),
            );
          }
          // TODO: handle Settings (index == 2) and others
        },
      ),
    );
  }
}

class _MomentTile extends StatelessWidget {
  final Moment moment;
  final bool isGrid;

  const _MomentTile({required this.moment, this.isGrid = false, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = moment.title ?? 'Untitled';
    final dateStr = moment.createdAt != null
        ? '${moment.createdAt!.toLocal().toString().split(' ').first}'
        : '';

    final imageWidget = Container(
      width: double.infinity,
      height: isGrid ? 120 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        image: moment.imagePath != null && moment.imagePath!.isNotEmpty && !moment.imagePath!.startsWith('assets/')
            ? DecorationImage(
                image: FileImage(File(moment.imagePath!)),
                fit: BoxFit.cover,
              )
            : const DecorationImage(
                image: AssetImage('assets/images/santorini.jpg'),
                fit: BoxFit.cover,
              ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.mic,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );

    if (!isGrid) {
      return Card(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              decoration: imageWidget.decoration,
              child: imageWidget.child,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3730A3),
            ),
          ),
          subtitle: Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateMemoryPage(moment: moment)),
            );
          },
        ),
      );
    } else {
      return SizedBox(
        height: 300,
        child: Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateMemoryPage(moment: moment)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    height: 105,
                    decoration: imageWidget.decoration,
                    child: imageWidget.child,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
