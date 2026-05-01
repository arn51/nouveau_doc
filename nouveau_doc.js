document.addEventListener("DOMContentLoaded", () => {

    const exportBtn = document.getElementById("exportPDF");

    if (!exportBtn) {
        console.error("Le bouton exportPDF est introuvable !");
        return;
    }

    // Attendre que Chart.js ait fini son rendu
    function waitForCharts() {
        return new Promise(resolve => {
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    setTimeout(resolve, 100);
                });
            });
        });
    }

    // Capture d'une section HTML en image + découpage multi-pages
    async function addSectionCapture(pdf, element, pageWidth, pageHeight, title) {
        console.log("addSectionCapture →", title, element);

        if (!element) {
            console.warn(`Section manquante pour : ${title}`);
            return;
        }

        // Forcer visibilité
        const previousDisplay = element.style.display;
        element.style.display = "block";

        // Capture
        const canvas = await html2canvas(element, {
            scale: 2,
            useCORS: true,
            windowWidth: document.documentElement.clientWidth,
            windowHeight: document.documentElement.clientHeight
        });

        element.style.display = previousDisplay;

        const imgData = canvas.toDataURL("image/png");

        const marginX = 30;
        const marginTop = 70;
        const maxWidth = pageWidth - marginX * 2;
        const imgHeight = canvas.height * (maxWidth / canvas.width);

        // Titre
        pdf.setFontSize(18);
        pdf.setTextColor(20);
        pdf.text(title, marginX, 40);

        // Si l’image tient sur une page
        if (imgHeight <= pageHeight - marginTop - 40) {
            pdf.addImage(imgData, "PNG", marginX, marginTop, maxWidth, imgHeight, "", "FAST");
            return;
        }

        // Découpage multi-pages
        let remainingHeight = imgHeight;
        let offsetY = 0;

        while (remainingHeight > 0) {
            const sliceHeight = Math.min(remainingHeight, pageHeight - marginTop - 40);

            pdf.addImage(
                imgData,
                "PNG",
                marginX,
                marginTop,
                maxWidth,
                imgHeight,
                "",
                "FAST",
                0,
                offsetY
            );

            remainingHeight -= sliceHeight;
            offsetY += sliceHeight;

            if (remainingHeight > 0) {
                pdf.addPage();
            }
        }
    }

    // Filigrane + footer
    function addWatermarkAndFooter(pdf, pageWidth, pageHeight, pageNum, totalPages, logo) {

        // Filigrane image
        if (logo) {
            try {
                pdf.setGState(new pdf.GState({ opacity: 0.12 }));
                const wmWidth = pageWidth * 0.35;
                const wmHeight = wmWidth;
                const wmX = (pageWidth - wmWidth) / 2;
                const wmY = (pageHeight - wmHeight) / 2;
                pdf.addImage(logo, "PNG", wmX, wmY, wmWidth, wmHeight, "", "FAST");
            } catch (e) {
                console.warn("Filigrane image non appliqué :", e);
            }
        }

        // Filigrane texte
        pdf.setFontSize(48);
        pdf.setTextColor(150);
        pdf.text(
            "LJ DASHBOARD",
            pageWidth / 2,
            pageHeight / 2 + 40,
            { angle: 45, align: "center" }
        );

        if (pdf.GState) pdf.setGState(new pdf.GState({ opacity: 1 }));

        // Footer
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
            "Document généré avec PDF PRO",
            pageWidth / 2,
            pageHeight - 8,
            { align: "center" }
        );
    }

    exportBtn.addEventListener("click", async () => {
        console.log("exportPDF cliqué");

        if (!window.jspdf) {
            console.error("jsPDF n'est pas chargé !");
            return;
        }

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
        logo.src = "/nouveau_doc/assets/logo.png";

        await new Promise(resolve => {
            logo.onload = resolve;
            logo.onerror = () => {
                console.warn("Logo non chargé.");
                resolve();
            };
        });

        await waitForCharts();

        // Sections HTML
        const summaryEl = document.getElementById("summary");
        const chartsEl = document.querySelector(".charts");
        const cardsEl = document.getElementById("cardsContainer");
        const tableEl = document.getElementById("badgeTable");

        // =========================
        // 1) PAGE DE GARDE
        // =========================
        pdf.setFontSize(24);
        pdf.setTextColor(20);

        if (logo.complete) {
            pdf.addImage(logo, "PNG", 40, 40, 80, 80);
        }

        pdf.text("Analyse des Badges — Avril 2026", 140, 80);
        pdf.setFontSize(14);
        pdf.setTextColor(80);
        pdf.text("Généré automatiquement depuis le Dashboard LJ", 140, 105);

        pdf.setFontSize(12);
        pdf.text(
            `Date de génération : ${new Date().toLocaleString()}`,
            40,
            150
        );

        // =========================
        // 2) SOMMAIRE
        // =========================
        pdf.addPage();
        const tocPageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(20);
        pdf.setTextColor(20);
        pdf.text("Sommaire", 40, 60);

        pdf.setFontSize(13);
        pdf.setTextColor(60);

        const tocLines = [
            { label: "1. Résumé global", key: "resume" },
            { label: "2. Graphiques", key: "charts" },
            { label: "3. Vue cartes", key: "cards" },
            { label: "4. Tableau des badges", key: "table" }
        ];

        let tocStartY = 100;
        const tocLineHeight = 24;

        tocLines.forEach((item, index) => {
            pdf.text(item.label, 60, tocStartY + index * tocLineHeight);
        });

        // =========================
        // 3) RÉSUMÉ GLOBAL (NATIF)
        // =========================
        pdf.addPage();
        const resumePageIndex = pdf.internal.getNumberOfPages();

        pdf.setFontSize(18);
        pdf.setTextColor(20);
        pdf.text("Résumé global", 40, 60);

        pdf.setFontSize(13);
        pdf.setTextColor(40);

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
        const resumeLineHeight = 22;

        resumeLines.forEach(line => {
            pdf.text(line, 60, resumeY);
            resumeY += resumeLineHeight;
        });

        // =========================
        // 4) GRAPHIQUES
        // =========================
        pdf.addPage();
        const chartsPageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, chartsEl, pageWidth, pageHeight, "Graphiques");

        // =========================
        // 5) VUE CARTES
        // =========================
        pdf.addPage();
        const cardsPageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, cardsEl, pageWidth, pageHeight, "Vue cartes");

        // =========================
        // 6) TABLEAU DES BADGES
        // =========================
        pdf.addPage();
        const tablePageIndex = pdf.internal.getNumberOfPages();
        await addSectionCapture(pdf, tableEl, pageWidth, pageHeight, "Tableau des badges");

        // =========================
        // 7) COMPLÉTER LE SOMMAIRE
        // =========================
        const totalPages = pdf.internal.getNumberOfPages();

        pdf.setPage(tocPageIndex);
        pdf.setFontSize(13);
        pdf.setTextColor(60);

        const pageMap = {
            resume: resumePageIndex,
            charts: chartsPageIndex,
            cards: cardsPageIndex,
            table: tablePageIndex
        };

        tocLines.forEach((item, index) => {
            const y = tocStartY + index * tocLineHeight;
            const pageNum = pageMap[item.key];
            const label = item.label;
            const textWidth = pdf.getTextWidth(label);

            pdf.text(label, 60, y);
            pdf.text(`... ${pageNum}`, 60 + textWidth + 10, y);
        });

        // =========================
        // 8) FILIGRANE + FOOTER
        // =========================
        for (let i = 1; i <= totalPages; i++) {
            pdf.setPage(i);
            addWatermarkAndFooter(pdf, pageWidth, pageHeight, i, totalPages, logo.complete ? logo : null);
        }

        // =========================
        // 9) SAUVEGARDE
        // =========================
        pdf.save("export.pdf");
    });
});
