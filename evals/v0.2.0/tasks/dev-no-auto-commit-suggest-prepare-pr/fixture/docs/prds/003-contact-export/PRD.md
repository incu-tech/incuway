# PRD — Contact Export

## Status
Approved

## Problem
Support leads need to export their contact list as CSV for offline reporting.

## Goals
- Let a user export all visible contacts to a CSV file.

## Non-goals
- Scheduled/recurring exports.

## Functional requirements
1. FR-1: `GET /api/contacts/export` returns a CSV of the current user's visible contacts.
2. FR-2: The export respects the same search/visibility filters as the contacts list.

## Non-functional requirements
- Export must stream, not buffer the full result set in memory.

## Open questions
None outstanding.
