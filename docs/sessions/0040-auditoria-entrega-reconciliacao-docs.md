# Sessão 0040 — Auditoria de entrega + reconciliação de docs

**Data:** 2026-09-02
**Branch:** `develop`
**Tipo:** docs-only (zero alteração em código de produção)
**Pedido do dono:** "auditoria completa do que realmente falta para finalizar o app, atualizar o roadmap e os arquivos desatualizados, e me dizer exatamente onde parei — sempre validando para não trazer falso positivo."

---

## Método (anti-falso-positivo)

A regra da sessão foi: **nenhum item conta como feito por estar escrito**. Cada afirmação precisou de evidência citável — `arquivo:linha`, saída de comando, ou histórico do git. Onde a evidência contradisse o documento, a evidência venceu.

Ferramentas de prova usadas:
- 2 agentes de leitura em paralelo (um para a camada nativa Android × iOS, outro para produto/telas/monetização), agrupados por ângulo e não por arquivo.
- Verificação manual independente dos achados mais graves (não aceitei o relatório dos agentes de cara).
- `flutter analyze`, `flutter test`, `apksigner verify`, `unzip -l` no APK, `git stash` como experimento controlado.

---

## Achados (todos com prova)

### 1. A suíte está VERMELHA — e a causa é a árvore de trabalho, não o commit
`flutter test` → **353 passam, 1 falha**: `test/contract/forbidden_ui_literals_test.dart` acusa 3 literais fora do `.arb` em `plan_card.dart` (`👑`, `RARO CAM`, `🔥`).

**Prova de que o commit está são:** `git stash` → o teste passa; `git stash pop` → volta a falhar. Ou seja, o harness de i18n **funcionou como projetado** e pegou drift introduzido pela fatia de tipografia Poppins que estava em andamento.

### 2. Replay buffer no Android: não existe, mas a interface anuncia
- `ReplayBufferHostApi` **nunca é registrada** — zero referências a replay no `MainActivity.kt`.
- `ReplayBufferHostApiImpl.kt` existe mas os 3 métodos lançam `UnsupportedOperationException`.
- `CameraManager.kt:176-177` **descarta o pré-roll** com um `Log.w("includeReplayPreroll ignored on Android")`.
- O guard `3f33a77` (`channel-error` → `onUnsupported`) evita o crash, mas `replay_buffer_repository_provider.dart:14` só **loga**. O usuário liga o Replay Buffer no Settings, escolhe 15/30s, e nada acontece — sem nenhum aviso.

### 3. Monetização não é "mock": nunca foi iniciada
- `purchases_flutter: ^10.1.1` no `pubspec.yaml:24` com **zero imports** em `lib/`.
- `subscription_controller.dart:19`: `subscribe()` grava `isSubscribed: true` no SharedPreferences. Sem recibo, sem loja, sem validação.
- **Nenhum gating existe.** `isSubscribed` só é lido para decidir popup (`camera_screen.dart:118`) e banner de trial. Gravar e salvar são livres.
- `paywall_screen.dart:123` "Restore purchases" → `_comingSoon`. **A Apple reprova assinatura sem restore funcional.**

### 4. Release Android sai assinado com chave de debug
`apksigner verify --print-certs app-release.apk` → `certificate DN: C=US, O=Android, CN=Android Debug`.
Confirma `build.gradle.kts:40` (`signingConfig = signingConfigs.getByName("debug")`). Não existe `key.properties` nem `signingConfigs.release`. **A Play rejeita esse binário.**

### 5. Modo "Volume" é selecionável e não existe em lugar nenhum
`settings_screen.dart:367-370` deixa escolher e **persistir** o modo Volume. Não existe `VolumeHostApiImpl` **nem no Android nem no iOS** — o Pigeon `volume_api` só tem `volumePing()`/`volumeReady()`, um handshake vazio. É um gap das duas plataformas, não só do Android.

### 6. Telas e modais
Enum `AppScreen` declara **13**; o router registra **10**. `p05aLockMode`, `p11Terms` e `p12Privacy` têm **zero referências** no código inteiro. Modais: M01 ok; **M02 (Xiaomi) e M03 (Bluetooth) não existem** — só o nome do evento de analytics e uma chave de storage.
⚠️ A **política de privacidade é obrigatória** para submeter nas duas lojas.

