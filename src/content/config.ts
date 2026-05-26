import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/[^_]*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    draft: z.boolean().default(true),
    tags: z.array(z.string()).optional(),
    description: z.string().optional(),
  }),
});

const projects = defineCollection({
  loader: glob({ pattern: '**/[^_]*.md', base: './src/content/projects' }),
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    status: z.enum(['active', 'shipped', 'archived']).default('active'),
    description: z.string().optional(),
    url: z.string().url().optional(),
    repo: z.string().url().optional(),
    links: z
      .array(z.object({ label: z.string(), url: z.string().url() }))
      .optional(),
    tags: z.array(z.string()).optional(),
    draft: z.boolean().default(false),
  }),
});

const bookshelf = defineCollection({
  loader: glob({ pattern: '**/[^_]*.md', base: './src/content/bookshelf' }),
  schema: z.object({
    title: z.string(),
    author: z.string(),
    kind: z.string().default('book'),
    status: z.enum(['reading', 'stalled', 'finished', 'want-to-read']).default('reading'),
    started: z.coerce.date().optional(),
    finished: z.coerce.date().optional(),
    rating: z.number().int().min(1).max(5).optional(),
    url: z.string().url().optional(),
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog, projects, bookshelf };
