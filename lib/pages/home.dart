
import 'dart:io';

import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:band_names/models/band.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';


class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    /*Band(id: '1', name: 'Metalica', votes: 5),
    Band(id: '2', name: 'Queen', votes: 1),
    Band(id: '3', name: 'Heroes del Silencio', votes: 2),
    Band(id: '4', name: 'Bon Jovi', votes: 5),*/
  ];

  @override
  void initState() {
    final socketService = Provider.of<SockerService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload){
    this.bands = (payload as List)
        .map((band) => Band.fromMap(band))
        .toList();

        setState(() {});
      
  }

  @override
  void dispose() {
    final socketService = Provider.of<SockerService>(context, listen: false);

    socketService.socket.off('active-bands');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SockerService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle(color: Colors.black87),),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)   ?
                Icon(Icons.check_circle, color: Colors.blue[300])
                : Icon(Icons.check_circle, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          (bands.isNotEmpty) ? _showGraph()
          : Text('No hay Bandass', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), ),

           Expanded(
             child: ListView.builder(

              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i])
              
          ),
           )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand
      ),
   );
  }

  Widget _bandTile(Band band) {

    final socketService = Provider.of<SockerService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id' : band.id }),
      background: Container(
        padding: EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Borrar Banda', style: TextStyle(color: Colors.white),),
        )
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0,2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20),),
        onTap: () => socketService.socket.emit('vote-band', {'id' : band.id }),
      ),
    );
  }

  addNewBand(){
    final textController = new TextEditingController();

    if(Platform.isAndroid){
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Nueva Banda'),
          content: TextField(
            controller: textController,
          ),
          actions: <Widget>[
            MaterialButton(
              child: Text('Agregar'),
              elevation: 0,
              textColor: Colors.blue,
              onPressed: ()=> addBandToList(textController.text)
            )
          ],
        )
        
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: (_) => CupertinoAlertDialog(
        title: Text('Nombre de nueva Banda'),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Agregar'),
            onPressed: () => addBandToList(textController.text)
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Cerrar'),
            onPressed: () => Navigator.pop(context)
          )

        ],
      )
      
    );
  }

  void addBandToList(String name){


    if(name.length > 1){
      final socketService = Provider.of<SockerService>(context, listen: false);

      //this.bands.add(new Band(id: DateTime.now().toString(), name: name, votes: 0));
      //emitir: add-band
      //{name: name}

      socketService.emit('add-band', {'name' : name});
    }

    Navigator.pop(context);
  }

  _showGraph(){
    Map<String, double> dataMap = new Map() ;
    //dataMap.putIfAbsent('Flutter', () => 5);
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    final List<Color> colorList = [
      Colors.blue[50],
      Colors.blue[200],
      Colors.pink[50],
      Colors.pink[200],
      Colors.yellow[50],
      Colors.pink[200]
    ];

    return Container(
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      height: 200,
      child: PieChart(
          dataMap: dataMap,
          animationDuration: Duration(milliseconds: 800),
          chartRadius: MediaQuery.of(context).size.width / 3.2,
          colorList: colorList,
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          ringStrokeWidth: 32,
          centerText: "HYBRID",
          legendOptions: LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
            legendShape: BoxShape.circle,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          chartValuesOptions: ChartValuesOptions(
            showChartValueBackground: true,
            showChartValues: true,
            showChartValuesInPercentage: false,
            showChartValuesOutside: false,
          ),
      )
    );
  }
}