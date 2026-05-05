export const SITE = {
  name: 'Stephen Lloyd',
  email: 'stephen@lloyd.dev',
  github: 'https://github.com/',
  rss: '/rss.xml',
  hero: {
    line1: 'I love solving things —',
    line2: 'in code, and in the slow work of becoming.',
    blurb:
      "Engineer in Austin. This is a logbook of what I'm building, what I'm reading, and the faith that keeps me at the desk. Filed by kind and lens — pick a thread, or read it all together.",
  },
  nav: [
    { href: '/', label: 'writing', current: true },
    { href: '/projects', label: 'projects' },
    { href: '/bookshelf', label: 'bookshelf' },
    { href: '/about', label: 'about' },
    { href: '/contact', label: 'contact' },
  ],
  now: {
    title: "Now · spring '26",
    items: [
      'Rewriting a query planner at $work',
      'Leading a small group on the Sermon on the Mount',
      'Learning to play the upright bass, badly',
      'Walking 6am with the dog, most days',
    ],
  },
  reading: [
    { title: 'The Cost of Discipleship', author: 'Dietrich Bonhoeffer', kind: 'faith' },
    { title: 'Designing Data-Intensive Applications', author: 'Martin Kleppmann', kind: 'tech' },
    { title: 'Gilead', author: 'Marilynne Robinson', kind: 'fiction' },
  ],
};
