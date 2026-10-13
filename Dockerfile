ARG NODE_IMAGE=node:24-bookworm-slim
FROM ${NODE_IMAGE}

ENV NODE_ENV=production \
    NODE_PATH=/opt/tools/node_modules \
    PUPPETEER_CACHE_DIR=/opt/puppeteer

# Chrome for Testing a besoin de ces bibliothèques Debian.
# tini gère les processus enfants ; tar/gzip servent au bot pour sa session.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates fonts-liberation tini tar gzip \
      libasound2 libatk-bridge2.0-0 libatk1.0-0 libcairo2 libcups2 \
      libdbus-1-3 libdrm2 libexpat1 libgbm1 libglib2.0-0 libgtk-3-0 \
      libnspr4 libnss3 libpango-1.0-0 libx11-6 libx11-xcb1 libxcb1 \
      libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 \
      libxrandr2 libxss1 libxtst6 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/tools
COPY package*.json ./

# Le lockfile est facultatif. S'il est présent, npm ci respecte sa résolution.
# On désactive les scripts npm, puis on installe explicitement un seul navigateur
# avec le CLI Puppeteer de whatsapp-web.js, sans récupérer un autre Puppeteer.
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev --ignore-scripts --no-audit --no-fund; \
    else \
      npm install --omit=dev --ignore-scripts --no-audit --no-fund; \
    fi \
    && ./node_modules/.bin/puppeteer browsers install chrome \
    && chmod -R a+rX /opt/puppeteer \
    && npm cache clean --force

# Le cache du navigateur est lisible par node et par l'UID utilisé en local.
# Les écritures du bot se font dans /tmp ou dans un volume, pas dans /opt/tools.
WORKDIR /app
USER node

# Test de l'image pendant le build : imports, lancement et arrêt de Chrome.
# Aucun accès à Google Sheets, à WhatsApp ou à une session réelle.
RUN node <<'JS'
const assert = require('node:assert/strict');
const puppeteer = require('puppeteer');
require('whatsapp-web.js');
require('qrcode-terminal');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });
  try {
    const page = await browser.newPage();
    await page.setContent('<title>Test image WhatsApp</title>');
    assert.equal(await page.title(), 'Test image WhatsApp');
    console.log('Test image OK :', process.version, await browser.version());
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
JS

# Même interface que le projet du bot : /app/bot.cjs est fourni par montage.
# Sans ce fichier, le démarrage normal échoue : ce n'est pas un bot embarqué.
ENTRYPOINT ["/usr/bin/tini", "--", "node", "/app/bot.cjs"]
CMD ["run"]