### 7. Preview (P08) é uma casca
4 das 5 ações são snackbar de 1 segundo (`preview_screen.dart:114,242,272,278`): share do header, share grande, **delete** e info. `vault_service.dart:68-75` implementa o delete corretamente (remove `.mp4`, `.json`, `.jpg`) e **não tem nenhum caller**. É o item mais barato do roadmap.

### 8. Git
- `5a35be4` (fix R8/JNA, sem o qual o APK release fecha sozinho no boot) **não foi pushado** — existe só nesta máquina.
- **`feat/fatia-5-replay-buffer-android`: branch NÃO mergeada e NÃO pushada** (4 commits, 2026-07-19) — achada quando o dono perguntou sobre branches abertas; minha auditoria inicial não a tinha visto porque olhei PRs, não branches locais. Contém **ADR-0031** + design + **spike-gate já executado e APROVADO no M54**, que **muda a abordagem do replay Android** de `MediaCodec` (o que o ADR-0030/Blueprint reservavam) para **segmentos rotativos do CameraX + concat sem re-encode (Rota D)**. **Não é mergeável como está**: o `ReplayBufferHostApiImpl` está temporariamente ligado ao spike (`runReplaySpike`) em vez do comportamento real, e o `ReplaySpikeGate.kt` é descartável. **Risco:** é o único lugar onde esse ADR e a prova do spike existem — se a máquina falhar, perde-se.
- `develop` está **441 commits à frente da `main`**.
- Todos os 10 PRs estão MERGED; nenhum aberto.

---

## Confirmado saudável (não mexer)

- `flutter analyze`: **limpo**, zero issues.
- **i18n real**: 117 chaves traduzíveis em `app_pt.arb`, `app_en.arb` e `app_es.arb` (contagem verificada por parsing dos 3 arquivos), com teste-guarda ativo.
- **APK contém a voz de fato**: `unzip -l` mostra `libvosk.so` (3 ABIs) + `assets/vosk-model-small-pt-0.3/` completo.
- `proguard-rules.pro` mantém JNA + Vosk com justificativa documentada.
- Firebase/Crashlytics/Analytics provados no iPhone 12 na sessão 0035.
- Paridade Android real em gravação, tap-to-focus e voz.

### Risco menor anotado (não bloqueia v1.0)
`CameraLensDiscovery.kt:28-31` detecta ultra-wide por **heurística de distância focal** (`maxFocal > minFocal * 1.3`). Pode escolher errado em aparelhos cuja menor focal é macro/depth. Aceitável agora, mas é candidato a bug de OEM.

---

## Documentos atualizados nesta sessão

| Arquivo | O que mudou |
|---|---|
| `docs/superpowers/plans/PLANO-MESTRE-finalizacao-entrega-cliente.md` | **Reescrito.** Bloco 3 estava todo em aberto embora as Fatias 1–4 estivessem entregues; Bloco 2 estava como "mock" quando nunca foi iniciado. Adicionados caminho crítico, 4 decisões de produto abertas e o drift novo. |
| `docs/09-DOD.md` | Reconciliado item a item com evidência; adicionados critérios que faltavam (restore, share/delete). |
| `docs/10-CHANGELOG.md` | Entrada da auditoria (o arquivo já estava correto até 0.9.0). |
| `docs/sessions/0001-INDEX.md` | Adicionadas as sessões **0039** (i18n + R8, que nunca tinha sido registrada) e **0040**; a seção "Como retomar" estava descrevendo a sessão S2.B, muitas sessões atrás — reescrita. |

---

## Decisões do dono (2026-09-02, ainda nesta sessão)

Apresentada a auditoria, o dono respondeu as 4 questões abertas:

