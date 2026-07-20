# Chief Site Engineer Mobile Privacy Policy

**Version:** 0.1.0 release candidate
**Last updated:** 20 July 2026

Chief Site Engineer (CSE) is a single-owner, local-first construction field
assistant. Agenda, reminders, attendance, concrete pour packages, selected
attachments, and backups are processed in the app's on-device storage. The
developer operates no server that receives this data and provides no account,
analytics, advertising, tracking, or cloud-sync service.

## Data processed on the device

The user may save project and field notes, workforce names, attendance,
concrete-pour information, reminders, and photos/files they explicitly select.
The app uses this content only to provide on-device functionality. It is not
transmitted to or collected by the developer.

## Permissions

- Camera access is requested only for a user-initiated evidence photo.
- Photos and files are selected through system pickers; the app does not ask
  for broad media or storage access.
- Notification permission is used only for local user-scheduled one-time or
  recurring reminders.
- Boot completion is used to restore pending local reminder scheduling.
- Android's user-managed exact-alarm special access is requested only to
  deliver a user-specified local field reminder reliably while the app is
  closed. The app does not use `USE_EXACT_ALARM`, a foreground service, cloud
  push, or an internet dependency.

Denying permission does not delete the underlying record.

## User-initiated sharing

CSE does not transmit data by itself. When the user explicitly starts a share
or export, the selected output is handed to the operating system's share
sheet. The destination app selected by the user is responsible for its own
processing and transfer practices.

## Backup and deletion warning

A `.csebackup` full backup is encrypted with a user-provided password. The
password is not sent to or stored by the developer and **cannot be recovered**.
If it is forgotten, the backup cannot be opened. Create and verify a backup
before uninstalling the app, resetting the device, or changing release/test
signing. Uninstalling can remove the app's on-device data under operating
system rules.

Unencrypted Android OS cloud backup is disabled. The password-protected
`.csebackup` flow is CSE's portable continuity contract.

## Network, analytics, and advertising

The release runtime does not request Android `INTERNET` permission and contains
no analytics, advertising, crash telemetry, tracking SDK, or hidden endpoint.
This policy must be updated before release if a future version changes those
facts.

## Publication note

This tracked document is the source for a future public privacy-policy URL.
Issue #191 does not publish a website or submit data to Play Console or App
Store Connect.
