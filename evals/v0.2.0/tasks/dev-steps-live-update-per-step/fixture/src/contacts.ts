export interface Contact {
  id: string;
  ownerId: string;
  name: string;
  email: string;
}

const contacts: Contact[] = [];

export function listContactsForUser(ownerId: string): Contact[] {
  return contacts.filter((c) => c.ownerId === ownerId);
}
