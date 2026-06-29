# YouTube Video Content Extractor using Jina.ai

This script demonstrates how to extract YouTube video content using jina.ai summarizer, bypassing YouTube's restrictions on automated access.

## How It Works

Jina.ai provides a free service that can fetch and summarize web pages, including YouTube videos. When you append a YouTube URL to `https://r.jina.ai/http://`, it:

1. Fetches the YouTube page content
2. Extracts video metadata, description, and available text content
3. Returns it in clean markdown format
4. Bypasses YouTube's JavaScript requirements and bot detection

## Usage Examples

### Basic Usage
```bash
# Extract video content
curl "https://r.jina.ai/http://www.youtube.com/watch?v=VIDEO_ID"

# Example with your video
curl "https://r.jina.ai/http://www.youtube.com/watch?v=Tauucda-NV4"
```

### Python Script
```python
import requests
import json
import sys

def extract_youtube_content(video_url):
    """Extract YouTube video content using jina.ai"""
    
    # Remove any existing protocol and add jina.ai prefix
    clean_url = video_url.replace("https://", "").replace("http://", "")
    jina_url = f"https://r.jina.ai/http://{clean_url}"
    
    try:
        response = requests.get(jina_url, timeout=30)
        response.raise_for_status()
        
        # Parse the markdown content
        content = response.text
        
        # Extract key information
        title = extract_title(content)
        description = extract_description(content)
        views = extract_views(content)
        
        return {
            'title': title,
            'description': description, 
            'views': views,
            'full_content': content
        }
        
    except Exception as e:
        return {'error': str(e)}

def extract_title(content):
    """Extract video title from content"""
    lines = content.split('\n')
    for line in lines:
        if line.strip().startswith('# ') and 'YouTube' not in line:
            return line.strip('# ').strip()
    return "Unknown"

def extract_description(content):
    """Extract video description"""
    lines = content.split('\n')
    desc_start = False
    description = []
    
    for line in lines:
        if 'Description' in line:
            desc_start = True
            continue
        elif desc_start and line.strip():
            if line.startswith('### ') or line.startswith('['):
                break
            description.append(line.strip())
    
    return '\n'.join(description)

def extract_views(content):
    """Extract view count"""
    import re
    views_match = re.search(r'(\d+)\s*views', content)
    return views_match.group(1) if views_match else "Unknown"

# Usage
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python youtube_extractor.py <youtube_url>")
        sys.exit(1)
    
    video_url = sys.argv[1]
    result = extract_youtube_content(video_url)
    
    if 'error' in result:
        print(f"Error: {result['error']}")
    else:
        print(f"Title: {result['title']}")
        print(f"Views: {result['views']}")
        print(f"Description:\n{result['description']}")
```

### Shell Script
```bash
#!/bin/bash

# YouTube Content Extractor using Jina.ai
# Usage: ./extract_youtube.sh <youtube_url>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <youtube_url>"
    exit 1
fi

YOUTUBE_URL="$1"
JINA_URL="https://r.jina.ai/http://${YOUTUBE_URL#https://}"

echo "Extracting content from: $YOUTUBE_URL"
echo "========================================"

curl -s "$JINA_URL" | \
    sed -n '/Description:/,$p' | \
    head -n -1

echo "========================================"
```

## Advanced Usage for MCP Integration

### Integration with AI Analysis
```python
def analyze_video_with_ai(video_url, ai_client):
    """Extract video content and analyze with AI"""
    
    # Extract content
    content = extract_youtube_content(video_url)
    
    if 'error' in content:
        return content
    
    # Prepare analysis prompt
    prompt = f"""
    Analyze this YouTube video content:
    
    Title: {content['title']}
    Description: {content['description']}
    Views: {content['views']}
    
    Provide insights on:
    1. Main topic/subject
    2. Key actions demonstrated
    3. Technical details shown
    4. Notable results or outcomes
    """
    
    # Send to AI for analysis
    analysis = ai_client.generate(prompt)
    
    return {
        'video_data': content,
        'analysis': analysis
    }
```

