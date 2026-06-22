# Contraponto Adversarial: Auditoria do "ESTADO-WAKEWORD-RARO.md"

> # 🛑 REFUTADO PELO DEVICE — sessão 0029 (2026-06-21)
> A tese central deste contraponto — "Raro' falha por domain gap, não por ser foneticamente difícil; o treino híbrido com voz real resolve" — foi **testada e não se sustentou**. A sessão 0029 fez o treino híbrido com a voz real do dono e o veredito no iPhone 12 foi o oposto: mesmo com voz real no treino, "Raro" não dispara (AUC máx 0.54, melhor 0.497, não cruza 0.5). A palavra "Raro" (2 sílabas, muitas rimas PT-BR) **é** o limite do pipeline openWakeWord. O contraponto estava certo em exigir o teste híbrido (valeu fazer), mas a conclusão que ele previa não veio. Background = **STANDBY (Sensory)**; foreground SFSpeech vigente. Ver `docs/sessions/0029-*.md` + ADR-0023. **Mantido como histórico.**
>
> **Objetivo:** Este documento é uma resposta direta e adversarial à análise feita na sessão S2.E (`ESTADO-WAKEWORD-RARO.md`). Ele visa expor falhas de lógica, contradições internas e testes fundamentais que foram ignorados antes de declarar o modelo "Raro" (toggle único) um beco sem saída devido ao seu tamanho (2 sílabas).

---

## 1. A Falácia do "Beco Sem Saída" (A Culpa do Domain Gap)

O documento original conclui na **Seção 3** que a palavra "Raro" falha na voz real porque é curta demais (<6 fonemas), usando como evidência o fato de que a probabilidade no *device* cai para "nível de silêncio" (<0.08) em gravações reais. 

**O Contraponto:**
A falha em atingir limiares mínimos (0.08) não prova a impossibilidade fonética da palavra. Prova apenas que as *features* extraídas da voz real não têm intersecção com o modelo treinado. 
O modelo foi treinado com **100% de vozes sintéticas (VoxCPM)**. O resultado (81% de acerto no sintético e 0% no real) é a definição de manual de **Overfitting e Domain Gap**. O modelo não aprendeu a palavra "Raro"; ele decorou a inflexão artificial do TTS e a ausência da distorção de microfone (EQ do iPhone 12 + Low-pass de estar no bolso). Condenar a palavra baseando-se num teste puramente *Zero-Shot* cruzando domínios (sintético -> real) é um erro metodológico.

## 2. A Contradição Explicita na Seção 10

Na **Seção 10**, o agente escreve: 
> *"Real-only NÃO substitui sintético... Consenso: HÍBRIDO (TTS multi-voz + 20–50 reais peso 3×)."*

Na **Seção 4 (Timeline)**, no entanto, é revelado o custo de US$11 e três modelos treinados (`gravar`, `parar`, `raro-toggle`). **Em nenhum deles foi injetado áudio real da voz do dono.**
O agente mapeou a solução correta da literatura de ML (treino híbrido pesado para fechar o *Domain Gap*) mas **abandonou o caminho sem sequer executá-lo** para o modelo `raro.onnx` final. A recomendação da Opção B -> A (gravar voz para testar no modelo velho) é falha; o modelo velho *nunca* vai pontuar áudio que não estava na sua distribuição original. A voz real deve entrar no **treinamento**, não apenas na validação.

## 3. O Viés do Inglês e a Omissão do "Spelling Fonético"

A base de extração de *features* do `openWakeWord` é altamente enviesada para o inglês. Embora o TTS VoxCPM seja PT-BR, gerar a *target_phrase* com a string pura `"Raro"` deixa o motor à mercê do sotaque gerado pelo TTS.
A comunidade que desenvolve para idiomas não-nativos frequentemente utiliza **Spelling Fonético** para forçar as pronúncias mais bizarra-mas-acuradas (ex: `"Haaro"`, `"Rrá-ro"`). Não há registro no *harness* de que manipulações nos fonemas-alvo da síntese foram testadas para contornar o som do "R" forte em português, que é notoriamente difícil para *features* treinadas em inglês.

## 4. Augmentation Insuficiente para o Caso de Uso

O projeto especifica: *"Pescaria/esporte com o telefone guardado no bolso, mãos ocupadas"*.
O ACAV apenas aplica ruídos adversários para evitar *False Positives*. Para evitar *False Negatives* (o problema atual), o treinamento sintético deve incluir **Domain Randomization**: os áudios TTS devem ser ativamente distorcidos com RIRs (Room Impulse Responses), filtros *Low-Pass* simulando tecido/bolso e sobreposição de ruídos ambientes severos (vento, água). O documento não garante que o pipeline do RunPod aplicou essas degradações extremas ao conjunto de treino positivo.

---

## 5. Diretrizes para Retomada (O que DEVE ser feito antes de mudar o Produto)

A sugestão final do documento original (Mudar para "Raro Câmera") é prematura e fere o *Blueprint* por conveniência de implementação. Como agente autônomo e responsável pela arquitetura, você não deve mudar as regras do negócio até exaurir as técnicas de Engenharia de Dados. 

**O Checklist Obrigatório (Apenas Mude para "Opção A" se isto falhar):**

1. **Geração de Dataset Real:** O dono DEVE gravar entre 50 e 100 amostras da palavra "Raro". Variando distância, entonação (sussurro, grito) e ruído de fundo.
2. **Treino Híbrido Obrigatório:** Volte ao RunPod. Misture os 4000 *samples* sintéticos do VoxCPM com os 100 áudios reais, aplicando um peso (multiplicador) de 3x a 5x nos reais.
3. **Domain Randomization Ativo:** Aplique filtros simulando a abafamento do microfone no bolso aos dados positivos.
4. **Testes de Pronúncia TTS:** Rode um lote menor alterando a *target_phrase* para variações fonéticas (`"Haaro"`, etc.) e avalie se as extrações de características (features) mapeiam melhor o sotaque humano.

**Conclusão:** O background no iOS está 100% provado. O obstáculo atual é puramente a ausência da voz alvo no dataset de treinamento de um classificador binário sensível. Execute o treino híbrido.
