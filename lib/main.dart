import 'package:flutter/material.dart';
import 'package:rheto/AppColors.dart';

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
        // base ui colors are based off of redit lol


        colorScheme: ColorScheme.dark(
          primary: AppColors.mainBackgroundColor
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF500073),
            foregroundColor: AppColors.textColor,
            // textStyle: TextStyle(fontFamily: 'Ntype82-R')
          )
        ),

        textTheme: TextTheme(
          
          headlineLarge: TextStyle(fontFamily: 'Ntype82-R', color: AppColors.textColor),
          bodyLarge: TextStyle(fontFamily: 'Lettera', color: AppColors.textColor),
          bodyMedium: TextStyle(fontFamily: 'Lettera', color: AppColors.textColor),
          bodySmall: TextStyle(fontFamily: 'Lettera', color: AppColors.textColor)

        )
      
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(Icons.eco, size: 40, color: Colors.green),
                  const Image(image: 
                              AssetImage(
                                'assets/icon/rheto.png'),
                                width: 70,
                                height: 70,
                              ),

                  const SizedBox(width: 12),
                  Text(
                   'Rheto',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                ],
            ),

            Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Get Started')
                  
                  

                  ),
                const SizedBox(height: 12), 
                Text(
                  'Take initial assessment before beginning',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          
            Text(
              'Welcome to Rheto',
              style: Theme.of(context).textTheme.bodyMedium,
            )

          
          ],



        ),
      ),
    );
  }
}
