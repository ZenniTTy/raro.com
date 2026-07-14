# 0026 — System Design formalizado: client-only single-node, vault filesystem como store canônico

- **Data:** 2026-07-14
- **Status:** Accepted
- **Relaciona:** ADR-0004 (client-only, sem backend), ADR-0002/0003 (native bridges + replay nativo), ADR-0013 (Pigeon anti-drift), ADR-0021 (integridade de formato), ADR-0025 (Firebase bootstrap)
- **Documento:** [docs/11-SYSTEM-DESIGN.md](../11-SYSTEM-DESIGN.md)

## Contexto

As decisões de arquitetura do RARO estavam distribuídas entre `02-ARCHITECTURE.md` (camadas), `07-NATIVE-BRIDGES.md` (bridges), o Blueprint e ~11 ADRs, mas **nunca houve um documento de nível de sistema** consolidando: (a) o modelo de dados local (schema do sidecar do vault), (b) o dimensionamento (crescimento de storage, custo de leitura do vault), e (c) o plano de evolução por gargalo. A ausência desse artefato é fonte de drift — mudanças no vault ou nos contratos não tinham um lugar canônico que descrevesse o desenho de dados/sistema como um todo. Este ADR registra a decisão de formalizar esse desenho e as escolhas de arquitetura que ele torna explícitas.

## Decisão

1. **O RARO é modelado como sistema client-only single-node por device** (consequência de ADR-0004). Não há servidor, banco central nem API própria. CAP não se aplica de forma distribuída — cada device é uma ilha `CA`. Componentes de sistemas distribuídos (cache distribuído, read replica, message queue, CDN, load balancer) são **deliberadamente ausentes** por falta de gargalo que os justifique (anti-YAGNI). Introduzir qualquer um deles — ou um backend — exige **novo ADR** e revisão de ADR-0004.

2. **O store canônico de vídeos é o vault filesystem**, não um banco: `<AppDocuments>/vault/` com trio flat por id (`$id.mp4` + `$id.json` sidecar + `$id.jpg` thumbnail). O **schema do sidecar** (`id`, `name`, `durationMs`, `recordedAt`, `isReplay`, `thumbnailHue`, `thumbnailPath?`) é **mínimo por design**: não persiste `path` (derivado do id, evita bug de UUID de container stale) nem `resolution`/`fps`/`codec` por vídeo. Mudança nesse schema é mudança de contrato de dados e deve atualizar §4 do SDD.

3. **Source of truth explícito por entidade** (SDD §4): nativo para sessão/gravação/replay; filesystem para clipes salvos; SharedPreferences para config; RevenueCat/lojas para assinatura; Firebase (write-only best-effort) para telemetria; constante para wake word. Estado nativo-assíncrono chega ao Dart sempre via stream + Notifier reativo, nunca bool local.

4. **A evolução é guiada por gargalo medido, não preventiva** (SDD §6). Os gargalos reais catalogados são on-device: scan O(n) do vault na galeria, crescimento de storage sem retenção, ausência de formato no sidecar, e paridade Android. Cada um só vira spec quando medido.

## Consequências

- **Positivas:** existe uma fonte autoritativa de desenho de dados/sistema (`11-SYSTEM-DESIGN.md`) que serve de gate contra drift de schema — em especial o schema do sidecar do vault, antes só implícito no código. As não-decisões (o que NÃO se adiciona) ficam registradas, evitando slop arquitetural futuro.
- **Negativas / limites conhecidos (registrados no SDD §7):** cobertura de analytics ~6,25% (2/32 eventos wired); bridge `volume` é só contrato Pigeon sem impl; sidecar não guarda formato; atomicidade cobre só o JSON, não a cópia do `.mp4`; 3 telas (`p05aLockMode`/`p11Terms`/`p12Privacy`) definidas mas não roteadas; paridade Android pendente (Bloco 3).
- **Guarda:** este ADR + SDD §4/§7 são o ponto de verificação quando o vault, o schema do sidecar ou os contratos Pigeon mudarem.

## Alternativas consideradas

- **Introduzir SQLite/DB local para o vault:** rejeitado agora — sem gargalo medido (o scan O(n) só dói com centenas de clipes); filesystem + sidecar basta. Fica como iteração 1 do plano de evolução se/quando medido.
- **Persistir resolução/fps/codec no sidecar já:** rejeitado — Surgical Changes; nenhuma tela consome hoje. Vira migração de schema quando houver consumidor (iteração 3).
- **Adicionar backend para sync/backup:** rejeitado — violaria ADR-0004; mudança de produto que exige decisão do dono + novo ADR.
