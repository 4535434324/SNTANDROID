import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class Oplata extends StatefulWidget {
  @override
  _OplataState createState() => _OplataState();
}

class _OplataState extends State<Oplata> {
  List<Map<String, dynamic>> gardeningCards = [];
  List<Map<String, dynamic>> paymentData = [];
  String? selectedGardener;
  Map<String, dynamic>? selectedPaymentCode;
  late List<Map<String, dynamic>> contributionsRates;

  @override
  void initState() {
    super.initState();
    fetchGardeningCards();
    fetchPaymentData();
    fetchContributionsRates();
  }

  Future<void> fetchGardeningCards() async {
    final response =
        await http.get(Uri.parse('http://217.25.90.41/v1/gardeningcards'));

    if (response.statusCode == 200) {
      setState(() {
        gardeningCards =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Failed to load gardening cards');
    }
  }

  Future<void> fetchPaymentData() async {
    final response =
        await http.get(Uri.parse('http://217.25.90.41/v1/Paymentofbills'));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allPaymentData =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      setState(() {
        paymentData = allPaymentData;
      });
    } else {
      print('Failed to load payment data');
    }
  }

  Future<void> fetchContributionsRates() async {
    final response = await http.get(Uri.parse('http://217.25.90.41/v1/Contributions_rate'));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> rates =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      setState(() {
        contributionsRates = rates;
      });
    } else {
      print('Failed to load contribution rates');
    }
  }

  String getGardeningNumber(int gardeningId) {
    var gardeningCard = gardeningCards.firstWhere(
        (card) => card['idКарточки_Садовода'] == gardeningId,
        orElse: () => {});
    return gardeningCard['номер_садовода'] ?? '';
  }

  List<Map<String, dynamic>> getFilteredPaymentData() {
    if (selectedGardener == null) {
      return paymentData;
    } else {
      return paymentData
          .where((payment) =>
              getGardeningNumber(payment['iD_Koд_садовода']) ==
              selectedGardener)
          .toList();
    }
  }

  void navigateToAddPaymentPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddPaymentPage(
                gardeningCards: gardeningCards,
                contributionsRates: contributionsRates,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Страница оплаты'),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: navigateToAddPaymentPage,
            child: Text('Добавить оплату'),
          ),
          SizedBox(height: 20),
          DropdownButton<String>(
            hint: Text('Выберите садовода'),
            value: selectedGardener,
            items: gardeningCards.map((gardener) {
              return DropdownMenuItem<String>(
                value: gardener['номер_садовода'],
                child: Text(gardener['номер_садовода'] ?? ''),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedGardener = newValue;
              });
            },
          ),
          SizedBox(height: 20),
          Expanded(
  child: Scrollbar(
    thumbVisibility: true,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text('ID оплаты')),
            DataColumn(label: Text('Номер садовода')),
            DataColumn(label: Text('Сумма оплаты')),
            DataColumn(label: Text('Дата оплаты')),
            DataColumn(label: Text('Статус')),
          ],
          rows: getFilteredPaymentData().map((payment) {
            var gardeningNumber =
                getGardeningNumber(payment['iD_Koд_садовода']);
            return DataRow(cells: [
              DataCell(
                  Text(payment['iD_Оплата_Взноса']?.toString() ?? '')),
              DataCell(Text(gardeningNumber)),
              DataCell(Text(payment['к_оплате']?.toString() ?? '')),
              DataCell(Text(payment['дата_и_время_оплаты'] ?? '')),
              DataCell(Text(payment['состояние_оплаты'] ?? '')),
            ]);
          }).toList(),
        ),
      ),
    ),
  ),
),
        ],
      ),
    );
  }
}

class AddPaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> gardeningCards;
  final List<Map<String, dynamic>> contributionsRates;

  const AddPaymentPage(
      {Key? key, required this.gardeningCards, required this.contributionsRates})
      : super(key: key);

  @override
  _AddPaymentPageState createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  late String selectedGardener;
  late Map<String, dynamic> selectedPaymentCode;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.gardeningCards.isNotEmpty) {
      selectedGardener = widget.gardeningCards.first['номер_садовода'] ?? '';
    }
    if (widget.contributionsRates.isNotEmpty) {
      selectedPaymentCode = widget.contributionsRates.first;
    }
  }

  Future<void> addPayment() async {
    int paymentId = Random().nextInt(10000);

    Map<String, dynamic> paymentData = {
      'ID_Оплата_Взноса': paymentId,
      'ID_Koд_садовода': int.parse(selectedGardener),
      'ID_Код_взноса': selectedPaymentCode['iD_взноса'],
      'Состояние_оплаты': 'Оплачено',
      'К_оплате': amountController.text,
      'Дата_и_время_оплаты': dateController.text,
    };

    String jsonData = jsonEncode(paymentData);

    try {
      final response = await http.post(
        Uri.parse('http://217.25.90.41/v1/Paymentofbills'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonData,
      );
      if (response.statusCode == 200) {
        print('Данные успешно отправлены на сервер');
      } else {
        print('Ошибка при отправке данных на сервер');
      }
    } catch (error) {
      print('Произошла ошибка при отправке данных: $error');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавление оплаты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Выберите садовода'),
              value: selectedGardener,
              items: widget.gardeningCards.map((gardener) {
                return DropdownMenuItem<String>(
                  value: gardener['номер_садовода'],
                  child: Text(gardener['номер_садовода'] ?? ''),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedGardener = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(labelText: 'Выберите взнос'),
              value: selectedPaymentCode,
              items: widget.contributionsRates.map((payment) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: payment,
                  child: Text(payment['наменование_взноса'] ?? ''),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? newValue) {
                setState(() {
                  selectedPaymentCode = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Сумма оплаты'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Дата оплаты'),
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  dateController.text = pickedDate.toString().substring(0, 10);
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addPayment,
              child: Text('Добавить данные'),
            ),
          ],
        ),
      ),
    );
  }
}