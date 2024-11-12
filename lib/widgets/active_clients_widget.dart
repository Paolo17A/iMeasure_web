import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:intl/intl.dart';

import '../utils/color_util.dart';
import 'custom_miscellaneous_widgets.dart';

class ActiveClientsWidget extends StatefulWidget {
  const ActiveClientsWidget({super.key});

  @override
  State<ActiveClientsWidget> createState() => _ActiveClientsScreenWidget();
}

class _ActiveClientsScreenWidget extends State<ActiveClientsWidget> {
  bool _isLoading = true;
  List<DocumentSnapshot> activeClients = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        final clients = await getAllClientDocs();
        activeClients = clients.where((client) {
          final clientData = client.data() as Map<dynamic, dynamic>;
          return clientData.containsKey(UserFields.lastActive) &&
              isTimeDifferenceLessThan12Hours(
                  (clientData[UserFields.lastActive] as Timestamp).toDate(),
                  DateTime.now());
        }).toList();

        // Sort the activeStudents based on lastLoginTime (most active to least active)
        activeClients.sort((a, b) {
          DateTime timeA = ((a.data()
                  as Map<dynamic, dynamic>)[UserFields.lastActive] as Timestamp)
              .toDate();
          DateTime timeB = ((b.data()
                  as Map<dynamic, dynamic>)[UserFields.lastActive] as Timestamp)
              .toDate();
          return timeB.compareTo(timeA); // Compare in descending order
        });
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting active clients: $error')));
      }
    });
  }

  bool isTimeDifferenceLessThan12Hours(DateTime dateTime1, DateTime dateTime2) {
    // Calculate the difference between the two DateTimes
    Duration difference = dateTime2.difference(dateTime1);

    // Check if the absolute difference in hours is less than 12
    return difference.inHours.abs() < 12;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Column(
        children: [
          _activeClientHeader(),
          switchedLoadingContainer(
              _isLoading,
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: activeClients.isEmpty
                      ? _noActiveClientsWidget()
                      : _activeClientsDisplayWidget()))
        ],
      ),
    );
  }

  Widget _activeClientHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const CircleAvatar(backgroundColor: Colors.green, radius: 5),
        quicksandWhiteBold('ACTIVE CUSTOMERS', textAlign: TextAlign.center),
      ],
    );
  }

  Widget _noActiveClientsWidget() {
    return Center(
      child: quicksandWhiteBold('THERE ARE CURRENTLY NO ACTIVE CUSTOMERS',
          textAlign: TextAlign.center),
    );
  }

  Widget _activeClientsDisplayWidget() {
    return SingleChildScrollView(
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: activeClients.length,
          itemBuilder: (context, index) {
            final studentData =
                activeClients[index].data() as Map<dynamic, dynamic>;
            String imageURL = studentData['profileImageURL'];
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Container(
                    decoration: BoxDecoration(
                        color: CustomColors.forestGreen,
                        border: Border.all(color: Colors.black)),
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _profileImageWidget(imageURL),
                              _profileDataWidget(studentData)
                            ]))));
          }),
    );
  }

  Widget _profileImageWidget(String imageURL) {
    if (imageURL.isNotEmpty) {
      return CircleAvatar(
          backgroundColor: Colors.white,
          radius: 40,
          backgroundImage: NetworkImage(imageURL));
    } else {
      return CircleAvatar(
          backgroundColor: CustomColors.forestGreen.withOpacity(0.5),
          radius: 40,
          child: const Icon(
            Icons.person,
            color: CustomColors.forestGreen,
          ));
    }
  }

  Widget _profileDataWidget(Map<dynamic, dynamic> studentData) {
    return Center(
      child: Column(children: [
        quicksandWhiteBold(
            '${studentData[UserFields.firstName]} ${studentData[UserFields.lastName]}',
            fontSize: 14),
        quicksandWhiteBold('Last Login:',
            textAlign: TextAlign.center, fontSize: 14),
        quicksandWhiteBold(
            DateFormat('dd MMM yyyy hh:mm:ss a').format(
                (studentData[UserFields.lastActive] as Timestamp).toDate()),
            fontSize: 14,
            textAlign: TextAlign.center),
      ]),
    );
  }
}
