package com.mcp

import groovy.json.JsonBuilder
import groovy.transform.CompileStatic
import org.moqui.context.ExecutionContext
import org.slf4j.Logger
import org.slf4j.LoggerFactory

/**
 * MCP Prompt Manager - handles MCP prompt operations
 * Provides templated prompts for common GrowERP/Moqui operations
 */
// @CompileStatic // Temporarily disabled for testing
class McpPromptManager {
    private static final Logger logger = LoggerFactory.getLogger(McpPromptManager.class)
    
    private final ExecutionContext ec
    
    McpPromptManager(ExecutionContext ec) {
        this.ec = ec
    }
    
    Map<String, Object> listPrompts(Map<String, Object> params) {
        List<Map<String, Object>> prompts = []
        
        // Entity operation prompts
        prompts.addAll(getEntityPrompts())
        
        // Business operation prompts
        prompts.addAll(getBusinessPrompts())
        
        // Analysis and reporting prompts
        prompts.addAll(getAnalysisPrompts())
        
        // Development and debugging prompts
        prompts.addAll(getDevelopmentPrompts())
        
        return [prompts: prompts]
    }
    
    Map<String, Object> getPrompt(Map<String, Object> params) {
        String name = params.name as String
        Map<String, Object> arguments = params.arguments as Map ?: [:]
        
        if (!name) {
            throw new IllegalArgumentException("Prompt name is required")
        }
        
        logger.debug("Getting prompt: ${name} with arguments: ${arguments}")
        
        Map<String, Object> promptData = generatePrompt(name, arguments)
        
        return [
            description: promptData.description,
            messages: promptData.messages
        ]
    }
    