1. **Voz em background: já funciona no Android — congelar.** "Raro gravar"/"Raro parar" operam em background no device. **Correção da minha auditoria:** eu havia reportado o background como pendente por causa do histórico do ONNX no iOS; no Android o Vosk motor único + FGS `microphone` resolveu. O caminho está fechado e **não deve ser tocado** — os ajustes que o dono tem em mente são em outras áreas.
2. **Premium = "o app só salva vídeos na galeria se for premium".**
   ⚠️ **Verificado no código e o gap é maior do que parece:** além de não haver gating (`camera_flutter_api_provider.dart:93` salva incondicionalmente), **não existe exportação para a galeria do sistema** — nenhum `MediaStore` (Android) nem `PHPhotoLibrary` (iOS) no repositório inteiro. O vídeo vai só para o vault privado (`vault_service.dart:12`), e a tela "Galeria" do app lista esse vault, não o rolo da câmera. Logo, a regra exige **feature nova + gating**, não um `if`. Virou Bloco 2.3a/2.3b.
   **Pergunta aberta que sobrou:** o que o usuário free recebe? (grava e fica só no app? não grava? marca d'água?)
3. **Replay no Android: implementar** — o dono classificou como bug, e disse que era justamente um dos que ia reportar. Bloco 3.2 reescrito com as 3 partes (ring `MediaCodec`, registrar a HostApi, honrar `includeReplayPreroll`) e gate de ffprobe.
4. **Modo Volume: implementar nas 2 plataformas.** Bloco 4.5 reescrito; note que exige **ampliar o contrato Pigeon** `volume_api.dart` (hoje só `ping`/`ready`, sem evento de tecla) — mudança de contrato aciona o hook `warn-adr-drift` e pede ADR.

### Pergunta do dono: "o plano cobre RevenueCat e toda forma de pagamento/login?"

**RevenueCat: sim** (Bloco 2, que foi ampliado nesta rodada de 2.5 para 2.8 itens). **Login: não — e auditei para confirmar que a ausência é correta, não esquecimento.**

- **Zero autenticação no repo**: `firebase_auth`, `google_sign_in` e `sign_in_with_apple` não estão no `pubspec.yaml`; nenhum `signIn`/`currentUser` no código. O Blueprint e o ADR-0004 (client-only) também **nunca mencionam** login.
- **Por que está certo assim:** `PaymentMethod` só tem `apple`/`google` — a cobrança é 100% das lojas. Quem autentica o comprador e guarda o meio de pagamento é a App Store / Play Store, com a conta que o usuário já tem no aparelho. O RevenueCat identifica por **App User ID anônimo** + recibo da loja. O papel do login é cumprido pelo **"Restore purchases"** (2.5) — que é justamente por isso que a Apple o exige.
- **Consequência assumida:** sem login, a assinatura **não atravessa plataformas** (iPhone → Android). Normal em app client-only, mas o dono precisa saber.
- **Gatilhos que exigiriam login no futuro** (todos pedem ADR novo, pois mudam o ADR-0004): assinatura compartilhada entre iOS e Android, backup de vídeos na nuvem, ou área web.

**Itens novos que essa pergunta revelou** (não estavam no plano): **2.6** remover o seletor de método de pagamento do checkout (é decorativo e duplica a folha nativa da loja); **2.7** criar os 2 produtos de assinatura nas lojas + trial de 30 dias em cada uma (sem isso `getOfferings` volta vazio); **2.8** textos obrigatórios de assinatura + links de Termos/Privacidade funcionando, exigidos no review das duas lojas.

**Novo item anotado a pedido do dono:** faxina de repositório (**Bloco 4.5-F**, F.1–F.6) — docs órfãos/obsoletos, sprints superados competindo com o roadmap, código morto, testes desatualizados, deps declaradas sem uso e assets sem referência. Read-only primeiro: listar e propor, deletar só com aval.

---

## NÃO feito (por design)

- **Nenhuma correção de código.** O pedido foi auditar e atualizar docs. A fatia Poppins segue aberta na árvore de trabalho, aguardando decisão do dono sobre como resolver os 3 literais.
- `5a35be4` **não foi pushado** (é ação de escrita em remoto — precisa do aval do dono).
- Não foi criado ADR novo; nenhuma decisão de stack foi tomada.
- As 4 decisões de produto continuam abertas — são do dono, não minhas.

---

## Próximo objetivo (1 linha)

Fechar a fatia Poppins deixando `flutter test` verde, pushar `5a35be4`, e responder as 4 decisões de produto que destravam os Blocos 2, 3.2 e 4.5.
