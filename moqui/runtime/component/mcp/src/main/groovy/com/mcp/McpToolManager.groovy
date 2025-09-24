package com.mcp

import groovy.json.JsonBuilder
import groovy.transform.CompileStatic
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.moqui.entity.EntityList
import org.moqui.entity.EntityFind
import org.moqui.service.ServiceCallSync
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * MCP Tool Manager - handles MCP tool operations
 * Provides callable tools for interacting with GrowERP/Moqui backend
 */
// @CompileStatic // Temporarily disabled for testing
class McpToolManager {
    private static final Logger logger = LoggerFactory.getLogger(McpToolManager.class)
    
    private final ExecutionContext ec
    
    McpToolManager(ExecutionContext ec) {
        this.ec = ec
    }
    
    Map<String, Object> listTools(Map<String, Object> params) {
        List<Map<String, Object>> tools = []
        
        // Entity CRUD tools
        tools.addAll(getEntityCrudTools())
        
        // Business operation tools
        tools.addAll(getBusinessTools())
        
        // Query and reporting tools
        tools.addAll(getQueryTools())
        
        // System tools
        tools.addAll(getSystemTools())
        
        return [tools: tools]
    }
    
    Map<String, Object> callTool(Map<String, Object> params) {
        String name = params.name as String
        Map<String, Object> arguments = params.arguments as Map ?: [:]
        
        if (!name) {
            throw new IllegalArgumentException("Tool name is required")
        }
        
        try {
            Map<String, Object> result = executeTool(name, arguments)
            
            return [
                content: [[
                    type: "text",
                    text: result.text ?: result.toString()
                ]],
                isError: false
            ]
            
        } catch (IllegalStateException e) {
            // Check if this is an authentication error
            if (e.message?.contains("Authentication required")) {
                logger.warn("Authentication error in tool ${name}: ${e.message}")
                return [
                    content: [[
                        type: "text", 
                        text: "Authentication required: ${e.message}"
                    ]],
                    isError: true,
                    isAuthError: true
                ]
            } else {
                logger.error("State error executing tool ${name}", e)
                return [
                    content: [[
                        type: "text", 
                        text: "Error executing tool ${name}: ${e.message}"
                    ]],
                    isError: true
                ]
            }
        } catch (Exception e) {
            logger.error("Error executing tool ${name}", e)
            
            return [
                content: [[
                    type: "text", 
                    text: "Error executing tool ${name}: ${e.message}"
                ]],
                isError: true
            ]
        }
    }
    
