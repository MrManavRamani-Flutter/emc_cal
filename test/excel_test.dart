import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

void main() {
  test('Excel creation test', () {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue('No.'),
      TextCellValue('Design No.'),
      IntCellValue(300000),
      DoubleCellValue(1.25),
    ]);
    final bytes = excel.encode();
    expect(bytes, isNotNull);
  });
}
