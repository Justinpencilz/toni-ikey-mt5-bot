//+------------------------------------------------------------------+
//|                                            Inducement.mqh         |
//|          Inducement detection based on Toni Iyke                 |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

Inducement g_inducement;

//+------------------------------------------------------------------+
//| Detect inducement after MSS or MBS                               |
//| Inducement = first valid pullback that takes out the body close  |
//| of the MSS/MBS trigger candle                                    |
//+------------------------------------------------------------------+

bool DetectInducement(
   string symbol,
   ENUM_TIMEFRAMES tf,
   MarketStructure &ms,
   double bodyPercent
)
{
   g_inducement.isValid = false;

   if(!ms.hasMSS && !ms.hasMBS) return false;

   // Find the MSS/MBS trigger bar
   datetime triggerTime = ms.hasMSS ? ms.mssTime : (ms.hasMBS ? iTime(symbol, tf, 1) : 0);
   if(triggerTime == 0) return false;

   int triggerBar = iBarShift(symbol, tf, triggerTime);
   if(triggerBar < 0) return false;

   // Get the body close of the trigger candle
   double triggerOpen  = iOpen(symbol, tf, triggerBar);
   double triggerClose = iClose(symbol, tf, triggerBar);
   double triggerHigh  = iHigh(symbol, tf, triggerBar);
   double triggerLow   = iLow(symbol, tf, triggerBar);

   // Body close: if bullish (close > open), body close = close
   // If bearish (close < open), body close = open
   double bodyClose = (triggerClose > triggerOpen) ? triggerClose : triggerOpen;
   double bodySize  = MathAbs(triggerClose - triggerOpen);
   double bodyThreshold = bodySize * bodyPercent;

   // For MSS to upside (downtrend → uptrend):
   // Inducement = pullback that takes out the body close (of the bearish trigger candle)
   // For MSS to downside (uptrend → downtrend):
   // Inducement = pullback that takes out the body close

   // Scan bars after trigger for a pullback that takes out body close
   for(int i = triggerBar - 1; i > MathMax(0, triggerBar - 15); i--)
   {
      double barLow  = iLow(symbol, tf, i);
      double barHigh = iHigh(symbol, tf, i);

      // Check if this bar's low/high takes out the body close
      // For bullish signal (MSS to upside): price pulled back and low went below body close
      if(ms.trend == TREND_UPTREND)
      {
         if(barLow <= bodyClose + bodyThreshold)
         {
            g_inducement.isValid     = true;
            g_inducement.time        = iTime(symbol, tf, i);
            g_inducement.level       = bodyClose;
            g_inducement.pullbackHigh = iHigh(symbol, tf, i);
            g_inducement.pullbackLow  = iLow(symbol, tf, i);
            return true;
         }
      }
      // For bearish signal (MSS to downside)
      else if(ms.trend == TREND_DOWNT REND)
      {
         if(barHigh >= bodyClose - bodyThreshold)
         {
            g_inducement.isValid     = true;
            g_inducement.time        = iTime(symbol, tf, i);
            g_inducement.level       = bodyClose;
            g_inducement.pullbackHigh = iHigh(symbol, tf, i);
            g_inducement.pullbackLow  = iLow(symbol, tf, i);
            return true;
         }
      }
   }

   return false;
}
//+------------------------------------------------------------------+