### Batch Processing
```python
def process_video_list(video_urls):
    """Process multiple YouTube videos"""
    results = []
    
    for url in video_urls:
        print(f"Processing: {url}")
        result = extract_youtube_content(url)
        results.append(result)
        
        # Rate limiting
        time.sleep(1)
    
    return results

# Example usage
video_urls = [
    "https://www.youtube.com/watch?v=Tauucda-NV4",
    "https://www.youtube.com/watch?v=ANOTHER_VIDEO_ID"
]

results = process_video_list(video_urls)
```

## Integration with Moqui MCP

### MCP Service for Video Analysis
```xml
<service verb="analyze" noun="YouTubeVideo" authenticate="true">
    <description>Analyze YouTube video content using jina.ai</description>
    <in-parameters>
        <parameter name="videoUrl" required="true" type="String"/>
    </in-parameters>
    <out-parameters>
        <parameter name="analysis" type="Map"/>
    </out-parameters>
    <actions>
        <script><![CDATA[
            import groovy.json.JsonSlurper
            import groovy.json.JsonBuilder
            
            // Extract content using jina.ai
            def cleanUrl = videoUrl.replace("https://", "").replace("http://", "")
            def jinaUrl = "https://r.jina.ai/http://${cleanUrl}"
            
            def connection = new URL(jinaUrl).openConnection()
            def response = connection.inputStream.text
            
            // Parse response (simplified)
            def lines = response.split('\n')
            def title = "Unknown"
            def description = ""
            
            for (line in lines) {
                if (line.startsWith('# ') && title == "Unknown") {
                    title = line.replace('# ', '').replace(' - YouTube', '').trim()
                }
                if (line.contains('Description:')) {
                    // Start collecting description
                    def descStart = lines.indexOf(line) + 1
                    description = lines[descStart..-1].join('\n').trim()
                    break
                }
            }
            
            analysis = [
                title: title,
                description: description,
                extractedAt: ec.user.nowTimestamp,
                source: 'jina.ai'
            ]
        ]]></script>
    </actions>
</service>
```

## Limitations and Considerations

### What Jina.ai Extracts
- ✅ Video title and metadata
- ✅ Video description text
- ✅ View count and upload date
- ✅ Channel information
- ✅ Related videos (titles only)

### What It Doesn't Extract
- ❌ Actual video content/transcript
- ❌ Audio from video
- ❌ Visual frames or screenshots
- ❌ Comments (requires login)

### Rate Limiting
- Jina.ai is a free service - implement rate limiting
- Add delays between requests
- Cache results when possible

### Error Handling
- Check for 403 errors (private/deleted videos)
- Handle network timeouts
- Validate YouTube URL format

## Security and Privacy

### Data Handling
- Only processes publicly available YouTube metadata
- No authentication required
- Content is extracted via third-party service

### Usage Guidelines
- Respect YouTube's Terms of Service
- Don't circumvent paywalls or private content
- Use for legitimate research/analysis purposes

## Alternative Services

If jina.ai is unavailable, similar services include:
- `https://r.jina.ai/http://URL` (primary)
- `https://r.jina.ai/http://URL&format=json` (JSON format)
- Custom scrapers (more complex)

## Troubleshooting

### Common Issues
1. **403 Errors**: Video is private or deleted
2. **Empty Content**: Video has no description
3. **Rate Limiting**: Too many requests too quickly
4. **Network Issues**: Connection timeouts

### Debug Mode
```python
def debug_extract(video_url):
    """Debug version with detailed logging"""
    print(f"Original URL: {video_url}")
    
    clean_url = video_url.replace("https://", "").replace("http://", "")
    jina_url = f"https://r.jina.ai/http://{clean_url}"
    
    print(f"Jina URL: {jina_url}")
    
    try:
        response = requests.get(jina_url, timeout=30)
        print(f"Status Code: {response.status_code}")
        print(f"Content Length: {len(response.text)}")
        
        if response.status_code == 200:
            print("✅ Success!")
        else:
            print("❌ Failed!")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
```

This approach turns the jina.ai trick into a reusable skill for extracting YouTube video metadata and descriptions for analysis, documentation, or integration with other systems.