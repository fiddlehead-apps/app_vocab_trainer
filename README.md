# Sola Vocab (iOS)

Auf Deutsch heißt die App **Sola Vokabeln**.

Englisch-Vokabeltrainer für Kinder: Buchseite fotografieren, neue Wörter auswählen, üben.
Alle 10 richtigen Antworten erscheint ein zufälliger Italian Brainrot. SwiftUI, keine
Abhängigkeiten, iPhone und iPad, ab iOS 18 (läuft also auf dem iPhone 12 Pro), Deutsch und
Englisch.

* Kein Server, kein Konto. Texterkennung (Vision), Übersetzung (Apples Translation-Framework)
  und Sprachausgabe laufen auf dem Gerät.
* Gleicher Look wie die anderen Sola-Apps, Akzentfarbe Traubenlila.

## Was die App kann

**Neue Wörter scannen:** drei Wege – *Buchseite scannen* (VisionKit-Dokumentkamera, findet
die Seitenränder und begradigt), *Foto aufnehmen* oder *Aus Fotos wählen* (bis zu 10).
Vision liest Englisch plus die eingestellte Muttersprache.

* **Vokabellisten** (Englisch | Lautschrift | Deutsch nebeneinander): Ab drei solchen Zeilen
  gilt die Seite als Liste, die Paare werden direkt übernommen. Lautschrift in eckigen
  Klammern und Beispielsätze in der Mitte werden übersprungen. Schief gehaltene Fotos sind
  kein Problem: die Neigung wird aus den erkannten Zeilen geschätzt und herausgerechnet.
* **Fließtext:** Aus dem englischen Text werden Nomen, Verben, Adjektive und Adverbien in der
  Grundform gezogen („children" → „child", „escaped" → „escape"), ohne Namen. Sie erscheinen
  als Chips zum Antippen. Sehr häufige Wörter (*CommonWords*, ca. 350) sind versteckt,
  lassen sich aber einblenden. Wörter, die schon in der Liste stehen, fehlen.
* Angetippte Wörter werden mit Apples On-Device-Übersetzung übersetzt (beim ersten Mal lädt
  iOS das Sprachpaket, danach offline). Alles bleibt editierbar, Wörter lassen sich auch von
  Hand ergänzen. Gespeichert wird in eine *Liste* (Standard „Scan 18. Okt.").

**Üben** (Startbildschirm): Wortauswahl *Alle Wörter*, *Knifflige Wörter* (falsch beantwortet
und noch nicht gelernt) oder eine Liste. Dann *Gemischt* oder eine bestimmte Übung:

| Übung | Ablauf |
| --- | --- |
| Was heißt das? | Englisches Wort (wird vorgelesen), 4 Übersetzungen zur Wahl |
| Welches Wort ist es? | Übersetzung, 4 englische Wörter zur Wahl |
| Schreib es | Übersetzung, englisches Wort tippen. Ein Tippfehler → „Fast!" und zweiter Versuch. Tipp-Knopf deckt Buchstaben auf (höchstens die Hälfte) |
| Hören und schreiben | Wort wird vorgelesen (🐢 = langsam), tippen |
| Buchstabenrätsel | Übersetzung, englisches Wort aus gemischten Buchstaben bauen |
| Finde die Paare | 4 englische Wörter und 4 Übersetzungen verbinden; richtig, wenn kein Paar daneben ging |

Wahl- und Paar-Übungen brauchen mindestens 4 Wörter. Beim Tippen zählt „to feed" = „feed",
„an apple" = „apple", und bei „go, went, gone" jede Form. Jede Antwort wird von der App
geprüft – Selbsteinschätzung („wusste ich") gibt es nur bei den Karteikarten, und die zählen
nicht.

Wörter wandern durch 6 Leitner-Fächer (richtig +1, falsch −2); niedrige Fächer kommen öfter
dran, die letzten drei Wörter nicht gleich wieder. In der Wortliste als 0–3 Sterne.

**Brainrots:** Jede richtige Antwort füllt den Balken „Nächster Brainrot", nach 10 (in den
Einstellungen 5–30) erscheint einer im Vollbild mit Konfetti, die italienische Stimme sagt
den Namen. Noch nicht gefundene kommen mit 75 % Wahrscheinlichkeit zuerst dran. Der Zähler
zählt über Sitzungen hinweg und setzt bei falschen Antworten nicht zurück. 28 Figuren sind
eingebaut (Tralalero Tralala, Bombardiro Crocodilo, Tung Tung Tung Sahur, …), aus Emoji
gezeichnet und animiert, jede mit einer kurzen englischen Beschreibung (antippen zeigt sie
auf Deutsch, *Vorlesen* liest sie auf Englisch vor – kleine Leseübung). *Sammlung* zeigt
alle, nicht gefundene als „?".

**Eigene Bilder** (Einstellungen → Brainrots): echte Brainrot-Bilder aus Fotos mit Namen
hinzufügen; sie kommen genauso als Belohnung und in die Sammlung.

**Einstellungen:** Muttersprache (18 Sprachen, Standard Gerätesprache, sonst Deutsch),
britische oder amerikanische Stimme, Brainrot-Takt, Lernfortschritt zurücksetzen.

## Daten

Eine JSON-Datei `vocab.json` in den Dokumenten der App (Wörter, Fortschritt, Sammlung) plus
`Brainrots/<id>.jpg` für eigene Bilder (900 px). Einstellungen in UserDefaults. Kein
iCloud-Sync.

## Bauen

`../build-sola-apps.sh` baut alle Sola-Apps und installiert sie auf dein iPhone (Sola Vocab
gehört dazu, zum Testen); `../build-sola-apps.sh vocab` nur diese App. Fürs iPhone 12 Pro
des Sohns die Geräte-ID mitgeben:

```sh
xcrun devicectl list devices                    # ID des iPhone 12 Pro
DEVICE_ID=<id> ../build-sola-apps.sh vocab
```

Beide Geräte haben getrennte Daten (Wörter, Fortschritt, Sammlung); Testen auf dem eigenen
iPhone verändert nichts beim Sohn.

Bundle-ID und Team kommen aus `Config/Config.xcconfig` (`eu.fiddlehead.sola.vocab`, Projekt
`SolaVocab.xcodeproj`). Bis Oktober 2026 hieß die App intern `org.christophschneider.vocab`:
der erste Build mit der neuen ID installiert sich als **eigene App** daneben und fängt mit
leeren Daten an. Die alte App mit Wörtern und Sammlung bleibt, bis man sie löscht.

Für den Simulator: `../build-sola-apps.sh --sim vocab`. In Debug-Builds öffnet
`-debugScreen practice-letters` (oder `scan`, `settings`, `reveal-tralalero`) direkt einen
Bildschirm, für Screenshots.

Icon neu erzeugen: `python3 tools/make_icon.py` (braucht Pillow).

## Dateien

| Datei | Inhalt |
| --- | --- |
| `TextExtractor.swift` | Vision-Texterkennung, Zeilen bilden (mit Neigungskorrektur), Paare und Einzelwörter finden |
| `ScanView.swift` / `ReviewView.swift` | Foto-Quellen, Auswahl der Wörter, Übersetzung |
| `Practice.swift` | Übungsarten, Fragen-Auswahl (Leitner), Übungsbildschirm, Brainrot-Balken |
| `Exercises.swift` | die sechs Übungen |
| `Brainrot.swift` | Figuren, Zeichnung und Animation, Belohnungsbildschirm, Sammlung |
| `Store.swift` | Daten, Speichern, Leitner-Fächer, Brainrot-Auswahl |
| `Models.swift` | Datentypen, Einstellungen, Antwortprüfung |
