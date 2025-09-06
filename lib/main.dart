import 'package:flutter/material.dart';

// Entry Point of Program
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  // All 'State*' widget needs a build method
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rheto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Rheto'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// where the logic exists
class _MyHomePageState extends State<MyHomePage> {
  String _counterState = '';
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
      _counterState = 'Incremented! Hell yeah!';
    });
  }

  void _decrementCounter() {
    setState(() {
      _counterState = 'We lost one!';
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body: Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         const Text('Rheto - Alpha Build'),
    //         Text(
    //           '$_counter',
    //           style: Theme.of(context).textTheme.headlineMedium,
    //         ),
    //         ElevatedButton(
    //           style: ElevatedButton.styleFrom(
    //             backgroundColor: Colors.red,
    //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    //           ),
    //           onPressed: _decrementCounter,
    //           child: const Text('Decrement'),
    //         ),
    //         const SizedBox(height: 45),
    //         Text(_counterState)

    //       ],
    //     ),
    //   ),

    //   floatingActionButton: Row(
    //     mainAxisAlignment: MainAxisAlignment.end,
    //     children: [
    //       FloatingActionButton(
    //         onPressed: _incrementCounter,
    //         tooltip: 'Increment',
    //         child: const Icon(Icons.add),
    //       ),

    //       const SizedBox(width: 10),

    //       FloatingActionButton(
    //         onPressed: _decrementCounter,
    //         tooltip: 'Decrement',
    //         child: const Icon(Icons.remove),
    //       ),
    //     ],
    //   ),

    //   // This trailing comma makes auto-formatting nicer for build methods.
    // );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            // logo + title
            Container(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco, size: 40, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'Rheto',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),

            Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Get Started')
                  
                  ),

                const SizedBox(width: 12),  
                Text('Take initial assessment before beginning'),
              ],
            
              
            ),
          
            Text(
              'Welcome to Rheto',
              style: Theme.of(context).textTheme.bodySmall,
            )

          
          ],



        ),
      ),
    );
  }
}
