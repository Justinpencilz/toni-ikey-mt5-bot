//+------------------------------------------------------------------+
//|                                          MarketStructure.mqh     |
//|             Market Structure detection based on Toni Iyke        |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| GLOBALS (per-symbol)                                              |
//+------------------------------------------------------------------+

MarketStructure g_marketStructure;
SwingPoint g_swingHighs[];    // Array of detected swing highs
SwingPoint g_swingLows[];     // Array of detected swing lows

//+------------------------------------------------------------------+
//| Initialize market structure                                      |
//+------------------------------------------------------------------+

void InitMarketStructure()
{
   g_marketStructure.trend = TREND_NONE;
   g_marketStructure.hasMSS = false;
   g_marketStructure.hasMBS = false;
   g_marketStructure.breaksCount = 0;
   ArrayFree(g_swingHighs);
   ArrayFree(g_swingLows);
}

//+------------------------------------------------------------------+
//| Detect swing points on given timeframe                           |
//+------------------------------------------------------------------+

void DetectSwingPoints(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   ArrayFree(g_swingHighs);
   ArrayFree(g_swingLows);

   int bars = MathMin(lookback, Bars(symbol, tf) - 3);
   if(bars < 10) return;

   for(int i = 2; i < bars; i++)
   {
      double high   = iHigh(symbol, tf, i);
      double low    = iLow(symbol, tf, i);
      double prevH  = iHigh(symbol, tf, i+1);
      double prevL  = iLow(symbol, tf, i+1);
      double nextH  = iHigh(symbol, tf, i-1);
      double nextL  = iLow(symbol, tf, i-1);

      // Swing High: current bar has higher high than both neighbors
      if(high > prevH && high >= nextH)
      {
         int size = ArraySize(g_swingHighs);
         ArrayResize(g_swingHighs, size + 1);
         g_swingHighs[size].time    = iTime(symbol, tf, i);
         g_swingHighs[size].price   = high;
         g_swingHighs[size].isHigh  = true;
         g_swingHighs[size].index   = i;
      }

      // Swing Low: current bar has lower low than both neighbors
      if(low < prevL && low <= nextL)
      {
         int size = ArraySize(g_swingLows);
         ArrayResize(g_swingLows, size + 1);
         g_swingLows[size].time    = iTime(symbol, tf, i);
         g_swingLows[size].price   = low;
         g_swingLows[size].isHigh  = false;
         g_swingLows[size].index   = i;
      }
   }
}

//+------------------------------------------------------------------+
//| Determine current trend from detected swings                     |
//+------------------------------------------------------------------+

ENUM_TREND_DIRECTION DetermineTrend(string symbol, ENUM_TIMEFRAMES tf)
{
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);

   if(hCount < 2 || lCount < 2) return TREND_NONE;

   // Sort by time (recent first)
   // Check last 3 swing highs and last 3 swing lows
   int check = MathMin(3, MathMin(hCount, lCount));

   int higherHighCount = 0;
   int higherLowCount  = 0;
   int lowerHighCount  = 0;
   int lowerLowCount   = 0;

   for(int i = 0; i < check - 1; i++)
   {
      // Check highs: each subsequent high should be compared
      if(g_swingHighs[i].price > g_swingHighs[i+1].price)
         higherHighCount++;
      else if(g_swingHighs[i].price < g_swingHighs[i+1].price)
         lowerHighCount++;

      // Check lows
      if(g_swingLows[i].price > g_swingLows[i+1].price)
         higherLowCount++;
      else if(g_swingLows[i].price < g_swingLows[i+1].price)
         lowerLowCount++;
   }

   // Trending criteria from Toni Iyke: need 2-3 series of HH/HL or LH/LL
   bool isUptrend = (higherHighCount >= 1 && higherLowCount >= 1);
   bool isDowntrend = (lowerHighCount >= 1 && lowerLowCount >= 1);

   if(isUptrend && !isDowntrend) return TREND_UPTREND;
   if(isDowntrend && !isUptrend) return TREND_DOWNT REND;

   // Check if ranging
   double atr = iATR(symbol, tf, 14, 0);
   double range = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, 20, 0))
                - iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, 20, 0));

   if(range < atr * 1.5) return TREND_RANGING;

   return TREND_NONE;
}

//+------------------------------------------------------------------+
//| Detect Market Structure Shift (MSS - Reversal Concept)           |
//| MSS = price breaks the LAST opposing swing point                 |
//| In uptrend: price breaks the last higher low (goes below it)     |
//| In downtrend: price breaks the last lower high (goes above it)   |
//+------------------------------------------------------------------+

