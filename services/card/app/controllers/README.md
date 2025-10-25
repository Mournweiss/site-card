# Controllers Module Documentation

## Overview
This module dispatches all application and admin requests, enforces security and proper separation of business logic (SRP/OCP/SOLID), and integrates with models, views, and session/auth subsystems.

### Structure
- application_controller.rb:
    - SiteCardServlet: Main controller, handles all public (non-admin) endpoints. Instantiates AdminController for /admin routing. Entry for GET/POST.
- admin_controller.rb:
    - AdminController: Handles all admin UI endpoints, authentication, session logic, privilege checks, and admin API calls (by section). Invoked only for /admin* routes. No user-mode or public logic inside. **Now implements:**
        - GET /admin/ — renders login layout (admin.html)
        - POST /admin/ — key validation (timing-safe, never stores key in session/cookie; secure logging)
        - GET /admin/panel — only with valid session cookie, renders panel
        - POST /admin/logout — session/cookie reset
        - Session & token: httpOnly, in-memory only, expiring; never exposes ADMIN_KEY to client
        - UI-injection: panel loads via components/admin_panel.html, layouts from layouts/admin.html/application.html
        - NEW: GET /admin/api/{section} — returns JSON for current section (about, ...), only for admin session
        - NEW: POST /admin/api/update — takes full sections JSON, applies changes with strict parameterization, logs all changes, errors and partials per-section.

### Routing Entrypoints
- All GET/POST requests dispatch into SiteCardServlet. /admin* paths are delegated to AdminController.

### API Security
- All admin API endpoints work only with active admin session (server token).
- Payload is strictly JSON, all updates parameterized, input validated.
- Centrally logged with AppLogger.

All changes must be reflected here; annotate every major method or responsibility change inline.
