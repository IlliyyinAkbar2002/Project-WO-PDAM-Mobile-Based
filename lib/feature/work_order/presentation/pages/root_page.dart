import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/assignee_page/assignee_work_order_page.dart';
import 'package:project_mobile_pdam/feature/work_order/presentation/pages/assigner_page/assigner_work_order_page.dart';

List<int> picIdList = [1, 2, 3];

List<int> userIdList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends AppStatePage<RootPage> {
  int picId = 0;
  int userId = 0;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Root Page')),
      body: Center(
        child: Column(
          children: [
            _buildDropdownPicId(),
            GestureDetector(
              onTap: () {
                if (picId == 0) {
                  AppSnackbar.showError('Please select a PIC ID');
                  print(picId);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AssignerWorkOrderPage(picId: picId);
                    },
                  ),
                );
              },
              child: Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Pengajuan',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            _buildDropdownUserId(),
            GestureDetector(
              onTap: () {
                if (userId == 0) {
                  AppSnackbar.showError('Please select a User ID');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AssigneeWorkOrderPage(userId: userId);
                    },
                  ),
                );
              },
              child: Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Penugasan',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPicId() {
    return DropdownButtonFormField(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: InputDecoration(
        hintText: 'PIC ID',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      items: picIdList
          .map((pic) => DropdownMenuItem(value: pic, child: Text('PIC $pic')))
          .toList(),
      onChanged: (value) {
        setState(() {
          picId = value!;
        });
      },
    );
  }

  Widget _buildDropdownUserId() {
    return DropdownButtonFormField(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: InputDecoration(
        hintText: 'User ID',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      items: userIdList
          .map(
            (user) => DropdownMenuItem(value: user, child: Text('User $user')),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          userId = value!;
        });
      },
    );
  }
}
