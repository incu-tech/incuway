// Step A1 (done): tracks each CSV export a user runs, for audit purposes.
export const up = `
CREATE TABLE export_log (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  requested_at TEXT NOT NULL
);
`;

export const down = `DROP TABLE export_log;`;
