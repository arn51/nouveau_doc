/******************************************************************************
 * Dashboard LJ
 * pdfCharts.js
 *
 * Description :
 *      Fonctions de construction des pages graphiques du rapport PDF.
 *
 * Auteur :
 *      Loïc J.
 *
 * Depuis :
 *      Sprint 5.1
 ******************************************************************************/

/******************************************************************************
 * buildCharts()
 * 
 * Construit les pages contenant les graphiques.
 ******************************************************************************/
async function buildCharts(pdf, resources) {

    const pageWidth = pdf.internal.pageSize.getWidth();

    await captureChartSection(
        pdf,
        "chartBars",
        "Graphique Barres",
        resources.bandeau,
        pageWidth
    );

    await captureChartSection(
        pdf,
        "chartRadar",
        "Graphique Radar",
        resources.bandeau,
        pageWidth
    );

    await captureChartSection(
        pdf,
        "chartDonut",
        "Graphique Donut",
        resources.bandeau,
        pageWidth
    );

}

/******************************************************************************
 * captureChartSection()
 *
 * Capture un canvas Chart.js et construit une page du rapport PDF.
 *
 * Étapes :
 *   - récupère le canvas
 *   - convertit le graphique en image PNG
 *   - ajoute une nouvelle page
 *   - dessine le bandeau
 *   - dessine le titre
 *   - insère le graphique centré
 ******************************************************************************/

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