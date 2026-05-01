document.addEventListener("DOMContentLoaded", () => {
    const exportBtn = document.getElementById("exportPDF");

    if (!exportBtn) {
        console.error("Bouton #exportPDF introuvable");
        return;
    }

    const waitForCharts = () =>
        new Promise(resolve => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    setTimeout(resolve, 150);
                });
            });
        });

async function captureSection(pdf, element, pageWidth, pageHeight, title) {

    const canvas = await html2canvas(element, {
        scale: 1.4,
        useCORS: true
    });

    const imgData = canvas.toDataURL("image/png");

    const marginX = 30;
    const marginTop = 70;
    const maxWidth = pageWidth - marginX * 2;
    const imgHeight = canvas.height * (maxWidth / canvas.width);

    // Titre
    pdf.setFontSize(18);
    pdf.setTextColor(20);
    pdf.text(title, marginX, 40);

    // UNE SEULE PAGE, PAS DE DÉCOUPAGE
    pdf.addImage(imgData, "PNG", marginX, marginTop, maxWidth, imgHeight, "", "FAST");
}

    function addWatermarkAndFooter(pdf, pageWidth, pageHeight, pageNum, totalPages, logoImg) {
        try {
            if (logoImg) {
                const g = new pdf.GState({ opacity: 0.12 });
                pdf.setGState(g);
                const wmWidth = pageWidth * 0.35;
                const wmHeight = wmWidth;
                const wmX = (pageWidth - wmWidth) / 2;
                const wmY = (pageHeight - wmHeight) / 2;
                pdf.addImage(logoImg, "PNG", wmX, wmY, wmWidth, wmHeight, "", "FAST");
            }

            pdf.setFontSize(48);
            pdf.setTextColor(150);
            pdf.text(
                "LJ DASHBOARD",
                pageWidth / 2,
                pageHeight / 2 + 40,
                { angle: 45, align: "center" }
            );

            if (pdf.GState) {
                pdf.setGState(new pdf.GState({ opacity: 1 }));
            }
        } catch (e) {
            console.warn("Filigrane : problème mineur", e);
        }

        pdf.setFontSize(11);
        pdf.setTextColor(120);
        pdf.text(
            `Page ${pageNum} / ${totalPages}`,
            pageWidth / 2,
            pageHeight - 20,
            { align: "center" }
        );

        pdf.setFontSize(10);
        pdf.text(
            "Document généré avec le Dashboard LJ",
            pageWidth / 2,
            pageHeight - 8,
            { align: "center" }
        );
    }

    exportBtn.addEventListener("click", async () => {
        const { jsPDF } = window.jspdf;

        const pdf = new jsPDF({
            unit: "px",
            format: "a4",
            hotfixes: ["px_scaling"]
        });

        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();

        // Logo
        const logo = new Image();
        logo.src = "assets/logo.png"; // adapte le chemin si besoin

        await new Promise(resolve => {
            logo.onload = resolve;
            logo.onerror = resolve;
        });

        await waitForCharts();

        const summaryEl = document.getElementById("summary");
        const chartsEl = document.querySelector(".charts");
        const cardsEl = document.getElementById("cardsContainer"); // mini-cards-grid
        const tableEl = document.getElementById("badgeTable");

        // PAGE DE GARDE
        pdf.setFontSize(24);
        pdf.setTextColor(20);

        if (logo.complete && logo.naturalWidth > 0) {
            pdf.addImage(logo, "PNG", 40, 40, 80, 80);
        }

        pdf.text("Analyse des Badges", 140, 80);
        pdf.setFontSize(14);
        pdf.setTextColor(80);
        pdf.text("Généré automatiquement depuis le Dashboard LJ", 140, 105);

        pdf.setFontSize(12);
        pdf.text(
            `Date de génération : ${new Date().toLocaleString()}`,
            40,
            150
        );

        // SOMMAIRE (page réservée)
        pdf.addPage();
        const tocPageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(20);
        pdf.setTextColor(20);
        pdf.text("Sommaire", 40, 60);

        const tocLines = [
            { label: "1. Résumé global", key: "resume" },
            { label: "2. Graphiques", key: "charts" },
            { label: "3. Vue cartes", key: "cards" },
            { label: "4. Tableau des badges", key: "table" }
        ];

        const tocStartY = 100;
        const tocLineHeight = 24;

        tocLines.forEach((item, index) => {
            pdf.setFontSize(13);
            pdf.setTextColor(40);
            pdf.text(item.label, 60, tocStartY + index * tocLineHeight);
        });

        // RÉSUMÉ GLOBAL
        pdf.addPage();
        const resumePageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(18);
        pdf.setTextColor(20);
        pdf.text("Résumé global", 40, 60);

        const getText = (id) => {
            const el = document.getElementById(id);
            return el ? el.textContent.trim() : "";
        };

        const resumeLines = [
            getText("total"),
            getText("completed"),
            getText("incomplete"),
            getText("average"),
            getText("updated")
        ].filter(Boolean);

        let resumeY = 100;
        pdf.setFontSize(13);
        pdf.setTextColor(40);
        resumeLines.forEach(line => {
            pdf.text(line, 60, resumeY);
            resumeY += 22;
        });

        // GRAPHIQUES
        pdf.addPage();
        const chartsPageIndex = pdf.internal.getNumberOfPages();
        await captureSection(pdf, chartsEl, pageWidth, pageHeight, "Graphiques");

        // VUE CARTES (mini-cards-grid → UNE SEULE PAGE normalement)
        pdf.addPage();
        const cardsPageIndex = pdf.internal.getNumberOfPages();
        await captureSection(pdf, cardsEl, pageWidth, pageHeight, "Vue cartes");

        // TABLEAU DES BADGES
        pdf.addPage();
        const tablePageIndex = pdf.internal.getNumberOfPages();
        await captureSection(pdf, tableEl, pageWidth, pageHeight, "Tableau des badges");

        // MISE À JOUR DU SOMMAIRE
        const totalPages = pdf.internal.getNumberOfPages();
        const pageMap = {
            resume: resumePageIndex,
            charts: chartsPageIndex,
            cards: cardsPageIndex,
            table: tablePageIndex
        };

        pdf.setPage(tocPageIndex);
        pdf.setFontSize(20);
        pdf.setTextColor(20);
        pdf.text("Sommaire", 40, 60);

        pdf.setFontSize(13);
        pdf.setTextColor(40);

        tocLines.forEach((item, index) => {
            const y = tocStartY + index * tocLineHeight;
            const label = item.label;
            const pageNum = pageMap[item.key];
            const textWidth = pdf.getTextWidth(label);

            pdf.text(label, 60, y);
            pdf.text(`... ${pageNum}`, 60 + textWidth + 10, y);
        });

        // FILIGRANE + FOOTER SUR TOUTES LES PAGES
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            addWatermarkAndFooter(
                pdf,
                pageWidth,
                pageHeight,
                i,
                totalPages,
                (logo.complete && logo.naturalWidth > 0) ? logo : null
            );
        }

        pdf.save("export.pdf");
    });
});
