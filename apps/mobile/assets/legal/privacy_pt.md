# Política de Privacidade — Raro Camera

Última atualização: 4 de setembro de 2026.

Este texto descreve o que o aplicativo **Raro Camera** (iOS e Android, identificador `com.rarocamera`) faz com dados. Não é aconselhamento jurídico.

## 1. Quem trata os dados

O controlador dos dados pessoais, no sentido da Lei nº 13.709/2018 (LGPD), é:

**Vitor Autorino Lopes (Raro Camera)**

Para exercer direitos ou tirar dúvida: **rarocan1@gmail.com**.

Versão pública deste texto: [https://rarocamera.com.br/privacidade](https://rarocamera.com.br/privacidade).

Não pedimos cadastro, login, nome nem e-mail dentro do app. Não operamos um servidor próprio (não há API nem nuvem de vídeo nossa).

Estas páginas do site são arquivos estáticos. **Não usamos cookies nem analytics neste site.**

## 2. Resumo

O Raro Camera grava vídeo no aparelho, com comando de voz opcional (“Raro gravar” / “Raro parar”) e um buffer de replay local. Os arquivos ficam no aparelho. O que sai do aparelho, sem uma ação sua de exportar ou compartilhar, é só telemetria de uso, relatório de falha e — se você assinar — o recibo da loja tratado pelo RevenueCat e pela App Store ou Google Play.

## 3. O que não pedimos e não enviamos

O app **não**:

- cria conta, perfil ou senha;
- pede e-mail, telefone, CPF ou endereço;
- lê seus contatos, calendário ou localização;
- lê o rolo de fotos (no iOS só **adiciona** um vídeo quando você escolhe guardar);
- envia o arquivo de vídeo ou o áudio da gravação para a gente;
- envia a transcrição da sua fala para a gente ou para um servidor nosso;
- mostra anúncios de terceiros.

## 4. O que fica só no aparelho

### 4.1 Vídeo, áudio e miniatura

Os clipes (MP4), o áudio embutido, a miniatura e um arquivo ao lado (duração, data, resolução, fps, lente, se veio do replay) ficam no espaço privado do app.

Não há cópia automática na nuvem. Não há sincronização entre um iPhone e um Android. Se você apagar o app, esse acervo no sandbox some com ele.

Guardar o clipe de forma permanente (vault do app + pasta da galeria do sistema) e compartilhá-lo exigem assinatura ativa. Sem assinatura você ainda pode gravar e ver o resultado na tela de preview; recusar a assinatura descarta o arquivo temporário daquela gravação. Vídeos que já estavam no vault continuam no aparelho.

Apagar um clipe no app remove o arquivo do vault. **Não** remove uma cópia que você já tenha exportado para Fotos / galeria do Android.

### 4.2 Preferências

No armazenamento local do sistema o app guarda só o que precisa para funcionar: se o onboarding já passou, idioma, resolução, fps, duração do buffer, modo de controle, se o aviso Xiaomi já apareceu, data da primeira abertura e um cache local do estado da assinatura. Nada disso é um cadastro.

### 4.3 Voz

O reconhecimento de voz roda **no aparelho**:

- **Android:** motor Vosk, no próprio telefone, inclusive em segundo plano via serviço em primeiro plano do tipo microfone.
- **iOS:** reconhecimento de fala com processamento **obrigatoriamente no aparelho**.

O áudio da voz **não é enviado** a um servidor nosso. Os registros técnicos do app anotam só se o comando reconhecido foi iniciar ou parar a gravação — **não** gravam o texto falado.

Você pode recusar o microfone. Sem microfone não há comando de voz nem áudio no clipe; a câmera de vídeo ainda pode ser usada se a permissão de câmera estiver concedida.

## 5. O que sai do aparelho

### 5.1 Firebase Analytics (Google)

Usamos o Firebase Analytics para saber se o app abre, se a câmera sobe e se houve erro de câmera.

Nesta versão, os eventos personalizados que o nosso código dispara são:

- `camera_started` — lente, resolução e fps então ativos;
- `camera_error` — código do erro e, se houver, a mensagem técnica.

O produto tem uma lista maior de nomes de evento previstos (por exemplo abertura, paywall, plano escolhido, troca de lente). Esses nomes existem no código; a maioria ainda não é enviada. O próprio SDK do Firebase também registra eventos automáticos (primeira abertura, sessão, atualização do app).

Não associamos esses eventos a um e-mail ou a um nome. Não enviamos vídeo nem fala.

O SDK do Firebase, se não for desligado à parte, pode coletar identificadores de dispositivo e, no Android, o identificador de publicidade do aparelho. O Raro Camera **não** usa esse identificador para anúncio. Não pedimos a permissão de tracking da Apple (ATT). Hoje **não há** interruptor de Analytics dentro do app.

Política do Google: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.2 Firebase Crashlytics (Google)

Se o app fecha ou lança um erro não tratado, o Crashlytics recebe o rastreamento da falha, versão do app e dados de aparelho/sistema que o SDK inclui por padrão. Servem para consertar o app. Não anexamos o seu nome nem o seu e-mail.

### 5.3 Assinatura — RevenueCat, Apple e Google

Não processamos cartão. A compra passa pela **App Store** (iOS) ou pela **Google Play** (Android).

O RevenueCat recebe um identificador anônimo de usuário do SDK (não fazemos login) e o recibo que a loja emite, para saber se o benefício premium está ativo e até quando. Serve para liberar guardar e compartilhar, e para o botão “Restaurar compras”.

Quem cobra, guarda o meio de pagamento e autentica você é a Apple ou o Google, com a conta que você já tem no telefone. Sem assinatura compartilhada automática entre iPhone e Android: são lojas diferentes.

- RevenueCat: [https://www.revenuecat.com/privacy](https://www.revenuecat.com/privacy)
- Apple: [https://www.apple.com/legal/privacy/](https://www.apple.com/legal/privacy/)
- Google Play: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.4 Exportar e compartilhar (você escolhe)

Se você tem assinatura e toca em guardar, o app escreve o MP4 na galeria do sistema (no iOS, só adiciona; no Android, pasta `Movies/Raro Camera/`). A partir daí o arquivo também vive nas regras da galeria do aparelho.

Se você toca em compartilhar, o sistema abre a folha nativa. O destino (WhatsApp, Files, AirDrop, etc.) é escolha sua. Esse destino deixa de ser tratamento nosso.

### 5.5 Internet

O app pede rede para Analytics, Crashlytics e assinatura. Gravar e ver clipes já salvos no vault **não** exige internet.

## 6. Permissões do sistema

| Permissão | Por quê | Dá para recusar? |
|---|---|---|
| Câmera | Preview e gravação | Sim. Sem câmera o app não grava vídeo |
| Microfone | Áudio do clipe e comando de voz | Sim. Sem microfone não há voz nem som no vídeo |
| Reconhecimento de fala (iOS) | Entender “Raro gravar” / “Raro parar” no aparelho | Sim. Sem isso o comando de voz no iOS não funciona |
| Adicionar à galeria (iOS) / armazenamento legado (Android 9 e abaixo) | Só quando você pede para guardar o clipe | Sim. O clipe pode continuar só no vault do app (se a assinatura permitir persistir) |
| Notificações (Android) | Aviso do serviço de microfone em segundo plano | Sim. O sistema pode limitar o serviço em segundo plano |
| Serviço em primeiro plano / microfone (Android) | Manter a escuta de voz com o app em segundo plano | Sem isso a voz em background no Android não sobe |
| Internet | Analytics, crashes, assinatura | Sem rede, essas partes ficam mudas; a câmera local segue |

Nenhuma dessas permissões é usada para ler o seu rolo de fotos nem para rastrear anúncio.

## 7. Bases e finalidades (LGPD)

Tratamos o mínimo que o app precisa para:

- executar o que você pediu (gravar, guardar, compartilhar, assinar, restaurar compra) — art. 7º, V, LGPD;
- melhorar estabilidade e uso (Analytics e Crashlytics, sem conteúdo da câmera) — art. 7º, IX, LGPD;
- cumprir regra das lojas e da lei (recibo de assinatura, atendimento a pedido seu) — art. 7º, II e V.

Não vendemos dados. Não fazemos decisão automatizada que gere efeito jurídico sobre você além de “tem ou não tem o benefício premium”, e isso vem do recibo da loja.

## 8. Seus direitos

Você pode pedir, pelo **rarocan1@gmail.com**, confirmação de tratamento, acesso, correção, anonimização, portabilidade quando couber, informação sobre compartilhamentos e revogação das permissões do sistema (essas se revogam também em Ajustes do iOS / Configurações do Android).

Caminhos práticos, sem esperar e-mail:

- **Vídeos no vault:** apague no próprio app ou desinstale o app.
- **Cópia na galeria do sistema:** apague pelo app de Fotos / Galeria — o Raro Camera não mexe nela no delete.
- **Permissões:** Ajustes / Configurações do aparelho.
- **Assinatura:** cancele na App Store ou na Google Play; o RevenueCat deixa de ver um recibo ativo.
- **Identificador anônimo do RevenueCat / dados de crash e analytics:** peça pelo e-mail acima. Nós não temos um cadastro seu; o pedido será encaminhado ao operador no que for possível identificar.

A Autoridade Nacional de Proteção de Dados (ANPD) é o órgão fiscalizador no Brasil.

## 9. Quanto tempo fica

| Dado | Retenção |
|---|---|
| Clipe e sidecar no vault | Até você apagar ou desinstalar o app |
| Cópia na galeria do sistema | Até você apagar na galeria; não segue o delete do app |
| Preferências locais | Até limpar dados do app ou desinstalar |
| Eventos Analytics / crashes | Pelo prazo padrão dos painéis Firebase do projeto |
| Recibo / entitlement no RevenueCat | Enquanto a loja e o RevenueCat mantiverem o histórico daquele identificador anônimo |

## 10. Transferência para fora do Brasil

Google (Firebase) e RevenueCat processam dado fora do Brasil, em geral nos Estados Unidos, sob os contratos deles com quem publica o app. Não hospedamos vídeo nosso em outro país porque **não hospedamos vídeo**.

## 11. Crianças

O app não pede idade e não tem área infantil. Não é feito para criança. Se você é responsável por um menor e quer que apaguemos o que for possível identificar nos operadores, escreva para **rarocan1@gmail.com**.

A classificação etária das lojas é definida no App Store Connect e no Play Console na hora de publicar.

## 12. Mudanças

Se o app passar a coletar coisa nova (login, nuvem, outro SDK), esta política precisa ser reescrita **antes** dessa mudança. A data no topo muda. A URL canônica continua apontando para o texto vigente.

## 13. Contato

Vitor Autorino Lopes (Raro Camera)  
E-mail: rarocan1@gmail.com  
Documento: [https://rarocamera.com.br/privacidade](https://rarocamera.com.br/privacidade)
