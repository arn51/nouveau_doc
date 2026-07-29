// ------------------------------------------------------------
// BLOC 1 — Bandeau, titre, filigrane, footer
// ------------------------------------------------------------

// Charge une image
function loadImage(src) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = "anonymous";
        img.onload = () => resolve(img);
        img.onerror = reject;
        img.src = src;
    });
}

/**
 * Charge toutes les ressources graphiques utilisées
 * pour la génération du rapport PDF.
 *
 * @returns {Promise<Object>}
 */
async function loadResources() {

    return {

        bandeau: await loadImage("bandeau_verre_depoli.png"),

        logo: await loadImage("assets/logo.png")

    };

}

// Bandeau fin
async function drawBandeau(pdf, bandeauImg, pageWidth) {
    const bandeauHeight = 20;
    pdf.addImage(bandeauImg, "PNG", 0, 0, pageWidth, bandeauHeight);
    return bandeauHeight;
}

// Titre sous bandeau
function drawPageTitle(pdf, title, yPosition, pageWidth) {
    pdf.setFont("helvetica", "bold");
    pdf.setFontSize(16);
    pdf.text(title, pageWidth / 2, yPosition + 14, { align: "center" });
    return yPosition + 22;
}

// Filigrane (position dynamique selon la page)
function drawFiligrane(pdf, logoImg, pageNumber) {

    const pageWidth  = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();

    // Position et taille du logo
    let logoSize = 90;
    let x = (pageWidth - logoSize) / 2;
    let y = (pageHeight - logoSize) / 2;

    // Ajustements selon les pages
    if (pageNumber === 1) {
        logoSize = 70;
        x = pageWidth - logoSize - 20;
        y = pageHeight - logoSize - 25;
    }

    if (pageNumber === 5 || pageNumber === 7) {
        logoSize = 65;
        x = pageWidth - logoSize - 20;
        y = pageHeight - logoSize - 20;
    }

    // Logo
    pdf.addImage(
        logoImg,
        "PNG",
        x,
        y,
        logoSize,
        logoSize
    );

    // Texte (sauf couverture)
    if (pageNumber !== 1) {

        pdf.setFont("helvetica", "bold");
        pdf.setFontSize(36);
        pdf.setTextColor(230);

        pdf.text(
            "DOCUMENT INTERNE",
            pageWidth / 2,
            pageHeight / 2,
            {
                align: "center",
                angle: 45
            }
        );
    }
}

// Footer premium
function drawFooter(pdf, pageNumber, totalPages, pageWidth, pageHeight) {
    pdf.setDrawColor(225, 225, 225);
    pdf.setLineWidth(0.4);
    pdf.line(50, pageHeight - 30, pageWidth - 50, pageHeight - 30);

    pdf.setFont("helvetica", "normal");
    pdf.setFontSize(9.5);
    pdf.setTextColor(140, 140, 140);

    pdf.text("Dashboard LJ — Rapport interne", 50, pageHeight - 15);
    pdf.text(`Page ${pageNumber} / ${totalPages}`, pageWidth - 50, pageHeight - 15, { align: "right" });
}

// ------------------------------------------------------------
// BLOC 2 — Capture des graphiques Chart.js
// ------------------------------------------------------------

async function captureChartSection(pdf, canvasId, titre, bandeauImg, pageWidth) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;

    const imgData = canvas.toDataURL("image/png", 1.0);

    const pageHeight = pdf.internal.pageSize.getHeight();
    const imgWidth = pageWidth * 0.90;
    let imgHeight = (canvas.height / canvas.width) * imgWidth;

    const maxHeight = pageHeight * 0.60;
    if (imgHeight > maxHeight) imgHeight = maxHeight;

    pdf.addPage();
    const bandeauHeight = await drawBandeau(pdf, bandeauImg, pageWidth);
    const y = drawPageTitle(pdf, titre, bandeauHeight, pageWidth);

    const x = (pageWidth - imgWidth) / 2;
    pdf.addImage(imgData, "PNG", x, y + 10, imgWidth, imgHeight);
}

