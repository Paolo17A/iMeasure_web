import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/custom_text_field_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';

class ViewGeneratedOrderScreen extends ConsumerStatefulWidget {
  final String orderID;
  const ViewGeneratedOrderScreen({super.key, required this.orderID});

  @override
  ConsumerState<ViewGeneratedOrderScreen> createState() =>
      _ViewGeneratedOrderScreenState();
}

class _ViewGeneratedOrderScreenState
    extends ConsumerState<ViewGeneratedOrderScreen> {
  num width = 0;
  num height = 0;
  String glassType = '';
  String color = '';
  List<dynamic> mandatoryMap = [];
  List<dynamic> optionalMap = [];
  num windowOverallPrice = 0;

  //  WINDOW VARIABLES
  String windowName = '';

  final laborPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        if (!hasLoggedInUser()) {
          GoRouter.of(context).goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }
        ref.read(loadingProvider).toggleLoading(true);
        final orderDoc = await getThisOrderDoc(widget.orderID);
        final orderData = orderDoc.data() as Map<dynamic, dynamic>;
        String status = orderData[OrderFields.purchaseStatus];
        if (status != OrderStatuses.generated) {
          GoRouter.of(context).goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }
        width = orderData[OrderFields.width];
        height = orderData[OrderFields.height];
        glassType = orderData[OrderFields.glassType];
        color = orderData[OrderFields.color];
        mandatoryMap = orderData[OrderFields.mandatoryMap];
        optionalMap = orderData[OrderFields.optionalMap];
        windowOverallPrice = orderData[OrderFields.windowOverallPrice];

        //  Window Data
        String windowID = orderData[OrderFields.windowID];
        final windowDoc = await getThisWindowDoc(windowID);
        final windowData = windowDoc.data() as Map<dynamic, dynamic>;
        windowName = windowData[WindowFields.name];

        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting generated order: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.orders),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _backButton(),
                      horizontal5Percent(context,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _selectedDetails(),
                                _mandatoryBreakdownWidget(),
                                _orderLaborCost(),
                                setLaborPriceButton()
                              ])),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _backButton() {
    return all20Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.orders))
    ]));
  }

  Widget _selectedDetails() {
    return all10Pix(
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          quicksandWhiteBold('Inputted Window Details'),
          quicksandWhiteRegular('Window: $windowName'),
          quicksandWhiteRegular('Width: ${width.toStringAsFixed(1)} ft',
              fontSize: 12),
          quicksandWhiteRegular('Height: ${height.toStringAsFixed(1)} ft',
              fontSize: 12),
          quicksandWhiteRegular('Glass Type: $glassType', fontSize: 12),
          quicksandWhiteRegular('Color: $color', fontSize: 12),
          Gap(10),
        ]),
      ]),
    );
  }

  Widget _mandatoryBreakdownWidget() {
    return all10Pix(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        padding: EdgeInsets.all(5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          quicksandWhiteBold('Window Cost Breakdown'),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mandatoryMap
                  .toList()
                  .map((mapEntry) => orderBreakdownWidget(mapEntry))
                  .toList()),
          Gap(10),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: optionalMap
                  .toList()
                  .map((mapEntry) => orderBreakdownWidget(mapEntry))
                  .toList()),
          Divider(),
          quicksandWhiteBold(
              'Window Overall Price: PHP ${formatPrice(windowOverallPrice.toDouble())}',
              fontSize: 16)
        ]),
      ),
    );
  }

  Widget orderBreakdownWidget(Map<dynamic, dynamic> orderBreakdownMap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        quicksandWhiteRegular('${orderBreakdownMap[OrderBreakdownMap.field]}: ',
            fontSize: 14),
        quicksandWhiteRegular(
            ' PHP ${formatPrice(orderBreakdownMap[OrderBreakdownMap.breakdownPrice].toDouble())}',
            fontSize: 14),
      ],
    );
  }

  pw.Widget PDForderBreakdownWidget(Map<dynamic, dynamic> orderBreakdownMap) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('${orderBreakdownMap[OrderBreakdownMap.field]}: ',
            style: pw.TextStyle(fontSize: 14)),
        pw.Text(
            ' PHP ${formatPrice(orderBreakdownMap[OrderBreakdownMap.breakdownPrice].toDouble())}',
            style: pw.TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _orderLaborCost() {
    return vertical20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quicksandWhiteBold('Labor Cost'),
          CustomTextField(
              text: 'Labor Cost',
              controller: laborPriceController,
              fillColor: Colors.white,
              textInputType: TextInputType.number)
        ],
      ),
    );
  }

  Widget setLaborPriceButton() {
    return vertical20Pix(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () async => createPDF(),
              child: all10Pix(child: quicksandWhiteBold('SET LABOR COST'))),
        ],
      ),
    );
  }

  Future createPDF() async {
    if (laborPriceController.text.isEmpty ||
        double.tryParse(laborPriceController.text) == null ||
        double.parse(laborPriceController.text) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please input a valid labor cost.')));
      return;
    }
    final document = pw.Document();
    document.addPage(pw.Page(
        build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Inputted Window Details'),
                          pw.Text('Window: $windowName'),
                          pw.Text('Width: ${width.toStringAsFixed(1)} ft',
                              style: pw.TextStyle(fontSize: 14)),
                          pw.Text('Height: ${height.toStringAsFixed(1)} ft',
                              style: pw.TextStyle(fontSize: 14)),
                          pw.Text('Glass Type: $glassType',
                              style: pw.TextStyle(fontSize: 14)),
                          pw.Text('Color: $color',
                              style: pw.TextStyle(fontSize: 14)),
                          pw.SizedBox(height: 10),
                        ]),
                  ]),
                  pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    padding: pw.EdgeInsets.all(5),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Window Cost Breakdown',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: mandatoryMap
                                  .map((mapEntry) =>
                                      PDForderBreakdownWidget(mapEntry))
                                  .toList()),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: optionalMap
                                  .map((mapEntry) =>
                                      PDForderBreakdownWidget(mapEntry))
                                  .toList()),
                          pw.Text(
                              'Window Overall Price: PHP ${formatPrice(windowOverallPrice.toDouble())}',
                              style: pw.TextStyle(fontSize: 14)),
                          pw.SizedBox(height: 10),
                          pw.Text(
                              'Labor Cost: PHP ${formatPrice(double.parse(laborPriceController.text))}'),
                        ]),
                  ),
                  pw.Text(
                      'Total Price: PHP ${formatPrice(windowOverallPrice.toDouble() + double.parse(laborPriceController.text))}',
                      style: pw.TextStyle(fontSize: 18)),
                ])));

    Uint8List savedPDF = await document.save();
    uploadQuotationPDF(context, ref,
        orderID: widget.orderID,
        pdfBytes: savedPDF,
        laborPrice: double.parse(laborPriceController.text));

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('CREATED PDF')));
  }
}
