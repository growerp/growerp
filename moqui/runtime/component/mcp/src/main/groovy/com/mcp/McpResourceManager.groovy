package com.mcp

import groovy.json.JsonBuilder
import groovy.transform.CompileStatic
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.moqui.entity.EntityList
import org.moqui.entity.EntityFind
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * MCP Resource Manager - handles MCP resource operations
 * Provides access to GrowERP entities, schemas, and system information
 */
// @CompileStatic // Temporarily disabled for testing
class McpResourceManager {
    private static final Logger logger = LoggerFactory.getLogger(McpResourceManager.class)
    
    private final ExecutionContext ec
    
    McpResourceManager(ExecutionContext ec) {
        this.ec = ec
    }
    
    Map<String, Object> listResources(Map<String, Object> params) {
        List<Map<String, Object>> resources = []
        
        // Entity resources
        resources.addAll(getEntityResources())
        
        // Service resources
        resources.addAll(getServiceResources())
        
        // System resources
        resources.addAll(getSystemResources())
        
        // Configuration resources
        resources.addAll(getConfigurationResources())
        
        return [resources: resources]
    }
    
    Map<String, Object> readResource(Map<String, Object> params) {
        String uri = params.uri as String
        
        if (!uri) {
            throw new IllegalArgumentException("Resource URI is required")
        }
        
        URI resourceUri = new URI(uri)
        String scheme = resourceUri.scheme
        String path = resourceUri.path
        
        if (scheme != "growerp") {
            throw new IllegalArgumentException("Unsupported URI scheme: ${scheme}")
        }
        
        String[] pathParts = path.split("/").findAll { it }
        
        if (pathParts.length < 2) {
            throw new IllegalArgumentException("Invalid resource path: ${path}")
        }
        
        String resourceType = pathParts[0]
        String resourceName = pathParts[1]
        
        switch (resourceType) {
            case "entities":
                return readEntityResource(resourceName, pathParts[2..-1])
            case "services":
                return readServiceResource(resourceName, pathParts[2..-1])
            case "system":
                return readSystemResource(resourceName, pathParts[2..-1])
            case "config":
                return readConfigResource(resourceName, pathParts[2..-1])
            default:
                throw new IllegalArgumentException("Unknown resource type: ${resourceType}")
        }
    }
    
    private List<Map<String, Object>> getEntityResources() {
        return [
            [
                uri: "growerp://entities/company",
                name: "Company Entities",
                description: "Company/Party entities and their schemas",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://entities/user",
                name: "User Entities",
                description: "User entities and authentication data",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://entities/product",
                name: "Product Entities",
                description: "Product catalog entities and categories",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://entities/findoc",
                name: "Financial Document Entities",
                description: "Orders, invoices, payments and financial documents",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://entities/opportunity",
                name: "Opportunity Entities",
                description: "Sales opportunities and CRM data",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://entities/asset",
                name: "Asset Entities", 
                description: "Asset management and inventory data",
                mimeType: "application/json"
            ]
        ]
    }
    
    private List<Map<String, Object>> getServiceResources() {
        return [
            [
                uri: "growerp://services/party",
                name: "Party Management Services",
                description: "Services for managing companies and users",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://services/catalog",
                name: "Catalog Management Services",
                description: "Services for managing products and categories",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://services/order",
                name: "Order Management Services",
                description: "Services for managing orders and financial documents",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://services/accounting",
                name: "Accounting Services",
                description: "Financial and accounting related services",
                mimeType: "application/json"
            ]
        ]
    }
    
    private List<Map<String, Object>> getSystemResources() {
        return [
            [
                uri: "growerp://system/status",
                name: "System Status",
                description: "Current system health and operational status",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://system/info",
                name: "System Information",
                description: "Moqui framework and GrowERP version information",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://system/entities",
                name: "Entity Definitions",
                description: "All available entity definitions and their fields",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://system/services",
                name: "Service Definitions",
                description: "All available service definitions and parameters",
                mimeType: "application/json"
            ]
        ]
    }
    