    private List<Map<String, Object>> getEntityCrudTools() {
        return [
            [
                name: "create_company",
                description: "Create a new company in the system. You can either provide a 'company' object with nested properties, or use flat parameters like 'name', 'email', etc.",
                inputSchema: [
                    type: "object",
                    properties: [
                        // Nested company object (preferred)
                        company: [
                            type: "object",
                            description: "Company information object",
                            properties: [
                                name: [type: "string", description: "Company name"],
                                role: [type: "string", description: "Company role (Customer, Supplier, Internal)"],
                                email: [type: "string", description: "Company email address"],
                                url: [type: "string", description: "Company website URL"],
                                currency: [
                                    type: "object",
                                    properties: [
                                        currencyId: [type: "string", description: "Currency ID (USD, EUR, etc.)"]
                                    ]
                                ],
                                address: [
                                    type: "object",
                                    properties: [
                                        address1: [type: "string", description: "Primary address line"],
                                        city: [type: "string", description: "City"],
                                        country: [type: "string", description: "Country"]
                                    ]
                                ],
                                telephoneNr: [type: "string", description: "Telephone number"]
                            ],
                            required: ["name"]
                        ],
                        // Flat parameters (alternative)
                        name: [type: "string", description: "Company name (alternative to company.name)"],
                        companyName: [type: "string", description: "Company name (alias for name)"],
                        role: [type: "string", description: "Company role (Customer, Supplier, Internal)"],
                        email: [type: "string", description: "Company email address"],
                        emailAddress: [type: "string", description: "Company email address (alias for email)"],
                        url: [type: "string", description: "Company website URL"],
                        currencyUomId: [type: "string", description: "Currency ID (USD, EUR, etc.)"],
                        telephoneNr: [type: "string", description: "Telephone number"]
                    ],
                    // Either company object OR name is required
                    anyOf: [
                        [required: ["company"]],
                        [required: ["name"]],
                        [required: ["companyName"]]
                    ]
                ]
            ],
            [
                name: "create_user",
                description: "Create a new user account",
                inputSchema: [
                    type: "object",
                    properties: [
                        username: [type: "string", description: "Login username"],
                        firstName: [type: "string", description: "First name"],
                        lastName: [type: "string", description: "Last name"],
                        emailAddress: [type: "string", description: "Email address"],
                        companyPartyId: [type: "string", description: "Company to associate with"]
                    ],
                    required: ["username", "firstName", "emailAddress"]
                ]
            ],
            [
                name: "create_product",
                description: "Create a new product in the catalog. You can either provide a 'product' object with nested properties, or use flat parameters like 'productName', 'price', etc.",
                inputSchema: [
                    type: "object",
                    properties: [
                        // Nested product object (preferred)
                        product: [
                            type: "object",
                            description: "Product information object",
                            properties: [
                                pseudoId: [type: "string", description: "Product pseudo ID"],
                                productTypeId: [type: "string", description: "Product type ID"],
                                assetClassId: [type: "string", description: "Asset class ID"],
                                productName: [type: "string", description: "Product name"],
                                description: [type: "string", description: "Product description"],
                                price: [type: "number", description: "Product price"],
                                listPrice: [type: "number", description: "List price"],
                                categories: [
                                    type: "array",
                                    description: "Product categories",
                                    items: [
                                        type: "object",
                                        properties: [
                                            categoryId: [type: "string", description: "Category ID"],
                                            categoryName: [type: "string", description: "Category name"],
                                            description: [type: "string", description: "Category description"],
                                            image: [type: "string", description: "Category image"]
                                        ]
                                    ]
                                ],
                                useWarehouse: [type: "boolean", description: "Whether product uses warehouse management"],
                                image: [type: "string", description: "Product image"],
                                amountUom: [
                                    type: "object",
                                    description: "Unit of measure for amounts",
                                    properties: [
                                        uomId: [type: "string", description: "UOM ID"]
                                    ]
                                ],
                                amount: [type: "number", description: "Amount/quantity"]
                            ],
                            required: ["productName"]
                        ],
                        // Flat parameters (alternative)
                        productName: [type: "string", description: "Product name (alternative to product.productName)"],
                        description: [type: "string", description: "Product description"],
                        price: [type: "number", description: "Product price"],
                        listPrice: [type: "number", description: "List price"],
                        productTypeId: [type: "string", description: "Product type ID"],
                        assetClassId: [type: "string", description: "Asset class ID"],
                        categoryId: [type: "string", description: "Primary category ID"],
                        useWarehouse: [type: "boolean", description: "Whether product uses warehouse management"],
                        image: [type: "string", description: "Product image"]
                    ],
                    // Either product object OR productName is required
                    anyOf: [
                        [required: ["product"]],
                        [required: ["productName"]]
                    ]
                ]
            ],
            [
                name: "create_category",
                description: "Create a new product category to group products. You can either provide a 'category' object with nested properties, or use flat parameters like 'categoryName', 'description', etc.",
                inputSchema: [
                    type: "object",
                    properties: [
                        // Nested category object (preferred)
                        category: [
                            type: "object",
                            description: "Category information object",
                            properties: [
                                pseudoId: [type: "string", description: "Category pseudo ID"],
                                categoryName: [type: "string", description: "Category name"],
                                description: [type: "string", description: "Category description"],
                                image: [type: "string", description: "Category image (base64 encoded)"],
                                products: [
                                    type: "array",
                                    description: "Products to include in this category",
                                    items: [
                                        type: "object",
                                        properties: [
                                            productId: [type: "string", description: "Product ID"]
                                        ],
                                        required: ["productId"]
                                    ]
                                ]
                            ],
                            required: ["categoryName"]
                        ],
                        // Flat parameters (alternative)
                        categoryName: [type: "string", description: "Category name (alternative to category.categoryName)"],
                        description: [type: "string", description: "Category description"],
                        pseudoId: [type: "string", description: "Category pseudo ID"],
                        image: [type: "string", description: "Category image (base64 encoded)"],
                        productIds: [
                            type: "array", 
                            description: "Array of product IDs to include in this category",
                            items: [type: "string"]
                        ]
                    ],
                    // Either category object OR categoryName is required
                    anyOf: [
                        [required: ["category"]],
                        [required: ["categoryName"]]
                    ]
                ]
            ],
            [
                name: "update_company",
                description: "Update an existing company",
                inputSchema: [
                    type: "object",
                    properties: [
                        partyId: [type: "string", description: "Company party ID"],
                        companyName: [type: "string", description: "Company name"],
                        description: [type: "string", description: "Company description"],
                        emailAddress: [type: "string", description: "Company email address"]
                    ],
                    required: ["partyId"]
                ]
            ],
            [
                name: "update_user",
                description: "Update an existing user account",
                inputSchema: [
                    type: "object",
                    properties: [
                        userId: [type: "string", description: "User ID"],
                        firstName: [type: "string", description: "First name"],
                        lastName: [type: "string", description: "Last name"],
                        emailAddress: [type: "string", description: "Email address"],
                        disabled: [type: "string", description: "Disabled flag (Y/N)"]
                    ],
                    required: ["userId"]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getBusinessTools() {
        return [
            [
                name: "create_sales_order",
                description: "Create a sales order",
                inputSchema: [
                    type: "object",
                    properties: [
                        customerPartyId: [type: "string", description: "Customer party ID"],
                        items: [
                            type: "array",
                            description: "Order items",
                            items: [
                                type: "object",
                                properties: [
                                    productId: [type: "string", description: "Product ID"],
                                    quantity: [type: "number", description: "Quantity"],
                                    price: [type: "number", description: "Unit price"]
                                ],
                                required: ["productId", "quantity"]
                            ]
                        ]
                    ],
                    required: ["customerPartyId", "items"]
                ]
            ],
            [
                name: "create_purchase_order",
                description: "Create a purchase order",
                inputSchema: [
                    type: "object",
                    properties: [
                        supplierPartyId: [type: "string", description: "Supplier party ID"],
                        items: [
                            type: "array",
                            description: "Order items",
                            items: [
                                type: "object",
                                properties: [
                                    productId: [type: "string", description: "Product ID"],
                                    quantity: [type: "number", description: "Quantity"],
                                    price: [type: "number", description: "Unit price"]
                                ],
                                required: ["productId", "quantity"]
                            ]
                        ]
                    ],
                    required: ["supplierPartyId", "items"]
                ]
            ],
            [
                name: "create_invoice",
                description: "Create an invoice. You can either provide a 'finDoc' object with nested properties, or use flat parameters like 'sales', 'otherCompanyPartyId', etc.",
                inputSchema: [
                    type: "object",
                    properties: [
                        // Nested finDoc object (preferred)
                        finDoc: [
                            type: "object",
                            description: "Financial document information object",
                            properties: [
                                docType: [type: "string", description: "Document type (should be 'invoice')", default: "invoice"],
                                sales: [type: "boolean", description: "Whether this is a sales invoice (true) or purchase invoice (false)"],
                                pseudoId: [type: "string", description: "Invoice pseudo ID"],
                                reference: [type: "string", description: "Invoice reference/number"],
                                statusId: [type: "string", description: "Invoice status ID"],
                                paymentInstrument: [type: "string", description: "Payment instrument"],
                                description: [type: "string", description: "Invoice description"],
                                otherUser: [
                                    type: "object",
                                    description: "Other user information",
                                    properties: [
                                        partyId: [type: "string", description: "User party ID"]
                                    ]
                                ],
                                otherCompany: [
                                    type: "object",
                                    description: "Customer/Supplier company information",
                                    properties: [
                                        partyId: [type: "string", description: "Company party ID"],
                                        paymentMethod: [
                                            type: "object",
                                            description: "Payment method information",
                                            properties: [
                                                ccPaymentMethodId: [type: "string", description: "Credit card payment method ID"]
                                            ]
                                        ]
                                    ],
                                    required: ["partyId"]
                                ],
                                grandTotal: [type: "number", description: "Invoice grand total"],
                                classificationId: [type: "string", description: "Classification ID"],
                                isPosted: [type: "boolean", description: "Whether invoice is posted to accounting"],
                                journal: [
                                    type: "object",
                                    description: "Journal information",
                                    properties: [
                                        journalId: [type: "string", description: "Journal ID"]
                                    ]
                                ],
                                items: [
                                    type: "array",
                                    description: "Invoice line items",
                                    items: [
                                        type: "object",
                                        properties: [
                                            itemSeqId: [type: "string", description: "Item sequence ID"],
                                            itemType: [
                                                type: "object",
                                                properties: [
                                                    itemTypeId: [type: "string", description: "Item type ID"],
                                                    itemTypeName: [type: "string", description: "Item type name"]
                                                ]
                                            ],
                                            paymentType: [
                                                type: "object",
                                                properties: [
                                                    paymentTypeId: [type: "string", description: "Payment type ID"],
                                                    paymentTypeName: [type: "string", description: "Payment type name"]
                                                ]
                                            ],
                                            productId: [type: "string", description: "Product ID"],
                                            pseudoProductId: [type: "string", description: "Product pseudo ID"],
                                            description: [type: "string", description: "Item description"],
                                            quantity: [type: "number", description: "Item quantity"],
                                            price: [type: "number", description: "Item unit price"],
                                            isDebit: [type: "boolean", description: "Whether this is a debit item"],
                                            glAccount: [
                                                type: "object",
                                                properties: [
                                                    glAccountId: [type: "string", description: "GL account ID"]
                                                ]
                                            ],
                                            asset: [
                                                type: "object",
                                                properties: [
                                                    assetId: [type: "string", description: "Asset ID"],
                                                    assetName: [type: "string", description: "Asset name"],
                                                    location: [
                                                        type: "object",
                                                        properties: [
                                                            locationId: [type: "string", description: "Location ID"],
                                                            locationName: [type: "string", description: "Location name"]
                                                        ]
                                                    ]
                                                ]
                                            ],
                                            rentalFromDate: [type: "string", description: "Rental start date"],
                                            rentalThruDate: [type: "string", description: "Rental end date"]
                                        ],
                                        required: ["quantity", "price"]
                                    ]
                                ],
                                requestType: [type: "string", description: "Request type"]
                            ],
                            required: ["docType", "otherCompany", "items"]
                        ],
                        // Flat parameters (alternative)
                        sales: [type: "boolean", description: "Whether this is a sales invoice (true) or purchase invoice (false)"],
                        otherCompanyPartyId: [type: "string", description: "Customer/Supplier party ID"],
                        partyId: [type: "string", description: "Customer/Supplier party ID (alias for otherCompanyPartyId)"],
                        invoiceType: [type: "string", description: "Invoice type (sales/purchase) - converted to boolean"],
                        reference: [type: "string", description: "Invoice reference/number"],
                        description: [type: "string", description: "Invoice description"],
                        grandTotal: [type: "number", description: "Invoice grand total"],
                        items: [
                            type: "array",
                            description: "Invoice line items",
                            items: [
                                type: "object",
                                properties: [
                                    productId: [type: "string", description: "Product ID"],
                                    quantity: [type: "number", description: "Item quantity"],
                                    price: [type: "number", description: "Item unit price"],
                                    description: [type: "string", description: "Item description"]
                                ],
                                required: ["quantity", "price"]
                            ]
                        ]
                    ],
                    // Either finDoc object OR required flat parameters
                    anyOf: [
                        [required: ["finDoc"]],
                        [required: ["items", "otherCompanyPartyId"]],
                        [required: ["items", "partyId"]]
                    ]
                ]
            ],
            [
                name: "approve_document",
                description: "Approve a financial document (order/invoice)",
                inputSchema: [
                    type: "object",
                    properties: [
                        finDocId: [type: "string", description: "Financial document ID"],
                        docType: [type: "string", description: "Document type (order/invoice)"]
                    ],
                    required: ["finDocId", "docType"]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getQueryTools() {
        return [
            [
                name: "get_companies",
                description: "Retrieve companies with optional filtering",
                inputSchema: [
                    type: "object",
                    properties: [
                        companyPartyId: [type: "string", description: "Specific company party ID to retrieve"],
                        companyPseudoId: [type: "string", description: "Company pseudo ID"],
                        firstName: [type: "string", description: "First name filter"],
                        lastName: [type: "string", description: "Last name filter"],
                        companyName: [type: "string", description: "Company name filter"],
                        userPartyId: [type: "string", description: "User party ID filter"],
                        role: [type: "string", description: "Company role filter"],
                        start: [type: "integer", description: "Starting index for pagination", default: 0],
                        limit: [type: "integer", description: "Maximum number of results", default: 20],
                        searchString: [type: "string", description: "General search string"],
                        isForDropDown: [type: "boolean", description: "Format results for dropdown display"]
                    ]
                ]
            ],
            [
                name: "get_users",
                description: "Retrieve users with optional filtering", 
                inputSchema: [
                    type: "object",
                    properties: [
                        limit: [type: "number", description: "Maximum number of results", default: 20],
                        searchTerm: [type: "string", description: "Search term for username/name"],
                        companyPartyId: [type: "string", description: "Filter by company"]
                    ]
                ]
            ],
            [
                name: "get_products",
                description: "Retrieve products with optional filtering",
                inputSchema: [
                    type: "object",
                    properties: [
                        pseudoId: [type: "string", description: "Product pseudo ID"],
                        categoryId: [type: "string", description: "Product category ID filter"],
                        productId: [type: "string", description: "Specific product ID to retrieve"],
                        productTypeId: [type: "string", description: "Product type ID filter"],
                        assetClassId: [type: "string", description: "Asset class ID filter"],
                        start: [type: "integer", description: "Starting index for pagination", default: 0],
                        limit: [type: "integer", description: "Maximum number of results", default: 20],
                        isForDropDown: [type: "boolean", description: "Format results for dropdown display"],
                        search: [type: "string", description: "General search string for product name/description"]
                    ]
                ]
            ],
            [
                name: "get_categories",
                description: "Retrieve product categories with optional filtering",
                inputSchema: [
                    type: "object",
                    properties: [
                        companyPartyId: [type: "string", description: "Company party ID filter"],
                        categoryId: [type: "string", description: "Specific category ID to retrieve"],
                        start: [type: "integer", description: "Starting index for pagination", default: 0],
                        limit: [type: "integer", description: "Maximum number of results", default: 20],
                        isForDropDown: [type: "boolean", description: "Format results for dropdown display", default: false],
                        search: [type: "string", description: "General search string for category name/description"]
                    ]
                ]
            ],
            [
                name: "get_orders",
                description: "Retrieve orders with optional filtering",
                inputSchema: [
                    type: "object",
                    properties: [
                        limit: [type: "number", description: "Maximum number of results", default: 20],
                        docType: [type: "string", description: "Document type filter (sales/purchase)"],
                        statusId: [type: "string", description: "Status filter"],
                        partyId: [type: "string", description: "Customer/Supplier filter"]
                    ]
                ]
            ],
            [
                name: "get_balance_summary",
                description: "Get balance summary and reports",
                inputSchema: [
                    type: "object",
                    properties: [
                        period: [type: "string", description: "Time period (month/quarter/year)", default: "month"],
                        docType: [type: "string", description: "Document type filter"],
                        partyId: [type: "string", description: "Party filter"]
                    ]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getSystemTools() {
        return [
            [
                name: "ping_system",
                description: "Check system health and connectivity",
                inputSchema: [
                    type: "object",
                    properties: [:]
                ]
            ],
            [
                name: "get_entity_info",
                description: "Get information about a specific entity",
                inputSchema: [
                    type: "object",
                    properties: [
                        entityName: [type: "string", description: "Entity name"]
                    ],
                    required: ["entityName"]
                ]
            ],
            [
                name: "get_service_info",
                description: "Get information about a specific service",
                inputSchema: [
                    type: "object",
                    properties: [
                        serviceName: [type: "string", description: "Service name"]
                    ],
                    required: ["serviceName"]
                ]
            ]
        ]
    }
    
    private Map<String, Object> executeTool(String toolName, Map<String, Object> arguments) {
        switch (toolName) {
            // Entity CRUD operations
            case "create_company":
                return executeCreateCompany(arguments)
            case "create_user":
                return executeCreateUser(arguments)
            case "create_product":
                return executeCreateProduct(arguments)
            case "create_category":
                return executeCreateCategory(arguments)
            case "update_company":
                return executeUpdateCompany(arguments)
            case "update_user":
                return executeUpdateUser(arguments)
                
            // Business operations
            case "create_sales_order":
                return executeCreateSalesOrder(arguments)
            case "create_purchase_order":
                return executeCreatePurchaseOrder(arguments)
            case "create_invoice":
                return executeCreateInvoice(arguments)
            case "approve_document":
                return executeApproveDocument(arguments)
                
            // Query operations
            case "get_companies":
                return ec.service.sync().name("growerp.100.PartyServices100.get#Company")
                .parameters(arguments + [searchString: arguments.companyName ? arguments.companyName : arguments.partyId? arguments.partyId : arguments.role]).call()
            case "get_users":
                return ec.service.sync().name("growerp.100.PartyServices100.get#User")
                .parameters(arguments).call()
            case "get_products":
                return ec.service.sync().name("growerp.100.CatalogServices100.get#Product")
                .parameters(arguments).call()
            case "get_categories":
                return ec.service.sync().name("growerp.100.CatalogServices100.get#ProductCategory")
                .parameters(arguments).call()
            case "get_orders":
                return ec.service.sync().name("growerp.100.FinDocServices100.get#FinDoc")
                .parameters(arguments + [docType: 'order']).call()
            case "get_balance_summary":
                return ec.service.sync().name("growerp.100.AccountingServices100.get#BalanceSummary")
                .parameters(arguments).call()

            // System operations
            case "ping_system":
                return executePingSystem(arguments)
            case "get_entity_info":
                return executeGetEntityInfo(arguments)
            case "get_service_info":
                return executeGetServiceInfo(arguments)
                
            default:
                throw new IllegalArgumentException("Unknown tool: ${toolName}")
        }
    }
    
    // Entity CRUD implementations
    private Map<String, Object> executeCreateCompany(Map<String, Object> arguments) {
        logger.info("executeCreateCompany called with arguments: ${arguments}")
        
        Map<String, Object> company = null
        
        // Try to get company parameter first (nested structure)
        if (arguments.company instanceof Map) {
            company = arguments.company as Map<String, Object>
        }
        // If no nested company, treat arguments as flat company data
        else if (arguments.name || arguments.companyName) {
            company = arguments.clone() as Map<String, Object>
            // Handle common flat parameter mappings
            if (arguments.companyName && !company.name) {
                company.name = arguments.companyName
            }
            if (arguments.emailAddress && !company.email) {
                company.email = arguments.emailAddress
            }
            if (arguments.currencyUomId && !company.currency) {
                company.currency = [currencyId: arguments.currencyUomId]
            }
        }
        
        if (!company || !company.name) {
            throw new IllegalArgumentException("Company name is required. Received arguments: ${arguments}")
        }
        
        // Ensure required fields have defaults
        if (!company.role) {
            company.role = "Customer" // Default role
        }
        
        logger.info("Processed company parameter: ${company}")
        
        // The service expects the company parameter directly
        Map<String, Object> serviceParams = [company: company]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.PartyServices100.create#Company")
                .parameters(serviceParams).call()

            String companyName = company.name ?: "Unknown"
            String partyId = result.company?.pseudoId ?: result.company.partyId
            
            return [
                text: "Successfully created company '${companyName}' with partyId: ${partyId}",
                data: result
            ]
        } catch (Exception e) {
            logger.error("Service call failed with company: ${company}", e)
            throw new RuntimeException("Failed to create company: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreateUser(Map<String, Object> arguments) {
        String username = arguments.username as String
        String firstName = arguments.firstName as String
        String lastName = arguments.lastName as String
        String emailAddress = arguments.emailAddress as String
        String companyPartyId = arguments.companyPartyId as String
        
        Map<String, Object> serviceParams = [
            username: username,
            firstName: firstName,
            lastName: lastName,
            emailAddress: emailAddress
        ]
        
        if (companyPartyId) serviceParams.companyPartyId = companyPartyId
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.PartyServices100.create#User")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created user '${username}' with partyId: ${result.partyId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create user: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreateProduct(Map<String, Object> arguments) {
        logger.info("executeCreateProduct called with arguments: ${arguments}")
        
        Map<String, Object> product = null
        
        // Try to get product parameter first (nested structure)
        if (arguments.product instanceof Map) {
            product = arguments.product as Map<String, Object>
        }
        // If no nested product, treat arguments as flat product data
        else if (arguments.productName) {
            product = arguments.clone() as Map<String, Object>
            // Handle common flat parameter mappings
            if (arguments.productCategoryId && !product.categories) {
                product.categories = [[categoryId: arguments.productCategoryId]]
            }
        }
        
        if (!product || !product.productName) {
            throw new IllegalArgumentException("Product name is required. Received arguments: ${arguments}")
        }
        
        logger.info("Processed product parameter: ${product}")
        
        // The service expects the product parameter directly, plus classificationId
        Map<String, Object> serviceParams = [
            product: product,
            classificationId: "AppAdmin" // Default classification
        ]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.CatalogServices100.create#Product")
                .parameters(serviceParams).call()

            String productName = product.productName ?: "Unknown"
            String productId = result.product?.productId ?: result.productId
            
            return [
                text: "Successfully created product '${productName}' with productId: ${productId}",
                data: result
            ]
        } catch (Exception e) {
            logger.error("Service call failed with product: ${product}", e)
            throw new RuntimeException("Failed to create product: ${e.message}", e)
        }
    }    
    
    private Map<String, Object> executeCreateCategory(Map<String, Object> arguments) {
        logger.info("executeCreateCategory called with arguments: ${arguments}")
        
        Map<String, Object> category = null
        
        // Try to get category parameter first (nested structure)
        if (arguments.category instanceof Map) {
            category = arguments.category as Map<String, Object>
        }
        // If no nested category, treat arguments as flat category data
        else if (arguments.categoryName) {
            category = arguments.clone() as Map<String, Object>
            // Handle flat productIds array to nested products structure
            if (arguments.productIds && !category.products) {
                category.products = (arguments.productIds as List<String>).collect { productId ->
                    [productId: productId]
                }
            }
        }
        
        if (!category || !category.categoryName) {
            throw new IllegalArgumentException("Category name is required. Received arguments: ${arguments}")
        }
        
        logger.info("Processed category parameter: ${category}")
        
        // The service expects the category parameter directly
        Map<String, Object> serviceParams = [category: category]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.CatalogServices100.create#ProductCategory")
                .parameters(serviceParams).call()

            String categoryName = category.categoryName ?: "Unknown"
            String categoryId = result.category?.categoryId ?: result.categoryId
            
            return [
                text: "Successfully created category '${categoryName}' with categoryId: ${categoryId}",
                data: result
            ]
        } catch (Exception e) {
            logger.error("Service call failed with category: ${category}", e)
            throw new RuntimeException("Failed to create category: ${e.message}", e)
        }
    }
    
    // System operations
    private Map<String, Object> executePingSystem(Map<String, Object> arguments) {
        try {
            // Test database connectivity
            long entityCount = ec.entity.find("Party").count()
            
            return [
                text: "System Status: Healthy\n" +
                      "Timestamp: ${new Date()}\n" +
                      "Moqui Version: ${ec.factory.moquiVersion}\n" +
                      "Database: Connected\n" +
                      "Entity Count: ${entityCount}"
            ]
        } catch (Exception e) {
            return [
                text: "System Status: Unhealthy\n" +
                      "Error: ${e.message}"
            ]
        }
    }
    
    private Map<String, Object> executeGetEntityInfo(Map<String, Object> arguments) {
        String entityName = arguments.entityName as String
        
        def entityDefinition = ec.entity.getEntityDefinition(entityName)
        if (!entityDefinition) {
            return [text: "Entity not found: ${entityName}"]
        }
        
        StringBuilder result = new StringBuilder("Entity: ${entityName}\n")
        result.append("Package: ${entityDefinition.packageName}\n")
        result.append("Table: ${entityDefinition.tableName}\n")
        result.append("Fields:\n")
        
        entityDefinition.fieldInfoList.each { fieldInfo ->
            result.append("  - ${fieldInfo.name} (${fieldInfo.type})")
            if (fieldInfo.isPk) result.append(" [PK]")
            if (fieldInfo.isNotNull) result.append(" [NOT NULL]")
            result.append("\n")
        }
        
        return [text: result.toString()]
    }
    
    private Map<String, Object> executeGetServiceInfo(Map<String, Object> arguments) {
        String serviceName = arguments.serviceName as String
        
        def serviceDefinition = ec.service.getServiceDefinition(serviceName)
        if (!serviceDefinition) {
            return [text: "Service not found: ${serviceName}"]
        }
        
        StringBuilder result = new StringBuilder("Service: ${serviceName}\n")
        result.append("Type: ${serviceDefinition.serviceType}\n")
        result.append("Description: ${serviceDefinition.description ?: 'N/A'}\n")
        
        if (serviceDefinition.inParameterNames) {
            result.append("Input Parameters:\n")
            serviceDefinition.inParameterNames.each { paramName ->
                def paramDef = serviceDefinition.getInParameter(paramName)
                result.append("  - ${paramName} (${paramDef.type})")
                if (paramDef.required) result.append(" [REQUIRED]")
                result.append("\n")
            }
        }
        
        if (serviceDefinition.outParameterNames) {
            result.append("Output Parameters:\n")
            serviceDefinition.outParameterNames.each { paramName ->
                def paramDef = serviceDefinition.getOutParameter(paramName)
                result.append("  - ${paramName} (${paramDef.type})")
                result.append("\n")
            }
        }
        
        return [text: result.toString()]
    }
    
    // Additional business operation implementations would go here...
    private Map<String, Object> executeCreateSalesOrder(Map<String, Object> arguments) {
        // Implementation for creating sales orders
        String customerPartyId = arguments.customerPartyId as String
        List<Map> items = arguments.items as List<Map>
        
        Map<String, Object> serviceParams = [
            salesOrderType: "sales",
            otherCompanyPartyId: customerPartyId,
            items: items
        ]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.FinDocServices100.create#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created sales order with orderId: ${result.finDocId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create sales order: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreatePurchaseOrder(Map<String, Object> arguments) {
        // Implementation for creating purchase orders
        String supplierPartyId = arguments.supplierPartyId as String
        List<Map> items = arguments.items as List<Map>
        
        Map<String, Object> serviceParams = [
            salesOrderType: "purchase",
            otherCompanyPartyId: supplierPartyId,
            items: items
        ]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.FinDocServices100.create#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created purchase order with orderId: ${result.finDocId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create purchase order: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreateInvoice(Map<String, Object> arguments) {
        logger.info("executeCreateInvoice called with arguments: ${arguments}")
        
        Map<String, Object> finDoc = null
        
        // Try to get finDoc parameter first (nested structure)
        if (arguments.finDoc instanceof Map) {
            finDoc = arguments.finDoc as Map<String, Object>
        }
        // If no nested finDoc, treat arguments as flat invoice data
        else if (arguments.items || arguments.partyId || arguments.otherCompanyPartyId) {
            finDoc = [:]
            finDoc.docType = "invoice"
            finDoc.items = arguments.items as List<Map>
            
            // Handle party ID mapping
            String partyId = arguments.otherCompanyPartyId ?: arguments.partyId
            if (partyId) {
                finDoc.otherCompany = [partyId: partyId]
            }
            
            // Handle sales/purchase type
            if (arguments.invoiceType) {
                finDoc.sales = (arguments.invoiceType == "sales")
            } else if (arguments.sales != null) {
                finDoc.sales = arguments.sales
            }
            
            // Handle other flat parameters
            if (arguments.reference) finDoc.reference = arguments.reference
            if (arguments.description) finDoc.description = arguments.description
            if (arguments.grandTotal) finDoc.grandTotal = arguments.grandTotal
        }
        
        if (!finDoc || !finDoc.items || !finDoc.otherCompany?.partyId) {
            throw new IllegalArgumentException("Invoice requires items and customer/supplier party ID. Received arguments: ${arguments}")
        }
        
        // Ensure required fields have defaults
        if (!finDoc.docType) {
            finDoc.docType = "invoice"
        }
        if (finDoc.sales == null) {
            finDoc.sales = true // Default to sales invoice
        }
        
        logger.info("Processed finDoc parameter: ${finDoc}")
        
        // The service expects the finDoc parameter directly
        Map<String, Object> serviceParams = [finDoc: finDoc]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.FinDocServices100.create#FinDoc")
                .parameters(serviceParams).call()

            String invoiceType = finDoc.sales ? "sales" : "purchase"
            String invoiceId = result.finDoc?.invoiceId ?: result.finDoc?.pseudoId ?: "Unknown"
            
            return [
                text: "Successfully created ${invoiceType} invoice with invoiceId: ${invoiceId}",
                data: result
            ]
        } catch (Exception e) {
            logger.error("Service call failed with finDoc: ${finDoc}", e)
            throw new RuntimeException("Failed to create invoice: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeApproveDocument(Map<String, Object> arguments) {
        // Implementation for approving documents
        String finDocId = arguments.finDocId as String
        String docType = arguments.docType as String
        
        Map<String, Object> serviceParams = [
            finDocId: finDocId,
            statusId: "FdApproved"
        ]
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.FinDocServices100.update#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully approved ${docType} document ${finDocId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to approve document: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeUpdateCompany(Map<String, Object> arguments) {
        // Implementation for updating companies
        String partyId = arguments.partyId as String
        String companyName = arguments.companyName as String
        String description = arguments.description as String
        String emailAddress = arguments.emailAddress as String
        
        Map<String, Object> serviceParams = [partyId: partyId]
        
        if (companyName) serviceParams.companyName = companyName
        if (description) serviceParams.description = description
        if (emailAddress) serviceParams.emailAddress = emailAddress
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.PartyServices100.update#Company")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully updated company ${partyId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to update company: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeUpdateUser(Map<String, Object> arguments) {
        // Implementation for updating users
        String userId = arguments.userId as String
        String firstName = arguments.firstName as String
        String lastName = arguments.lastName as String
        String emailAddress = arguments.emailAddress as String
        String disabled = arguments.disabled as String
        
        Map<String, Object> serviceParams = [userId: userId]
        
        if (firstName) serviceParams.firstName = firstName
        if (lastName) serviceParams.lastName = lastName
        if (emailAddress) serviceParams.emailAddress = emailAddress
        if (disabled) serviceParams.disabled = disabled
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.100.PartyServices100.update#User")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully updated user ${userId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to update user: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeGetFinancialSummary(Map<String, Object> arguments) {
        // Implementation for financial summary
        String period = (arguments.period as String) ?: "month"
        String docType = arguments.docType as String
        String partyId = arguments.partyId as String
        
        // Calculate date range based on period
        Calendar cal = Calendar.getInstance()
        Date endDate = new Date()
        Date startDate
        
        switch (period) {
            case "month":
                cal.add(Calendar.MONTH, -1)
                startDate = cal.time
                break
            case "quarter":
                cal.add(Calendar.MONTH, -3)
                startDate = cal.time
                break
            case "year":
                cal.add(Calendar.YEAR, -1)
                startDate = cal.time
                break
            default:
                cal.add(Calendar.MONTH, -1)
                startDate = cal.time
        }
        
        // Query financial documents
        EntityFind entityFind = ec.entity.find("growerp.mobile.FinDoc")
            .condition("entryDate", ">=", startDate)
            .condition("entryDate", "<=", endDate)
        
        if (docType) {
            entityFind.condition("docType", docType)
        }
        
        if (partyId) {
            entityFind.condition("otherPartyId", partyId)
        }
        
        EntityList finDocs = entityFind.list()
        
        BigDecimal totalSales = BigDecimal.ZERO
        BigDecimal totalPurchases = BigDecimal.ZERO
        int openOrders = 0
        int pendingInvoices = 0
        
        finDocs.each { EntityValue doc ->
            if (doc.docType?.startsWith("sales")) {
                totalSales = totalSales.add(doc.grandTotal ?: BigDecimal.ZERO)
            } else if (doc.docType?.startsWith("purchase")) {
                totalPurchases = totalPurchases.add(doc.grandTotal ?: BigDecimal.ZERO)
            }
            
            if (doc.statusId == "FdInPreparation") {
                openOrders++
            } else if (doc.statusId == "FdApproved") {
                pendingInvoices++
            }
        }
        
        BigDecimal netIncome = totalSales.subtract(totalPurchases)
        
        return [
            text: "Financial Summary (${period}):\n\n" +
                  "Total Sales: \$${totalSales}\n" +
                  "Total Purchases: \$${totalPurchases}\n" +
                  "Net Income: \$${netIncome}\n" +
                  "Open Orders: ${openOrders}\n" +
                  "Pending Invoices: ${pendingInvoices}\n" +
                  "Period: ${startDate} to ${endDate}",
            data: [
                totalSales: totalSales,
                totalPurchases: totalPurchases,
                netIncome: netIncome,
                openOrders: openOrders,
                pendingInvoices: pendingInvoices,
                period: period,
                startDate: startDate,
                endDate: endDate
            ]
        ]
    }
}
