import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finanzas_app/core/theme/theme_provider.dart';
import 'package:finanzas_app/main.dart';

void main() {
  testWidgets('Kpital app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const KpitalApp(),
      ),
    );

    // Verifica que cargue el splash con el lema oficial de Kpital
    expect(find.text('Tu capital, en calma.'), findsOneWidget);
  });
}
