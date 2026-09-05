#!/usr/bin/env python3
from __future__ import annotations

import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "legal"
DIST = Path(__file__).resolve().parent / "dist"

PAGES = [
    {
        "src": "politica-de-privacidade-pt-BR.md",
        "out": "privacidade.html",
        "lang": "pt-BR",
        "title": "Política de Privacidade — Raro Camera",
        "privacy": "/privacidade",
        "terms": "/termos",
        "home": "/",
        "nav_privacy": "Privacidade",
        "nav_terms": "Termos",
        "alts": [("/", "PT"), ("/en/privacy", "EN"), ("/es/privacidad", "ES")],
        "current": "privacy",
    },
    {
        "src": "termos-de-uso-pt-BR.md",
        "out": "termos.html",
        "lang": "pt-BR",
        "title": "Termos de Uso — Raro Camera",
        "privacy": "/privacidade",
        "terms": "/termos",
        "home": "/",
        "nav_privacy": "Privacidade",
        "nav_terms": "Termos",
        "alts": [("/", "PT"), ("/en/terms", "EN"), ("/es/terminos", "ES")],
        "current": "terms",
    },
    {
        "src": "privacy-policy-en.md",
        "out": "en/privacy.html",
        "lang": "en",
        "title": "Privacy Policy — Raro Camera",
        "privacy": "/en/privacy",
        "terms": "/en/terms",
        "home": "/en/",
        "nav_privacy": "Privacy",
        "nav_terms": "Terms",
        "alts": [("/privacidade", "PT"), ("/en/privacy", "EN"), ("/es/privacidad", "ES")],
        "current": "privacy",
    },
    {
        "src": "terms-of-use-en.md",
        "out": "en/terms.html",
        "lang": "en",
        "title": "Terms of Use — Raro Camera",
        "privacy": "/en/privacy",
        "terms": "/en/terms",
        "home": "/en/",
        "nav_privacy": "Privacy",
        "nav_terms": "Terms",
        "alts": [("/termos", "PT"), ("/en/terms", "EN"), ("/es/terminos", "ES")],
        "current": "terms",
    },
    {
        "src": "politica-de-privacidad-es.md",
        "out": "es/privacidad.html",
        "lang": "es",
        "title": "Política de privacidad — Raro Camera",
        "privacy": "/es/privacidad",
        "terms": "/es/terminos",
        "home": "/es/",
        "nav_privacy": "Privacidad",
        "nav_terms": "Términos",
        "alts": [("/privacidade", "PT"), ("/en/privacy", "EN"), ("/es/privacidad", "ES")],
        "current": "privacy",
    },
    {
        "src": "terminos-de-uso-es.md",
        "out": "es/terminos.html",
        "lang": "es",
        "title": "Términos de uso — Raro Camera",
        "privacy": "/es/privacidad",
        "terms": "/es/terminos",
        "home": "/es/",
        "nav_privacy": "Privacidad",
        "nav_terms": "Términos",
        "alts": [("/termos", "PT"), ("/en/terms", "EN"), ("/es/terminos", "ES")],
        "current": "terms",
    },
]


def inline(text: str) -> str:
    text = html.escape(text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    return text


def md_to_html(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    i = 0
    first_h1 = True
    while i < len(lines):
        line = lines[i]
        if line.startswith("# "):
            title = inline(line[2:])
            out.append(f"<h1>{title}</h1>")
            if first_h1 and i + 1 < len(lines) and lines[i + 1].strip():
                nxt = lines[i + 1]
                if not nxt.startswith("#") and not nxt.startswith("|"):
                    out.append(f'<p class="updated">{inline(nxt)}</p>')
                    i += 2
                    first_h1 = False
                    continue
            first_h1 = False
            i += 1
            continue
        if line.startswith("## "):
            out.append(f"<h2>{inline(line[3:])}</h2>")
            i += 1
            continue
        if line.startswith("### "):
            out.append(f"<h3>{inline(line[4:])}</h3>")
            i += 1
            continue
        if line.startswith("|"):
            rows: list[str] = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i])
                i += 1
            body_rows = [r for r in rows if not re.match(r"^\|\s*-+", r)]
            table = ["<table>"]
            for idx, row in enumerate(body_rows):
                cells = [c.strip() for c in row.strip("|").split("|")]
                tag = "th" if idx == 0 else "td"
                table.append("<tr>" + "".join(f"<{tag}>{inline(c)}</{tag}>" for c in cells) + "</tr>")
            table.append("</table>")
            out.extend(table)
            continue
        if line.startswith("- "):
            out.append("<ul>")
            while i < len(lines) and lines[i].startswith("- "):
                out.append(f"<li>{inline(lines[i][2:])}</li>")
                i += 1
            out.append("</ul>")
            continue
        if not line.strip():
            i += 1
            continue
        para = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].startswith("#") and not lines[i].startswith("|") and not lines[i].startswith("- "):
            para.append(lines[i])
            i += 1
        out.append(f"<p>{inline(' '.join(para))}</p>")
    return "\n".join(out)


