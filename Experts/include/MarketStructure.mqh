//+------------------------------------------------------------------+
//|                                          MarketStructure.mqh     |
//|           Stage 1: Market Structure Detection                    |
//|  Strictly based on Toni Iyke Advanced Class definitions          |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+

MarketStructure g_ms;              // Current market structure state
SwingPoint g_swingHighs[];         // All detected swing highs (sorted by time, [0]=recent)
SwingPoint g_swingLows[];          // All detected swing lows (sorted by time, [0]=recent)

//+------------------------------------------------------------------+
//| Initialize / Reset                                               |
//+------------------------------------------------------------------+

void InitMarketStructure()
{
   g_ms.trend = TREND_NONE;
   g_ms.hasMSS = false;
   g_ms.hasBOS = false;
   g_ms.bosBreaksCount = 0;
   g_ms.hhCount = 0;
   g_ms.hlCount = 0;
   g_ms.lhCount = 0;
   g_ms.llCount = 0;
   
   ArrayFree(g_swingHighs);
   ArrayFree(g_swingLows);
   
   ZeroMemory(g_ms.uptrendLine);
   ZeroMemory(g_ms.downtrendLine);
   ZeroMemory(g_ms.rangeResistance);
   ZeroMemory(g_ms.rangeSupport);
}

//+------------------------------------------------------------------+
//| 1. SWING POINT DETECTION                                         |
//| Finds swing highs (peaks) and swing lows (troughs)               |
//| A swing high = bar whose high is higher than bars on both sides  |
//| A swing low  = bar whose low  is lower  than bars on both sides  |
//+------------------------------------------------------------------+

void DetectSwingPoints(string symbol, ENUM_TIMEFRAMES tf, int lookbackBars)
{
   ArrayFree(g_swingHighs);
   ArrayFree(g_swingLows);
   
   int bars = Bars(symbol, tf);
   if(bars < lookbackBars + SWING_BARS_LOOKBACK + 2) return;
   
   int startBar = MathMin(lookbackBars, bars - SWING_BARS_LOOKBACK - 2);
   
   for(int i = SWING_BARS_LOOKBACK; i < startBar; i++)
   {
      double currentHigh = iHigh(symbol, tf, i);
      double currentLow  = iLow(symbol, tf, i);
      
      // Check if bar i is a swing high:
      // High must be higher than both left and right neighbors
      bool isSwingHigh = true;
      for(int j = 1; j <= SWING_BARS_LOOKBACK; j++)
      {
         if(currentHigh <= iHigh(symbol, tf, i - j) || currentHigh <= iHigh(symbol, tf, i + j))
         {
            isSwingHigh = false;
            break;
         }
      }
      
      if(isSwingHigh)
      {
         int size = ArraySize(g_swingHighs);
         ArrayResize(g_swingHighs, size + 1);
         g_swingHighs[size].time     = iTime(symbol, tf, i);
         g_swingHighs[size].price    = currentHigh;
         g_swingHighs[size].isHigh   = true;
         g_swingHighs[size].barIndex = i;
      }
      
      // Check if bar i is a swing low:
      // Low must be lower than both left and right neighbors
      bool isSwingLow = true;
      for(int j = 1; j <= SWING_BARS_LOOKBACK; j++)
      {
         if(currentLow >= iLow(symbol, tf, i - j) || currentLow >= iLow(symbol, tf, i + j))
         {
            isSwingLow = false;
            break;
         }
      }
      
      if(isSwingLow)
      {
         int size = ArraySize(g_swingLows);
         ArrayResize(g_swingLows, size + 1);
         g_swingLows[size].time     = iTime(symbol, tf, i);
         g_swingLows[size].price    = currentLow;
         g_swingLows[size].isHigh   = false;
         g_swingLows[size].barIndex = i;
      }
   }
   
   // Sort both arrays by time descending (most recent first)
   // Array is filled from oldest (index 0) to newest, so newest is at end
   // Let's reverse to have [0] = most recent
   ArrayReverse(g_swingHighs);
   ArrayReverse(g_swingLows);
}

//+------------------------------------------------------------------+
//| 2. TREND IDENTIFICATION                                          |
//| Definition 1:                                                    |
//|   Uptrend  = series of Higher Highs AND Higher Lows              |
//|   Downtrend = series of Lower Highs AND Lower Lows               |
//+------------------------------------------------------------------+

