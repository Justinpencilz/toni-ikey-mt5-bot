# Toni Iyke Advanced Class — MT5 Expert Advisor

**A fully automated MT5 trading bot based on Toni Iyke's January 2026 Advanced Class strategy.**

> Built from 5+ hours of live trading video analysis — Market Structure, Order Blocks,
> Breaker Blocks, Inducement, Liquidity & Directional Bias — all coded into MQL5.

---

## 🧠 Strategy Overview (4 Pillars)

This EA implements the exact 4-pillar framework taught by Toni Iyke:

### 1. Market Structure
| Concept | Description |
|---------|-------------|
| **Uptrend** | Series of Higher Highs (HH) + Higher Lows (HL) |
| **Downtrend** | Series of Lower Highs (LH) + Lower Lows (LL) |
| **Range** | Sideways consolidation between support/resistance |
| **MSS** (Market Structure Shift) | Price breaks the last opposing swing point → **Reversal signal** |
| **MBS** (Multiple Break of Structure) | Price breaks 2+ zones (internal + external) → **Continuation signal** |

### 2. Inducement
The **first valid pullback** after MSS or MBS that takes out the **body close** of the trigger candle.

### 3. Points of Interest (POI)
Two types of zones where price is expected to react:

| POI Type | Description |
|----------|-------------|
| **Order Block (OB)** | Last candle before an impulsive move. Bullish OB = last bearish candle before a rally. Bearish OB = last bullish candle before a sell-off. |
| **Breaker Block (BB)** | A failed OB — a zone where a reversal was expected but price broke through it. The body of the broken zone becomes the BB. |

**The 4 Rules for choosing the right POI:**

1. ✅ Must have MSS or MBS structure first
2. ✅ Must have a valid inducement
3. ❌ Mitigation: any POI the inducement touches is **disqualified**
4. 🎯 Among remaining POIs, pick the **closest to the inducement**

### 4. Directional Bias & Liquidity TP
- Determine bias from the **daily timeframe** (HH/HL = bullish, LH/LL = bearish)
- Only take entries **aligned with the daily bias**
- TP is set using **liquidity zones**:
  - **Trendline Liquidity** (most common) — TP at the origin of the previous trend
  - **Range Liquidity** — TP at the opposite side of the range
  - **Last Swing High/Low** — fallback TP level

---

## 📁 File Structure

```
toni-ikey-mt5-bot/
├── Experts/
│   ├── include/
│   │   ├── Strategy.mqh           # Core enums, structs, constants, settings
│   │   ├── MarketStructure.mqh    # Swing detection, trend, MSS, MBS
│   │   ├── OrderBlocks.mqh        # OB & BB detection, 4 Rules filter
│   │   ├── Inducement.mqh         # Inducement detection
│   │   ├── Liquidity.mqh          # TP via liquidity zones
│   │   ├── DirectionalBias.mqh    # Daily bias & correction zones
│   │   └── RiskManager.mqh        # Lot sizing, SL calculation, RR check
│   └── Toni_Ikey_Strategy_EA.mq5  # Main Expert Advisor
├── Indicators/
│   └── (optional — OSD display indicators)
├── Scripts/
│   └── (optional — manual entry helpers)
├── README.md
└── LICENSE
```

---

## ⚙️ Installation

**Copy to MT5 → File → Open Data Folder → MQL5:**

```
Experts/Toni_Ikey_Strategy_EA.mq5  →  <data>/MQL5/Experts/
Experts/include/*.mqh               →  <data>/MQL5/Include/  (then #include them from main EA)
```

Or simply copy the entire `Experts/` folder into `<data>/MQL5/`.

**Compile:**
1. Open MetaEditor (F4 in MT5)
2. Select `Toni_Ikey_Strategy_EA.mq5`
3. Press F7 to compile

---

## 📐 Settings Guide

### Timeframes
| Setting | Default | Notes |
|---------|---------|-------|
| `BiasTF` | D1 | Daily timeframe for directional bias |
| `EntryTF` | H1 | Lower timeframe for MSS/POI entry |

### Market Structure
| Setting | Default | Notes |
|---------|---------|-------|
| `SwingLookback` | 50 | Bars to scan for swing points |
| `MinSwingPercent` | 0.3 | Minimum swing as % of ATR |
| `MSSConfirmationBars` | 1 | Bars after MSS to confirm |

### Inducement
| Setting | Default | Notes |
|---------|---------|-------|
| `IDMBodyPercent` | 0.3 | % of candle body that must be taken out |

### POI
| Setting | Default | Notes |
|---------|---------|-------|
| `MaxPOIDistance` | 3.0 | Max distance from IDM in ATR units |

### Risk
| Setting | Default | Notes |
|---------|---------|-------|
| `RiskMode` | Percent | Fixed lot or % of balance |
| `RiskPercent` | 1.0 | % risk per trade |
| `FixedLot` | 0.01 | Lot size when fixed mode |
| `MinRR` | 1.5 | Min risk-reward ratio |

### TP Method
| Setting | Default | Notes |
|---------|---------|-------|
| `UseTrendlineTP` | true | Trendline liquidity TP (most common) |
| `UseRangeTP` | true | Range liquidity TP |
| `UseLastSwingTP` | true | Last swing HL fallback |

### Filters
| Setting | Default | Notes |
|---------|---------|-------|
| `UseBiasFilter` | true | Only trade with daily bias |
| `ReversalOnly` | false | Skip MBS, only MSS |
| `ContinuationOnly` | false | Skip MSS, only MBS |

---

## 🧪 Recommended Pairs

| Pair | Notes |
|------|-------|
| **EURUSD** | Best for ICT/SMC strategies |
| **GBPUSD** | Good trending behavior |
| **USDJPY** | Clean structure |
| **XAUUSD (Gold)** | Volatile but respects liquidity zones |
| **BTCUSD** | Works with the strategy (as shown in class) |

---

## ⚠️ Important Notes

- This EA was developed from **Toni Iyke's January Advanced Class 2026** video recordings
- It implements **manual trading concepts** in automated form — always **backtest** extensively
- The strategy is **price-action based** — works best on higher timeframes (H1+)
- Market structure detection requires sufficient swing data — avoid low-liquidity pairs
- The 4 Rules for POI selection are the core of the strategy's edge

---

## 📜 License

MIT License — use freely, modify, and share.

---

## 🔗 Links

- [GitHub Repository](https://github.com/Justinpencilz/toni-ikey-mt5-bot)
- [Toni Iyke](https://t.me/toniiyke) (Telegram)
