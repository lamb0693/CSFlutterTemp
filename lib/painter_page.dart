
import 'package:flutter/material.dart';

class Painter extends CustomPainter{
  final List<List<Map<String, double>>> lines ;
  final List<Map<String, double>> line;

  Painter(this.line, this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    print('>>>> onPaint : $line, $lines');

    // Draw lines based on the linesCSR data
    for (var line in lines) {
      if (line.length > 1) {
        final path = Path();
        path.moveTo(line[0]['x']!, line[0]['y']!);
        for (var i = 1; i < line.length; i++) {
          path.lineTo(line[i]['x']!, line[i]['y']!);
        }

        var paint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke;

        canvas.drawPath(path, paint);
      }
    }

     // Draw the current line being drawn
    if (line.isNotEmpty) {
      final path = Path();
      path.moveTo(line[0]['x']!, line[0]['y']!);
      for (var i = 1; i < line.length; i++) {
        path.lineTo(line[i]['x']!, line[i]['y']!);
      }
      canvas.drawPath(path, Paint()..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PainterPage extends StatefulWidget {
  final String title;

  const PainterPage({super.key, required this.title});

  @override
  State<PainterPage> createState() => _PainterPage();

}

class _PainterPage extends State<PainterPage>{
  List<List<Map<String, double>>> lines = [];
  List<Map<String, double>> line = [];
  bool isDrawing = false;

  late Painter painter;

  @override
  void initState() {
    painter = Painter(line, lines);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home : Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 400,
                  minHeight: 600,
                  maxHeight: 600,
                ),
                child: Container(
                  color: Colors.grey,
                  child: GestureDetector(
                    onPanDown: (details) {
                      if (painter != null)  {
                        isDrawing = true;
                        print('on Mouse Down ${details.localPosition}');
                        setState(() {
                          line.add({'x': details.localPosition.dx, 'y': details.localPosition.dy});
                        });
                      }
                    },
                    onPanUpdate: (details) async {
                      if (painter != null){
                        //print('on Mouse Down ${details.localPosition}');

                        line.add({'x': details.localPosition.dx, 'y': details.localPosition.dy});
                        setState(() { });
                      }
                    },
                    onPanEnd: (details) {
                      if (painter != null) {
                        setState(() {
                          lines.add([...line]);
                          line.clear();
                        });
                        isDrawing = false;
                        print('number of line : ${lines.length}');
                      }
                    },
                    child: CustomPaint(
                      size: const Size(400, 600),
                      painter: painter ,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child : Row (
              children: [
                ElevatedButton(
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back)),
                ElevatedButton(
                    onPressed: () {},
                    child: const Icon(Icons.upload)
                ),
              ],
            )
        ),
      ),
    );
  }
}




