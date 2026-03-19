#!/bin/bash

# CLI entry point for app-clone-kit
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    init)
        shift
        exec "$SCRIPT_DIR/install.sh" "$@"
        ;;
    help|--help|-h|"")
        echo ""
        echo "  app-clone-kit - Clone any app with AI automation"
        echo ""
        echo "  Usage:"
        echo "    curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash"
        echo "    curl -fsSL ... | bash -s -- --global    Install commands globally"
        echo ""
        echo "  After install:"
        echo "    claude"
        echo "    > /research-app-01 <app name>"
        echo "    > /build-app-locally-02"
        echo "    > /connect-backend-03  (optional)"
        echo ""
        ;;
    *)
        echo "  Unknown command: $1"
        echo "  Run './bin/cli.sh help' for usage."
        exit 1
        ;;
esac
