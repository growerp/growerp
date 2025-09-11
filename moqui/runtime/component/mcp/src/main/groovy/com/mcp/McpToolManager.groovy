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
        
        ec.logger.info("===========Calling tool: ${name} with arguments: ${arguments}")
        
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
                description: "Create a new company in the system",
                inputSchema: [
                    type: "object",
                    properties: [
                        companyName: [type: "string", description: "Company name"],
                        description: [type: "string", description: "Company description"],
                        currencyUomId: [type: "string", description: "Default currency (USD, EUR, etc.)"],
                        emailAddress: [type: "string", description: "Company email address"],
                        website: [type: "string", description: "Company website"]
                    ],
                    required: ["companyName"]
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
                description: "Create a new product in the catalog",
                inputSchema: [
                    type: "object",
                    properties: [
                        productName: [type: "string", description: "Product name"],
                        description: [type: "string", description: "Product description"],
                        listPrice: [type: "number", description: "List price"],
                        productCategoryId: [type: "string", description: "Product category ID"],
                        productTypeEnumId: [type: "string", description: "Product type (PtFinished, PtService, etc.)"]
                    ],
                    required: ["productName"]
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
                description: "Create an invoice",
                inputSchema: [
                    type: "object",
                    properties: [
                        partyId: [type: "string", description: "Customer/Supplier party ID"],
                        invoiceType: [type: "string", description: "Invoice type (sales/purchase)"],
                        finDocId: [type: "string", description: "Related order ID (optional)"],
                        items: [
                            type: "array",
                            description: "Invoice items",
                            items: [
                                type: "object",
                                properties: [
                                    productId: [type: "string", description: "Product ID"],
                                    quantity: [type: "number", description: "Quantity"],
                                    price: [type: "number", description: "Unit price"]
                                ],
                                required: ["productId", "quantity", "price"]
                            ]
                        ]
                    ],
                    required: ["partyId", "invoiceType", "items"]
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
                        limit: [type: "number", description: "Maximum number of results", default: 20],
                        searchTerm: [type: "string", description: "Search term for company name"],
                        partyTypeEnumId: [type: "string", description: "Party type filter"]
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
                        limit: [type: "number", description: "Maximum number of results", default: 20],
                        searchTerm: [type: "string", description: "Search term for product name"],
                        productCategoryId: [type: "string", description: "Filter by category"]
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
                name: "get_financial_summary",
                description: "Get financial summary and reports",
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
        logger.info("===!!===ex groovy==Executing tool: ${toolName} with arguments: ${arguments}")
        switch (toolName) {
            // Entity CRUD operations
            case "create_company":
                return executeCreateCompany(arguments)
            case "create_user":
                return executeCreateUser(arguments)
            case "create_product":
                return executeCreateProduct(arguments)
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
                return executeGetCompanies(arguments)
            case "get_users":
                return executeGetUsers(arguments)
            case "get_products":
                return executeGetProducts(arguments)
            case "get_orders":
                return executeGetOrders(arguments)
            case "get_financial_summary":
                return executeGetFinancialSummary(arguments)
                
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
        logger.info("========Calling tool: create_company with arguments: ${arguments}")
        String companyName = arguments.companyName as String
        String description = arguments.description as String
        String currencyUomId = (arguments.currencyUomId as String) ?: "USD"
        String emailAddress = arguments.emailAddress as String
        String website = arguments.website as String
        
        Map<String, Object> serviceParams = [
            companyName: companyName,
            description: description,
            currencyUomId: currencyUomId
        ]
        
        if (emailAddress) serviceParams.emailAddress = emailAddress
        if (website) serviceParams.website = website
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.PartyServices.create#Company")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created company '${companyName}' with ID: ${result.partyId}",
                data: result
            ]
        } catch (Exception e) {
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.PartyServices.create#Person")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created user '${username}' with ID: ${result.partyId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create user: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreateProduct(Map<String, Object> arguments) {
        String productName = arguments.productName as String
        String description = arguments.description as String
        BigDecimal listPrice = arguments.listPrice as BigDecimal
        String productCategoryId = arguments.productCategoryId as String
        String productTypeEnumId = (arguments.productTypeEnumId as String) ?: "PtFinished"
        
        Map<String, Object> serviceParams = [
            productName: productName,
            description: description,
            productTypeEnumId: productTypeEnumId
        ]
        
        if (listPrice) serviceParams.listPrice = listPrice
        if (productCategoryId) serviceParams.productCategoryId = productCategoryId
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.ProductServices.create#Product")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created product '${productName}' with ID: ${result.productId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create product: ${e.message}", e)
        }
    }
    
    // Query implementations
    private Map<String, Object> executeGetCompanies(Map<String, Object> arguments) {
        // Check for explicit API key authentication - more strict than service
        String apiKey = ec.web?.request?.getHeader('api_key')
        
        if (!apiKey || apiKey.trim().isEmpty() || 'null'.equals(apiKey) || 'undefined'.equals(apiKey)) {
            throw new IllegalStateException("Authentication required: API key required for MCP tool access")
        }
        
        // Validate the API key
        def authResult = ec.service.sync().name("McpAuthServices.validate#McpApiKey")
            .parameter("apiKey", apiKey).call()
        if (!authResult.authenticated) {
            throw new IllegalStateException("Authentication required: ${authResult.errorMessage ?: 'Invalid API key'}")
        }
        
        // Simple implementation to test authentication
        return [
            text: "Authentication successful! Found 3 companies: Main Company, Test Company, Demo Company",
            data: [
                [partyId: "100001", companyName: "Main Company", partyTypeEnumId: "PtyOrganization"],
                [partyId: "100002", companyName: "Test Company", partyTypeEnumId: "PtyOrganization"], 
                [partyId: "100003", companyName: "Demo Company", partyTypeEnumId: "PtyOrganization"]
            ]
        ]
    }
    
    private Map<String, Object> executeGetUsers(Map<String, Object> arguments) {
        Integer limit = (arguments.limit as Integer) ?: 20
        String searchTerm = arguments.searchTerm as String
        String companyPartyId = arguments.companyPartyId as String
        
        EntityFind entityFind = ec.entity.find("UserAccount")
        
        if (searchTerm) {
            entityFind.condition([
                ec.entity.conditionFactory.makeCondition("username", "like", "%${searchTerm}%"),
                ec.entity.conditionFactory.makeCondition("userFullName", "like", "%${searchTerm}%")
            ], "or")
        }
        
        EntityList users = entityFind.orderBy("username").limit(limit).list()
        
        StringBuilder result = new StringBuilder("Found ${users.size()} users:\n\n")
        
        users.each { EntityValue user ->
            result.append("- ${user.username}")
            if (user.userFullName) {
                result.append(" (${user.userFullName})")
            }
            if (user.emailAddress) {
                result.append(" - ${user.emailAddress}")
            }
            result.append("\n")
        }
        
        return [
            text: result.toString(),
            data: users.collect { EntityValue it ->
                [
                    userId: it.userId,
                    username: it.username,
                    userFullName: it.userFullName,
                    emailAddress: it.emailAddress,
                    disabled: it.disabled
                ]
            }
        ]
    }
    
    private Map<String, Object> executeGetProducts(Map<String, Object> arguments) {
        Integer limit = (arguments.limit as Integer) ?: 20
        String searchTerm = arguments.searchTerm as String
        String productCategoryId = arguments.productCategoryId as String
        
        EntityFind entityFind = ec.entity.find("Product")
        
        if (searchTerm) {
            entityFind.condition([
                ec.entity.conditionFactory.makeCondition("productName", "like", "%${searchTerm}%"),
                ec.entity.conditionFactory.makeCondition("description", "like", "%${searchTerm}%")
            ], "or")
        }
        
        if (productCategoryId) {
            entityFind.condition("productCategoryId", productCategoryId)
        }
        
        EntityList products = entityFind.orderBy("productName").limit(limit).list()
        
        StringBuilder result = new StringBuilder("Found ${products.size()} products:\n\n")
        
        products.each { EntityValue product ->
            result.append("- ${product.productName} (ID: ${product.productId})")
            if (product.description) {
                result.append(" - ${product.description}")
            }
            result.append("\n")
        }
        
        return [
            text: result.toString(),
            data: products.collect { EntityValue it ->
                [
                    productId: it.productId,
                    productName: it.productName,
                    description: it.description,
                    productTypeEnumId: it.productTypeEnumId
                ]
            }
        ]
    }
    
    private Map<String, Object> executeGetOrders(Map<String, Object> arguments) {
        Integer limit = (arguments.limit as Integer) ?: 20
        String docType = arguments.docType as String
        String statusId = arguments.statusId as String
        String partyId = arguments.partyId as String
        
        EntityFind entityFind = ec.entity.find("growerp.mobile.FinDoc")
        
        if (docType) {
            entityFind.condition("docType", docType)
        }
        
        if (statusId) {
            entityFind.condition("statusId", statusId)
        }
        
        if (partyId) {
            entityFind.condition("otherPartyId", partyId)
        }
        
        EntityList orders = entityFind.orderBy("-entryDate").limit(limit).list()
        
        StringBuilder result = new StringBuilder("Found ${orders.size()} orders:\n\n")
        
        orders.each { EntityValue order ->
            result.append("- ${order.description ?: order.finDocId}")
            result.append(" (${order.docType})")
            if (order.grandTotal) {
                result.append(" - \$${order.grandTotal}")
            }
            result.append(" - ${order.statusId}")
            result.append("\n")
        }
        
        return [
            text: result.toString(),
            data: orders.collect { EntityValue it ->
                [
                    finDocId: it.finDocId,
                    docType: it.docType,
                    description: it.description,
                    grandTotal: it.grandTotal,
                    statusId: it.statusId,
                    entryDate: it.entryDate
                ]
            }
        ]
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.OrderServices.create#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created sales order with ID: ${result.finDocId}",
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.OrderServices.create#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created purchase order with ID: ${result.finDocId}",
                data: result
            ]
        } catch (Exception e) {
            throw new RuntimeException("Failed to create purchase order: ${e.message}", e)
        }
    }
    
    private Map<String, Object> executeCreateInvoice(Map<String, Object> arguments) {
        // Implementation for creating invoices
        String partyId = arguments.partyId as String
        String invoiceType = arguments.invoiceType as String
        String finDocId = arguments.finDocId as String
        List<Map> items = arguments.items as List<Map>
        
        Map<String, Object> serviceParams = [
            salesInvoiceType: invoiceType,
            otherCompanyPartyId: partyId,
            items: items
        ]
        
        if (finDocId) serviceParams.orderId = finDocId
        
        try {
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.OrderServices.create#FinDoc")
                .parameters(serviceParams).call()
            
            return [
                text: "Successfully created ${invoiceType} invoice with ID: ${result.finDocId}",
                data: result
            ]
        } catch (Exception e) {
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.OrderServices.update#FinDoc")
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.PartyServices.update#Company")
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
            Map<String, Object> result = ec.service.sync().name("growerp.mobile.PartyServices.update#Person")
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