    private List<Map<String, Object>> getEntityPrompts() {
        return [
            [
                name: "create_entity_guide",
                description: "Guide for creating entities in GrowERP",
                arguments: [
                    [
                        name: "entityType",
                        description: "Type of entity to create (company, user, product, etc.)",
                        required: true
                    ],
                    [
                        name: "purpose",
                        description: "Purpose or use case for the entity",
                        required: false
                    ]
                ]
            ],
            [
                name: "entity_validation",
                description: "Validate entity data before creation",
                arguments: [
                    [
                        name: "entityType",
                        description: "Type of entity to validate",
                        required: true
                    ],
                    [
                        name: "data",
                        description: "Entity data to validate",
                        required: true
                    ]
                ]
            ],
            [
                name: "entity_relationship_guide",
                description: "Guide for understanding entity relationships",
                arguments: [
                    [
                        name: "primaryEntity",
                        description: "Primary entity name",
                        required: true
                    ]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getBusinessPrompts() {
        return [
            [
                name: "business_process_guide",
                description: "Guide for business processes in GrowERP",
                arguments: [
                    [
                        name: "processType",
                        description: "Type of business process (order-to-cash, procure-to-pay, etc.)",
                        required: true
                    ]
                ]
            ],
            [
                name: "workflow_optimization",
                description: "Suggestions for optimizing business workflows",
                arguments: [
                    [
                        name: "currentProcess",
                        description: "Description of current process",
                        required: true
                    ],
                    [
                        name: "painPoints",
                        description: "Known issues or pain points",
                        required: false
                    ]
                ]
            ],
            [
                name: "financial_analysis",
                description: "Financial analysis and insights",
                arguments: [
                    [
                        name: "analysisType",
                        description: "Type of analysis (profit-loss, cash-flow, etc.)",
                        required: true
                    ],
                    [
                        name: "period",
                        description: "Time period for analysis",
                        required: false
                    ]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getAnalysisPrompts() {
        return [
            [
                name: "data_analysis",
                description: "Analyze GrowERP data for insights",
                arguments: [
                    [
                        name: "dataType",
                        description: "Type of data to analyze (sales, inventory, customers, etc.)",
                        required: true
                    ],
                    [
                        name: "timeframe",
                        description: "Timeframe for analysis",
                        required: false
                    ]
                ]
            ],
            [
                name: "performance_metrics",
                description: "Key performance indicators and metrics",
                arguments: [
                    [
                        name: "department",
                        description: "Department or area (sales, operations, finance, etc.)",
                        required: true
                    ]
                ]
            ],
            [
                name: "trend_analysis",
                description: "Identify trends and patterns in business data",
                arguments: [
                    [
                        name: "metric",
                        description: "Metric to analyze for trends",
                        required: true
                    ]
                ]
            ]
        ]
    }
    
    private List<Map<String, Object>> getDevelopmentPrompts() {
        return [
            [
                name: "service_development",
                description: "Guide for developing Moqui services",
                arguments: [
                    [
                        name: "serviceType",
                        description: "Type of service to develop",
                        required: true
                    ],
                    [
                        name: "functionality",
                        description: "Desired functionality",
                        required: true
                    ]
                ]
            ],
            [
                name: "entity_design",
                description: "Guide for designing entity models",
                arguments: [
                    [
                        name: "businessDomain",
                        description: "Business domain for the entity",
                        required: true
                    ],
                    [
                        name: "requirements",
                        description: "Functional requirements",
                        required: true
                    ]
                ]
            ],
            [
                name: "debugging_guide",
                description: "Debugging guide for common issues",
                arguments: [
                    [
                        name: "issueType",
                        description: "Type of issue (performance, data, logic, etc.)",
                        required: true
                    ],
                    [
                        name: "symptoms",
                        description: "Observed symptoms",
                        required: false
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generatePrompt(String promptName, Map<String, Object> arguments) {
        switch (promptName) {
            case "create_entity_guide":
                return generateCreateEntityGuide(arguments)
            case "entity_validation":
                return generateEntityValidation(arguments)
            case "entity_relationship_guide":
                return generateEntityRelationshipGuide(arguments)
            case "business_process_guide":
                return generateBusinessProcessGuide(arguments)
            case "workflow_optimization":
                return generateWorkflowOptimization(arguments)
            case "financial_analysis":
                return generateFinancialAnalysis(arguments)
            case "data_analysis":
                return generateDataAnalysis(arguments)
            case "performance_metrics":
                return generatePerformanceMetrics(arguments)
            case "trend_analysis":
                return generateTrendAnalysis(arguments)
            case "service_development":
                return generateServiceDevelopment(arguments)
            case "entity_design":
                return generateEntityDesign(arguments)
            case "debugging_guide":
                return generateDebuggingGuide(arguments)
            default:
                throw new IllegalArgumentException("Unknown prompt: ${promptName}")
        }
    }
    
    private Map<String, Object> generateCreateEntityGuide(Map<String, Object> arguments) {
        String entityType = arguments.entityType as String
        String purpose = arguments.purpose as String
        
        String systemPrompt = """You are an expert GrowERP/Moqui consultant helping users create ${entityType} entities.

GrowERP is built on the Moqui framework and uses a specific data model and business logic structure.

Key principles for ${entityType} entities:
- Follow Moqui entity naming conventions
- Ensure proper relationships with existing entities
- Validate required fields and data types
- Consider business rules and constraints
- Plan for extensibility and future requirements

Available tools for ${entityType} creation:
- create_${entityType.toLowerCase()} tool
- Entity validation tools
- Relationship mapping tools

Please provide step-by-step guidance for creating a ${entityType} entity${purpose ? " for ${purpose}" : ""}.
"""

        String userPrompt = """I need help creating a ${entityType} entity in GrowERP${purpose ? " for ${purpose}" : ""}.

Please guide me through:
1. Required fields and their data types
2. Optional fields that might be useful
3. Relationships to other entities
4. Business rules to consider
5. Validation requirements
6. Best practices for this entity type

Also provide a practical example with sample data.
"""

        return [
            description: "Guide for creating ${entityType} entities in GrowERP",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text", 
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateEntityValidation(Map<String, Object> arguments) {
        String entityType = arguments.entityType as String
        String data = arguments.data as String
        
        String systemPrompt = """You are a data validation expert for GrowERP/Moqui systems.

Your role is to validate entity data before creation or updates to ensure:
- Data integrity and consistency
- Compliance with business rules
- Proper formatting and data types
- Required field validation
- Relationship constraints

For ${entityType} entities, pay special attention to:
- Primary key requirements
- Foreign key relationships
- Data format validation (emails, phones, dates, etc.)
- Business logic constraints
- Moqui framework requirements
"""

        String userPrompt = """Please validate this ${entityType} entity data:

${data}

Check for:
1. Required fields
2. Data type correctness
3. Format validation
4. Business rule compliance
5. Potential issues or improvements
6. Missing relationships

Provide specific feedback and suggestions for any issues found.
"""

        return [
            description: "Validate ${entityType} entity data",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateEntityRelationshipGuide(Map<String, Object> arguments) {
        String primaryEntity = arguments.primaryEntity as String
        
        String systemPrompt = """You are a GrowERP/Moqui data architect helping users understand entity relationships.

The GrowERP data model includes these core entity types:
- Party (companies, persons, users)
- Product (catalog items, services)
- FinDoc (orders, invoices, payments)
- Asset (inventory, equipment)
- Opportunity (sales prospects)
- UserAccount (authentication, authorization)

For ${primaryEntity} entities, focus on:
- Direct relationships (foreign keys)
- Indirect relationships (through junction entities)
- Business logic connections
- Data flow patterns
- Common query patterns
"""

        String userPrompt = """Help me understand the relationships for ${primaryEntity} entities in GrowERP.

Please explain:
1. Direct relationships (what entities link to ${primaryEntity})
2. Indirect relationships (what connects through other entities)
3. Common business scenarios involving ${primaryEntity}
4. Query patterns and joins typically used
5. Data dependencies and constraints
6. Best practices for working with ${primaryEntity} relationships

Provide examples of typical relationship scenarios.
"""

        return [
            description: "Understanding ${primaryEntity} entity relationships",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateBusinessProcessGuide(Map<String, Object> arguments) {
        String processType = arguments.processType as String
        
        String systemPrompt = """You are a GrowERP business process expert helping users understand and optimize business workflows.

GrowERP supports these key business processes:
- Order-to-Cash (sales order → invoice → payment)
- Procure-to-Pay (purchase order → receipt → payment)
- Lead-to-Opportunity (marketing → sales → conversion)
- Inventory Management (receiving → storage → fulfillment)
- Financial Management (accounting → reporting → analysis)

For ${processType} processes, consider:
- Standard workflow steps
- Entity interactions and data flow
- Business rules and validations
- Integration points
- Performance considerations
- Compliance requirements
"""

        String userPrompt = """Help me understand the ${processType} business process in GrowERP.

Please explain:
1. Standard workflow steps and sequence
2. Key entities and data involved
3. Business rules and validations
4. Common variations or exceptions
5. Integration points with other processes
6. Performance and optimization considerations
7. Best practices and common pitfalls

Provide a practical example with step-by-step implementation.
"""

        return [
            description: "Guide for ${processType} business process",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateWorkflowOptimization(Map<String, Object> arguments) {
        String currentProcess = arguments.currentProcess as String
        String painPoints = arguments.painPoints as String
        
        String systemPrompt = """You are a business process optimization expert specializing in GrowERP implementations.

Your expertise includes:
- Workflow analysis and improvement
- GrowERP feature utilization
- Business rule optimization
- Integration opportunities
- Performance tuning
- User experience enhancement

Focus on practical, implementable solutions that leverage GrowERP's capabilities.
"""

        String userPrompt = """Help me optimize this business workflow:

Current Process:
${currentProcess}

${painPoints ? "Pain Points:\n${painPoints}\n" : ""}

Please provide:
1. Analysis of the current workflow
2. Identification of inefficiencies
3. Specific optimization recommendations
4. GrowERP features that could help
5. Implementation steps
6. Expected benefits and ROI
7. Potential risks and mitigation

Focus on practical, actionable improvements.
"""

        return [
            description: "Workflow optimization recommendations",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateFinancialAnalysis(Map<String, Object> arguments) {
        String analysisType = arguments.analysisType as String
        String period = arguments.period as String
        
        String systemPrompt = """You are a financial analyst expert in GrowERP financial management.

GrowERP provides comprehensive financial data including:
- Sales and revenue tracking
- Purchase and expense management
- Invoice and payment processing
- Financial document workflows
- General ledger integration
- Multi-currency support

For ${analysisType} analysis, focus on:
- Key financial metrics and KPIs
- Data sources and calculations
- Trend identification
- Performance benchmarks
- Actionable insights
- Business recommendations
"""

        String userPrompt = """Help me perform a ${analysisType} analysis in GrowERP${period ? " for ${period}" : ""}.

Please provide:
1. Key metrics to track for ${analysisType}
2. Data sources and how to access them
3. Calculation methods and formulas
4. Interpretation guidelines
5. Common patterns and what they indicate
6. Actionable recommendations based on results
7. Tools and reports available in GrowERP

Include practical examples and implementation steps.
"""

        return [
            description: "${analysisType} analysis guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateDataAnalysis(Map<String, Object> arguments) {
        String dataType = arguments.dataType as String
        String timeframe = arguments.timeframe as String
        
        String systemPrompt = """You are a data analytics expert specializing in GrowERP business intelligence.

GrowERP contains rich business data across:
- Customer and supplier information
- Product and inventory data
- Sales and purchase transactions
- Financial documents and payments
- User activity and system usage

For ${dataType} data analysis, consider:
- Data quality and completeness
- Statistical methods and techniques
- Visualization approaches
- Pattern recognition
- Predictive insights
- Business impact assessment
"""

        String userPrompt = """Help me analyze ${dataType} data in GrowERP${timeframe ? " for ${timeframe}" : ""}.

Please guide me through:
1. Data sources and extraction methods
2. Data quality checks and cleaning
3. Analysis techniques appropriate for ${dataType}
4. Key metrics and calculations
5. Visualization recommendations
6. Pattern identification approaches
7. Insights and business implications
8. Action items based on findings

Provide practical examples and implementation steps.
"""

        return [
            description: "${dataType} data analysis guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generatePerformanceMetrics(Map<String, Object> arguments) {
        String department = arguments.department as String
        
        String systemPrompt = """You are a performance management expert focused on GrowERP KPIs and metrics.

GrowERP enables tracking performance across:
- Sales effectiveness and revenue
- Operations efficiency and productivity
- Finance health and profitability
- Customer satisfaction and retention
- Inventory turnover and optimization
- User adoption and system utilization

For ${department} performance, emphasize:
- Industry-standard KPIs
- GrowERP-specific metrics
- Benchmark comparisons
- Trend analysis
- Goal setting and tracking
- Dashboard and reporting
"""

        String userPrompt = """Help me establish performance metrics for ${department} using GrowERP data.

Please provide:
1. Key performance indicators for ${department}
2. How to calculate each metric in GrowERP
3. Industry benchmarks and targets
4. Frequency of measurement and reporting
5. Dashboard and visualization recommendations
6. Early warning indicators
7. Action triggers and responses
8. Performance improvement strategies

Include specific examples and implementation guidance.
"""

        return [
            description: "${department} performance metrics guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateTrendAnalysis(Map<String, Object> arguments) {
        String metric = arguments.metric as String
        
        String systemPrompt = """You are a trend analysis expert specializing in business intelligence and forecasting.

Trend analysis in GrowERP involves:
- Historical data patterns
- Seasonal variations
- Growth rates and trajectories
- Correlation analysis
- Predictive modeling
- Business cycle impacts

For ${metric} trend analysis, focus on:
- Data collection and preparation
- Statistical techniques
- Pattern recognition
- Forecasting methods
- Business context interpretation
- Strategic implications
"""

        String userPrompt = """Help me analyze trends in ${metric} using GrowERP data.

Please guide me through:
1. Data requirements and collection for ${metric}
2. Time series analysis techniques
3. Trend identification methods
4. Seasonal and cyclical pattern detection
5. Correlation with other business factors
6. Forecasting approaches and accuracy
7. Business interpretation and implications
8. Strategic recommendations based on trends

Provide practical examples and step-by-step implementation.
"""

        return [
            description: "${metric} trend analysis guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateServiceDevelopment(Map<String, Object> arguments) {
        String serviceType = arguments.serviceType as String
        String functionality = arguments.functionality as String
        
        String systemPrompt = """You are a Moqui framework development expert helping create custom services for GrowERP.

Moqui service development principles:
- Service-oriented architecture
- Transaction management
- Parameter validation
- Error handling
- Security and authorization
- Performance optimization
- Testing and documentation

For ${serviceType} services, consider:
- Service interface design
- Implementation patterns
- Data access strategies
- Business logic organization
- Integration approaches
- Deployment and maintenance
"""

        String userPrompt = """Help me develop a ${serviceType} service in Moqui for this functionality:

${functionality}

Please provide:
1. Service definition structure (XML)
2. Implementation approach (Groovy/Java)
3. Parameter design and validation
4. Business logic organization
5. Error handling strategies
6. Security considerations
7. Testing approaches
8. Documentation requirements
9. Performance optimization tips
10. Integration with existing GrowERP services

Include code examples and best practices.
"""

        return [
            description: "${serviceType} service development guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateEntityDesign(Map<String, Object> arguments) {
        String businessDomain = arguments.businessDomain as String
        String requirements = arguments.requirements as String
        
        String systemPrompt = """You are a data modeling expert specializing in Moqui entity design for business applications.

Moqui entity design principles:
- Normalized data structures
- Relationship integrity
- Performance considerations
- Extensibility planning
- Business rule enforcement
- Multi-tenancy support
- Audit and history tracking

For ${businessDomain} entities, focus on:
- Domain modeling best practices
- Entity relationship design
- Field definition and constraints
- Index optimization
- Business rule implementation
- Integration with existing model
"""

        String userPrompt = """Help me design entities for the ${businessDomain} domain with these requirements:

${requirements}

Please provide:
1. Entity model design and relationships
2. Field definitions and data types
3. Primary and foreign key strategies
4. Index recommendations
5. Business rule implementation
6. Integration with existing GrowERP entities
7. Extensibility considerations
8. Performance optimization
9. Security and access control
10. Migration and deployment strategy

Include XML entity definitions and implementation examples.
"""

        return [
            description: "${businessDomain} entity design guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
    
    private Map<String, Object> generateDebuggingGuide(Map<String, Object> arguments) {
        String issueType = arguments.issueType as String
        String symptoms = arguments.symptoms as String
        
        String systemPrompt = """You are a GrowERP/Moqui troubleshooting expert helping diagnose and resolve system issues.

Common issue categories:
- Performance problems (slow queries, timeouts)
- Data issues (validation errors, inconsistencies)
- Logic errors (business rule failures, workflow problems)
- Integration issues (API errors, data sync problems)
- User interface problems (display issues, navigation errors)
- Security and permission problems

For ${issueType} issues, focus on:
- Systematic diagnosis approaches
- Common root causes
- Debugging tools and techniques
- Log analysis methods
- Resolution strategies
- Prevention measures
"""

        String userPrompt = """Help me debug this ${issueType} issue in GrowERP:

${symptoms ? "Symptoms:\n${symptoms}\n" : ""}

Please provide:
1. Systematic diagnosis approach
2. Common causes for ${issueType} issues
3. Debugging tools and techniques to use
4. Log files and monitoring to check
5. Step-by-step troubleshooting process
6. Resolution strategies
7. Prevention and monitoring recommendations
8. When to escalate or seek additional help

Include practical examples and specific commands/queries where applicable.
"""

        return [
            description: "${issueType} debugging guide",
            messages: [
                [
                    role: "system",
                    content: [
                        type: "text",
                        text: systemPrompt
                    ]
                ],
                [
                    role: "user",
                    content: [
                        type: "text",
                        text: userPrompt
                    ]
                ]
            ]
        ]
    }
}
