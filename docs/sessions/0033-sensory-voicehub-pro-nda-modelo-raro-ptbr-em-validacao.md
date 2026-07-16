# 0033 — Sensory reaberto: VoiceHub Pro grátis + NDA assinado + modelo "Raro" pt-BR em build (validação ativa)

- **Data:** 2026-06-23
- **Duração:** ~2h (frente comercial/produto, sobreposta ao build da Sensory)
- **Participantes:** Eduardo Rodrigues + Claude Code (Opus 4.8) · contato externo: Jeff Rogers (Sensory Inc.)
- **Branch:** `feat/camera-native-bridge`
- **Commits:** commit de reconciliação harness/memória desta sessão (docs only)

## Objetivo

Avaliar a virada na frente do wake-word **background**: a Sensory respondeu ao contato do dono e deu acesso à ferramenta de criação de modelo. Decidir os próximos passos comerciais/técnicos **sem fechar nada** e reconciliar o harness/memórias, que ainda diziam "Sensory descartado → fica no ONNX próprio" (agora desatualizado).

> **Natureza desta sessão:** marco **comercial/produto + validação em curso**. **ZERO código de produção tocado.** Quase tudo foi decisão/negociação/ação-do-dono (criar conta, assinar NDA, buildar modelo no VoiceHub) + reconciliação de docs.

## Contexto inicial

Saída da 0029/0032: wake-word background ONNX próprio = **inviável** (4 modelos falharam "Raro" na voz real no iPhone 12 — a palavra de 2 sílabas com muitas rimas PT-BR é o teto do pipeline openWakeWord). Estava em "STANDBY aguardando licença Sensory". O Bloco 1 (Firebase) é o próximo trabalho de **código** (pré-reqs prontos na 0032). Memórias/harness diziam, de várias formas, "Sensory é paga/gated → fora; caminho RARO = ONNX próprio (ADR-0023); NÃO refazer esta pesquisa".

## O que foi feito

**Frente Sensory (ação do dono, fonte = email Jeff Rogers 2026-06-23 — fato externo, não verificável no repo):**
- Jeff deu acesso **grátis ao VoiceHub Pro** (expira 2026-09-21, 90 dias) — ferramenta onde se cria/testa o modelo `.snsr`.
- **VoiceHub tem pt-BR nativo** — exatamente o idioma cuja ausência matou o ONNX próprio. Projeto Wake Word criado: `Raro WW PT-BR`, Language `pt_BR`, palavra `raro`, output `THF/TNL SDK: snsr file`, Operating Point default (10/21), **Best Quality**. Build **em curso** (Best Quality entra em fila e demora; notifica por email).
- Jeff confirmou por email os 3 pontos que faltavam: **(1)** licença de **produção é non-expiring** (a expiração de 120 dias era só do tier de teste; o modelo deeply-embedded de teste expira ainda antes — 11.43h OU 107 eventos, por email); **(2)** **1 preço cobre iOS + Android** ("we don't view these as separate"); **(3)** disposto a modelar preço ao nosso caso.
- **NDA mútuo assinado** (`Sensory Mutual NDA - 6-2026.docx`). Lido cláusula a cláusula: recíproco genuíno, vigência 5 anos / sigilo sobrevive 3 anos, lei da Califórnia, **sem** non-use / exclusividade / non-compete / cessão de IP / obrigação de compra. 2(e) proíbe engenharia reversa (padrão). Seguro de assinar.
- Resposta ao Jeff redigida (NDA assinado anexo + pedido do **modelo de preço** — flat/per-app vs per-user — e **ballpark**). Enviar é ação do dono.

**Reconciliação harness/memórias (anti-drift — docs only, nesta sessão):**
- Auditoria adversarial (workflow 6 agentes, 3 dims + verify) mapeou ~12 lugares dizendo "Sensory descartado/standby". A verificação **pegou erros dos mapeadores** (atribuíram a uma memória dados que ela não tinha; citaram um arquivo sem menção a Sensory; queriam editar append-only) e reforçou a trava anti-sobre-correção.
- Escopo escolhido pelo dono: **session log 0033 + alta alavancagem.** Atualizados (com proveniência "email Jeff 2026-06-23" e fraseado "validação ativa / decisão pendente", nunca "resolvido"):
  - `.claude/hooks/reinject-roadmap.sh` (CRÍTICO — injetado em todo SessionStart): bloco "SENSORY EM VALIDAÇÃO ATIVA" + pendências (preço + teste device). Validado `bash -n` + smoke.
  - `MEMORY.md` (índice L8/L81): "background standby Sensory" → "validação ativa, não descartado". L82 já estava correto, não tocado.
  - `raro-competitor-sensory-voicehub-ios-sdk-gated.md`: description corrigida + bloco "VIRADA 2026-06-23" no topo + neutralizado o "NÃO refazer esta pesquisa". Corpo original preservado (era correto em 2026-06-10).
  - `ADR-0023`: bloco "ATUALIZAÇÃO 2026-06-23" no topo (append, histórico intacto) + linha de Status. Marca que só vira ADR-0025 se passar nos 2 gates.

