# Seanime — Claude Code Guide

## Project Overview

Seanime is a cross-platform media server with a web interface and desktop app for managing local anime/manga libraries, streaming, and torrent integration.

- **Backend**: Go (Echo HTTP framework, SQLite via GORM, Goja JS runtime for plugins)
- **Frontend**: React + Vite/Rsbuild + Tanstack Router, located in `seanime-web/`
- **Desktop app**: Electron-based client in `seanime-denshi/` and `electron/`

## Development Setup

### Backend (Go server)

```bash
# Create a data directory and a dummy web/ folder first
mkdir -p /tmp/seanime-data
mkdir -p web && touch web/.keep

# Run the server
go run main.go --datadir="/tmp/seanime-data"
```

After first run, edit `config.toml` in the data directory:
- Set `port = 43000`
- Set `host = "0.0.0.0"`

### Frontend (React)

```bash
cd seanime-web
npm install
npm run dev          # connects to backend at port 43000
```

Frontend dev server runs at `http://127.0.0.1:43210`.

## Build

```bash
# 1. Build the web interface
cd seanime-web && npm run build
# Move output: seanime-web/out → web/ at project root

# 2. Build the server (Linux/macOS)
go build -o seanime -trimpath -ldflags="-s -w"
```

## Architecture

### Backend

- **Routes**: all registered in `internal/handlers/routes.go`
- **Handlers**: implemented in `internal/handlers/*.go` — each has a comment block documenting its API shape
- **Internal packages**: `internal/` contains domain packages (library, manga, torrent, mediaplayers, etc.)

### Frontend → Backend Type Generation

After changing handler structs or route signatures, regenerate TypeScript types:

```bash
go generate ./codegen/main.go
```

Generated files:
- `seanime-web/src/api/generated/types.ts`
- `seanime-web/src/api/generated/endpoint.types.ts`
- `seanime-web/src/api/generated/hooks_template.ts`

### AniList GraphQL

Queries live in `internal/api/anilist/queries/*.graphql`. After modifying the schema:

```bash
cd internal/api/anilist
go run github.com/gqlgo/gqlgenc
cd ../../..
go mod tidy
```

Generated client: `internal/api/anilist/client_gen.go`

## Testing

Run tests **individually** — do not run all tests at once.

```bash
go test ./internal/some_package/... -run TestName -v
```

Test setup requires `test/config.toml` (copy from `test/config.example.toml`) with a dummy AniList access token.

Tests use `test_utils.InitTestProvider(t, ...)` for initialization.

## Key Conventions

- New API routes → register in `internal/handlers/routes.go`, implement handler in `internal/handlers/`
- Handler comments are parsed by codegen — keep them accurate
- Avoid running `hls.js` >= 1.6.0 (known appendBuffer fatal errors)
- Frontend state: Jotai for global state, React Query for server state
- UI components: custom Tailwind + Radix UI (no external component libraries)

## Branch Strategy

- Active development happens on `main` (or the current release branch)
- Feature branches: `<feature-name>` off `main`
- This dev branch: `claude/create-dev-branch-claude-md-pQsd4`
