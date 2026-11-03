# 🪡 OM MAVTAR GROUP — Embroidery ERP & Production Calculator

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20%7C%20macOS-0078D6.svg)]()
[![Database](https://img.shields.io/badge/Database-SQLite%20Schema%20v1%20(100%25%20Offline)-green.svg)](https://sqlite.org)
[![Build Status](https://img.shields.io/badge/Build-v1.0.0%20Release%20Ready-success.svg)]()
[![Code Quality](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues%20(100%25%20Clean)-brightgreen.svg)]()
[![Tests](https://img.shields.io/badge/Tests-139%20Passed%20(100%25)-brightgreen.svg)]()

> **OM MAVTAR GROUP** is a modern, enterprise desktop ERP and production calculation suite tailored specifically for embroidery factories, textile workshops, and jobwork units. It provides daily multi-head stitch billing, separate Khata / Account ledgers (`Beads`, `250 Area`, `400 Area`), machine inventory (`M-01` to `M-08`), raw material and challan statement accounting, comprehensive **Employee & Upad (Advance Salary) Ledger**, a **Recycle Bin with 1-Click Restoration**, JSON backup/restore, interactive analytics charts, and native Microsoft Excel exports — operating **100% offline with zero dummy data on SQLite Version 1**.

---

## 📖 Quick Hindi Overview (ऐप का संपूर्ण परिचय)

यह सॉफ्टवेयर विशेष रूप से **OM MAVTAR GROUP** और एम्ब्रॉयडरी कारखानों के लिए विकसित किया गया एक ऑल-इन-वन डेस्कटॉप सॉफ्टवेयर है:

1. **👥 कर्मचारी विवरण, डायनामिक रोल्स एवं 3-व्यू उपल/उपाड़ (Advance) और पगार हिसाब**:
   - कर्मचारियों का पूरा विवरण (नाम, लिंग/जेंडर, पद/रोल जैसे Master, Operator, Karigar, Helper, Designer, Checker, Manager, फोन नंबर, मासिक पगार, जॉइनिंग डेट, और सक्रिय स्थिति)।
   - **डायनामिक रोल्स**: यूजर जब चाहे नए रोल्स जोड़, अपडेट या डिलीट कर सकता है।
   - **उपाड़ (Advance Upad) खाता व 3-व्यूज**:
     - 1. *Employee Directory Cards*: सुंदर विजुअल कार्ड्स।
     - 2. *Master Payroll & Upad Register*: सभी कर्मचारियों का एक साथ फाइनल उपाड़, पगार व बाकी राशि का सामूहिक रजिस्टर।
     - 3. *All Upads History & Ledger*: पूरी पुरानी तारीखवार उपाड़ हिस्ट्री, जिसे स्टेटस व तारीख से आसानी से फिल्टर किया जा सकता है।
   - **मासिक पगार सैटलमेंट (Salary Settlement)**: 1-क्लिक में उपाड़ काटकर शुद्ध पगार चुकाने का वाउचर और नया चक्र रीसेट।
2. **📲 WhatsApp उपाड़ रसीद, मानवाचक संबोधन एवं संपूर्ण मैसेज ऑडिट लॉग (WhatsApp Receipts & Message Logs)**:
   - **मानवाचक संबोधन (Respectful Honorific Salutations)**: कर्मचारी के नाम के साथ सम्मानजनक प्रत्यय (हिन्दी में: *"नमस्ते [नाम] जी,"*, अंग्रेज़ी में: *"Dear [Name] ji,"*).
   - **OM MAVTAR GROUP ब्रांडिंग**: प्रत्येक पावती और खातावही के शीर्ष व पादलेख (Header/Footer) में कंपनी का नाम *"OM MAVTAR GROUP - कढ़ाई उत्पादन प्रबंधन"* स्पष्ट रूप से अंकित रहता है।
   - **મોકલેલા મેસેજનો ઓડિટ રેકોર્ડ (Sent Message History & Audit Logs)**: ક્યારે, ક્યા નંબરેથી, કોને અને શું મેસેજ મોકલ્યો તેનો સંપૂર્ણ SQLite રેકોર્ડ (`whatsapp_logs`).
3. **🗑️ रीसायकल बिन (Recycle Bin - क्लीन रीस्टोर एवं स्थायी डिलीट)**:
   - कारखाने में कोई भी रिकॉर्ड गलती से डिलीट होने पर सीधे रीसायकल बिन में सुरक्षित जाता है।
   - **केवल २ विकल्प**: 'Restore' (पुनर्स्थापित) अथवा 'Permanent Delete' (कड़े स्थायी निष्कासन)।
   - **शून्य अवशिष्ट स्टोरेज**: रीसायकल बिन से डिलीट करने पर रिकॉर्ड SQLite से पूरी तरह नष्ट हो जाता है।
4. **📁 डायरेक्ट स्क्रीन फीचर-वाइज आर्किटेक्चर (Direct Feature-Wise Screen Structure)**:
   - सभी स्क्रीन्स सीधे `lib/screens/` के अंतर्गत व्यवस्थित हैं।
5. **🌐 शुद्ध बहुभाषी व्यवस्था (Pure Multi-Language Localization - Default English)**:
   - मिश्रित खिचड़ी भाषा समाप्त; अलग-अलग शुद्ध भाषा फाइल्स (`app_en.dart`, `app_guj.dart`, `app_hindi.dart`).
   - डिफ़ॉल्ट भाषा अंग्रेज़ी (`en`).
6. **✨ क्लीन सॉफ्टवेयर इंटरफ़ेस (Clean UI - Zero Demo Clutter)**:
   - सभी स्क्रीन्स से "Help & Demo" बटन्स और FAQ सेक्शन हटाकर केवल स्पष्ट **कैलकुलेशन फ़ॉर्मूला गाइड** और **सैंडबॉक्स** रखा गया है।
7. **💾 100% क्लीन डेटाबेस (Database Version 1 - Zero Dummy Data)**:
   - कोई भी डमी या टेस्ट डेटा नहीं है। सभी टेबल्स फ्रेश इंस्टॉलेशन पर वर्शन 1 के तहत तैयार होती हैं।
8. **🖥️ डेस्कटॉप रिलीज़ बिल्ड (Desktop Release Ready)**:
   - macOS रिलीज़ बिल्ड (`OM MAVTAR GROUP.app`, 65.2 MB) Desktop पर सीधे उपलब्ध।
9. **🧹 इनपुट फील्ड्स का पूर्ण सरलीकरण (Zero Extra Fields - No Notes, No GST, No Address)**:
   - ऑपरेटर के समय और त्रुटि को बचाने के लिए **Notes, GST Number, और Address** के इनपुट फील्ड्स को सभी डायलॉग्स (Material Product, Record, Employee, Accounts, Upad, Supplier) से पूर्णतः हटा दिया गया है।
   - पुराने बैकअप में यदि ये फील्ड्स हों तो सिस्टम उन्हें सुरक्षित रूप से इग्नोर करता है और सारा सही डेटा लोड करता है।
10. **🪡 "Dhaga" का शुद्ध अंग्रेज़ी अनुवाद "Thread"**:
   - अंग्रेज़ी भाषा मोड में अब सभी जगह 'Dhaga' के स्थान पर शुद्ध अंग्रेज़ी शब्द **"Thread"** (Tabs, Category pills, Product cards, Filters) प्रदर्शित होता है।
   - डेटाबेस में 'Thread', 'Dhaga', और 'Daga' तीनों का पूर्णतः बैकवर्ड-કમ્પેટીબલ મિલાન હોતા હૈ.

---

## 🌟 Core System Modules (મુખ્ય સિસ્ટમ મોડ્યુલ્સ)

### 1. 👥 Employee Management, Dynamic Roles & 3-View Upad Ledger (કર્મચારી, રોલ અને ઉપાડ ખાતાવહી)
- **Dynamic Role Management (ડાયનેમિક રોલ વ્યવસ્થાપન)**:
  - યુઝર પોતાની ફેક્ટરી મુજબ ગમે ત્યારે નવા રોલ ઉમેરી શકે છે (`Operator`, `Master`, `Karigar`, `Helper`, `Designer`, `Checker`, `Manager`, `Supervisor`, `Thread Cutter`, `Other`, વગેરે).
  - રોલનું નામ બદલતાં જ તે રોલ ધરાવતા તમામ કર્મચારીઓ આપમેળે અપડેટ થઈ જાય છે.
- **3-View Comprehensive Navigation (૩ મુખ્ય વ્યુઝ)**:
  1. `કર્મચારી કાર્ડ્સ (Employee Directory)`: રિસ્પોન્સિવ વિઝ્યુઅલ કાર્ડ્સ, જેમાં ૩-સ્તંભ નાણાકીય પિલ્સ (માસિક પગાર, બાકી ઉપાડ, ચૂકવવાપાત્ર રકમ) દર્શાવેલ છે.
  2. `સર્વગ્રાહી પગાર & ઉપાડ રજિસ્ટર (Master Payroll & Upad Register)`: ફેક્ટરીના તમામ કર્મચારીઓનો એક જ ટેબલમાં સામૂહિક હિસાબ (નામ, રોલ, ફોન, માસિક પગાર, કુલ ઐતિહાસિક ઉપાડ, ચાલુ પેન્ડિંગ ઉપાડ, અને ચોખ્ખો બાકી પગાર) સાથે ગ્રાન્ડ ટોટલ ફૂટર બાર.
  3. `તમામ ઉપાડ ઇતિહાસ અને લેજર (All Upads History & Ledger)`: ફેક્ટરીમાં ક્યારે અને કેટલો ઉપાડ થયો તેની સંપૂર્ણ તારીખવાર હિસ્ટ્રી. કર્મચારી મુજબ, સ્ટેટસ મુજબ (પેન્ડિંગ કે સેટલ), તારીખ મુજબ અને સર્ચ ફિલ્ટર સાથે.
- **વ્યક્તિગત કર્મચારી ખાતાવહી સ્ટેટમેન્ટ (Individual Employee Khata Statement)**:
  - કોઈપણ કર્મચારી પર ક્લિક કરતાં તેનું વિગતવાર ખાતાવહી પત્રક ખુલે છે: મૂળ પગાર, કુલ ઐતિહાસિક ઉપાડ, અગાઉ સેટલ થયેલ રકમ, ચાલુ મહિનાનો ઉપાડ અને ચોખ્ખો બાકી પગાર સાથે તમામ ટ્રાન્ઝેક્શન્સની ટાઇમલાઇન.
- **Advance Upad Tracking**: તહેવાર, બીમારી કે જરૂરિયાત પેટે આપેલ ઉપાડની તારીખવાર નોંધણી અને લાઇવ પ્રિવ્યૂ:
  $$\text{Net Remaining Salary (બાકી પગાર)} = \text{Monthly Base Salary} - \sum \text{Unsettled Upad Amounts}$$
- **Cycle Settlement**: મહિનો પૂરો થતાં તમામ ઉપાડ સેટલ કરીને ચોખ્ખો પગાર વાઉચર જનરેટ કરવો અને નવો મહિનો શૂન્ય ઉપાડથી શરૂ કરવો.
- **4 Live KPI Cards**:
  - `કુલ સક્રિય કર્મચારીઓ (Active Employees)`
  - `માસિક કુલ પગાર (Monthly Base Payroll)`
  - `કુલ પેન્ડિંગ ઉપાડ (Total Pending Advance Upad)`
  - `ચોખ્ખો બાકી ચૂકવવાપાત્ર પગાર (Net Payable Balance)`

### 2. 📲 WhatsApp Advance Upad Receipts, Logs & Audit Trail (WhatsApp ઉપાડ રસીદ અને મેસેજ રેકોર્ડ)
- **માનવાચક સન્માનપૂર્વક સંબોધન (Respectful Honorific Suffix Salutations)**:
  - અતિશય ઔપચારિકતા (જેમ કે *"आदरणीया मैडम"*) દૂર કરીને કારખાના/ઓફિસ માટે અત્યંત સહજ અને આદરપૂર્ણ માનવાચક સંબોધન:
    - હિન્દી: *"नमस्ते [નામ] જી,"* (દા.ત. *"नमस्ते रमेश जी,"*)
    - અંગ્રેજી: *"Dear [Name] ji,"* (દા.ત. *"Dear Ramesh ji,"*)
- **કંપની બ્રાન્ડિંગ (OM MAVTAR GROUP Branding)**:
  - દરેક ઉપાડ રસીદ અને ખાતાવહી સ્ટેટમેન્ટમાં કંપનીનું નામ સ્પષ્ટ રીતે સમાવિષ્ટ:
    - હેડર: `💐 *OM MAVTAR GROUP - अग्रिम वेतन / उपाड़ पावती* 💐`
    - ફૂટર: `🏢 *OM MAVTAR GROUP - कढ़ाई उत्पादन प्रबंधन*`
- **મોકલેલા મેસેજનો સંપૂર્ણ ઓડિટ રેકોર્ડ (WhatsApp Sent Message Logs & Audit Trail)**:
  - કારખાનામાં ક્યારેય પણ મોકલેલા તમામ મેસેજનો સંપૂર્ણ રેકોર્ડ SQLite `whatsapp_logs` ટેબલમાં સેવ થાય છે:
    - **શું મેસેજ મોકલ્યો (`message`)**: મોકલેલ રસીદ કે ખાતાવહીનું સંપૂર્ણ લખાણ.
    - **ક્યા નંબરેથી મોકલ્યો (`sender_phone`)**: એડમિન/મેનેજરનો નંબર.
    - **ક્યા કર્મચારીને મોકલ્યો (`employee_name`, `recipient_phone`, `employee_id`)**: કર્મચારીનું નામ અને મોબાઈલ નંબર.
    - **ક્યારે મોકલ્યો (`created_at`)**: ચોક્કસ તારીખ અને સમય.
    - **રકમ (`amount`)**: ઉપાડની રકમ.
- **ઇન્ટરેક્ટિવ WhatsApp હિસ્ટ્રી ડાયલોગ (`WhatsAppHistoryDialog`)**:
  - `સેટિંગ્સ સ્ક્રીન`, `કર્મચારી સ્ક્રીન` અને `ખાતાવહી સ્ટેટમેન્ટ` માંથી ગમે ત્યારે ખોલી શકાય છે.
  - કર્મચારી મુજબ ડ્રોપડાઉન ફિલ્ટર, મેસેજ ટાઇપ ફિલ્ટર, અને સર્ચ બાર (નામ, નંબર કે મેસેજ દ્વારા સર્ચ).
  - ૩ KPI સમરી કાર્ડ્સ: કુલ મોકલેલા મેસેજ, કુલ ઉપાડ રકમ અને કુલ કર્મચારીઓ.
  - દરેક રેકોર્ડ માટે:
    - **સંપૂર્ણ મેસેજ જુઓ (View Full)**: મોકલેલ મેસેજનું આખું લખાણ જોવા માટે.
    - **મેસેજ કોપી કરો (Copy)**: ૧-ક્લિકમાં ક્લિપબોર્ડ પર કોપી.
    - **ફરી મોકલો (Resend)**: ૧-ક્લિકમાં WhatsApp પર ફરી મોકલવાની સુવિધા.
    - **ડિલીટ કરો (Delete)**: રેકોર્ડ દૂર કરવાની સુવિધા.
- **સંપૂર્ણ વિગતવાર રસીદ ટેમ્પલેટ (Comprehensive Itemized Receipt)**:
  - કર્મચારીનું નામ અને હોદ્દો (Name & Role)
  - ઉપાડની રકમ (Upad Amount ₹) અને તારીખ (Date)
  - ઉપાડનું કારણ / નોંધ (Notes / Purpose)
  - મૂળ માસિક ફિક્સ પગાર (Monthly Base Salary ₹)
  - ચાલુ સાયકલનો કુલ પેન્ડિંગ ઉપાડ (Total Current Pending Upad ₹)
  - ચોખ્ખો બાકી રહેતો અંદાજિત પગાર (Net Estimated Remaining Balance ₹)
  - વ્યવસ્થાપક/મેનેજરનો સંપર્ક નંબર (Manager Contact Phone)
- **૩ ભાષા સપોર્ટ (Multi-Language Support)**:
  - `Both`: હિન્દી અને અંગ્રેજી બંનેમાં સમાન નાણાકીય વિગતો સાથે દ્વિભાષી રસીદ.
  - `Hindi (हिन्दी)`: શુદ્ધ અને વ્યાવસાયિક હિન્દી રસીદ.
  - `English`: સ્ટાન્ડર્ડ અંગ્રેજી રસીદ.
- **મેનેજર અને કર્મચારી નંબર મેનેજમેન્ટ**:
  - મેનેજરનો મોબાઇલ નંબર Settings માં સુરક્ષિત સેવ રહે છે. જો સેટ ન હોય, તો રસીદ મોકલતી વખતે જ ડાયલોગ દ્વારા પૂછીને સેવ કરવામાં આવે છે.
  - કર્મચારીના પ્રોફાઇલમાં નંબર ન હોય તો પણ મોકલતા પહેલા તરત નંબર દાખલ કરવાની સુવિધા.
- **ડિફૉલ્ટ ઓટો-સેન્ડ સંપૂર્ણપણે બંધ (Default Auto-Send Strictly OFF)**:
  - યુઝરની સ્પષ્ટ જરૂરિયાત મુજબ ઓટો-સેન્ડ ડિફૉલ્ટ રીતે બંધ (OFF) રહે છે.
  - Settings માંથી જો યુઝર સ્વિચ ચાલુ કરે, તો જ નવો ઉપાડ નોંધાતા આપોઆપ WhatsApp ખૂલશે.
  - કોઈપણ સમયે મેન્યુઅલ "WhatsApp મોકલો" બટન દ્વારા ૧-ક્લિકમાં રસીદ મોકલી શકાય છે.
- **ખાતાવહી શેરિંગ (Share Complete Khata Statement)**:
  - કર્મચારીના ખાતાવહી સ્ટેટમેન્ટ ડાયલોગમાંથી સમગ્ર ખાતાનો હિસાબ પણ ૧-ક્લિકમાં WhatsApp પર મોકલી શકાય છે.

### 3. 🗑️ Recycle Bin & 1-Click Restoration (કચરાપેટી અને રીસ્ટોર)
- **7 એન્ટિટીઝનું સોફ્ટ-ડિલીટ પ્રોટેક્શન**:
  - Production Records
  - Material Items & Challans
  - Embroidery Machines (`M-01` થી `M-08`)
  - Accounts / Khatas (`Beads`, `250 Area`, `400 Area`)
  - Material Products Master
  - Suppliers Directory
  - Employees & Advance Upads
- **Recycle Bin Actions**:
  - **Restore Record**: ૧-ક્લિકમાં રેકોર્ડ મૂળ ટેબલમાં પાછો પહોંચી જાય છે.
  - **Restore All**: તમામ ડીલીટ થયેલ રેકોર્ડ્સ એકસાથે રીસ્ટોર કરવાની સુવિધા.
  - **Permanently Delete**: જરૂર ન હોય તેવા રેકોર્ડને કાયમી ડિલીટ કરવો.
  - **Empty Recycle Bin**: એક ક્લિકમાં કચરાપેટી સાફ કરવી.

### 3. 📊 Multi-Khata Dashboard & Production Hub
- **Financial Market Trend Chart**: ૨-મિનિટ ઓટો-સિન્ક સાથે લાઇવ ટ્રેન્ડ ગ્રાફ (`All Factory`, `Beads`, `250 Area`, `400 Area`).
- **Dedicated Khata Tables**: દરેક ખાતાની અલગ પ્રોડક્શન ટેબલ, સરવાળા, અને પેજીનેશન.
- **Inline Table Editing**: ટેબલમાં જ દર (Rate) કે હેડ્સ (Heads) પર ક્લિક કરી સીધો નવો આંકડો નાખી ઓટો-સેવ કરવાની સુવિધા.

### 4. 🪡 Production Entry & 3-Step Mathematical Engine
- **અધિકૃત 3-સ્ટેપ ગણતરી સૂત્ર**:
  $$\text{Final Stitch} = \frac{\text{Total Stitch}}{1,000}$$
  $$\text{Base Amount (₹)} = \text{Final Stitch} \times \text{Rate (₹)}$$
  $$\text{Final Amount (₹)} = \text{Base Amount (₹)} \times \text{Machine Heads}$$
- **Shift Tracking**: Day Shift (☀️) અને Night Shift (🌙).

### 5. 📦 Material & Daily Challan Calculation Statement (ચલાન ગણતરી પત્રક)
- **6 ડેસ્કટોપ ટેબ્સ**: Challan Register, Sequence, Beads, Thread, Products Master, Suppliers Master.
- **Challan Calculation Statement Sheet**:
  - વેપારી કાર્ડ, ચલાન રસીદ બેજ, તારીખ અને કેટેગરી ટેગ્સ.
  - આઇટમાઇઝ્ડ લેજર ટેબલ: $\text{Qty} \times \text{Rate} = \text{Amount}$ ગણતરી પિલ અને બોલ્ડ એમરાલ્ડ ગ્રીન રકમ.
  - સ્ટેપ-બાય-સ્ટેપ ગણતરી બ્રેકડાઉન કાર્ડ અને ફાઇનલ ચૂકવવાપાત્ર વાઉચર.

### 6. 💾 1-Click Backup & Restore
- **Autonomous JSON Export**: આખા સોફ્ટવેરનો ડેટા (પ્રોડક્શન, મટીરિયલ, કર્મચારી, ઉપાડ, સેટિંગ્સ) સિંગલ JSON ફાઇલમાં બેકઅપ થાય છે.
- **Seamless Recovery**: નવા કોમ્પ્યુટરમાં આ ફાઇલ સિલેક્ટ કરતાં જ તમામ ડેટા પૂર્વવત થઈ જાય છે.

---

## 🏗️ Feature-Wise Directory Architecture (આર્કિટેક્ચર માળખું)

```
lib/
├── core/                        # ડિઝાઇન સિસ્ટમ અને ગણતરી એન્જિન
│   ├── app_theme.dart
│   └── calculation_engine.dart
├── data/                        # ડેટાબેઝ હેલ્પર (Version 1) અને સેમ્પલ કેટલોગ
│   ├── database_helper.dart
│   └── sample_data.dart
├── features/                    # ફીચર-વાઇઝ મોડ્યુલર સિસ્ટમ
│   ├── employees/               # કર્મચારી પ્રોફાઇલ, ઉપાડ ખાતાવહી, પગાર સેટલમેન્ટ
│   │   ├── screens/
│   │   │   ├── add_edit_employee_dialog.dart
│   │   │   ├── add_upad_dialog.dart
│   │   │   ├── employee_settlement_dialog.dart
│   │   │   └── employees_screen.dart
│   │   └── employees_feature.dart
│   ├── production/              # દૈનિક પ્રોડક્શન એન્ટ્રી અને ડેશબોર્ડ
│   ├── materials/               # કાચો માલ, સિક્વન્સ, ધાગા અને ચલાન રજીસ્ટર
│   ├── masters/                 # મશીન કેટલોગ, ખાતાવહી (Khatas), દરો
│   ├── analytics/               # રિપોર્ટ્સ, ચાર્ટ્સ અને એક્સેલ એક્સપોર્ટ
│   ├── recycle_bin/             # કચરાપેટી અને ૧-ક્લિક રીસ્ટોરેશન
│   ├── backup_restore/          # ડેટાબેઝ જેસન બેકઅપ અને રીસ્ટોર
│   ├── settings/                # કારખાના રૂપરેખા અને ડાર્ક મોડ
│   └── features.dart            # સેન્ટ્રલ ફીચર બેરલ એક્સપોર્ટ
├── models/                      # ડેટા મોડલ્સ
├── providers/                   # ગ્લોબલ સ્ટેટ મેનેજમેન્ટ (ProductionProvider)
├── screens/                     # બેકવર્ડ-કમ્પેટીબલ સ્ક્રીન એક્સપોર્ટ્સ
└── widgets/                     # પુનઃઉપયોગી UI કમ્પોનન્ટ્સ
```

---

## 🪟 Windows Installation & Portable Distribution Guide

### 📦 Option 1: Direct Send Portable ZIP (સૌથી સરળ - કોઈ ઇન્સ્ટોલેશન નહીં!)
જો તમારે કોઈને પણ સીધો સોફ્ટવેર મોકલવો હોય કે જેથી તે તરત જ ચલાવી શકે:
1. `dist/OM_MAVTAR_Embroidery_Calculator_v1.0_Windows_x64.zip` ફાઇલ મોકલો (માત્ર 14 MB).
2. સામેવાળી વ્યક્તિ આ ZIP ને Desktop અથવા કોઈપણ ડ્રાઇવમાં Unzip / Extract કરશે.
3. ફોલ્ડર ખોલીને **`Run_OM_MAVTAR_Calculator.bat`** અથવા **`emb_cal.exe`** પર ડબલ ક્લિક કરશે.
4. સોફ્ટવેર કોઈપણ વધારાના સેટઅપ કે ઇન્ટરનેટ વગર સીધો શરૂ થઈ જશે!

### 💿 Option 2: Windows Setup Wizard (.exe Installer)
જો તમારે સેટઅપ વિઝાર્ડ વાળો ઇન્સ્ટોલર બનાવવો હોય:
1. પ્રોજેક્ટ રૂટમાં રહેલ **`build_windows_installer.bat`** પર ડબલ ક્લિક કરો.
2. આ સ્ક્રિપ્ટ આપમેળે:
   - `flutter build windows --release` કરશે.
   - `sqlite3.dll` અને તમામ ફાઇલો ચકાસશે.
   - Inno Setup કમ્પાઇલર દ્વારા `dist/OM_MAVTAR_Calculator_v1.0_Setup.exe` સિંગલ ઇન્સ્ટોલર ફાઇલ બનાવી આપશે.
3. આ સેટઅપ ફાઇલ રન કરતાં ડેસ્કટોપ આઇકોન અને સ્ટાર્ટ મેનુ સાથે સામાન્ય સોફ્ટવેરની જેમ ઇન્સ્ટોલ થશે.

---

## 🧪 Testing & Verification

પ્રોજેક્ટની ગુણવત્તા ૧૦૦% સુનિશ્ચિત કરવા માટે સંપૂર્ણ ટેસ્ટ સ્યુટ ઉપલબ્ધ છે:

```bash
# 1. સ્ટેટિક કોડ એનાલિસિસ (0 Warnings, 0 Errors, 0 Infos)
flutter analyze

# 2. કર્મચારી અને ઉપાડ મોડ્યુલ ટેસ્ટ
flutter test test/employee_and_upad_test.dart

# 3. આખો ટેસ્ટ સ્યુટ (19 ટેસ્ટ ફાઇલો, 139 ટેસ્ટ્સ)
flutter test -j 1
```

- **Flutter Analyze Status**: `No issues found! (ran in 0.7s)`
- **Automated Tests**: **139 Passed (100% Zero Failures)**
- **Database Status**: `Version 1` (Clean, Zero Dummy Data)

---

## ⚠️ वर्तमान सीमाएं एवं भविष्य के संभावित जोखिमों का विश्लेषण (Current Limitations & Future Risk Analysis)

एम्ब्रॉयडरी कारखाने के दैनिक कामकाज में सॉफ़्टवेयर को सुचारू रखने के लिए वर्तमान सीमाओं, संभावित जोखिमों और उनके समाधानों का ईमानदार एवं विस्तृत तकनीकी विश्लेषण नीचे दिया गया है:

### 1. 📌 वर्तमान में क्या-क्या सीमाएं / इश्यूज़ हैं (Current Known Limitations):

1. **सिंगल-पीसी लोकल ऑफलाइन आर्किटेक्चर (Single-PC Local SQLite Architecture)**:
   - **वर्तमान स्थिति**: डेटा केवल उसी कंप्यूटर की लोकल डिस्क (`sqflite_common_ffi` SQLite) में सुरक्षित रहता है जिस पर सॉफ़्टवेयर चल रहा है।
   - **सीमा**: यदि कारखाने में ऑफिस केबिन (मालिक) और फ्लोर (सुपरवाइज़र) पर दो अलग-अलग कंप्यूटर हैं, तो रियल-टाइम ऑटो-सिंक (LAN/Cloud) उपलब्ध नहीं है। एक कंप्यूटर का डेटा दूसरे में ले जाने के लिए Settings में जाकर 1-Click JSON Backup/Restore का उपयोग करना पड़ता है।

2. **थर्मल स्लिप प्रिंटिंग (Thermal Slip Printing via OS Print Spooler)**:
   - **वर्तमान स्थिति**: प्रोडक्शन स्लिप या उपाड़ रसीद प्रिंट करने पर सिस्टम ऑपरेटिंग सिस्टम का डिफ़ॉल्ट प्रिंट डायलॉग / PDF इंजन ओपन करता है।
   - **सीमा**: 58mm/80mm USB/Serial थर्मल प्रिंटर पर डायरेक्ट रॉ ESC/POS कमांड (बिना प्रिंट डायलॉग के तुरंत कटर चलना) नहीं भेजे जाते, बल्कि OS प्रिंट प्रिव्यू के माध्यम से प्रिंट होता है।

3. **WhatsApp रसीद भेजने की बाहरी निर्भरता (External WhatsApp Web / Desktop Dependency)**:
   - **वर्तमान स्थिति**: WhatsApp रसीद भेजने पर सिस्टम `https://wa.me/` डीप लिंक जनरेट करके डिफॉल्ट ब्राउज़र या WhatsApp Desktop ऐप को कॉल करता है।
   - **सीमा**: यदि उस कंप्यूटर पर इंटरनेट बंद है या WhatsApp लॉगिन नहीं है, तो ऐप स्वचालित बैकग्राउंड मैसेज नहीं भेज सकता। हालांकि सिस्टम ने **"Copy to Clipboard"** और **"WhatsApp Logs"** का सुरक्षित फॉलबैक दिया है, फिर भी वास्तविक डिलीवरी इंटरनेट और बाहरी WhatsApp पर निर्भर करती है।

4. **मैकओएस अनसाइंड एप्लिकेशन गेटकीपर (Unsigned macOS Gatekeeper Notice)**:
   - **वर्तमान स्थिति**: बिना ₹8,500/वर्ष Apple Developer Certificate के रिलीज़ बिल्ड तैयार किया गया है।
   - **सीमा**: जब यह `.app` किसी नए Mac कंप्यूटर पर पहली बार ट्रांसफर की जाएगी, तो macOS *"App is damaged or cannot be opened"* कहेगा। इसके लिए टर्मिनल में `xattr -cr "/Applications/OM MAVTAR GROUP.app"` चलाना पड़ता है या System Settings > Security में जाकर "Open Anyway" करना पड़ता है।

5. **दैनिक ऑटो-बैकअप अनुशासन (Manual Daily Backup Discipline)**:
   - **वर्तमान स्थिति**: सॉफ़्टवेयर में 1-क्लिक बैकअप और रीस्टोर से पहले ऑटो-सेफ्टी बैकअप मौजूद है।
   - **सीमा**: जब तक ऑपरेटर स्वयं "Export Backup" पर क्लिक नहीं करता या ऐप बंद होने पर पेनड्राइव में कॉपी नहीं करता, तब तक हार्ड डिस्क क्रैश की स्थिति में डेटा रिकवरी केवल उसी डिस्क पर निर्भर रहती है।

---

### 2. 🔮 भविष्य में क्या-क्या इश्यूज़ आ सकते हैं और उनके ठोस समाधान (Potential Future Risks & Mitigations):

| क्र. | संभावित भविष्य का जोखिम (Future Potential Risk) | उत्पन्न होने का कारण (Root Cause) | जोखिम का स्तर | ठोस निवारण एवं समाधान (Mitigation Strategy) |
| :---: | :--- | :--- | :---: | :--- |
| **१** | **अचानक बिजली गुल होने पर डेटाबेस करप्शन (Sudden Power Outage / Hard Shutdown)** | एम्ब्रॉयडरी कारखाने में हेवी मोटर या जनरेटर चेंजओवर के समय बिजली कटने पर यदि SQLite डिस्क में राइट कर रहा हो। | **मध्यम** | **समाधान**: SQLite में `PRAGMA journal_mode=WAL;` (Write-Ahead Logging) सक्षम है जो बिजली जाने पर भी डेटा सुरक्षित रखता है। साथ ही ऑपरेटर को हफ्ते में कम से कम 2 बार पेनड्राइव में JSON बैकअप लेने की सलाह दी जाती है। |
| **२** | **3-5 वर्षों के भारी डेटा (30,000+ रिकॉर्ड्स) पर गति धीमी होना** | 8 मशीनें × 2 शिफ्ट = साल के 5,840 रिकॉर्ड्स। 5 वर्षों में 30,000+ रिकॉर्ड्स होने पर पूरी लिस्ट लोड करने में देरी। | **कम** | **समाधान**: डेटाबेस में `date`, `design_no`, `machine_no`, `account_name`, और `challan_no` पर इंडेक्सिंग (Indexing) पहले से मौजूद है। भविष्य में "Yearly Archive / Financial Year Close" फीचर जोड़कर पुराने वर्षों का डेटा अलग सुरक्षित आर्काइव में रखा जा सकता है। |
| **३** | **एक्सेल खुली होने पर फाइल लॉक एरर (File Locked by Microsoft Excel)** | यदि ऑपरेटर ने पिछला एक्सपोर्ट किया हुआ एक्सेल खोला हुआ है और उसी फ़ाइल नाम पर दोबारा "Export to Excel" दबा देता है। | **मध्यम** | **समाधान**: विंडोज़ OS खुली हुई फाइल पर राइट करने की अनुमति नहीं देता। इसके समाधान हेतु एक्सपोर्ट कोड में टाइमस्टैम्पयुक्त नाम (उदा. `Om_Mavtar_Export_20261102_1830.xlsx`) जनरेट होता है और `try-catch` ब्लॉक ऑपरेटर को तुरंत "कृपया एक्सेल फ़ाइल बंद करें" का स्पष्ट संदेश दिखाता है। |
| **४** | **एक ही चालान नंबर की दोहरी एंट्री (Duplicate Challan No Entry)** | एक ही सप्लायर से अलग-अलग तारीखों में एक ही बिल नंबर गलती से दो बार टाइप हो जाना। | **निम्न** | **समाधान**: सप्लायर व चालान नंबर संयोजन पर इनलाइन चेतावनी बैनर दिखाना। |
| **५** | **विंडोज़ 125% / 150% डिस्प्ले स्केलिंग पर ओवरफ्लो (HiDPI Scaling Overflow)** | छोटे लैपटॉप (13-14 इंच) पर जब विंडोज़ डिफ़ॉल्ट रूप से 150% स्केलिंग चालू करता है तो डायलॉग्स कट सकते हैं। | **निम्न** | **समाधान**: हमारे सभी डायलॉग्स (`SingleChildScrollView` + `ConstrainedBox`) के साथ बनाए गए हैं जिससे किसी भी स्क्रीन रेजोल्यूशन पर बॉटम या साइड ओवरफ्लो नहीं होता। |
| **६** | **मल्टी-पीसी नेटवर्क की आवश्यकता (Future Multi-PC Expansion)** | भविष्य में यदि कारखाने में 3 अलग-अलग केबिन से एक साथ डेटा एंट्री करनी हो। | **दीर्घकालिक** | **समाधान**: वर्तमान मॉड्युलर प्रोवाइडर आर्किटेक्चर इतना लचीला है कि केवल डेटा लेयर में एक लोकल LAN REST API सर्वर (उदा. Node.js/Dart Shelf/PostgreSQL) जोड़कर इसे तुरंत मल्टी-यूज़र नेटवर्क क्लाइंट में बदला जा सकता है। |

---

## 🛠️ Technology Stack

- **Framework**: Flutter 3.x (Desktop Channel)
- **Language**: Dart 3.x
- **Desktop Targets**: Windows 10/11 (x64) & macOS Desktop
- **Database**: `sqflite_common_ffi` (2.4.5) + native `sqlite3.dll`
- **State Management**: `provider` (6.1.5)
- **Spreadsheet Generation**: `excel` (4.0.6)
- **UI & Architecture**: Feature-Driven Architecture, Vanilla Material 3

---

Developed with ❤️ for **OM MAVTAR GROUP** | Version 1.0.0
