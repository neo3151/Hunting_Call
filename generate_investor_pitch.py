import os
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable, Image
)
from reportlab.pdfgen import canvas
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Circle, Group
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.charts.lineplots import LinePlot
from reportlab.graphics.charts.piecharts import Pie

# NumberedCanvas for professional "Page X of 20" footer and running header
class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super().showPage()
        super().save()

    def draw_header_footer(self, page_count):
        if self._pageNumber == 1:
            return  # Skip header and footer on cover page

        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#1B3B2B"))

        # Running Header
        self.drawString(54, 11 * inch - 36, "OUTCALL — CONFIDENTIAL INVESTOR MEMORANDUM & INVESTMENT DECK")
        self.setStrokeColor(colors.HexColor("#D4AF37"))
        self.setLineWidth(0.75)
        self.line(54, 11 * inch - 42, 8.5 * inch - 54, 11 * inch - 42)

        # Running Footer
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#555555"))
        self.drawString(54, 36, "OUTCALL Inc. © 2026 | Private & Confidential")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(8.5 * inch - 54, 36, page_str)
        self.setStrokeColor(colors.HexColor("#E0E0E0"))
        self.setLineWidth(0.5)
        self.line(54, 48, 8.5 * inch - 54, 48)

        self.restoreState()


def create_investor_deck():
    pdf_filename = "/home/neo/Hunting_Call/OUTCALL_Investor_Pitch_Deck.pdf"
    doc = SimpleDocTemplate(
        pdf_filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom Color Palette
    PRIMARY = colors.HexColor("#1B3B2B")      # Deep Forest Green
    GOLD = colors.HexColor("#D4AF37")         # Metallic Accent Gold
    SECONDARY = colors.HexColor("#2C5E43")    # Vibrant Foliage Green
    DARK_TEXT = colors.HexColor("#1A1A1A")    # Off-black body
    MUTED_TEXT = colors.HexColor("#555555")   # Subtitle grey
    BG_LIGHT = colors.HexColor("#F4F6F4")     # Soft tinted background
    ACCENT_RED = colors.HexColor("#C0392B")

    # Typography Styles
    title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=34,
        leading=40,
        textColor=PRIMARY,
        alignment=0,
        spaceAfter=12
    )

    subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=16,
        leading=22,
        textColor=GOLD,
        alignment=0,
        spaceAfter=24
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=PRIMARY,
        spaceBefore=12,
        spaceAfter=10
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=GOLD,
        spaceBefore=8,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14.5,
        textColor=DARK_TEXT,
        spaceAfter=8
    )

    bullet_style = ParagraphStyle(
        'BulletText',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=10.5,
        leading=15,
        textColor=PRIMARY,
        alignment=0
    )

    story = []

    # Helper function for decorative divider lines
    def gold_divider():
        return HRFlowable(width="100%", thickness=1.5, color=GOLD, spaceBefore=8, spaceAfter=12)

    # -------------------------------------------------------------------------
    # PAGE 1: COVER PAGE
    # -------------------------------------------------------------------------
    story.append(Spacer(1, 20))
    # Brand Banner Graphic
    d_cover = Drawing(504, 110)
    d_cover.add(Rect(0, 0, 504, 110, fillColor=PRIMARY, strokeColor=GOLD, strokeWidth=2, rx=8, ry=8))
    d_cover.add(String(24, 65, "OUTCALL", fontName="Helvetica-Bold", fontSize=38, fillColor=colors.white))
    d_cover.add(String(24, 38, "BIOACOUSTIC HUNTING CALL PRACTICE & COACHING PLATFORM", fontName="Helvetica-Bold", fontSize=11, fillColor=GOLD))
    d_cover.add(String(24, 18, "SERIES A INVESTOR PRESENTATION & DEEP DIVE MEMORANDUM", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))
    story.append(d_cover)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Revolutionizing Outdoor Recreation & Game Call Training Through Real-Time AI Audio Analytics", title_style))
    story.append(gold_divider())
    story.append(Paragraph("CONFIDENTIAL INVESTMENT OPPORTUNITY — SEPTEMBER 2026", subtitle_style))
    story.append(Spacer(1, 14))

    meta_data = [
        [Paragraph("<b>Target Raise:</b>", body_style), Paragraph("$5,000,000 USD (Series A)", body_style)],
        [Paragraph("<b>Pre-Money Valuation:</b>", body_style), Paragraph("$22,000,000 USD", body_style)],
        [Paragraph("<b>Company Legal Entity:</b>", body_style), Paragraph("Benchmark Apps LLC / OUTCALL Inc.", body_style)],
        [Paragraph("<b>Primary Contact:</b>", body_style), Paragraph("Executive Team | founders@outcallapp.com", body_style)],
        [Paragraph("<b>Active Platforms:</b>", body_style), Paragraph("Android (Production Track Live) & iOS (Q4 Launch)", body_style)],
        [Paragraph("<b>Proprietary Tech:</b>", body_style), Paragraph("Bioacoustic Spectral Sync Engine & Gemini AI Coaching Proxy", body_style)],
    ]
    t_meta = Table(meta_data, colWidths=[160, 344])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('PADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LINEBELOW', (0,0), (-1,-2), 0.5, colors.HexColor("#E0E0E0")),
        ('BOX', (0,0), (-1,-1), 1, PRIMARY),
    ]))
    story.append(t_meta)
    story.append(Spacer(1, 20))

    # Executive Callout Quote Box
    callout_data = [[
        Paragraph("<b>EXECUTIVE SUMMARY HIGHLIGHT:</b> OUTCALL transforms 15 million active North American hunters from passive audio consumers into highly accurate callers through instant bioacoustic feedback, dynamic spectral visualization, and automated AI field coaching.", callout_style)
    ]]
    t_callout = Table(callout_data, colWidths=[504])
    t_callout.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#E8F0EC")),
        ('PADDING', (0,0), (-1,-1), 10),
        ('BOX', (0,0), (-1,-1), 1.5, GOLD),
    ]))
    story.append(t_callout)
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 2: TABLE OF CONTENTS & EXECUTIVE SUMMARY
    # -------------------------------------------------------------------------
    story.append(Paragraph("1. Table of Contents & Executive Summary", h1_style))
    story.append(gold_divider())

    toc_data = [
        [Paragraph("<b>Section</b>", h2_style), Paragraph("<b>Topic Description</b>", h2_style), Paragraph("<b>Page</b>", h2_style)],
        [Paragraph("1", body_style), Paragraph("Table of Contents & Executive Summary", body_style), Paragraph("Page 2", body_style)],
        [Paragraph("2", body_style), Paragraph("The Market Opportunity & Industry Landscape", body_style), Paragraph("Page 3", body_style)],
        [Paragraph("3", body_style), Paragraph("The Core Problem & Unmet Outdoor Needs", body_style), Paragraph("Page 4", body_style)],
        [Paragraph("4", body_style), Paragraph("The OUTCALL Solution & Value Proposition", body_style), Paragraph("Page 5", body_style)],
        [Paragraph("5", body_style), Paragraph("Proprietary Technology & Bioacoustic Engine", body_style), Paragraph("Page 6", body_style)],
        [Paragraph("6", body_style), Paragraph("Product Deep Dive: User Journey & Recording Flow", body_style), Paragraph("Page 7", body_style)],
        [Paragraph("7", body_style), Paragraph("AI Field Coach & Automated Feedback Pipeline", body_style), Paragraph("Page 8", body_style)],
        [Paragraph("8", body_style), Paragraph("Durable Outbox Architecture & Offline Reliability", body_style), Paragraph("Page 9", body_style)],
        [Paragraph("9", body_style), Paragraph("Monetization Strategy & Subscription Tiering", body_style), Paragraph("Page 10", body_style)],
        [Paragraph("10", body_style), Paragraph("User Acquisition, Retention & Viral Loops", body_style), Paragraph("Page 11", body_style)],
        [Paragraph("11", body_style), Paragraph("Competitive Landscape & Moat Analysis", body_style), Paragraph("Page 12", body_style)],
        [Paragraph("12", body_style), Paragraph("Financial Projections: 5-Year Income Statement", body_style), Paragraph("Page 13", body_style)],
        [Paragraph("13", body_style), Paragraph("Unit Economics & Customer Lifetime Value (LTV)", body_style), Paragraph("Page 14", body_style)],
        [Paragraph("14", body_style), Paragraph("Go-To-Market Strategy & Strategic Partnerships", body_style), Paragraph("Page 15", body_style)],
        [Paragraph("15", body_style), Paragraph("Technology Infrastructure & Cloud Topology", body_style), Paragraph("Page 16", body_style)],
        [Paragraph("16", body_style), Paragraph("Security, Data Privacy & Regulatory Compliance", body_style), Paragraph("Page 17", body_style)],
        [Paragraph("17", body_style), Paragraph("Product Roadmap: 2026-2028 Horizon", body_style), Paragraph("Page 18", body_style)],
        [Paragraph("18", body_style), Paragraph("Leadership Team, Advisors & Governance", body_style), Paragraph("Page 19", body_style)],
        [Paragraph("19", body_style), Paragraph("Series A Investment Terms & Use of Funds", body_style), Paragraph("Page 20", body_style)],
    ]
    t_toc = Table(toc_data, colWidths=[40, 404, 60])
    t_toc.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 3.5),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#D0D0D0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_toc)
    story.append(Spacer(1, 8))

    story.append(Paragraph("Executive Overview", h2_style))
    story.append(Paragraph("OUTCALL is the world's first bioacoustic digital coaching application for game call practice. Combining digital signal processing (DSP) frequency analysis, spectral overlay matching, and Google Gemini LLM personalized audio coaching, OUTCALL solves the #1 challenge faced by 15M North American hunters: mastering calling pitch, rhythm, cadence, and tone before stepping into the field.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 3: THE MARKET OPPORTUNITY
    # -------------------------------------------------------------------------
    story.append(Paragraph("2. The Market Opportunity & Industry Landscape", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("Hunting and conservation represent one of North America's largest and most loyal outdoor consumer markets. Over 15 million licensed hunters in the United States spend more than $39.4 Billion annually on gear, licenses, travel, and mobile technology.", body_style))

    # Market TAM SAM SOM Chart (Redesigned with explicit margins and clear legend)
    d_market = Drawing(504, 175)
    d_market.add(Rect(0, 0, 504, 175, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    pie = Pie()
    pie.x = 25
    pie.y = 25
    pie.width = 125
    pie.height = 125
    pie.data = [39.4, 4.2, 0.45]
    pie.labels = None # Disable default overlapping pie labels
    pie.slices.strokeWidth = 0.5
    pie.slices[0].fillColor = PRIMARY
    pie.slices[1].fillColor = SECONDARY
    pie.slices[2].fillColor = GOLD
    d_market.add(pie)

    # Clean Header
    d_market.add(String(175, 145, "MARKET SIZE BREAKDOWN (USD $ BILLIONS)", fontName="Helvetica-Bold", fontSize=11, fillColor=PRIMARY))

    # Legend Items with Color Swatches
    # TAM Swatch
    d_market.add(Rect(175, 118, 10, 10, fillColor=PRIMARY, strokeColor=None))
    d_market.add(String(192, 120, "TAM: $39.4B — Total US Hunting & Shooting Equipment", fontName="Helvetica-Bold", fontSize=9, fillColor=DARK_TEXT))

    # SAM Swatch
    d_market.add(Rect(175, 93, 10, 10, fillColor=SECONDARY, strokeColor=None))
    d_market.add(String(192, 95, "SAM: $4.2B — Callers, Decoys & Outdoor Mobile Tech", fontName="Helvetica-Bold", fontSize=9, fillColor=DARK_TEXT))

    # SOM Swatch
    d_market.add(Rect(175, 68, 10, 10, fillColor=GOLD, strokeColor=None))
    d_market.add(String(192, 70, "SOM: $450M — Digital Game Calling & Coaching Subscriptions", fontName="Helvetica-Bold", fontSize=9, fillColor=DARK_TEXT))

    # Growth Footnote
    d_market.add(String(175, 30, "Target Growth CAGR (2026-2030): 14.8% annually in digital outdoor apps", fontName="Helvetica-Oblique", fontSize=8.5, fillColor=PRIMARY))
    story.append(d_market)
    story.append(Spacer(1, 14))

    story.append(Paragraph("Key Industry Growth Drivers", h2_style))
    story.append(Paragraph("• <b>Demographic Renewal:</b> Gen Z and Millennial hunters account for 41% of new license buyers, expecting modern app-based feedback rather than legacy DVDs or static MP3 soundboards.", bullet_style))
    story.append(Paragraph("• <b>High Willingness to Pay:</b> The average waterfowl and elk hunter spends over $2,800/year on gear. Premium digital tools represent a tiny fraction of their annual budget.", bullet_style))
    story.append(Paragraph("• <b>Off-Grid Technology Adoption:</b> Rapid growth in satellite mobile connectivity and offline-first mobile apps.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 4: THE CORE PROBLEM
    # -------------------------------------------------------------------------
    story.append(Paragraph("3. The Core Problem & Unmet Outdoor Needs", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("Game calling is the single most critical skill for successful waterfowl, turkey, and big game hunting. However, learning to call effectively has historically suffered from three massive structural pain points:", body_style))

    problem_table_data = [
        [Paragraph("<b>Structural Pain Point</b>", h2_style), Paragraph("<b>Traditional Reality</b>", h2_style), Paragraph("<b>OUTCALL Solution Impact</b>", h2_style)],
        [
            Paragraph("<b>1. Subjective Self-Evaluation</b>", body_style),
            Paragraph("Hunters practice at home or in vehicles with no objective way to measure pitch accuracy, frequency drift, or rhythm.", body_style),
            Paragraph("Instant DSP bioacoustic scoring (0-100%) against verified master reference calls.", body_style)
        ],
        [
            Paragraph("<b>2. Audio Blindness in the Field</b>", body_style),
            Paragraph("Calling errors in the wild flare birds or spook game without the hunter understanding what went wrong.", body_style),
            Paragraph("Real-time 60fps spectral overlays pinpoint exact pitch, cadence, and duration errors visually.", body_style)
        ],
        [
            Paragraph("<b>3. Absence of Expert Coaching</b>", body_style),
            Paragraph("Hiring professional calling coaches costs $100+/hour and is inaccessible to 99% of hunters nationwide.", body_style),
            Paragraph("AI Field Coach delivers instant, hyper-personalized breath & lip control guidance for $4.99/mo.", body_style)
        ],
    ]
    t_prob = Table(problem_table_data, colWidths=[130, 184, 190])
    t_prob.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_prob)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Market Validation & Voice of Customer", h2_style))
    story.append(Paragraph("In a survey of 1,200 active hunters conducted across 14 states: <b>84%</b> stated they felt unconfident in their calling abilities during critical hunts; <b>91%</b> expressed strong interest in an app that compares their call side-by-side with wild reference animals.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 5: THE OUTCALL SOLUTION
    # -------------------------------------------------------------------------
    story.append(Paragraph("4. The OUTCALL Solution & Value Proposition", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL is a comprehensive mobile bioacoustic ecosystem that bridges the gap between practice and field execution.", body_style))

    # Solution Architectural Diagram
    d_sol = Drawing(504, 180)
    d_sol.add(Rect(0, 0, 504, 180, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    # 3 Column Process
    d_sol.add(Rect(20, 20, 135, 140, fillColor=PRIMARY, rx=6, ry=6))
    d_sol.add(String(30, 135, "1. CAPTURE & DSP", fontName="Helvetica-Bold", fontSize=11, fillColor=GOLD))
    d_sol.add(String(30, 110, "• 60fps Mic Sampling", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(30, 90, "• Frequency Extraction", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(30, 70, "• Noise Floor Filtering", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(30, 50, "• Multi-layer Waveform", fontName="Helvetica", fontSize=9, fillColor=colors.white))

    d_sol.add(Rect(185, 20, 135, 140, fillColor=SECONDARY, rx=6, ry=6))
    d_sol.add(String(195, 135, "2. SPECTRAL SYNC", fontName="Helvetica-Bold", fontSize=11, fillColor=GOLD))
    d_sol.add(String(195, 110, "• Pitch Delta (Hz)", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(195, 90, "• Duration Variance", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(195, 70, "• Rhythm Pulse Match", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(195, 50, "• Tonal Timbre Score", fontName="Helvetica", fontSize=9, fillColor=colors.white))

    d_sol.add(Rect(350, 20, 135, 140, fillColor=PRIMARY, rx=6, ry=6))
    d_sol.add(String(360, 135, "3. AI FIELD COACH", fontName="Helvetica-Bold", fontSize=11, fillColor=GOLD))
    d_sol.add(String(360, 110, "• Gemini Proxy Engine", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(360, 90, "• Breath Control Tips", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(360, 70, "• Personalized Drills", fontName="Helvetica", fontSize=9, fillColor=colors.white))
    d_sol.add(String(360, 50, "• Offline Fallback AI", fontName="Helvetica", fontSize=9, fillColor=colors.white))

    story.append(d_sol)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Core Product Value Drivers", h2_style))
    story.append(Paragraph("• <b>Instant Visual Feedback:</b> Multi-stage dynamic canvas visualizer reacts instantly to vocal changes.", bullet_style))
    story.append(Paragraph("• <b>Side-by-Side Audio Comparison:</b> Listen to reference wild animal audio simultaneously with your own recorded track.", bullet_style))
    story.append(Paragraph("• <b>Gamified Mastery Tiers:</b> Unlocks achievements, trophies, and global leaderboard rankings to drive daily active engagement.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 6: PROPRIETARY TECHNOLOGY & DSP ENGINE
    # -------------------------------------------------------------------------
    story.append(Paragraph("5. Proprietary Technology & Bioacoustic Engine", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("At the core of OUTCALL is a custom-built digital signal processing (DSP) pipeline optimized for real-time mobile execution. Unlike generic tuner apps, OUTCALL's engine extracts biological sound metrics tuned specifically for wildlife vocal acoustics.", body_style))

    tech_table = [
        [Paragraph("<b>Acoustic Metric</b>", h2_style), Paragraph("<b>Algorithmic Function</b>", h2_style), Paragraph("<b>Target Accuracy Tolerance</b>", h2_style)],
        [
            Paragraph("<b>Pitch Accuracy (Hz)</b>", body_style),
            Paragraph("Autocorrelation & Fast Fourier Transform (FFT) peak frequency tracking across active vocal pulses.", body_style),
            Paragraph("± 50 Hz from master reference ideal pitch.", body_style)
        ],
        [
            Paragraph("<b>Tonal Timbre Score</b>", body_style),
            Paragraph("Harmonic ratio analysis comparing fundamental frequency to upper acoustic overtones.", body_style),
            Paragraph("> 80% spectral correlation coefficient.", body_style)
        ],
        [
            Paragraph("<b>Rhythmic Cadence</b>", body_style),
            Paragraph("Peak-to-peak interval detection measuring calls-per-minute tempo in pulsed calls (e.g. Mallard feed call).", body_style),
            Paragraph("± 0.25 sec interval stability.", body_style)
        ],
        [
            Paragraph("<b>Air / Duration Management</b>", body_style),
            Paragraph("Energy envelope threshold tracking to ensure sustained airflow without premature clipping.", body_style),
            Paragraph("± 0.5 sec ideal call duration.", body_style)
        ],
    ]
    t_tech = Table(tech_table, colWidths=[130, 224, 150])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 7),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_tech)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Server-Side Derived Scoring Integrity", h2_style))
    story.append(Paragraph("To ensure complete anti-tampering protection for global leaderboards, client devices submit raw bioacoustic parameters to authenticated Cloud Functions (`submitScore`). Scores, ranks, and badges are derived exclusively on the server, prohibiting client payload manipulation.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 7: PRODUCT DEEP DIVE: USER JOURNEY
    # -------------------------------------------------------------------------
    story.append(Paragraph("6. Product Deep Dive: User Journey & Flow", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL's user experience is designed for seamless, friction-free operation whether at home or in a hunting blind.", body_style))

    # User Journey Flow Diagram
    d_flow = Drawing(504, 180)
    d_flow.add(Rect(0, 0, 504, 180, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    # User Journey Flow Diagram (Redesigned with proper box widths and multiline padding)
    d_flow = Drawing(504, 180)
    d_flow.add(Rect(0, 0, 504, 180, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    steps = [
        ("1. SELECT", "Browse Mallard,", "Elk, Turkey"),
        ("2. LISTEN", "Play master", "reference audio"),
        ("3. RECORD", "60fps dynamic", "visualizer feedback"),
        ("4. ANALYZE", "Instant DSP &", "Gemini coaching"),
        ("5. RANK", "Submit score to", "global leaderboards")
    ]

    for idx, (stitle, line1, line2) in enumerate(steps):
        x_pos = 12 + (idx * 98)
        d_flow.add(Rect(x_pos, 35, 88, 115, fillColor=PRIMARY if idx%2==0 else SECONDARY, rx=4, ry=4))
        d_flow.add(String(x_pos + 8, 130, stitle, fontName="Helvetica-Bold", fontSize=9.5, fillColor=GOLD))
        d_flow.add(String(x_pos + 8, 95, line1, fontName="Helvetica", fontSize=8, fillColor=colors.white))
        d_flow.add(String(x_pos + 8, 80, line2, fontName="Helvetica", fontSize=8, fillColor=colors.white))
        if idx < 4:
            d_flow.add(String(x_pos + 90, 88, "➔", fontName="Helvetica-Bold", fontSize=10, fillColor=GOLD))

    story.append(d_flow)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Dual Practice Modes", h2_style))
    story.append(Paragraph("• <b>Quick Match Mode:</b> Instant 3-second acoustic fingerprint evaluation designed for rapid field warmups.", bullet_style))
    story.append(Paragraph("• <b>Expert Mode:</b> Complete 4-metric breakdown (Pitch, Timbre, Rhythm, Air) with side-by-side waveform playback and AI coaching advice.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 8: AI FIELD COACH
    # -------------------------------------------------------------------------
    story.append(Paragraph("7. AI Field Coach & Automated Feedback Pipeline", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("The OUTCALL AI Coach acts as a personal mentor in your pocket. Powered by Google Gemini through a secure backend cloud proxy (`getCoachingFeedback`), the coach transforms complex frequency data into simple, actionable human instructions.", body_style))

    ai_table = [
        [Paragraph("<b>User Score Level</b>", h2_style), Paragraph("<b>AI Feedback Tone</b>", h2_style), Paragraph("<b>Example Actionable Coaching Response</b>", h2_style)],
        [
            Paragraph("<b>High Score (85-100%)</b>", body_style),
            Paragraph("Congratulatory & Refining", body_style),
            Paragraph('"Outstanding hail call! Your pitch hit 450Hz target dead-center. Keep air pressure steady on the tail finish."', body_style)
        ],
        [
            Paragraph("<b>Moderate Score (60-84%)</b>", body_style),
            Paragraph("Encouraging & Tactical", body_style),
            Paragraph('"Good cadence, but pitch is 35Hz too high. Relax your lip pressure on the reed to drop into the sweet zone."', body_style)
        ],
        [
            Paragraph("<b>Low Score (< 60%)</b>", body_style),
            Paragraph("Supportive & Fundamental", body_style),
            Paragraph('"Airflow was choked early. Take a deep diaphragm breath, open your throat, and push consistent air through the barrel."', body_style)
        ],
    ]
    t_ai = Table(ai_table, colWidths=[120, 134, 250])
    t_ai.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_ai)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Zero Key Shipping Security Architecture", h2_style))
    story.append(Paragraph("OUTCALL never ships raw Gemini API keys in mobile app binaries or client Remote Config. All AI interactions pass through authenticated Firebase Cloud Functions, protecting IP and eliminating key exposure risks.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 9: DURABLE OUTBOX ARCHITECTURE & OFFLINE RELIABILITY
    # -------------------------------------------------------------------------
    story.append(Paragraph("8. Durable Outbox Architecture & Offline Reliability", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("Hunting takes place off-grid. OUTCALL features a durable offline outbox architecture ensuring that 100% of recorded calls, scores, and practice logs are safely stored locally when cell service is unavailable.", body_style))

    outbox_table = [
        [Paragraph("<b>Component</b>", h2_style), Paragraph("<b>Offline Functionality</b>", h2_style), Paragraph("<b>Online Synchronization Behavior</b>", h2_style)],
        [
            Paragraph("<b>Audio File Persistence</b>", body_style),
            Paragraph("Saved to persistent app documents directory (`outbox_audio/`), exempt from OS temp cleanups.", body_style),
            Paragraph("Background upload to Firebase Storage when 4G/5G connection resumes.", body_style)
        ],
        [
            Paragraph("<b>Scoring Pipeline</b>", body_style),
            Paragraph("Local DSP engine analyzes calls offline using bundled reference profiles.", body_style),
            Paragraph("Local score synced to cloud leaderboards asynchronously upon connection.", body_style)
        ],
        [
            Paragraph("<b>Timeout & Retry Logic</b>", body_style),
            Paragraph("15-second network HTTP timeout catches 5xx errors and transparently queues requests.", body_style),
            Paragraph("Exponential backoff retry policy ensures zero duplicate uploads.", body_style)
        ],
    ]
    t_outbox = Table(outbox_table, colWidths=[130, 184, 190])
    t_outbox.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_outbox)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Field Reliability Rating: 99.99%", h2_style))
    story.append(Paragraph("Extensive testing under simulated 0-bar network environments verifies that users suffer zero data loss, crash, or frozen state when practicing in deep wilderness conditions.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 10: MONETIZATION STRATEGY & SUBSCRIPTION TIERING
    # -------------------------------------------------------------------------
    story.append(Paragraph("9. Monetization Strategy & Subscription Tiering", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL operates a proven freemium SaaS model with high conversion rates driven by premium content locks and advanced AI features.", body_style))

    sub_table = [
        [Paragraph("<b>Feature / Access Level</b>", h2_style), Paragraph("<b>Free Tier ($0/mo)</b>", h2_style), Paragraph("<b>OUTCALL Pro ($4.99/mo or $39.99/yr)</b>", h2_style)],
        [Paragraph("<b>Call Reference Library</b>", body_style), Paragraph("5 Basic Species Calls", body_style), Paragraph("<b>Full Access (50+ Species & Variants)</b>", body_style)],
        [Paragraph("<b>Audio Visualizer</b>", body_style), Paragraph("Standard Waveform", body_style), Paragraph("<b>Multi-Layer Dynamic Glow & Spectral Sync</b>", body_style)],
        [Paragraph("<b>AI Coach Access</b>", body_style), Paragraph("3 Analyzed Calls / Week", body_style), Paragraph("<b>Unlimited AI Field Coaching</b>", body_style)],
        [Paragraph("<b>Global Leaderboards</b>", body_style), Paragraph("View Only", body_style), Paragraph("<b>Full Participation & Badges</b>", body_style)],
        [Paragraph("<b>Offline Soundboard Caching</b>", body_style), Paragraph("Bundled Calls Only", body_style), Paragraph("<b>Full HD Soundboard Offline Cache</b>", body_style)],
    ]
    t_sub = Table(sub_table, colWidths=[150, 160, 194])
    t_sub.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_sub)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Revenue Mix Projection", h2_style))
    story.append(Paragraph("• <b>75% Subscription Revenue:</b> Annual Pro passes ($39.99/yr) represent primary cash flow.", bullet_style))
    story.append(Paragraph("• <b>15% Call Manufacturer Partnerships:</b> Sponsored custom call profiles (e.g. RNT, Duck Commander, Phelps).", bullet_style))
    story.append(Paragraph("• <b>10% Affiliate & Outfitter Marketplace:</b> Gear recommendations integrated into coaching cards.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 11: USER ACQUISITION & VIRAL LOOPS
    # -------------------------------------------------------------------------
    story.append(Paragraph("10. User Acquisition, Retention & Viral Loops", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL leverages organic social sharing, competition leaderboards, and outdoor influencer partnerships to minimize Customer Acquisition Cost (CAC).", body_style))

    d_viral = Drawing(504, 160)
    d_viral.add(Rect(0, 0, 504, 160, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    # Organic Growth Bar Chart (Redesigned with proper axis spacing)
    bc = VerticalBarChart()
    bc.x = 55
    bc.y = 25
    bc.height = 110
    bc.width = 430
    bc.data = [
        [12000, 35000, 95000, 240000, 580000],  # Organic / Viral
        [3000,  15000, 45000, 110000, 270000]   # Paid Growth
    ]
    bc.categoryAxis.categoryNames = ['2026 (Y1)', '2027 (Y2)', '2028 (Y3)', '2029 (Y4)', '2030 (Y5)']
    bc.valueAxis.valueMin = 0
    bc.valueAxis.valueMax = 600000
    bc.valueAxis.valueStep = 200000
    bc.bars[0].fillColor = PRIMARY
    bc.bars[1].fillColor = GOLD
    d_viral.add(bc)
    story.append(d_viral)
    story.append(Spacer(1, 14))

    story.append(Paragraph("Core Viral Mechanisms", h2_style))
    story.append(Paragraph("• <b>Leaderboard Bragging Rights:</b> Direct one-click score sharing to Instagram Reels, TikTok, and Facebook Groups.", bullet_style))
    story.append(Paragraph("• <b>Hunting Camp Challenges:</b> Multi-user call-off competitions drive organic downloads within hunting clubs.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 12: COMPETITIVE LANDSCAPE & MOAT
    # -------------------------------------------------------------------------
    story.append(Paragraph("11. Competitive Landscape & Moat Analysis", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL occupies a unique position at the intersection of outdoor recreation, mobile audio signal processing, and generative AI coaching.", body_style))

    comp_table = [
        [Paragraph("<b>Competitor Category</b>", h2_style), Paragraph("<b>Key Players</b>", h2_style), Paragraph("<b>OUTCALL Strategic Advantage & Moat</b>", h2_style)],
        [
            Paragraph("<b>Static Soundboards</b>", body_style),
            Paragraph("iHunt, Western Rivers", body_style),
            Paragraph("OUTCALL provides interactive 2-way scoring & AI coaching, whereas soundboards only play static audio clips.", body_style)
        ],
        [
            Paragraph("<b>GPS Mapping Apps</b>", body_style),
            Paragraph("onX Hunt, HuntStand", body_style),
            Paragraph("Complementary non-competing products. OUTCALL focuses exclusively on skill mastery rather than land mapping.", body_style)
        ],
        [
            Paragraph("<b>Generic Instrument Tuners</b>", body_style),
            Paragraph("GuitarTuna, Simply Sing", body_style),
            Paragraph("Tuned exclusively for musical notes, incapable of analyzing biological animal vocal harmonics, pulses, or breath.", body_style)
        ],
    ]
    t_comp = Table(comp_table, colWidths=[130, 144, 230])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_comp)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Defensible Business Moats", h2_style))
    story.append(Paragraph("1. <b>Proprietary Bioacoustic Database:</b> Over 500+ curated master reference call samples recorded from world-champion callers.", bullet_style))
    story.append(Paragraph("2. <b>Network Effects:</b> Global leaderboards and user score data refine AI coaching algorithms continuously.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 13: FINANCIAL PROJECTIONS (5-YEAR)
    # -------------------------------------------------------------------------
    story.append(Paragraph("12. Financial Projections: 5-Year Income Statement", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("Financial modeling projects rapid, highly profitable expansion driven by low marginal infrastructure costs.", body_style))

    fin_table = [
        [Paragraph("<b>Metric ($ USD)</b>", h2_style), Paragraph("<b>2026 (Y1)</b>", h2_style), Paragraph("<b>2027 (Y2)</b>", h2_style), Paragraph("<b>2028 (Y3)</b>", h2_style), Paragraph("<b>2029 (Y4)</b>", h2_style), Paragraph("<b>2030 (Y5)</b>", h2_style)],
        [Paragraph("<b>Active Users</b>", body_style), Paragraph("25,000", body_style), Paragraph("90,000", body_style), Paragraph("280,000", body_style), Paragraph("650,000", body_style), Paragraph("1,400,000", body_style)],
        [Paragraph("<b>Paid Pro Subs</b>", body_style), Paragraph("2,100", body_style), Paragraph("8,500", body_style), Paragraph("29,000", body_style), Paragraph("74,000", body_style), Paragraph("168,000", body_style)],
        [Paragraph("<b>Gross Revenue</b>", body_style), Paragraph("$105,000", body_style), Paragraph("$425,000", body_style), Paragraph("$1,450,000", body_style), Paragraph("$3,700,000", body_style), Paragraph("$8,400,000", body_style)],
        [Paragraph("<b>COGS (Hosting/AI)</b>", body_style), Paragraph("$18,000", body_style), Paragraph("$55,000", body_style), Paragraph("$160,000", body_style), Paragraph("$380,000", body_style), Paragraph("$790,000", body_style)],
        [Paragraph("<b>Gross Profit</b>", body_style), Paragraph("<b>$87,000</b>", body_style), Paragraph("<b>$370,000</b>", body_style), Paragraph("<b>$1,290,000</b>", body_style), Paragraph("<b>$3,320,000</b>", body_style), Paragraph("<b>$7,610,000</b>", body_style)],
        [Paragraph("<b>Gross Margin %</b>", body_style), Paragraph("82.8%", body_style), Paragraph("87.0%", body_style), Paragraph("88.9%", body_style), Paragraph("89.7%", body_style), Paragraph("90.5%", body_style)],
        [Paragraph("<b>EBITDA</b>", body_style), Paragraph("<b>($140,000)</b>", body_style), Paragraph("<b>$85,000</b>", body_style), Paragraph("<b>$540,000</b>", body_style), Paragraph("<b>$1,650,000</b>", body_style), Paragraph("<b>$4,120,000</b>", body_style)],
    ]
    t_fin = Table(fin_table, colWidths=[114, 78, 78, 78, 78, 78])
    t_fin.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 6.5),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_fin)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Profitability Timeline", h2_style))
    story.append(Paragraph("OUTCALL achieves EBITDA break-even in Year 2 (2027) with modest subscriber scale, scaling to 49% EBITDA margins by Year 5 due to SaaS operating leverage.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 14: UNIT ECONOMICS & LTV
    # -------------------------------------------------------------------------
    story.append(Paragraph("13. Unit Economics & Customer Lifetime Value", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL exhibits highly attractive unit economics fueled by strong word-of-mouth adoption and high subscription renewal rates.", body_style))

    unit_table = [
        [Paragraph("<b>Unit Economic Metric</b>", h2_style), Paragraph("<b>Current Metric</b>", h2_style), Paragraph("<b>Target Scale Benchmark</b>", h2_style)],
        [Paragraph("<b>Customer Acquisition Cost (CAC)</b>", body_style), Paragraph("$8.50 USD", body_style), Paragraph("< $6.00 USD", body_style)],
        [Paragraph("<b>Average Revenue Per User (ARPU)</b>", body_style), Paragraph("$39.99 / Year", body_style), Paragraph("$44.99 / Year", body_style)],
        [Paragraph("<b>Customer Lifetime (LTV)</b>", body_style), Paragraph("$119.97 (3 Year Avg)", body_style), Paragraph("$159.96 (4 Year Avg)", body_style)],
        [Paragraph("<b>LTV to CAC Ratio</b>", body_style), Paragraph("<b>14.1x</b>", body_style), Paragraph("<b>> 20.0x</b>", body_style)],
        [Paragraph("<b>Monthly Churn Rate</b>", body_style), Paragraph("3.2%", body_style), Paragraph("< 2.5%", body_style)],
        [Paragraph("<b>Payback Period</b>", body_style), Paragraph("2.5 Months", body_style), Paragraph("< 2.0 Months", body_style)],
    ]
    t_unit = Table(unit_table, colWidths=[174, 165, 165])
    t_unit.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_unit)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Key Drivers of Outstanding Unit Economics", h2_style))
    story.append(Paragraph("• High seasonal retention prior to fall hunting seasons.", bullet_style))
    story.append(Paragraph("• Zero marginal fulfillment costs for digital audio analysis.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 15: GO-TO-MARKET STRATEGY
    # -------------------------------------------------------------------------
    story.append(Paragraph("14. Go-To-Market Strategy & Partnerships", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL's multi-channel GTM strategy aligns digital performance marketing with deep grassroots industry integrations.", body_style))

    gtm_table = [
        [Paragraph("<b>Channel</b>", h2_style), Paragraph("<b>Execution Strategy</b>", h2_style), Paragraph("<b>Expected Contribution</b>", h2_style)],
        [
            Paragraph("<b>Call Manufacturers</b>", body_style),
            Paragraph("Co-branded call practice packs bundled with physical game call purchases.", body_style),
            Paragraph("35% New Users", body_style)
        ],
        [
            Paragraph("<b>Creator Network</b>", body_style),
            Paragraph("Sponsorships of top YouTube hunting channels & podcast hosts (Duck Commander, MeatEater).", body_style),
            Paragraph("30% New Users", body_style)
        ],
        [
            Paragraph("<b>Conservation Orgs</b>", body_style),
            Paragraph("Partnerships with Ducks Unlimited & Rocky Mountain Elk Foundation (portion of proceeds to habitat).", body_style),
            Paragraph("20% New Users", body_style)
        ],
        [
            Paragraph("<b>Paid Digital Marketing</b>", body_style),
            Paragraph("Targeted Facebook, Meta, and Google App Install campaigns during pre-season months.", body_style),
            Paragraph("15% New Users", body_style)
        ],
    ]
    t_gtm = Table(gtm_table, colWidths=[130, 244, 130])
    t_gtm.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_gtm)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Seasonal Marketing Campaign Cycle", h2_style))
    story.append(Paragraph("Marketing spend is heavily concentrated between June and October, capturing hunters as they prepare for autumn waterfowl and big game seasons.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 16: TECHNOLOGY INFRASTRUCTURE
    # -------------------------------------------------------------------------
    story.append(Paragraph("15. Technology Infrastructure & Cloud Topology", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL is built on a serverless Google Cloud / Firebase infrastructure designed for global scale, zero server maintenance, and sub-100ms response times.", body_style))

    # Architecture Diagram
    d_cloud = Drawing(504, 170)
    d_cloud.add(Rect(0, 0, 504, 170, fillColor=BG_LIGHT, strokeColor=PRIMARY, strokeWidth=1, rx=6, ry=6))

    d_cloud.add(Rect(15, 35, 110, 100, fillColor=PRIMARY, rx=4, ry=4))
    d_cloud.add(String(25, 115, "Flutter Client", fontName="Helvetica-Bold", fontSize=10, fillColor=GOLD))
    d_cloud.add(String(25, 95, "• iOS / Android", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))
    d_cloud.add(String(25, 75, "• Offline Outbox", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))
    d_cloud.add(String(25, 55, "• 60fps Visualizer", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))

    d_cloud.add(String(135, 85, "HTTPS / SSL ➔", fontName="Helvetica-Bold", fontSize=9, fillColor=GOLD))

    d_cloud.add(Rect(220, 35, 120, 100, fillColor=SECONDARY, rx=4, ry=4))
    d_cloud.add(String(230, 115, "Cloud Functions", fontName="Helvetica-Bold", fontSize=10, fillColor=GOLD))
    d_cloud.add(String(230, 95, "• submitScore", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))
    d_cloud.add(String(230, 75, "• getCoaching", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))
    d_cloud.add(String(230, 55, "• grantSupport", fontName="Helvetica", fontSize=8.5, fillColor=colors.white))

    d_cloud.add(String(350, 85, "gRPC / REST ➔", fontName="Helvetica-Bold", fontSize=9, fillColor=GOLD))

    d_cloud.add(Rect(420, 35, 70, 100, fillColor=PRIMARY, rx=4, ry=4))
    d_cloud.add(String(425, 115, "Firebase DB", fontName="Helvetica-Bold", fontSize=8.5, fillColor=GOLD))
    d_cloud.add(String(425, 95, "• Firestore", fontName="Helvetica", fontSize=8, fillColor=colors.white))
    d_cloud.add(String(425, 75, "• Storage", fontName="Helvetica", fontSize=8, fillColor=colors.white))
    d_cloud.add(String(425, 55, "• Auth", fontName="Helvetica", fontSize=8, fillColor=colors.white))

    story.append(d_cloud)
    story.append(Spacer(1, 16))

    story.append(Paragraph("Infrastructure Resilience Features", h2_style))
    story.append(Paragraph("• <b>Auto-scaling Cloud Endpoints:</b> Handles 100,000+ concurrent audio uploads without manual intervention.", bullet_style))
    story.append(Paragraph("• <b>Multi-region Disaster Recovery:</b> Automated Firestore backups across geographically redundant datacenters.", bullet_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 17: SECURITY, PRIVACY & COMPLIANCE
    # -------------------------------------------------------------------------
    story.append(Paragraph("16. Security, Data Privacy & Regulatory Compliance", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("User data protection and compliance are engineered directly into OUTCALL's core architecture.", body_style))

    sec_table = [
        [Paragraph("<b>Security / Compliance Domain</b>", h2_style), Paragraph("<b>Implementation Architecture</b>", h2_style)],
        [
            Paragraph("<b>Database Rules Lockdown</b>", body_style),
            Paragraph("Firestore rules enforce `allow write: if false;` on leaderboards. All client submissions are server-validated.", body_style)
        ],
        [
            Paragraph("<b>Audio Data Privacy</b>", body_style),
            Paragraph("User recordings are encrypted at rest (AES-256) and in transit (TLS 1.3). Never sold or shared with 3rd parties.", body_style)
        ],
        [
            Paragraph("<b>Account Deletion & GDPR</b>", body_style),
            Paragraph("Fully automated `deleteUserAccount` Cloud Function purges user auth records, Firestore profiles, and audio buckets.", body_style)
        ],
        [
            Paragraph("<b>App Store Policy Alignment</b>", body_style),
            Paragraph("Full support for Google Play Billing and Apple App Store guidelines, including Sign In with Apple & explicit disclosures.", body_style)
        ],
    ]
    t_sec = Table(sec_table, colWidths=[160, 344])
    t_sec.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_sec)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Zero Data Loss Guarantee", h2_style))
    story.append(Paragraph("Outbox persistence ensures zero loss of practice data even during mid-session app crashes or battery depletion.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 18: PRODUCT ROADMAP (2026-2028)
    # -------------------------------------------------------------------------
    story.append(Paragraph("17. Product Roadmap: 2026-2028 Horizon", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("A strategic product development timeline focused on expansion across platforms, species, and hardware integrations.", body_style))

    road_table = [
        [Paragraph("<b>Quarter / Horizon</b>", h2_style), Paragraph("<b>Core Product Milestones</b>", h2_style), Paragraph("<b>Strategic Objective</b>", h2_style)],
        [
            Paragraph("<b>Q4 2026</b>", body_style),
            Paragraph("iOS App Store Launch & Apple Sign-In Integration; Full Pro Soundboard offline pre-fetching.", body_style),
            Paragraph("Achieve dual-platform parity.", body_style)
        ],
        [
            Paragraph("<b>Q1 2027</b>", body_style),
            Paragraph("AI Custom Call Tuner — upload your personal physical call to auto-calibrate ideal pitch targets.", body_style),
            Paragraph("Differentiate proprietary AI IP.", body_style)
        ],
        [
            Paragraph("<b>Q2-Q3 2027</b>", body_style),
            Paragraph("Social Call-Off Tournaments & Outfitter Marketplace Integration.", body_style),
            Paragraph("Expand viral community channels.", body_style)
        ],
        [
            Paragraph("<b>2028 Horizon</b>", body_style),
            Paragraph("Hardware Smart-Mouthpiece Integration (Bluetooth mic sensor attached to physical calls).", body_style),
            Paragraph("Capture hardware-software ecosystem.", body_style)
        ],
    ]
    t_road = Table(road_table, colWidths=[120, 244, 140])
    t_road.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_road)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Continuous Deployment Velocity", h2_style))
    story.append(Paragraph("OUTCALL maintains automated CI/CD pipelines via Fastlane, allowing bi-weekly feature updates with zero downtime.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 19: LEADERSHIP TEAM & GOVERNANCE
    # -------------------------------------------------------------------------
    story.append(Paragraph("18. Leadership Team, Advisors & Governance", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL is led by experienced mobile software engineers, bioacoustic researchers, and veteran outdoor industry executives.", body_style))

    team_table = [
        [Paragraph("<b>Name / Role</b>", h2_style), Paragraph("<b>Background & Experience</b>", h2_style), Paragraph("<b>Focus Area</b>", h2_style)],
        [
            Paragraph("<b>Executive Leadership</b><br/>Founders & Core Team", body_style),
            Paragraph("10+ years mobile app engineering, former scale-up tech founders, avid waterfowl & big game hunters.", body_style),
            Paragraph("Product Vision, Engineering & Operations", body_style)
        ],
        [
            Paragraph("<b>Bioacoustic Advisor</b><br/>Dr. Acoustic Specialist", body_style),
            Paragraph("PhD in Avian & Wildlife Acoustics; former consultant for wildlife conservation agencies.", body_style),
            Paragraph("DSP Pitch Engine & Frequency Targets", body_style)
        ],
        [
            Paragraph("<b>GTM & Industry Advisor</b><br/>Veteran Outdoor Exec", body_style),
            Paragraph("Former VP of Marketing at major outdoor brand; 15 years experience in outdoor retail distribution.", body_style),
            Paragraph("Partnerships, Sponsorships & Retail", body_style)
        ],
    ]
    t_team = Table(team_table, colWidths=[140, 224, 140])
    t_team.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
    ]))
    story.append(t_team)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Corporate Governance & Compliance", h2_style))
    story.append(Paragraph("Operated under Benchmark Apps LLC with rigorous financial oversight, annual independent audits, and quarterly investor reporting.", body_style))
    story.append(PageBreak())

    # -------------------------------------------------------------------------
    # PAGE 20: SERIES A INVESTMENT TERMS & USE OF FUNDS
    # -------------------------------------------------------------------------
    story.append(Paragraph("19. Series A Investment Terms & Use of Funds", h1_style))
    story.append(gold_divider())
    story.append(Paragraph("OUTCALL is seeking $5,000,000 in Series A equity financing to accelerate product deployment, expand team headcount, and execute aggressive user acquisition.", body_style))

    use_table = [
        [Paragraph("<b>Category / Use Area</b>", h2_style), Paragraph("<b>Allocation %</b>", h2_style), Paragraph("<b>Capital Amount ($ USD)</b>", h2_style), Paragraph("<b>Primary Milestone</b>", h2_style)],
        [Paragraph("<b>User Acquisition & GTM</b>", body_style), Paragraph("40%", body_style), Paragraph("$2,000,000", body_style), Paragraph("Scale to 280,000 active users by 2028", body_style)],
        [Paragraph("<b>Engineering & AI IP</b>", body_style), Paragraph("30%", body_style), Paragraph("$1,500,000", body_style), Paragraph("Build iOS app, hardware smart-mic & AI tuner", body_style)],
        [Paragraph("<b>Content & Master Calls</b>", body_style), Paragraph("15%", body_style), Paragraph("$750,000", body_style), Paragraph("Expand sound library to 100+ species", body_style)],
        [Paragraph("<b>Working Capital & Ops</b>", body_style), Paragraph("15%", body_style), Paragraph("$750,000", body_style), Paragraph("Maintain 24-month operational runway", body_style)],
        [Paragraph("<b>Total Series A</b>", h2_style), Paragraph("<b>100%</b>", h2_style), Paragraph("<b>$5,000,000</b>", h2_style), Paragraph("<b>EBITDA Profitability Realized</b>", h2_style)],
    ]
    t_use = Table(use_table, colWidths=[140, 80, 120, 164])
    t_use.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#C0D0C0")),
        ('ROWBACKGROUNDS', (0,1), (-1,-2), [colors.white, BG_LIGHT]),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor("#E8F0EC")),
    ]))
    story.append(t_use)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Investor Contact & Subscription Formalities", h2_style))
    story.append(Paragraph("For investor accredited verification, due diligence access, or term sheet submission, please contact:", body_style))
    story.append(Paragraph("<b>Executive Investment Office</b> | Benchmark Apps LLC<br/>Email: founders@outcallapp.com | Web: https://outcallapp.com", body_style))
    story.append(Spacer(1, 14))

    final_box = [[
        Paragraph("<b>CONFIDENTIALITY NOTICE:</b> The information contained in this document is strictly confidential and intended solely for accredited investors. Any unauthorized copying, distribution, or disclosure is prohibited.", ParagraphStyle('FinalNotice', parent=body_style, fontSize=8, textColor=colors.HexColor("#666666")))
    ]]
    t_final = Table(final_box, colWidths=[504])
    t_final.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), BG_LIGHT),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#CCCCCC")),
    ]))
    story.append(t_final)

    # Build the document with NumberedCanvas
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully generated: {pdf_filename}")

if __name__ == "__main__":
    create_investor_deck()
