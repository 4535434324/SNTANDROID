import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Olata.dart';

class Osnova extends StatefulWidget {
  @override
  _OsnovaState createState() => _OsnovaState();
}

class _OsnovaState extends State<Osnova> {
  List<Map<String, dynamic>> gardeningCards = [];
  List<Map<String, dynamic>> paymentData = [];
  List<Map<String, dynamic>> contributionRates = [];

  @override
  void initState() {
    super.initState();
    fetchGardeningCards();
    fetchContributionRates();
  }

  Future<void> fetchGardeningCards() async {
    final response = await http.get(Uri.parse('http://217.25.90.41/v1/gardeningcards'));

    if (response.statusCode == 200) {
      setState(() {
        gardeningCards = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Failed to load gardening cards');
    }
  }

  Future<void> fetchPaymentData(int gardenerId) async {
    final response = await http.get(Uri.parse('http://217.25.90.41/v1/Paymentofbills?gardenerId=$gardenerId'));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> allPaymentData = List<Map<String, dynamic>>.from(jsonDecode(response.body));

      setState(() {
        paymentData = allPaymentData.where((payment) => payment['iD_Koд_садовода'] == gardenerId).toList();
      });
    } else {
      print('Failed to load payment data');
    }
  }

  Future<void> fetchContributionRates() async {
    final response = await http.get(Uri.parse('http://217.25.90.41/v1/Contributions_rate'));

    if (response.statusCode == 200) {
      setState(() {
        contributionRates = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Failed to load contribution rates');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Садовники'),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Oplata()),
                );
              },
              child: Text('Оплата'),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: gardeningCards.length,
        itemBuilder: (context, index) {
          final card = gardeningCards[index];
          return ListTile(
            title: Text(
                '${card['idКарточки_Садовода']} - ${card['номер_садовода']}: ${card['фамилия_садовода']} ${card['имя_содовода']} ${card['отчество_садовода']}'),
            subtitle: Text(
                'Участок: ${card['код_Улица_участка_садовода']}-${card['номер_участка_садовода']}'),
            trailing: ElevatedButton(
              onPressed: () async {
                await fetchPaymentData(card['idКарточки_Садовода'] ?? 0);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DetailPage(
                          gardeningCard: card,
                          paymentData: paymentData,
                          contributionRates: contributionRates)),
                );
              },
              child: Text('Подробнее'),
            ),
          );
        },
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> gardeningCard;
  final List<Map<String, dynamic>> paymentData;
  final List<Map<String, dynamic>> contributionRates;

  const DetailPage(
      {Key? key,
      required this.gardeningCard,
      required this.paymentData,
      required this.contributionRates})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подробная информация о садовнике'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('id садовода: ${gardeningCard['idКарточки_Садовода']}'),
              Divider(),
              Text('Номер садовода: ${gardeningCard['номер_садовода']}'),
              Divider(),
              Text('Фамилия садовода: ${gardeningCard['фамилия_садовода']}'),
              Divider(),
              Text('Имя садовода: ${gardeningCard['имя_содовода']}'),
              Divider(),
              Text('Отчество садовода: ${gardeningCard['отчество_садовода']}'),
              Divider(),
              Text(
                  'Серия и номер паспорта садовода: ${gardeningCard['серия_номер_паспорта_садовода']}'),
              Divider(),
              Text(
                  'Код улицы участка садовода: ${gardeningCard['код_Улица_участка_садовода']}'),
              Divider(),
              Text(
                  'Номер участка садовода: ${gardeningCard['номер_участка_садовода']}'),
              Divider(),
              Text(
                  'Код сотки участка садовода: ${gardeningCard['код_Сотак_участка_садовода']}'),
              Divider(),
              Text('Книжка выдана: ${gardeningCard['книжка_выдана']}'),
              Divider(),
              Text('Дата рождения: ${gardeningCard['дата_рождения']}'),
              Divider(),
              Text('Кадастровый номер: ${gardeningCard['кадастровый_номер']}'),
              Divider(),
              Text('ЕГРП номер: ${gardeningCard['егрпНомер']}'),
              Divider(),
              Text(
                  'Год принятия в товарищество: ${gardeningCard['год_принятия_в_товарищество']}'),
              Divider(),
              Text(
                  'Номер телефона садовода: ${gardeningCard['номер_телефона_садовода']}'),
              SizedBox(height: 20),
              Text('Данные об оплате:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('ID оплаты')),
                    DataColumn(label: Text('ID садовода')),
                    DataColumn(label: Text('ID взноса')),
                    DataColumn(label: Text('Состояние оплаты')),
                    DataColumn(label: Text('К оплате')),
                    DataColumn(label: Text('Дата и время оплаты')),
                  ],
                  rows: paymentData.map((payment) {
                    String? contributionName;
                    final int paymentCode = payment['iD_Код_взноса'];
                    final int gardeningId = payment['iD_Koд_садовода'];

                    final contribution = contributionRates.firstWhere(
                        (contribution) => contribution['iD_взноса'] == paymentCode,
                        orElse: () => {});

                    contributionName = contribution['наменование_взноса'];

                    return DataRow(cells: [
                      DataCell(
                          Text(payment['iD_Оплата_Взноса']?.toString() ?? '')),
                      DataCell(Text(gardeningId.toString())),
                      DataCell(Text(contributionName ?? '')),
                      DataCell(Text(payment['состояние_оплаты'] ?? '')),
                      DataCell(Text(payment['к_оплате']?.toString() ?? '')),
                      DataCell(Text(payment['дата_и_время_оплаты'] ?? '')),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}