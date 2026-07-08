# Adim 134 - Record ID Soft Validation Plan

## Soft validation neden migration dostudur?

Soft validation, mevcut veriyi veya mevcut testleri hemen reddetmeden uyumsuzluklari gorunur hale getirir.

Migration dostu olmasinin nedeni budur: Sistem eski ID orneklerini calistirmaya devam eder, ama ayni zamanda hangi orneklerin canonical formata uymadigi raporlanabilir.

Bu projede `NCR-001`, `REC-1`, `file-att-001` ve `audit-001` gibi legacy ornekler hala anlamlidir. Bunlari bir anda reddetmek yerine once diagnostic olarak izlemek daha guvenlidir.

## Warning uretmek ile veri reddetmek arasindaki fark nedir?

Warning uretmek, "bu veri dikkat gerektiriyor" demektir.

Veri reddetmek ise "bu veri sisteme giremez" demektir.

Soft validation warning uretir. Hard validation veri reddeder.

Ornek:

```text
target_record_type=attachment
target_record_id=file-att-001
severity=warning
message=Legacy attachment id prefix kullaniliyor.
```

Bu durumda kayit reddedilmez. Sadece rapor veya kalite kontrol ciktisinda gorunur hale gelir.

## Audit log guvenilirligi icin neden once diagnostic gerekir?

Audit log, sahadaki olaylarin ve kayit baglantilarinin kanit zinciridir.

Bu zincir cok gevsek kalirsa raporlanabilirlik zayiflar. Cok erken sertlestirilirse eski ama anlamli kayitlar reddedilir.

Diagnostic katmani bu iki uc arasinda guvenli bir ara basamaktir. Once sistem hangi ID'lerin canonical, hangilerinin legacy, hangilerinin bilinmeyen oldugunu gosterir. Sonra ekip gercek veri davranisini gorerek karar verir.

## Hard validation neden en sona birakilir?

Hard validation hata uretir ve model olusturmayi engeller.

Bu yuzden hard validation icin sunlar net olmalidir:

- Merkezi ID sozlesmesi.
- Target type / ID family mapping.
- Legacy ID politikasi.
- Test ornek standardizasyonu.
- Migration stratejisi.
- Diagnostic cikti davranisi.

Bu bilgiler netlesmeden hard validation eklemek testleri ve ilerideki veriyi gereksiz yere kirabilir.

## CSE'de bu yaklasim neden guvenilir veri omurgasina hizmet eder?

CSE'nin hedefi hizli kayit, guvenilir arsiv ve kanit zinciri kurmaktir.

Record ID soft validation bu hedefe su sekilde hizmet eder:

- ID tutarsizliklarini erken gorunur yapar.
- Eski kayitlari bir anda reddetmez.
- Audit raporlarina kalite sinyali ekleyebilir.
- Handover package veya export on kontrolu icin zemin hazirlar.
- Hard validation'a gecmeden once veri davranisini anlamayi saglar.

Bu yaklasim, otomasyon veya AI katmanindan once guvenilir veri omurgasini guclendirir.

## Bu adimin ana dersi

Bir sistemi guvenilir yapmak her zaman hemen hata firlatmak anlamina gelmez.

Bazen en dogru ilk adim, veriyi reddetmeden sorunlari gorunur hale getirmektir.

Soft validation bu yuzden CSE icin guvenli bir ara katmandir: once gor, sonra standardize et, en son sertlestir.
