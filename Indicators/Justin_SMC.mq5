//+------------------------------------------------------------------+
//|                                      SMC_Structure_Core.mq5        |
//|  Smart Money Concepts - Core Structure Engine                     |
//|  Converted from LuxAlgo "Smart Money Concepts" Pine Script logic  |
//|                                                                    |
//|  PHASE 1 CORE - implements:                                        |
//|    - Swing pivot detection      (Pine: leg() + getCurrentStructure)|
//|    - Internal pivot detection   (same, length = 5)                |
//|    - BOS / CHoCH detection      (Pine: displayStructure())        |
//|    - BOS / CHoCH drawing as TRUE SEGMENTS (pivot bar -> break bar)|
//|      with midpoint labels (Pine: drawStructure())                 |
//|    - HH/HL/LH/LL swing point labels                               |
//|    - Strong/Weak High & Low trailing lines                        |
//|    - 8 hidden buffers exposing every BOS/CHoCH event for an EA    |
//|                                                                    |
//|  NOT YET IN THIS FILE (Phase 2 - to be appended as modules):       |
//|    - Order Blocks, Equal Highs/Lows, Fair Value Gaps,             |
//|      Premium/Discount zones, Daily/Weekly/Monthly levels           |
//+------------------------------------------------------------------+
#property copyright "Converted for personal/internal use"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   8

//--- hidden EA-readable signal buffers (price level on event bar, EMPTY_VALUE otherwise)
#property indicator_label1  "SwingBullBOS"
#property indicator_type1   DRAW_NONE
#property indicator_label2  "SwingBullCHoCH"
#property indicator_type2   DRAW_NONE
#property indicator_label3  "SwingBearBOS"
#property indicator_type3   DRAW_NONE
#property indicator_label4  "SwingBearCHoCH"
#property indicator_type4   DRAW_NONE
#property indicator_label5  "IntBullBOS"
#property indicator_type5   DRAW_NONE
#property indicator_label6  "IntBullCHoCH"
#property indicator_type6   DRAW_NONE
#property indicator_label7  "IntBearBOS"
#property indicator_type7   DRAW_NONE
#property indicator_label8  "IntBearCHoCH"
#property indicator_type8   DRAW_NONE

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input group "=== Swing Structure ==="
input int    InpSwingLength          = 50;            // Swing pivot lookback length (Pine: swingsLengthInput)
input bool   InpShowSwingStructure   = true;           // Draw swing BOS/CHoCH
input color  InpSwingBullColor       = C'8,153,129';   // Pine GREEN #089981
input color  InpSwingBearColor       = C'242,54,69';   // Pine RED   #F23645
input bool   InpShowSwingLabels      = false;          // Show HH/HL/LH/LL labels

input group "=== Internal Structure ==="
input int    InpInternalLength          = 5;           // Internal pivot lookback length (fixed in Pine source)
input bool   InpShowInternalStructure   = true;        // Draw internal BOS/CHoCH
input color  InpInternalBullColor       = C'8,153,129';
input color  InpInternalBearColor       = C'242,54,69';

input group "=== Strong / Weak High Low ==="
input bool   InpShowStrongWeak       = true;           // Trailing extreme lines + labels

input group "=== Label Appearance ==="
input int    InpStructureLabelFontSize = 8;            // BOS/CHoCH label font size
input int    InpSwingPointFontSize     = 7;            // HH/HL/LH/LL label font size

input group "=== Performance ==="
input int    InpMaxHistoryBars       = 0;              // 0 = process all available history
//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
#define LEG_BULLISH     1
#define LEG_BEARISH     0
#define TREND_NONE      0
#define TREND_BULLISH   1
#define TREND_BEARISH  -1

//+------------------------------------------------------------------+
//| Data structures                                                   |
//+------------------------------------------------------------------+
struct PivotPoint
  {
   double   price;       // current pivot level
   double   lastPrice;   // previous pivot level (for HH/HL/LH/LL classification)
   datetime time;        // bar time of the pivot
   int      barIndex;    // bar index of the pivot (array index, ascending)
   bool     crossed;     // true once price has broken through this level
   bool     valid;       // true once at least one pivot has been confirmed
  };

struct TrailingExtremes
  {
   double   top;
   double   bottom;
   datetime lastTopTime;
   datetime lastBottomTime;
   bool     valid;
  };

//+------------------------------------------------------------------+
//| Global state (persists between OnCalculate calls)                |
//+------------------------------------------------------------------+
PivotPoint        swingHigh, swingLow, internalHigh, internalLow;
TrailingExtremes  trailing;

