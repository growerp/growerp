# Docker Build with Flutter Admin Integration

## Overview
The Moqui Dockerfile now builds and deploys the Flutter Admin web application during the Docker image build process.

## Build Process

### Stage 1: Build Environment Setup

#### 1. Install Flutter SDK
```dockerfile
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
    tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt && \
    rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
```

#### 2. Pre-download Flutter Artifacts
```dockerfile
RUN flutter config --no-analytics && \
    flutter precache --web && \
    dart pub global activate melos
```

#### 3. Copy Source Code
```dockerfile
COPY . /root/growerp/moqui
COPY ../flutter /root/growerp/flutter
```

#### 4. Build Flutter Admin App
```dockerfile
WORKDIR /root/growerp/flutter
RUN melos clean && \
    melos bootstrap && \
    melos l10n --no-select && \
    melos build --no-select

WORKDIR /root/growerp/flutter/packages/admin
RUN flutter build web --release
```

#### 5. Deploy to Moqui Runtime
```dockerfile
COPY deploy-flutter-admin.sh /tmp/deploy-flutter-admin.sh
RUN chmod +x /tmp/deploy-flutter-admin.sh && \
    /tmp/deploy-flutter-admin.sh
```

## Deployment Script (`deploy-flutter-admin.sh`)

The deployment script performs these actions:

1. **Verify Flutter Build**
   - Checks that `build/web` directory exists
   - Verifies `flutter_service_worker.js` is present

2. **Copy Files**
   ```bash
   cp -r "$FLUTTER_BUILD_DIR"/* "$MOQUI_ADMIN_DIR/"
   ```

3. **Fix Base Href**
   ```bash
   sed -i 's|<base href="/">|<base href="/admin/">|g' "$MOQUI_ADMIN_DIR/index.html"
   ```

4. **Remove Duplicate Service Worker Registration**
   ```bash
   perl -i -0pe 's/<script>\s*if \(.serviceWorker. in navigator\).*?<\/script>\s*//gs' "$MOQUI_ADMIN_DIR/index.html"
   ```

5. **Add Explanatory Comments**
   ```bash
   sed -i 's|<script src="flutter_bootstrap.js" async></script>|...|g' "$MOQUI_ADMIN_DIR/index.html"
   ```

6. **Create admin.xml Screen**
   - Creates Moqui screen definition for `/admin/` path

7. **Verify Deployment**
   - Checks all critical files are in place

## Directory Structure in Docker Image

```
/opt/moqui/runtime/component/PopRestStore/
├── screen/
│   └── store/
│       ├── admin.xml                    ← Moqui screen definition
│       └── admin/
│           ├── index.html               ← Entry point (base href="/admin/")
│           ├── flutter_service_worker.js ← Service worker
│           ├── main.dart.js             ← Flutter app (~7.6 MB)
│           ├── flutter_bootstrap.js      ← Bootstrap loader
│           ├── flutter.js
│           ├── manifest.json
│           ├── version.json
│           ├── assets/                  ← App assets
│           ├── canvaskit/               ← CanvasKit runtime
│           └── icons/                   ← App icons
└── template/
    └── store/
        └── root.html.ftl                ← Registers service worker
```

## Building the Docker Image

### From Project Root
```bash
cd /home/hans/growerp
docker build -f moqui/Dockerfile \
  --build-arg DOCKER_TAG=1.9.0 \
  --build-arg PAT=<your_github_pat> \
  -t growerp/moqui:1.9.0 \
  .
```

### Build Arguments
- `DOCKER_TAG`: Version tag (default: NOTSET1)
- `BRANCH`: Git branch (default: development)
- `PAT`: GitHub Personal Access Token for private repos

### Expected Build Output
```
========================================
Deploying Flutter Admin to Moqui Runtime
========================================
Creating admin directory...
Copying Flutter web files...
Fixing base href to /admin/...
Removing service worker registration from index.html...
Creating admin.xml screen...

Verifying deployment...
✓ flutter_service_worker.js
✓ main.dart.js (7.6M)
✓ index.html
✓ admin.xml screen

========================================
✓ Flutter Admin deployed successfully!
========================================
Files accessible at: /admin/
Service worker: /admin/flutter_service_worker.js
```

## Running the Docker Container

### Basic Run
```bash
docker run -d \
  -p 8080:80 \
  --name growerp-moqui \
  growerp/moqui:1.9.0
```

### With Volumes (Recommended)
```bash
docker run -d \
  -p 8080:80 \
  -v moqui-db:/opt/moqui/runtime/db \
  -v moqui-log:/opt/moqui/runtime/log \
  --name growerp-moqui \
  growerp/moqui:1.9.0
```

### Access Points
- Store: `http://localhost:8080/`
- Admin: `http://localhost:8080/admin/`
- API: `http://localhost:8080/rest/`

