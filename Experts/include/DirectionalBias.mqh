//+------------------------------------------------------------------+
//|                                        DirectionalBias.mqh        |
//|       Daily timeframe bias analysis based on Toni Iyke           |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

MarketStructure g_dailyBias;

//+------------------------------------------------------------------+
//| Determine directional bias from higher timeframe (D1)            |
//| Toni Iyke: "Go to daily timeframe, look for HH/HL or LH/LL"     |
//| Once bias is set, only take entries in that direction            |
//+------------------------------------------------------------------+

ENUM_TREND_DIRECTION GetDirectionalBias(string symbol)
{
   // Use daily timeframe for bias
   InitMarketStructure();
   DetectSwingPoints(symbol, PERIOD_D1, 100);

   ENUM_TREND_DIRECTION bias = DetermineTrend(symbol, PERIOD_D1);
   g_dailyBias = g_marketStructure; // Store for reference
   g_dailyBias.trend = bias;

   return bias;
}

//+------------------------------------------------------------------+
//| Check if a trade signal aligns with the daily bias               |
//| Only take entries that go WITH the daily bias direction           |
//+------------------------------------------------------------------+

bool AlignsWithBias(bool isBuySignal)
{
   ENUM_TREND_DIRECTION bias = g_dailyBias.trend;

   if(bias == TREND_UPTREND && isBuySignal) return true;
   if(bias == TREND_DOWNT REND && !isBuySignal) return true;
   if(bias == TREND_RANGING) return true;  // Range = both directions OK
   if(bias == TREND_NONE) return true;     // No clear bias = cautious

   return false; // Signal against the daily bias
}

//+------------------------------------------------------------------+
//| Get the logic description for current bias (for logging)         |
//+------------------------------------------------------------------+

string GetBiasDescription(ENUM_TREND_DIRECTION bias)
{
   switch(bias)
   {
      case TREND_UPTREND:
         return "Bullish (HH/HL) — focus on buys only";
      case TREND_DOWNT REND:
         return "Bearish (LH/LL) — focus on sells only";
      case TREND_RANGING:
         return "Ranging — buy/sell from range boundaries";
      case TREND_NONE:
         return "No clear bias — wait for structure";
      default:
         return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get correction zones from daily timeframe                        |
//| These are the daily OBs/BBs where price is likely to retrace     |
//| before continuing in the bias direction                          |
//+------------------------------------------------------------------+

void GetDailyCorrectionZones(
   string symbol,
   double &zoneHigh[],
   double &zoneLow[],
   int &zoneCount
)
{
   zoneCount = 0;
   ArrayFree(zoneHigh);
   ArrayFree(zoneLow);

   if(g_dailyBias.trend == TREND_UPTREND)
   {
      // In uptrend, correction zones = areas where higher lows form
      // These are previous Order Blocks on daily
      FindOrderBlocks(symbol, PERIOD_D1, 100);

      for(int i = 0; i < ArraySize(g_poiList); i++)
      {
         if(g_poiList[i].bullish) // Bullish OBs are correction zones
         {
            int size = ArraySize(zoneHigh);
            ArrayResize(zoneHigh, size + 1);
            ArrayResize(zoneLow, size + 1);
            zoneHigh[size] = g_poiList[i].priceHigh;
            zoneLow[size]  = g_poiList[i].priceLow;
            zoneCount++;
         }
      }
   }
   else if(g_dailyBias.trend == TREND_DOWNT REND)
   {
      // In downtrend, correction zones = areas where lower highs form
      FindOrderBlocks(symbol, PERIOD_D1, 100);

      for(int i = 0; i < ArraySize(g_poiList); i++)
      {
         if(!g_poiList[i].bullish) // Bearish OBs are correction zones
         {
            int size = ArraySize(zoneHigh);
            ArrayResize(zoneHigh, size + 1);
            ArrayResize(zoneLow, size + 1);
            zoneHigh[size] = g_poiList[i].priceHigh;
            zoneLow[size]  = g_poiList[i].priceLow;
            zoneCount++;
         }
      }
   }
}
//+------------------------------------------------------------------+