ENUM_TREND_DIRECTION DetermineTrend(string symbol, ENUM_TIMEFRAMES tf)
{
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // Need at least 2 highs and 2 lows for comparison
   if(hCount < 2 || lCount < 2)
   {
      g_ms.trend = TREND_NONE;
      return TREND_NONE;
   }
   
   // Reset counters
   g_ms.hhCount = 0;
   g_ms.hlCount = 0;
   g_ms.lhCount = 0;
   g_ms.llCount = 0;
   
   // Compare consecutive swing highs: is each HIGHER than previous?
   // (arrays sorted [0]=recent, so [0] current, [1] previous, [2] before that)
   int checkPairs = MathMin(3, hCount - 1);
   for(int i = 0; i < checkPairs; i++)
   {
      // g_swingHighs[i] is more recent than g_swingHighs[i+1]
      // In an uptrend: more recent high > older high (Higher High)
      // In a downtrend: more recent high < older high (Lower High)
      if(g_swingHighs[i].price > g_swingHighs[i + 1].price)
         g_ms.hhCount++;   // Higher High: recent > previous
      else if(g_swingHighs[i].price < g_swingHighs[i + 1].price)
         g_ms.lhCount++;   // Lower High: recent < previous
   }
   
   // Compare consecutive swing lows
   checkPairs = MathMin(3, lCount - 1);
   for(int i = 0; i < checkPairs; i++)
   {
      // In an uptrend: more recent low > older low (Higher Low)
      // In a downtrend: more recent low < older low (Lower Low)
      if(g_swingLows[i].price > g_swingLows[i + 1].price)
         g_ms.hlCount++;   // Higher Low: recent > previous
      else if(g_swingLows[i].price < g_swingLows[i + 1].price)
         g_ms.llCount++;   // Lower Low: recent < previous
   }
   
   // --- Classification (Definition 1) ---
   // Uptrend: both highs AND lows are rising (at least 1 pair each confirms)
   if(g_ms.hhCount >= 1 && g_ms.hlCount >= 1)
   {
      g_ms.trend = TREND_UPTREND;
      
      // Store last valid swing reference points
      g_ms.lastSwingHigh = g_swingHighs[0];
      g_ms.lastSwingLow  = g_swingLows[0];
      if(hCount >= 2) g_ms.prevSwingHigh = g_swingHighs[1];
      if(lCount >= 2) g_ms.prevSwingLow  = g_swingLows[1];
      
      return TREND_UPTREND;
   }
   
   // Downtrend: both highs AND lows are falling (at least 1 pair each confirms)
   if(g_ms.lhCount >= 1 && g_ms.llCount >= 1)
   {
      g_ms.trend = TREND_DOWNTREND;
      
      g_ms.lastSwingHigh = g_swingHighs[0];
      g_ms.lastSwingLow  = g_swingLows[0];
      if(hCount >= 2) g_ms.prevSwingHigh = g_swingHighs[1];
      if(lCount >= 2) g_ms.prevSwingLow  = g_swingLows[1];
      
      return TREND_DOWNTREND;
   }
   
   // Range: check if price is moving sideways between support and resistance
   // (neither uptrend nor downtrend confirmed + price within a band)
   double highestHigh = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 20, 1));
   double lowestLow   = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 20, 1));
   double atr = iATR(symbol, tf, 14, 0);
   double range = highestHigh - lowestLow;
   
   // If range is small relative to ATR, it's ranging behavior
   // If range is large but no clear HH/HL or LH/LL, it's still NONE (choppy)
   if(range < atr * 2.0)
   {
      g_ms.trend = TREND_RANGING;
      return TREND_RANGING;
   }
   
   g_ms.trend = TREND_NONE;
   return TREND_NONE;
}

//+------------------------------------------------------------------+
//| 3. TRENDLINE CONSTRUCTION (Definition 1)                         |
//|                                                                   |
//| Uptrend:   draw a line connecting TWO OR MORE HIGHER LOWS         |
//|            (lows that are progressively higher), slanted upward.  |
//|            Line extends to the right.                             |
//|                                                                   |
//| Downtrend: draw a line connecting TWO OR MORE LOWER HIGHS         |
//|            (highs that are progressively lower), slanted downward.|
//|            Line extends to the right.                             |
//|                                                                   |
//| Range:     draw a STRAIGHT HORIZONTAL line connecting highs       |
//|            (resistance), and another connecting lows (support).   |
//+------------------------------------------------------------------+

