//+------------------------------------------------------------------+
//|                                            OrderBlocks.mqh        |
//|          Order Block & Breaker Block detection with 4 Rules     |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

OrderBlock g_poiList[];        // All identified POIs
OrderBlock g_qualifiedPOIs[];  // POIs that passed the 4 rules

//+------------------------------------------------------------------+
//| Find Order Blocks (Bullish & Bearish)                            |
//| Bullish OB = last bearish candle before an impulsive move up     |
//| Bearish OB = last bullish candle before an impulsive move down   |
//+------------------------------------------------------------------+

void FindOrderBlocks(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   ArrayFree(g_poiList);

   int bars = MathMin(lookback, Bars(symbol, tf) - 5);
   if(bars < 10) return;

   for(int i = 2; i < bars - 2; i++)
   {
      // Check for Bullish Order Block
      // Condition: bearish candle (close < open) followed by 2+ bullish candles
      // that break above the bearish candle's high
      bool bearishCandle = (iClose(symbol, tf, i) < iOpen(symbol, tf, i));
      bool bullishMove1  = (iClose(symbol, tf, i-1) > iOpen(symbol, tf, i-1));
      bool bullishMove2  = (iClose(symbol, tf, i-2) > iOpen(symbol, tf, i-2));
      bool brokeAbove    = (iHigh(symbol, tf, i-1) > iHigh(symbol, tf, i));

      if(bearishCandle && bullishMove1 && brokeAbove)
      {
         int size = ArraySize(g_poiList);
         ArrayResize(g_poiList, size + 1);
         g_poiList[size].type       = POI_ORDER_BLOCK;
         g_poiList[size].timeStart  = iTime(symbol, tf, i);
         g_poiList[size].timeEnd    = iTime(symbol, tf, i);
         g_poiList[size].priceHigh  = iHigh(symbol, tf, i);
         g_poiList[size].priceLow   = iLow(symbol, tf, i);
         g_poiList[size].bullish    = true;
         g_poiList[size].isMitigated = false;
         g_poiList[size].isDisqualified = false;
      }

      // Check for Bearish Order Block
      // Condition: bullish candle (close > open) followed by 2+ bearish candles
      // that break below the bullish candle's low
      bool bullishCandle = (iClose(symbol, tf, i) > iOpen(symbol, tf, i));
      bool bearishMove1  = (iClose(symbol, tf, i-1) < iOpen(symbol, tf, i-1));
      bool bearishMove2  = (iClose(symbol, tf, i-2) < iOpen(symbol, tf, i-2));
      bool brokeBelow    = (iLow(symbol, tf, i-1) < iLow(symbol, tf, i));

      if(bullishCandle && bearishMove1 && brokeBelow)
      {
         int size = ArraySize(g_poiList);
         ArrayResize(g_poiList, size + 1);
         g_poiList[size].type       = POI_ORDER_BLOCK;
         g_poiList[size].timeStart  = iTime(symbol, tf, i);
         g_poiList[size].timeEnd    = iTime(symbol, tf, i);
         g_poiList[size].priceHigh  = iHigh(symbol, tf, i);
         g_poiList[size].priceLow   = iLow(symbol, tf, i);
         g_poiList[size].bullish    = false;
         g_poiList[size].isMitigated = false;
         g_poiList[size].isDisqualified = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Find Breaker Blocks (failed OBs)                                 |
//| Breaker Block = zone where reversal was expected but price broke |
//| through it. The body of the broken zone becomes a BB.            |
//+------------------------------------------------------------------+

void FindBreakerBlocks(string symbol, ENUM_TIMEFRAMES tf, int lookback)
{
   int bars = MathMin(lookback, Bars(symbol, tf) - 5);
   if(bars < 10) return;

   // First find potential OB zones, then check which ones got broken
   FindOrderBlocks(symbol, tf, lookback);

   for(int i = 0; i < ArraySize(g_poiList); i++)
   {
      if(g_poiList[i].type != POI_ORDER_BLOCK) continue;

      // Find the bar index for this OB
      int barIndex = iBarShift(symbol, tf, g_poiList[i].timeStart);
      if(barIndex < 0) continue;

      // Check if price subsequently broke through this OB
      bool broken = false;
      if(g_poiList[i].bullish)
      {
         // Bullish OB should hold as support. If price breaks below it, it's a failed OB = Breaker Block
         for(int j = barIndex - 1; j > 0 && j > barIndex - 20; j--)
         {
            if(iLow(symbol, tf, j) < g_poiList[i].priceLow)
            {
               broken = true;
               break;
            }
         }
      }
      else
      {
         // Bearish OB should hold as resistance. If price breaks above it, it's a failed OB = Breaker Block
         for(int j = barIndex - 1; j > 0 && j > barIndex - 20; j--)
         {
            if(iHigh(symbol, tf, j) > g_poiList[i].priceHigh)
            {
               broken = true;
               break;
            }
         }
      }

      if(broken)
      {
         // Convert to Breaker Block
         int size = ArraySize(g_poiList);
         ArrayResize(g_poiList, size + 1);
         g_poiList[size - 1].type       = POI_BREAKER_BLOCK;
         g_poiList[size - 1].priceHigh  = g_poiList[i].priceHigh;
         g_poiList[size - 1].priceLow   = g_poiList[i].priceLow;
         g_poiList[size - 1].bullish    = g_poiList[i].bullish;
         g_poiList[size - 1].timeStart  = g_poiList[i].timeStart;
         g_poiList[size - 1].isMitigated = false;
         g_poiList[size - 1].isDisqualified = false;
      }
   }
}

//+------------------------------------------------------------------+
//| RULE #1: Must have MSS or MBS                                    |
//| Before picking POIs, confirm structure is present                |
//+------------------------------------------------------------------+

bool Rule1_ConfirmStructure(MarketStructure &ms)
{
   return (ms.hasMSS || ms.hasMBS);
}

//+------------------------------------------------------------------+
//| RULE #2: Must have an inducement                                 |
//| The inducement is the first valid pullback after MSS/MBS         |
//| that takes out the body close of the trigger candle             |
//+------------------------------------------------------------------+

bool Rule2_ConfirmInducement(Inducement &idm, MarketStructure &ms)
{
   return idm.isValid;
}

//+------------------------------------------------------------------+
//| RULE #3: Mitigation Check                                        |
//| During inducement formation, if price touched the body of any    |
//| POI, that POI is DISQUALIFIED                                    |
//+------------------------------------------------------------------+

void Rule3_ApplyMitigation(Inducement &idm)
{
   for(int i = 0; i < ArraySize(g_poiList); i++)
   {
      if(g_poiList[i].isDisqualified) continue;

      // Check if the inducement pullback touched the body of this POI
      bool touchedBody = false;

      if(g_poiList[i].bullish)
      {
         // For bullish POI, check if inducement low went below POI high
         if(idm.pullbackLow <= g_poiList[i].priceHigh &&
            idm.pullbackLow >= g_poiList[i].priceLow)
            touchedBody = true;
      }
      else
      {
         // For bearish POI, check if inducement high went above POI low
         if(idm.pullbackHigh >= g_poiList[i].priceLow &&
            idm.pullbackHigh <= g_poiList[i].priceHigh)
            touchedBody = true;
      }

      if(touchedBody)
      {
         g_poiList[i].isDisqualified = true;
      }
   }
}

//+------------------------------------------------------------------+
//| RULE #4: Choose POI closest to inducement                        |
//| Among remaining qualified POIs, select the one nearest to the    |
//| inducement level                                                 |
//+------------------------------------------------------------------+

OrderBlock Rule4_SelectClosestPOI(Inducement &idm, bool isBullishSignal)
{
   OrderBlock selected;
   selected.type = POI_NONE;
   double minDist = DBL_MAX;

   ArrayFree(g_qualifiedPOIs);

   for(int i = 0; i < ArraySize(g_poiList); i++)
   {
      if(g_poiList[i].isDisqualified) continue;
      if(g_poiList[i].bullish != isBullishSignal) continue;

      // Calculate distance from inducement to POI
      double distance = 0;
      if(isBullishSignal)
      {
         // For buy: distance from IDM low to POI high (resistance above POI)
         distance = MathAbs(g_poiList[i].priceHigh - idm.pullbackLow);
      }
      else
      {
         // For sell: distance from IDM high to POI low
         distance = MathAbs(g_poiList[i].priceLow - idm.pullbackHigh);
      }

      g_poiList[i].distanceToIDM = distance;

      // Add to qualified list
      int size = ArraySize(g_qualifiedPOIs);
      ArrayResize(g_qualifiedPOIs, size + 1);
      g_qualifiedPOIs[size] = g_poiList[i];

      // Track closest
      if(distance < minDist)
      {
         minDist = distance;
         selected = g_poiList[i];
      }
   }

   return selected;
}

//+------------------------------------------------------------------+
//| Full POI selection pipeline applying all 4 rules                 |
//+------------------------------------------------------------------+

OrderBlock SelectBestPOI(
   MarketStructure &ms,
   Inducement &idm,
   string symbol,
   ENUM_TIMEFRAMES tf,
   bool isBullishSignal
)
{
   // Rule 1
   if(!Rule1_ConfirmStructure(ms))
   {
      OrderBlock empty;
      empty.type = POI_NONE;
      return empty;
   }

   // Rule 2
   if(!Rule2_ConfirmInducement(idm, ms))
   {
      OrderBlock empty;
      empty.type = POI_NONE;
      return empty;
   }

   // Find all POIs first
   FindOrderBlocks(symbol, tf, 50);
   FindBreakerBlocks(symbol, tf, 50);

   // Rule 3 - Mitigation
   Rule3_ApplyMitigation(idm);

   // Rule 4 - Select closest
   return Rule4_SelectClosestPOI(idm, isBullishSignal);
}
//+------------------------------------------------------------------+