## O que NÃO foi feito (e por quê)

- **Nenhum código de produção** — esta sessão é comercial/validação. O `.snsr` nem existe ainda (build em fila); a integração nativa (libsnsr.a/Pigeon) só faria sentido pós-contrato.
- **Teste do modelo "Raro" no iPhone 12** — o build não terminou. É o gate técnico decisivo (lição 0029: só device decide).
- **Preço/decisão comercial** — Jeff ainda não mandou o número (atrelado ao NDA, que acabou de ser assinado). Sem número, não dá pra fazer a conta margem (R$9,90 ≈ US$1,80/mês; per-user mata, flat/per-app serve).
- **Não promovi o ADR-0023 a Accepted nem declarei o background resolvido** — Sensory está em VALIDAÇÃO, não é o caminho confirmado. Sobre-correção seria drift.
- **Docs de estado vivo de menor alavancagem** (02-ARCHITECTURE, 05-FEATURES, 07-NATIVE-BRIDGES, ESTADO-WAKEWORD, Blueprint §2.3, 09-DOD) ainda dizem "standby Sensory" — ficam para a sessão que **decidir** Sensory (com preço + teste). Anotado como dívida consciente.
- **Append-only respeitado:** session logs antigos (0029-0032), CHANGELOG e histórico do ADR NÃO foram editados — eram verdadeiros quando escritos.

## Aprendizados / surpresas

- **Aceitar o teto do ONNX próprio ≠ desistir do problema.** A lição 0029 ("N modelos independentes reprovando = teto") continua certa, mas o teto era do *nosso* pipeline — uma engine paga com pt-BR nativo é um caminho distinto, não uma reabertura do beco.
- **O "muro" da memória era parcialmente um mal-entendido de tier.** A memória tratava a expiração do dev-key como prova de inviabilidade comercial geral; o contato direto esclareceu que produção é perpétua. Lição: "investigação de docs públicos" pode errar onde só o contato comercial esclarece.
- **Negociação: não dar o primeiro número.** O Jeff perguntou "$1, $10?" para ancorar o royalty na nossa margem. A resposta enquadrou o ticket como *restrição* (per-user não cabe) e devolveu a pergunta — ele deve revelar o modelo primeiro.
- **Verify adversarial pegou 2 erros dos próprios mapeadores** (memória fantasma; atribuição de fato à memória errada) — confirmar cada achado na fonte antes de editar não é opcional.

## Próximos passos

- **[AÇÃO DO DONO] Enviar a resposta ao Jeff** (NDA assinado anexo + pedido de preço/modelo).
- **[QUANDO O BUILD SAIR] Testar "Raro" no iPhone 12** via app de teste do VoiceHub: taxa de detecção (de 10 ditos, quantos disparam) + falso-positivo (1-2 min de fala normal sem "Raro") + **tela bloqueada** (o cenário que só a Sensory promete). Gate = device, não o medidor do VoiceHub.
- **[QUANDO O PREÇO CHEGAR] Fazer a conta de margem** com o dono (per-user vs flat contra R$9,90/US$1,80).
- **[DECISÃO DE PRODUTO ABERTA]** se Sensory passar nos 2 gates → ADR-0025 (troca de engine background) + reconciliar os docs de estado vivo restantes. Se reprovar → foreground-only fica definitivo, registrar.
- **[TRABALHO DE CÓDIGO — independente da Sensory] Bloco 1 (Firebase)** continua sendo o próximo entregável de código (pré-reqs prontos na 0032): `flutterfire configure` (`export PATH="$PATH:$HOME/.pub-cache/bin"`) + `initializeApp` + plugins gradle + Crashlytics 3 handlers.

## Referências

- Memórias: `raro-competitor-sensory-voicehub-ios-sdk-gated` (virada no topo), `raro-competitor-okcamera-android-apk-teardown` (parâmetros Sensory p/ calibrar: 16kHz mono, score 0.45, operating-point), `feedback_synthetic_eval_is_not_the_gate_device_is` (gate = device), `feedback_many_native_fixes_means_reread_logs_not_abandon_framework` (teto do ONNX próprio)
- ADR: `0023-voice-engine-dedicated-not-sfspeechrecognizer.md` (atualização 2026-06-23 no topo); futuro ADR-0025 se Sensory fechar
- Hook: `reinject-roadmap.sh` (bloco Sensory)
- Externo (não no repo): email Jeff Rogers/Sensory 2026-06-23; `Sensory Mutual NDA - 6-2026.docx` (assinado)
- Sessão anterior: [0032](0032-bloco-1-prep-firebase-configs-cli-harness-reconciliacao.md)
