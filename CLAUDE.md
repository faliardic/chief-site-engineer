# CLAUDE.md — Claude Code bootstrap

Bu dosya Claude Code'a özel ince bir bootstrap/router'dır. Kanonik CSE gerçeğini
kopyalamaz; yalnız hangi sırayla nereye bakılacağını gösterir. Çelişkide her
zaman aşağıda linklenen kaynaklar ve current GitHub gerçeği geçerlidir, bu dosya
değil.

Claude Code, bu repodaki **Repository Execution Agent** rolünün current
provider'ıdır (bkz. `AGENTS.md` §1). Codex, aynı role gelecekte geri
bağlanabilecek uyumlu bir alternatif provider'dır. Provider hangisi olursa
olsun yetki, risk lane, topology, validation, Git ve publication kuralları
`AGENTS.md` ve onun yönlendirdiği protokollerden gelir; bu dosyadan değil.

## Zorunlu okuma sırası

1. @AGENTS.md — tek zorunlu giriş noktası: güncel gerçek, aktör dispatch'i, risk lane, süre bütçesi, Git/publication sınırları.
2. @.agents/ads/CORE.md — pinned ADS çekirdeği (source-pinned; CSE bunu fork etmez, yalnız `Execution Agent` ile provider-neutral eşler — bkz. `AGENTS.md` §1).
3. Göreve uygun `.agents/skills/ads-*/SKILL.md` (`ads-deliver`, `ads-resume`, `ads-review`, `ads-scout` — hangisi görevin rolüyse).
4. Current GitHub `master`, açık Issue/PR ve varsa görevi veren canonical comment; bunlar task authority'sidir, Claude'un kendi planı değil.
5. @ROADMAP.md — yalnız sıradaki production/release işi seçilecekse.

Değişen sözleşmenin gerektirdiği koşullu protokol (Unified Source, Project
Instructions, Workflow Acceleration, Minimum Validation, Model Routing,
Execution Agent Instruction Comment Protocol) `AGENTS.md` §2'deki tabloya göre
ayrıca okunur.

## Değişmeyen sınırlar (özet — otorite `AGENTS.md`'dedir)

- Task authority GitHub Issue/PR/canonical comment'tir; Claude kendi planından
  yetki üretmez.
- Risk lane (`FAST | STANDARD | CRITICAL`), topology (`SINGLE | PARALLEL_READ`)
  ve execution time budget görev başında verilir ve execution boyunca kilitlidir;
  Claude bunları kendiliğinden değiştirmez veya genişletmez.
- `PARALLEL_READ` içinde yalnız `Builder/WRITE` production dosyasına yazar.
  Claude subagent desteği kullanılsa da `Scout/READ` ve `Reviewer/READ` kesin
  read-only kalır; hiçbir subagent yalnızca bu yetenek var diye WRITE kazanmaz.
- Exact allowlist dışında dosya değiştirilmez; kapsam kendiliğinden genişletilmez.
- Force-push, destructive `reset`/`clean`/`stash`, hard-delete ve sessiz gate
  bypass'ı yasaktır. MAIN/production paket ve gerçek owner verisi açık CRITICAL
  authority olmadan okunmaz/değiştirilmez.
- Repository defaults blanket permission bypass kullanmaz (ör.
  `--dangerously-skip-permissions` çalıştırılmaz); bu dosya veya `.claude/`
  altında böyle bir bypass varsayılan olarak tanımlanmaz.
- Teslim, `AGENTS.md` §8 ve ilgili protokollerdeki final handoff/evidence
  sözleşmesini kullanır (değişen davranış, changed paths, automated/manual
  validation durumu, commit/push, PR ve Issue disposition); format Codex'ten
  Execution Agent'a taşınmıştır, içerik aynıdır.

## Claude-specific sınır

Claude Code'a özgü izin/hook/ayar yalnız bu dosyada veya `.claude/` altında
tutulur; CSE'nin genel authority modeli sayılmaz ve `AGENTS.md`/ADS/protokol
kurallarını gevşetmez.
