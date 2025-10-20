# GrowERP B2C and B2B Party Model Documentation

## Overview

GrowERP implements a sophisticated party model that seamlessly supports both Business-to-Consumer (B2C) and Business-to-Business (B2B) interactions. The system distinguishes between **individuals (persons)** and **organizations (companies)**, with support for relationships where individuals represent or work for companies.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Party Types](#party-types)
3. [B2C Model: Direct Consumer Relationships](#b2c-model-direct-consumer-relationships)
4. [B2B Model: Company Representation](#b2b-model-company-representation)
5. [UI/UX Behavior](#uiux-behavior)
6. [Ordering and Accounting](#ordering-and-accounting)
7. [Data Model](#data-model)
8. [Implementation Details](#implementation-details)
9. [Use Cases](#use-cases)
10. [Technical Considerations](#technical-considerations)

---

## Core Concepts

### Parties

A **party** is the fundamental entity in GrowERP representing any actor in business transactions:
- **Person**: An individual (customer, employee, supplier contact, lead)
- **Company**: An organization (customer company, supplier company, internal organization)

### Relationships

The system supports three primary party relationship patterns:

1. **Standalone Person** (B2C): A person with no company affiliation
   - Direct buyer/seller in transactions
   - Direct accounting records
   - Independent identity

2. **Person in Company** (B2B): A person representing or employed by a company
   - Secondary identity as an employee/representative
   - Company is primary in transactions
   - Accounting records belong to the company

3. **Standalone Company** (B2B): An organization with no specific employees listed
   - Direct transactional party
   - Company accounting records

---

## Party Types

### PartyType Enum

```dart
enum PartyType {
  person,      // Individual with no company affiliation
  company,     // Organization (may have employees)
  employee,    // Individual representing a company
}
```

### Party Roles

```dart
enum Role {
  company,      // Internal organization
  employee,     // Works for the internal company
  customer,     // Buys products/services
  lead,         // Potential customer
  supplier,     // Sells products/services
  unknown,      // Undefined role
}
```

---

## B2C Model: Direct Consumer Relationships

### Definition

In the B2C (Business-to-Consumer) model, transactions occur directly between the business and individual consumers who have **no associated company entity**.

### Key Characteristics

- **Single Identity**: The person is the sole party to transactions
- **Direct Relationships**: Orders, invoices, and payments are directly with the individual
- **Simplified Record Keeping**: Accounting records belong to the person
- **Independent Customers**: Each customer maintains their own identity and transaction history

### Example Scenario

```
E-commerce Platform → Individual Customer (Alice)
- Alice places order as individual
- Invoice issued to Alice
- Payment received from Alice
- Accounting: Sales to Alice (person entity)
- No company intermediary
```

### Implementation

**B2C User Record:**
```dart
User(
  firstName: 'customer1',
  lastName: 'lastName1',
  role: Role.customer,
  company: null,  // ← No company affiliation
  email: 'customer@example.com',
  // ...
)
```

**UI Behavior**: When displayed in the system, a B2C customer shows only the user details in the **UserDialog**.

---

## B2B Model: Company Representation

### Definition

In the B2B (Business-to-Business) model, transactions occur between organizations. When an individual represents or works for a company, the **company becomes the primary transactional party**, even though business communication may occur through the individual representative.

### Key Characteristics

- **Dual Identity**: Person + Company relationship
  - Primary: Company identity for transactions and accounting
  - Secondary: Individual as employee/representative for communication
  
- **Hierarchical Records**: 
  - Company maintains primary records
  - Individual employee is listed under the company
  - Transactions credited to company, not individual
  
- **Unified Accounting**: All financial records for a company's representatives aggregate at the company level

- **Organizational Context**: The company provides context and authority for transactions

### Example Scenario

```
GrowERP Sales Team ← Company A (ABC Corp)
                    ├── Employee: John (Account Manager)
                    ├── Employee: Sarah (Procurement Officer)
                    └── Employee: Mike (Operations Manager)

Transaction Flow:
- John (employee) initiates purchase order
- Order is recorded under ABC Corp (company)
- Invoice issued to ABC Corp
- Payment received by ABC Corp
- Accounting: Purchase from ABC Corp (company entity), not from John
```

### Implementation

**B2B User Record with Company:**
```dart
User(
  firstName: 'customer2',
  lastName: 'lastName2',
  role: Role.customer,
  company: Company(
    name: 'ABC Corporation',
    role: Role.customer,
    email: 'contact@abc-corp.com',
    telephoneNr: '555-1234567',
    // ... company details ...
  ),
)
```

**UI Behavior**: When displayed in the company_user context, a B2B customer shows as the **CompanyDialog** with the employee listed under it.

---

## UI/UX Behavior

### Display Logic

The GrowERP UI intelligently displays the appropriate dialog based on the party structure:

#### 1. **User List Context** (Direct User Management)

```dart
// Display rules in user_list.dart
for (User user in users) {
  show: UserDialog(user)  // Always show user perspective
}
```

- Displays `UserDialog` for all users
- Used in employee management, lead management
- Focuses on individual details regardless of company affiliation

#### 2. **Company-User List Context** (B2C/B2B Integration)

```dart
// Display rules in company_user_list.dart
if (companyUser.type == PartyType.company) {
  show: CompanyDialog(company)  // Pure company entity
} else if (companyUser.company != null) {
  show: CompanyDialog(
    company_with_employee: companyUser.company,
    employee: companyUser.getUser()
  )  // Company with employee representation
} else {
  show: UserDialog(user)  // Standalone person (B2C)
}
```

**Decision Matrix:**

| Scenario | Type | Company | Display | Context |
|----------|------|---------|---------|---------|
| Standalone customer | person | null | UserDialog | B2C direct sales |
| Employee of customer | person | ABC Corp | CompanyDialog | B2B account management |
| Pure company (no employee details) | company | (self) | CompanyDialog | B2B direct company |

### User Journey Examples

#### B2C Customer Journey

```
1. Browse as: Alice (individual)
   ↓
2. Click on customer record
   ↓
3. See: UserDialog with Alice's details
   ├── Name: Alice Smith
   ├── Email: alice@personal.com
   ├── Phone: 555-1111111
   ├── Address: 123 Main St
   └── Related Company: [NONE]
   ↓
4. Create order as: Alice (person)
   ↓
5. Accounting recorded as: Sale to Alice
```

#### B2B Employee-Company Journey

```
1. Browse as: John (employee of ABC Corp)
   ↓
2. Click on customer record in company-user view
   ↓
3. See: CompanyDialog showing:
   ├── Company: ABC Corporation
   ├── Company Email: contact@abc-corp.com
   ├── Company Phone: 555-2222222
   ├── Employees:
   │   ├── John Smith [selected]
   │   ├── Sarah Johnson
   │   └── Mike Wilson
   └── Company Address: 456 Business Ave
   ↓
4. Create order as: ABC Corp (company)
   with contact person: John
   ↓
5. Accounting recorded as: Sale to ABC Corp (company entity)
```

---

## Ordering and Accounting

### Critical Business Rule

**All ordering and accounting is fundamentally transacted between persons/parties, but when a person relates to a company, the record keeping shifts to the company level.**

### Ordering Model

#### B2C Ordering

```
Order Document:
├── Customer: Alice Smith (Person)
├── Recipient Address: Alice's address
├── Contact: Alice's email/phone
└── Accounting Party: Alice

Order Processing:
├── Create: Order for Alice
├── Confirm: Order by Alice
├── Fulfill: Deliver to Alice
└── Invoice: Bill to Alice
```

#### B2B Ordering

```
Order Document:
├── Customer: ABC Corporation (Company)
├── Contact Person: John Smith (Employee)
├── Recipient Address: ABC Corp's address
├── Contact: John's email/phone (for communication)
└── Accounting Party: ABC Corporation

Order Processing:
├── Create: Order by John for ABC Corp
├── Confirm: Order from ABC Corp (with John as contact)
├── Fulfill: Deliver to ABC Corp
└── Invoice: Bill to ABC Corp (not to John)
```

### Accounting Model

#### B2C Accounting Records

```
Journal Entry - Sale to Individual:
├── Debit: Cash/Accounts Receivable (Alice)
│   └── Reference: Alice Smith
├── Credit: Sales Revenue
│   └── Reference: B2C Direct Sale
└── Customer Ledger:
    └── Alice Smith: +$500 (transaction amount)
```

**Key Point**: Accounting records identify the customer as the individual person.

#### B2B Accounting Records

```
Journal Entry - Sale to Company:
├── Debit: Cash/Accounts Receivable (ABC Corp)
│   └── Reference: ABC Corporation (with employee John noted for communication)
├── Credit: Sales Revenue
│   └── Reference: B2B Company Sale
└── Customer Ledger:
    └── ABC Corporation: +$5000 (transaction amount)
       └── Note: Contact person John Smith
```

**Key Point**: Accounting records identify the customer as the company, NOT the employee. The employee is noted for communication/reference purposes only.

### Practical Impact

#### For B2C Businesses

- Track individual customer lifetime value
- Individual payment terms and credit limits
- Direct loyalty programs (customer-specific)
- Simple credit analysis (individual creditworthiness)

#### For B2B Businesses

- Track company volume and profitability
- Company-level payment terms and credit limits
- Account-based marketing (company-specific)
- Complex credit analysis (company balance sheet, parent company guarantees)
- Multiple contacts per customer company (different employees)

### Multi-Contact Management (B2B)

A single company may have multiple employee contacts:

```dart
Company: ABC Corporation
├── Employee 1: John Smith (Account Manager)
│   └── Email: john@abc-corp.com
│   └── Orders: 15 orders worth $50K
├── Employee 2: Sarah Johnson (Procurement)
│   └── Email: sarah@abc-corp.com
│   └── Orders: 8 orders worth $30K
└── Employee 3: Mike Wilson (Operations)
    └── Email: mike@abc-corp.com
    └── Orders: 12 orders worth $45K

Company Total: $125K in orders

Accounting Aggregates: All orders to ABC Corporation
↓
Company Account: +$125K (regardless of which employee placed it)
```

---

## Data Model

### Core Entities

#### Person/User Entity

```dart
class User {
  String partyId;           // Unique person identifier
  String pseudoId;          // Display/reference ID
  String firstName;
  String lastName;
  String email;
  String telephoneNr;
  String url;
  
  Role role;                // customer, employee, lead, supplier, etc.
  
  Company? company;         // ← B2B relationship
  // When NOT null: person represents/works for this company
  // When null: standalone person (B2C)
  
  Address? address;
  PaymentMethod? paymentMethod;
  // ...
}
```

#### Company Entity

```dart
class Company {
  String partyId;           // Unique company identifier
  String pseudoId;          // Display/reference ID
  String name;
  
  Role role;                // customer, supplier, company (internal), etc.
  
  String email;
  String telephoneNr;
  String url;
  
  Address? address;
  PaymentMethod? paymentMethod;
  
  List<User> employees;     // ← B2B relationships
  // List of employees/representatives who work for this company
  
  Currency currency;
  Decimal vatPerc;
  Decimal salesPerc;
  // ...
}
```

#### CompanyUser Entity (Bridge Model)

The `CompanyUser` model represents a unified view that can be either a person or a company:

```dart
class CompanyUser {
  PartyType type;           // company, person, or employee
  
  String partyId;
  String pseudoId;
  String name;              // firstName+lastName for person, name for company
  String email;
  String telephoneNr;
  String url;
  
  Role role;                // customer, supplier, etc.
  
  Company? company;         // ← When type=person and company is set
  List<User>? employees;    // ← When type=company
  
  // Helper method
  Company? getCompany() {
    if (type == PartyType.company) {
      return Company(...);  // Create from this entity
    } else {
      if (company != null) {
        // Return company with this person as employee
        return company.copyWith(
          employees: [this.getUser()],
        );
      } else {
        // No company - return null
        return null;
      }
    }
  }
  
  User? getUser() {
    // Return user representation
  }
}
```

### Relational Model

```
Customers Table
├── customer_id: 1001
├── type: "person"
├── name: "Alice Smith"
├── company_id: NULL        → B2C (standalone)
├── role: "customer"
└── ...

Customers Table
├── customer_id: 1002
├── type: "person"
├── name: "John Smith"
├── company_id: 2001        → B2B (belongs to company 2001)
├── role: "customer"
└── ...

Companies Table
├── company_id: 2001
├── name: "ABC Corporation"
├── role: "customer"
├── ...

Employees Table (join table)
├── employee_id: 1002       → John Smith
├── company_id: 2001        → Works for ABC Corp
└── ...
```

---

## Implementation Details

### Company-User List View

The `company_user_list.dart` implements the display logic that determines what to show:

```dart
class CompanyUserList extends StatelessWidget {
  build(context) {
    // Get company users from backend
    List<CompanyUser> companiesUsers = fetchCompanyUsers();
    
    // Build list of items
    return ListView.builder(
      itemBuilder: (context, index) {
        CompanyUser item = companiesUsers[index];
        
        // Determine what dialog to show
        Widget dialog;
        if (item.type == PartyType.company) {
          // Pure company - show company details
          dialog = ShowCompanyDialog(item.getCompany()!);
        } else if (item.company != null) {
          // Person with company - show company with employee
          dialog = ShowCompanyDialog(item.getCompany()!);
        } else {
          // Standalone person - show user details
          dialog = ShowUserDialog(item.getUser()!);
        }
        
        return ListItem(
          onTap: () => showDialog(dialog),
        );
      },
    );
  }
}
```

### Ordering Flow

#### B2C Order Creation

```dart
void createB2COrder(User customer) {
  // Customer is standalone person
  Order order = Order(
    customerId: customer.partyId,        // Direct person ID
    customerName: "${customer.firstName} ${customer.lastName}",
    customerEmail: customer.email,
    shippingAddress: customer.address,
    billToPartyId: customer.partyId,     // Bill to person
    billToName: "${customer.firstName} ${customer.lastName}",
  );
  
  submitOrder(order);
}
```

#### B2B Order Creation

```dart
void createB2BOrder(CompanyUser companyUser) {
  // Get the company with employee info
  Company company = companyUser.getCompany()!;
  User employee = companyUser.getUser()!;
  
  Order order = Order(
    customerId: company.partyId,         // Company ID (not employee)
    customerName: company.name,
    contactPersonId: employee.partyId,   // For communication
    contactPersonName: "${employee.firstName} ${employee.lastName}",
    contactPersonEmail: employee.email,
    shippingAddress: company.address,
    billToPartyId: company.partyId,      // Bill to company (not employee)
    billToName: company.name,
  );
  
  submitOrder(order);
}
```

### Accounting Integration

#### B2C Transaction Recording

```dart
void recordB2CTransaction(User customer, double amount) {
  // Create journal entry
  JournalEntry entry = JournalEntry(
    description: "Sale to ${customer.firstName} ${customer.lastName}",
    entries: [
      // Debit: Accounts Receivable
      DebitLine(
        glAccountId: "AR",
        amount: amount,
        partyId: customer.partyId,        // Individual customer
        partyName: "${customer.firstName} ${customer.lastName}",
      ),
      // Credit: Sales Revenue
      CreditLine(
        glAccountId: "SALES",
        amount: amount,
        description: "B2C Direct Sale",
      ),
    ],
  );
  
  postJournalEntry(entry);
}
```

#### B2B Transaction Recording

```dart
void recordB2BTransaction(Company company, User employee, double amount) {
  // Create journal entry
  JournalEntry entry = JournalEntry(
    description: "Sale to ${company.name}",
    entries: [
      // Debit: Accounts Receivable
      DebitLine(
        glAccountId: "AR",
        amount: amount,
        partyId: company.partyId,         // Company, NOT employee
        partyName: company.name,
        notes: "Contact: ${employee.firstName} ${employee.lastName}",
      ),
      // Credit: Sales Revenue
      CreditLine(
        glAccountId: "SALES",
        amount: amount,
        description: "B2B Sale to ${company.name}",
      ),
    ],
  );
  
  postJournalEntry(entry);
}
```

---

## Use Cases

### Use Case 1: E-commerce B2C Platform

**Scenario**: Online retail selling to individual consumers

```
Customer: Direct B2C
- Alice purchases electronics
- Order recorded to Alice (person)
- Payment from Alice
- Accounting: Sale to Alice
- Loyalty: Alice's account accumulates points
- Analytics: Track Alice's purchase history

UI Display: UserDialog with Alice's personal info
```

### Use Case 2: B2B Corporate Sales

**Scenario**: SaaS company selling to enterprise customers

```
Customer: B2B via company + employees
- Company: Acme Inc (customer)
  - John (Sales contact, initiates POs)
  - Sarah (Procurement, approves POs)
  - Mike (Operations, receives products)

Order Flow:
1. John browses catalog
2. John places order for Acme Inc
3. System creates order for ACME INC (company), not John
4. Order routed to Sarah (procurement approver)
5. Order fulfilled to Acme Inc
6. Invoice issued to Acme Inc
7. Payment received by Acme Inc
8. Accounting: All activity on Acme Inc account

UI Display: CompanyDialog showing Acme Inc with employees
```

### Use Case 3: Supplier Network with Multiple Contacts

**Scenario**: Manufacturing purchasing with complex supplier relationships

```
Supplier: ABC Manufacturing
- Contact 1: Tom (Sales rep)
- Contact 2: Lisa (Technical support)
- Contact 3: Bob (Accounts payable)

Purchase Flow:
1. Tom quotes pricing to our company
2. Lisa provides technical specs
3. Bob handles invoicing and payments
4. All interactions recorded to ABC Manufacturing (company)
5. Individual contact info retained for communication
6. Analytics: ABC Manufacturing's sales/payment terms
```

### Use Case 4: Hybrid B2C/B2B Marketplace

**Scenario**: Platform supporting both individual sellers and company sellers

```
Seller Type A: Individual (B2C)
- Shop Owner: Jane (individual, independent)
- Records as: Jane's Personal Shop
- Accounting: All transactions to Jane (person)

Seller Type B: Company (B2B)
- Shop Owner: CompanyXYZ
- Employees: Alice (seller), Bob (customer service)
- Records as: CompanyXYZ Shop
- Accounting: All transactions to CompanyXYZ (company)
```

---

## Technical Considerations

### Database Implications

#### Query Complexity

**B2C Simple Query:**
```sql
SELECT * FROM customers 
WHERE customer_id = 1001;
-- Single table lookup
```

**B2B Complex Query:**
```sql
SELECT c.*, e.employee_id, e.first_name, e.last_name
FROM companies c
LEFT JOIN employees e ON c.company_id = e.company_id
WHERE c.company_id = 2001;
-- Multi-table join required
```

#### Performance Optimization

1. **Indexing Strategy**:
   - Index `User.companyId` for efficient lookup of employees
   - Index `Company.partyId` for fast company lookups
   - Composite index on `(company_id, role)` for role-based employee lookup

2. **Query Caching**:
   - Cache full company records with employees
   - Invalidate cache on company/employee changes

3. **N+1 Query Prevention**:
   - Load companies with employees in single query
   - Use database joins, not sequential queries

### API Design

#### Backend Endpoints

```
GET /api/customers?role=customer
  - Returns both B2C users and B2B companies with employees

GET /api/customers/{id}
  - Returns appropriate entity based on type
  - For company: includes employee list

POST /api/orders
  Request:
  {
    "customerId": "...",        // Always company/person ID
    "contactPersonId": "...",   // Only for B2B (optional)
    "amount": 1000,
    ...
  }
```

#### Frontend Components

```dart
// Polymorphic dialog system
Widget showCustomerDialog(CompanyUser customer) {
  if (customer.company != null) {
    return CompanyDialog(customer.company!);
  } else {
    return UserDialog(customer.getUser()!);
  }
}
```

### Migration from B2C-only to B2B Support

When adding B2B support to existing B2C system:

1. **Phase 1**: Add company fields to user table (nullable)
2. **Phase 2**: Create company table and relationships
3. **Phase 3**: Update order creation logic to handle both paths
4. **Phase 4**: Update accounting to use company when present
5. **Phase 5**: Migrate UI to show appropriate dialogs
6. **Phase 6**: Update reports/analytics for B2B metrics

---

## Summary Table

| Aspect | B2C (Standalone Person) | B2B (Company with Employee) |
|--------|------------------------|---------------------------|
| **Primary Party** | Individual person | Organization/Company |
| **Transactional Entity** | User object | Company object |
| **User Record** | Null company field | Populated company field |
| **Accounting Posted To** | Individual person ID | Company ID |
| **UI Display** | UserDialog | CompanyDialog |
| **Order Records** | Direct to person | To company, via person |
| **Contact Method** | Person's email/phone | Company's email/phone (primary)<br/>Person's for direct communication |
| **Credit Terms** | Individual basis | Company basis |
| **Payment Received From** | Individual | Company |
| **Analytics** | Individual metrics | Company metrics |
| **Employees** | N/A | Can have multiple |
| **Typical Businesses** | Retail, Services | B2B Wholesale, Enterprise SaaS |

---

## Conclusion

GrowERP's party model elegantly handles both B2C and B2B relationships through a flexible design where:

1. **B2C** is a person without company affiliation → shown as UserDialog
2. **B2B** is a person with company affiliation → shown as CompanyDialog (company-centric)
3. **All accounting** respects the hierarchy: company records take precedence over employee records
4. **Communication** can involve individuals, but **financial records** always flow to the correct entity (person or company)

This design allows businesses to grow from B2C to B2B seamlessly, handling complex organizational hierarchies while maintaining clean, auditable accounting records.
