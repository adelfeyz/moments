import 'package:flutter/material.dart';
import 'create_memory_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isGridView = false;

  final List<Map<String, dynamic>> folders = [
    {
      'name': 'Summer Vacation 2024',
      'icon': Icons.beach_access,
    },
    {
      'name': 'Birthday Celebrations',
      'icon': Icons.cake,
    },
    {
      'name': 'Graduation Day',
      'icon': Icons.school,
    },
    {
      'name': 'Family Reunions',
      'icon': Icons.family_restroom,
    },
    {
      'name': 'Road Trips',
      'icon': Icons.directions_car,
    },
    {
      'name': 'Special Moments',
      'icon': Icons.favorite,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moments',
                  style: TextStyle(color: Color.fromARGB(255, 6, 154, 102), fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color.fromARGB(255, 6, 154, 102)),
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
              onTap: () => Navigator.pushReplacementNamed(context, '/intro'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: isGridView
            ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: folders.length,
                itemBuilder: (ctx, i) => Card(
                  child: InkWell(
                    onTap: () {
                      // TODO: navigate into folder
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          folders[i]['icon'],
                          size: 48,
                          color: const Color.fromARGB(255, 6, 154, 102),
                        ),
                        SizedBox(height: 8),
                        Text(
                          folders[i]['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: folders.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    leading: Icon(
                      folders[i]['icon'],
                      color: const Color.fromARGB(255, 6, 154, 102),
                    ),
                    title: Text(folders[i]['name']),
                    onTap: () {
                      // TODO: navigate into folder
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMemoryPage()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 6, 154, 102),
        child: Icon(Icons.add),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
