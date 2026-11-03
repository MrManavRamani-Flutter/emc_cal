import '../models/account_model.dart';
import '../models/machine_model.dart';
import '../models/material_item.dart';
import '../models/material_product.dart';
import '../models/production_record.dart';
import '../models/supplier.dart';

class SampleData {
  static List<AccountModel> getInitialAccounts() {
    return [
      AccountModel(
        id: 1,
        name: 'Beads',
        area: 'Beads',
        displayOrder: 1,
        colorHex: '#7C3AED',
        isActive: true,
        notes: 'Beads, Sequins & Special Cording Production Account',
      ),
      AccountModel(
        id: 2,
        name: '250 Area',
        area: '250',
        displayOrder: 2,
        colorHex: '#2563EB',
        isActive: true,
        notes: '250 Standard Frame Area Production Account',
      ),
      AccountModel(
        id: 3,
        name: '400 Area',
        area: '400',
        displayOrder: 3,
        colorHex: '#059669',
        isActive: true,
        notes: '400 Large Frame Area Production Account',
      ),
    ];
  }

  static List<MachineModel> getMachines() {
    return [
      MachineModel(
        id: 1,
        machineNo: 'M-01',
        name: 'Dahao Computerized (32 Head)',
        headCapacity: 32,
        isActive: true,
        notes: '250 Area Standard Line - Machine 1',
      ),
      MachineModel(
        id: 2,
        machineNo: 'M-02',
        name: 'Dahao High-Speed (26 Head)',
        headCapacity: 26,
        isActive: true,
        notes: '250 Area Heavy Production - Machine 2',
      ),
      MachineModel(
        id: 3,
        machineNo: 'M-03',
        name: 'Dahao Sequential (32 Head)',
        headCapacity: 32,
        isActive: true,
        notes: '250 Area Multi-Step Line - Machine 3',
      ),
      MachineModel(
        id: 4,
        machineNo: 'M-04',
        name: 'Dahao Multi-Part (32 Head)',
        headCapacity: 32,
        isActive: true,
        notes: '250 Area Composite Line - Machine 4',
      ),
      MachineModel(
        id: 5,
        machineNo: 'M-05',
        name: 'Dahao Jumbo Frame (24 Head)',
        headCapacity: 24,
        isActive: true,
        notes: '400 Area Wide Border Line - Machine 5',
      ),
      MachineModel(
        id: 6,
        machineNo: 'M-06',
        name: 'Dahao Jumbo Frame (24 Head)',
        headCapacity: 24,
        isActive: true,
        notes: '400 Area Top Embroidery - Machine 6',
      ),
      MachineModel(
        id: 7,
        machineNo: 'M-07',
        name: 'Dahao Multi-Needle (30 Head)',
        headCapacity: 30,
        isActive: true,
        notes: 'Standard Production Line - Floor 2',
      ),
      MachineModel(
        id: 8,
        machineNo: 'M-08',
        name: 'Dahao Beads/Sequins (32 Head)',
        headCapacity: 32,
        isActive: true,
        notes: 'Beads, Sequins & Cording Attachment - Machine 8',
      ),
    ];
  }

  /// Ground-truth production records extracted from real DAHAO MATE-A8 machine monitor screenshots
  static List<ProductionRecord> getDahaoScreenshotRecords() {
    return [];
  }

  static List<ProductionRecord> getInitialRecords() {
    return [];
  }

  /// Initial material items (starts clean without dummy data)
  static List<MaterialItem> getInitialMaterials() {
    return [];
  }

  /// Sample demo bills preserved for testing/reference only
  static List<MaterialItem> getDemoMaterials() {
    return [];
  }

  /// Initial Master Products with Default Rates & Units (From Register Ledger)
  static List<MaterialProduct> getInitialMaterialProducts() {
    return [];
  }

  /// Initial Suppliers Master (From Register Ledger)
  static List<Supplier> getInitialSuppliers() {
    return [];
  }
}
