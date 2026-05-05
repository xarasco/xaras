---
title: On Patience & Garbage Collection
date: 2026-04-28
draft: false
slug: on-patience-and-garbage-collection
tags: [essay, faith, tech]
description: Waiting on a long-running query taught me what Augustine meant by restless hearts.
---

The query had been running for forty minutes when I opened my Bible. I don't usually do this — flip pages while a process bar drifts forward — but the office was quiet and the cursor was blinking and I had read every other tab twice.

*Psalm 130. Out of the depths I cry to thee, O Lord; Lord, hear my voice.* The psalmist, it seems, also knew what it was to wait.

## The garbage collector

A long-running query is a small thing to be patient about. Most of the people I admire have waited for harder things — a child to come home, a diagnosis to lift, a calling to clarify. But the small impatiences are the ones I notice in myself. Forty minutes against an empty afternoon and I am a man with a stopwatch in his soul.

The runtime, meanwhile, is doing something I should respect: it is sweeping memory. Holding the heap still while it walks the graph of what is reachable, marking the live cells, freeing the rest. *Mark and sweep.* It is, if you will indulge me, an examination of conscience.

> What is reachable from here? What is still alive?

## Restless hearts

Augustine has a line every Christian writer eventually quotes: *fecisti nos ad te, et inquietum est cor nostrum, donec requiescat in te.* You have made us for yourself, and our hearts are restless until they rest in you.

I have been thinking about that word *requiescat.* It is the same root as *requiescat in pace* — rest in peace. Augustine is not asking for a hammock. He is asking for the kind of stillness that lets a heart stop running queries against itself.

The bar finishes. The result set lands. I close the Bible, mark the result for review, and notice that I am no longer in a hurry.
