//+------------------------------------------------------------------+
//|                                             Liquidity.mqh        |
//|      Liquidity zone detection & TP level calculation             |
//|       3 TP methods: Trendline, Range, Last Swing                 |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

LiquidityZone g_tpZone;

//+------------------------------------------------------------------+
//| Detect Trendline Liquidity (most common)                         |
//| In uptrend: draw trendline from origin of previous downtrend     |
//|   TP = clear that trendline level (buy-side liquidity above)     |
//| In downtrend: draw trendline from origin of previous uptrend     |
//|   TP = clear that trendline level (sell-side liquidity below)    |
//+------------------------------------------------------------------+

bool DetectTrendlineLiquidity(
   string symbol,
   ENUM_TIMEFRAMES tf,
   MarketStructure &ms,
   int lookback
)
{
   int bars = MathMin(lookback, Bars(symbol, tf) - 10);
   if(bars < 20) return false;

   // For reversal concept: TP = previous trend origin
   if(ms.trend == TREND_UPTREND)
   {
      // After MSS to upside, previous trend was downtrend
      // Find the origin of that downtrend (highest high before the sell-off)
      int highestBar = iHighest(symbol, tf, MODE_HIGH, bars, 1);
      if(highestBar < 0) return false;

      g_tpZone.priceHigh    = iHigh(symbol, tf, highestBar);
      g_tpZone.priceLow     = g_tpZone.priceHigh * 0.995; // 0.5% zone
      g_tpZone.isBuySide    = true;
      g_tpZone.isSellSide   = false;
      g_tpZone.isTrendline  = true;
      g_tpZone.isRange      = false;

      // Draw trendline: connect the highs of the previous downtrend
      return true;
   }
   else if(ms.trend == TREND_DOWNT REND)
   {
      // After MSS to downside, previous trend was uptrend
      // Find the origin of that uptrend (lowest low before the rally)
      int lowestBar = iLowest(symbol, tf, MODE_LOW, bars, 1);
      if(lowestBar < 0) return false;

      g_tpZone.priceHigh    = iLow(symbol, tf, lowestBar) * 1.005; // 0.5% zone
      g_tpZone.priceLow     = iLow(symbol, tf, lowestBar);
      g_tpZone.isBuySide    = false;
      g_tpZone.isSellSide   = true;
      g_tpZone.isTrendline  = true;
      g_tpZone.isRange      = false;

      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Range Liquidity                                           |
//| Market ranges = liquidity on BOTH sides (buy side & sell side)   |
//| TP = opposite side of the range                                  |
//+------------------------------------------------------------------+

bool DetectRangeLiquidity(
   string symbol,
   ENUM_TIMEFRAMES tf,
   MarketStructure &ms,
   double entryPrice,
   bool isBuy
)
{
   // Find the range: look for consolidation (20 bars with tight range)
   int bars = 20;
   double rangeHigh = iHigh(symbol, tf, iHighest(symbol, tf, MODE_HIGH, bars, 1));
   double rangeLow  = iLow(symbol, tf, iLowest(symbol, tf, MODE_LOW, bars, 1));
   double atr = iATR(symbol, tf, 14, 1);

   // Check if this looks like a range (tight consolidation)
   if((rangeHigh - rangeLow) / atr > 2.0) return false; // Not a range

   // Range detected - TP is the opposite side
   if(isBuy)
   {
      // Buy: TP = top of range (buy-side liquidity above)
      g_tpZone.priceHigh    = rangeHigh;
      g_tpZone.priceLow     = rangeHigh * 0.995;
      g_tpZone.isBuySide    = true;
      g_tpZone.isSellSide   = false;
      g_tpZone.isTrendline  = false;
      g_tpZone.isRange      = true;
   }
   else
   {
      // Sell: TP = bottom of range
      g_tpZone.priceHigh    = rangeLow * 1.005;
      g_tpZone.priceLow     = rangeLow;
      g_tpZone.isBuySide    = false;
      g_tpZone.isSellSide   = true;
      g_tpZone.isTrendline  = false;
      g_tpZone.isRange      = true;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Detect Last Swing High/Low (fallback TP method)                  |
//| TP = the last swing high/low before POI was triggered            |
//| This works when no clear trendline or range exists               |
//+------------------------------------------------------------------+

bool DetectLastSwingTP(
   string symbol,
   ENUM_TIMEFRAMES tf,
   double entryPrice,
   bool isBuy
)
{
   // Find the most recent swing point
   if(isBuy)
   {
      // For buy: TP = last swing high before entry
      // Look back for the most recent swing high
      for(int i = 3; i < 30; i++)
      {
         double high = iHigh(symbol, tf, i);
         double prevH = iHigh(symbol, tf, i+1);
         double nextH = iHigh(symbol, tf, i-1);

         if(high > prevH && high > nextH && high > entryPrice)
         {
            g_tpZone.priceHigh   = high;
            g_tpZone.priceLow    = high * 0.995;
            g_tpZone.isBuySide   = true;
            g_tpZone.isSellSide  = false;
            g_tpZone.isTrendline = false;
            g_tpZone.isRange     = false;
            return true;
         }
      }
   }
   else
   {
      // For sell: TP = last swing low before entry
      for(int i = 3; i < 30; i++)
      {
         double low = iLow(symbol, tf, i);
         double prevL = iLow(symbol, tf, i+1);
         double nextL = iLow(symbol, tf, i-1);

         if(low < prevL && low < nextL && low < entryPrice)
         {
            g_tpZone.priceHigh   = low * 1.005;
            g_tpZone.priceLow    = low;
            g_tpZone.isBuySide   = false;
            g_tpZone.isSellSide  = true;
            g_tpZone.isTrendline = false;
            g_tpZone.isRange     = false;
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Calculate TP level using all available methods                   |
//+------------------------------------------------------------------+

double CalculateTakeProfit(
   string symbol,
   ENUM_TIMEFRAMES tf,
   MarketStructure &ms,
   double entryPrice,
   bool isBuy,
   StrategySettings &settings
)
{
   g_tpZone.priceHigh = 0;
   g_tpZone.priceLow = 0;

   bool found = false;

   // Method 1: Trendline liquidity (most common)
   if(settings.useTrendlineTP)
      found = DetectTrendlineLiquidity(symbol, tf, ms, 50);

   // Method 2: Range liquidity (fallback)
   if(!found && settings.useRangeTP)
      found = DetectRangeLiquidity(symbol, tf, ms, entryPrice, isBuy);

   // Method 3: Last swing high/low (final fallback)
   if(!found && settings.useLastSwingTP)
      found = DetectLastSwingTP(symbol, tf, entryPrice, isBuy);

   if(!found)
   {
      // Ultimate fallback: fixed RR
      double atr = iATR(symbol, tf, 14, 1);
      if(isBuy)
         return entryPrice + (atr * 2.0);
      else
         return entryPrice - (atr * 2.0);
   }

   if(isBuy)
      return g_tpZone.priceHigh;
   else
      return g_tpZone.priceLow;
}
//+------------------------------------------------------------------+
