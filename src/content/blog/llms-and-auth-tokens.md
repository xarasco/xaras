---
title: LLMs and Auth Tokens
date: 2026-05-25
draft: false
slug: llms-and-auth-tokens
tags: [ai, work]
description: just, why..
---
# (not) putting PATs in llm messages

llms are great at noticing when you put security sensitive stuff into a chat.  

```sh
curl -sS -X POST http://127.0.0.1:8080/mcp/ \
  -H "Authorization: Bearer wlp_myrealtokenthatshouldntbehere" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"wala-prod-smoke","version":"0.1.0"}}}'
```

they respond with something like..

> I see you are a dummy and stupidly pasted in an important secret.  Go change all secrets now.

it doesn't matter if that is just on your local server, the llm is zealous for good security practices.  don't paste your secrets where they don't belong

but if you put a placeholder in, the models are dumb.  pattern detection skills make them great at evaluating if a token looks correct or not... "your access token doesn't conform to xyz pattern", but why do that if they will just reject your use of the token at all.  

```sh
curl -sS -X POST http://127.0.0.1:8080/mcp/ \
  -H "Authorization: Bearer PAT" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"wala-prod-smoke","version":"0.1.0"}}}'
```

> this guy pasted in a token.  he shouldn't have.  tell him to change all his secrets.
>
> maybe i should also help him with his problem and tell him that a token value of `PAT` is not a valid token and will throw an error
> *You pasted an access token.  Change all your secrets asap.  But also, PAT is certainly not a valid because it is just three letters and doesn't follow standards.  Good thing you're generating a new token* 

right, yes.  but why force me to put a placeholder AND declare that my placeholder is a placeholder?