// ------------------------------------------------------------
// BLOC 3 — Capture HTML (cartes + tableau)
// ------------------------------------------------------------

async function captureHtmlSection(pdf, elementId, titre, bandeauImg, pageWidth) {
    const element = document.getElementById(elementId);
    if (!element) return;

    // Patch visibilité
    const oldDisplay = element.style.display;
    const computed = getComputedStyle(element);
    if (computed.display === "none") element.style.display = "block";

    // Patch scale élément
    const oldTransform = element.style.transform;
    element.style.transform = "scale(1)";

    // Patch scale parent (important pour page 6)
    const parent = element.parentElement;
    const oldParentTransform = parent ? parent.style.transform : null;
    if (parent) parent.style.transform = "scale(1)";

    // Patch largeur
    const oldWidth = element.style.width;
    const oldParentWidth = parent ? parent.style.width : null;

    element.style.width = "100%";
    if (parent) parent.style.width = "100%";

    // Agrandir le tableau pendant la capture
    const oldZoom = element.style.zoom;
    element.style.zoom = "1.50";   // +50% de taille

    const canvas = await html2canvas(element, { scale: 2, useCORS: true });

    // Restauration
    element.style.display = oldDisplay;
    element.style.transform = oldTransform;
    element.style.zoom = oldZoom;

    if (parent && oldParentTransform !== null) parent.style.transform = oldParentTransform;

    element.style.width = oldWidth;
    if (parent && oldParentWidth !== null) parent.style.width = oldParentWidth;

    const imgData = canvas.toDataURL("image/png", 1.0);

    const pageHeight = pdf.internal.pageSize.getHeight();
    const imgWidth = pageWidth * 0.90;
    const imgHeight = (canvas.height / canvas.width) * imgWidth;

    let heightLeft = imgHeight;

    pdf.addPage();
    const bandeauHeight = await drawBandeau(pdf, bandeauImg, pageWidth);
    let y = drawPageTitle(pdf, titre, bandeauHeight, pageWidth);

    const x = (pageWidth - imgWidth) / 2;
    pdf.addImage(imgData, "PNG", x, y + 10, imgWidth, imgHeight);

    heightLeft -= (pageHeight - (y + 10) - 20);

    while (heightLeft > 0) {
        pdf.addPage();
        const bandeauHeight2 = await drawBandeau(pdf, bandeauImg, pageWidth);
        const y2 = bandeauHeight2 + 10;

        pdf.addImage(imgData, "PNG", x, y2, imgWidth, imgHeight);
        heightLeft -= (pageHeight - y2 - 20);
    }
}

// ------------------------------------------------------------
// BLOC 4 — Génération du PDF complet
// ------------------------------------------------------------

