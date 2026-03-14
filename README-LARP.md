# Telegram iOS - Build IPA via GitHub (sans Mac)

Ton projet TBuild (c:\TBuild) n'a **pas été modifié**.

## Méthode : GitHub Actions

GitHub a des serveurs Mac. On peut builder l'app **dans le cloud** sans avoir de Mac.

### Étapes

1. **Crée un repo GitHub** (si tu n'en as pas)
   - github.com → New repository
   - Nom : `telegram-ipa` (ou autre)

2. **Pousse ce dossier sur GitHub**
   ```
   cd "F:\ipa telegram"
   git remote add origin https://github.com/TON_USERNAME/telegram-ipa.git
   git add .
   git commit -m "Initial"
   git push -u origin main
   ```
   (Remplace TON_USERNAME par ton pseudo GitHub)

3. **Ajoute les secrets** (obligatoires pour que l'app fonctionne)
   - Va sur ton repo → **Settings** → **Secrets and variables** → **Actions**
   - **New repository secret** pour chacun :
     - `API_ID` — va sur https://my.telegram.org/apps pour l'obtenir
     - `API_HASH` — même page

4. **Lance le build**
   - Onglet **Actions** → **Build Telegram IPA** → **Run workflow**
   - Attends 30–60 min

5. **Télécharge le résultat**
   - Quand c'est vert → clique sur le run → **Artifacts** → télécharge **Telegram-build**

### ⚠️ Simulateur vs iPhone

Le workflow actuel build pour le **simulateur** (.app). Ça ne s'installe pas sur un vrai iPhone.

Pour un **IPA installable sur iPhone**, il faut :
- Un compte Apple Developer (gratuit ou 99$/an)
- Exporter ton certificat + provisioning profile
- Les ajouter en secrets GitHub
- Adapter le workflow pour la signature

Si ton pote a réussi, demande-lui quels secrets il a utilisés (certificat, profile, etc.).
