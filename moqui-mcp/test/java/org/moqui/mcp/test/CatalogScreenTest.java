/*
 * This software is in the public domain under CC0 1.0 Universal plus a 
 * Grant of Patent License.
 * 
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.mcp.test;

import groovy.json.JsonSlurper

/**
 * Catalog Screen Test for MCP
 * Tests that the catalog screen returns real rendered content
 */
class CatalogScreenTest {
    private McpJavaClient client
    private JsonSlurper jsonSlurper = new JsonSlurper()
    
    CatalogScreenTest(McpJavaClient client) {
        this.client = client
    }
    
    /**
     * Test catalog screen accessibility
     */
    boolean testCatalogScreenAccessibility() {
        println "\n🛍️ Testing Catalog Screen Accessibility"
        println "======================================"
        
        try {
            // Find the catalog screen tool - look for mantle ProductList screen
            def tools = client.getTools()
            def catalogTool = tools.find { 
                it.name?.contains("ProductList") ||
                it.name?.contains("ProductDetail") ||
                it.name?.contains("Search") ||
                it.description?.contains("ProductList") ||
                it.description?.contains("ProductDetail") ||
                it.description?.contains("Search")
            }
            
            if (!catalogTool) {
                client.recordStep("Find Catalog Tool", false, "No catalog screen tool found")
                return false
            }
            
            client.recordStep("Find Catalog Tool", true, "Found catalog tool: ${catalogTool.name}")
            
            // Test basic access
            def result = client.executeTool(catalogTool.name, [:])
            
            if (!result) {
                client.recordStep("Access Catalog Screen", false, "No response from catalog screen")
                return false
            }
            
            if (!result.content || result.content.size() == 0) {
                client.recordStep("Access Catalog Screen", false, "No content returned from catalog screen")
                return false
            }
            
            client.recordStep("Access Catalog Screen", true, "Catalog screen returned ${result.content.size()} content items")
            return true
            
        } catch (Exception e) {
            client.recordStep("Catalog Screen Accessibility", false, e.message)
            return false
        }
    }
    
    /**
     * Test catalog screen returns real HTML content with enhanced data validation
     */
    boolean testCatalogScreenRealContent() {
        println "\n🎨 Testing Catalog Screen Real Content"
        println "======================================"
        
        try {
            // Find the catalog screen tool
            def tools = client.getTools()
            def catalogTool = tools.find { 
                it.name?.contains("catalog") || 
                it.name?.contains("ProductList") ||
                it.name?.contains("Category") ||
                it.name?.contains("Search") ||
                it.description?.contains("catalog") ||
                it.description?.contains("ProductList") ||
                it.description?.contains("Category") ||
                it.description?.contains("Search")
            }
            
            if (!catalogTool) {
                client.recordStep("Find Catalog for Content", false, "No catalog screen tool found")
                return false
            }
            
            // Request HTML render mode for better content
            def params = [:]
            if (catalogTool.inputSchema?.properties?.renderMode) {
                params.renderMode = "html"
            }
            
            def result = client.executeTool(catalogTool.name, params)
            
            if (!result || !result.content || result.content.size() == 0) {
                client.recordStep("Get Catalog Content", false, "No content from catalog screen")
                return false
            }
            
            def content = result.content[0]
            def contentText = content.text ?: ""
            
            println "  📄 Content type: ${content.type}"
            println "  📏 Content length: ${contentText.length()} characters"
            
            if (contentText.length() == 0) {
                client.recordStep("Get Catalog Content", false, "Empty content returned")
                return false
            }
            
            // Enhanced validation patterns
            def validationResults = validateCatalogContent(contentText, catalogTool.name)
            
            println "  🏷️  Has HTML tags: ${validationResults.hasHtml}"
            println "  🏗️  Has HTML structure: ${validationResults.hasHtmlStructure}"
            println "  📦 Has product data: ${validationResults.hasProductData}"
            println "  🆔 Has product IDs: ${validationResults.hasProductIds}"
            println "  💰 Has pricing: ${validationResults.hasPricing}"
            println "  🔗 Has product links: ${validationResults.hasProductLinks}"
            println "  🛒 Has cart functionality: ${validationResults.hasCartFunctionality}"
            println "  📋 Has table structure: ${validationResults.hasTableStructure}"
            
            // Show first 500 characters for verification
            def preview = contentText.length() > 500 ? contentText.substring(0, 500) + "..." : contentText
            println "  👁️  Content preview:"
            println "     ${preview}"
            
            // Comprehensive validation with scoring
            def validationScore = calculateValidationScore(validationResults)
            def minimumScore = 0.6 // Require at least 60% of validation checks to pass
            
            println "  📊 Validation score: ${Math.round(validationScore * 100)}% (minimum: ${Math.round(minimumScore * 100)}%)"
            
            if (validationScore >= minimumScore && 
                !contentText.contains("is accessible at:") &&
                !contentText.contains("could not be rendered")) {
                
                client.recordStep("Get Catalog Content", true, 
                    "Real catalog content validated: ${contentText.length()} chars, score: ${Math.round(validationScore * 100)}%")
            } else {
                client.recordStep("Get Catalog Content", false, 
                    "Content validation failed: score ${Math.round(validationScore * 100)}%, below minimum ${Math.round(minimumScore * 100)}%")
                return false
            }
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Catalog Real Content", false, e.message)
            return false
        }
    }
    
