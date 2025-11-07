# GrowERP Release Workflow

## Philosophy

The release process follows a **repository-first** approach to ensure consistency and reproducibility:

1. **Clone** current repository to temp directory (`/tmp/growerp`)
2. **Update** versions in temp workspace
3. **Commit & Tag** changes, push to GitHub
4. **Build** Docker images from repository (not local files)
5. **Push** Docker images to Docker Hub

## Why This Approach?

✅ **Consistency**: Docker images are always built from the exact code in the repository
✅ **Traceability**: Git tags match Docker image versions
✅ **Reproducibility**: Anyone can rebuild the exact same image from the tagged commit
✅ **Clean State**: Fresh clone ensures no local artifacts or uncommitted changes

## Workflow Steps

### Step 1: Version Updates (in `/tmp/growerp`)
- Calculate new version based on user input (patch/minor/major)
- Update `pubspec.yaml` files for Flutter apps
- Update `component.xml` for growerp-moqui

### Step 2: Git Operations
- Commit all version changes
- Create git tag (e.g., `1.9.1`)
- Push commit and tag to GitHub
- Wait 3 seconds for GitHub to process

### Step 3: Docker Builds
- Build each selected app's Docker image
  - **growerp-moqui**: Dockerfile clones from GitHub in build stage
  - **Flutter apps**: Dockerfile clones from GitHub in build stage
- Tag images with version number
- Push to Docker Hub (if selected)

## Key Changes from Previous Workflow

### Before (Problematic)
- Build Docker images from local files
- Local changes might not be in repository
- Images could differ from tagged code

### Now (Correct)
- Always build from repository
- Git tag → GitHub push → Docker build from GitHub
- Images match tagged commits exactly

## Usage

```bash
cd /home/hans/growerp/flutter
./release.sh
```

Follow the prompts:
1. Select applications to release
2. Choose version increment (patch/minor/major)
3. Confirm push to Docker Hub (auto-pushes to GitHub)
4. Review summary and confirm

## Docker Build Details

### growerp-moqui Dockerfile
- **Stage 1 (build-flutter)**: Clones repo, builds Flutter web apps
- **Stage 2 (build-env)**: Copies from stage 1, builds Moqui WAR
- **Stage 3 (final)**: Runtime image with compiled artifacts

### Flutter App Dockerfiles
- Clone repository
- Build Flutter web with `--wasm`
- Deploy to nginx

All Dockerfiles use `ARG BRANCH=master` to control which branch is cloned.

## Troubleshooting

**Issue**: Docker image has old code
**Solution**: Verify git push succeeded before Docker build (check GitHub)

**Issue**: Build fails with "branch not found"
**Solution**: Ensure changes are pushed and tag exists on GitHub

**Issue**: Version mismatch between tag and image
**Solution**: Release workflow now enforces matching - versions are committed before building

## Related Files

- `/home/hans/growerp/flutter/release.sh` - Main release script
- `/home/hans/growerp/flutter/release/release_tool.dart` - Release automation
- `/home/hans/growerp/moqui/Dockerfile` - Backend Docker build
- `/home/hans/growerp/flutter/packages/*/Dockerfile` - Frontend Docker builds