async function generatePDF() {
    try {
        const { jsPDF } = window.jspdf;
        const pdf = new jsPDF("p", "mm", "a4");

        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();

        const resources = await loadResources();

		const bandeauImg = resources.bandeau;
		const logoImg = resources.logo;

        // ------------------------------------------------------------
        // PAGE 1 — PAGE DE COUVERTURE PREMIUM AVEC LOGO
        // ------------------------------------------------------------

        // Bandeau fin
        const bandeauHeight1 = await drawBandeau(pdf, bandeauImg, pageWidth);

        // Logo en haut à droite (proportionné)
        const logoWidth = 28;   // largeur du logo
        const logoHeight = 28;  // hauteur du logo
        pdf.addImage(
            logoImg,
            "PNG",
            pageWidth - logoWidth - 10,  // marge droite
            1,                           // marge haute
            logoWidth,
            logoHeight
        );

        // Fond léger
        pdf.setFillColor(245, 245, 245);
        pdf.rect(0, bandeauHeight1, pageWidth, pageHeight - bandeauHeight1, "F");

        // Titre principal
        pdf.setFont("helvetica", "bold");
        pdf.setFontSize(28);
        pdf.setTextColor(40, 40, 40);
        pdf.text("Rapport d'analyse", pageWidth / 2, bandeauHeight1 + 40, { align: "center" });

        // Sous-titre
        pdf.setFont("helvetica", "normal");
        pdf.setFontSize(16);
        pdf.setTextColor(90, 90, 90);
        pdf.text("Synthèse des indicateurs — Dashboard LJ", pageWidth / 2, bandeauHeight1 + 60, { align: "center" });

        // Ligne décorative
        pdf.setDrawColor(180, 180, 180);
        pdf.setLineWidth(0.6);
        pdf.line(pageWidth / 2 - 30, bandeauHeight1 + 70, pageWidth / 2 + 30, bandeauHeight1 + 70);

        // Bloc d'informations (à gauche)
        pdf.setFontSize(12);
        pdf.setTextColor(70, 70, 70);

        let infoY = bandeauHeight1 + 95;
        pdf.text("Document interne", 20, infoY);
        infoY += 8;
        pdf.text("Auteur : Loïc J.", 20, infoY);
        infoY += 8;
        pdf.text("Date : " + new Date().toLocaleDateString("fr-FR"), 20, infoY);

        // Signature (à droite)
        pdf.setFont("helvetica", "italic");
        pdf.setFontSize(12);
        pdf.text("Dashboard LJ", pageWidth - 20, bandeauHeight1 + 95, { align: "right" });

        // Page 2 — Barres
        await captureChartSection(pdf, "chartBars", "Graphique Barres", bandeauImg, pageWidth);

        // Page 3 — Radar
        await captureChartSection(pdf, "chartRadar", "Graphique Radar", bandeauImg, pageWidth);

        // Page 4 — Donut (filigrane recentré)
        await captureChartSection(pdf, "chartDonut", "Graphique Donut", bandeauImg, pageWidth);

        // Page 5 — Vue Cartes (filigrane discret)
        await captureHtmlSection(pdf, "cardsContainer", "Vue Cartes", bandeauImg, pageWidth);

        // Page 6 — Tableau des badges (taille réelle)
        await captureHtmlSection(pdf, "badgeTable", "Tableau des Badges", bandeauImg, pageWidth);

        // Page 7 — Sommaire compact
        pdf.addPage();
        const bandeauSommaire = await drawBandeau(pdf, bandeauImg, pageWidth);

        pdf.setFont("helvetica", "bold");
        pdf.setFontSize(20);
        pdf.text("Sommaire", pageWidth / 2, bandeauSommaire + 30, { align: "center" });

        pdf.setFont("helvetica", "normal");
        pdf.setFontSize(12);

        const sommaire = [
            "Page 1 — Page de couverture",
            "Page 2 — Graphique Barres",
            "Page 3 — Graphique Radar",
            "Page 4 — Graphique Donut",
            "Page 5 — Vue Cartes",
            "Page 6 — Tableau des Badges",
            "Page 7 — Sommaire"
        ];

        let y = bandeauSommaire + 50;
        sommaire.forEach(line => {
            pdf.text(line, 60, y);
            y += 7;
        });

        // Footer + filigrane
        const totalPages = pdf.internal.getNumberOfPages();
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            await drawFiligrane(pdf, logoImg, i);
            drawFooter(pdf, i, totalPages, pageWidth, pageHeight);
        }

        pdf.save("rapport.pdf");

    } catch (err) {
        console.error("Erreur lors de la génération du PDF :", err);
    }
}

// ------------------------------------------------------------
// BLOC 5 — Bouton d’export
// ------------------------------------------------------------

let pdfInProgress = false;

async function startPDFGeneration() {
    if (pdfInProgress) return;
    pdfInProgress = true;

    try {
        await generatePDF();
    } catch (err) {
        console.error("Erreur PDF :", err);
        alert("Erreur pendant la génération du PDF.");
    }

    pdfInProgress = false;
}

const btn = document.getElementById("exportPdfBtn");
if (btn) btn.addEventListener("click", startPDFGeneration);
else console.warn("Bouton export PDF introuvable !");
