# Business flow
![[businessflow.jpg]]

Please find below the general business flow of the purchase and sales process. The processes assume that incoming and outgoing products, employees, suppliers and customer have been defined. Accounting has been setup by the system when the company was created.

Every document has similar status in the order of:
	1. in preparation (only used for web orders)
	2. Created
	3. Approved
	4. Completed/posted
	5. Cancelled

## Purchasing Order

	1. enter & approve/send purchase order --> creates:
		1. 'approved/posted' invoice 
		2. 'created' payment
		3. 'created' incoming shipment(when physical product)
	2. approve/send payment --> creates:
		1. 'completed/posted' payment
		2. non physical product: order 'completed'.
	3. approve/receive shipment when physical product --> creates:
		1. 'completed/posted' shipment
		2. purchase order 'completed' (when payment approved/send)
## Sales order

	1. enter & approve/receive sales order --> creates:
		1. 'approved/send/posted' invoice
		2. 'created' payment
		3. 'created' outgoing shipment(when physical product)
	2. approve/pack shipment when physical product shipped --> creates:
		1. posted shipment
	4. complete/send shipment
	5. approve/receive payment -> order completed

## Sales Invoice

## Purchase Invoice

## Sales(Incoming) Payment

	1. enter & approve sales Payment
	2. complete payment -> posted transaction
## Purchase(outgoing) Payment

	1. enter & approve Purchase Payment
	2. complete payment -> posted transaction

## End user actions

Below an explanation of the user actions which are possible. All other actions referenced will be performed by the system.

#### Create Order

If anything has been bought or sold, it will start with an order. This avoids inputting duplicate data on either the lower level documents like invoices, payment, shipment documents and ledger transactions.

Creating an order is doing just that, it has no further implications in the system and the order can be cancelled when input in error.

#### Approve order

Approving an order is a major action within the system, it will create an invoice and payment using the data from the order. If there are any physical order items which need to be sent or received, also a shipment note will be created. (see the 'use warehouse' field on the product.)

#### Approve shipment

The creation of a shipment happened by approving the order. If this shipment is approved, it confirms that either the purchase order has received or the sales order has gone out. If successful, the system will set the order to be completed and that order will will not appear on the outstanding order list anymore. Further the ledger will be credited or debited by the system depending if it was an incoming of outgoing shipment.

#### Approve invoice

The invoice was created by the system when the order was approved. If it was a purchase invoice it should be compared and adjusted by the user with the invoice from the supplier. When it is the same the invoice can be approved and the system will post the invoice to the ledger.

#### Approve payment

Also the payment was created by the system when the order was approved. The payment can be confirmed as received or sent by the user depending if a receipt or a purchase; the system will post this event to the ledger which will also complete the purchase or sales business process.

#### Ledger reports.

the content of the ledger can be browsed and printed to processed by an accountant.
