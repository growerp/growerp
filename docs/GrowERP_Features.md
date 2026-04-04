# Features

- **Open Source:** GrowERP is a fully open-source ERP system, allowing for complete customization and community-driven development.

- **Multi-Platform:** Built with Flutter, the application offers a consistent user experience across:
	- Web: Accessible from any modern web browser.
	- Android: Available on the Google Play Store.
	- iOS: Available on the Apple App Store.
	- Linux: Snap Store.
	- macOS: Available on the Mac App Store.
	- Windows: Microsoft Store.

- **Multi-Tenancy:**
	- SAAS: Supports multi-company, multi-currency, and multi-language setups for Software as a Service (SaaS) installations.
	- Single Company: Can be deployed for a single company with existing Moqui or Apache OFBiz installations.

- **Applications:** GrowERP ships several ready-to-use applications built from reusable domain packages:
	- **Admin Application:** A comprehensive ERP system for managing all aspects of a business.
	- **Hotel Application:** A specialized application tailored for the hospitality industry.
	- **Freelance Application:** A project-based work management application for freelancers and service professionals.
	- **eLearner Application:** A student-facing platform for course enrollment and learning.
	- **Health Application:** A healthcare management application.
	- **Support Application:** A support and ticketing system.
	- **Assessment Application:** A lead-capture and AI-scored assessment platform.

- **AI-Powered Features:** Integrated AI capabilities powered by Google Gemini, including invoice scanning, assessment scoring, landing page generation, and AI-assisted content creation.

- **Real-Time Chat:** Built-in WebSocket-based chat and notifications for team collaboration.

- **Data Exchange:** CSV import and export for bulk data operations across all major entities.

- **PDF Reports:** Generate professional PDF reports and documents directly from the application.

- **Payment Integration:** Stripe integration for processing customer payments.

- **Dark Mode:** Full dark mode support across all applications.

- **Demo Data:** The system can be initialized with demo data, providing a pre-populated environment to explore and test the system's features.

- **Local Installation:**
	- Easy Install: A streamlined command-line installer (`growerp install`) simplifies the setup process.
	- Manual Install: Detailed, step-by-step instructions are available for manual installation.
	- Docker Support: The entire GrowERP system can be run locally using Docker containers for a consistent and isolated development environment.

- **Backend:**
	- Moqui Framework: Powered by the robust and scalable [Moqui Framework](https://www.moqui.org/), providing a solid foundation for the ERP's business logic.

- **Frontend:**
	- Flutter: The user interface is built with [Flutter](https://flutter.dev/), ensuring a modern, responsive, and cross-platform experience.

- **Generated Business Website:** GrowERP automatically generates a professional, customer-facing website based on the data within the ERP system.

---

## Core Modules (Admin Application)

- **Dashboard:** A centralized and customizable dashboard provides a real-time overview of key business metrics and operations.

- **User and Company Management:**
	- **Contact Persons:** Manage contact information and their relationships with companies.
	- **Employees:** Manage employee data, including access rights (admin or non-admin).
	- **Suppliers:** Maintain a database of suppliers and their associated information.
	- **Customers:** Manage customer data and relationships.

- **Catalog Management:**
	- **Product Types:** Supports various product types, including:
		- Services: For intangible products.
		- Physical: For tangible goods.
		- Rental: For products that are rented out.
	- **Product Categories:** Organize products into a hierarchical structure for easy management and browsing.
	- **Standard and Website Categories:** Maintain separate category structures for internal use and the public-facing website.

- **Order Management:**
	- **Purchase and Sales Orders:** Create and manage both purchase orders for suppliers and sales orders for customers.
	- **Flexible Order Items:** Order items can be products from the catalog, rental items, or ad-hoc items without a specific product ID.
	- **Automated Document Creation:** Automatically generate invoices, payments, and shipments from sales and purchase orders.

- **Inventory Management:**
	- **Location Management:** Manage multiple warehouse and inventory locations.
	- **Shipments:** Track incoming and outgoing shipments.
	- **Asset Management:** Manage and track company assets.

- **Manufacturing:**
	- **Bill of Materials (BOM):** Define and manage product structures and component requirements.
	- **Work Orders:** Create, schedule, and track production work orders.
	- **Production Routing:** Define manufacturing steps and routing sequences.
	- **Production Scheduling:** Plan and manage production schedules across work centers.

- **Accounting:**
	- **Sales and Purchase Management:** Full cycle of sales and purchase accounting.
	- **Invoicing and Payments:** Create and manage customer invoices and supplier payments.
	- **Automatic Posting:** Configure automatic posting of financial transactions to the ledger.
	- **Double-Entry Ledger:** A complete double-entry accounting system.
	- **Flexible Ledger Organization:** The ledger can be organized to fit any business structure.
	- **Financial Reports:** Period-based financial reporting and analytics.

- **Activity and Task Management:**
	- **Task Management:** Create, assign, and track tasks across the organization.
	- **Event Scheduling:** Schedule and manage business events and appointments.
	- **Reminders:** Set reminders and follow-up actions for tasks and activities.

- **Marketing and CRM:**
	- **Opportunity Management:** Track and manage sales opportunities and leads.
	- **Lead Management:** Capture, score, and nurture leads through the sales pipeline.
	- **Outreach Campaigns:** Multi-channel campaign management with scheduling and A/B testing.

- **Sales:**
	- **Sales Pipeline:** Visualize and manage the full sales pipeline.
	- **Quotes:** Create and manage customer quotations.
	- **Analytics:** Sales performance dashboards and analytics.

- **Website Management:**
	- **Content Management:** Manage the content of the automatically generated business website, including pages and content blocks.

---

## Hotel Application Modules

- **Dashboard:** A specialized dashboard designed for the unique needs of hotel operations, providing a quick overview of key metrics.

- **Room Management:**
	- **Room and Bed Management:** Manage hotel rooms and their availability, including different room types and bed configurations.

- **Reservation Management:**
	- **Reservation Creation:** Create, view, and manage room reservations.
	- **Visual Calendar:** A visual reservation calendar with day and week views for easy management of bookings.

- **Accounting:**
	- **Integrated Accounting:** Full accounting features tailored for the hotel industry, seamlessly integrated with reservation and billing processes.

---

## Freelance Application Modules

- **Dashboard:** An overview of active projects, tasks, and billable hours.

- **Project Management:** Create and manage client projects, milestones, and deliverables.

- **Task Management:** Assign and track tasks within projects.

- **Time Tracking:** Log billable and non-billable hours against projects and tasks.

- **Invoicing:** Generate and manage invoices based on logged time and project costs.

- **Accounting:** Full accounting cycle including payments and ledger management.

---

## eLearner Application Modules

- **Dashboard:** A student-facing overview of enrolled courses and progress.

- **Course Catalog:** Browse and enroll in available courses.

- **Curriculum Management:** Structured course content with lessons and media delivery.

- **Enrollment Management:** Manage student enrollments and access.

- **AI Content Generation:** AI-assisted course content creation for instructors.
