# Docker whatsapp-webjs

Image `node:24-bookworm-slim`, avec `whatsapp-web.js`,
Puppeteer / Chrome et `qrcode-terminal`. Les dépendances de `package.json`
sont installées automatiquement pendant la construction.

Cette image fournit un environnement pour exécuter un bot WhatsApp pour publier
des messages automatiquement dans un groupe WhatsApp.

L'image ne contient pas le bot en lui-même. Son code, son calendrier Google
Sheets et sa configuration Cloud Run sont gérés dans un dépôt GitHub séparé.
<!-- Ajouter ici le lien vers le dépôt du bot dès sa création. -->

## Construction

Construire l'image localement :

```sh
docker build -t docker-whatsapp-webjs .
```

## Utilisation

Depuis le dossier du projet du bot, monter `bot.cjs` dans `/app/bot.cjs`.
Par exemple, pour générer le calendrier sans connexion à WhatsApp :

```sh
docker run --rm -v "$PWD/bot.cjs:/app/bot.cjs:ro" docker-whatsapp-webjs calendar
```

Ou utiliser l'image publiée sur Docker Hub :

```sh
docker run --rm -v "$PWD/bot.cjs:/app/bot.cjs:ro" drdpham/docker-whatsapp-webjs:latest calendar
```

Pour ouvrir un shell :

```sh
docker run --rm -it --entrypoint /bin/sh docker-whatsapp-webjs
```

L'appairage WhatsApp et le déploiement Google Cloud sont documentés dans le
projet du bot.

## Maintenance

Dans **Settings > Secrets and variables > Actions** du dépôt GitHub, ajouter :

- Secret `DOCKERHUB_USERNAME` : nom d'utilisateur Docker Hub.
- Secret `DOCKERHUB_TOKEN` : jeton Docker Hub autorisé à publier des images.
- Variable `DOCKERHUB_IMAGE` : `drdpham/docker-whatsapp-webjs`, sans tag.

Créer le jeton dans les paramètres du compte Docker Hub, sous **Personal access
tokens**. Pour le renouveler, remplacer le secret GitHub, puis révoquer l'ancien.
Ne jamais enregistrer le jeton dans Git.

Le workflow construit les pull requests vers `main` sans publication. Un push
sur `main` publie `latest` ; un tag Git comme `v1.0.0` publie le tag correspondant.
Un lancement manuel sur `main` reconstruit `latest`. Aucun déploiement Google Cloud
n'est effectué par ce dépôt.
