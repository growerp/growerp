#!/bin/bash
# GrowERP GCE Release Machine
#
# Manages a Google Compute Engine VM dedicated to running production releases.
# Key benefit over a local machine: persistent Docker layer cache on an SSD
# disk, Google-backbone network to Docker Hub, and more CPU/RAM for parallel
# Docker builds — drastically cutting release time for repeat runs.
#
# Prerequisites: gcloud CLI authenticated and project set.
#
# Usage:
#   ./release/gce-setup.sh create          # one-time: provision VM
#   ./release/gce-setup.sh setup           # one-time: install deps on VM
#   ./release/gce-setup.sh release [args]  # run release tool on the VM
#   ./release/gce-setup.sh ssh             # interactive SSH session
#   ./release/gce-setup.sh stop            # stop (keep disk / cache intact)
#   ./release/gce-setup.sh start           # restart a stopped VM
#   ./release/gce-setup.sh delete          # permanently destroy VM + disk
#
# Environment overrides (all optional):
#   GCE_PROJECT       GCP project ID  (default: current gcloud project)
#   GCE_INSTANCE      instance name   (default: growerp-release)
#   GCE_ZONE          zone            (default: us-central1-a)
#   GCE_MACHINE_TYPE  machine type    (default: n2-standard-4 = 4 vCPU / 16 GB)
#   GCE_DISK_SIZE     boot disk GiB   (default: 100)
#   REPO_URL          git clone URL   (default: https://github.com/growerp/growerp.git)
#   REPO_BRANCH       branch          (default: master)

set -euo pipefail

PROJECT="${GCE_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
INSTANCE="${GCE_INSTANCE:-growerp-release}"
ZONE="${GCE_ZONE:-us-central1-a}"
MACHINE="${GCE_MACHINE_TYPE:-n2-standard-4}"
DISK_SIZE="${GCE_DISK_SIZE:-100}"
REPO_URL="${REPO_URL:-https://github.com/growerp/growerp.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"

_ssh() {
  gcloud compute ssh "$INSTANCE" --zone="$ZONE" --project="$PROJECT" \
    --command="$1"
}

_ssh_interactive() {
  gcloud compute ssh "$INSTANCE" --zone="$ZONE" --project="$PROJECT"
}

create() {
  echo "Creating GCE instance: $INSTANCE ($MACHINE, ${DISK_SIZE}GB SSD)"
  gcloud compute instances create "$INSTANCE" \
    --project="$PROJECT" \
    --zone="$ZONE" \
    --machine-type="$MACHINE" \
    --boot-disk-size="${DISK_SIZE}GB" \
    --boot-disk-type=pd-ssd \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --scopes=cloud-platform
  echo ""
  echo "Instance created. Run:  $0 setup"
}

setup() {
  echo "Installing Docker and Dart on $INSTANCE…"

  _ssh '
    set -e

    # Docker
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"

    # Dart SDK (stable)
    sudo wget -qO /usr/share/keyrings/dart.gpg \
      https://dl-ssl.google.com/linux/linux_signing_key.pub
    echo "deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] \
      https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" \
      | sudo tee /etc/apt/sources.list.d/dart_stable.list
    sudo apt-get update -q
    sudo apt-get install -y dart git

    # dcli
    dart pub global activate dcli

    echo "Setup complete."
  '

  echo ""
  echo "Cloning repository on $INSTANCE…"
  _ssh "
    git clone --depth=1 -b $REPO_BRANCH $REPO_URL ~/growerp || \
      (cd ~/growerp && git fetch --depth=1 && git reset --hard origin/$REPO_BRANCH)
  "

  echo ""
  echo "Done. Run:  $0 release"
}

release() {
  local extra_args="${*:-}"
  echo "Running release on $INSTANCE…"

  _ssh "
    set -e
    export PATH=\"\$HOME/.pub-cache/bin:\$PATH\"
    cd ~/growerp/flutter
    git fetch --depth=1 origin $REPO_BRANCH
    git reset --hard origin/$REPO_BRANCH
    dart release/release_tool.dart $extra_args
  "
}

ssh_session() {
  _ssh_interactive
}

stop() {
  echo "Stopping $INSTANCE (disk and Docker cache preserved)…"
  gcloud compute instances stop "$INSTANCE" --zone="$ZONE" --project="$PROJECT"
}

start() {
  echo "Starting $INSTANCE…"
  gcloud compute instances start "$INSTANCE" --zone="$ZONE" --project="$PROJECT"
}

delete() {
  echo "WARNING: This will permanently delete $INSTANCE and all its data."
  read -rp "Type the instance name to confirm: " confirm
  if [[ "$confirm" != "$INSTANCE" ]]; then
    echo "Aborted."
    exit 1
  fi
  gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --project="$PROJECT"
}

usage() {
  cat <<EOF
GrowERP GCE Release Machine

Commands:
  create          Provision a new GCE VM
  setup           Install Docker/Dart and clone the repo (run once after create)
  release [args]  Run release tool on the VM (args are passed to release_tool.dart)
  ssh             Open an interactive SSH session
  stop            Stop the VM (preserves Docker cache on disk)
  start           Start a previously stopped VM
  delete          Permanently delete the VM

Examples:
  $0 create
  $0 setup
  $0 release                              # interactive release
  $0 release --ci --bump=patch --parallel # non-interactive CI-style
  $0 stop                                 # pause billing, keep cache
  $0 start && $0 release                  # resume for next release

Environment variables (all optional):
  GCE_PROJECT     GCP project ID
  GCE_INSTANCE    instance name   (default: growerp-release)
  GCE_ZONE        zone            (default: us-central1-a)
  GCE_MACHINE_TYPE                (default: n2-standard-4)
  GCE_DISK_SIZE   boot disk GiB   (default: 100)
  REPO_URL        git clone URL
  REPO_BRANCH     branch          (default: master)
EOF
}

case "${1:-help}" in
  create)  create ;;
  setup)   setup ;;
  release) shift; release "$@" ;;
  ssh)     ssh_session ;;
  stop)    stop ;;
  start)   start ;;
  delete)  delete ;;
  *)       usage ;;
esac
