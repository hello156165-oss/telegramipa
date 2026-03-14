# Telegram IPA Build

Build Telegram pour iOS via GitHub Actions (sans Mac).

## Setup simulateur

1. Ajoute les secrets : **Settings** → **Secrets** → **Actions**
   - `API_ID` — https://my.telegram.org/apps
   - `API_HASH` — même page

2. Push sur main → le build simulateur se lance automatiquement

3. Télécharge l'artefact **Telegram-simulator** quand c'est vert.

## Build pour iPhone (compte Apple gratuit, 7 jours)

Sans compte Developer payant : l'app expire après 7 jours, tu la réinstalles.

### 1. Sur ton Mac (une fois, puis tous les 7 jours)

1. Ouvre **Xcode** → **Settings** → **Accounts** → ajoute ton Apple ID (gratuit)
2. Va sur https://developer.apple.com/account → **Certificates, Identifiers & Profiles**
3. **Identifiers** → crée un App ID avec bundle ID `org.telegram.build` (ou autre)
4. **Profiles** → crée un **Development** profile pour cet App ID
5. **Certificates** → crée un certificat **Apple Development** (si besoin)
6. Télécharge le profil (.mobileprovision) et le certificat
7. Dans **Keychain Access** : clic droit sur le certificat → **Export** → .p12 avec mot de passe

### 2. Convertir en Base64

```bash
base64 -i ton_certificat.p12 | pbcopy
# Colle dans le secret BUILD_CERTIFICATE_BASE64

base64 -i ton_profil.mobileprovision | pbcopy
# Colle dans le secret BUILD_PROVISION_PROFILE_BASE64
```

### 3. Secrets GitHub

Ajoute dans **Settings** → **Secrets** → **Actions** :

| Secret | Description |
|--------|-------------|
| `BUILD_CERTIFICATE_BASE64` | Certificat .p12 en base64 |
| `P12_PASSWORD` | Mot de passe du .p12 |
| `BUILD_PROVISION_PROFILE_BASE64` | Profil .mobileprovision en base64 |
| `KEYCHAIN_PASSWORD` | N'importe quel mot de passe (ex: `build`) |
| `TEAM_ID` | Ton Team ID (developer.apple.com → Membership) |
| `BUNDLE_ID` | (optionnel) `org.telegram.build` par défaut |

### 4. Lancer le build

**Actions** → **Build Telegram IPA** → **Run workflow** (manuel)

Le job **build-device** va tourner. Télécharge **Telegram-device** à la fin.
