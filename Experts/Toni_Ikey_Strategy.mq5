//+------------------------------------------------------------------+
//|                                          Toni_Ikey_Strategy.mq5  |
//|           Stage 1: Market Structure Detection + Visual Mapping   |
//|     Strictly based on Toni Iyke Advanced Class definitions       |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.10"

#include <Trade/Trade.mqh>
#include "include/Strategy.mqh"
#include "include/MarketStructure.mqh"
#include "include/ChartDrawing.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

// --- Timeframes ---
input ENUM_TIMEFRAMES InpTFTrend     = PERIOD_H1;   // Trend & Structure TF
input ENUM_TIMEFRAMES InpTFBias      = PERIOD_D1;   // Directional Bias TF (Definition 3)

// --- Swing Detection ---
input int    InpSwingLookback        = 100;          // Bars to scan for swing points
input int    InpSwingBars            = 3;            // Bars each side for swing confirmation

// --- MSS Detection ---
input int    InpMSSLookback          = 20;           // Bars to scan for MSS

// --- BOS Detection ---
input int    InpBOSLookback          = 30;           // Bars to scan for BOS

// --- Display: Chart Objects ---
input bool   InpDrawSwingPoints      = true;         // Draw ▲ ▼ at swing points
input bool   InpDrawTrendline        = true;         // Draw trendlines (uptrend/downtrend)
input bool   InpDrawMSS              = true;         // Draw horizontal line at MSS level
input bool   InpDrawBOS              = true;         // Draw horizontal lines at BOS zones
input bool   InpDrawSequence         = true;         // Label HH/HL/LH/LL on swings
input bool   InpDrawZones            = true;         // Label INTERNAL vs EXTERNAL zones
input bool   InpDrawBias             = true;         // Show directional bias on chart

// --- Display: Text Labels ---
input bool   InpShowInfoPanel        = true;         // Show info panel (top-left)
input color  InpPanelColor           = clrWhite;     // Panel text color
input int    InpPanelX               = 10;           // Panel X offset
input int    InpPanelY               = 30;           // Panel Y offset

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