int swingLeg     = -1;   // -1 = not yet determined
int internalLeg  = -1;

int swingTrendBias    = TREND_NONE;
int internalTrendBias = TREND_NONE;

//--- indicator buffers
double BufSwingBullBOS[];
double BufSwingBullCHoCH[];
double BufSwingBearBOS[];
double BufSwingBearCHoCH[];
double BufIntBullBOS[];
double BufIntBullCHoCH[];
double BufIntBearBOS[];
double BufIntBearCHoCH[];

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, BufSwingBullBOS,   INDICATOR_DATA);
   SetIndexBuffer(1, BufSwingBullCHoCH, INDICATOR_DATA);
   SetIndexBuffer(2, BufSwingBearBOS,   INDICATOR_DATA);
   SetIndexBuffer(3, BufSwingBearCHoCH, INDICATOR_DATA);
   SetIndexBuffer(4, BufIntBullBOS,     INDICATOR_DATA);
   SetIndexBuffer(5, BufIntBullCHoCH,   INDICATOR_DATA);
   SetIndexBuffer(6, BufIntBearBOS,     INDICATOR_DATA);
   SetIndexBuffer(7, BufIntBearCHoCH,   INDICATOR_DATA);

   ArraySetAsSeries(BufSwingBullBOS,   false);
   ArraySetAsSeries(BufSwingBullCHoCH, false);
   ArraySetAsSeries(BufSwingBearBOS,   false);
   ArraySetAsSeries(BufSwingBearCHoCH, false);
   ArraySetAsSeries(BufIntBullBOS,     false);
   ArraySetAsSeries(BufIntBullCHoCH,   false);
   ArraySetAsSeries(BufIntBearBOS,     false);
   ArraySetAsSeries(BufIntBearCHoCH,   false);

   for(int b=0; b<8; b++)
      PlotIndexSetDouble(b, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   IndicatorSetString(INDICATOR_SHORTNAME, "SMC Structure Core (BOS/CHoCH)");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit - clean up only this indicator's chart objects           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "SMC_");
  }

//+------------------------------------------------------------------+
//| Helpers: rolling highest / lowest over [from..to] inclusive       |
//+------------------------------------------------------------------+
double Highest(const double &arr[], int from, int to)
  {
   double m = arr[from];
   for(int k=from+1; k<=to; k++)
      if(arr[k] > m) m = arr[k];
   return m;
  }

double Lowest(const double &arr[], int from, int to)
  {
   double m = arr[from];
   for(int k=from+1; k<=to; k++)
      if(arr[k] < m) m = arr[k];
   return m;
  }
