import 'package:flutter/material.dart';
import 'package:rheto/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  @override
  Widget build(BuildContext context) {

    // chip Theme





    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[  // children is a list of widgets
                // 1st child of the column -> Return & subtitle screen
                Row(
                 children: [
                  IconButton(
                    // iconSize: ,
                    onPressed: () {Navigator.pop(context);},
                    icon: Icon(Icons.arrow_back),
                  ),

                  Text(
                    'Initial Assessment',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                  ),
                 ], 
                ),

                // Second child of the column -> Welcome and Onboaring with Proceed Button
                Column(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Think of this as a checkup!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: 'Ntype82-R'),
                    ),
                    Text(
                      'This is to establish your baseline cognitive profile across three domains:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
                      textAlign: TextAlign.center,
                    ),
                  
                  // Symbols for the three domains:
                  // Creativity - Yellow lightbulb
                    Chip(
                      avatar: FaIcon(FontAwesomeIcons.gears, color: Color(0xFF74C0FC),size: 20),
                      label: Text("Critical Thinking"),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Color(0xFF74C0FC)),
                      ),
                    ),

                    Chip(
                      avatar: FaIcon(FontAwesomeIcons.lightbulb, color: Color(0xFFFFD43B), size: 20,),
                      label: Text("Memory"),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Color(0xFFFFD43B)),
                      ),
                    ),

                    Chip(
                      avatar: FaIcon(FontAwesomeIcons.squareShareNodes, color: Color(0xFF63E6BE),size: 20),
                      label: Text("Creativity"),
                      labelStyle: const TextStyle(
                        fontFamily: 'Lettera'
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Color(0xFF63E6BE)),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () {},
                      child: Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008000),
                        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 20,
                          fontFamily: 'Ntype82-R' // for some reason, changing the font size of the button changes the theme. I have to explicitly set its the typeface again.
                        )
                      ),
                    ),

                    Text(
                      "This won't take long! 😊",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
                      textAlign: TextAlign.center
                    )

                  ]


                )


                // Third child of the column -> Terms

                
               
              ]
        ),
      ),
    );
  }
}
