# Entry-point and dependency detection — stack-agnostic signals

Use this as a **checklist of where to look**, not as a scanner. It is not exhaustive: when a stack
is not listed, apply the same question to it ("how does the outside world trigger code here, and
what does this code call?") and record what you used as evidence. Every hit is confirmed by
reading the code it points to. A text match is not a finding by itself.

The most common error is reading an annotation or keyword out of context. `@Post` on a
**client** interface is an *outbound* call. `router.get` inside a test is not an entry point.
Confirm the **type that owns the signal** before you classify it. A knowledge graph (AST-based)
makes this owner relation explicit when one is present.

## 1. Stack detection (Phase 0)

| Signal file | Stack |
|---|---|
| `pom.xml`, `build.gradle(.kts)` | JVM (Java/Kotlin/Scala). Look in dependencies for Spring Boot, Micronaut, Quarkus, Helidon, Vert.x, Ktor, Dropwizard |
| `package.json` | Node/TS. Look in dependencies for express, fastify, koa, hapi, @nestjs/*, next, nuxt, remix, @sveltejs/kit, react-router, @angular/*, vue-router, serverless, aws-lambda |
| `pyproject.toml`, `requirements*.txt`, `setup.py`, `Pipfile` | Python: fastapi, flask, django, starlette, aiohttp, celery, click, typer |
| `*.csproj`, `*.sln` | .NET: ASP.NET Core (Controllers / Minimal APIs), Azure Functions, MassTransit, Hangfire |
| `go.mod` | Go: net/http, gin, echo, chi, fiber, grpc-go, cobra |
| `Gemfile` | Ruby: rails, sinatra, sidekiq, thor |
| `composer.json` | PHP: laravel, symfony, slim |
| `Cargo.toml` | Rust: axum, actix-web, rocket, tonic, clap |
| `mix.exs` | Elixir: phoenix, broadway, oban |
| `serverless.yml`, `template.yaml` (SAM), `cdk.json`, `*.tf`, `host.json` | Function-as-a-service wiring: entry points are declared in infrastructure, not only in code |
| `Dockerfile`, `docker-compose*.yml`, `k8s/`, `helm/` | Runtime wiring: ports, cron jobs, sidecars, env-driven feature switches |

A repo can contain several stacks. List each with its paths, for example a Next.js front end plus a
Python worker.

## 2. Inbound surface (entry points) — by `kind`

| `kind` | What to look for (examples, not a closed list) |
|---|---|
| `http` | Route declarations: annotations on controller types (`@RestController`/`@Controller` + `@GetMapping`…, `@Path` JAX-RS, `[HttpGet]`/`MapGet` .NET), router registrations (`app.get`, `router.post`, `@app.route`, `path()` in Django `urls.py`, `r.HandleFunc`, `e.GET`, Rails `routes.rb`, Laravel `Route::`), file-system routing (Next `app/**/route.ts`, `pages/api/**`, SvelteKit `+server.ts`), OpenAPI specs that generate servers |
| `graphql` | Schema files (`*.graphql`, SDL strings), resolvers (`@Resolver`, `Query`/`Mutation` maps, graphene/strawberry types) |
| `grpc` | `*.proto` `service` blocks plus the server implementation that registers them |
| `websocket` | `@WebSocketGateway`, `socket.io` `on(...)`, `@ServerEndpoint`, Phoenix channels, SignalR hubs |
| `message` | Consumers/listeners: `@KafkaListener`, `@SqsListener`, `@JmsListener`, `@RabbitListener`, `@EventPattern`, Celery/Sidekiq/BullMQ workers, MassTransit consumers, Broadway pipelines, function triggers bound to a queue/topic in IaC. **A consumer with no HTTP controller is event-driven, not empty.** |
| `webhook` | HTTP routes that receive third-party callbacks (signature verification code is a good marker). Classify as `webhook`, not `http`, so the contract records the sender |
| `schedule` | `@Scheduled`, cron expressions in code or IaC (`schedule:` in serverless, k8s `CronJob`), `node-cron`, Celery beat, Hangfire recurring, Oban cron, Quartz |
| `cli` | Command frameworks (picocli, commander/yargs, click/typer, cobra, clap, thor, Symfony Console), `bin` in `package.json`, `console_scripts` |
| `ui-route` | Front-end routes and screens: router configs, file-system pages, navigation graphs. The behavior to spec is what the user can do on each route |
| `function` | Function handlers (`exports.handler`, `def handler(event, context)`, Azure `[Function]`) whose trigger is not one of the above |
| `library-export` | Only when the component **is** a library: its public API (exports, `__all__`, public types). Internal modules are not entry points |
| `db-trigger` | DB triggers, CDC consumers (Debezium), change streams that run component code |

Also record, per entry point, **auth** as observed: middleware/filters/guards/decorators in
application order, gateway config. If it cannot be determined from the repo, use `null` and add a
warning.

## 3. Outbound, data stores, configuration

- **Outbound:** HTTP clients (declarative clients, `fetch`/axios/requests/HttpClient wrappers),
  gRPC stubs, message producers/publishers, third-party SDKs (payments, email, storage, auth).
  Record target, timeout and retries from config or code, and which entry points reach each call.
- **Data stores:** ORM entities/models, migrations, repositories, raw SQL, cache clients, object
  storage clients. Record entities and whether access is read, write or both.
- **Configuration that changes behavior:** feature flags, env switches, tenant/country config.
  Record **names only**, and mark keys that hold credentials, tokens or connection strings with
  `secret: true`. Never copy a secret value, connection string or token into any artifact,
  including values that look harmless in `.env.example` or test fixtures.

## 4. Usage evidence (optional, never invented)

Usage numbers come only from a source the user provides: gateway/access logs, APM
(Dynatrace, Datadog, New Relic), queue metrics (CloudWatch `NumberOfMessagesReceived`, consumer-group
throughput), product analytics for UI routes. Without one, every `usage` is `null` and a warning
says the dead-surface analysis is **structure-only**. When a metric counts something other than
invocations (queue receives include redeliveries, a gateway may count retries or probes), record
the number as given and say in a warning what it counts. Entry points the source does not cover
(e.g. a CronJob or an operator CLI next to gateway logs) stay `null` with a warning.

## 5. Knowledge graph (when present)

If `graphify-out/graph.json` (or another AST-derived graph) exists, check freshness first: did
any scope path change since it was built? The three states are `absent`, `current` and `stale`,
and the inventory records which one applies. A current graph gives the owner type of each
annotation, plus communities and hyperedges that seed the capability map. Respect its
`EXTRACTED`/`INFERRED` labels. `INFERRED` facts orient the work but are verified against code
before they back a spec.
