---
title: A small Lisp, in a quiet week
date: 2026-04-14
draft: false
slug: a-small-lisp
tags: [devlog, tech]
description: Forty-eight hours, two hundred lines, a renewed affection for parentheses.
---

I had two days off and one stale itch: I wanted to *write* a Lisp instead of read another tutorial about one. Not a serious one. Not one that competes with the half-dozen excellent small Lisps already on GitHub. A bonsai Lisp. A Sunday Lisp.

```clojure
(defn fact [n]
  (if (<= n 1) 1
    (* n (fact (- n 1)))))
```

By Sunday night I had a tokenizer, a recursive descent parser, an eval loop, and a tiny standard library. About two hundred lines of TypeScript, a handful of ugly tests, and a notebook of notes I will not show anyone.

## Why this still feels good

I have been writing software professionally for ten years. Most days the work is shaped by other people's decisions: a framework's, a team's, an org's. The pleasure of a small Lisp is that for a weekend you decide everything. Whitespace? You decide. Tail calls? You decide. Whether `nil` is falsy? You decide.

That is not a serious case for production code. It is, however, a serious case for spending an occasional weekend writing something with no users. The shape of one's taste needs exercise too.
