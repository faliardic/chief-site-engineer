# Chief Site Engineer Mobil Gizlilik Politikası

**Sürüm:** 0.1.0 release candidate
**Son güncelleme:** 20 Temmuz 2026

Chief Site Engineer (CSE), tek kullanıcılı ve local-first bir şantiye saha
asistanıdır. Ajanda, hatırlatıcı, puantaj, beton paketi, fotoğraf/dosya eki ve
yedek verileri uygulamanın cihaz-içi alanında işlenir. CSE geliştiricisinin bu
verileri alan bir sunucusu, kullanıcı hesabı, analytics, reklam, tracking veya
cloud sync hizmeti yoktur.

## İşlenen veriler

Kullanıcı; proje ve saha notları, personel/ekip adları, puantaj, beton döküm
bilgileri, hatırlatıcılar ve kendi seçtiği fotoğraf/dosyaları kaydedebilir. Bu
veriler yalnız uygulama işlevini sağlamak için cihazda tutulur. Geliştiriciye
iletilmez ve geliştirici tarafından toplanmaz.

## İzinler

- Kamera yalnız kullanıcının başlattığı kanıt fotoğrafı çekimi için istenir.
- Fotoğraf ve dosya seçimi sistem seçicileriyle tekil kullanıcı seçimine
  dayanır; geniş galeri/depolama izni istenmez.
- Bildirim izni yalnız cihazdaki kullanıcı planlı tek-seferlik veya tekrarlayan
  hatırlatıcıları göstermek için istenir.
- Cihaz açılış bildirimi, bekleyen yerel hatırlatıcıların yeniden kurulması
  içindir.
- Android'in kullanıcı tarafından yönetilen exact alarm özel erişimi, yalnız
  kullanıcının belirlediği yerel saha hatırlatıcısını uygulama kapalıyken
  güvenilir zamanda teslim etmek için istenir. `USE_EXACT_ALARM`, foreground
  service, cloud push veya internet kullanılmaz.

İzin reddi kaydı silmez; ilgili kamera, seçim veya bildirim işlemi kullanıcıya
anlaşılır sonuçla kapanır.

## Paylaşım ve dışa aktarma

CSE kendiliğinden veri göndermez. Kullanıcı açıkça paylaş/export işlemi
başlatırsa seçilen çıktı işletim sisteminin paylaşım ekranına teslim edilir.
Kullanıcının seçtiği hedef uygulamanın veri işleme ve aktarım koşulları o hedef
uygulamanın sorumluluğundadır.

## Yedek ve silme

`.csebackup` tam yedeği kullanıcı parolasıyla şifrelenir. Parola geliştiriciye
gönderilmez, saklanmaz ve **kurtarılamaz**. Parola unutulursa yedek açılamaz.
Uygulama kaldırılmadan, cihaz sıfırlanmadan veya release/test imzası
değiştirilmeden önce doğrulanmış bir `.csebackup` alınmalıdır. Uygulamanın
silinmesi cihaz-içi uygulama alanını işletim sistemi kurallarına göre silebilir.

Android otomatik şifresiz OS cloud backup kapalıdır. CSE'nin taşınabilir veri
sürekliliği sözleşmesi parola korumalı `.csebackup` akışıdır.

## Ağ, analytics ve reklam

Release runtime `INTERNET` izni istemez. Analytics, reklam, crash telemetry,
tracking SDK'sı veya gizli ağ endpoint'i içermez. Bu politika ileride ağ veya
veri toplama davranışı eklenirse uygulama yayımlanmadan önce güncellenmelidir.

## İletişim ve yayın notu

Bu tracked metin public bir URL'ye taşınabilir kanıt kaynağıdır. Issue #191
Play Console veya App Store Connect gönderimi ve public hosting işlemi yapmaz.