bool DetectMSS(string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   int bars = MathMin(barsBack, Bars(symbol, tf) - 2);
   if(bars < 10) return false;

   ENUM_TREND_DIRECTION trend = DetermineTrend(symbol, tf);

   if(trend == TREND_UPTREND)
   {
      // For MSS to the downside in an uptrend:
      // Price must take out the last higher low
      double lastHL = FindLastSwingLow(symbol, tf, bars);
      if(lastHL == 0) return false;

      // Check if current close is below that last higher low
      double currentClose = iClose(symbol, tf, 1);
      if(currentClose < lastHL)
      {
         g_marketStructure.hasMSS    = true;
         g_marketStructure.mssTime   = iTime(symbol, tf, 1);
         g_marketStructure.mssLevel  = lastHL;
         g_marketStructure.trend     = TREND_DOWNT REND;
         return true;
      }
   }
   else if(trend == TREND_DOWNT REND)
   {
      // For MSS to the upside in a downtrend:
      // Price must take out the last lower high
      double lastLH = FindLastSwingHigh(symbol, tf, bars);
      if(lastLH == 0) return false;

      double currentClose = iClose(symbol, tf, 1);
      if(currentClose > lastLH)
      {
         g_marketStructure.hasMSS    = true;
         g_marketStructure.mssTime   = iTime(symbol, tf, 1);
         g_marketStructure.mssLevel  = lastLH;
         g_marketStructure.trend     = TREND_UPTREND;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Multiple Break of Structure (MBS - Continuation Concept) |
//| MBS = price breaks MORE THAN ONE zone (internal + external)      |
//| while maintaining current trend direction                        |
//+------------------------------------------------------------------+

bool DetectMBS(string symbol, ENUM_TIMEFRAMES tf, int barsBack)
{
   int bars = MathMin(barsBack, Bars(symbol, tf) - 2);
   if(bars < 15) return false;

   ENUM_TREND_DIRECTION trend = DetermineTrend(symbol, tf);
   if(trend != TREND_UPTREND && trend != TREND_DOWNT REND) return false;

   int breaks = 0;

   if(trend == TREND_UPTREND)
   {
      // Count how many previous swing highs have been broken
      double currentHigh = iHigh(symbol, tf, 1);
      for(int i = 0; i < ArraySize(g_swingHighs); i++)
      {
         if(g_swingHighs[i].price < currentHigh)
            breaks++;
      }
   }
   else if(trend == TREND_DOWNT REND)
   {
      // Count how many previous swing lows have been broken
      double currentLow = iLow(symbol, tf, 1);
      for(int i = 0; i < ArraySize(g_swingLows); i++)
      {
         if(g_swingLows[i].price > currentLow)
            breaks++;
      }
   }

   // Toni Iyke: MBS requires more than 1 zone broken (internal + external)
   if(breaks >= 2)
   {
      g_marketStructure.hasMBS      = true;
      g_marketStructure.breaksCount = breaks;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Find the last swing low (higher low in uptrend context)          |
//+------------------------------------------------------------------+

double FindLastSwingLow(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   int size = ArraySize(g_swingLows);
   if(size == 0) return 0;

   // Return the most recent (first in array since sorted by time descending)
   return g_swingLows[0].price;
}

//+------------------------------------------------------------------+
//| Find the last swing high (lower high in downtrend context)       |
//+------------------------------------------------------------------+

double FindLastSwingHigh(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   int size = ArraySize(g_swingHighs);
   if(size == 0) return 0;

   return g_swingHighs[0].price;
}

//+------------------------------------------------------------------+
//| Get internal vs external zone status for a swing point           |
//| Internal = made during current trend                             |
//| External = made during previous opposite trend                   |
//+------------------------------------------------------------------+

bool IsInternalZone(double swingPrice, ENUM_TREND_DIRECTION trend, string symbol, ENUM_TIMEFRAMES tf)
{
   // Internal zones belong to the current trend structure
   // External zones were created when price was in the opposite trend
   // Simplified: most recent swings are internal, older swings are external

   if(trend == TREND_UPTREND)
   {
      // Higher highs and higher lows are internal
      // Lower highs and lower lows from previous downtrend are external
      int hCount = ArraySize(g_swingHighs);
      return (hCount > 0 && swingPrice >= g_swingLows[0].price);
   }
   else if(trend == TREND_DOWNT REND)
   {
      int lCount = ArraySize(g_swingLows);
      return (lCount > 0 && swingPrice <= g_swingHighs[0].price);
   }

   return true;
}
//+------------------------------------------------------------------+
