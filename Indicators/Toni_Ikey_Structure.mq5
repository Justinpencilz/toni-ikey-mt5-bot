//+------------------------------------------------------------------+
//|                                      Toni_Ikey_Structure.mq5     |
//|           Market Structure Indicator — Visual Mapper Only        |
//|     Strictly based on Toni Iyke Advanced Class definitions       |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.10"
#property description "Toni Iyke Market Structure Mapper"
#property description "Draws swing points, trendlines, MSS, BOS, and structure labels"
#property description "on your chart. Non-trading — visual mapping only."
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include <Trade/Trade.mqh>
#include "include/Strategy.mqh"
#include "include/MarketStructure.mqh"
#include "include/ChartDrawing.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

// --- Structure Detection ---
input ENUM_TIMEFRAMES InpTFTrend     = PERIOD_H1;   // Trend & Structure TF
input ENUM_TIMEFRAMES InpTFBias      = PERIOD_D1;   // Directional Bias TF
input int    InpSwingLookback        = 100;          // Bars to scan for swing points
input int    InpSwingBars            = 3;            // Bars each side for swing confirmation

// --- Display: Chart Objects ---
input bool   InpDrawSwingPoints      = true;         // Draw ▲ ▼ at swing points
input bool   InpDrawTrendline        = true;         // Draw trendlines
input bool   InpDrawMSS              = true;         // Draw MSS reversal line
input bool   InpDrawBOS              = true;         // Draw BOS continuation zones
input bool   InpDrawSequence         = true;         // Label HH/HL/LH/LL
input bool   InpDrawZones            = true;         // Label INTERNAL vs EXTERNAL
input bool   InpDrawBias             = true;         // Show directional bias

// --- Info Panel ---
input bool   InpShowInfoPanel        = true;         // Show info panel (top-left)
input color  InpPanelColor           = clrWhite;     // Panel text color

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

long            g_chartId;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

