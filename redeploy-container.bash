#!/bin/bash
# Purpose: This script is to purge the previous jenkins "test" image and container from the build node (ocibuilder.lab.x.x in this case) so that we can guarantee we've pulled and started the latest revision of the image from docker.io
# The order of the podman rmi's matters here since we're sourcing nginx originally rebuilding it and tagging it twice (once to local podman registry then pushing to docker.io)

if [ "$(whoami)" != "podman-builder" ]; then
  echo "Not podman-builder user...exiting"
  exit 1
else
  # Cleanup old build
  podman stop test
  podman rm test
  podman rmi docker.io/library/nginx
  podman rmi localhost/my-nginx
  podman rmi docker.io/jsanderson104/stuff:my-nginx
  
  # Run latest release..
  podman run -dt --name test -p 9090:9090 docker.io/jsanderson104/stuff:my-nginx
  fi
  