CTrade          g_trade;
long            g_chartId;
datetime        g_lastUpdate;
int             g_updateInterval = 5;  // Update every N seconds

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   g_chartId = ChartID();
   
   // Validate swing lookback parameter
   if(InpSwingBars < 1 || InpSwingBars > 10)
   {
      Print("ERROR: SwingBars must be between 1 and 10");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Initialize market structure
   InitMarketStructure();
   g_lastUpdate = 0;
   
   // Initialize chart drawing
   DrawInit(g_chartId, _Symbol, "TI_");
   
   Print("Toni Ikey Strategy EA v1.10 — Stage 1 loaded.");
   Print("Scanning: " + _Symbol + " on TF " + EnumToString(InpTFTrend));
   Print("Bias TF: " + EnumToString(InpTFBias));
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   // Clean up all drawn objects and labels
   DrawEraseAll();
   ObjectsDeleteAll(g_chartId, "TI_LBL_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // Throttle updates - don't recalculate every tick
   if(TimeCurrent() - g_lastUpdate < g_updateInterval)
      return;
   
   g_lastUpdate = TimeCurrent();
   
   // --- STEP 1: Update Market Structure on entry timeframe ---
   UpdateMarketStructure(_Symbol, InpTFTrend, InpSwingLookback);
   
   // --- STEP 2: Get directional bias from HTF (Definition 3) ---
   string biasStr = GetDirectionalBias(_Symbol, InpTFBias);
   
   // --- STEP 3: Draw structures on chart ---
   if(InpDrawSwingPoints || InpDrawTrendline || InpDrawMSS || 
      InpDrawBOS || InpDrawSequence || InpDrawZones || InpDrawBias)
   {
      DrawAllStructures(biasStr);
   }
   
   // --- STEP 4: Display info panel ---
   if(InpShowInfoPanel)
   {
      DisplayInfoPanel(biasStr);
   }
   
   // --- STEP 5: Log signal if one is active ---
   LogCurrentState(biasStr);
}

//+------------------------------------------------------------------+
//| Get Directional Bias from Higher Timeframe (Definition 3)        |
//+------------------------------------------------------------------+

string GetDirectionalBias(string symbol, ENUM_TIMEFRAMES htf)
{
   // Save and restore the main structure
   MarketStructure savedMS = g_ms;
   SwingPoint savedHighs[];
   SwingPoint savedLows[];
   ArrayCopy(savedHighs, g_swingHighs);
   ArrayCopy(savedLows, g_swingLows);
   
   // Analyze HTF trend
   DetectSwingPoints(symbol, htf, InpSwingLookback);
   ENUM_TREND_DIRECTION htfTrend = DetermineTrend(symbol, htf);
   
   string biasStr = "";
   
   switch(htfTrend)
   {
      case TREND_UPTREND:
         biasStr = "BULLISH (look for BUYS)";
         break;
      case TREND_DOWNTREND:
         biasStr = "BEARISH (look for SELLS)";
         break;
      case TREND_RANGING:
         biasStr = "NEUTRAL";
         break;
      default:
         biasStr = "UNCLEAR";
   }
   
   // Restore the main structure
   g_ms = savedMS;
   ArrayCopy(g_swingHighs, savedHighs);
   ArrayCopy(g_swingLows, savedLows);
   
   return biasStr;
}

//+------------------------------------------------------------------+
//| Display info panel on chart (top-left)                           |
//+------------------------------------------------------------------+

void DisplayInfoPanel(string biasStr)
{
   string trendSymbol = "";
   color trendColor = clrWhite;
   
   switch(g_ms.trend)
   {
      case TREND_UPTREND:
         trendSymbol = "▲ UPTREND";
         trendColor = clrLimeGreen;
         break;
      case TREND_DOWNTREND:
         trendSymbol = "▼ DOWNTREND";
         trendColor = clrRed;
         break;
      case TREND_RANGING:
         trendSymbol = "◆ RANGING";
         trendColor = clrYellow;
         break;
      default:
         trendSymbol = "● NONE";
         trendColor = clrGray;
   }
   
   int y = InpPanelY;
   int x = InpPanelX;
   int fontSize = 10;
   
   // Line 1: Symbol + Trend
   PanelLabel("TREND", x, y, _Symbol + " | " + trendSymbol, trendColor, fontSize);
   y += 18;
   
   // Line 2: Trend sequence details
   string seq = "";
   if(g_ms.trend == TREND_UPTREND)
   {
      seq = "HH:" + IntegerToString(g_ms.hhCount) + "  HL:" + IntegerToString(g_ms.hlCount);
      seq += "  Last Swing H: " + DoubleToString(g_ms.lastSwingHigh.price, _Digits);
      seq += "  L: " + DoubleToString(g_ms.lastSwingLow.price, _Digits);
   }
   else if(g_ms.trend == TREND_DOWNTREND)
   {
      seq = "LH:" + IntegerToString(g_ms.lhCount) + "  LL:" + IntegerToString(g_ms.llCount);
      seq += "  Last Swing H: " + DoubleToString(g_ms.lastSwingHigh.price, _Digits);
      seq += "  L: " + DoubleToString(g_ms.lastSwingLow.price, _Digits);
   }
   else if(g_ms.trend == TREND_RANGING)
   {
      seq = "Range bound — no HH/HL or LH/LL";
   }
   else
   {
      seq = "Insufficient data for trend";
   }
   PanelLabel("SEQ", x, y, seq, clrWhite, fontSize);
   y += 18;
   
   // Line 3: Directional Bias
   if(StringFind(biasStr, "BUYS") >= 0)
      PanelLabel("BIAS", x, y, "Bias: " + biasStr, clrLimeGreen, fontSize);
   else if(StringFind(biasStr, "SELLS") >= 0)
      PanelLabel("BIAS", x, y, "Bias: " + biasStr, clrRed, fontSize);
   else
      PanelLabel("BIAS", x, y, "Bias: " + biasStr, clrYellow, fontSize);
   y += 18;
   
   // Line 4: MSS Status
   if(g_ms.hasMSS)
   {
      string mssStr = "⚡ MSS: ";
      mssStr += (g_ms.mssIsBullish ? "BUY REVERSAL" : "SELL REVERSAL");
      mssStr += " at " + DoubleToString(g_ms.mssBrokenLevel, _Digits);
      PanelLabel("MSS", x, y, mssStr, clrOrange, fontSize + 1);
   }
   else
   {
      PanelLabel("MSS", x, y, "MSS: none", clrGray, fontSize);
   }
   y += 18;
   
   // Line 5: BOS Status
   if(g_ms.hasBOS)
   {
      string bosStr = "⇨ BOS: " + IntegerToString(g_ms.bosBreaksCount) + " zone(s)";
      bosStr += (g_ms.bosIsBullish ? " ↑" : " ↓");
      
      if(g_ms.bosBreaksCount >= BOS_MIN_MULTIPLE)
      {
         bosStr += "  VALID ✓";
         PanelLabel("BOS", x, y, bosStr, clrCyan, fontSize + 1);
      }
      else
      {
         bosStr += "  IGNORE (single)";
         PanelLabel("BOS", x, y, bosStr, clrDarkGray, fontSize);
      }
   }
   else
   {
      PanelLabel("BOS", x, y, "BOS: none", clrGray, fontSize);
   }
   y += 18;
   
   // Line 6: Trendline info
   if(g_ms.uptrendLine.valid)
      PanelLabel("TL", x, y, "Trendline: Uptrend (higher lows connected)", clrLimeGreen, fontSize);
   else if(g_ms.downtrendLine.valid)
      PanelLabel("TL", x, y, "Trendline: Downtrend (lower highs connected)", clrRed, fontSize);
   else if(g_ms.rangeResistance.valid)
      PanelLabel("TL", x, y, "Range: " + DoubleToString(g_ms.rangeSupport.point2Price, _Digits) 
         + " — " + DoubleToString(g_ms.rangeResistance.point2Price, _Digits), clrYellow, fontSize);
   else
      PanelLabel("TL", x, y, "Trendline: none", clrGray, fontSize);
   y += 18;
   
   // Line 7: Trading implication
   string summary = "→ ";
   if(g_ms.trend == TREND_RANGING)
      summary += "Wait for breakout for continuation entries.";
   else if(StringFind(biasStr, "BUYS") >= 0 && g_ms.trend == TREND_DOWNTREND)
      summary += "HTF bullish, LTF selling. Watch for MSS at HTF POI.";
   else if(StringFind(biasStr, "SELLS") >= 0 && g_ms.trend == TREND_UPTREND)
      summary += "HTF bearish, LTF buying. Watch for MSS at HTF POI.";
   else if(g_ms.trend == TREND_UPTREND)
      summary += "Uptrend. Look for multiple BOS for continuation buys.";
   else if(g_ms.trend == TREND_DOWNTREND)
      summary += "Downtrend. Look for multiple BOS for continuation sells.";
   else
      summary += "No clear setup.";
   PanelLabel("SUMMARY", x, y, summary, clrLightGray, fontSize - 2);
}

//+------------------------------------------------------------------+
//| Helper: Create or update info panel label                        |
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
//| Log current state to Experts tab                                 |
//+------------------------------------------------------------------+

void LogCurrentState(string biasStr)
{
   static datetime lastLog = 0;
   
   // Log every minute
   if(TimeCurrent() - lastLog < 60) return;
   lastLog = TimeCurrent();
   
   string log = "[" + TimeToString(TimeCurrent()) + "] " + _Symbol;
   log += " | " + MarketStructureToString();
   log += " | Bias: " + biasStr;
   
   Print(log);
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Refresh on chart change
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      g_lastUpdate = 0;
   }
}

//+------------------------------------------------------------------+
