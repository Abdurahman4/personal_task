import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_task/screens/add_task_screen.dart';
import 'package:personal_task/screens/login_screen.dart';
import 'package:personal_task/screens/statistics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_task/services/notification_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String selectedFilter = 'All';
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in!")),
      );
    }

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Task List...");
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("Task List | Unknown User");
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final userName = userData?["username"] ?? "Unknown";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Task List",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    "Hello، $userName 👋",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Statistics'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StatisticsPage()),
                  );
                },
              ),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No tasks"));
            }

            final tasks = snapshot.data!.docs;

            // تصفية المهام حسب البحث والفلاتر
            final filteredTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              if (selectedFilter != 'All' && status != selectedFilter) {
                return false;
              }

              if (_searchQuery.isNotEmpty &&
                  !data['title']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) {
                return false;
              }
              return true;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have ${filteredTasks.length} Tasks now',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedFilter,
                        items: ['All', 'completed', 'pending', 'canceled']
                            .map((filter) => DropdownMenuItem<String>(
                                  value: filter,
                                  child: Text(filter),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedFilter = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('yyyy/MM/dd').format(DateTime.now()),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Search tasks",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final data = task.data() as Map<String, dynamic>;

                      final title = data['title'] ?? "No Title";
                      final taskId = task.id;
                      final status = data['status'] ?? 'Pending';

                      DateTime? dueDate;
                      String dueDateText = "No Due Date";

                      final dueDateRaw = data['dueDate'];
                      if (dueDateRaw != null) {
                        if (dueDateRaw is Timestamp) {
                          dueDate = dueDateRaw.toDate();
                        } else if (dueDateRaw is int) {
                          dueDate =
                              DateTime.fromMillisecondsSinceEpoch(dueDateRaw);
                        }

                        if (dueDate != null) {
                          final today = DateTime.now();
                          final daysDiff = DateTime(
                                  dueDate.year, dueDate.month, dueDate.day)
                              .difference(
                                  DateTime(today.year, today.month, today.day))
                              .inDays;

                          if (status == 'completed') {
                            dueDateText = "✅ completed";
                          } else if (status == 'canceled') {
                            dueDateText = "❌ canceled";
                          } else if (daysDiff < 0) {
                            dueDateText = "❗ Late by ${-daysDiff} day(s)";
                          } else if (daysDiff == 0) {
                            dueDateText = "Due Today!";
                          } else if (daysDiff == 1) {
                            dueDateText = "Due Tomorrow";
                          } else {
                            dueDateText = "$daysDiff days left";
                          }
                        }
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: status == 'completed'
                                      ? Colors.green
                                      : status == 'canceled'
                                          ? Colors.grey
                                          : (dueDate != null &&
                                                  dueDate
                                                      .isBefore(DateTime.now()))
                                              ? Colors.red
                                              : Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dueDateText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration: status == 'Completed'
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dueDate != null
                                          ? DateFormat('EEEE d MMM yyyy')
                                              .format(dueDate)
                                          : "No Due Date",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('tasks')
                                          .doc(taskId)
                                          .update({'status': value});
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                          value: 'completed',
                                          child: Text("Mark as completed")),
                                      const PopupMenuItem(
                                          value: 'pending',
                                          child: Text("Mark as pending")),
                                      const PopupMenuItem(
                                          value: 'canceled',
                                          child: Text("Mark as canceled")),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editTask(
                                        context, user.uid, taskId, title),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _confirmDelete(
                                        context, user.uid, taskId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTaskScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String userId, String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Warning!"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('tasks')
                    .doc(taskId)
                    .delete();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editTask(
      BuildContext context, String userId, String taskId, String oldTitle) {
    final TextEditingController editController =
        TextEditingController(text: oldTitle);
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Edit Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  decoration: const InputDecoration(labelText: "Task Title"),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Due Date:"),
                    Text(
                      selectedDate != null
                          ? DateFormat('yyyy/MM/dd').format(selectedDate!)
                          : "No Date Selected",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: const Text("Pick Date"),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.blue)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newTitle = editController.text.trim();
                  if (newTitle.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Task title can't be empty")),
                    );
                    return;
                  }

                  final taskRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('tasks')
                      .doc(taskId);

                  Map<String, dynamic> updateData = {'title': newTitle};

                  if (selectedDate != null) {
                    updateData['dueDate'] = Timestamp.fromDate(selectedDate!);
                  } else {
                    updateData['dueDate'] = null;
                  }

                  await taskRef.update(updateData);

                  await NotificationService().onTaskEdited(
                      taskId, newTitle, selectedDate ?? DateTime.now());

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }
}
