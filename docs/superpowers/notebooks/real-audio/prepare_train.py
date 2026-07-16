import wave, numpy as np, os, json, shutil

CLIPS = "/tmp/raro_rec/clips"
OUT = "/tmp/raro_rec/train_real"
SR = 16000

# Peso 3x (best practice CoreWorxLab/openWakeWord: reais weighted 3x).
# Implementado por DUPLICACAO (lib trava positivo em weight 1.0 — trainer.py:291).
# Cada copia recebe augmentation aleatorio diferente no RunPod (RIR/EQ por-clip).
WEIGHT = 3
# NAO reservar TEST real: o augment DEGRADA o test set (augment.py:127-131,
# features.py:47) — test real nao fica limpo, entao nao serve de gate honesto.
# Gate honesto = recall offline Python ($0) com a voz CRUA contra o .onnx final.
# Logo: TODOS os 40 positivos + 31 negativos vao pro TRAIN (mais voz real = melhor).
TEST_FRACTION = 0.0

def read_wav(path):
    w = wave.open(path, 'rb'); raw = w.readframes(w.getnframes()); w.close()
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32)

validated = json.load(open("/tmp/raro_rec/validated.json"))

# Filtro de qualidade: descartar clips muito curtos (<0.3s = provavel meio-fonema)
# ou com rms quase nulo (vazio). Mantemos os demais.
def keep(m):
    if m["dur"] < 0.30: return False
    if m["rms"] < 0.012: return False
    return True

pos = [m for m in validated if m["region"]=="pos" and keep(m)]
neg = [m for m in validated if m["region"]=="neg" and keep(m)]
pos_drop = [m for m in validated if m["region"]=="pos" and not keep(m)]
neg_drop = [m for m in validated if m["region"]=="neg" and not keep(m)]

# Sem split: tudo vai pro train (test real seria degradado pelo augment).
pos_train, pos_test = sorted(pos, key=lambda x: x["t_start"]), []
neg_train, neg_test = sorted(neg, key=lambda x: x["t_start"]), []

# Limpa e recria as pastas de saida (so as NOSSAS, nao mexe no RunPod)
for d in ["positive_train","positive_test","negative_train","negative_test"]:
    p = os.path.join(OUT, d)
    if os.path.exists(p): shutil.rmtree(p)
    os.makedirs(p, exist_ok=True)

# IMPORTANTE: naming clip_NNNNNN.wav (6 digitos) com indice ALTO (900000+) pra
# NAO colidir com os sinteticos gerados pelo RunPod (que vao 0..n_samples).
def emit(arr, subdir, base_index, duplicate):
    idx = base_index
    written = 0
    for m in arr:
        src = os.path.join(CLIPS, m["name"])
        samples = read_wav(src)
        for _ in range(duplicate):
            dst = os.path.join(OUT, subdir, f"clip_{idx:06d}.wav")
            w = wave.open(dst, 'wb')
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes(samples.astype(np.int16).tobytes()); w.close()
            idx += 1; written += 1
    return written

# Positivos: peso 3x no TRAIN; test sem duplicar (validacao limpa)
w_pos_tr = emit(pos_train, "positive_train", 900000, WEIGHT)
w_pos_te = emit(pos_test,  "positive_test",  910000, 1)
# Negativos (iscas): tambem peso 3x no train (sao os hard-negatives valiosos)
w_neg_tr = emit(neg_train, "negative_train", 920000, WEIGHT)
w_neg_te = emit(neg_test,  "negative_test",  930000, 1)

print("="*60)
print("PREPARACAO DOS CLIPS REAIS (naming clip_NNNNNN.wav, 6 digitos)")
print("="*60)
print(f"POSITIVOS 'Raro':  {len(pos)} bons / {len(pos_drop)} descartados")
print(f"  train: {len(pos_train)} takes x{WEIGHT} = {w_pos_tr} arquivos")
print(f"  test:  {len(pos_test)} takes x1 = {w_pos_te} arquivos")
print(f"NEGATIVOS iscas:   {len(neg)} bons / {len(neg_drop)} descartados")
print(f"  train: {len(neg_train)} takes x{WEIGHT} = {w_neg_tr} arquivos")
print(f"  test:  {len(neg_test)} takes x1 = {w_neg_te} arquivos")
print()
if pos_drop:
    print("Positivos descartados (curtos/vazios):")
    for m in pos_drop: print(f"  {m['name']} dur={m['dur']} rms={m['rms']}")
if neg_drop:
    print("Negativos descartados:")
    for m in neg_drop: print(f"  {m['name']} dur={m['dur']} rms={m['rms']}")
print()
print(f"Saida em: {OUT}/")
print("Indices: pos_train 900000+, pos_test 910000+, neg_train 920000+, neg_test 930000+")
print("(indices altos = sem colisao com sinteticos 0..n_samples)")
