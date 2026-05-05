export const KIND_TAGS = ['essay', 'devlog', 'note', 'reflection'] as const;
export const LENS_TAGS = ['tech', 'faith', 'reading'] as const;

export type Kind = (typeof KIND_TAGS)[number];
export type Lens = (typeof LENS_TAGS)[number];

export function classify(tags: string[] | undefined) {
  const ts = tags ?? [];
  const kind = (ts.find((t) => (KIND_TAGS as readonly string[]).includes(t)) ?? 'note') as Kind;
  const lenses = ts.filter((t) => (LENS_TAGS as readonly string[]).includes(t)) as Lens[];
  return { kind, lenses };
}

export function readingTime(body: string | undefined): number {
  if (!body) return 1;
  const words = body.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 220));
}

export function formatDate(d: Date): string {
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(d.getUTCDate()).padStart(2, '0');
  return `${yyyy}.${mm}.${dd}`;
}
