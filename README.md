# 🪡 OM MAVTAR GROUP — Embroidery ERP & Production Calculator

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20%7C%20macOS-0078D6.svg)]()
[![Database](https://img.shields.io/badge/Database-SQLite%20Schema%20v1%20(100%25%20Offline)-green.svg)](https://sqlite.org)
[![Build Status](https://img.shields.io/badge/Build-v1.0.0%20Release%20Ready-success.svg)]()
[![Code Quality](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues%20(100%25%20Clean)-brightgreen.svg)]()
[![Tests](https://img.shields.io/badge/Tests-151%20Passed%20(100%25)-brightgreen.svg)]()

> **OM MAVTAR GROUP** is a modern, enterprise desktop ERP and production calculation suite tailored specifically for embroidery factories, textile workshops, and jobwork units. It provides daily multi-head stitch billing, separate Khata / Account ledgers (`Beads`, `250 Area`, `400 Area`), machine inventory (`M-01` to `M-08`), raw material and challan statement accounting with authentic Surat textile single-item slips, comprehensive **Customer & Jobwork Billing with Partial Payment Tracking**, an **Authentic 18 Factory Expense Management Suite with Checkbox Filtering & PDF Reporting**, **Employee & Upad (Advance Salary) Ledger**, a **Recycle Bin with 1-Click Restoration**, JSON backup/restore, interactive analytics charts, and native Microsoft Excel exports — operating **100% offline with zero dummy data on SQLite Version 1**.

---

## 📖 Quick Hindi Overview (ऐप का संपूर्ण परिचय)

यह सॉफ्टवेयर विशेष रूप से **OM MAVTAR GROUP** और एम्ब्रॉयडरी कारखानों के लिए विकसित किया गया एक ऑल-इन-वन डेस्कटॉप सॉफ्टवेयर है:

1. **🏢 ग्राहक एवं पार्टी बहीखाता (Customer Directory, Invoices & Jobwork Billing)**:
   - **पार्टी लेजर**: पार्टी का नाम, फोन नंबर, शहर, कुल इनवॉइस, जमा राशि और कुल बकाया वसूली (Remaining Due)।
   - **डिफ़ॉल्ट Unpaid बिलिंग**: नया बिल बनाते समय डिफ़ॉल्ट रूप से `⏳ Unpaid (बकाया)` रहता है जिससे गलती से बिल तुरंत Paid नहीं होता। यदि पार्टी ने एडवांस दिया हो तभी `Advance` चुन सकते हैं।
   - **Edit Bill (✏️) सुविधा**: यदि कोई बिल गलती से Paid हो गया हो तो 1-क्लिक में Edit (✏️) दबाकर वापस Unpaid किया जा सकता है या राशि बदली जा सकती है।
   - **+ Receive Payment (जमा दर्ज करें)**: हेडर बार और पार्टी कार्ड पर डायरेक्ट जमा बटन, जिससे नकद (Cash) या UPI आने पर 1-क्लिक में (Full Due, 50% Half या Custom राशि) जमा दर्ज हो जाती है।
   - **3-स्टेप स्पष्ट भुगतान गाइड बैनर**: इनवॉइस टेबल के ऊपर स्पष्ट हिन्दी/गुजराती गाइड।
   - **रसीद डिलीट पर बैलेंस रिवर्सल**: गलत रसीद डिलीट करने पर डेटाबेस में बिल का बैलेंस स्वतः वापस बकाया में जुड़ जाता है।

2. **🏭 कारखाने के प्रामाणिक 18 खर्च श्रेणियां एवं PDF रिपोर्ट्स (18 Factory Expenses & PDF Reports)**:
   - कारखाने की वास्तविक डायरी के 18 मुख्य खर्च: अંદરનો પરચૂરણ ખર્ચ, ટેમ્પો ભાડું, ગ્રાહક સેવા, ઓફિસ ખર્ચ, પડદા/કવર, બોબીન, પીવાનું પાણી, પેટ્રોલ, મશીન રીપેરિંગ, દોરા કટિંગ, ગોડાઉન ભાડું, લાઈટબિલ, ચા-પાણી નાસ્તો, ઇસ્ત્રી/ફોલ્ડિંગ, વાઇફાઇ/કમ્પ્યુટર, વાયરિંગ, નવી મશીનરી, મશીન ઓઇલિંગ અને અન્ય ખર્ચ.
   - **डायनामिक श्रेणियां**: यूजर जब चाहे नई श्रेणी जोड़, संशोधित या डिलीट कर सकता है।
   - **मल्टी-चेकबॉक्स फिल्टर्स**: जिन श्रेणियों पर टिक (✓) रखेंगे केवल वही डेटा दिखेगा। साथ में **Select All**, **Deselect All**, और **Clear Filters** बटन्स।
   - **खर्च PDF एक्सपोर्ट**: 1. *Group By Category Report* (श्रेणीवार योग एवं विवरण) तथा 2. *Detailed Itemized Register* (क्रोनोलॉजिकल रजिस्टर)।

3. **🧾 कच्चा माल प्रामाणिक सूरत टेक्सटाइल सिंगल-आइटम चालान PDF (Surat Textile Slip)**:
   - भगवती जरी, खुशी फैशन जैसी प्रामाणिक सूरत टेक्सटाइल चालान रसीद A4/A5 PDF।
   - चालान में प्रत्येक उत्पाद लाइन के लिए स्वतंत्र **PDF Bill** बटन जिससे एक ही आइटम का अलग चालान पर्चा निकाला जा सकता है।
   - **macOS Preview इंटीग्रेशन**: प्रिंट दबाते ही सीधे macOS Preview ऐप में बिना किसी सैंडबॉक्स एरर के 1 सेकंड में ओपन होता है।

4. **👥 कर्मचारी विवरण, डायनामिक रोल्स (UPPERCASE) एवं उपाड़ (Advance) और पगार हिसाब**:
   - कर्मचारियों का पूरा विवरण (नाम, पद/रोल, फोन नंबर, मासिक पगार, जॉइनिंग डेट, और सक्रिय स्थिति)।
   - **UPPERCASE रोल्स**: यूजर कैपिटल या स्माल में लिखे, सिस्टम बिना डुप्लीकेशन के हमेशा सुंदर अपरकेस में ही रोल दिखाता है।
   - **3-व्यूज**: 1. Employee Cards, 2. Master Payroll & Upad Register, 3. All Upads History & Ledger।
   - **मासिक पगार सैटलमेंट**: 1-क्लिक में उपाड़ काटकर शुद्ध पगार चुकाने का वाउचर और नया चक्र रीसेट।

5. **📲 WhatsApp उपाड़ रसीद, मानवाचक संबोधन एवं ऑडिट लॉग**:
   - मानवाचक सम्मानजनक संबोधन (*"नमस्ते [नाम] जी,"*, *"Dear [Name] ji,"*).
   - कंपनी ब्रांडिंग: `OM MAVTAR GROUP - कढ़ाई उत्पादन प्रबंधन`.
   - SQLite `whatsapp_logs` में पूरा संदेश, भेजने का समय और मोबाइल नंबर सुरक्षित रहता है।

6. **🪡 प्रोडक्शन एंट्री & बैच मैट्रिक्स (Daily Stitch & Shift Calculation)**:
   - सटीक सूत्र: $\text{राशि (₹)} = \frac{\text{Stitch}}{1000} \times \text{Rate} \times \text{Heads}$.
   - Day / Night शिफ्ट, हॉरिजॉन्टल स्क्रॉल रहित फुल-स्क्रीन टेबल।
   - सभी तालिकाओं में Ascending/Descending सॉर्टिंग और 50+ रिकॉर्ड्स के लिए "Show All" पेजिनेशन।

7. **🗑️ रीसायकल बिन & सुरक्षित बैकअप/रीस्टोर**:
   - डिलीट किए गए रिकॉर्ड्स सीधे रीसायकल बिन में सुरक्षित जाते हैं।
   - खाली डेटाबेस होने पर भी 1-क्लिक में सुरक्षित JSON रीस्टोर।
   - `SafeRangeUtils` द्वारा किसी भी स्थिति में RangeError या क्रैश से पूर्ण सुरक्षा।

---

## 🌟 Core System Modules (મુખ્ય સિસ્ટમ મોડ્યુલ્સ)

### 1. 🏢 Customers & Jobwork Billing (ગ્રાહક અને જોબવર્ક બિલિંગ)
- **Customer Directory**: Active customer cards with 3 KPI indicators (Total Invoiced, Total Received, Remaining Due).
- **Invoice Register**: Invoice number, date, total amount, received amount, due balance, and status badges (`UNPAID`, `PARTIAL`, `PAID`).
- **Default Unpaid Status**: Prevents accidental full-paid marking upon bill creation.
- **Edit Bill (✏️) Dialog**: Direct status switcher (`Unpaid`, `50% Half`, `Full Paid`) and custom adjustment.
- **Payment Receipts Log**: Datewise log with delete receipt confirmation and safe automatic balance reversal.
- **3-Step Payment Guide Banner**: Inline visual explanation of the 3-step billing and collection cycle.

### 2. 🏭 Authentic 18 Factory Expenses & Multi-Category Checkbox Filters
- **18 Authentic Embroidery Categories**: Petty cash, tempo freight, client relations, office, covers, bobbins, drinking water, petrol, repairs, thread cutting, rent, electricity, tea/snacks, ironing/folding, computer/Wi-Fi, electrical wiring, machinery, machine oiling, and other.
- **Dynamic Category Management**: Add new categories from dropdown or manage existing ones via dialog.
- **Checkbox Filtering**: Instant reactive filtering by checking/unchecking categories.
- **Toolbar Controls**: "Select All", "Deselect All", and "Clear Filters".
- **PDF Export Suite**: Category-wise summary reports and chronological registers with instant macOS Preview launch.

### 3. 🧾 Raw Material Challan & Single-Item Paper Slips
- **Challan Ledger**: Supplier inward tracking, category badges (`Sequence`, `Beads`, `Thread`), and partial payments outward.
- **Authentic Paper Challan Format**: Modeled directly after Surat textile market standards (Bhagwati Jari, Khushi Fashion).
- **Single-Item PDF Button**: Generate clean separate PDF slips for individual items.
- **Native macOS Preview Integration**: Eliminates system printing error modals; launches Preview app where Cmd+P prints immediately.

### 4. 👥 Employee Management, Dynamic Roles & 3-View Upad Ledger
- **UPPERCASE Dynamic Roles**: Automatic normalization regardless of user case input.
- **3-View Comprehensive Navigation**: Employee Directory, Master Payroll Register, and All Upads History.
- **Advance Upad Tracking & Excess Carry-Forward**:
  $$\text{Net Salary} = \text{Monthly Base Salary} - \sum \text{Unsettled Upads}$$
- **WhatsApp Receipts with Honorifics**: Respectful salutations (*"नमस्ते [नाम] जी,"*) with SQLite audit log.

### 5. 🪡 Daily Stitch Production & Batch Matrix
- **Core Formula**:
  $$\text{Amount (₹)} = \frac{\text{Stitch}}{1000} \times \text{Rate} \times \text{Heads}$$
- **Batch Matrix**: M-01 to M-08 multi-machine entry without modal resets.
- **Asc/Desc Sorting**: Click on any column header to sort in ascending or descending order.
- **"Show All" Pagination**: Display all records without page splits when reviewing bulk data.

---

## 💰 Income vs Expense Financial Engine

$$\text{Net Operating Profit} = \text{Total Customer Invoices} - (\text{Material Purchases} + \text{Base Payroll} + \text{Factory Expenses})$$

$$\text{Net Cash In-Hand} = \text{Customer Cash Received} - (\text{Supplier Payments} + \text{Worker Advances} + \text{Expenses Paid})$$

---

## 🧪 Testing & Verification

```bash
# 1. Static Code Analysis (0 Warnings, 0 Errors, 0 Infos)
flutter analyze

# 2. Customer & Financial Integration Tests
flutter test test/financial_customers_and_expenses_test.dart

# 3. Expense Categories & PDF Generation Tests
flutter test test/expense_categories_management_test.dart

# 4. Entire Test Suite (151 Tests across all modules)
flutter test -j 1
```

- **Flutter Analyze**: `No issues found! (0 warnings, 0 errors)`
- **Automated Tests**: **151 Passed (100% Zero Failures)**
- **macOS Release Build**: `/Users/manavramani/Desktop/OM MAVTAR GROUP.app`

---

Developed with ❤️ for **OM MAVTAR GROUP** | Version 1.0.0
