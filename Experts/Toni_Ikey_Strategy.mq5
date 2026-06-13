//+------------------------------------------------------------------+
//|                                          Toni_Ikey_Strategy.mq5  |
//|           Stage 1: Market Structure Detection                    |
//|     Strictly based on Toni Iyke Advanced Class definitions       |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include "include/Strategy.mqh"
#include "include/MarketStructure.mqh"

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

// --- Display ---
input bool   InpShowLabels           = true;         // Show structure info on chart
input color  InpLabelColor           = clrWhite;     // Label color
input int    InpLabelX               = 10;           // Label X offset
input int    InpLabelY               = 30;           // Label Y offset

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

CTrade          g_trade;
long            g_chartId;
int             g_labelPrefix;
string          g_prefix;
datetime        g_lastUpdate;
int             g_updateInterval = 5;  // Update every N ticks

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   g_chartId = ChartID();
   g_prefix = "TONI_IKEY_";
   
   // Validate swing lookback parameter
   if(InpSwingBars < 1 || InpSwingBars > 10)
   {
      Print("ERROR: SwingBars must be between 1 and 10");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Initialize market structure
   InitMarketStructure();
   g_lastUpdate = 0;
   
   Print("Toni Ikey Strategy EA Stage 1 loaded.");
   Print("Scanning: " + _Symbol + " on TF " + EnumToString(InpTFTrend));
   Print("Bias TF: " + EnumToString(InpTFBias));
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   // Clean up chart labels
   ObjectsDeleteAll(g_chartId, g_prefix);
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
   
   // --- STEP 3: Display results ---
   if(InpShowLabels)
   {
      DisplayStructureInfo(biasStr);
   }
   
   // --- STEP 4: Log signal if one is active ---
   LogCurrentState(biasStr);
}

//+------------------------------------------------------------------+
//| Get Directional Bias from Higher Timeframe (Definition 3)        |
//| HTF in uptrend → overall bullish → look for buys                 |
//| HTF in downtrend → overall bearish → look for sells              |
//+------------------------------------------------------------------+

string GetDirectionalBias(string symbol, ENUM_TIMEFRAMES htf)
{
   // Save and restore the main structure
   MarketStructure savedMS = g_ms;
   
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
   
   return biasStr;
}

//+------------------------------------------------------------------+
//| Display structure information on chart                           |
//+------------------------------------------------------------------+

void DisplayStructureInfo(string biasStr)
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
   
   int y = InpLabelY;
   int x = InpLabelX;
   int fontSize = 10;
   
   // Line 1: Symbol + Trend
   CreateLabel("TREND", x, y, _Symbol + " | " + trendSymbol, trendColor, fontSize);
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
   else
   {
      seq = "No clear HH/HL or LH/LL sequence";
   }
   CreateLabel("SEQ", x, y, seq, clrWhite, fontSize);
   y += 18;
   
   // Line 3: Directional Bias
   string biasColorStr = "";
   if(StringFind(biasStr, "BUYS") >= 0)
      CreateLabel("BIAS", x, y, "Bias: " + biasStr, clrLimeGreen, fontSize);
   else if(StringFind(biasStr, "SELLS") >= 0)
      CreateLabel("BIAS", x, y, "Bias: " + biasStr, clrRed, fontSize);
   else
      CreateLabel("BIAS", x, y, "Bias: " + biasStr, clrYellow, fontSize);
   y += 18;
   
   // Line 4: MSS Status
   if(g_ms.hasMSS)
   {
      string mssStr = "⚡ MSS DETECTED: ";
      mssStr += (g_ms.mssIsBullish ? "BUY REVERSAL" : "SELL REVERSAL");
      mssStr += "  (Level: " + DoubleToString(g_ms.mssBrokenLevel, _Digits) + ")";
      CreateLabel("MSS", x, y, mssStr, clrOrange, fontSize + 2);
      y += 18;
   }
   else
   {
      CreateLabel("MSS", x, y, "No MSS detected", clrGray, fontSize);
      y += 18;
   }
   
   // Line 5: BOS Status
   if(g_ms.hasBOS)
   {
      string bosStr = "⇨ BOS: " + IntegerToString(g_ms.bosBreaksCount) + " zone(s) broken";
      bosStr += " (" + (g_ms.bosIsBullish ? "BULLISH" : "BEARISH") + ")";
      
      if(g_ms.bosBreaksCount >= BOS_MIN_MULTIPLE)
      {
         bosStr += " → VALID for continuation trades";
         CreateLabel("BOS", x, y, bosStr, clrCyan, fontSize + 2);
      }
      else
      {
         bosStr += " → IGNORE (single BOS)";
         CreateLabel("BOS", x, y, bosStr, clrGray, fontSize);
      }
      y += 18;
   }
   else
   {
      CreateLabel("BOS", x, y, "No BOS detected", clrGray, fontSize);
      y += 18;
   }
   
   // Line 6: Trendline info
   if(g_ms.uptrendLine.valid)
      CreateLabel("TLU", x, y, "Uptrend line active (connecting higher lows)", clrLimeGreen, fontSize);
   else if(g_ms.downtrendLine.valid)
      CreateLabel("TLD", x, y, "Downtrend line active (connecting lower highs)", clrRed, fontSize);
   else if(g_ms.rangeResistance.valid)
      CreateLabel("TLR", x, y, "Range: Resistance=" + DoubleToString(g_ms.rangeResistance.point2Price, _Digits) 
         + " Support=" + DoubleToString(g_ms.rangeSupport.point2Price, _Digits), clrYellow, fontSize);
   y += 18;
   
   // Line 7: Summary / Trading implication
   string summary = "→ ";
   if(g_ms.trend == TREND_RANGING)
      summary += "Range market. Wait for breakout for continuation entries.";
   else if(StringFind(biasStr, "BUYS") >= 0 && g_ms.trend == TREND_DOWNTREND)
      summary += "HTF bullish, LTF selling. Watch for MSS at HTF POI for reversal.";
   else if(StringFind(biasStr, "SELLS") >= 0 && g_ms.trend == TREND_UPTREND)
      summary += "HTF bearish, LTF buying. Watch for MSS at HTF POI for reversal.";
   else if(g_ms.trend == TREND_UPTREND)
      summary += "Uptrend. Look for multiple BOS for continuation buys.";
   else if(g_ms.trend == TREND_DOWNTREND)
      summary += "Downtrend. Look for multiple BOS for continuation sells.";
   else
      summary += "No clear setup.";
   CreateLabel("SUMMARY", x, y, summary, clrDarkGray, fontSize - 2);
}

//+------------------------------------------------------------------+
//| Helper: Create a chart label                                     |
//+------------------------------------------------------------------+

void CreateLabel(string name, int x, int y, string text, color clr, int fontSize)
{
   string objName = g_prefix + name;
   
   if(ObjectFind(g_chartId, objName) < 0)
   {
      ObjectCreate(g_chartId, objName, OBJ_LABEL, 0, 0, 0);
   }
   
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