def shell(page: dict, body: str) -> str:
    alt_links = " ".join(
        f'<a href="{href}"{" aria-current=\"page\"" if href in (page["privacy"], page["terms"], page["home"]) and label == page["lang"][:2].upper() else ""}>{label}</a>'
        for href, label in page["alts"]
    )
    privacy_cur = ' aria-current="page"' if page["current"] == "privacy" else ""
    terms_cur = ' aria-current="page"' if page["current"] == "terms" else ""
    return f"""<!DOCTYPE html>
<html lang="{page["lang"]}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(page["title"])}</title>
  <meta name="description" content="{html.escape(page["title"])}">
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <div class="wrap">
    <header>
      <a class="brand" href="{page["home"]}">RARO CAMERA</a>
      <nav>
        {alt_links}
        <a href="{page["terms"]}"{terms_cur}>{page["nav_terms"]}</a>
        <a href="{page["privacy"]}"{privacy_cur}>{page["nav_privacy"]}</a>
      </nav>
    </header>
    <main>
{body}
    </main>
    <footer>
      Vitor Autorino Lopes (Raro Camera) ·
      <a href="mailto:rarocan1@gmail.com">rarocan1@gmail.com</a>
      · site estático, sem cookies
    </footer>
  </div>
</body>
</html>
"""


HOMES = {
    "index.html": {
        "lang": "pt-BR",
        "title": "Raro Camera — documentos legais",
        "home": "/",
        "privacy": "/privacidade",
        "terms": "/termos",
        "nav_privacy": "Privacidade",
        "nav_terms": "Termos",
        "alts": [("/", "PT"), ("/en/", "EN"), ("/es/", "ES")],
        "current": "home",
        "heading": "Documentos legais",
        "lead": "Textos públicos exigidos pelas lojas. Páginas estáticas, sem cookies e sem analytics.",
        "terms_label": "Termos de Uso",
        "terms_hint": "Assinatura, trial de 30 dias, renovação e cancelamento.",
        "privacy_label": "Política de Privacidade",
        "privacy_hint": "O que fica no aparelho e o que vai ao Firebase, RevenueCat e lojas.",
    },
    "en/index.html": {
        "lang": "en",
        "title": "Raro Camera — legal",
        "home": "/en/",
        "privacy": "/en/privacy",
        "terms": "/en/terms",
        "nav_privacy": "Privacy",
        "nav_terms": "Terms",
        "alts": [("/", "PT"), ("/en/", "EN"), ("/es/", "ES")],
        "current": "home",
        "heading": "Legal documents",
        "lead": "Public texts required by the stores. Static pages, no cookies and no analytics.",
        "terms_label": "Terms of Use",
        "terms_hint": "Subscription, 30-day trial, renewal, and cancellation.",
        "privacy_label": "Privacy Policy",
        "privacy_hint": "What stays on the device and what goes to Firebase, RevenueCat, and the stores.",
    },
    "es/index.html": {
        "lang": "es",
        "title": "Raro Camera — legal",
        "home": "/es/",
        "privacy": "/es/privacidad",
        "terms": "/es/terminos",
        "nav_privacy": "Privacidad",
        "nav_terms": "Términos",
        "alts": [("/", "PT"), ("/en/", "EN"), ("/es/", "ES")],
        "current": "home",
        "heading": "Documentos legales",
        "lead": "Textos públicos exigidos por las tiendas. Páginas estáticas, sin cookies y sin analítica.",
        "terms_label": "Términos de uso",
        "terms_hint": "Suscripción, prueba de 30 días, renovación y cancelación.",
        "privacy_label": "Política de privacidad",
        "privacy_hint": "Lo que se queda en el aparato y lo que va a Firebase, RevenueCat y las tiendas.",
    },
}


def home_body(page: dict) -> str:
    return f"""<h1>{html.escape(page["heading"])}</h1>
<p class="updated">{html.escape(page["lead"])}</p>
<a class="home-card" href="{page["privacy"]}">
  <strong>{html.escape(page["privacy_label"])}</strong>
  <span>{html.escape(page["privacy_hint"])}</span>
</a>
<a class="home-card" href="{page["terms"]}">
  <strong>{html.escape(page["terms_label"])}</strong>
  <span>{html.escape(page["terms_hint"])}</span>
</a>
"""


def main() -> None:
    if DIST.exists():
        for old in DIST.rglob("*"):
            if old.is_file():
                old.unlink()
    DIST.mkdir(parents=True, exist_ok=True)
    (DIST / "en").mkdir(exist_ok=True)
    (DIST / "es").mkdir(exist_ok=True)

    css = Path(__file__).resolve().parent / "styles.css"
    (DIST / "styles.css").write_text(css.read_text(encoding="utf-8"), encoding="utf-8")
    (DIST / "robots.txt").write_text(
        "User-agent: *\nAllow: /\nSitemap: https://rarocamera.com.br/sitemap.xml\n",
        encoding="utf-8",
    )
    (DIST / "sitemap.xml").write_text(
        """<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://rarocamera.com.br/</loc></url>
  <url><loc>https://rarocamera.com.br/privacidade</loc></url>
  <url><loc>https://rarocamera.com.br/termos</loc></url>
  <url><loc>https://rarocamera.com.br/en/</loc></url>
  <url><loc>https://rarocamera.com.br/en/privacy</loc></url>
  <url><loc>https://rarocamera.com.br/en/terms</loc></url>
  <url><loc>https://rarocamera.com.br/es/</loc></url>
  <url><loc>https://rarocamera.com.br/es/privacidad</loc></url>
  <url><loc>https://rarocamera.com.br/es/terminos</loc></url>
</urlset>
""",
        encoding="utf-8",
    )

    for page in PAGES:
        md = (DOCS / page["src"]).read_text(encoding="utf-8")
        body = md_to_html(md)
        dest = DIST / page["out"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(shell(page, body), encoding="utf-8")

    for out, page in HOMES.items():
        dest = DIST / out
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(shell(page, home_body(page)), encoding="utf-8")


if __name__ == "__main__":
    main()