## Service Worker Architecture in Docker

### Registration Flow
1. User visits `http://localhost:8080/` (store)
2. `root.html.ftl` loads and registers `/admin/flutter_service_worker.js`
3. Service worker installs with scope `/admin/`
4. User clicks "Admin" link
5. Moqui serves `/admin/` → `admin.xml` → `admin/index.html`
6. Flutter bootstrap finds already-registered service worker
7. App loads from cache (second visit)

### Why This Works
- Service worker registered **early** (when browsing store)
- Service worker **activated** before user clicks Admin
- Flutter finds **ready** service worker (no timeout)
- Assets served from **cache** (fast load)

## Troubleshooting

### Build Fails: Flutter Not Found
**Problem:** `flutter: command not found`

**Solution:** Ensure Flutter SDK is installed in Dockerfile:
```dockerfile
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
```

### Build Fails: Melos Not Found
**Problem:** `melos: command not found`

**Solution:** Activate melos globally:
```dockerfile
RUN dart pub global activate melos
ENV PATH="${PATH}:/root/.pub-cache/bin"
```

### Build Fails: Flutter Build Error
**Problem:** `flutter build web` fails

**Check:**
1. Melos bootstrap ran successfully
2. Dependencies resolved
3. L10n generated
4. Build runner completed

**Fix:**
```dockerfile
RUN melos clean && \
    melos bootstrap && \
    melos l10n --no-select && \
    melos build --no-select
```

### Deployment Verification Failed
**Problem:** `deploy-flutter-admin.sh` exits with error

**Check:**
```bash
# Inside container
ls -la /opt/moqui/runtime/component/PopRestStore/screen/store/admin/
```

**Expected Files:**
- flutter_service_worker.js (12-13 KB)
- main.dart.js (7-8 MB)
- index.html (2-3 KB)
- flutter_bootstrap.js (4-5 KB)

### Admin Page 404
**Problem:** `/admin/` returns 404

**Check:**
1. admin.xml exists:
   ```bash
   ls /opt/moqui/runtime/component/PopRestStore/screen/store/admin.xml
   ```

2. index.html exists:
   ```bash
   ls /opt/moqui/runtime/component/PopRestStore/screen/store/admin/index.html
   ```

**Fix:** Rebuild image with deployment script

### Service Worker Not Caching
**Problem:** main.dart.js always loads from network

**Check:**
1. root.html.ftl has service worker registration
2. Service worker scope is `/admin/`
3. No duplicate registration in index.html

**Verify in Browser:**
- DevTools → Application → Service Workers
- Should show: `activated and is running`
- Scope: `http://localhost:8080/admin/`

## Image Size Optimization

### Current Layers
```
openjdk:11-jdk (base)
  ├─ Flutter SDK (~800 MB)
  ├─ Moqui WAR (~100 MB)
  ├─ Moqui Runtime (~500 MB)
  └─ Flutter Admin (~10 MB)
Total: ~1.5 GB
```

### Optimization Ideas (Future)
1. **Multi-stage Build**: Use separate Flutter build stage
2. **Alpine Base**: Switch to alpine-based images
3. **Layer Caching**: Optimize layer order
4. **Clean Artifacts**: Remove build dependencies in final image

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Build Moqui with Flutter Admin

on:
  push:
    branches: [master, development]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker Image
        run: |
          docker build -f moqui/Dockerfile \
            --build-arg DOCKER_TAG=${GITHUB_SHA::7} \
            --build-arg PAT=${{ secrets.GITHUB_TOKEN }} \
            -t growerp/moqui:${GITHUB_SHA::7} \
            .
      
      - name: Push to Registry
        run: |
          docker push growerp/moqui:${GITHUB_SHA::7}
```

## Monitoring & Health Checks

### Health Check
```dockerfile
HEALTHCHECK --interval=30s --timeout=600ms --start-period=120s \
  CMD curl -f http://localhost/status || exit 1
```

### Admin App Health
Test admin app availability:
```bash
curl -I http://localhost:8080/admin/
# Should return: 200 OK
```

### Service Worker Health
```bash
curl -I http://localhost:8080/admin/flutter_service_worker.js
# Should return: 200 OK
```

## Version Management

### Tagging Convention
```bash
docker build -t growerp/moqui:1.9.0 .      # Specific version
docker tag growerp/moqui:1.9.0 growerp/moqui:latest
docker push growerp/moqui:1.9.0
docker push growerp/moqui:latest
```

### Version in Flutter App
```dockerfile
WORKDIR /root/growerp/flutter/packages/admin
RUN sed -i 's/version: .*/version: '"${DOCKER_TAG}"'/' pubspec.yaml
```

## References
- [Moqui Framework](https://www.moqui.org/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
