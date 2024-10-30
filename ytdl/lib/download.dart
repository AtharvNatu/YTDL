import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int cardCount = 0; // Number of cards to display

  void _updateCardCount() {
    setState(() {
      // Increase the number of cards displayed by 4 or reset to 0
      cardCount = (cardCount < 16) ? cardCount + 4 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align items at the start
          children: [
            SizedBox(height: 20), // Space at the top

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center columns horizontally
                crossAxisAlignment: CrossAxisAlignment.center, // Center columns vertically
                children: [
                  // Left Column with Image (smaller width)
                  Expanded(
                    flex: 1, // Smaller width
                    child: Align(
                      alignment: Alignment.center, // Center the image
                      child: Container(
                        margin: EdgeInsets.all(8.0), // Margin around the image
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/youtube.png"),
                            fit: BoxFit.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right Column (larger width)
                  Expanded(
                    flex: 2, // Larger width
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center rows vertically
                      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start horizontally
                      children: [
                        // First Row with TextField
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft, // Align TextField to the left
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Enter text',
                              ),
                            ),
                          ),
                        ),
                        // Second Row with Button
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 20.0), // Reduced gap
                          child: Align(
                            alignment: Alignment.center, // Align Button to the left
                            child: ElevatedButton.icon(
                              onPressed: _updateCardCount,
                              icon: Icon(Icons.add), // Add an icon to the button
                              label: Text('Show More Cards'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Increased size
                                textStyle: TextStyle(fontSize: 16), // Font size
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Space for Card-like widgets in a Grid
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 cards in one row
                    childAspectRatio: 0.6, // Adjust aspect ratio for smaller cards
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: cardCount, // Number of card-like widgets based on cardCount
                  itemBuilder: (context, index) {
                    return Card(
                      child: Center(
                        child: Text('Card ${index + 1}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