//+------------------------------------------------------------------+
//| Draw a BOS/CHoCH structure segment + midpoint label               |
//| Equivalent to Pine drawStructure()                                |
//|   labelAbove = true  -> label sits ABOVE the line (bearish break) |
//|   labelAbove = false -> label sits BELOW the line (bullish break) |
//+------------------------------------------------------------------+
void DrawStructureLine(string prefix, datetime t1, datetime t2, double price,
                        string tag, color clr, ENUM_LINE_STYLE style,
                        datetime midTime, bool labelAbove, int fontSize)
  {
   string lname = prefix + "_LN_" + IntegerToString((long)t1) + "_" + IntegerToString((long)t2);
   if(ObjectFind(0, lname) < 0)
      ObjectCreate(0, lname, OBJ_TREND, 0, t1, price, t2, price);

   ObjectSetInteger(0, lname, OBJPROP_TIME,  0, t1);
   ObjectSetDouble (0, lname, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, lname, OBJPROP_TIME,  1, t2);
   ObjectSetDouble (0, lname, OBJPROP_PRICE, 1, price);
   ObjectSetInteger(0, lname, OBJPROP_RAY_LEFT,  false);   // <-- segment, NOT a chart-wide line
   ObjectSetInteger(0, lname, OBJPROP_RAY_RIGHT, false);   // <--
   ObjectSetInteger(0, lname, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, lname, OBJPROP_STYLE, style);
   ObjectSetInteger(0, lname, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, lname, OBJPROP_BACK, true);
   ObjectSetInteger(0, lname, OBJPROP_SELECTABLE, false);

   string tname = prefix + "_LBL_" + IntegerToString((long)t1) + "_" + IntegerToString((long)t2);
   if(ObjectFind(0, tname) < 0)
      ObjectCreate(0, tname, OBJ_TEXT, 0, midTime, price);

   ObjectSetInteger(0, tname, OBJPROP_TIME,  0, midTime);
   ObjectSetDouble (0, tname, OBJPROP_PRICE, 0, price);
   ObjectSetString (0, tname, OBJPROP_TEXT, tag);
   ObjectSetInteger(0, tname, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, tname, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, tname, OBJPROP_ANCHOR, labelAbove ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0, tname, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Draw a swing point label (HH / HL / LH / LL)                      |
//+------------------------------------------------------------------+
void DrawSwingPointLabel(string prefix, datetime t, double price, string tag,
                          color clr, bool above, int fontSize)
  {
   string name = prefix + "_PT_" + IntegerToString((long)t) + "_" + tag;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);

   ObjectSetInteger(0, name, OBJPROP_TIME,  0, t);
   ObjectSetDouble (0, name, OBJPROP_PRICE, 0, price);
   ObjectSetString (0, name, OBJPROP_TEXT, tag);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, above ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Update Strong/Weak High & Low trailing lines (redrawn each call) |
//+------------------------------------------------------------------+
void UpdateTrailingLines(datetime currentTime)
  {
   string topLine = "SMC_TRAIL_TOP_LN";
   string topLbl  = "SMC_TRAIL_TOP_LBL";
   string botLine = "SMC_TRAIL_BOT_LN";
   string botLbl  = "SMC_TRAIL_BOT_LBL";
if(ObjectFind(0, topLine) < 0)
      ObjectCreate(0, topLine, OBJ_TREND, 0, trailing.lastTopTime, trailing.top, currentTime, trailing.top);
   ObjectSetInteger(0, topLine, OBJPROP_TIME,  0, trailing.lastTopTime);
   ObjectSetDouble (0, topLine, OBJPROP_PRICE, 0, trailing.top);
   ObjectSetInteger(0, topLine, OBJPROP_TIME,  1, currentTime);
   ObjectSetDouble (0, topLine, OBJPROP_PRICE, 1, trailing.top);
   ObjectSetInteger(0, topLine, OBJPROP_RAY_LEFT,  false);
   ObjectSetInteger(0, topLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, topLine, OBJPROP_COLOR, InpSwingBearColor);
   ObjectSetInteger(0, topLine, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, topLine, OBJPROP_SELECTABLE, false);

   if(ObjectFind(0, topLbl) < 0)
      ObjectCreate(0, topLbl, OBJ_TEXT, 0, currentTime, trailing.top);
   ObjectSetInteger(0, topLbl, OBJPROP_TIME,  0, currentTime);
   ObjectSetDouble (0, topLbl, OBJPROP_PRICE, 0, trailing.top);
   ObjectSetString (0, topLbl, OBJPROP_TEXT, swingTrendBias==TREND_BEARISH ? "Strong High" : "Weak High");
   ObjectSetInteger(0, topLbl, OBJPROP_COLOR, InpSwingBearColor);
   ObjectSetInteger(0, topLbl, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, topLbl, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, topLbl, OBJPROP_SELECTABLE, false);

   if(ObjectFind(0, botLine) < 0)
      ObjectCreate(0, botLine, OBJ_TREND, 0, trailing.lastBottomTime, trailing.bottom, currentTime, trailing.bottom);
   ObjectSetInteger(0, botLine, OBJPROP_TIME,  0, trailing.lastBottomTime);
   ObjectSetDouble (0, botLine, OBJPROP_PRICE, 0, trailing.bottom);
   ObjectSetInteger(0, botLine, OBJPROP_TIME,  1, currentTime);
   ObjectSetDouble (0, botLine, OBJPROP_PRICE, 1, trailing.bottom);
   ObjectSetInteger(0, botLine, OBJPROP_RAY_LEFT,  false);
   ObjectSetInteger(0, botLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, botLine, OBJPROP_COLOR, InpSwingBullColor);
   ObjectSetInteger(0, botLine, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, botLine, OBJPROP_SELECTABLE, false);

   if(ObjectFind(0, botLbl) < 0)
      ObjectCreate(0, botLbl, OBJ_TEXT, 0, currentTime, trailing.bottom);
   ObjectSetInteger(0, botLbl, OBJPROP_TIME,  0, currentTime);
   ObjectSetDouble (0, botLbl, OBJPROP_PRICE, 0, trailing.bottom);
   ObjectSetString (0, botLbl, OBJPROP_TEXT, swingTrendBias==TREND_BULLISH ? "Strong Low" : "Weak Low");
   ObjectSetInteger(0, botLbl, OBJPROP_COLOR, InpSwingBullColor);
   ObjectSetInteger(0, botLbl, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, botLbl, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, botLbl, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Pivot detection - equivalent to Pine leg() + getCurrentStructure()|
//| length = InpSwingLength (internal=false) or InpInternalLength     |
//| (internal=true)                                                    |
//+------------------------------------------------------------------+
void ProcessPivots(int i, int length, const datetime &time[],
                    const double &high[], const double &low[], bool internal)
  {
   if(i < length) return;

   double hh = Highest(high, i-length+1, i);
   double ll = Lowest (low,  i-length+1, i);

   bool newLegHigh = high[i-length] > hh;
   bool newLegLow  = low[i-length]  < ll;

   int prevLeg = internal ? internalLeg : swingLeg;
   int newLeg  = prevLeg;
   if(newLegHigh)      newLeg = LEG_BEARISH;
   else if(newLegLow)  newLeg = LEG_BULLISH;

   bool pivotLowConfirmed  = (prevLeg != -1) && (newLeg != prevLeg) && (newLeg == LEG_BULLISH);
   bool pivotHighConfirmed = (prevLeg != -1) && (newLeg != prevLeg) && (newLeg == LEG_BEARISH);

   if(internal) internalLeg = newLeg; else swingLeg = newLeg;

   int pivBarIdx = i - length;
if(pivotLowConfirmed)
     {
      PivotPoint p = internal ? internalLow : swingLow;
      p.lastPrice = p.valid ? p.price : low[pivBarIdx];
      p.price     = low[pivBarIdx];
      p.time      = time[pivBarIdx];
      p.barIndex  = pivBarIdx;
      p.crossed   = false;
      p.valid     = true;
      if(internal) internalLow = p; else swingLow = p;

      if(!internal)
        {
         trailing.bottom         = p.price;
         trailing.lastBottomTime = p.time;
         trailing.valid          = true;

         if(InpShowSwingLabels)
            DrawSwingPointLabel("SMC_SWING", p.time, p.price,
                                 (p.price < p.lastPrice) ? "LL" : "HL",
                                 InpSwingBullColor, true, InpSwingPointFontSize);
        }
     }

   if(pivotHighConfirmed)
     {
      PivotPoint p = internal ? internalHigh : swingHigh;
      p.lastPrice = p.valid ? p.price : high[pivBarIdx];
      p.price     = high[pivBarIdx];
      p.time      = time[pivBarIdx];
      p.barIndex  = pivBarIdx;
      p.crossed   = false;
      p.valid     = true;
      if(internal) internalHigh = p; else swingHigh = p;

      if(!internal)
        {
         trailing.top         = p.price;
         trailing.lastTopTime = p.time;
         trailing.valid       = true;

         if(InpShowSwingLabels)
            DrawSwingPointLabel("SMC_SWING", p.time, p.price,
                                 (p.price > p.lastPrice) ? "HH" : "LH",
                                 InpSwingBearColor, false, InpSwingPointFontSize);
        }
     }
  }

//+------------------------------------------------------------------+
//| BOS/CHoCH break detection - equivalent to Pine displayStructure() |
//+------------------------------------------------------------------+
void CheckStructureBreaks(int i, const datetime &time[], const double &close[], bool internal)
  {
   PivotPoint pHigh = internal ? internalHigh : swingHigh;
   PivotPoint pLow  = internal ? internalLow  : swingLow;
   int trendBias    = internal ? internalTrendBias : swingTrendBias;

   bool   showThis = internal ? InpShowInternalStructure : InpShowSwingStructure;
   color  bullClr  = internal ? InpInternalBullColor : InpSwingBullColor;
   color  bearClr  = internal ? InpInternalBearColor : InpSwingBearColor;
   ENUM_LINE_STYLE lstyle = internal ? STYLE_DASH : STYLE_SOLID;
   int    fontSize = InpStructureLabelFontSize;
   string prefix   = internal ? "SMC_INT" : "SMC_SWING";

   // For internal structure, skip the break if it sits at the same price
   // as the current swing-level (avoids duplicate overlapping labels).
   bool extraBull = true, extraBear = true;
   if(internal)
     {
      extraBull = (!swingHigh.valid) || (pHigh.price != swingHigh.price);
      extraBear = (!swingLow.valid)  || (pLow.price  != swingLow.price);
     }

   //--- Bullish break: close crosses above pivot high
   if(pHigh.valid && !pHigh.crossed && close[i] > pHigh.price && extraBull)
     {
      string tag = (trendBias == TREND_BEARISH) ? "CHoCH" : "BOS";

      if(showThis)
        {
         int midIdx = (pHigh.barIndex + i) / 2;
         DrawStructureLine(prefix, pHigh.time, time[i], pHigh.price, tag,
                            bullClr, lstyle, time[midIdx], false, fontSize);
        }

      pHigh.crossed = true;
      if(internal) internalHigh = pHigh; else swingHigh = pHigh;

      if(internal) internalTrendBias = TREND_BULLISH; else swingTrendBias = TREND_BULLISH;

      if(internal)
        { if(tag=="BOS") BufIntBullBOS[i]=pHigh.price; else BufIntBullCHoCH[i]=pHigh.price; }
      else
        { if(tag=="BOS") BufSwingBullBOS[i]=pHigh.price; else BufSwingBullCHoCH[i]=pHigh.price; }
     }

   // re-read trend bias (may have just changed above)
   trendBias = internal ? internalTrendBias : swingTrendBias;

   //--- Bearish break: close crosses below pivot low
   if(pLow.valid && !pLow.crossed && close[i] < pLow.price && extraBear)
     {
      string tag = (trendBias == TREND_BULLISH) ? "CHoCH" : "BOS";
if(showThis)
        {
         int midIdx = (pLow.barIndex + i) / 2;
         DrawStructureLine(prefix, pLow.time, time[i], pLow.price, tag,
                            bearClr, lstyle, time[midIdx], true, fontSize);
        }

      pLow.crossed = true;
      if(internal) internalLow = pLow; else swingLow = pLow;

      if(internal) internalTrendBias = TREND_BEARISH; else swingTrendBias = TREND_BEARISH;

      if(internal)
        { if(tag=="BOS") BufIntBearBOS[i]=pLow.price; else BufIntBearCHoCH[i]=pLow.price; }
      else
        { if(tag=="BOS") BufSwingBearBOS[i]=pLow.price; else BufSwingBearCHoCH[i]=pLow.price; }
     }
  }

//+------------------------------------------------------------------+
//| OnCalculate                                                       |
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
   int maxLen = MathMax(InpSwingLength, InpInternalLength);
   if(rates_total < maxLen + 2)
      return(0);

   // ensure ascending (index 0 = oldest bar) indexing on everything we touch
   ArraySetAsSeries(time,  false);
   ArraySetAsSeries(open,  false);
   ArraySetAsSeries(high,  false);
   ArraySetAsSeries(low,   false);
   ArraySetAsSeries(close, false);

   int start;
   if(prev_calculated == 0)
     {
      // fresh calculation - reset all persisted state
      swingHigh.valid = false;  swingLow.valid = false;
      internalHigh.valid = false; internalLow.valid = false;
      swingLeg = -1; internalLeg = -1;
      swingTrendBias = TREND_NONE; internalTrendBias = TREND_NONE;
      trailing.valid = false;

      start = maxLen + 1;

      if(InpMaxHistoryBars > 0 && rates_total > InpMaxHistoryBars)
         start = rates_total - InpMaxHistoryBars;

      if(start < maxLen + 1)
         start = maxLen + 1;
     }
   else
      start = prev_calculated - 1;

   for(int i = start; i < rates_total; i++)
     {
      BufSwingBullBOS[i]   = EMPTY_VALUE;
      BufSwingBullCHoCH[i] = EMPTY_VALUE;
      BufSwingBearBOS[i]   = EMPTY_VALUE;
      BufSwingBearCHoCH[i] = EMPTY_VALUE;
      BufIntBullBOS[i]     = EMPTY_VALUE;
      BufIntBullCHoCH[i]   = EMPTY_VALUE;
      BufIntBearBOS[i]     = EMPTY_VALUE;
      BufIntBearCHoCH[i]   = EMPTY_VALUE;

      ProcessPivots(i, InpSwingLength,    time, high, low, false);
      ProcessPivots(i, InpInternalLength, time, high, low, true);

      CheckStructureBreaks(i, time, close, false);
      CheckStructureBreaks(i, time, close, true);

      if(trailing.valid)
        {
         if(high[i] >= trailing.top)    { trailing.top    = high[i]; trailing.lastTopTime    = time[i]; }
         if(low[i]  <= trailing.bottom) { trailing.bottom = low[i];  trailing.lastBottomTime = time[i]; }
        }
     }

   if(InpShowStrongWeak && trailing.valid)
      UpdateTrailingLines(time[rates_total-1]);

   return(rates_total);
  }
//+------------------------------------------------------------------+