    private List<Map<String, Object>> getConfigurationResources() {
        return [
            [
                uri: "growerp://config/app",
                name: "Application Configuration",
                description: "GrowERP application configuration settings",
                mimeType: "application/json"
            ],
            [
                uri: "growerp://config/security",
                name: "Security Configuration",
                description: "Security and authentication configuration",
                mimeType: "application/json"
            ]
        ]
    }
    
    private Map<String, Object> readEntityResource(String entityName, List<String> subPath) {
        switch (entityName) {
            case "company":
                return readCompanyEntities(subPath)
            case "user":
                return readUserEntities(subPath)
            case "product":
                return readProductEntities(subPath)
            case "findoc":
                return readFinDocEntities(subPath)
            case "opportunity":
                return readOpportunityEntities(subPath)
            case "asset":
                return readAssetEntities(subPath)
            default:
                throw new IllegalArgumentException("Unknown entity resource: ${entityName}")
        }
    }
    
    private Map<String, Object> readCompanyEntities(List<String> subPath) {
        // Get sample company data
        EntityList companies = ec.entity.find("Party")
            .condition("partyTypeEnumId", "PtyOrganization")
            .orderBy("organizationName")
            .limit(10)
            .list()
        
        Map<String, Object> schema = getEntitySchema("Party")
        
        return [
            contents: [[
                uri: "growerp://entities/company",
                mimeType: "application/json",
                text: new JsonBuilder([
                    entityName: "Party",
                    description: "Company/Organization entities",
                    schema: schema,
                    sampleData: companies.collect { EntityValue it -> 
                        [
                            partyId: it.partyId,
                            partyTypeEnumId: it.partyTypeEnumId,
                            organizationName: it.organizationName,
                            description: it.description
                        ]
                    },
                    count: companies.size(),
                    totalCount: ec.entity.find("Party").condition("partyTypeEnumId", "PtyOrganization").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readUserEntities(List<String> subPath) {
        // Get sample user data
        EntityList users = ec.entity.find("UserAccount")
            .orderBy("username")
            .limit(10)
            .list()
        
        Map<String, Object> schema = getEntitySchema("UserAccount")
        
        return [
            contents: [[
                uri: "growerp://entities/user", 
                mimeType: "application/json",
                text: new JsonBuilder([
                    entityName: "UserAccount",
                    description: "User account entities",
                    schema: schema,
                    sampleData: users.collect { EntityValue it ->
                        [
                            userId: it.userId,
                            username: it.username,
                            userFullName: it.userFullName,
                            emailAddress: it.emailAddress,
                            disabled: it.disabled
                        ]
                    },
                    count: users.size(),
                    totalCount: ec.entity.find("UserAccount").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readProductEntities(List<String> subPath) {
        // Get sample product data
        EntityList products = ec.entity.find("Product")
            .orderBy("productName")
            .limit(10)
            .list()
        
        Map<String, Object> schema = getEntitySchema("Product")
        
        return [
            contents: [[
                uri: "growerp://entities/product",
                mimeType: "application/json", 
                text: new JsonBuilder([
                    entityName: "Product",
                    description: "Product entities",
                    schema: schema,
                    sampleData: products.collect { EntityValue it ->
                        [
                            productId: it.productId,
                            productName: it.productName,
                            description: it.description,
                            productTypeEnumId: it.productTypeEnumId
                        ]
                    },
                    count: products.size(),
                    totalCount: ec.entity.find("Product").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readFinDocEntities(List<String> subPath) {
        // Get sample financial document data
        EntityList finDocs = ec.entity.find("growerp.mobile.FinDoc")
            .orderBy("-entryDate")
            .limit(10)
            .list()
        
        return [
            contents: [[
                uri: "growerp://entities/findoc",
                mimeType: "application/json",
                text: new JsonBuilder([
                    entityName: "FinDoc",
                    description: "Financial document entities (orders, invoices, payments)",
                    sampleData: finDocs.collect { EntityValue it ->
                        [
                            finDocId: it.finDocId,
                            docType: it.docType,
                            description: it.description,
                            grandTotal: it.grandTotal,
                            statusId: it.statusId,
                            entryDate: it.entryDate
                        ]
                    },
                    count: finDocs.size(),
                    totalCount: ec.entity.find("growerp.mobile.FinDoc").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readOpportunityEntities(List<String> subPath) {
        // Get sample opportunity data
        EntityList opportunities = ec.entity.find("growerp.mobile.Opportunity")
            .orderBy("-entryDate")
            .limit(10)
            .list()
        
        return [
            contents: [[
                uri: "growerp://entities/opportunity",
                mimeType: "application/json",
                text: new JsonBuilder([
                    entityName: "Opportunity",
                    description: "Sales opportunity entities",
                    sampleData: opportunities.collect { EntityValue it ->
                        [
                            opportunityId: it.opportunityId,
                            opportunityName: it.opportunityName,
                            description: it.description,
                            estimatedAmount: it.estimatedAmount,
                            estProbability: it.estProbability,
                            opportunityStageId: it.opportunityStageId
                        ]
                    },
                    count: opportunities.size(),
                    totalCount: ec.entity.find("growerp.mobile.Opportunity").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readAssetEntities(List<String> subPath) {
        // Get sample asset data
        EntityList assets = ec.entity.find("Asset")
            .orderBy("assetName")
            .limit(10)
            .list()
        
        Map<String, Object> schema = getEntitySchema("Asset")
        
        return [
            contents: [[
                uri: "growerp://entities/asset",
                mimeType: "application/json",
                text: new JsonBuilder([
                    entityName: "Asset",
                    description: "Asset management entities",
                    schema: schema,
                    sampleData: assets.collect { EntityValue it ->
                        [
                            assetId: it.assetId,
                            assetName: it.assetName,
                            assetTypeEnumId: it.assetTypeEnumId,
                            statusId: it.statusId,
                            ownerPartyId: it.ownerPartyId
                        ]
                    },
                    count: assets.size(),
                    totalCount: ec.entity.find("Asset").count()
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readServiceResource(String serviceName, List<String> subPath) {
        // Return service documentation based on service definitions
        Map<String, Object> serviceInfo = getServiceInfo(serviceName)
        
        return [
            contents: [[
                uri: "growerp://services/${serviceName}",
                mimeType: "application/json",
                text: new JsonBuilder(serviceInfo).toString()
            ]]
        ]
    }
    
    private Map<String, Object> readSystemResource(String resourceName, List<String> subPath) {
        switch (resourceName) {
            case "status":
                return getSystemStatus()
            case "info":
                return getSystemInfo()
            case "entities":
                return getEntityDefinitions()
            case "services":
                return getServiceDefinitions()
            default:
                throw new IllegalArgumentException("Unknown system resource: ${resourceName}")
        }
    }
    
    private Map<String, Object> readConfigResource(String configName, List<String> subPath) {
        // Return configuration information
        Map<String, Object> configInfo = getConfigurationInfo(configName)
        
        return [
            contents: [[
                uri: "growerp://config/${configName}",
                mimeType: "application/json",
                text: new JsonBuilder(configInfo).toString()
            ]]
        ]
    }
    
    private Map<String, Object> getEntitySchema(String entityName) {
        // Get entity definition from Moqui
        def entityDefinition = ec.entity.getEntityDefinition(entityName)
        if (!entityDefinition) {
            return [error: "Entity not found: ${entityName}"]
        }
        
        Map<String, Object> schema = [
            entityName: entityName,
            packageName: entityDefinition.packageName,
            tableName: entityDefinition.tableName,
            fields: [:]
        ]
        
        entityDefinition.fieldInfoList.each { fieldInfo ->
            schema.fields[fieldInfo.name] = [
                type: fieldInfo.type,
                isPk: fieldInfo.isPk,
                isNotNull: fieldInfo.isNotNull,
                columnName: fieldInfo.columnName
            ]
        }
        
        return schema
    }
    
    private Map<String, Object> getServiceInfo(String serviceName) {
        // Return information about available services in the specified category
        switch (serviceName) {
            case "party":
                return [
                    category: "Party Management",
                    description: "Services for managing companies, users, and party relationships",
                    services: [
                        "growerp.mobile.PartyServices.create#Company",
                        "growerp.mobile.PartyServices.update#Company", 
                        "growerp.mobile.PartyServices.create#Person",
                        "growerp.mobile.PartyServices.update#Person"
                    ]
                ]
            case "catalog":
                return [
                    category: "Catalog Management",
                    description: "Services for managing products, categories, and catalog data",
                    services: [
                        "growerp.mobile.ProductServices.create#Product",
                        "growerp.mobile.ProductServices.update#Product",
                        "growerp.mobile.ProductServices.create#Category",
                        "growerp.mobile.ProductServices.update#Category"
                    ]
                ]
            case "order":
                return [
                    category: "Order Management", 
                    description: "Services for managing orders, invoices, and financial documents",
                    services: [
                        "growerp.mobile.OrderServices.create#FinDoc",
                        "growerp.mobile.OrderServices.update#FinDoc",
                        "growerp.mobile.OrderServices.approve#FinDoc"
                    ]
                ]
            case "accounting":
                return [
                    category: "Accounting",
                    description: "Financial and accounting related services",
                    services: [
                        "growerp.mobile.AccountingServices.create#GlAccount",
                        "growerp.mobile.AccountingServices.post#AcctgTrans"
                    ]
                ]
            default:
                return [error: "Unknown service category: ${serviceName}"]
        }
    }
    
    private Map<String, Object> getSystemStatus() {
        return [
            contents: [[
                uri: "growerp://system/status",
                mimeType: "application/json",
                text: new JsonBuilder([
                    status: "healthy",
                    timestamp: new Date().time,
                    moquiVersion: ec.factory.moquiVersion,
                    javaVersion: System.getProperty("java.version"),
                    uptime: System.currentTimeMillis() - ec.factory.startTime,
                    database: [
                        connected: true,
                        type: ec.entity.getDatasourceInfo(ec.entity.getDefaultDatasourceName()).databaseProductName
                    ]
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> getSystemInfo() {
        return [
            contents: [[
                uri: "growerp://system/info",
                mimeType: "application/json",
                text: new JsonBuilder([
                    moqui: [
                        version: ec.factory.moquiVersion,
                        buildInfo: ec.factory.moquiBuildInfo
                    ],
                    growerp: [
                        version: "1.9.0",
                        components: ["growerp", "growerp-mcp-server"]
                    ],
                    system: [
                        javaVersion: System.getProperty("java.version"),
                        javaVendor: System.getProperty("java.vendor"),
                        osName: System.getProperty("os.name"),
                        osVersion: System.getProperty("os.version")
                    ]
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> getEntityDefinitions() {
        List<String> entityNames = ec.entity.getAllEntityNames().sort()
        
        return [
            contents: [[
                uri: "growerp://system/entities",
                mimeType: "application/json",
                text: new JsonBuilder([
                    totalCount: entityNames.size(),
                    entities: entityNames.take(100) // Limit for performance
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> getServiceDefinitions() {
        // Get service registry information
        def serviceRegistry = ec.service.serviceRegistry
        List<String> serviceNames = serviceRegistry.getServiceNames().sort()
        
        return [
            contents: [[
                uri: "growerp://system/services",
                mimeType: "application/json",
                text: new JsonBuilder([
                    totalCount: serviceNames.size(),
                    services: serviceNames.take(100) // Limit for performance
                ]).toString()
            ]]
        ]
    }
    
    private Map<String, Object> getConfigurationInfo(String configName) {
        switch (configName) {
            case "app":
                return [
                    applicationName: "GrowERP",
                    version: "1.9.0",
                    classification: "AppAdmin",
                    features: ["accounting", "inventory", "crm", "catalog", "website"],
                    defaultCurrency: "USD"
                ]
            case "security":
                return [
                    authenticationRequired: true,
                    sessionTimeout: 24 * 60 * 60 * 1000, // 24 hours
                    passwordPolicy: [
                        minLength: 8,
                        requireSpecialChar: false,
                        requireNumber: false
                    ]
                ]
            default:
                return [error: "Unknown configuration: ${configName}"]
        }
    }
}
