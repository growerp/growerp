# Assessment REST Endpoints - Moqui Service Definition

## Overview
Assessment REST endpoints have been added to `growerp.rest.xml` following GrowERP conventions and patterns.

## API Endpoint Structure

### Base Path
All assessment endpoints are available at: `/rest/s1/growerp/100/Assessment`

### Endpoints

#### Assessment Management
```
GET     /rest/s1/growerp/100/Assessment           - Get assessments (list/search)
POST    /rest/s1/growerp/100/Assessment           - Create new assessment
PATCH   /rest/s1/growerp/100/Assessment           - Update assessment
DELETE  /rest/s1/growerp/100/Assessment           - Delete assessment
```

#### Assessment Questions (nested under Assessment ID)
```
GET     /rest/s1/growerp/100/Assessment/{assessmentId}/Question           - List questions
POST    /rest/s1/growerp/100/Assessment/{assessmentId}/Question           - Create question
PATCH   /rest/s1/growerp/100/Assessment/{assessmentId}/Question           - Update question
DELETE  /rest/s1/growerp/100/Assessment/{assessmentId}/Question           - Delete question
```

#### Question Options (nested under Assessment ID and Question ID)
```
GET     /rest/s1/growerp/100/Assessment/{assessmentId}/Question/{questionId}/Option      - List options
POST    /rest/s1/growerp/100/Assessment/{assessmentId}/Question/{questionId}/Option      - Create option
PATCH   /rest/s1/growerp/100/Assessment/{assessmentId}/Question/{questionId}/Option      - Update option
DELETE  /rest/s1/growerp/100/Assessment/{assessmentId}/Question/{questionId}/Option      - Delete option
```

#### Scoring Thresholds
```
GET     /rest/s1/growerp/100/Assessment/{assessmentId}/Threshold      - Get thresholds
PATCH   /rest/s1/growerp/100/Assessment/{assessmentId}/Threshold      - Update thresholds
```

#### Score Calculation
```
POST    /rest/s1/growerp/100/Assessment/{assessmentId}/CalculateScore  - Calculate score
```

#### Assessment Results
```
GET     /rest/s1/growerp/100/Assessment/{assessmentId}/Result      - List results
POST    /rest/s1/growerp/100/Assessment/{assessmentId}/Result      - Create result
DELETE  /rest/s1/growerp/100/Assessment/{assessmentId}/Result      - Delete result
```

## Service Mappings

All endpoints map to services in the `AssessmentServices100` class:

- `get#Assessment` - GET assessment(s)
- `create#Assessment` - POST new assessment
- `update#Assessment` - PATCH assessment
- `delete#Assessment` - DELETE assessment
- `get#Question` - GET question(s)
- `create#Question` - POST new question
- `update#Question` - PATCH question
- `delete#Question` - DELETE question
- `get#Option` - GET option(s)
- `create#Option` - POST new option
- `update#Option` - PATCH option
- `delete#Option` - DELETE option
- `get#Threshold` - GET threshold(s)
- `update#Threshold` - PATCH threshold
- `calculate#Score` - POST score calculation
- `get#Result` - GET result(s)
- `create#Result` - POST new result
- `delete#Result` - DELETE result

## Service Definition (XML)

The endpoints are defined in `/moqui/runtime/component/growerp/service/growerp.rest.xml`:

```xml
<!-- assessment -->
<resource name="Assessment">
    <method type="get">
        <service name="growerp.100.AssessmentServices100.get#Assessment" />
    </method>
    <method type="post">
        <service name="growerp.100.AssessmentServices100.create#Assessment" />
    </method>
    <method type="patch">
        <service name="growerp.100.AssessmentServices100.update#Assessment" />
    </method>
    <method type="delete">
        <service name="growerp.100.AssessmentServices100.delete#Assessment" />
    </method>
    <id name="assessmentId">
        <resource name="Question">
            <method type="get">
                <service name="growerp.100.AssessmentServices100.get#Question" />
            </method>
            <method type="post">
                <service name="growerp.100.AssessmentServices100.create#Question" />
            </method>
            <method type="patch">
                <service name="growerp.100.AssessmentServices100.update#Question" />
            </method>
            <method type="delete">
                <service name="growerp.100.AssessmentServices100.delete#Question" />
            </method>
            <id name="questionId">
                <resource name="Option">
                    <method type="get">
                        <service name="growerp.100.AssessmentServices100.get#Option" />
                    </method>
                    <method type="post">
                        <service name="growerp.100.AssessmentServices100.create#Option" />
                    </method>
                    <method type="patch">
                        <service name="growerp.100.AssessmentServices100.update#Option" />
                    </method>
                    <method type="delete">
                        <service name="growerp.100.AssessmentServices100.delete#Option" />
                    </method>
                </resource>
            </id>
        </resource>
        <resource name="Threshold">
            <method type="get">
                <service name="growerp.100.AssessmentServices100.get#Threshold" />
            </method>
            <method type="patch">
                <service name="growerp.100.AssessmentServices100.update#Threshold" />
            </method>
        </resource>
        <resource name="CalculateScore">
            <method type="post">
                <service name="growerp.100.AssessmentServices100.calculate#Score" />
            </method>
        </resource>
        <resource name="Result">
            <method type="get">
                <service name="growerp.100.AssessmentServices100.get#Result" />
            </method>
            <method type="post">
                <service name="growerp.100.AssessmentServices100.create#Result" />
            </method>
            <method type="delete">
                <service name="growerp.100.AssessmentServices100.delete#Result" />
            </method>
        </resource>
    </id>
</resource>
```

## Integration with Flutter Client

These endpoints are called from the Flutter assessment package's API client:
- File: `flutter/packages/growerp_assessment/lib/src/api/assessment_api_client.dart`
- Client: `AssessmentApiClient` (Retrofit-based)

The Retrofit client automatically generates correct HTTP calls based on the API endpoint paths and HTTP method decorators (@GET, @POST, @PATCH, @DELETE).

## Notes

1. **Nested Resources**: The Assessment resource uses nested IDs to create hierarchical endpoints (Assessment → Question → Option)
2. **Service Pattern**: Following GrowERP conventions with service class names like `AssessmentServices100`
3. **HTTP Methods**: Standard REST methods used (GET, POST, PATCH, DELETE)
4. **Authentication**: Assessment endpoints require standard GrowERP authentication via JWT

## Related Files

- Frontend API Client: `flutter/packages/growerp_assessment/lib/src/api/assessment_api_client.dart`
- Backend Service Implementation: `moqui/runtime/component/growerp/service/AssessmentServices.xml` (to be created)
- Data Models: `flutter/packages/growerp_assessment/lib/src/models/`
- Repository Layer: `flutter/packages/growerp_assessment/lib/src/repository/assessment_repository.dart`
