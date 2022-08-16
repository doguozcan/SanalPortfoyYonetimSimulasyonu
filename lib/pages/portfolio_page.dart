import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:sanal_portfoy_yonetim_simulasyonu/constants/widgets/app_bar_drawer.dart';
import 'package:sanal_portfoy_yonetim_simulasyonu/pages/prices_pages/networking.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final Map<String, double> dovizElements = {};
  final Map<String, dynamic> kriptoElements = {};
  final Map<String, dynamic> vadeliMevduatElements = {};
  Map<String, double> allAssets = {};
  double malVarligi = 0;
  bool bitti = false;

  Future getDovizElements() async {
    DocumentSnapshot variable = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    var elements = variable.get('Yatırım.Döviz');

    elements.forEach((k, v) {
      if (v > 0) {
        dovizElements[k.toString()] = v;
        calculateDoviz(k);
      }
    });
  }

  Future getKriptoElements() async {
    DocumentSnapshot variable = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    var elements = variable.get('Yatırım.Kripto');

    elements.forEach((k, v) {
      if (v > 0) {
        kriptoElements[k.toString()] = v;
        calculateKripto(k.toString());
      }
    });
  }

  Future getVadeliMevduatElements() async {
    DocumentSnapshot variable = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    var elements = variable.get('Yatırım.Vadeli Mevduat');

    elements.forEach((currency, mevduatBilgileri) =>
        mevduatBilgileri['Aktif'] == true
            ? vadeliMevduatElements[currency.toString()] = mevduatBilgileri
            : null);
  }

  Future calculateDoviz(String doviz) async {
    NetworkHelper myNetworkHelper = NetworkHelper(
        'https://api.exchangerate.host/convert?from=$doviz&to=TRY');
    var dovizData = await myNetworkHelper.requestData();
    double dovizPrice = dovizData['result'];
    allAssets[doviz] = dovizElements[doviz]! * dovizPrice;
  }

  Future calculateKripto(String kripto) async {
    String pathVariable = kriptoApiNames[kripto]!;

    NetworkHelper myNetworkHelper = NetworkHelper(
        'https://api.coingecko.com/api/v3/simple/price?ids=$pathVariable&vs_currencies=try');
    var kriptoData = await myNetworkHelper.requestData();
    var kriptoPrice = kriptoData[pathVariable]['try'];

    allAssets[kripto] = kriptoElements[kripto] * kriptoPrice;
  }

  Future getCurrentBalance() async {
    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    dovizElements['TRY'] = userData['Current Balance'];
    allAssets['TRY'] = userData['Current Balance'];
  }

  Future getAllAssets() async {
    await getKriptoElements();

    kriptoElements.forEach((key, value) async {
      while (allAssets[key] == null) {
        await calculateKripto(key);
      }
    });

    await getCurrentBalance();
    await getDovizElements();

    dovizElements.forEach((key, value) async {
      while (allAssets[key] == null) {
        await calculateDoviz(key);
      }
    });

    await getVadeliMevduatElements();

    allAssets.forEach((key, value) {
      malVarligi += value;
    });

    bitti = true;
  }

  final Map<String?, String> currencyEmojis = {
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'AED': '🇦🇪',
    'AUD': '🇦🇺',
    'CAD': '🇨🇦',
    'CHF': '🇨🇭',
    'DKK': '🇩🇰',
    'JPY': '🇯🇵',
    'KWD': '🇰🇼',
    'NOK': '🇳🇴',
    'SAR': '🇸🇦',
    'SEK': '🇸🇪',
    'TRY': '🇹🇷'
  };

  final Map<String?, String> currencyNames = {
    'USD': 'Amerikan Doları',
    'EUR': 'Avrupa Para Birimi',
    'GBP': 'İngiliz Sterlini',
    'AED': 'Bae Dirhemi',
    'AUD': 'Avustralya Doları',
    'CAD': 'Kanada Doları',
    'CHF': 'İsviçre Frangı',
    'DKK': 'Danimarka Kronu',
    'JPY': 'Japon Yeni',
    'KWD': 'Kuveyt Dinarı',
    'NOK': 'Norveç Kronu',
    'SAR': 'Arabistan  Riyali',
    'SEK': 'İsveç Kronu',
    'TRY': 'Türk Lirası'
  };

  final Map<String?, String> kriptoNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'BNB': 'Binance Coin',
  };

  final Map<String?, String> kriptoApiNames = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'BNB': 'binancecoin',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppBarDrawer(),
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: (() {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('UYARI'),
                    content: const Text(
                        'Sayfa sık sık yenilendiğinde, kullanılan farklı fiyat API\'lerinden dolayı fiyat bilgisi alınamayabilmektedir. Bu durumlarda grafikte de eksik bilgi gözükecektir.'),
                    actions: [
                      MaterialButton(
                        onPressed: (() {
                          Navigator.pop(context);
                        }),
                        child: const Text('Tamam'),
                      ),
                    ],
                  );
                },
              );
            }),
            icon: const Icon(Icons.question_mark_outlined),
          )
        ],
        centerTitle: true,
        title: const Text('Sanal Portföyüm'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: Future.delayed(
                  const Duration(milliseconds: 700), () => getAllAssets()),
              builder: ((context, index) {
                print(dovizElements);
                print('${dovizElements.length} dovizElements.length');
                print(kriptoElements);
                print('${kriptoElements.length} kriptoElements.length');
                print(allAssets);
                print('${allAssets.length} allAssets.length');
                print(malVarligi);
                if (!bitti) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SpinKitPouringHourGlass(
                        strokeWidth: 2,
                        color: Colors.orange,
                        size: 60,
                        duration: Duration(milliseconds: 1000),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Hazırlıyoruz...',
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PieChart(
                          centerText:
                              'Toplam:\n${malVarligi.toStringAsFixed(2)} TRY',
                          dataMap: allAssets,
                          chartRadius: MediaQuery.of(context).size.width / 2,
                          chartType: ChartType.ring,
                          ringStrokeWidth: 16,
                          animationDuration: const Duration(seconds: 2),
                          chartValuesOptions: const ChartValuesOptions(
                            decimalPlaces: 2,
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: bitti ? getListView() : const SizedBox(),
                      ),
                    ],
                  );
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  ListView getListView() {
    return ListView.builder(
      itemCount: dovizElements.values.length +
          kriptoElements.values.length +
          vadeliMevduatElements.values.length,
      itemBuilder: ((context, index) {
        if (index < dovizElements.values.length) {
          return portfolioCard(
            currencyEmojis[dovizElements.keys.elementAt(index)],
            dovizElements.keys.elementAt(index),
            currencyNames[dovizElements.keys.elementAt(index)],
            dovizElements.values.elementAt(index),
          );
        } else if (index <
            dovizElements.values.length + kriptoElements.values.length) {
          return kriptoCard(
              kriptoElements.keys
                  .elementAt(index - dovizElements.values.length),
              kriptoNames[kriptoElements.keys
                  .elementAt(index - dovizElements.values.length)],
              kriptoElements.values
                  .elementAt(index - dovizElements.values.length));
        } else {
          String key = vadeliMevduatElements.keys.elementAt(index -
              dovizElements.values.length -
              kriptoElements.values.length);
          return vadeliMevduatCard(
              currencyEmojis[key],
              vadeliMevduatElements[key]['Anapara'],
              key,
              vadeliMevduatElements[key]['Yatırma Tarihi'],
              vadeliMevduatElements[key]['Vade Tarihi'],
              vadeliMevduatElements[key]['Net Getiri']);
        }
      }),
    );
  }

  Card portfolioCard(
      String? flag, String currencyCode, String? currencyName, double owned) {
    String tlMiktari = 'Fiyat alınamadı';
    if (allAssets[currencyCode] != null) {
      tlMiktari = allAssets[currencyCode]!.toStringAsFixed(2);
    }
    return Card(
      color: Colors.black54,
      child: ListTile(
        leading: Text(
          flag!,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(currencyCode, style: const TextStyle(color: Colors.white)),
        subtitle: Text(currencyName!),
        trailing:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '${owned.toStringAsFixed(2)} $currencyCode',
            style: const TextStyle(fontSize: 16),
          ),
          currencyCode != 'TRY'
              ? Text('$tlMiktari TRY',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : const SizedBox(),
        ]),
      ),
    );
  }

  Card kriptoCard(String currencyCode, String? currencyName, double owned) {
    String tlMiktari = 'Fiyat alınamadı';
    if (allAssets[currencyCode] != null) {
      tlMiktari = allAssets[currencyCode]!.toStringAsFixed(2);
    }
    return Card(
      color: const Color.fromARGB(255, 27, 40, 83),
      child: ListTile(
        title: Text(currencyCode, style: const TextStyle(color: Colors.white)),
        subtitle: Text(currencyName!),
        trailing:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '${owned.toStringAsFixed(2)} $currencyCode',
            style: const TextStyle(fontSize: 16),
          ),
          currencyCode != 'TRY'
              ? Text('$tlMiktari TRY',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : const SizedBox(),
        ]),
      ),
    );
  }

  Card vadeliMevduatCard(String? emoji, int anapara, String? currency,
      String yatirmaTarihi, String vadeTarihi, double netGetiri) {
    DateTime dtYatirmaTarihi = DateFormat('dd-MM-yyyy').parse(yatirmaTarihi);
    DateTime dtVadeTarihi = DateFormat('dd-MM-yyyy').parse(vadeTarihi);

    DateTime dtNow =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Card(
      color: Colors.red,
      child: ListTile(
        leading: Text(emoji!, style: const TextStyle(fontSize: 32)),
        title: Text('$anapara ${currency!} Vadeli Mevduat'),
        subtitle: Text(
            '$yatirmaTarihi - $vadeTarihi\nNet Getiri: $netGetiri $currency'),
        trailing: MaterialButton(
          onPressed: () {
            double getiri = netGetiri;

            String dialogMessage =
                'Toplamda kazancınız $getiri $currency. Emin misiniz?';

            if (dtVadeTarihi.compareTo(dtNow) >= 0) {
              // Vade dolmamış, geçen gün sayısına oranla gelir
              getiri = netGetiri *
                  (DateTime.now().difference(dtYatirmaTarihi).inDays) /
                  (dtVadeTarihi.difference(dtYatirmaTarihi).inDays);

              dialogMessage =
                  'Vade tarihi bitmediği için $getiri $currency kazanacaksınız. Emin misiniz?';
            }

            showDialog(
                context: context,
                builder: ((context) {
                  return AlertDialog(
                    title: const Text('Onayla!'),
                    content: Text(dialogMessage),
                    actions: [
                      MaterialButton(
                        onPressed: () async {
                          DocumentReference docUser = FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid);

                          if (currency == 'TRY') {
                            docUser.update({
                              'Current Balance': FieldValue.increment(
                                  anapara.toDouble() + getiri),
                              'Yatırım.Vadeli Mevduat.TRY.Aktif': false,
                            });
                          } else {
                            docUser.update({
                              'Yatırım.Döviz.$currency': FieldValue.increment(
                                  anapara.toDouble() + getiri),
                              'Yatırım.Vadeli Mevduat.$currency.Aktif': false
                            });
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('İşlem Başarılı')));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PortfolioScreen(),
                            ),
                          );
                        },
                        child: const Text('Onayla!'),
                      ),
                      MaterialButton(
                          child: const Text('İptal'),
                          onPressed: () {
                            Navigator.pop(context);
                          })
                    ],
                  );
                }));

            setState(() {});
          },
          color: Colors.black,
          child: const Text('Boz'),
        ),
      ),
    );
  }
}
