# PopRestStore Component Documentation

## Overview

PopRestStore is a REST API for eCommerce and an in-browser eCommerce application built with Vue.js. It provides a complete online store solution with both server-rendered and client-rendered components. The component has been modified from its original version to work with the GrowERP administrator frontend, which can be used to manage the website.

## Architecture

PopRestStore follows a modern web application architecture with:

1. **Backend**: Moqui Framework services that provide REST APIs
2. **Frontend**: Vue.js-based single-page application for user-specific pages
3. **Server-rendered pages**: For catalog browsing and content pages to ensure search engine compatibility

## Key Features

### Store Configuration

- **Multi-store support**: Can be configured for multiple stores with different settings
- **Multi-organizational companies**: Supports multiple organizations
- **Multi-currency support**: Handles different currencies for international sales
- **Customizable templates**: All server and client rendered templates can be overridden
- **Customizable styling**: Website colors can be changed from the GrowERP admin app

### Customer Management

- **User registration and authentication**: Supports account creation, login, and password management
- **Customer profiles**: Stores customer information and preferences
- **Address management**: Allows customers to manage multiple shipping addresses
- **Payment method management**: Supports saving and managing credit card information

### Product Catalog

- **Category browsing**: Hierarchical product categories
- **Product search**: Full-text search capabilities
- **Product details**: Comprehensive product information including images, descriptions, and pricing
- **Product variants**: Support for products with multiple variants (sizes, colors, etc.)
- **Product reviews**: Customer reviews and ratings

### Shopping Cart and Checkout

- **Cart management**: Add, update, remove items
- **Shipping options**: Multiple shipping methods
- **Payment processing**: Credit card processing
- **Order confirmation**: Complete order flow with confirmation
- **Promotional codes**: Support for discount codes

### Order Management

- **Order history**: Customers can view their order history
- **Order details**: Detailed information about each order
- **Order status tracking**: Real-time status updates

## Technical Components

### REST API Services

The component provides a comprehensive REST API for eCommerce operations, organized into the following categories:

1. **Store Services**: Store information, geo data, locales, and time zones
2. **Product Services**: Product information, categories, variants, reviews, and search
3. **Cart Services**: Cart management, shipping options, and order placement
4. **Customer Services**: User authentication, profile management, and order history

### Frontend Components

The frontend is built with Vue.js and organized into several key components:

1. **Navigation**: Header, footer, and menu components
2. **Product Display**: Product listings, details, and images
3. **Shopping Cart**: Cart management and checkout process
4. **Account Management**: User profile, addresses, and payment methods
5. **Order History**: Order listings and details

### Data Flow

1. The application starts by loading store configuration from the server
2. User interactions trigger API calls to the backend services
3. The frontend components update based on the API responses
4. Server-rendered pages are used for catalog browsing and content
5. Client-rendered pages are used for user-specific functionality

## Integration with GrowERP

The PopRestStore component is designed to work with the GrowERP administrator frontend, which provides:

1. **Product management**: Add, update, and remove products
2. **Category management**: Organize products into categories
3. **Order processing**: Process and fulfill orders
4. **Customer management**: View and manage customer information
5. **Website customization**: Change website colors and content

## Customization Options

The component can be customized in several ways:

1. **Templates**: Override server and client rendered templates
2. **Styling**: Customize CSS styles
3. **Configuration**: Adjust store settings
4. **Content**: Manage store content through the GrowERP admin app

## Technical Requirements

- **Moqui Framework**: The component is built on the Moqui Framework
- **Dependencies**: Requires moqui-fop, mantle-udm, mantle-usl, and growerp components
- **Browser Support**: Modern web browsers with JavaScript enabled

## Conclusion

PopRestStore provides a complete eCommerce solution with a REST API and in-browser application. It's designed to be customizable and extensible, making it suitable for a wide range of eCommerce needs. The integration with GrowERP provides powerful administration capabilities, making it a comprehensive solution for online stores.