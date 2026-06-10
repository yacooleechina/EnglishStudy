# English Study

SwiftUI iPhone/iPad app prototype for reviewing words from Eudic wordbooks.

## Features

- Store Eudic OpenAPI `Authorization` securely in Keychain.
- Sync Eudic wordbook categories and words.
- Check Chinese meaning answers against synced explanations.
- Record English pronunciation and grade it with Apple Speech recognition.
- Adaptive SwiftUI layout for iPhone and iPad.

## Eudic Setup

1. Open `https://my.eudic.net/OpenAPI/Authorization`.
2. Copy the OpenAPI authorization value, usually in the form `NIS xxxxx`.
3. Run the app, open Settings, paste the value, then tap Save and Sync.

Do not put your Eudic password in this project.

## Next Improvements

- Add Eudic's pronunciation scoring API or Azure Pronunciation Assessment for word-level and phoneme-level scoring.
- Add spaced repetition scheduling.
- Add offline cache and review history.
