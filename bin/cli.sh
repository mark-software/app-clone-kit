#!/bin/bash

# CLI entry point for npx app-clone-kit
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
        echo "    npx app-clone-kit init            Install into current project"
        echo "    npx app-clone-kit init --global    Install /clone command globally"
        echo ""
        echo "  After install:"
        echo "    claude"
        echo "    > /clone <app name>"
        echo ""
        ;;
    *)
        echo "  Unknown command: $1"
        echo "  Run 'npx app-clone-kit help' for usage."
        exit 1
        ;;
esac
