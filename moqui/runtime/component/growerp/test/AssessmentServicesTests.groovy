/*
 * Assessment Services Integration Tests
 * Tests for assessment management, scoring, and submission
 * Covers dual-ID lookup, multi-tenant isolation, and error handling
 */

def ec = (ExecutionContext) context.get("executionContext")
def logger = org.slf4j.LoggerFactory.getLogger("AssessmentServicesTests")

// Test counters
int passed = 0
int failed = 0
List<String> failedTests = []

// Test 1: Create Assessment
logger.info("TEST 1: Create Assessment")
try {
    def result = ec.service.sync().name("growerp.assessment.createAssessment")
        .parameters([
            assessmentName: "Test Product Readiness",
            description: "Assessment to measure product readiness",
            status: "ACTIVE",
            ownerPartyId: "test_company_1"
        ]).call()
    
    if (result.assessmentId && result.pseudoId) {
        logger.info("✓ PASSED: Assessment created - ID: ${result.assessmentId}")
        passed++
        context.put("assessmentId", result.assessmentId)
        context.put("pseudoId", result.pseudoId)
    } else {
        logger.error("✗ FAILED: Assessment IDs not generated")
        failed++
        failedTests.add("Create Assessment")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Create Assessment")
}

// Test 2: Get Assessment by ID
logger.info("TEST 2: Get Assessment by ID")
try {
    def result = ec.service.sync().name("growerp.assessment.getAssessment")
        .parameters([
            idOrPseudo: context.get("assessmentId"),
            ownerPartyId: "test_company_1"
        ]).call()
    
    if (result.assessment?.assessmentName == "Test Product Readiness") {
        logger.info("✓ PASSED: Assessment retrieved by ID")
        passed++
    } else {
        logger.error("✗ FAILED: Assessment data mismatch")
        failed++
        failedTests.add("Get Assessment by ID")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Get Assessment by ID")
}

// Test 3: Get Assessment by PseudoId
logger.info("TEST 3: Get Assessment by PseudoId")
try {
    def result = ec.service.sync().name("growerp.assessment.getAssessment")
        .parameters([
            idOrPseudo: context.get("pseudoId"),
            ownerPartyId: "test_company_1"
        ]).call()
    
    if (result.assessment?.assessmentName == "Test Product Readiness") {
        logger.info("✓ PASSED: Assessment retrieved by pseudoId")
        passed++
    } else {
        logger.error("✗ FAILED: Assessment data mismatch")
        failed++
        failedTests.add("Get Assessment by PseudoId")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Get Assessment by PseudoId")
}

// Test 4: List Assessments
logger.info("TEST 4: List Assessments")
try {
    def result = ec.service.sync().name("growerp.assessment.listAssessments")
        .parameters([
            ownerPartyId: "test_company_1",
            pageNumber: 1,
            pageSize: 20
        ]).call()
    
    if (result.assessments && result.totalCount > 0) {
        logger.info("✓ PASSED: Listed ${result.totalCount} assessments")
        passed++
    } else {
        logger.error("✗ FAILED: No assessments found")
        failed++
        failedTests.add("List Assessments")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("List Assessments")
}

// Test 5: Update Assessment
logger.info("TEST 5: Update Assessment")
try {
    def updateResult = ec.service.sync().name("growerp.assessment.updateAssessment")
        .parameters([
            assessmentId: context.get("assessmentId"),
            assessmentName: "Updated Test Assessment",
            status: "INACTIVE",
            ownerPartyId: "test_company_1"
        ]).call()
    
    def getResult = ec.service.sync().name("growerp.assessment.getAssessment")
        .parameters([
            idOrPseudo: context.get("assessmentId"),
            ownerPartyId: "test_company_1"
        ]).call()
    
    if (getResult.assessment?.assessmentName == "Updated Test Assessment" && 
        getResult.assessment?.status == "INACTIVE") {
        logger.info("✓ PASSED: Assessment updated successfully")
        passed++
    } else {
        logger.error("✗ FAILED: Assessment not updated")
        failed++
        failedTests.add("Update Assessment")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Update Assessment")
}

// Test 6: Multi-Tenant Isolation
logger.info("TEST 6: Multi-Tenant Isolation")
try {
    // Create assessment for tenant 2
    def result = ec.service.sync().name("growerp.assessment.createAssessment")
        .parameters([
            assessmentName: "Tenant 2 Assessment",
            status: "ACTIVE",
            ownerPartyId: "test_company_2"
        ]).call()
    
    // List assessments for tenant 1
    def tenant1List = ec.service.sync().name("growerp.assessment.listAssessments")
        .parameters([ownerPartyId: "test_company_1"]).call()
    
    // List assessments for tenant 2
    def tenant2List = ec.service.sync().name("growerp.assessment.listAssessments")
        .parameters([ownerPartyId: "test_company_2"]).call()
    
    // Verify isolation
    boolean tenant1HasOnly1 = !tenant1List.assessments.any { it.assessmentName == "Tenant 2 Assessment" }
    boolean tenant2HasCorrect = tenant2List.assessments.any { it.assessmentName == "Tenant 2 Assessment" }
    
    if (tenant1HasOnly1 && tenant2HasCorrect) {
        logger.info("✓ PASSED: Multi-tenant isolation verified")
        passed++
    } else {
        logger.error("✗ FAILED: Tenant data leakage detected")
        failed++
        failedTests.add("Multi-Tenant Isolation")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Multi-Tenant Isolation")
}

// Test 7: Delete Assessment
logger.info("TEST 7: Delete Assessment")
try {
    // Create assessment to delete
    def createResult = ec.service.sync().name("growerp.assessment.createAssessment")
        .parameters([
            assessmentName: "Assessment to Delete",
            status: "ACTIVE",
            ownerPartyId: "test_company_1"
        ]).call()
    
    def assessmentIdToDelete = createResult.assessmentId
    
    // Delete it
    def deleteResult = ec.service.sync().name("growerp.assessment.deleteAssessment")
        .parameters([
            assessmentId: assessmentIdToDelete,
            ownerPartyId: "test_company_1"
        ]).call()
    
    if (deleteResult.deletedCount > 0) {
        logger.info("✓ PASSED: Assessment deleted (cascade: ${deleteResult.deletedCount} records)")
        passed++
    } else {
        logger.error("✗ FAILED: Assessment not deleted")
        failed++
        failedTests.add("Delete Assessment")
    }
} catch (Exception e) {
    logger.error("✗ FAILED: ${e.message}")
    failed++
    failedTests.add("Delete Assessment")
}

// Summary
logger.info("\n" + "="*60)
logger.info("TEST SUMMARY: ${passed} passed, ${failed} failed")
logger.info("="*60)

if (failed > 0) {
    logger.error("Failed tests: ${failedTests.join(', ')}")
}

// Return summary
context.put("testsPassed", passed)
context.put("testsFailed", failed)
context.put("failedTests", failedTests)
