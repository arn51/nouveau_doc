document.addEventListener("DOMContentLoaded", () => {

    const exportBtn = document.getElementById("exportPDF");

    if (!exportBtn) {
        console.error("Le bouton exportPDF est introuvable !");
        return;
    }

    function waitForCharts() {
        return new Promise(resolve => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    setTimeout(resolve, 150);
                });
            });
        });
    }

    async function loadImageAsDataURL(path) {
        try {
            const blob = await fetch(path).then(r => r.blob());
            return await new Promise(resolve => {
                const reader = new FileReader();
                reader.onload = () => resolve(reader.result);
                reader.readAsDataURL(blob);
            });
        } catch (e) {
            console.error("Erreur chargement image :", e);
            return null;
        }
    }

    // 🔥 VERSION ÉQUILIBRÉE
    async function captureSection(pdf, element, pageWidth, pageHeight, title) {

        if (!element) {
            console.warn("Section introuvable :", title);
            return;
        }

        // 🔥 Scale final équilibré + améliorations demandées
        let scale = 1.0;

        if (title === "Graphiques") scale = 1.35;          // ➜ Graphiques plus grands
        if (title === "Vue cartes") scale = 0.95;          // ➜ Déjà OK
        if (title === "Tableau des badges") scale = 1.25;  // ➜ Tableau plus lisible

        const canvas = await html2canvas(element, {
            scale: scale,
            useCORS: true
        });

        const imgData = canvas.toDataURL("image/jpeg", 0.92);

        const marginX = 40;
        const marginTop = 110;
        const maxWidth = pageWidth - marginX * 2;

        let imgHeight = canvas.height * (maxWidth / canvas.width);

        // 🔥 Limite de hauteur pour éviter débordement
        const maxHeight = pageHeight - 180;
        if (imgHeight > maxHeight) imgHeight = maxHeight;

        pdf.setFontSize(18);
        pdf.setTextColor(20);
        pdf.text(title, marginX, 60);

        pdf.addImage(imgData, "JPEG", marginX, marginTop, maxWidth, imgHeight, "", "FAST");
    }

    function addWatermarkAndFooter(pdf, pageWidth, pageHeight, pageNum, totalPages, logoData) {

        try {
            if (logoData) {
                const g = new pdf.GState({ opacity: 0.12 });
                pdf.setGState(g);

                const wmWidth = pageWidth * 0.35;
                const wmHeight = wmWidth;
                const wmX = (pageWidth - wmWidth) / 2;
                const wmY = (pageHeight - wmHeight) / 2;

                pdf.addImage(logoData, "PNG", wmX, wmY, wmWidth, wmHeight, "", "FAST");
            }

            pdf.setFontSize(48);
            pdf.setTextColor(150);
            pdf.text(
                "LJ DASHBOARD",
                pageWidth / 2,
                pageHeight / 2 + 40,
                { angle: 45, align: "center" }
            );

            if (pdf.GState) pdf.setGState(new pdf.GState({ opacity: 1 }));
        } catch (e) {}

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

        const logoData = await loadImageAsDataURL("assets/logo.png");

        await waitForCharts();

        const summaryEl = document.getElementById("summary");
        const chartsEl = document.querySelector(".charts");
        const cardsEl = document.getElementById("cardsContainer");
        const tableEl = document.getElementById("badgeTable");

        // PAGE DE GARDE
        pdf.setFontSize(24);
        pdf.setTextColor(20);

        if (logoData) {
            pdf.addImage(logoData, "PNG", 40, 40, 80, 80);
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

        // SOMMAIRE
        pdf.addPage();
        const tocPageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(20);
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
            pdf.text(item.label, 60, tocStartY + index * tocLineHeight);
        });

        // RÉSUMÉ GLOBAL
        pdf.addPage();
        const resumePageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(18);
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
        resumeLines.forEach(line => {
            pdf.text(line, 60, resumeY);
            resumeY += 22;
        });

        // GRAPHIQUES
        pdf.addPage();
        const chartsPageIndex = pdf.internal.getNumberOfPages();
        await captureSection(pdf, chartsEl, pageWidth, pageHeight, "Graphiques");

        // VUE CARTES
        pdf.addPage();
        const cardsPageIndex = pdf.internal.getNumberOfPages();
        await captureSection(pdf, cardsEl, pageWidth, pageHeight, "Vue cartes");

        // TABLEAU DES BADGES
        pdf.addPage();
        const tablePageIndex = pdf.internal.getNumberOfPages();

        // On calcule le nombre total de pages
        const totalPages = pdf.internal.getNumberOfPages();

        // On crée pageMap IMMÉDIATEMENT après

        const pageMap = {
            resume: resumePageIndex,
            charts: chartsPageIndex,
            cards: cardsPageIndex,
            table: tablePageIndex
        };

        // 👉 Rendre visible avant capture
        tableEl.classList.remove("hidden");

        await captureSection(pdf, tableEl, pageWidth, pageHeight, "Tableau des badges");

        // 👉 Re-masquer après capture
        tableEl.classList.add("hidden");

        // MISE À JOUR DU SOMMAIRE (CLICABLE)
        pdf.setPage(tocPageIndex);
        pdf.setFontSize(20);
        pdf.text("Sommaire", 40, 60);

        pdf.setFontSize(13);

        tocLines.forEach((item, index) => {
            const y = tocStartY + index * tocLineHeight;
            const label = item.label;
            const pageNum = pageMap[item.key];

            // Affichage du texte
            pdf.text(label, 60, y);

            // Largeur du texte pour créer la zone cliquable
            const textWidth = pdf.getTextWidth(label);

            // 🔥 Zone cliquable
            pdf.link(
                60,               // x
                y - 10,           // y (un peu au-dessus du texte)
                textWidth + 4,    // largeur
                14,               // hauteur
                { pageNumber: pageNum }
            );

            // Numéro de page affiché
            pdf.text(`... ${pageNum}`, 60 + textWidth + 10, y);
        });


        // FILIGRANE + FOOTER
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            addWatermarkAndFooter(
                pdf,
                pageWidth,
                pageHeight,
                i,
                totalPages,
                logoData
            );
        }

        pdf.save("export.pdf");
    });
});
