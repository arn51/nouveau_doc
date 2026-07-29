/******************************************************************************
 * Dashboard LJ
 * pdfHtmlPages.js
 *
 * Description :
 *      Fonctions de construction des pages HTML du rapport PDF.
 *
 * Auteur :
 *      Loïc J.
 *
 * Depuis :
 *      Sprint 5.2
 ******************************************************************************/

/******************************************************************************
 * Construit les pages HTML.
 ******************************************************************************/
async function buildHtmlPages(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();

    await captureHtmlSection(
        pdf,
        "cardsContainer",
        "Vue Cartes",
        resources.bandeau,
        pageWidth
    );

    await captureHtmlSection(
        pdf,
        "badgeTable",
        "Tableau des Badges",
        resources.bandeau,
        pageWidth
    );

}

// ------------------------------------------------------------
//  Capture HTML (cartes + tableau)
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