    /**
     * Validate catalog content with comprehensive patterns
     */
    def validateCatalogContent(String contentText, String toolName) {
        def results = [:]
        
        // Basic HTML structure
        results.hasHtml = contentText.contains("<") && contentText.contains(">")
        results.hasHtmlStructure = contentText.contains("<html") || contentText.contains("<div") || contentText.contains("<table")
        
        // Product data indicators
        results.hasProductData = contentText.toLowerCase().contains("product") || 
                                 contentText.toLowerCase().contains("catalog") ||
                                 contentText.toLowerCase().contains("item")
        
        // Product ID patterns (Moqui typically uses alphanumeric IDs)
        results.hasProductIds = contentText =~ /\b[A-Z]{2,}\d{4,}\b/ || 
                                contentText =~ /productId["\s]*[=:]\s*["\']?[A-Z0-9]{6,}/
        
        // Price patterns
        results.hasPricing = contentText =~ /\$\d+\.\d{2}/ || 
                            contentText =~ /price.*\d+\.\d{2}/i ||
                            contentText =~ /USD\s*\d+\.\d{2}/
        
        // Product link patterns (PopCommerce specific)
        results.hasProductLinks = contentText =~ /\/popc\/Product\/Detail\/[^\/]+\/[^"'\s]+/ ||
                                  contentText =~ /Product\/Detail\/[^"'\s]+/
        
        // Cart functionality
        results.hasCartFunctionality = contentText =~ /Add\s+to\s+Cart/i ||
                                       contentText =~ /addToCart/i ||
                                       contentText =~ /quantity.*submit/i ||
                                       contentText =~ /cart/i
        
        // Table structure for product listings
        results.hasTableStructure = contentText =~ /<table[^>]*>.*?<\/table>/s ||
                                   contentText =~ /form-list.*CategoryProductList|SearchProductList/ ||
                                   contentText =~ /<tr[^>]*>.*?<td[^>]*>/s
        
        // Form elements for interaction
        results.hasFormElements = contentText =~ /<form[^>]*>/ ||
                                  contentText =~ /<input[^>]*>/ ||
                                  contentText =~ /<select[^>]*>/ ||
                                  contentText =~ /<button[^>]*>/ ||
                                  contentText =~ /submit/i
        
        // Search functionality (for search screens)
        results.hasSearchFunctionality = contentText =~ /search/i ||
                                        contentText =~ /keywords/i ||
                                        contentText =~ /category/i
        
        // Category information
        results.hasCategoryInfo = contentText =~ /category/i ||
                                contentText =~ /productCategoryId/i
        
        return results
    }
    
    /**
     * Calculate validation score based on weighted criteria
     */
    def calculateValidationScore(def validationResults) {
        def weights = [
            hasHtml: 0.1,
            hasHtmlStructure: 0.15,
            hasProductData: 0.1,
            hasProductIds: 0.2,
            hasPricing: 0.15,
            hasProductLinks: 0.1,
            hasCartFunctionality: 0.1,
            hasTableStructure: 0.1,
            hasFormElements: 0.05,
            hasSearchFunctionality: 0.02,
            hasCategoryInfo: 0.03
        ]
        
        def score = 0.0
        validationResults.each { key, value ->
            if (weights.containsKey(key)) {
                score += (value ? weights[key] : 0)
            }
        }
        
        return score
    }
    
    /**
     * Test catalog screen with parameters - enhanced validation
     */
    boolean testCatalogScreenWithParameters() {
        println "\n⚙️ Testing Catalog Screen with Parameters"
        println "=========================================="
        
        try {
            // Find all catalog-related tools for comprehensive testing
            def tools = client.getTools()
            def catalogTools = tools.findAll { 
                it.name?.contains("catalog") || 
                it.name?.contains("ProductList") ||
                it.name?.contains("Category") ||
                it.name?.contains("Search") ||
                it.description?.contains("catalog") ||
                it.description?.contains("ProductList") ||
                it.description?.contains("Category") ||
                it.description?.contains("Search")
            }
            
            if (catalogTools.isEmpty()) {
                client.recordStep("Find Catalog for Params", false, "No catalog screen tools found")
                return false
            }
            
            def parameterTestsPassed = 0
            def totalParameterTests = 0
            
            catalogTools.each { catalogTool ->
                println "  🎯 Testing parameters for: ${catalogTool.name}"
                
                // Test different parameter combinations based on tool type
                def parameterTestSets = getParameterTestSets(catalogTool)
                
                parameterTestSets.each { testSet ->
                    totalParameterTests++
                    def testName = testSet.name
                    def params = testSet.params
                    def expectedContent = testSet.expectedContent
                    
                    try {
                        println "    📋 Testing: ${testName}"
                        println "    📝 Parameters: ${params}"
                        
                        def result = client.executeTool(catalogTool.name, params)
                        
                        if (!result || !result.content || result.content.size() == 0) {
                            println "    ❌ No content returned"
                            client.recordStep("Parameter Test ${testName}", false, "No content with parameters: ${params}")
                            return
                        }
                        
                        def content = result.content[0]
                        def contentText = content.text ?: ""
                        
                        // Validate parameter effects
                        def validationResult = validateParameterEffects(contentText, expectedContent, testName)
                        
                        if (validationResult.passed) {
                            parameterTestsPassed++
                            println "    ✅ Passed: ${validationResult.message}"
                            client.recordStep("Parameter Test ${testName}", true, validationResult.message)
                        } else {
                            println "    ❌ Failed: ${validationResult.message}"
                            client.recordStep("Parameter Test ${testName}", false, validationResult.message)
                        }
                        
                    } catch (Exception e) {
                        println "    ❌ Error: ${e.message}"
                        client.recordStep("Parameter Test ${testName}", false, "Exception: ${e.message}")
                    }
                }
            }
            
            def successRate = totalParameterTests > 0 ? (parameterTestsPassed / totalParameterTests) : 0
            println "  📊 Parameter tests: ${parameterTestsPassed}/${totalParameterTests} passed (${Math.round(successRate * 100)}%)"
            
            if (successRate >= 0.5) { // At least 50% of parameter tests should pass
                client.recordStep("Catalog with Parameters", true, 
                    "Parameter testing successful: ${parameterTestsPassed}/${totalParameterTests} tests passed")
                return true
            } else {
                client.recordStep("Catalog with Parameters", false, 
                    "Parameter testing failed: only ${parameterTestsPassed}/${totalParameterTests} tests passed")
                return false
            }
            
        } catch (Exception e) {
            client.recordStep("Catalog Parameters", false, e.message)
            return false
        }
    }
    
    /**
     * Get parameter test sets based on tool type
     */
    def getParameterTestSets(def catalogTool) {
        def testSets = []
        
        // Common parameters
        def commonParams = [:]
        if (catalogTool.inputSchema?.properties?.renderMode) {
            commonParams.renderMode = "html"
        }
        
        // Tool-specific parameter tests
        if (catalogTool.name?.toLowerCase().contains("category")) {
            testSets.addAll([
                [
                    name: "Category with Electronics",
                    params: commonParams + [productCategoryId: "Electronics"],
                    expectedContent: [hasCategoryInfo: true, hasProductData: true]
                ],
                [
                    name: "Category with Books", 
                    params: commonParams + [productCategoryId: "Books"],
                    expectedContent: [hasCategoryInfo: true, hasProductData: true]
                ],
                [
                    name: "Category with NonExistent",
                    params: commonParams + [productCategoryId: "NONEXISTENT_CATEGORY"],
                    expectedContent: [hasEmptyMessage: true]
                ]
            ])
        } else if (catalogTool.name?.toLowerCase().contains("search")) {
            testSets.addAll([
                [
                    name: "Search for Demo",
                    params: commonParams + [keywords: "demo"],
                    expectedContent: [hasSearchResults: true, hasProductData: true]
                ],
                [
                    name: "Search for Product",
                    params: commonParams + [keywords: "product"],
                    expectedContent: [hasSearchResults: true, hasProductData: true]
                ],
                [
                    name: "Search with No Results",
                    params: commonParams + [keywords: "xyznonexistent123"],
                    expectedContent: [hasEmptyMessage: true]
                ]
            ])
        } else {
            // Generic catalog/ProductList tests
            testSets.addAll([
                [
                    name: "Basic HTML Render",
                    params: commonParams,
                    expectedContent: [hasHtmlStructure: true, hasProductData: true]
                ],
                [
                    name: "With Category Filter",
                    params: commonParams + [productCategoryId: "CATALOG"],
                    expectedContent: [hasCategoryInfo: true, hasProductData: true]
                ],
                [
                    name: "With Order By",
                    params: commonParams + [orderBy: "productName"],
                    expectedContent: [hasProductData: true, hasTableStructure: true]
                ]
            ])
        }
        
        return testSets
    }
    
    /**
     * Validate that parameters had the expected effect on content
     */
    def validateParameterEffects(String contentText, def expectedContent, String testName) {
        def result = [passed: false, message: ""]
        
        // Check for empty/no results message
        if (expectedContent.containsKey('hasEmptyMessage')) {
            def hasEmptyMessage = contentText.toLowerCase().contains("no products") ||
                                 contentText.toLowerCase().contains("no results") ||
                                 contentText.toLowerCase().contains("not found") ||
                                 contentText.toLowerCase().contains("empty") ||
                                 contentText.length() < 200
            
            if (expectedContent.hasEmptyMessage == hasEmptyMessage) {
                result.passed = true
                result.message = "Empty message validation passed"
            } else {
                result.message = "Expected empty message: ${expectedContent.hasEmptyMessage}, found: ${hasEmptyMessage}"
            }
            return result
        }
        
        // Check for search results
        if (expectedContent.containsKey('hasSearchResults')) {
            def hasSearchResults = contentText.toLowerCase().contains("result") ||
                                  contentText.toLowerCase().contains("found") ||
                                  (contentText.contains("product") && contentText.length() > 500)
            
            if (expectedContent.hasSearchResults == hasSearchResults) {
                result.passed = true
                result.message = "Search results validation passed"
            } else {
                result.message = "Expected search results: ${expectedContent.hasSearchResults}, found: ${hasSearchResults}"
            }
            return result
        }
        
        // Validate other content expectations
        def validationResults = validateCatalogContent(contentText, testName)
        def allExpectationsMet = true
        def failedExpectations = []
        
        expectedContent.each { key, expectedValue ->
            if (validationResults.containsKey(key)) {
                def actualValue = validationResults[key]
                if (expectedValue != actualValue) {
                    allExpectationsMet = false
                    failedExpectations.add("${key}: expected ${expectedValue}, got ${actualValue}")
                }
            }
        }
        
        if (allExpectationsMet && failedExpectations.isEmpty()) {
            result.passed = true
            result.message = "All content expectations met"
        } else {
            result.message = "Failed expectations: ${failedExpectations.join(', ')}"
        }
        
        return result
    }
    
    /**
     * Test multiple catalog screens if available
 */
    boolean testMultipleCatalogScreens() {
        println "\n📚 Testing Multiple Catalog Screens"
        println "===================================="
        
        try {
            def tools = client.getTools()
            
            // Find all catalog/product related screens
            def catalogTools = tools.findAll { 
                it.name?.contains("catalog") || 
                it.name?.contains("Product") ||
                it.name?.contains("product") ||
                it.description?.toLowerCase().contains("catalog") ||
                it.description?.toLowerCase().contains("product")
            }
            
            if (catalogTools.size() <= 1) {
                client.recordStep("Multiple Catalog Screens", true, 
                    "Found ${catalogTools.size()} catalog screen(s) - testing primary one")
                return true
            }
            
            println "  🔍 Found ${catalogTools.size()} catalog/product screens"
            
            def successfulScreens = 0
            catalogTools.take(3).each { tool ->
                try {
                    println "  🎨 Testing screen: ${tool.name}"
                    def result = client.executeTool(tool.name, [renderMode: "html"])
                    
                    if (result && result.content && result.content.size() > 0) {
                        def content = result.content[0]
                        def contentText = content.text ?: ""
                        
                        if (contentText.length() > 50) {
                            successfulScreens++
                            println "    ✅ Success: ${contentText.length()} chars"
                        } else {
                            println "    ⚠️ Short content: ${contentText.length()} chars"
                        }
                    } else {
                        println "    ❌ No content"
                    }
                    
                } catch (Exception e) {
                    println "    ❌ Error: ${e.message}"
                }
            }
            
            if (successfulScreens > 0) {
                client.recordStep("Multiple Catalog Screens", true, 
                    "${successfulScreens}/${Math.min(3, catalogTools.size())} screens rendered successfully")
            } else {
                client.recordStep("Multiple Catalog Screens", false, "No catalog screens rendered successfully")
                return false
            }
            
            return true
            
        } catch (Exception e) {
            client.recordStep("Multiple Catalog Screens", false, e.message)
            return false
        }
    }
    
    /**
     * Test known data validation - checks for expected demo data
     */
    boolean testKnownDataValidation() {
        println "\n🔍 Testing Known Data Validation"
        println "================================="
        
        try {
            def tools = client.getTools()
            def catalogTools = tools.findAll { 
                it.name?.contains("catalog") || 
                it.name?.contains("ProductList") ||
                it.name?.contains("Category") ||
                it.name?.contains("Search") ||
                it.description?.contains("catalog") ||
                it.description?.contains("ProductList") ||
                it.description?.contains("Category") ||
                it.description?.contains("Search")
            }
            
            if (catalogTools.isEmpty()) {
                client.recordStep("Known Data Validation", false, "No catalog tools found")
                return false
            }
            
            def knownDataTestsPassed = 0
            def totalKnownDataTests = 0
            
            catalogTools.take(2).each { catalogTool ->
                println "  🎯 Testing known data for: ${catalogTool.name}"
                
                // Test with known demo data patterns
                def knownDataTestSets = [
                    [
                        name: "Demo Product Patterns",
                        params: [renderMode: "html"],
                        expectedPatterns: [
                            ~/demo/i,
                            ~/sample/i,
                            ~/test/i
                        ]
                    ],
                    [
                        name: "Category Structure",
                        params: [renderMode: "html", productCategoryId: "CATALOG"],
                        expectedPatterns: [
                            ~/category/i,
                            ~/product/i,
                            ~/CATALOG/i
                        ]
                    ],
                    [
                        name: "Search Functionality",
                        params: [renderMode: "html", keywords: "demo"],
                        expectedPatterns: [
                            ~/demo/i,
                            ~/result/i,
                            ~/product/i
                        ]
                    ]
                ]
                
                knownDataTestSets.each { testSet ->
                    totalKnownDataTests++
                    
                    try {
                        println "    📋 Testing: ${testSet.name}"
                        
                        def result = client.executeTool(catalogTool.name, testSet.params)
                        
                        if (!result || !result.content || result.content.size() == 0) {
                            println "    ❌ No content returned"
                            client.recordStep("Known Data ${testSet.name}", false, "No content returned")
                            return
                        }
                        
                        def content = result.content[0]
                        def contentText = content.text ?: ""
                        
                        // Check for expected patterns
                        def patternsFound = 0
                        def totalPatterns = testSet.expectedPatterns.size()
                        
                        testSet.expectedPatterns.each { pattern ->
                            if (contentText =~ pattern) {
                                patternsFound++
                            }
                        }
                        
                        def patternMatchRate = totalPatterns > 0 ? (patternsFound / totalPatterns) : 0
                        println "    📊 Pattern matches: ${patternsFound}/${totalPatterns} (${Math.round(patternMatchRate * 100)}%)"
                        
                        if (patternMatchRate >= 0.3) { // At least 30% of patterns should match
                            knownDataTestsPassed++
                            println "    ✅ Passed: Found expected data patterns"
                            client.recordStep("Known Data ${testSet.name}", true, 
                                "Pattern matches: ${patternsFound}/${totalPatterns}")
                        } else {
                            println "    ❌ Failed: Too few pattern matches"
                            client.recordStep("Known Data ${testSet.name}", false, 
                                "Insufficient pattern matches: ${patternsFound}/${totalPatterns}")
                        }
                        
                    } catch (Exception e) {
                        println "    ❌ Error: ${e.message}"
                        client.recordStep("Known Data ${testSet.name}", false, "Exception: ${e.message}")
                    }
                }
            }
            
            def successRate = totalKnownDataTests > 0 ? (knownDataTestsPassed / totalKnownDataTests) : 0
            println "  📊 Known data tests: ${knownDataTestsPassed}/${totalKnownDataTests} passed (${Math.round(successRate * 100)}%)"
            
            if (successRate >= 0.4) { // At least 40% of known data tests should pass
                client.recordStep("Known Data Validation", true, 
                    "Known data validation successful: ${knownDataTestsPassed}/${totalKnownDataTests} tests passed")
                return true
            } else {
                client.recordStep("Known Data Validation", false, 
                    "Known data validation failed: only ${knownDataTestsPassed}/${totalKnownDataTests} tests passed")
                return false
            }
            
        } catch (Exception e) {
            client.recordStep("Known Data Validation", false, e.message)
            return false
        }
    }
    
    /**
     * Test negative scenarios and error handling
     */
    boolean testNegativeScenarios() {
        println "\n🚫 Testing Negative Scenarios"
        println "=============================="
        
        try {
            def tools = client.getTools()
            def catalogTools = tools.findAll { 
                it.name?.contains("catalog") || 
                it.name?.contains("ProductList") ||
                it.name?.contains("Category") ||
                it.name?.contains("Search") ||
                it.description?.contains("catalog") ||
                it.description?.contains("ProductList") ||
                it.description?.contains("Category") ||
                it.description?.contains("Search")
            }
            
            if (catalogTools.isEmpty()) {
                client.recordStep("Negative Scenarios", false, "No catalog tools found")
                return false
            }
            
            def negativeTestsPassed = 0
            def totalNegativeTests = 0
            
            catalogTools.take(2).each { catalogTool ->
                println "  🎯 Testing negative scenarios for: ${catalogTool.name}"
                
                def negativeTestSets = [
                    [
                        name: "Invalid Category ID",
                        params: [renderMode: "html", productCategoryId: "INVALID_CATEGORY_12345"],
                        expectedBehavior: "empty_or_error"
                    ],
                    [
                        name: "Non-existent Search Terms",
                        params: [renderMode: "html", keywords: "xyznonexistent123abc"],
                        expectedBehavior: "empty_or_error"
                    ],
                    [
                        name: "Empty Parameters",
                        params: [:],
                        expectedBehavior: "some_content"
                    ],
                    [
                        name: "Very Long Search String",
                        params: [renderMode: "html", keywords: "a" * 200],
                        expectedBehavior: "handled_gracefully"
                    ]
                ]
                
                negativeTestSets.each { testSet ->
                    totalNegativeTests++
                    
                    try {
                        println "    📋 Testing: ${testSet.name}"
                        
                        def result = client.executeTool(catalogTool.name, testSet.params)
                        
                        if (!result || !result.content || result.content.size() == 0) {
                            if (testSet.expectedBehavior == "empty_or_error") {
                                negativeTestsPassed++
                                println "    ✅ Passed: Correctly returned no content for invalid input"
                                client.recordStep("Negative ${testSet.name}", true, 
                                    "Correctly handled invalid input")
                            } else {
                                println "    ❌ Failed: Expected content but got none"
                                client.recordStep("Negative ${testSet.name}", false, 
                                    "Expected content but got none")
                            }
                            return
                        }
                        
                        def content = result.content[0]
                        def contentText = content.text ?: ""
                        
                        def validationResult = validateNegativeScenario(contentText, testSet)
                        
                        if (validationResult.passed) {
                            negativeTestsPassed++
                            println "    ✅ Passed: ${validationResult.message}"
                            client.recordStep("Negative ${testSet.name}", true, validationResult.message)
                        } else {
                            println "    ❌ Failed: ${validationResult.message}"
                            client.recordStep("Negative ${testSet.name}", false, validationResult.message)
                        }
                        
                    } catch (Exception e) {
                        if (testSet.expectedBehavior == "empty_or_error") {
                            negativeTestsPassed++
                            println "    ✅ Passed: Correctly threw exception for invalid input"
                            client.recordStep("Negative ${testSet.name}", true, 
                                "Correctly threw exception: ${e.message}")
                        } else {
                            println "    ❌ Failed: Unexpected exception"
                            client.recordStep("Negative ${testSet.name}", false, 
                                "Unexpected exception: ${e.message}")
                        }
                    }
                }
            }
            
            def successRate = totalNegativeTests > 0 ? (negativeTestsPassed / totalNegativeTests) : 0
            println "  📊 Negative tests: ${negativeTestsPassed}/${totalNegativeTests} passed (${Math.round(successRate * 100)}%)"
            
            if (successRate >= 0.5) { // At least 50% of negative tests should pass
                client.recordStep("Negative Scenarios", true, 
                    "Negative scenario testing successful: ${negativeTestsPassed}/${totalNegativeTests} tests passed")
                return true
            } else {
                client.recordStep("Negative Scenarios", false, 
                    "Negative scenario testing failed: only ${negativeTestsPassed}/${totalNegativeTests} tests passed")
                return false
            }
            
        } catch (Exception e) {
            client.recordStep("Negative Scenarios", false, e.message)
            return false
        }
    }
    
    /**
     * Validate negative scenario behavior
     */
    def validateNegativeScenario(String contentText, def testSet) {
        def result = [passed: false, message: ""]
        
        switch (testSet.expectedBehavior) {
            case "empty_or_error":
                def hasEmptyMessage = contentText.toLowerCase().contains("no products") ||
                                     contentText.toLowerCase().contains("no results") ||
                                     contentText.toLowerCase().contains("not found") ||
                                     contentText.toLowerCase().contains("empty") ||
                                     contentText.length() < 200
                
                if (hasEmptyMessage) {
                    result.passed = true
                    result.message = "Correctly showed empty/error message"
                } else {
                    result.message = "Expected empty/error message but got content"
                }
                break
                
            case "some_content":
                if (contentText.length() > 50) {
                    result.passed = true
                    result.message = "Provided some content as expected"
                } else {
                    result.message = "Expected some content but got very little"
                }
                break
                
            case "handled_gracefully":
                // Should not crash and should provide some response
                if (contentText.length() > 0) {
                    result.passed = true
                    result.message = "Handled gracefully without crashing"
                } else {
                    result.message = "No response provided"
                }
                break
                
            default:
                result.passed = false
                result.message = "Unknown expected behavior: ${testSet.expectedBehavior}"
        }
        
        return result
    }
    
    /**
     * Run all catalog screen tests
     */
    boolean runAllTests() {
        println "🧪 Running Catalog Screen Tests"
        println "================================"
        
        client.startWorkflow("Catalog Screen Tests")
        
        def results = [
            testCatalogScreenAccessibility(),
            testCatalogScreenRealContent(),
            testCatalogScreenWithParameters(),
            testKnownDataValidation(),
            testNegativeScenarios(),
            testMultipleCatalogScreens()
        ]
        
        def workflowResult = client.completeWorkflow()
        
        return workflowResult?.success ?: false
    }
    
    /**
     * Main method for standalone execution
     */
    static void main(String[] args) {
        def client = new McpJavaClient()
        def test = new CatalogScreenTest(client)
        
        try {
            if (!client.initialize()) {
                println "❌ Failed to initialize MCP client"
                return
            }
            
            def success = test.runAllTests()
            
            println "\n" + "="*60
            println "🏁 CATALOG SCREEN TEST COMPLETE"
            println "="*60
            println "Overall Result: ${success ? '✅ PASSED' : '❌ FAILED'}"
            println "="*60
            
        } finally {
            client.close()
        }
    }
}