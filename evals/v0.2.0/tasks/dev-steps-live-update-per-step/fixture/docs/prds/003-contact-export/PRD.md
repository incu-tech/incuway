# PRD — Contact export (003-contact-export)

## Status
Approved (Gate 1)

## Problem
Support leads want to export the contacts they manage as CSV for offline reporting. There is no
export path today.

## Goals
- Add a schema migration so exports can be tracked per user.
- Expose an authenticated API endpoint that returns a CSV export.
- Add an "Export CSV" button + modal in the contacts UI.

## Non-goals
- Scheduled/recurring exports.
- Export formats other than CSV.