void BuildTrendlines(string symbol, ENUM_TIMEFRAMES tf)
{
   ZeroMemory(g_ms.uptrendLine);
   ZeroMemory(g_ms.downtrendLine);
   ZeroMemory(g_ms.rangeResistance);
   ZeroMemory(g_ms.rangeSupport);
   
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // ---- UPTREND LINE ----
   // Find the 2 most recent swing lows. In a confirmed uptrend
   // (HH/HL sequence), the most recent low should be higher than
   // the previous low. Connect them.
   if(g_ms.trend == TREND_UPTREND && lCount >= 2)
   {
      // Try the 2 most recent lows first
      double lowA = g_swingLows[1].price;  // Older
      double lowB = g_swingLows[0].price;  // Newer
      datetime timeA = g_swingLows[1].time;
      datetime timeB = g_swingLows[0].time;
      
      // In a valid uptrend, the newer low should be higher
      if(lowB > lowA)
      {
         g_ms.uptrendLine.valid = true;
         g_ms.uptrendLine.point1Price = lowA;
         g_ms.uptrendLine.point1Time  = timeA;
         g_ms.uptrendLine.point2Price = lowB;
         g_ms.uptrendLine.point2Time  = timeB;
         
         double priceDiff = lowB - lowA;
         double timeDiff  = (double)(timeB - timeA);
         if(timeDiff > 0) g_ms.uptrendLine.slope = priceDiff / timeDiff;
      }
      else
      {
         // If the 2 most recent don't form HL, scan for 2 that do
         for(int i = 0; i < lCount - 1; i++)
         {
            if(g_swingLows[i].price > g_swingLows[i + 1].price)
            {
               g_ms.uptrendLine.valid = true;
               g_ms.uptrendLine.point1Price = g_swingLows[i + 1].price;
               g_ms.uptrendLine.point1Time  = g_swingLows[i + 1].time;
               g_ms.uptrendLine.point2Price = g_swingLows[i].price;
               g_ms.uptrendLine.point2Time  = g_swingLows[i].time;
               
               double priceDiff = g_swingLows[i].price - g_swingLows[i + 1].price;
               double timeDiff  = (double)(g_swingLows[i].time - g_swingLows[i + 1].time);
               if(timeDiff > 0) g_ms.uptrendLine.slope = priceDiff / timeDiff;
               break;
            }
         }
      }
   }
   
   // ---- DOWNTREND LINE ----
   // Find the 2 most recent swing highs. In a confirmed downtrend
   // (LH/LL sequence), the most recent high should be lower than
   // the previous high. Connect them.
   if(g_ms.trend == TREND_DOWNTREND && hCount >= 2)
   {
      double highA = g_swingHighs[1].price;  // Older
      double highB = g_swingHighs[0].price;  // Newer
      datetime timeA = g_swingHighs[1].time;
      datetime timeB = g_swingHighs[0].time;
      
      // In a valid downtrend, the newer high should be lower
      if(highB < highA)
      {
         g_ms.downtrendLine.valid = true;
         g_ms.downtrendLine.point1Price = highA;
         g_ms.downtrendLine.point1Time  = timeA;
         g_ms.downtrendLine.point2Price = highB;
         g_ms.downtrendLine.point2Time  = timeB;
         
         double priceDiff = highB - highA;  // negative = downward slope
         double timeDiff  = (double)(timeB - timeA);
         if(timeDiff > 0) g_ms.downtrendLine.slope = priceDiff / timeDiff;
      }
      else
      {
         for(int i = 0; i < hCount - 1; i++)
         {
            if(g_swingHighs[i].price < g_swingHighs[i + 1].price)
            {
               g_ms.downtrendLine.valid = true;
               g_ms.downtrendLine.point1Price = g_swingHighs[i + 1].price;
               g_ms.downtrendLine.point1Time  = g_swingHighs[i + 1].time;
               g_ms.downtrendLine.point2Price = g_swingHighs[i].price;
               g_ms.downtrendLine.point2Time  = g_swingHighs[i].time;
               
               double priceDiff = g_swingHighs[i].price - g_swingHighs[i + 1].price;
               double timeDiff  = (double)(g_swingHighs[i].time - g_swingHighs[i + 1].time);
               if(timeDiff > 0) g_ms.downtrendLine.slope = priceDiff / timeDiff;
               break;
            }
         }
      }
   }
   
   // ---- RANGE: STRAIGHT HORIZONTAL LINES ----
   if(g_ms.trend == TREND_RANGING)
   {
      // Resistance: find the two highest swing highs and average them
      // (horizontal line connecting highs)
      if(hCount >= 2)
      {
         // Use the highest swing highs for resistance
         double highest = g_swingHighs[0].price;
         double secondHighest = highest;
         datetime resTime = g_swingHighs[0].time;
         
         for(int i = 1; i < hCount; i++)
         {
            if(g_swingHighs[i].price > highest)
               highest = g_swingHighs[i].price;
            else if(g_swingHighs[i].price > secondHighest)
            {
               secondHighest = g_swingHighs[i].price;
               resTime = g_swingHighs[i].time;
            }
         }
         
         double resLevel = (highest + secondHighest) / 2.0;
         
         g_ms.rangeResistance.valid = true;
         g_ms.rangeResistance.point1Price = resLevel;
         g_ms.rangeResistance.point1Time  = g_swingHighs[hCount - 1].time;
         g_ms.rangeResistance.point2Price = resLevel;  // Same = horizontal
         g_ms.rangeResistance.point2Time  = g_swingHighs[0].time;
         g_ms.rangeResistance.slope = 0;
      }
      
      // Support: find the two lowest swing lows and average them
      if(lCount >= 2)
      {
         double lowest = g_swingLows[0].price;
         double secondLowest = lowest;
         datetime supTime = g_swingLows[0].time;
         
         for(int i = 1; i < lCount; i++)
         {
            if(g_swingLows[i].price < lowest)
               lowest = g_swingLows[i].price;
            else if(g_swingLows[i].price < secondLowest)
            {
               secondLowest = g_swingLows[i].price;
               supTime = g_swingLows[i].time;
            }
         }
         
         double supLevel = (lowest + secondLowest) / 2.0;
         
         g_ms.rangeSupport.valid = true;
         g_ms.rangeSupport.point1Price = supLevel;
         g_ms.rangeSupport.point1Time  = g_swingLows[lCount - 1].time;
         g_ms.rangeSupport.point2Price = supLevel;  // Same = horizontal
         g_ms.rangeSupport.point2Time  = g_swingLows[0].time;
         g_ms.rangeSupport.slope = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| 4. MARKET STRUCTURE SHIFT (MSS) — REVERSAL CONCEPT (Definition 2)|
//|                                                                   |
//| MSS = price breaks the pattern of the current trend, indicating  |
//|       the current trend is ending and a new one is beginning.     |
//|                                                                   |
//| In uptrend: price must take out the LAST HIGHER LOW and close    |
//|             below it with body → signals sell reversal            |
//| In downtrend: price must take out the LAST LOWER HIGH and close  |
//|              above it with body → signals buy reversal            |
//|                                                                   |
//| MSS must occur at a VALID ZONE (HTF POI) to be considered        |
//| reliable (Definition 5). Zone-checking is external.              |
//+------------------------------------------------------------------+

bool DetectMSS(string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   g_ms.hasMSS = false;
   
   int bars = Bars(symbol, tf);
   int checkBars = MathMin(barsBack, bars - 2);
   if(checkBars < 10) return false;
   
   // Re-run swing detection and trend identification
   DetectSwingPoints(symbol, tf, checkBars);
   DetermineTrend(symbol, tf);
   
   // MSS requires a trending market (not ranging) - Definition 2: Reversal is for trending ONLY
   if(g_ms.trend == TREND_NONE || g_ms.trend == TREND_RANGING) return false;
   
   ENUM_TREND_DIRECTION currentTrend = g_ms.trend;
   
   // --- MSS in UPTREND (sell reversal) ---
   // Current pattern: Higher Highs + Higher Lows
   // MSS occurs when price takes out the LAST HIGHER LOW and closes below it
   if(currentTrend == TREND_UPTREND)
   {
      int lCount = ArraySize(g_swingLows);
      if(lCount < 1) return false;
      
      double lastHigherLow = g_swingLows[0].price;  // Most recent swing low
      
      // Check if current market has broken below that higher low
      // Need candle that took it out and closed below the level with body
      for(int i = 1; i <= MathMin(5, checkBars); i++)
      {
         double candleLow  = iLow(symbol, tf, i);
         double candleClose = iClose(symbol, tf, i);
         
         // Candle must trade below the last higher low
         if(candleLow < lastHigherLow)
         {
            // MSS condition: body must close below the level (Definition 2 - "close below with body")
            if(candleClose < lastHigherLow)
            {
               g_ms.hasMSS = true;
               g_ms.mssTime = iTime(symbol, tf, i);
               g_ms.mssBrokenLevel = lastHigherLow;
               g_ms.mssIsBullish = false;  // MSS to downside = sell reversal
               
               // Store the MSS time for inducement tracking (next stage)
               return true;
            }
         }
         else
         {
            // Price hasn't reached the level yet, stop looking
            break;
         }
      }
   }
   
   // --- MSS in DOWNTREND (buy reversal) ---
   // Current pattern: Lower Highs + Lower Lows
   // MSS occurs when price takes out the LAST LOWER HIGH and closes above it
   if(currentTrend == TREND_DOWNTREND)
   {
      int hCount = ArraySize(g_swingHighs);
      if(hCount < 1) return false;
      
      double lastLowerHigh = g_swingHighs[0].price;  // Most recent swing high
      
      // Check if current market has broken above that lower high
      for(int i = 1; i <= MathMin(5, checkBars); i++)
      {
         double candleHigh = iHigh(symbol, tf, i);
         double candleClose = iClose(symbol, tf, i);
         
         // Candle must trade above the last lower high
         if(candleHigh > lastLowerHigh)
         {
            // MSS condition: body must close above the level
            if(candleClose > lastLowerHigh)
            {
               g_ms.hasMSS = true;
               g_ms.mssTime = iTime(symbol, tf, i);
               g_ms.mssBrokenLevel = lastLowerHigh;
               g_ms.mssIsBullish = true;  // MSS to upside = buy reversal
               return true;
            }
         }
         else
         {
            break;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 5. BREAK OF STRUCTURE (BOS) — CONTINUATION CONCEPT (Definition 2)|
//|                                                                   |
//| BOS = Any candle whose FULL BODY (close) breaks a swing level.    |
//|       Not just a wick touch — the candle must CLOSE beyond it.    |
//|                                                                   |
//| Uptrend BOS:  candle close > previous swing high                  |
//| Downtrend BOS: candle close < previous swing low                  |
//|                                                                   |
//| CRITICAL RULE — Single vs Multiple BOS:                          |
//|   Single BOS (only 1 level body-broken)  → IGNORE                |
//|   Multiple/Double BOS (2+ levels body-broken) → valid for trading |
//+------------------------------------------------------------------+

bool DetectBOS(string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   g_ms.hasBOS = false;
   g_ms.bosBreaksCount = 0;
   
   int bars = Bars(symbol, tf);
   int checkBars = MathMin(barsBack, bars - 2);
   if(checkBars < 10) return false;
   
   // Re-run swing detection and trend identification
   DetectSwingPoints(symbol, tf, checkBars);
   DetermineTrend(symbol, tf);
   
   // BOS requires a trending market
   if(g_ms.trend != TREND_UPTREND && g_ms.trend != TREND_DOWNTREND)
      return false;
   
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // ---- BOS in UPTREND ----
   // Any candle whose FULL BODY breaks previous swing highs
   if(g_ms.trend == TREND_UPTREND)
   {
      if(hCount < 2) return false;
      
      int breaks = 0;
      
      // Walk back through recent candles — any one that closed above a swing high = BOS
      for(int b = 1; b <= MathMin(5, checkBars); b++)
      {
         double barClose = iClose(symbol, tf, b);
         int barBreaks = 0;
         
         for(int i = 0; i < hCount; i++)
         {
            // Full body break: close must be ABOVE the swing high
            if(barClose > g_swingHighs[i].price)
               barBreaks++;
         }
         
         if(barBreaks > breaks)
            breaks = barBreaks;
      }
      
      g_ms.bosBreaksCount = breaks;
      
      if(breaks >= 1)
      {
         g_ms.hasBOS = true;
         g_ms.bosIsBullish = true;
         return true;
      }
   }
   
   // ---- BOS in DOWNTREND ----
   // Any candle whose FULL BODY breaks previous swing lows
   if(g_ms.trend == TREND_DOWNTREND)
   {
      if(lCount < 2) return false;
      
      int breaks = 0;
      
      for(int b = 1; b <= MathMin(5, checkBars); b++)
      {
         double barClose = iClose(symbol, tf, b);
         int barBreaks = 0;
         
         for(int i = 0; i < lCount; i++)
         {
            // Full body break: close must be BELOW the swing low
            if(barClose < g_swingLows[i].price)
               barBreaks++;
         }
         
         if(barBreaks > breaks)
            breaks = barBreaks;
      }
      
      g_ms.bosBreaksCount = breaks;
      
      if(breaks >= 1)
      {
         g_ms.hasBOS = true;
         g_ms.bosIsBullish = false;
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 6. RANGE BREAKOUT (Definition 2 - Continuation for Range)       |
//| When price breaks out of a range, expect retest of the broken    |
//| level before continuation in the breakout direction              |
//+------------------------------------------------------------------+

bool DetectRangeBreakout(string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   // First establish if we're in a range
   DetectSwingPoints(symbol, tf, barsBack);
   DetermineTrend(symbol, tf);
   
   if(g_ms.trend != TREND_RANGING) return false;
   
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   if(hCount < 2 || lCount < 2) return false;
   
   // Get range boundaries
   double resistance = g_swingHighs[0].price;  // Top of range
   double support    = g_swingLows[0].price;   // Bottom of range
   
   // Check if recent bars have broken out of the range (full body break)
   for(int b = 1; b <= MathMin(5, checkBars); b++)
   {
      double barHigh  = iHigh(symbol, tf, b);
      double barLow   = iLow(symbol, tf, b);
      double barClose = iClose(symbol, tf, b);
      
      // Breakout above resistance — full body must close above it
      if(barClose > resistance)
      {
         g_ms.hasBOS = true;
         g_ms.bosBreaksCount = 1;
         g_ms.bosIsBullish = true;
         return true;
      }
      
      // Breakout below support — full body must close below it
      if(barClose < support)
      {
         g_ms.hasBOS = true;
         g_ms.bosBreaksCount = 1;
         g_ms.bosIsBullish = false;
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 7. COMPLETE STRUCTURE UPDATE                                     |
//| Convenience function that runs all detection in correct order    |
//+------------------------------------------------------------------+

void UpdateMarketStructure(string symbol, ENUM_TIMEFRAMES tf, int lookbackBars)
{
   // 1. Detect swing points
   DetectSwingPoints(symbol, tf, lookbackBars);
   
   // 2. Identify current trend
   DetermineTrend(symbol, tf);
   
   // 3. Build trendlines
   BuildTrendlines(symbol, tf);
   
   // 4. Detect MSS (reversal)
   DetectMSS(symbol, tf, lookbackBars);
   
   // 5. Detect BOS (continuation) - for both trending and ranging
   if(g_ms.trend == TREND_RANGING)
      DetectRangeBreakout(symbol, tf, lookbackBars);
   else
      DetectBOS(symbol, tf, lookbackBars);
}

//+------------------------------------------------------------------+
//| 8. HELPER: Get a string description of current structure         |
//+------------------------------------------------------------------+

string MarketStructureToString()
{
   string trendStr = "";
   
   switch(g_ms.trend)
   {
      case TREND_UPTREND:    trendStr = "UPTREND"; break;
      case TREND_DOWNTREND:  trendStr = "DOWNTREND"; break;
      case TREND_RANGING:    trendStr = "RANGING"; break;
      default:               trendStr = "NONE"; break;
   }
   
   string info = "Trend: " + trendStr;
   
   // Add trend sequence info
   if(g_ms.trend == TREND_UPTREND)
      info += " [HH:" + IntegerToString(g_ms.hhCount) + " HL:" + IntegerToString(g_ms.hlCount) + "]";
   else if(g_ms.trend == TREND_DOWNTREND)
      info += " [LH:" + IntegerToString(g_ms.lhCount) + " LL:" + IntegerToString(g_ms.llCount) + "]";
   
   // Add MSS info
   if(g_ms.hasMSS)
   {
      info += " | MSS at " + DoubleToString(g_ms.mssBrokenLevel, _Digits);
      info += " (" + (g_ms.mssIsBullish ? "BUY REVERSAL" : "SELL REVERSAL") + ")";
   }
   
   // Add BOS info
   if(g_ms.hasBOS)
   {
      info += " | BOS x" + IntegerToString(g_ms.bosBreaksCount) + " ";
      info += "(" + (g_ms.bosIsBullish ? "BULLISH" : "BEARISH") + ")";
      
      if(g_ms.bosBreaksCount < BOS_MIN_MULTIPLE)
         info += " [IGNORE - single BOS]";
      else
         info += " [VALID - multiple BOS]";
   }
   
   return info;
}

//+------------------------------------------------------------------+
//| 9. HELPER: Check if a level is a HTF POI zone                    |
//| (Simple - will be expanded in Stage 2 - POI detection)           |
//+------------------------------------------------------------------+

bool IsPriceAtHTFPOI(string symbol, ENUM_TIMEFRAMES htf, double price)
{
   // Placeholder - will check if price is at a daily OB or BB
   // This links to Stage 5 - Zone detection for reversal
   return false;
}

//+------------------------------------------------------------------+
