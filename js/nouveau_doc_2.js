// =====================================================
// THEME DU PDF
// =====================================================

const PDF_THEME = {

    colors: {

        primary:     [78, 22, 9],      // brun LJ
        secondary:   [187,174,152],    // beige
        background:  [245,245,245],
        text:        [40,40,40],
        textLight:   [90,90,90],
        border:      [190,190,190],
        watermark:   [180,180,180]

    },

    logo: {

        cover: 70,
        chart: 55,
        table: 35

    }

};

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

/******************************************************************************
 * Construit la page de couverture.
 ******************************************************************************/
async function buildCover(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();
    const pageHeight = pdf.internal.pageSize.getHeight();

    const bandeauHeight = await drawBandeau(
        pdf,
        resources.bandeau,
        pageWidth
    );

    const logoWidth = 28;
    const logoHeight = 28;

    pdf.addImage(
        resources.logo,
        "PNG",
        pageWidth - logoWidth - 10,
        1,
        logoWidth,
        logoHeight
    );

    // Fond
    pdf.setFillColor(245,245,245);
    pdf.rect(
        0,
        bandeauHeight,
        pageWidth,
        pageHeight - bandeauHeight,
        "F"
    );

    // Titre
    pdf.setFont("helvetica","bold");
    pdf.setFontSize(28);
    pdf.setTextColor(40,40,40);

    pdf.text(
        "Rapport d'analyse",
        pageWidth/2,
        bandeauHeight + 40,
        {align:"center"}
    );

    // Sous-titre

    pdf.setFont("helvetica","normal");
    pdf.setFontSize(16);
    pdf.setTextColor(90,90,90);

    pdf.text(
        "Synthèse des indicateurs — Dashboard LJ",
        pageWidth/2,
        bandeauHeight + 60,
        {align:"center"}
    );

    // Ligne

    pdf.setDrawColor(180,180,180);
    pdf.setLineWidth(0.6);

    pdf.line(
        pageWidth/2 -30,
        bandeauHeight +70,
        pageWidth/2 +30,
        bandeauHeight +70
    );

    // Informations

    pdf.setFontSize(12);
    pdf.setTextColor(70,70,70);

    let infoY = bandeauHeight +95;

    pdf.text("Document interne",20,infoY);

    infoY+=8;

    pdf.text("Auteur : Loïc J.",20,infoY);

    infoY+=8;

    pdf.text(
        "Date : " +
        new Date().toLocaleDateString("fr-FR"),
        20,
        infoY
    );

    // Signature

    pdf.setFont(
        "helvetica",
        "italic"
    );

    pdf.setFontSize(12);

    pdf.text(
        "Dashboard LJ",
        pageWidth-20,
        bandeauHeight+95,
        {
            align:"right"
        }
    );

}

// Filigrane (position dynamique selon la page)
function drawFiligrane(pdf, logoImg, type = "chart") {

    const w = pdf.internal.pageSize.getWidth();
    const h = pdf.internal.pageSize.getHeight();

    let size = 55;
    let x = (w - size) / 2;
    let y = (h - size) / 2;

    if (type === "cover") {
        size = 70;
        x = w - size - 20;
        y = h - size - 20;
    }

    if (type === "table") {
        size = 35;
        x = w - size - 20;
        y = h - size - 20;
    }

    // Logo
    pdf.addImage(
        logoImg,
        "PNG",
        x,
        y,
        size,
        size
    );

    // Texte
    if (type !== "cover") {

        pdf.setFont("helvetica", "bold");
        pdf.setFontSize(34);

        // Gris clair
        pdf.setTextColor(220);

        pdf.text(
            "DOCUMENT INTERNE",
            w / 2,
            h / 2,
            {
                align: "center",
                angle: 45
            }
        );
    }
}

// Footer premium
function drawFooter(
    pdf,
    page,
    total
){

    const w = pdf.internal.pageSize.getWidth();
    const h = pdf.internal.pageSize.getHeight();

    pdf.setDrawColor(
        ...PDF_THEME.colors.border
    );

    pdf.line(
        15,
        h-12,
        w-15,
        h-12
    );

    pdf.setFont("helvetica","normal");

    pdf.setFontSize(9);

    pdf.setTextColor(
        ...PDF_THEME.colors.textLight
    );

    pdf.text(
        "Dashboard LJ",
        15,
        h-6
    );

    pdf.text(
        `Page ${page}/${total}`,
        w/2,
        h-6,
        {
            align:"center"
        }
    );

    pdf.text(
        new Date().toLocaleDateString("fr-FR"),
        w-15,
        h-6,
        {
            align:"right"
        }
    );

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
    drawFiligrane(pdf, logoImg, "chart");
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

        const bandeauImg = await loadImage("bandeau_verre_depoli.png");

        // ------------------------------------------------------------
        // PAGE 1 — PAGE DE COUVERTURE PREMIUM AVEC LOGO
        // ------------------------------------------------------------

		await buildCover(pdf, resources);

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
            
            drawFooter(
                pdf, 
                i, 
                totalPages
            );
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
