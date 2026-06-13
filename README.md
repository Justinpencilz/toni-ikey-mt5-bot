# Toni Iyke Advanced Class — MT5 Bot (Stage 1)

**Building Toni Iyke's trading strategy from scratch — one concept at a time.**

> Based on January 2026 Advanced Class video recordings.  
> Stage 1 = Market Structure only. More stages to follow.

---

## ✅ Stage 1: Market Structure (Complete)

What's implemented, mapped strictly to the video definitions:

### A. Three Basic Patterns
| Pattern | Definition |
|---------|-----------|
| **Uptrend** | Series of Higher Highs + Higher Lows |
| **Downtrend** | Series of Lower Highs + Lower Lows |
| **Ranging** | Sideways between support & resistance |

### B. Two Core Trading Concepts
| Concept | Signal | What It Does |
|---------|--------|-------------|
| **MSS** (Market Structure Shift) | Reversal | Current trend ending, new trend beginning |
| **BOS** (Break of Structure) | Continuation | Maintaining current trend direction |

### C. Key Rules
- **MSS** occurs at a **valid zone** (HTF POI) — zone detection comes in Stage 5
- **Single BOS** (only 1 level broken) → **IGNORE**
- **Multiple/Double BOS** (2+ levels) → **VALID for trading**
- Continuations traded **many more times** than reversals

### D. Directional Bias (Stage 1 Preview)
- HTF uptrend → overall bullish → look for buys
- HTF downtrend → overall bearish → look for sells
- HTF is for bias only — DO NOT trade on HTF

---

## 📁 File Structure (Current)
```
toni-ikey-mt5-bot/
├── Experts/
│   ├── include/
│   │   ├── Strategy.mqh           # Enums, structs, constants
│   │   └── MarketStructure.mqh    # Swing points, trend, MSS, BOS, trendlines
│   └── Toni_Ikey_Strategy.mq5     # Main EA (detection + display)
├── README.md
└── (more files added per stage)
```

---

## ⚙️ Installation

**Copy to MT5:**
```
Experts/Toni_Ikey_Strategy.mq5  →  <data>/MQL5/Experts/
Experts/include/*.mqh            →  <data>/MQL5/Include/
```

**Compile:** Open MetaEditor (F4) → Select EA → F7

---

## 📐 Input Parameters (Stage 1)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpTFTrend` | H1 | Timeframe for structure detection |
| `InpTFBias` | D1 | Higher timeframe for directional bias |
| `InpSwingLookback` | 100 | Bars to scan for swing points |
| `InpSwingBars` | 3 | Bars each side to confirm a swing |
| `InpMSSLookback` | 20 | Bars to scan for MSS |
| `InpBOSLookback` | 30 | Bars to scan for BOS |
| `InpShowLabels` | true | Display info labels on chart |

---

## 🗺️ Coming Next (Per Your Instructions)

1. ✅ **Market Structure** ← You are here
2. ⬜ **Liquidity** (Inducement — the pullback after MSS/BOS)
3. ⬜ **Points of Interest** (Order Blocks & Breaker Blocks)
4. ⬜ **The 4 Rules for POI selection**
5. ⬜ **Liquidity TP Zones**
6. ⬜ **Directional Bias** (full integration)

---

## 🔗 Links
- [GitHub Repository](https://github.com/Justinpencilz/toni-ikey-mt5-bot)
