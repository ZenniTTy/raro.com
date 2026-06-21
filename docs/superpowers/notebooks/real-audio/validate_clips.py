import wave, numpy as np, onnxruntime as ort, os, json

RES = "/Users/eduardorodrigues/Documents/Projetos/Clientes/vitor-workana/app-raro/apps/mobile/ios/Runner/Resources"
CLIPS = "/tmp/raro_rec/clips"

mel = ort.InferenceSession(f"{RES}/melspectrogram.onnx")
emb = ort.InferenceSession(f"{RES}/embedding_model.onnx")
clf = ort.InferenceSession(f"{RES}/raro.onnx")

AUDIO_STEP, MEL_WINDOW, MEL_STEP, EMB_COUNT = 1280, 76, 8, 16

def read_wav(path):
    w = wave.open(path, 'rb'); raw = w.readframes(w.getnframes()); w.close()
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0

def rms_of(samples):
    return float(np.sqrt(np.mean(samples*samples) + 1e-12))

def max_score(samples):
    sil = np.zeros(24000, dtype=np.float32)
    audio = list(np.concatenate([sil, samples, sil]))
    mel_frames, emb_buffer, mx = [], [], 0.0
    while len(audio) >= AUDIO_STEP:
        chunk = np.array(audio[:AUDIO_STEP], dtype=np.float32); audio = audio[AUDIO_STEP:]
        out = mel.run(["output"], {"input": chunk.reshape(1,-1)})[0].reshape(-1)
        for f in range(len(out)//32):
            mel_frames.append(out[f*32:(f+1)*32]/10.0 + 2.0)
        while len(mel_frames) >= MEL_WINDOW:
            window = np.array(mel_frames[:MEL_WINDOW], dtype=np.float32); mel_frames = mel_frames[MEL_STEP:]
            e = emb.run(["conv2d_19"], {"input_1": window.reshape(1,76,32,1)})[0].reshape(-1)
            emb_buffer.append(e)
            if len(emb_buffer) > EMB_COUNT: emb_buffer = emb_buffer[-EMB_COUNT:]
            if len(emb_buffer) == EMB_COUNT:
                stack = np.array(emb_buffer, dtype=np.float32).reshape(1,16,96)
                sc = float(clf.run(["score"], {"embeddings": stack})[0].reshape(-1)[0])
                if sc > mx: mx = sc
    return mx

manifest = json.load(open("/tmp/raro_rec/manifest.json"))
results = []
for m in manifest:
    s = read_wav(os.path.join(CLIPS, m["name"]))
    r = rms_of(s)
    sc = max_score(s)
    m2 = dict(m); m2["rms"] = round(r,4); m2["score"] = round(sc,4)
    results.append(m2)

json.dump(results, open("/tmp/raro_rec/validated.json","w"), indent=2)

pos = [r for r in results if r["region"]=="pos"]
neg = [r for r in results if r["region"]=="neg"]

def summ(name, arr):
    scs = [r["score"] for r in arr]
    rmss = [r["rms"] for r in arr]
    print(f"\n=== {name} (n={len(arr)}) ===")
    print(f"  score: min={min(scs):.3f} med={np.median(scs):.3f} max={max(scs):.3f}")
    print(f"  rms:   min={min(rmss):.4f} med={np.median(rmss):.4f} max={max(rmss):.4f}")

print("VALIDACAO DOS CLIPS no modelo raro.onnx ATUAL (treino 100% sintetico)")
summ("POSITIVO 'Raro'", pos)
summ("NEGATIVO iscas", neg)

# Flags de qualidade
print("\n=== FLAGS ===")
quiet_pos = [r for r in pos if r["rms"] < 0.01]
print(f"Positivos muito baixos (rms<0.01, possivel ruido/vazio): {len(quiet_pos)}")
for r in quiet_pos: print(f"  {r['name']} rms={r['rms']} score={r['score']} t={r['t_start']}")
loud_neg = [r for r in neg if r["score"] > 0.2]
print(f"Negativos que pontuam ALTO (>0.2, falso-positivo a treinar): {len(loud_neg)}")
for r in loud_neg: print(f"  {r['name']} score={r['score']} t={r['t_start']}")
# Top positivos por score (os que o modelo atual MENOS odeia)
print("\nTop 5 positivos por score (mais proximos de disparar hoje):")
for r in sorted(pos, key=lambda x:-x["score"])[:5]:
    print(f"  {r['name']} score={r['score']} rms={r['rms']} t={r['t_start']}-{r['t_end']}")
