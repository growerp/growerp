The payment type make the connection  between a descriptive payment type  and a account code. 

isPay is a flag to indicate a payment, so outgoing amount equals 'Y' or incoming equals 'N' .

isAppl is a flag to indicate if the payment needs to be applied to and invoice, Y or N or E for either, so both.

| ***Payment Type*** | ***description*** | ***glAccount name*** | ***isPay*** | ***isAppl*** |
| ---- | ---- | ---- | ---- | ---- |
| PtDisbursement | Disbursement | Retained Earnings | Y | E |
| PtFinancialAccount | Financial Account Transaction | Financial Account  Deposits | N | E |
| PtFinancialAccount | Financial Account Transaction | Financial Account Withdrawals | Y | E |
| PtInvoicePayment | Invoice Payment | Accounts Receivable - Unapplied Payments | N | N |
| PtInvoicePayment | Invoice Payment | Accounts Receivable | N | Y |
| PtInvoicePayment | Invoice Payment | Accounts Payable - Unapplied Payments | Y | N |
| PtInvoicePayment | Invoice Payment | Accounts Payable - Operating | Y | Y |
| PtPrePayment | Pre Payment - Expense | Accts Receivable - Unapplied Payments | N | N |
| PtPrePayment | Pre Payment - Expense | Accounts Receivable | N | Y |
| PtPrePayment | Pre Payment - Expense | Prepaid Expenses | Y | N |
| PtPrePayment | Pre Payment - Expense | Accounts Payable - Operating | Y | Y |
| PtPrePaymentInventory | Pre Payment - Inventory | Accounts Received - Unapplied Payments | N | N |
| PtPrePaymentInventory | Pre Payment - Inventory | Accounts Receivable | N | Y |
| PtPrePaymentInventory | Pre Payment - Inventory | Prepaid Inventory | Y | N |
| PtPrePaymentInventory | Pre Payment - Inventory | Accounts Payable - Operating | Y | Y |
| PtRefund | Refund | Accounts Receivable - Unapplied Payments | N | N |
| PtRefund | Refund | Accounts Payable - Unapplied Payments | Y | N |

