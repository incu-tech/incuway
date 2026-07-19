export interface Contact {
  id: string;
  name: string;
  email: string;
}

export function listVisibleContacts(_userId: string): Contact[] {
  return [];
}

export function exportContactsCsv(userId: string): string {
  const rows = listVisibleContacts(userId).map((c) => `${c.id},${c.name},${c.email}`);
  return ["id,name,email", ...rows].join("\n");
}
