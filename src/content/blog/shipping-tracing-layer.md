---
title: Shipping a tracing layer at $work
date: 2026-03-09
draft: false
slug: shipping-tracing-layer
tags: [devlog, tech]
description: What I learned about flame graphs and humility, in that order.
---

Tracing is one of those things you put off until you cannot. We had finally arrived at "cannot." A handful of customer reports about "slow saves," nothing reproducible locally, and the kind of dashboard that tells you everything is fine, exactly when it is not.

So: a tracing layer. OpenTelemetry SDK, vendor of choice, two weeks of plumbing.

## What flame graphs taught me

The first week of tracing data is humbling in a specific way. You are confronted with the difference between the system you *thought* you had built and the system you actually run.

In our case, a single seemingly-trivial validation hook was running thirteen times per save under certain shapes of input. The code was correct. The orchestration around it was not. The fix was four lines.

> If you have not measured it, you have not built it. You have built something *near* it.

The flame graph showed, in a way no amount of unit tests could, the *shape* of a request. And the shape of a request is — I am increasingly convinced — the most useful thing to know about a system.

## Humility, briefly

I had been carrying around a mental model of this code path for two years. It was wrong in small but consistent ways. There is no instrument as sharpening as a span tree.
