# Architecture du moteur PDF

## Vue d'ensemble

generatePDF()

├── loadResources()

├── buildCover()

├── buildCharts()

├── buildHtmlPages()

├── buildSummary()

├── decoratePages()

└── pdf.save()

---

## Ressources

- logo
- bandeau

---

## Thème

Le moteur PDF utilise PDF_THEME pour :

- couleurs

- tailles

- marges

- polices
