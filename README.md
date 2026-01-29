# SMB-for-Watch

Eine Apple Watch App zum Abrufen, Abspielen und Herunterladen von Inhalten (z.B. Musik) von entfernten Servern über SMB, NFS, FTP und WebDAV.

## Features

- **Multi-Protokoll Unterstützung**: Verbindung zu Servern über SMB, NFS, FTP und WebDAV
- **Datei-Browser**: Durchsuchen von entfernten Server-Verzeichnissen
- **Audio-Player**: Direktes Abspielen von Musik-Dateien vom Server
- **Download-Manager**: Herunterladen von Dateien auf die Apple Watch
- **Server-Verwaltung**: Speichern und Verwalten mehrerer Server-Konfigurationen

## Verwendung

1. **Server hinzufügen**: Tippen Sie auf das "+" Symbol und geben Sie die Server-Details ein
2. **Verbinden**: Wählen Sie einen Server aus der Liste und tippen Sie auf "Verbinden"
3. **Dateien durchsuchen**: Navigieren Sie durch die Verzeichnisse auf dem Server
4. **Musik abspielen**: Tippen Sie auf eine Audio-Datei zum direkten Abspielen
5. **Herunterladen**: Tippen Sie auf das Download-Symbol neben einer Datei

## Unterstützte Protokolle

- **SMB/CIFS**: Windows-Freigaben und Samba-Server
- **NFS**: Network File System
- **FTP**: File Transfer Protocol
- **WebDAV**: Web Distributed Authoring and Versioning

## Technische Details

- **Plattform**: watchOS 10.0+
- **Sprache**: Swift 5.0
- **Framework**: SwiftUI, AVFoundation, URLSession

## Hinweise

- Für SMB und NFS wird in der Produktionsversion eine native Bibliothek benötigt (z.B. libsmbclient)
- Die aktuelle Implementierung verwendet URLSession für FTP und WebDAV
- Audio-Dateien werden temporär heruntergeladen für die Wiedergabe
- Downloads werden im Dokumenten-Verzeichnis der App gespeichert

## Installation

1. Öffnen Sie das Projekt in Xcode
2. Wählen Sie ein Watch-Simulator oder eine physische Apple Watch
3. Drücken Sie Cmd+R zum Builden und Ausführen

## Lizenz

Dieses Projekt ist für den persönlichen Gebrauch erstellt.