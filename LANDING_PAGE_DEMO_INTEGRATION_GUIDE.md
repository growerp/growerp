# Landing Page Demo Data Integration Guide

This guide explains how to integrate comprehensive landing page demo data into the GrowERP system's demo data loading process.

## Overview

The demo data creates realistic, professional landing pages that showcase the full capabilities of the GrowERP landing page system. This includes:

- **Multiple Landing Page Variations**: Business assessment, tech startup, e-commerce variations
- **Complete Content Structure**: Headlines, subheadings, value propositions, credibility sections
- **Visual Elements**: Placeholder images for sections and creator photos
- **Call-to-Action Configurations**: Compelling CTAs with time estimates and value promises
- **Credibility Components**: Expert bios, background text, and supporting statistics

## Files Created

### 1. `demo_landing_page_data.xml`
- **Purpose**: Complete XML data file with all landing page entities
- **Content**: 3 landing page variations with full content structure
- **Usage**: Can be loaded separately or integrated into existing demo data loading

### 2. `landing_page_demo_integration.xml`
- **Purpose**: Integration snippet for PartyServices100.xml
- **Content**: Simplified demo data creation using entity-create actions
- **Usage**: Add directly to the existing demo data loading service

## Integration Method 1: Direct XML Loading

### Step 1: Place Demo Data File
```bash
# Copy the demo data file to the appropriate location
cp demo_landing_page_data.xml moqui/runtime/component/growerp/data/LandingPageDemoData.xml
```

### Step 2: Update Component Configuration
Add the data file to the component's data loading configuration in:
`moqui/runtime/component/growerp/component.xml`

```xml
<load-data>
    <entity-facade-xml filename="data/LandingPageDemoData.xml"/>
</load-data>
```

### Step 3: Load Demo Data
```bash
cd moqui
java -jar moqui.war load types=demo
```

## Integration Method 2: PartyServices100.xml Integration (Recommended)

This method integrates landing page creation into the existing demo data loading service, ensuring landing pages are created alongside other demo data.

### Step 1: Locate Demo Data Service
Open `moqui/runtime/component/growerp/service/growerp/100/PartyServices100.xml` and find the `load#demo` service (around line 3600).

### Step 2: Add Landing Page Demo Code
Insert the content from `landing_page_demo_integration.xml` after the activities section and before the closing `</while>` tag:

```xml
<!-- Add after activities section -->
<set field="index" from="index + 1" />
</iterate>

<!-- INSERT LANDING PAGE DEMO CODE HERE -->
<if condition="!disableContentLoad">
    <log level="info" message="Creating landing page demo data..."/>
    <!-- ... rest of landing page demo code ... -->
</if>

</while> <!-- Existing closing tag -->
```

### Step 3: Test Integration
```bash
cd moqui
./gradlew cleandb
java -jar moqui.war load types=seed,seed-initial,install,demo no-run-es
```

## Demo Data Structure

### Landing Pages Created

1. **Main Business Assessment** (`business-assessment-demo`)
   - Hook Type: Problem-focused
   - Target: General business optimization
   - Sections: 3 value proposition sections
   - CTA: "Start Your Free Assessment"

2. **Tech Startup Growth** (`tech-startup-growth`)
   - Hook Type: Results-focused
   - Target: Tech startups and MVPs
   - Sections: Product-market fit and scaling systems
   - CTA: "Get My Startup Growth Plan"

3. **E-commerce Optimization** (`ecommerce-optimization`)
   - Hook Type: Frustration-focused
   - Target: E-commerce businesses
   - Sections: Conversion optimization and customer retention
   - CTA: "Find My Profit Leaks"

### Content Components

Each landing page includes:
- **Page Configuration**: Title, headline, subheading, hook type, status
- **Value Proposition Sections**: 2-3 sections with titles, descriptions, images
- **Credibility Information**: Expert bio, background text, creator image
- **Supporting Statistics**: 2-3 credibility statistics per page
- **Primary CTA**: Button text, estimated time, cost, value promise

### Image Placeholders

All images use placeholder.com URLs with:
- **Color-coded placeholders**: Different colors for different page types
- **Descriptive text**: Clear indication of image purpose
- **Consistent dimensions**: 500x300 for sections, 150x150 for profiles
- **No external dependencies**: Works without internet connection

## Verification

After loading demo data, verify the landing pages are created:

### 1. Check Database Records
```sql
-- Count landing pages
SELECT COUNT(*) FROM growerp.landing.LandingPage WHERE ownerPartyId = 'DEMO';

-- Count sections
SELECT COUNT(*) FROM growerp.landing.PageSection p 
JOIN growerp.landing.LandingPage l ON p.pageId = l.pageId 
WHERE l.ownerPartyId = 'DEMO';

-- Count credibility info
SELECT COUNT(*) FROM growerp.landing.CredibilityInfo c
JOIN growerp.landing.LandingPage l ON c.pageId = l.pageId 
WHERE l.ownerPartyId = 'DEMO';
```

### 2. Test API Access
```bash
# Test landing page retrieval
curl -X GET "http://localhost:8080/rest/s1/growerp/LandingPage/demo-business-assessment"

# Test via pseudoId
curl -X GET "http://localhost:8080/rest/s1/growerp/LandingPage/pseudo_business-assessment-demo"
```

### 3. Frontend Integration
The demo landing pages should be accessible via the landing page app:
- URL: `http://localhost:3000/business-assessment-demo`
- Should display complete page with all sections and CTAs

## Customization

To customize the demo data:

### 1. Modify Content
Edit the text content in the demo data files:
- Headlines and subheadings
- Value proposition descriptions
- Credibility information
- Statistics and credentials

### 2. Update Images
Replace placeholder URLs with actual images:
- Use publicly accessible image URLs
- Ensure proper XML encoding for query parameters
- Maintain consistent dimensions

### 3. Add More Variations
Create additional landing page variations by:
- Adding new landing page entities
- Creating corresponding sections and CTAs
- Following the existing naming conventions

## Troubleshooting

### Common Issues

1. **XML Parsing Errors**
   - Ensure all URLs are properly XML-encoded
   - Check for unescaped ampersands (&) in URLs
   - Validate XML structure

2. **Missing Dependencies**
   - Verify landing page entities exist in the database schema
   - Check that LandingPageServices100.xml is properly loaded
   - Ensure REST endpoints are configured

3. **Demo Data Not Loading**
   - Check ownerPartyId exists (should be 'DEMO')
   - Verify demo data loading is enabled
   - Check server logs for errors during data loading

### Debug Queries

```sql
-- Check if landing pages were created
SELECT pageId, pseudoId, title, status FROM growerp.landing.LandingPage;

-- Check sections for a specific page
SELECT sectionId, sectionTitle, sectionSequence 
FROM growerp.landing.PageSection 
WHERE pageId = 'demo-business-assessment'
ORDER BY sectionSequence;

-- Check credibility info
SELECT credibilityId, creatorBio, backgroundText 
FROM growerp.landing.CredibilityInfo;
```

## Next Steps

After successfully integrating the demo data:

1. **Test Frontend Integration**: Verify landing pages display correctly in the Flutter app
2. **Customize Content**: Adapt the demo content to your specific use case
3. **Add More Variations**: Create additional landing page templates
4. **Configure Assessment Integration**: Link landing pages to actual assessment flows
5. **Set Up Analytics**: Configure tracking for landing page performance

The demo data provides a solid foundation for showcasing the landing page system's capabilities and can be easily customized for specific business needs.