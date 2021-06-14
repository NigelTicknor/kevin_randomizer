import 'package:flutter/material.dart';
import "dart:math";
import 'db/db.dart';
import 'dart:developer' as developer;


void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {

    MyDatabase myDb = constructDb();

    Color myColor = Color(0xff1C46C5);

    return MaterialApp(
      title: 'KevinRandomizer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: MaterialColor(myColor.value, getSwatch(myColor)),
      ),
      home: CategoryPage(myDb: myDb),
    );
  }
}

class CategoryPage extends StatefulWidget {
  CategoryPage({Key key, this.myDb}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final MyDatabase myDb;

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> realCategories = [];

  // This stuff is for the text dialog
  TextEditingController _textFieldController = TextEditingController();
  String valueText;

  void _createCategory(String category) {
    widget.myDb.addCategory(category);
    getCategories();
  }

  void _removeCategory(Category category) {
    widget.myDb.removeCategory(category.id);
    getCategories();
  }

  Future<void> getCategories() async {
    developer.log("[*] getting categories");
    List<Category> realC = await widget.myDb.allCategories;
    setState(() {
      realCategories = realC;
    });
  }


  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add a new category'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    valueText = '';
                    Navigator.pop(context);
                  });
                  _textFieldController.clear();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  _createCategory(valueText);
                  setState(() {
                    valueText = '';
                    Navigator.pop(context);
                  });
                  _textFieldController.clear();
                },
              ),

            ],
          );
        });
  }

  Future<void> _displayRemoveCategoryDialog(BuildContext context, Category category) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Remove category ' + category.title + '?'),
            content: Text('Are you sure you want to remove this category?'),
            actions: <Widget>[
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                child: Text('REMOVE'),
                onPressed: () {
                  _removeCategory(category);
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),

            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    developer.log("init here");
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('KevinRandomizer'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView.builder(
          itemCount: realCategories.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Center(child: Text(realCategories[index].title),),
              onTap: (){
                Navigator.push(context, new MaterialPageRoute(builder: (context) => new RandomizerPage(category: realCategories[index], myDb: widget.myDb,)));
              },
              onLongPress: (){
                _displayRemoveCategoryDialog(context, realCategories[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _displayTextInputDialog(context);
        },
        tooltip: 'Add Category',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class RandomizerPage extends StatefulWidget {
  RandomizerPage({Key key, this.title, this.category, this.myDb}) : super(key: key);

  final String title;
  final Category category;
  final MyDatabase myDb;

  @override
  _RandomizerPageState createState() => _RandomizerPageState();
}

class _RandomizerPageState extends State<RandomizerPage> {
  List<Entry> realEntries = [];
  String chosenEntry = '';
  Random random = new Random();

  // This stuff is for the text dialog
  TextEditingController _textFieldController = TextEditingController();
  String valueText;
  
  void _createRandomizerEntry(String entry) {
    widget.myDb.addEntry(widget.category.id, entry);
    getEntries();
  }

  void _deleteRandomizerEntry(Entry entry) async {
    await widget.myDb.deleteEntry(entry.id);
    getEntries();
  }

  Future<void> getEntries({bool choose = false}) async {
    developer.log("[*] getting entries");
    List<Entry> realE = await widget.myDb.getEntriesForCategory(widget.category.id);
    setState(() {
      realEntries = realE;
    });
    if(choose == true) {
      _randomizeChosenEntry();
    }
  }

  Widget _buildChosenEntry() {
    if(realEntries.length == 0) {
      return Text('There is nothing for me to choose yet...');
    }
    if(chosenEntry.length == 0) {
      return Text('I haven\'t chosen anything yet...');
    }
    return Text('I chose: ' + chosenEntry);
  }

  void _randomizeChosenEntry() {
    String myChoice = '';
    if(realEntries.length == 1) {
      myChoice = realEntries[0].entry;
    } else if(realEntries.length > 1){
      do {
        int tempChoice = Random().nextInt(realEntries.length);
        myChoice = realEntries[tempChoice].entry;
      }while(myChoice == chosenEntry);
    }
    setState(() {
      chosenEntry = myChoice;
    });
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add an entry'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    valueText = '';
                    Navigator.pop(context);
                  });
                  _textFieldController.clear();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  _createRandomizerEntry(valueText);
                  setState(() {
                    valueText = '';
                    Navigator.pop(context);
                  });
                  _textFieldController.clear();
                },
              ),

            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    getEntries(choose: true);
    developer.log("init here for entries");
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('KevinRandomizer: ' + widget.category.title.toUpperCase()),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
                height: 50,
                color: const Color(0xffc3c4c7),
                child: TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.black
                  ),
                    child: Center(child: _buildChosenEntry(),),
                    onPressed: _randomizeChosenEntry,
                ),
              ),
            Expanded(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: ListView.builder(
                itemCount: realEntries.length,
                itemBuilder: (BuildContext context, int index) {
                  return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (DismissDirection direction){
                      _deleteRandomizerEntry(realEntries[index]);
                    },
                    child: ListTile(
                      title: Center(child: Text(realEntries[index].entry),),
                      onTap: (){},
                    ),
                  );
                },
              ),
            ),
          ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  () {
          _displayTextInputDialog(context);
        },
        tooltip: 'Add Entry',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Map<int, Color> getSwatch(Color color) {
  final hslColor = HSLColor.fromColor(color);
  final lightness = hslColor.lightness;

  /// if [500] is the default color, there are at LEAST five
  /// steps below [500]. (i.e. 400, 300, 200, 100, 50.) A
  /// divisor of 5 would mean [50] is a lightness of 1.0 or
  /// a color of #ffffff. A value of six would be near white
  /// but not quite.
  final lowDivisor = 6;

  /// if [500] is the default color, there are at LEAST four
  /// steps above [500]. A divisor of 4 would mean [900] is
  /// a lightness of 0.0 or color of #000000
  final highDivisor = 5;

  final lowStep = (1.0 - lightness) / lowDivisor;
  final highStep = lightness / highDivisor;

  return {
    50: (hslColor.withLightness(lightness + (lowStep * 5))).toColor(),
    100: (hslColor.withLightness(lightness + (lowStep * 4))).toColor(),
    200: (hslColor.withLightness(lightness + (lowStep * 3))).toColor(),
    300: (hslColor.withLightness(lightness + (lowStep * 2))).toColor(),
    400: (hslColor.withLightness(lightness + lowStep)).toColor(),
    500: (hslColor.withLightness(lightness)).toColor(),
    600: (hslColor.withLightness(lightness - highStep)).toColor(),
    700: (hslColor.withLightness(lightness - (highStep * 2))).toColor(),
    800: (hslColor.withLightness(lightness - (highStep * 3))).toColor(),
    900: (hslColor.withLightness(lightness - (highStep * 4))).toColor(),
  };
}