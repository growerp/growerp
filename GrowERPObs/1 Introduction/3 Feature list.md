## Core Features

- **Open Source:** GrowERP is a fully open-source ERP system, allowing for complete customization and community-driven development.

- **Multi-Platform:** Built with Flutter, the application offers a consistent user experience across:
	- Web: Accessible from any modern web browser.
	- Android: Available on the Google Play Store.
	- iOS: Available on the Apple App Store.

- **Multi-Tenancy:**
	- SAAS: Supports multi-company, multi-currency, and multi-language setups for Software as a Service (SAAS) installations.
	- Single Company: Can be deployed for a single company with existing Moqui or Apache OFBiz installations.

- **Two Main Applications:**
	- Admin Application: A comprehensive ERP system for managing all aspects of a business.
	- Hotel Application: A specialized application tailored for the hospitality industry.

- **Demo Data:** The system can be initialized with demo data, providing a pre-populated environment to explore and test the system's features.

- **Local Installation:**
	- Easy Install: A streamlined command-line installer (`growerp install`) simplifies the setup process.
	- Manual Install: Detailed, step-by-step instructions are available for a manual installation.
	- Docker Support: The entire GrowERP system can be run locally using Docker containers for a consistent and isolated development environment.

- **Backend:**
	- Moqui Framework: Powered by the robust and scalable [Moqui Framework](https://www.moqui.org/), providing a solid foundation for the ERP's business logic.

- **Frontend:**
	- Flutter: The user interface is built with [Flutter](https://flutter.dev/), ensuring a modern, responsive, and cross-platform experience.

- **Generated Business Website:** GrowERP automatically generates a professional, customer-facing website based on the data within the ERP system.  

## Core Modules (Admin Application)

- **Dashboard:** A centralized and customizable dashboard provides a real-time overview of key business metrics and operations.
	- **User and Company Management:**
	- Contact Persons: Manage contact information and their relationships with companies.
	- Employees: Manage employee data, including access rights (admin or non-admin).
	- Suppliers: Maintain a database of suppliers and their associated information.
	- Customers: Manage customer data and relationships.

- **Catalog Management:**
	- Product Types: Supports various product types, including:
		- Services: For intangible products.
		- Physical: For tangible goods.
		- Rental: For products that are rented out.
	- Product Categories: Organize products into a hierarchical structure for easy management and browsing.
	- Standard and Website Categories: Maintain separate category structures for internal use and the public-facing website.

- **Order Management:**
	- Purchase and Sales Orders: Create and manage both purchase orders for suppliers and sales orders for customers.
	- Flexible Order Items: Order items can be products from the catalog, rental items, or ad-hoc items without a specific product ID.
	- Automated Document Creation: Automatically generate invoices, payments, and shipments from sales and purchase orders.

- **Inventory Management:**
	- Location Management: Manage multiple warehouse and inventory locations.
	- Shipments: Track incoming and outgoing shipments.
	- Asset Management: Manage and track company assets.

- **Accounting:**
	- Sales and Purchase Management: Full cycle of sales and purchase accounting.
	- Invoicing and Payments: Create and manage customer invoices and supplier payments.
	- Automatic Posting: Configure automatic posting of financial transactions to the ledger.
	- Double-Entry Ledger: A complete double-entry accounting system.
	- Flexible Ledger Organization: The ledger can be organized to fit any business structure.

- **Marketing:**
	- Opportunity Management: Track and manage sales opportunities and leads.
	- Task management
	- Lead/customer management

- **Website Management:**
	- Content Management: Manage the content of the automatically generated business website. 

## Hotel Application Modules

- **Dashboard:** A specialized dashboard designed for the unique needs of hotel operations, providing a quick overview of key metrics.
- **Room Management:**
	- Room and Bed Management: Manage hotel rooms and their availability, including different room types and bed configurations.
- **Reservation Management:**
	- Reservation Creation: Create, view, and manage room reservations.
	- Visual Calendar: A visual reservation calendar with day and week views for easy management of bookings.

- **Accounting:**
	- Integrated Accounting: Full accounting features tailored for the hotel industry, seamlessly integrated with reservation and billing processes.