import wave, numpy as np, os, json

SRC = "/tmp/raro_rec/full_16k.wav"
OUT = "/tmp/raro_rec/clips"
os.makedirs(OUT, exist_ok=True)
SR = 16000

# Mapa de regioes (descoberto via whisper-cli token timestamps):
#   POSITIVO "Raro": 1.0s ate 60.0s
#   NEGATIVO iscas:  60.0s ate 108.2s
# A regiao final (108s+) e silencio/[MUSICA] -> descartar.
POS_RANGE = (1.0, 60.0)
NEG_RANGE = (60.0, 108.2)

def read_wav(path):
    w = wave.open(path, 'rb')
    raw = w.readframes(w.getnframes()); w.close()
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32)

def write_wav(path, samples_i16):
    w = wave.open(path, 'wb')
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(samples_i16.astype(np.int16).tobytes()); w.close()

x = read_wav(SRC)
N = len(x)

# Energia em janelas de 20ms
WIN = int(0.02 * SR)  # 320
n_win = N // WIN
rms = np.zeros(n_win)
for i in range(n_win):
    seg = x[i*WIN:(i+1)*WIN] / 32768.0
    rms[i] = np.sqrt(np.mean(seg*seg) + 1e-12)

# Limiar adaptativo: ruido de fundo = percentil 20; fala = acima de 4x esse piso
floor = np.percentile(rms, 20)
peak = np.percentile(rms, 95)
thresh = max(floor * 3.0, floor + 0.15*(peak - floor))

voiced = rms > thresh

# Agrupa janelas voiced contiguas (com tolerancia de 2 janelas = 40ms de gap)
MIN_GAP = 3   # janelas de silencio para separar elocucoes
MIN_DUR = 8   # min 160ms de fala (~8 janelas) para contar como clip
segments = []
i = 0
while i < n_win:
    if voiced[i]:
        start = i
        gap = 0
        j = i
        while j < n_win and (voiced[j] or gap < MIN_GAP):
            if voiced[j]:
                gap = 0
                end = j
            else:
                gap += 1
            j += 1
        dur = end - start + 1
        if dur >= MIN_DUR:
            segments.append((start*WIN, (end+1)*WIN))
        i = j
    else:
        i += 1

def region_of(start_sample):
    t = start_sample / SR
    if POS_RANGE[0] <= t < POS_RANGE[1]:
        return "pos"
    if NEG_RANGE[0] <= t < NEG_RANGE[1]:
        return "neg"
    return "drop"

# Padding de 80ms antes/depois para o clip respirar
PAD = int(0.08 * SR)
manifest = []
pos_i = neg_i = 0
for (s, e) in segments:
    reg = region_of(s)
    if reg == "drop":
        continue
    a = max(0, s - PAD); b = min(N, e + PAD)
    clip = x[a:b]
    dur_s = (b - a) / SR
    if dur_s > 2.5:  # clip longo demais = provavelmente 2+ elocucoes coladas, marca
        tag = "LONG"
    else:
        tag = "ok"
    if reg == "pos":
        pos_i += 1
        name = f"pos_{pos_i:03d}.wav"
    else:
        neg_i += 1
        name = f"neg_{neg_i:03d}.wav"
    write_wav(os.path.join(OUT, name), clip)
    manifest.append({"name": name, "region": reg, "t_start": round(a/SR,2),
                     "t_end": round(b/SR,2), "dur": round(dur_s,2), "tag": tag})

json.dump(manifest, open("/tmp/raro_rec/manifest.json","w"), indent=2)
print(f"Total elocucoes detectadas: {len(segments)}")
print(f"  POSITIVO (Raro):  {pos_i}")
print(f"  NEGATIVO (iscas): {neg_i}")
print(f"  threshold={thresh:.4f} floor={floor:.4f} peak={peak:.4f}")
longs = [m for m in manifest if m['tag']=='LONG']
print(f"  clips >2.5s (suspeitos de colagem): {len(longs)}")
for m in longs:
    print(f"    {m['name']} {m['t_start']}-{m['t_end']} ({m['dur']}s)")