void OnInit()
{
   g_chartId = ChartID();
   
   // Validate
   if(InpSwingBars < 1 || InpSwingBars > 10)
   {
      Print("ERROR: SwingBars must be between 1 and 10");
      return;
   }
   
   // Initialize
   InitMarketStructure();
   DrawInit(g_chartId, _Symbol, "TI_");
   
   IndicatorSetString(INDICATOR_SHORTNAME, "TI Structure (" + EnumToString(InpTFTrend) + ")");
   
   Print("Toni Ikey Structure Indicator loaded — " + _Symbol + " on " + EnumToString(InpTFTrend));
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization                                |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   DrawEraseAll();
   ObjectsDeleteAll(g_chartId, "TI_LBL_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration                                       |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Only update on new bar (not every tick)
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBarTime == lastBarTime && prev_calculated > 0)
      return rates_total;
   
   lastBarTime = currentBarTime;
   
   // --- STEP 1: Update Market Structure on the configured TF ---
   UpdateMarketStructure(_Symbol, InpTFTrend, InpSwingLookback);
   
   // --- STEP 2: Get directional bias from HTF ---
   string biasStr = GetDirectionalBias(_Symbol, InpTFBias);
   
   // --- STEP 3: Draw structures ---
   if(InpDrawSwingPoints || InpDrawTrendline || InpDrawMSS || 
      InpDrawBOS || InpDrawSequence || InpDrawZones || InpDrawBias)
   {
      DrawAllStructures(biasStr);
   }
   
   // --- STEP 4: Info panel ---
   if(InpShowInfoPanel)
      DisplayInfoPanel(biasStr);
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Get Directional Bias from HTF (Definition 3)                     |
//+------------------------------------------------------------------+

string GetDirectionalBias(string symbol, ENUM_TIMEFRAMES htf)
{
   // Save current state
   MarketStructure savedMS = g_ms;
   SwingPoint savedHighs[];
   SwingPoint savedLows[];
   ArrayCopy(savedHighs, g_swingHighs);
   ArrayCopy(savedLows, g_swingLows);
   
   // Analyze HTF
   DetectSwingPoints(symbol, htf, InpSwingLookback);
   ENUM_TREND_DIRECTION htfTrend = DetermineTrend(symbol, htf);
   
   string biasStr;
   switch(htfTrend)
   {
      case TREND_UPTREND:    biasStr = "BULLISH (look for BUYS)";  break;
      case TREND_DOWNTREND:  biasStr = "BEARISH (look for SELLS)"; break;
      case TREND_RANGING:    biasStr = "NEUTRAL";                  break;
      default:               biasStr = "UNCLEAR";
   }
   
   // Restore current state
   g_ms = savedMS;
   ArrayCopy(g_swingHighs, savedHighs);
   ArrayCopy(g_swingLows, savedLows);
   
   return biasStr;
}

//+------------------------------------------------------------------+
//| Info panel                                                       |
//+------------------------------------------------------------------+

void DisplayInfoPanel(string biasStr)
{
   string trendSymbol;
   color trendColor;
   
   switch(g_ms.trend)
   {
      case TREND_UPTREND:
         trendSymbol = "▲ UPTREND";  trendColor = clrLimeGreen; break;
      case TREND_DOWNTREND:
         trendSymbol = "▼ DOWNTREND"; trendColor = clrRed;      break;
      case TREND_RANGING:
         trendSymbol = "◆ RANGING";   trendColor = clrYellow;   break;
      default:
         trendSymbol = "● NONE";      trendColor = clrGray;
   }
   
   int y = 30;
   int x = 10;
   int fs = 10;
   
   // Line 1
   PanelLabel("TREND", x, y, _Symbol + " | " + trendSymbol, trendColor, fs);
   y += 18;
   
   // Line 2
   string seq;
   if(g_ms.trend == TREND_UPTREND)
      seq = "HH:" + IntegerToString(g_ms.hhCount) + "  HL:" + IntegerToString(g_ms.hlCount);
   else if(g_ms.trend == TREND_DOWNTREND)
      seq = "LH:" + IntegerToString(g_ms.lhCount) + "  LL:" + IntegerToString(g_ms.llCount);
   else if(g_ms.trend == TREND_RANGING)
      seq = "Range bound";
   else
      seq = "Insufficient data";
   PanelLabel("SEQ", x, y, seq, clrWhite, fs);
   y += 18;
   
   // Line 3
   color biasC;
   if(StringFind(biasStr, "BUYS") >= 0) biasC = clrLimeGreen;
   else if(StringFind(biasStr, "SELLS") >= 0) biasC = clrRed;
   else biasC = clrYellow;
   PanelLabel("BIAS", x, y, "Bias: " + biasStr, biasC, fs);
   y += 18;
   
   // Line 4: MSS
   if(g_ms.hasMSS)
   {
      string m = "⚡ MSS: " + (g_ms.mssIsBullish ? "BUY" : "SELL") + " reversal at "
               + DoubleToString(g_ms.mssBrokenLevel, _Digits);
      PanelLabel("MSS", x, y, m, clrOrange, fs + 1);
   }
   else
      PanelLabel("MSS", x, y, "MSS: none", clrGray, fs);
   y += 18;
   
   // Line 5: BOS
   if(g_ms.hasBOS)
   {
      string b = "⇨ BOS: " + IntegerToString(g_ms.bosBreaksCount) + " zone(s)"
               + (g_ms.bosIsBullish ? " ↑" : " ↓");
      if(g_ms.bosBreaksCount >= BOS_MIN_MULTIPLE)
      {
         b += "  VALID ✓";
         PanelLabel("BOS", x, y, b, clrCyan, fs + 1);
      }
      else
      {
         b += "  IGNORE";
         PanelLabel("BOS", x, y, b, clrDarkGray, fs);
      }
   }
   else
      PanelLabel("BOS", x, y, "BOS: none", clrGray, fs);
   y += 18;
   
   // Line 6: Trendline
   if(g_ms.uptrendLine.valid)
      PanelLabel("TL", x, y, "Trendline: Uptrend channel", clrLimeGreen, fs);
   else if(g_ms.downtrendLine.valid)
      PanelLabel("TL", x, y, "Trendline: Downtrend channel", clrRed, fs);
   else if(g_ms.rangeResistance.valid)
      PanelLabel("TL", x, y, "Range: " + DoubleToString(g_ms.rangeSupport.point2Price, _Digits)
         + " — " + DoubleToString(g_ms.rangeResistance.point2Price, _Digits), clrYellow, fs);
   else
      PanelLabel("TL", x, y, "Trendline: none", clrGray, fs);
   y += 18;
   
   // Line 7: Implication
   string imp = "→ ";
   if(g_ms.trend == TREND_RANGING)
      imp += "Wait for breakout";
   else if(StringFind(biasStr, "BUYS") >= 0 && g_ms.trend == TREND_DOWNTREND)
      imp += "HTF bullish, LTF selling — watch MSS at POI";
   else if(StringFind(biasStr, "SELLS") >= 0 && g_ms.trend == TREND_UPTREND)
      imp += "HTF bearish, LTF buying — watch MSS at POI";
   else if(g_ms.trend == TREND_UPTREND)
      imp += "Uptrend — look for multiple BOS for continuation buys";
   else if(g_ms.trend == TREND_DOWNTREND)
      imp += "Downtrend — look for multiple BOS for continuation sells";
   else
      imp += "No clear setup";
   PanelLabel("IMP", x, y, imp, clrLightGray, fs - 2);
}

//+------------------------------------------------------------------+
//| Helper: create/update panel label                                |
//+------------------------------------------------------------------+

void PanelLabel(string name, int x, int y, string text, color clr, int fontSize)
{
   string objName = "TI_LBL_" + name;
   if(ObjectFind(g_chartId, objName) < 0)
      ObjectCreate(g_chartId, objName, OBJ_LABEL, 0, 0, 0);
   
   ObjectSetInteger(g_chartId, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(g_chartId, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(g_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(g_chartId, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(g_chartId, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(g_chartId, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(g_chartId, objName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, objName, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
