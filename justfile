# Justfile (bash mode)
# Requirements: just, podman (not docker)
# Usage: just dev
set shell := ["bash", "-eo", "pipefail", "-c"]

# -----------------------------
# Config
# -----------------------------
project_name := "invoice"
nix_image := "ghcr.io/nixos/nix"
podman := "podman"
workspace       := "/workspace"
project_root    := justfile_directory()

# Nix flags kept explicit but centralized
nix_flags := "--extra-experimental-features nix-command --extra-experimental-features flakes"
nix_envs := "NIX_USER_CONF_FILES=/workspace/.nix-config"

_default: bootstrap
    @just --list

_has-nix := `command -v nix || true`

_has-nix-store := `podman volume inspect nix-store &>/dev/null && echo "yes" || echo ""`

_in-container := `[ -f /run/.containerenv ] && echo "yes" || echo ""`

[no-exit-message]
_not-in-container:
    @[ ! -f /run/.containerenv ] || { echo "leave container to run this"; exit 1; }

_need-nix-store:
    @[ -n "{{_has-nix-store}}" ] || exit 1

# Start here.
bootstrap:
    #!/usr/bin/env bash
    if [ -z "{{_has-nix-store}}" ]; then
        echo "Bootstrapping nix-store volume..."
        {{podman}} run --rm \
          -v nix-store:/nix \
          {{nix_image}} \
          cp -a /nix/. /nix/
        echo "nix-store volume ready."
    fi

# Load an image onto the host podman
_load-image target: _not-in-container _need-nix-store
    {{podman}} run --rm \
      -v {{project_root}}:{{workspace}}:z \
      -v nix-store:/nix \
      --userns keep-id:uid=0,gid=0 \
      -w {{workspace}} \
      {{nix_image}} \
      nix {{nix_flags}} run .#{{target}} | {{podman}} load -q

# Run a developpment image
_run-image image: _not-in-container _need-nix-store
    {{podman}} run --rm -it \
      -v {{project_root}}:{{workspace}}:z \
      -v nix-store:/nix \
      --userns keep-id:uid=0,gid=0 \
      -e SHELL \
      -w {{workspace}} \
      {{image}}

_nix +args:
    #!/usr/bin/env bash
    -set -eo pipefail
    if [ -n "$(command -v nix || true)" ]; then
        nix {{args}}
    else
        just _need-nix-store
        podman run --rm \
          -v {{project_root}}:{{workspace}}:z \
          -v nix-store:/nix \
          -e NIX_USER_CONF_FILES={{workspace}}/.nix-config \
          -w {{workspace}} \
          {{nix_image}} \
          nix {{args}}
    fi

_build +cmd:
    #!/usr/bin/env bash
    set -eo pipefail
    if [ -n "{{_in-container}}" ]; then
        eval {{cmd}}
    else
        {{podman}} run --rm \
          -v {{project_root}}:{{workspace}}:z \
          -v nix-store:/nix \
          --userns keep-id:uid=0,gid=0 \
          -w {{workspace}} \
          localhost/dev:latest \
          sh -c "{{cmd}}"
    fi

# Run bare nixOS within a container, mount workspace
naked-nix: _not-in-container _need-nix-store
    {{podman}} run -it --rm \
      -e="{{nix_envs}}" \
      -v {{project_root}}:{{workspace}}:z \
      -v nix-store:/nix \
      --userns keep-id:uid=0,gid=0 \
      -w {{workspace}} \
      {{nix_image}}
    
# Start a dev-shell in container
dev: _not-in-container bootstrap
   just devcontainer
   just run-dev

# Load devcontainer into podman
devcontainer: _not-in-container
   just _load-image dev-image

invoiceninja: _not-in-container
    just _load-image invoiceninja-image

mariadb: _not-in-container
    just _load-image mariadb-image
# === Running Containers ===

# Run prebuilt dev container interactively
run-dev:
   just _run-image localhost/{{project_name}}-dev:latest

# === Utilities ===
#

# update the nix image used for the dev container
update-base-image image tag: _need-nix-store
    #!/usr/bin/env bash
    output="containers/base-image-$(echo {{image}} | tr '/' '-')-{{tag}}.nix"
    {{podman}} run --rm \
      -v {{project_root}}:{{workspace}}:z \
      -v nix-store:/nix \
      -e NIX_USER_CONF_FILES={{workspace}}/.nix-config \
      -w {{workspace}} \
      {{nix_image}} \
      nix run nixpkgs#nix-prefetch-docker -- --image-name {{image}} --image-tag {{tag}} \
      | sed -n '/^{/,$ p' \
      > $output

# Show flake outputs
flake-show:
    just _nix "run flake show"

# Update flake.lock
update:
    just _nix "run flake update"

# Garbage collect old builds
gc:
    just _nix "run nikpkgs#nix --store gc"

# Format nix files (requires nixfmt)
fmt:
    just _nix "run nixpkgs#nixfmt -- **/*.nix"

# Demo: build pipeline pattern
# lowdown converts README.md → assets/index.html inside the dev container
build:
    mkdir -p {{project_root}}/assets
    just _build "lowdown -s -Thtml README.md -o assets/index.html"

# Download and unpack Invoice Ninja into invoiceninja/
get-invoiceninja version="5.13.1":
    #!/usr/bin/env bash
    set -euo pipefail
    url="https://github.com/invoiceninja/invoiceninja/releases/download/v{{version}}/invoiceninja.tar"
    mkdir -p {{project_root}}/invoiceninja
    curl -L "$url" | tar -xzf - -C {{project_root}}/invoiceninja

# Create the invoiceninja pod
pod-create: _not-in-container
    {{podman}} pod create \
      --name invoiceninja \
      -p 8080:8080

# Run MariaDB in the pod
run-mariadb: _not-in-container
    {{podman}} run -d \
      --pod invoiceninja \
      --name mariadb \
      -v {{project_root}}/data/mysql:/var/lib/mysql:z \
      -v {{project_root}}/data/mysql-tmp:/tmp:z \
      -v {{project_root}}/data/mysql-run:/run/mysqld:z \
      --env-file {{project_root}}/invoiceninja.env \
      localhost/{{project_name}}-mariadb:latest

# Run Invoice Ninja in the pod
run-invoiceninja: _not-in-container
    {{podman}} run -d \
      --pod invoiceninja \
      --name invoiceninja \
      -v {{project_root}}/invoiceninja:/var/www/invoiceninja:z \
      --env-file {{project_root}}/invoiceninja.env \
      localhost/invoiceninja:latest

# Start the whole thing
start: pod-create run-mariadb run-invoiceninja

# Tear it all down
stop: _not-in-container
    {{podman}} pod stop invoiceninja
    {{podman}} pod rm invoiceninja

# Generate APP_KEY and write it into invoiceninja.env
generate-appkey:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "export INVOICENINJA_APP_KEY=base64:$(openssl rand -base64 32)"

setup-dirs:
    mkdir -p {{project_root}}/data/mysql
    mkdir -p {{project_root}}/data/mysql-tmp
    mkdir -p {{project_root}}/data/mysql-run
