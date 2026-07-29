// ------------------------------------------------------------
// Evolution du fichier nouveau-doc.js
// Numéro de sprint => nbre de lignes de ce fichier
// 4.0 => 642
// 5.4 => 116 
// ------------------------------------------------------------
// Chargement des ressources
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

// ------------------------------------------------------------
// Génération du PDF complet
// ------------------------------------------------------------

async function generatePDF() {
    try {
        const { jsPDF } = window.jspdf;
        const pdf = new jsPDF("p", "mm", "a4");

        const resources = await loadResources();

		// ------------------------------------------------------------
        // PAGE 1 — PAGE DE COUVERTURE PREMIUM AVEC LOGO
        // ------------------------------------------------------------

		await buildCover(pdf, resources);

        // ------------------------------------------------------------
        // Page 2 — Barres
        // Page 3 — Radar
        // Page 4 — Donut (filigrane recentré)
		// ------------------------------------------------------------
		
        await buildCharts(pdf, resources);

		// ------------------------------------------------------------
        // Page 5 — Vue Cartes (filigrane discret)
        // Page 6 — Tableau des badges (taille réelle)
		// ------------------------------------------------------------
		
        await buildHtmlPages(pdf, resources);

        // ------------------------------------------------------------
		// Page 7 — Sommaire compact
		// ------------------------------------------------------------
		
		await buildSummary(pdf, resources);

        // Footer + filigrane
        
		await decoratePages(pdf, resources);

        pdf.save("rapport.pdf");

    } catch (err) {
        console.error("Erreur lors de la génération du PDF :", err);
    }
}

// ------------------------------------------------------------
//  Bouton d’export
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