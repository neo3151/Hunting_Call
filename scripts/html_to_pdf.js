const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
    console.log('[██░░░░░░░░] 10% | Launching headless browser...');
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    
    const htmlPath = path.resolve('C:\\Users\\neo31\\Hunting_Call\\OUTCALL_Full_Remediation_Report.html');
    const pdfPath = path.resolve('C:\\Users\\neo31\\Hunting_Call\\OUTCALL_Full_Remediation_Report.pdf');
    
    console.log('[████░░░░░░] 30% | Loading report...');
    await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`, { waitUntil: 'networkidle2', timeout: 30000 });
    
    console.log('[██████░░░░] 50% | Waiting for Mermaid diagrams to render...');
    await new Promise(r => setTimeout(r, 6000));
    
    console.log('[████████░░] 70% | Generating PDF...');
    await page.pdf({
        path: pdfPath,
        format: 'A4',
        printBackground: true,
        margin: { top: '20mm', bottom: '20mm', left: '15mm', right: '15mm' },
        displayHeaderFooter: true,
        headerTemplate: '<div style="font-size:8px;color:#888;width:100%;text-align:center;font-family:Inter,sans-serif;">OUTCALL Architecture, Security & Performance Audit — March 2026</div>',
        footerTemplate: '<div style="font-size:8px;color:#888;width:100%;text-align:center;font-family:Inter,sans-serif;">Page <span class="pageNumber"></span> of <span class="totalPages"></span></div>',
    });
    
    console.log('[██████████] 100% | PDF generated successfully!');
    console.log(`Output: ${pdfPath}`);
    
    await browser.close();
})();
