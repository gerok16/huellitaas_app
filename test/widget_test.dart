
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas_app/app.dart';

void main() {
  testWidgets('La aplicación Huellitas inicia correctamente', (tester) async {
    await tester.pumpWidget(const HuellitasApp());

    expect(find.text('Huellitas'), findsOneWidget);
  });
}
