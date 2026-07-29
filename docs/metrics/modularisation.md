# Suivi de la modularisation

## Objectif

Ce document suit l'évolution de la modularisation du moteur PDF.

Il permet de visualiser, sprint après sprint :

- la diminution progressive du fichier `nouveau_doc.js` ;
- l'apparition des modules spécialisés ;
- l'avancement de l'architecture.

---

| Sprint | nouveau_doc.js | Modules PDF | Module concerné | Fonctions déplacées | Validation |
|---------|---------------:|------------:|-----------|---------------| -------------|
| 4.0 | 642* | 1 | Projet initial | -- | ✅ |
| 4.1 | 642 | 2 | `pdfTheme.js` | `PDF_THEME` | ✅ |
| 4.2 | 642 | 3 | `pdfGenerator.js` | *(creation du point d'entrée)* | ✅ |
| 4.3 | 617 | 4 | `pdfFooter.js` | `drawFooter()` | ✅ |
| 4.4 | 590 | 5 | `pdfCover.js` | `drawBandeau()` | ✅ |
| 4.5 | 583 | 5 | `pdfCover.js` | `drawPageTitle()` | ✅ |
| 4.6 | 443 | 5 | `pdfCover.js` | `buildCover()` | ✅ |
| 4.7 | 363 | 6 | `pdfDecoration.js` | `drawFiligrane()` | ✅ |
| 4.8 | 331 | 6 | `pdfDecoration.js` | `decoratePages()` | ✅ |
| 5.0 | 271 | 7 | `pdfSummary.js` | `buildSummary()` | ✅ |
| 5.1 | 238 | 8 | `pdfCharts.js` | `buildCharts()` | ✅ |
| 5.2 | 213 | 9 | `pdfHtmlPages.js` | `buildHtmlPages()` | ✅ |
| 5.3 | 188 | 9 | `pdfCharts.js` | `caputureChartSection()` | ✅ |
| 5.4 | 116 | 9 | `pdfHtmlPages.js` | `captureHtmlSection()` | ✅ |

> *Les valeurs pourront être ajustées si le nombre exact de lignes évolue.*

---
 
## Modules existants

| Module | Responsabilité | Sprint | État |
|----------| :-----------: | :------: | :---: |
| pdfTheme.js | Centralisation du thème PDF | 4.1 | ✅ |
| pdfGenerator.js | Orchestration de la génération | 4.2 | ✅ |
| pdfFooter.js | Pied de page | 4.3 | ✅ |
| pdfCover.js | Construction de la couverture | 4.4 | ✅ |
| pdfDecoration.js | Décorations et filigranes | 4.7 | ✅ |
| pdfSummary.js | Construit la page sommaire | 5.0 | ✅ |
| pdfCharts.js | Construit les pages contenant du graphique | 5.1 | ✅ |
| pdfHtmlPages.js | Construit les pages HTML | 5.2 | ✅ |

---

## Objectif final

À terme, le moteur PDF sera composé des modules suivants :

- pdfGenerator.js
- pdfTheme.js
- pdfLayout.js
- pdfText.js
- pdfResources.js
- pdfCover.js
- pdfSummary.js
- pdfCharts.js
- pdfDecoration.js
- pdfFooter.js

Le fichier `nouveau_doc.js` deviendra progressivement un simple point d'entrée vers ces différents modules.
---

## Philosophie

La modularisation n'a pas pour objectif de réduire artificiellement
le nombre de lignes d'un fichier.

Son objectif est de :

- améliorer la lisibilité ;
- isoler les responsabilités ;
- faciliter les tests ;
- simplifier la maintenance ;
- préparer les évolutions futures.

Chaque extraction de module est validée par un test complet de non-régression.