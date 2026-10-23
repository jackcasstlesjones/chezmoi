# Automation guide for agents

How to run checks, drive a real browser and open PRs with screenshots without a human. The project's own instructions (`CLAUDE.md`, contributing docs) take precedence over this file.

## Ground rules

- Work against local services only. Never point checks at production databases, buckets or live payment and email keys.
- Never print `.env` files or secrets. If you have to grep for a connection string, mask it: `sed -E 's/(:\/\/)[^@]*@/\1***@/'`.
- Don't install browsers. Use the system Chrome (for example `/usr/bin/google-chrome-stable`) and don't run `playwright install`.
- Keep throwaway scripts in a scratch directory, not the repo. Keep evidence (screenshots, logs, reports) in a git-ignored folder such as `.verification/<task>/`.
- Commit and push only when asked. Never merge. No AI attribution in commits or PRs.

## 1. Local services

- Start the project's local stack (database, storage and so on) before running anything that needs it, and check that it's up (for Postgres: `pg_isready -h 127.0.0.1 -p <port>`).
- If a port is already taken, find out what holds it (`docker ps`, `lsof -i :<port>`). If it belongs to another project, don't stop it. Ask the user.
- Tools that write to your home directory or talk to Docker may need to run outside a sandbox. Only do that after a sandbox-caused failure.

## 2. Checks before anything else

Run the project's typecheck, lint, tests and production build. All must pass before you verify behaviour or open a PR. Auto-fix only formatting and import order. Fix real errors by hand, and never weaken a test to make it pass.

## 3. Dev server

Start it in the background on its own port, then wait until it responds:

```bash
until curl -sf -o /dev/null http://localhost:<port>/; do sleep 2; done
```

Check the server's output for errors before reporting. Kill only your own server when you're done: `lsof -tiTCP:<port> -sTCP:LISTEN | xargs kill`.

## 4. Browser checks with system Chrome

### Quick screenshot or DOM dump (no script)

```bash
CHROME=/usr/bin/google-chrome-stable
$CHROME --headless=new --disable-gpu --hide-scrollbars \
  --window-size=1280,900 --screenshot=out/home-1280.png http://localhost:<port>/
$CHROME --headless=new --window-size=390,844 --screenshot=out/home-390.png http://localhost:<port>/
$CHROME --headless=new --dump-dom http://localhost:<port>/ | grep -c 'some-class'
```

Check every visual change at a desktop width (1280px) and a phone width (390px). `--screenshot` captures only the viewport, so use a script for full pages.

### Scripted checks (full-page shots, clicks, cookies, console errors)

Install `puppeteer-core` in your scratch directory, never as a project dependency, and point it at system Chrome:

```bash
cd "$SCRATCH" && npm init -y >/dev/null && npm i puppeteer-core
```

```js
// $SCRATCH/shots.mjs, run with: node $SCRATCH/shots.mjs <baseUrl> <outDir> <route>...
import puppeteer from "puppeteer-core";

const [baseUrl, outDir, ...routes] = process.argv.slice(2);
const browser = await puppeteer.launch({
  executablePath: "/usr/bin/google-chrome-stable",
});
const errors = [];
for (const [width, height] of [
  [1280, 900],
  [390, 844],
]) {
  const page = await browser.newPage();
  await page.setViewport({ width, height });
  page.on(
    "console",
    (m) =>
      m.type() === "error" && errors.push(`${width} ${page.url()} ${m.text()}`),
  );
  for (const route of routes) {
    const res = await page.goto(`${baseUrl}/${route}`, {
      waitUntil: "networkidle0",
    });
    const scrollWidth = await page.evaluate(
      () => document.documentElement.scrollWidth,
    );
    console.log(
      width,
      `/${route}`,
      res.status(),
      scrollWidth > width ? `H-SCROLL ${scrollWidth}` : "",
    );
    const name = (route || "home").replace(/\//g, "_");
    await page.screenshot({
      path: `${outDir}/${name}-${width}.png`,
      fullPage: true,
    });
  }
}
console.log(errors.join("\n") || "no console errors");
await browser.close();
```

Useful extras in the same script:

- Reduced motion: `await page.emulateMediaFeatures([{ name: 'prefers-reduced-motion', value: 'reduce' }])`.
- Dark mode: `[{ name: 'prefers-color-scheme', value: 'dark' }]`.
- Keyboard: `await page.keyboard.press('Tab')`, then `page.evaluate(() => document.activeElement?.outerHTML)`.
- Cookies and storage: `await page.cookies()`, `page.evaluate(() => ({ ...sessionStorage }))`.
- Analytics: `page.evaluate(() => window.dataLayer)`. Check that no personal data appears in it.
- Click-through: `await page.click('selector')`, then `await page.waitForNavigation()`.

Open and look at every screenshot yourself before you call a check passed. Look for horizontal scroll, overlap, clipped text and broken images.

### Accessibility and performance

```bash
npx lighthouse http://localhost:<port>/ --only-categories=accessibility,performance \
  --chrome-path=/usr/bin/google-chrome-stable --chrome-flags="--headless=new" \
  --output=json --output-path=out/lighthouse.json --quiet
```

Report the scores and any failed audits (contrast, image sizing and so on).

### API and database checks

- `curl -i` the endpoint. For authenticated APIs, log in once and keep the session with `-c cookies.txt` / `-b cookies.txt`.
- `psql "<local connection string>" -c "…"`. Wrap anything destructive in `BEGIN; … ROLLBACK;`.

## 5. Opening the PR with screenshots

```bash
git push -u origin <branch>
gh pr create --base main --head <branch> --title "<conventional title>" --body-file "$SCRATCH/pr-body.md"
```

If a PR already exists for the branch (`gh pr list --head <branch>`), update it with `gh pr edit <n> --body-file …` rather than opening another.

`gh` can't upload images, and evidence folders are usually git-ignored. To show screenshots in the PR:

1. Commit the chosen PNGs (only the useful ones, at both widths) to a separate orphan branch, so they never land on `main`:

   ```bash
   git worktree add "$SCRATCH/pr-assets" --orphan pr-assets 2>/dev/null || git worktree add "$SCRATCH/pr-assets" pr-assets
   mkdir -p "$SCRATCH/pr-assets/<branch>" && cp out/*.png "$SCRATCH/pr-assets/<branch>/"
   git -C "$SCRATCH/pr-assets" add . && git -C "$SCRATCH/pr-assets" commit -m "chore: screenshots for <branch>"
   git -C "$SCRATCH/pr-assets" push -u origin pr-assets
   ```

2. Reference them in the body by commit SHA, so the links keep working. This also works on private repos for anyone with access:

   ```md
   ## Screenshots

   | Desktop                                                                                       | Mobile                                                                                      |
   | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
   | ![home desktop](https://github.com/<owner>/<repo>/blob/<sha>/<branch>/home-1280.png?raw=true) | ![home mobile](https://github.com/<owner>/<repo>/blob/<sha>/<branch>/home-390.png?raw=true) |
   ```

Ask the user before pushing the `pr-assets` branch the first time, because it creates a new branch on the shared remote.

## 6. After pushing

- Don't poll CI or deployments. Check once if asked, then report.
- Report the PR URL, the result of each check, the evidence path for each behaviour you verified, and anything you couldn't verify, saying why.
