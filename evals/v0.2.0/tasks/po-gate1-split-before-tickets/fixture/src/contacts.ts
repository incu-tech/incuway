export interface Contact {
  id: string;
  name: string;
  email: string;
  tags: string[];
}

const contacts: Contact[] = [];

export function listContacts(): Contact[] {
  return contacts;
}

export function searchContacts(query: string): Contact[] {
  const q = query.toLowerCase();
  return contacts.filter(
    (c) => c.name.toLowerCase().includes(q) || c.email.toLowerCase().includes(q)
  );
}

export function tagContact(id: string, tag: string): void {
  const contact = contacts.find((c) => c.id === id);
  if (contact && !contact.tags.includes(tag)) {
    contact.tags.push(tag);
  }
}
