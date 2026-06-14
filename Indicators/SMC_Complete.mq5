//+------------------------------------------------------------------+
//|                                          SMC_Complete.mq5         |
//|  Smart Money Concepts — Full Structure Mapping Indicator         |
//|  Pivot Detection | BOS/CHoCH | Order Blocks | FVG | EQH/EQL      |
//|  Premium/Discount | Strong/Weak HL | MTF Levels | Buffers        |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "2.00"
#property description "SMC Full: Pivot -> BOS/CHoCH -> OB -> FVG -> PD Array -> MTF Levels"
#property indicator_chart_window
#property indicator_buffers 14
#property indicator_plots   14

//--- Buffer enums
enum BUFFER_IX
{
   BUF_INT_BULL_BOS   = 0,
   BUF_INT_BEAR_BOS   = 1,
   BUF_INT_BULL_CHOCH = 2,
   BUF_INT_BEAR_CHOCH = 3,
   BUF_SWING_BULL_BOS   = 4,
   BUF_SWING_BEAR_BOS   = 5,
   BUF_SWING_BULL_CHOCH = 6,
   BUF_SWING_BEAR_CHOCH = 7,
   BUF_OB_BULL_MITIGATED  = 8,
   BUF_OB_BEAR_MITIGATED  = 9,
   BUF_EQH = 10,
   BUF_EQL = 11,
   BUF_FVG_BULL = 12,
   BUF_FVG_BEAR = 13
};

//--- Plot definitions
#property indicator_label1  "Int Bull BOS"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Int Bear BOS"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "Int Bull CHoCH"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLimeGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "Int Bear CHoCH"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDarkOrange
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "Swing Bull BOS"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#property indicator_label6  "Swing Bear BOS"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

#property indicator_label7  "Swing Bull CHoCH"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrMediumSeaGreen
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

#property indicator_label8  "Swing Bear CHoCH"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrTomato
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1

#property indicator_label9  "Bull OB Mitigated"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrGold
#property indicator_style9  STYLE_SOLID
#property indicator_width9  1

#property indicator_label10 "Bear OB Mitigated"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrMagenta
#property indicator_style10 STYLE_SOLID
#property indicator_width10 1

#property indicator_label11 "EQH"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrCyan
#property indicator_style11 STYLE_SOLID
#property indicator_width11 1

#property indicator_label12 "EQL"
#property indicator_type12  DRAW_ARROW
#property indicator_color12 clrOrange
#property indicator_style12 STYLE_SOLID
#property indicator_width12 1

#property indicator_label13 "Bull FVG"
#property indicator_type13  DRAW_ARROW
#property indicator_color13 clrMediumSpringGreen
#property indicator_style13 STYLE_SOLID
#property indicator_width13 1

#property indicator_label14 "Bear FVG"
#property indicator_type14  DRAW_ARROW
#property indicator_color14 clrDeepPink
#property indicator_style14 STYLE_SOLID
#property indicator_width14 1

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_TREND_BIAS
{
   BIAS_NONE     = 0,
   BIAS_BULLISH  = 1,
   BIAS_BEARISH  = 2
};

enum ENUM_DISPLAY_FILTER
{
   DISPLAY_ALL    = 0,
   DISPLAY_BOS    = 1,
   DISPLAY_CHOCH  = 2
};

enum ENUM_LABEL_SIZE
{
   SIZE_TINY   = 0,
   SIZE_SMALL  = 1,
   SIZE_NORMAL = 2
};

enum ENUM_FILTER_METHOD
{
   FILTER_ATR  = 0,
   FILTER_CMR  = 1   // Cumulative Mean Range
};

enum ENUM_MITIGATION_SRC
{
   MITIGATE_CLOSE    = 0,
   MITIGATE_HIGHLOW  = 1
};

enum ENUM_MODE
{
   MODE_HISTORICAL = 0,
   MODE_PRESENT    = 1
};

//+------------------------------------------------------------------+
//| STRUCTS                                                          |
//+------------------------------------------------------------------+
struct PivotInfo
{
   double   price;
   datetime time;
   int      barIndex;
   bool     crossed;
};

struct PivotTracker
{
   // Current active (not-yet-crossed) pivots
   PivotInfo   pivotHigh;
   PivotInfo   pivotLow;
   
   // Trend bias state
   ENUM_TREND_BIAS trendBias;
   
   // Trailing extremes (reset at each new swing pivot)
   double    trailingTop;
   datetime  trailingTopTime;
   double    trailingBottom;
   datetime  trailingBottomTime;
   
   // Previous swing pivot for HH/HL/LH/LL comparison
   PivotInfo prevSwingHigh;
   PivotInfo prevSwingLow;
   
   // Last drawn BOS/CHoCH info (for cleanup in Present mode)
   datetime  lastBreakPivotTime;
   datetime  lastBreakBarTime;
   double    lastBreakPrice;
   bool      lastBreakIsBullish;
   string    lastBreakLabel;
   bool      lastBreakIsSwing;
   
   // Counters
   int       bullishBreaks;
   int       bearishBreaks;
};

struct OrderBlock
{
   datetime  pivotTime;
   datetime  impulseTime;
   double    impulseHigh;
   double    impulseLow;
   datetime  breakTime;
   double    obTop;
   double    obBottom;
   bool      isBullish;
   bool      isSwing;
   bool      mitigated;
};

struct EqualLevel
{
   datetime  pivot1Time;
   double    pivot1Price;
   datetime  pivot2Time;
   double    pivot2Price;
   bool      isHigh;
};

struct FVG
{
   datetime  barATime;
   datetime  barBTime;
   datetime  barCTime;
   double    fvgTop;
   double    fvgBottom;
   bool      isBullish;
   bool      filled;
};

//+------------------------------------------------------------------+
//| INPUTS — General                                                 |
//+------------------------------------------------------------------+
input ENUM_MODE        InpMode                = MODE_HISTORICAL;  // Mode
input bool             InpColorCandlesByTrend = false;            // Color candles by internal trend

//+------------------------------------------------------------------+
//| INPUTS — Internal Structure                                      |
//+------------------------------------------------------------------+
input bool                InpShowInternal        = true;             // Show Internal Structure
input ENUM_DISPLAY_FILTER InpIntBullFilter       = DISPLAY_ALL;      // Int Bull Display
input ENUM_DISPLAY_FILTER InpIntBearFilter       = DISPLAY_ALL;      // Int Bear Display
input color               InpIntBullColor        = clrDodgerBlue;    // Int Bull Color
input color               InpIntBearColor        = clrCrimson;       // Int Bear Color
input bool                InpIntConfluenceFilter = false;            // Int Confluence Filter
input ENUM_LABEL_SIZE     InpIntLabelSize        = SIZE_TINY;        // Int Label Size
input int                 InpIntLength           = 5;                // Internal Pivot Length

//+------------------------------------------------------------------+
//| INPUTS — Swing Structure                                         |
//+------------------------------------------------------------------+
input bool                InpShowSwing           = true;             // Show Swing Structure
input ENUM_DISPLAY_FILTER InpSwingBullFilter     = DISPLAY_ALL;      // Swing Bull Display
input ENUM_DISPLAY_FILTER InpSwingBearFilter     = DISPLAY_ALL;      // Swing Bear Display
input color               InpSwingBullColor      = clrBlue;          // Swing Bull Color
input color               InpSwingBearColor      = clrRed;           // Swing Bear Color
input ENUM_LABEL_SIZE     InpSwingLabelSize      = SIZE_SMALL;       // Swing Label Size
input bool                InpShowSwingPointLabels = false;           // Show swing point labels
input int                 InpSwingLength         = 50;               // Swing Length (min 10)
input bool                InpShowStrongWeakHL    = true;             // Show Strong/Weak High/Low

//+------------------------------------------------------------------+
//| INPUTS — Order Blocks                                            |
//+------------------------------------------------------------------+
input bool                InpShowIntOBs          = true;             // Show Internal OBs
input int                 InpIntOBMax            = 5;                // Int OB Max Count
input bool                InpShowSwingOBs        = false;            // Show Swing OBs
input int                 InpSwingOBMax          = 5;                // Swing OB Max Count
input ENUM_FILTER_METHOD  InpOBFilterMethod      = FILTER_ATR;      // OB Filter Method
input ENUM_MITIGATION_SRC InpOBMitigationSrc     = MITIGATE_HIGHLOW; // OB Mitigation Source
input color               InpIntOBBullColor      = clrDodgerBlue;    // Int Bull OB Color
input color               InpIntOBBearColor      = clrCrimson;       // Int Bear OB Color
input color               InpSwingOBBullColor    = clrBlue;          // Swing Bull OB Color
input color               InpSwingOBBearColor    = clrRed;           // Swing Bear OB Color

//+------------------------------------------------------------------+
//| INPUTS — Equal Highs/Lows                                        |
//+------------------------------------------------------------------+
input bool             InpShowEQHEQL          = true;             // Show EQH/EQL
input int              InpEqLen               = 3;                // EQH/EQL Bars Confirmation
input double           InpEqThreshold         = 0.1;              // EQH/EQL Threshold
input ENUM_LABEL_SIZE  InpEqLabelSize         = SIZE_TINY;        // EQH/EQL Label Size

//+------------------------------------------------------------------+
//| INPUTS — Fair Value Gaps                                         |
//+------------------------------------------------------------------+
input bool             InpShowFVG             = false;            // Show FVGs
input bool             InpFVG_AutoThreshold   = true;             // FVG Auto Threshold
input ENUM_TIMEFRAMES  InpFVG_TF              = PERIOD_CURRENT;   // FVG Timeframe
input int              InpFVG_ExtendBars      = 1;                // FVG Extend (bars)
input color            InpFVG_BullColor       = clrMediumSpringGreen; // FVG Bull Color
input color            InpFVG_BearColor       = clrDeepPink;      // FVG Bear Color

//+------------------------------------------------------------------+
//| INPUTS — MTF Levels                                              |
//+------------------------------------------------------------------+
input bool             InpShowDaily           = true;             // Show Daily Levels
input ENUM_LINE_STYLE  InpDailyStyle          = STYLE_SOLID;      // Daily Line Style
input color            InpDailyColor          = clrGray;          // Daily Color
input bool             InpShowWeekly          = false;            // Show Weekly Levels
input ENUM_LINE_STYLE  InpWeeklyStyle         = STYLE_DASH;       // Weekly Line Style
input color            InpWeeklyColor         = clrDarkGray;      // Weekly Color
input bool             InpShowMonthly         = false;            // Show Monthly Levels
input ENUM_LINE_STYLE  InpMonthlyStyle        = STYLE_DOT;        // Monthly Line Style
input color            InpMonthlyColor        = clrDimGray;       // Monthly Color

//+------------------------------------------------------------------+
//| INPUTS — Premium/Discount Zones                                  |
//+------------------------------------------------------------------+
input bool             InpShowPDZones         = false;            // Show Premium/Discount Zones
input color            InpPremiumColor        = clrRed;           // Premium Zone Color
input color            InpEquilibriumColor    = clrGray;          // Equilibrium Zone Color
input color            InpDiscountColor       = clrGreen;         // Discount Zone Color

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
long     g_chartId;
string   g_prefix = "SMC_";
int      g_atrHandle = INVALID_HANDLE;

// Pivot trackers
PivotTracker g_swingTracker;
PivotTracker g_intTracker;
PivotTracker g_eqTracker;

// Order block arrays
OrderBlock g_intOBs[];
OrderBlock g_swingOBs[];

// Equal levels
EqualLevel g_eqLevel;

// FVG arrays
FVG g_fvgs[];

// Swing point tracking
double   g_lastSwingHighPrice = 0;
double   g_lastSwingLowPrice = 0;
bool     g_hasPrevSwingHigh = false;
bool     g_hasPrevSwingLow = false;

// Strong/Weak trailing
double   g_trailTop = 0;
double   g_trailBottom = 0;
datetime g_trailTopTime = 0;
datetime g_trailBottomTime = 0;

// MTF levels
struct MTFLevel
{
   double   price;
   datetime barTime;
   string   label;
};
MTFLevel g_dailyHigh, g_dailyLow;
MTFLevel g_weeklyHigh, g_weeklyLow;
MTFLevel g_monthlyHigh, g_monthlyLow;

// Last bar time
datetime g_lastBarTime = 0;

// FVG static accumulators
double g_fvgSumPct = 0;
int    g_fvgCountPct = 0;

// Indicator buffers
double g_bufIntBullBOS[];
double g_bufIntBearBOS[];
double g_bufIntBullCHoCH[];
double g_bufIntBearCHoCH[];
double g_bufSwingBullBOS[];
double g_bufSwingBearBOS[];
double g_bufSwingBullCHoCH[];
double g_bufSwingBearCHoCH[];
double g_bufOBBullMitigated[];
double g_bufOBBearMitigated[];
double g_bufEQH[];
double g_bufEQL[];
double g_bufFVGBull[];
double g_bufFVGBear[];

//+------------------------------------------------------------------+
//| INIT                                                             |
//+------------------------------------------------------------------+
void OnInit()
{
   g_chartId = ChartID();
   
   SetIndexBuffer(BUF_INT_BULL_BOS,   g_bufIntBullBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_BOS,   g_bufIntBearBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BULL_CHOCH, g_bufIntBullCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_CHOCH, g_bufIntBearCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_BOS,   g_bufSwingBullBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_BOS,   g_bufSwingBearBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_CHOCH, g_bufSwingBullCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_CHOCH, g_bufSwingBearCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BULL_MITIGATED,  g_bufOBBullMitigated,  INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BEAR_MITIGATED,  g_bufOBBearMitigated,  INDICATOR_DATA);
   SetIndexBuffer(BUF_EQH, g_bufEQH, INDICATOR_DATA);
   SetIndexBuffer(BUF_EQL, g_bufEQL, INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BULL, g_bufFVGBull, INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BEAR, g_bufFVGBear, INDICATOR_DATA);
   
   // Arrow codes
   for(int i = 0; i < 14; i++)
   {
      PlotIndexSetInteger(i, PLOT_ARROW, (i % 2 == 0) ? 233 : 234);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
   }
   PlotIndexSetInteger(BUF_OB_BULL_MITIGATED,  PLOT_ARROW, 76);  // M
   PlotIndexSetInteger(BUF_OB_BEAR_MITIGATED,  PLOT_ARROW, 77);  // n
   
   // Initialize trackers
   InitTracker(g_swingTracker, BIAS_NONE);
   InitTracker(g_intTracker, BIAS_NONE);
   InitTracker(g_eqTracker, BIAS_NONE);
   
   // ATR handle
   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, 200);
   if(g_atrHandle == INVALID_HANDLE)
      Print("WARNING: ATR handle failed");
   
   IndicatorSetString(INDICATOR_SHORTNAME, "SMC Complete (" + IntegerToString(InpSwingLength) + ")");
   
   ObjectsDeleteAll(g_chartId, g_prefix);
}

//+------------------------------------------------------------------+
//| DEINIT                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(g_chartId, g_prefix);
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
//| TRACKER INIT                                                     |
//+------------------------------------------------------------------+
void InitTracker(PivotTracker &t, ENUM_TREND_BIAS bias)
{
   t.pivotHigh.price = 0;   t.pivotHigh.time = 0;   t.pivotHigh.crossed = true;
   t.pivotLow.price  = 0;   t.pivotLow.time  = 0;   t.pivotLow.crossed = true;
   t.trendBias = bias;
   t.trailingTop = 0;       t.trailingTopTime = 0;
   t.trailingBottom = 1e10; t.trailingBottomTime = 0;
   t.prevSwingHigh.price = 0;   t.prevSwingHigh.time = 0;
   t.prevSwingLow.price  = 0;   t.prevSwingLow.time  = 0;
   t.lastBreakPivotTime = 0;
   t.lastBreakBarTime = 0;
   t.lastBreakPrice = 0;
   t.lastBreakIsBullish = false;
   t.lastBreakLabel = "";
   t.lastBreakIsSwing = false;
   t.bullishBreaks = 0;
   t.bearishBreaks = 0;
}

//+------------------------------------------------------------------+
//| HELPER: Font size                                                |
//+------------------------------------------------------------------+
int GetFontSize(ENUM_LABEL_SIZE sz)
{
   switch(sz)
   {
      case SIZE_TINY:   return 7;
      case SIZE_SMALL:  return 9;
      case SIZE_NORMAL: return 12;
   }
   return 9;
}

//+------------------------------------------------------------------+
//| HELPER: ATR                                                      |
//+------------------------------------------------------------------+
double GetATR(int index)
{
   double atr[];
   ArraySetAsSeries(atr, true);
   if(g_atrHandle != INVALID_HANDLE && CopyBuffer(g_atrHandle, 0, index, 1, atr) > 0)
      return atr[0];
   // Fallback simple ATR
   double sum = 0;
   int count = 0;
   for(int i = index; i < index + 14 && i < 10000; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      double pc = iClose(_Symbol, PERIOD_CURRENT, i+1);
      if(h > 0 && l > 0)
      {
         sum += MathMax(h - l, MathMax(MathAbs(h - pc), MathAbs(l - pc)));
         count++;
      }
   }
   return count > 0 ? sum / count : 0;
}

//+------------------------------------------------------------------+
//| HELPER: Cumulative Mean Range                                    |
//+------------------------------------------------------------------+
double GetCMR(int index)
{
   double sum = 0;
   int count = 0;
   int maxBars = MathMin(200, 10000);
   for(int i = 0; i < maxBars; i++)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, index + i);
      double l = iLow(_Symbol, PERIOD_CURRENT, index + i);
      double pc = iClose(_Symbol, PERIOD_CURRENT, index + i + 1);
      if(h > 0 && l > 0)
      {
         sum += MathMax(h - l, MathMax(MathAbs(h - pc), MathAbs(l - pc)));
         count++;
      }
   }
   return count > 0 ? sum / count : 0;
}

//+------------------------------------------------------------------+
//| HELPER: Parsed high/low for spike candle handling                |
//+------------------------------------------------------------------+
void GetParsedHL(int barIndex, double &parsedHigh, double &parsedLow)
{
   double h = iHigh(_Symbol, PERIOD_CURRENT, barIndex);
   double l = iLow(_Symbol, PERIOD_CURRENT, barIndex);
   double atr = GetATR(barIndex);
   double cmr = GetCMR(barIndex);
   
   double spikeThreshold = (InpOBFilterMethod == FILTER_ATR) ? (2.0 * atr) : (2.0 * cmr);
   
   if(spikeThreshold > 0 && (h - l) >= spikeThreshold)
   {
      parsedHigh = l;
      parsedLow  = h;
   }
   else
   {
      parsedHigh = h;
      parsedLow  = l;
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 1: PIVOT DETECTION — Rolling Leg State                   |
//|                                                                |
//+------------------------------------------------------------------+
void DetectPivot(PivotTracker &t, int L, int rates_total,
                 const datetime &time[], const double &high[], const double &low[])
{
   if(rates_total <= L + 2) return;
   
   int barL = L;
   
   // --- Check for pivot HIGH at bar L ---
   bool isPivotHigh = true;
   for(int i = 0; i < L; i++)
   {
      if(high[barL] <= high[i]) { isPivotHigh = false; break; }
   }
   
   if(isPivotHigh)
   {
      t.pivotHigh.price = high[barL];
      t.pivotHigh.time  = time[barL];
      t.pivotHigh.barIndex = barL;
      t.pivotHigh.crossed = false;
      
      t.trendBias = BIAS_BEARISH;
      
      // Reset trailing top for swing
      if(L >= 10)
      {
         g_trailTop = high[barL];
         g_trailTopTime = time[barL];
         t.trailingTop = high[barL];
         t.trailingTopTime = time[barL];
      }
      
      // Store for HH/LH comparison
      if(L >= 10)
         t.prevSwingHigh.price = high[barL];
   }
   
   // --- Check for pivot LOW at bar L ---
   bool isPivotLow = true;
   for(int i = 0; i < L; i++)
   {
      if(low[barL] >= low[i]) { isPivotLow = false; break; }
   }
   
   if(isPivotLow)
   {
      t.pivotLow.price = low[barL];
      t.pivotLow.time  = time[barL];
      t.pivotLow.barIndex = barL;
      t.pivotLow.crossed = false;
      
      t.trendBias = BIAS_BULLISH;
      
      if(L >= 10)
      {
         g_trailBottom = low[barL];
         g_trailBottomTime = time[barL];
         t.trailingBottom = low[barL];
         t.trailingBottomTime = time[barL];
      }
      
      if(L >= 10)
         t.prevSwingLow.price = low[barL];
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 2: BOS/CHoCH DETECTION + SEGMENT DRAWING                 |
//|                                                                |
//+------------------------------------------------------------------+
bool GetLabelVisibility(bool isBullish, ENUM_DISPLAY_FILTER filter, bool isCHoCH)
{
   switch(filter)
   {
      case DISPLAY_ALL:   return true;
      case DISPLAY_BOS:   return !isCHoCH;
      case DISPLAY_CHOCH: return isCHoCH;
   }
   return true;
}

void SetBufferBreak(int L, bool isBullish, bool isCHoCH, double price, int bar)
{
   if(L >= 10)
   {
      if(isBullish && !isCHoCH)      g_bufSwingBullBOS[bar] = price;
      else if(isBullish && isCHoCH)  g_bufSwingBullCHoCH[bar] = price;
      else if(!isBullish && !isCHoCH) g_bufSwingBearBOS[bar] = price;
      else                           g_bufSwingBearCHoCH[bar] = price;
   }
   else
   {
      if(isBullish && !isCHoCH)      g_bufIntBullBOS[bar] = price;
      else if(isBullish && isCHoCH)  g_bufIntBullCHoCH[bar] = price;
      else if(!isBullish && !isCHoCH) g_bufIntBearBOS[bar] = price;
      else                           g_bufIntBearCHoCH[bar] = price;
   }
}

void DrawStructureSegment(datetime pivotTime, datetime breakTime, double price,
                          string label, bool isBullish, bool isSwing,
                          color lineColor, ENUM_LABEL_SIZE labelSize, bool visible)
{
   if(!visible) return;
   if(!isSwing && !InpShowInternal) return;
   if(isSwing && !InpShowSwing) return;
   
   string prefix = g_prefix + (isSwing ? "SW_" : "IN_");
   string id = prefix + "STRUCT_" + IntegerToString(pivotTime);
   string lineName = id + "_LINE";
   string lblName = id + "_LBL";
   
   // Present mode: delete old
   if(InpMode == MODE_PRESENT)
   {
      ObjectDelete(g_chartId, lineName);
      ObjectDelete(g_chartId, lblName);
   }
   
   // Create SEGMENT line (OBJ_TREND, no rays)
   if(ObjectFind(g_chartId, lineName) < 0)
      ObjectCreate(g_chartId, lineName, OBJ_TREND, 0, pivotTime, price, breakTime, price);
   else
   {
      ObjectMove(g_chartId, lineName, 0, pivotTime, price);
      ObjectMove(g_chartId, lineName, 1, breakTime, price);
   }
   
   ObjectSetInteger(g_chartId, lineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_WIDTH, isSwing ? 2 : 1);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_STYLE, isSwing ? STYLE_SOLID : STYLE_DASH);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_SELECTABLE, false);
   
   // Label at horizontal midpoint
   datetime midTime = pivotTime + (breakTime - pivotTime) / 2;
   
   if(ObjectFind(g_chartId, lblName) < 0)
      ObjectCreate(g_chartId, lblName, OBJ_TEXT, 0, midTime, price);
   else
      ObjectMove(g_chartId, lblName, 0, midTime, price);
   
   ObjectSetString(g_chartId, lblName, OBJPROP_TEXT, label);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_FONTSIZE, GetFontSize(labelSize));
   ObjectSetString(g_chartId, lblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, lblName, OBJPROP_ANCHOR, isBullish ? ANCHOR_TOP : ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_SELECTABLE, false);
}

void CheckBreak(PivotTracker &t, int L, int rates_total, int currentBar,
                const datetime &time[], const double &high[], const double &low[], const double &close[])
{
   if(currentBar < 0 || currentBar >= rates_total) return;
   if(!InpShowInternal && L < 10) return;
   if(!InpShowSwing && L >= 10) return;
   
   double currentClose = close[currentBar];
   datetime currentTime = time[currentBar];
   
   // --- Bullish break: close above pivot high ---
   if(t.pivotHigh.price > 0 && !t.pivotHigh.crossed)
   {
      if(currentClose > t.pivotHigh.price)
      {
         t.pivotHigh.crossed = true;
         
         bool isCHoCH = (t.trendBias == BIAS_BEARISH);
         string label = isCHoCH ? "CHoCH" : "BOS";
         
         color col = (L >= 10) ? InpSwingBullColor : InpIntBullColor;
         ENUM_LABEL_SIZE sz = (L >= 10) ? InpSwingLabelSize : InpIntLabelSize;
         ENUM_DISPLAY_FILTER flt = (L >= 10) ? InpSwingBullFilter : InpIntBullFilter;
         
         DrawStructureSegment(t.pivotHigh.time, currentTime, t.pivotHigh.price,
                            label, true, (L >= 10), col, sz,
                            GetLabelVisibility(true, flt, isCHoCH));
         
         t.trendBias = BIAS_BULLISH;
         
         // Fire OB detection
         if(L >= 10 && InpShowSwingOBs)
            CreateOrderBlock(t, true, t.pivotHigh.time, currentTime, currentBar, high, low, close, time, true);
         else if(L < 10 && InpShowIntOBs)
            CreateOrderBlock(t, true, t.pivotHigh.time, currentTime, currentBar, high, low, close, time, false);
         
         SetBufferBreak(L, true, isCHoCH, t.pivotHigh.price, currentBar);
         
         t.lastBreakPivotTime = t.pivotHigh.time;
         t.lastBreakBarTime = currentTime;
         t.lastBreakPrice = t.pivotHigh.price;
         t.lastBreakIsBullish = true;
         t.lastBreakLabel = label;
         t.lastBreakIsSwing = (L >= 10);
         t.bullishBreaks++;
         
         Print("SMC: " + label + " " + (L >= 10 ? "SWING":"INT") + " BULLISH at " + DoubleToString(t.pivotHigh.price, _Digits));
      }
   }
   
   // --- Bearish break: close below pivot low ---
   if(t.pivotLow.price > 0 && !t.pivotLow.crossed)
   {
      if(currentClose < t.pivotLow.price)
      {
         t.pivotLow.crossed = true;
         
         bool isCHoCH = (t.trendBias == BIAS_BULLISH);
         string label = isCHoCH ? "CHoCH" : "BOS";
         
         color col = (L >= 10) ? InpSwingBearColor : InpIntBearColor;
         ENUM_LABEL_SIZE sz = (L >= 10) ? InpSwingLabelSize : InpIntLabelSize;
         ENUM_DISPLAY_FILTER flt = (L >= 10) ? InpSwingBearFilter : InpIntBearFilter;
         
         DrawStructureSegment(t.pivotLow.time, currentTime, t.pivotLow.price,
                            label, false, (L >= 10), col, sz,
                            GetLabelVisibility(false, flt, isCHoCH));
         
         t.trendBias = BIAS_BEARISH;
         
         if(L >= 10 && InpShowSwingOBs)
            CreateOrderBlock(t, false, t.pivotLow.time, currentTime, currentBar, high, low, close, time, true);
         else if(L < 10 && InpShowIntOBs)
            CreateOrderBlock(t, false, t.pivotLow.time, currentTime, currentBar, high, low, close, time, false);
         
         SetBufferBreak(L, false, isCHoCH, t.pivotLow.price, currentBar);
         
         t.lastBreakPivotTime = t.pivotLow.time;
         t.lastBreakBarTime = currentTime;
         t.lastBreakPrice = t.pivotLow.price;
         t.lastBreakIsBullish = false;
         t.lastBreakLabel = label;
         t.lastBreakIsSwing = (L >= 10);
         t.bearishBreaks++;
         
         Print("SMC: " + label + " " + (L >= 10 ? "SWING":"INT") + " BEARISH at " + DoubleToString(t.pivotLow.price, _Digits));
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 3: ORDER BLOCKS                                           |
//|                                                                |
//+------------------------------------------------------------------+
void CreateOrderBlock(PivotTracker &t, bool isBullishBreak,
                      datetime pivotTime, datetime breakTime, int breakBar,
                      const double &high[], const double &low[], const double &close[],
                      const datetime &time[], bool isSwing)
{
   int pivotBar = -1;
   int brkBar = breakBar;
   int timeSize = ArraySize(time);
   for(int i = 0; i < timeSize; i++)
   {
      if(time[i] == pivotTime) { pivotBar = i; break; }
   }
   if(pivotBar < 0 || brkBar <= pivotBar) return;
   
   // Find impulse candle
   // Bullish break (price broke up thru pivot high) -> bearish OB
   //   impulse = highest parsed high in the range
   // Bearish break (price broke down thru pivot low) -> bullish OB
   //   impulse = lowest parsed low in the range
   
   double impulsePrice = isBullishBreak ? -1e10 : 1e10;
   int impulseBar = pivotBar;
   double impulseHigh = 0, impulseLow = 0;
   
   for(int i = pivotBar; i <= brkBar; i++)
   {
      double pH, pL;
      GetParsedHL(i, pH, pL);
      
      if(isBullishBreak)
      {
         if(pH > impulsePrice)
         {
            impulsePrice = pH;
            impulseBar = i;
            impulseHigh = pH;
            impulseLow = pL;
         }
      }
      else
      {
         if(pL < impulsePrice)
         {
            impulsePrice = pL;
            impulseBar = i;
            impulseHigh = pH;
            impulseLow = pL;
         }
      }
   }
   
   OrderBlock ob;
   ob.pivotTime = pivotTime;
   ob.impulseTime = time[impulseBar];
   ob.impulseHigh = impulseHigh;
   ob.impulseLow = impulseLow;
   ob.breakTime = breakTime;
   ob.obTop = impulseHigh;
   ob.obBottom = impulseLow;
   ob.isBullish = !isBullishBreak; // Bullish break -> bearish OB, vice versa
   ob.isSwing = isSwing;
   ob.mitigated = false;
   
   if(isSwing)
      AddOBToArray(g_swingOBs, ob, InpSwingOBMax);
   else
      AddOBToArray(g_intOBs, ob, InpIntOBMax);
   
   DrawOBRectangle(ob);
}

void AddOBToArray(OrderBlock &arr[], OrderBlock &ob, int maxCount)
{
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);
   arr[size] = ob;
   
   if(size + 1 > maxCount)
   {
      for(int i = 0; i < size; i++)
         arr[i] = arr[i + 1];
      ArrayResize(arr, maxCount);
   }
}

void DrawOBRectangle(OrderBlock &ob)
{
   if(ob.mitigated) return;
   
   string prefix = g_prefix + (ob.isSwing ? "SW_OB_" : "IN_OB_");
   string rectName = prefix + (ob.isBullish ? "BULL_" : "BEAR_") + IntegerToString(ob.pivotTime);
   
   color rectColor;
   if(ob.isSwing)
      rectColor = ob.isBullish ? InpSwingOBBullColor : InpSwingOBBearColor;
   else
      rectColor = ob.isBullish ? InpIntOBBullColor : InpIntOBBearColor;
   
   ObjectDelete(g_chartId, rectName);
   
   datetime rightEdge = iTime(_Symbol, PERIOD_CURRENT, 0);
   ObjectCreate(g_chartId, rectName, OBJ_RECTANGLE, 0,
                ob.impulseTime, ob.obTop, rightEdge, ob.obBottom);
   
   ObjectSetInteger(g_chartId, rectName, OBJPROP_COLOR, rectColor);
   ObjectSetInteger(g_chartId, rectName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, rectName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, rectName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, rectName, OBJPROP_SELECTABLE, false);
}

void UpdateOBs(const double &high[], const double &low[], const double &close[], int currentBar)
{
   datetime now = iTime(_Symbol, PERIOD_CURRENT, 0);
   double currentHigh = high[currentBar];
   double currentLow = low[currentBar];
   double currentClose = close[currentBar];
   
   // Swing OBs
   for(int i = 0; i < ArraySize(g_swingOBs); i++)
   {
      if(g_swingOBs[i].mitigated) continue;
      
      string rectName = g_prefix + "SW_OB_" + (g_swingOBs[i].isBullish ? "BULL_" : "BEAR_") 
                        + IntegerToString(g_swingOBs[i].pivotTime);
      ObjectMove(g_chartId, rectName, 1, now, g_swingOBs[i].obBottom);
      
      bool mitigated = false;
      if(InpOBMitigationSrc == MITIGATE_CLOSE)
      {
         if(!g_swingOBs[i].isBullish && currentClose > g_swingOBs[i].obTop) mitigated = true;
         if(g_swingOBs[i].isBullish && currentClose < g_swingOBs[i].obBottom) mitigated = true;
      }
      else
      {
         if(!g_swingOBs[i].isBullish && currentHigh > g_swingOBs[i].obTop) mitigated = true;
         if(g_swingOBs[i].isBullish && currentLow < g_swingOBs[i].obBottom) mitigated = true;
      }
      
      if(mitigated)
      {
         g_swingOBs[i].mitigated = true;
         ObjectDelete(g_chartId, rectName);
         if(g_swingOBs[i].isBullish)
            g_bufOBBullMitigated[currentBar] = g_swingOBs[i].obBottom;
         else
            g_bufOBBearMitigated[currentBar] = g_swingOBs[i].obTop;
         Print("SMC: OB MITIGATED " + (g_swingOBs[i].isBullish?"BULL":"BEAR") + " SWING");
      }
   }
   
   // Internal OBs
   for(int i = 0; i < ArraySize(g_intOBs); i++)
   {
      if(g_intOBs[i].mitigated) continue;
      
      string rectName = g_prefix + "IN_OB_" + (g_intOBs[i].isBullish ? "BULL_" : "BEAR_") 
                        + IntegerToString(g_intOBs[i].pivotTime);
      ObjectMove(g_chartId, rectName, 1, now, g_intOBs[i].obBottom);
      
      bool mitigated = false;
      if(InpOBMitigationSrc == MITIGATE_CLOSE)
      {
         if(!g_intOBs[i].isBullish && currentClose > g_intOBs[i].obTop) mitigated = true;
         if(g_intOBs[i].isBullish && currentClose < g_intOBs[i].obBottom) mitigated = true;
      }
      else
      {
         if(!g_intOBs[i].isBullish && currentHigh > g_intOBs[i].obTop) mitigated = true;
         if(g_intOBs[i].isBullish && currentLow < g_intOBs[i].obBottom) mitigated = true;
      }
      
      if(mitigated)
      {
         g_intOBs[i].mitigated = true;
         ObjectDelete(g_chartId, rectName);
         if(g_intOBs[i].isBullish)
            g_bufOBBullMitigated[currentBar] = g_intOBs[i].obBottom;
         else
            g_bufOBBearMitigated[currentBar] = g_intOBs[i].obTop;
         Print("SMC: OB MITIGATED " + (g_intOBs[i].isBullish?"BULL":"BEAR") + " INT");
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 4: EQUAL HIGHS / EQUAL LOWS                              |
//|                                                                |
//+------------------------------------------------------------------+
void DrawEQHEQL(datetime t1, datetime t2, double p1, double p2, bool isHigh)
{
   string prefix = g_prefix + (isHigh ? "EQH_" : "EQL_");
   ObjectDelete(g_chartId, prefix + "LINE");
   ObjectDelete(g_chartId, prefix + "LBL");
   
   double price = (p1 + p2) / 2.0;
   datetime midTime = t1 + (t2 - t1) / 2;
   
   string lineName = prefix + "LINE";
   if(ObjectFind(g_chartId, lineName) < 0)
      ObjectCreate(g_chartId, lineName, OBJ_TREND, 0, t1, p1, t2, p2);
   else
   {
      ObjectMove(g_chartId, lineName, 0, t1, p1);
      ObjectMove(g_chartId, lineName, 1, t2, p2);
   }
   ObjectSetInteger(g_chartId, lineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_COLOR, isHigh ? clrCyan : clrOrange);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(g_chartId, lineName, OBJPROP_SELECTABLE, false);
   
   string lblName = prefix + "LBL";
   if(ObjectFind(g_chartId, lblName) < 0)
      ObjectCreate(g_chartId, lblName, OBJ_TEXT, 0, midTime, price);
   else
      ObjectMove(g_chartId, lblName, 0, midTime, price);
   
   ObjectSetString(g_chartId, lblName, OBJPROP_TEXT, isHigh ? "EQH" : "EQL");
   ObjectSetInteger(g_chartId, lblName, OBJPROP_COLOR, isHigh ? clrCyan : clrOrange);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_FONTSIZE, GetFontSize(InpEqLabelSize));
   ObjectSetString(g_chartId, lblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, lblName, OBJPROP_ANCHOR, isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP);
   ObjectSetInteger(g_chartId, lblName, OBJPROP_SELECTABLE, false);
}

void CheckEqualHighsLows(int rates_total, const datetime &time[],
                         const double &high[], const double &low[])
{
   if(!InpShowEQHEQL) return;
   
   int L = InpEqLen;
   if(rates_total <= L + 2) return;
   
   int barL = L;
   bool hasHigh = true;
   for(int i = 0; i < L; i++)
      if(high[barL] <= high[i]) { hasHigh = false; break; }
   
   bool hasLow = true;
   for(int i = 0; i < L; i++)
      if(low[barL] >= low[i]) { hasLow = false; break; }
   
   double atr = GetATR(barL);
   double threshold = (atr > 0) ? InpEqThreshold * atr : 0;
   
   if(hasHigh && g_eqTracker.pivotHigh.price > 0 && !g_eqTracker.pivotHigh.crossed)
   {
      if(MathAbs(high[barL] - g_eqTracker.pivotHigh.price) < threshold)
      {
         DrawEQHEQL(g_eqTracker.pivotHigh.time, time[barL],
                   g_eqTracker.pivotHigh.price, high[barL], true);
         g_bufEQH[barL] = high[barL];
         Print("SMC: EQH at " + DoubleToString(high[barL], _Digits));
      }
   }
   
   if(hasLow && g_eqTracker.pivotLow.price > 0 && !g_eqTracker.pivotLow.crossed)
   {
      if(MathAbs(low[barL] - g_eqTracker.pivotLow.price) < threshold)
      {
         DrawEQHEQL(g_eqTracker.pivotLow.time, time[barL],
                   g_eqTracker.pivotLow.price, low[barL], false);
         g_bufEQL[barL] = low[barL];
         Print("SMC: EQL at " + DoubleToString(low[barL], _Digits));
      }
   }
   
   if(hasHigh)
   {
      g_eqTracker.pivotHigh.price = high[barL];
      g_eqTracker.pivotHigh.time = time[barL];
      g_eqTracker.pivotHigh.crossed = false;
   }
   if(hasLow)
   {
      g_eqTracker.pivotLow.price = low[barL];
      g_eqTracker.pivotLow.time = time[barL];
      g_eqTracker.pivotLow.crossed = false;
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 5: FAIR VALUE GAPS                                        |
//|                                                                |
//+------------------------------------------------------------------+
void AddFVG(datetime tA, datetime tB, datetime tC,
            double fvgTop, double fvgBottom, double aLow, bool isBullish)
{
   // Dedup check
   for(int i = 0; i < ArraySize(g_fvgs); i++)
      if(g_fvgs[i].barBTime == tB && g_fvgs[i].isBullish == isBullish)
         return;
   
   FVG fvg;
   fvg.barATime = tA;
   fvg.barBTime = tB;
   fvg.barCTime = tC;
   fvg.fvgTop = fvgTop;
   fvg.fvgBottom = fvgBottom;
   fvg.isBullish = isBullish;
   fvg.filled = false;
   
   int size = ArraySize(g_fvgs);
   ArrayResize(g_fvgs, size + 1);
   g_fvgs[size] = fvg;
   
   // Draw two stacked rectangles
   double midPoint = (fvgTop + fvgBottom) / 2.0;
   string prefix = g_prefix + "FVG_" + (isBullish ? "BULL_" : "BEAR_") + IntegerToString(tB);
   color fvgColor = isBullish ? InpFVG_BullColor : InpFVG_BearColor;
   datetime endTime = tC + InpFVG_ExtendBars * PeriodSeconds(PERIOD_CURRENT);
   
   // Upper half
   string upperName = prefix + "_UPPER";
   ObjectDelete(g_chartId, upperName);
   ObjectCreate(g_chartId, upperName, OBJ_RECTANGLE, 0, tB, fvgTop, endTime, midPoint);
   ObjectSetInteger(g_chartId, upperName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(g_chartId, upperName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, upperName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, upperName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, upperName, OBJPROP_SELECTABLE, false);
   
   // Lower half
   string lowerName = prefix + "_LOWER";
   ObjectDelete(g_chartId, lowerName);
   ObjectCreate(g_chartId, lowerName, OBJ_RECTANGLE, 0, tB, midPoint, endTime, fvgBottom);
   ObjectSetInteger(g_chartId, lowerName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(g_chartId, lowerName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, lowerName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, lowerName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, lowerName, OBJPROP_SELECTABLE, false);
   
   // Buffer
   int bufferBar = iBarShift(_Symbol, PERIOD_CURRENT, tB);
   if(bufferBar >= 0)
   {
      if(isBullish) g_bufFVGBull[bufferBar] = fvgBottom;
      else g_bufFVGBear[bufferBar] = fvgTop;
   }
   
   Print("SMC: FVG " + (isBullish?"BULL":"BEAR") + " " + DoubleToString(fvgBottom, _Digits) + "->" + DoubleToString(fvgTop, _Digits));
}

void CheckFVG(int rates_total, const datetime &time[],
              const double &open[], const double &high[], const double &low[], const double &close[])
{
   if(!InpShowFVG || rates_total < 4) return;
   
   ENUM_TIMEFRAMES fvgTF = (InpFVG_TF == PERIOD_CURRENT) ? Period() : InpFVG_TF;
   
   // Only run once per FVG TF bar
   static datetime lastFVGCheckTime = 0;
   datetime currentFVGTime = iTime(_Symbol, fvgTF, 0);
   if(currentFVGTime == lastFVGCheckTime && rates_total > 100) return;
   lastFVGCheckTime = currentFVGTime;
   
   // Scan FVG TF bars
   int fvgBars = iBars(_Symbol, fvgTF);
   if(fvgBars < 4) return;
   
   for(int shiftC = 2; shiftC < MathMin(fvgBars, 100); shiftC++)
   {
      int shiftB = shiftC + 1;
      int shiftA = shiftC + 2;
      
      double aHigh  = iHigh(_Symbol, fvgTF, shiftA);
      double aLow   = iLow(_Symbol, fvgTF, shiftA);
      double aClose = iClose(_Symbol, fvgTF, shiftA);
      datetime tA   = iTime(_Symbol, fvgTF, shiftA);
      
      double bOpen  = iOpen(_Symbol, fvgTF, shiftB);
      double bHigh  = iHigh(_Symbol, fvgTF, shiftB);
      double bLow   = iLow(_Symbol, fvgTF, shiftB);
      double bClose = iClose(_Symbol, fvgTF, shiftB);
      datetime tB   = iTime(_Symbol, fvgTF, shiftB);
      
      double cOpen  = iOpen(_Symbol, fvgTF, shiftC);
      double cHigh  = iHigh(_Symbol, fvgTF, shiftC);
      double cLow   = iLow(_Symbol, fvgTF, shiftC);
      double cClose = iClose(_Symbol, fvgTF, shiftC);
      datetime tC   = iTime(_Symbol, fvgTF, shiftC);
      
      // Bullish FVG
      if(cLow > aHigh && bClose > aHigh)
      {
         double pctMove = (bOpen > 0) ? (bClose - bOpen) / bOpen * 100.0 : 0;
         bool passThreshold = true;
         
         if(InpFVG_AutoThreshold)
         {
            g_fvgSumPct += MathAbs(pctMove);
            g_fvgCountPct++;
            double avgPct = (g_fvgCountPct > 0) ? g_fvgSumPct / g_fvgCountPct : 0;
            passThreshold = (avgPct > 0 && MathAbs(pctMove) > 2.0 * avgPct);
         }
         
         if(passThreshold)
            AddFVG(tA, tB, tC, aHigh, cLow, aLow, true);
      }
      
      // Bearish FVG
      if(cHigh < aLow && bClose < aLow)
      {
         double pctMove = (bOpen > 0) ? (bClose - bOpen) / bOpen * 100.0 : 0;
         bool passThreshold = true;
         
         if(InpFVG_AutoThreshold)
         {
            double avgPct = (g_fvgCountPct > 0) ? g_fvgSumPct / g_fvgCountPct : 0;
            passThreshold = (avgPct > 0 && MathAbs(pctMove) > 2.0 * avgPct);
         }
         
         if(passThreshold)
            AddFVG(tA, tB, tC, cHigh, aLow, aLow, false);
      }
   }
   
   // Check fill & right edge
   double currentLow = iLow(_Symbol, PERIOD_CURRENT, 0);
   double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
   
   for(int i = 0; i < ArraySize(g_fvgs); i++)
   {
      if(g_fvgs[i].filled) continue;
      
      string prefix = g_prefix + "FVG_" + (g_fvgs[i].isBullish ? "BULL_" : "BEAR_") + IntegerToString(g_fvgs[i].barBTime);
      datetime endTime = g_fvgs[i].barCTime + InpFVG_ExtendBars * PeriodSeconds(PERIOD_CURRENT);
      
      bool filled = false;
      if(g_fvgs[i].isBullish && currentLow < g_fvgs[i].fvgBottom)
         filled = true;
      if(!g_fvgs[i].isBullish && currentHigh > g_fvgs[i].fvgTop)
         filled = true;
      
      if(filled)
      {
         g_fvgs[i].filled = true;
         ObjectDelete(g_chartId, prefix + "_UPPER");
         ObjectDelete(g_chartId, prefix + "_LOWER");
         Print("SMC: FVG FILLED " + (g_fvgs[i].isBullish?"BULL":"BEAR"));
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 6: PREMIUM / DISCOUNT / EQUILIBRIUM ZONES                |
//|                                                                |
//+------------------------------------------------------------------+
void DrawPDZones(datetime currentTime, int currentBar)
{
   if(!InpShowPDZones) return;
   
   double top = g_swingTracker.trailingTop;
   double bottom = g_swingTracker.trailingBottom;
   
   if(top <= bottom || top <= 0 || bottom >= 1e9) return;
   
   datetime startTime = MathMin(g_swingTracker.trailingTopTime, g_swingTracker.trailingBottomTime);
   if(startTime == 0) startTime = currentTime - 100 * PeriodSeconds(PERIOD_CURRENT);
   
   double range = top - bottom;
   double premiumLevel = top - range * 0.05;
   double discountLevel = bottom + range * 0.05;
   double equilibrium = (top + bottom) / 2.0;
   double eqBand = range * 0.05;
   
   // --- Premium ---
   string premName = g_prefix + "PD_PREMIUM";
   ObjectDelete(g_chartId, premName);
   ObjectCreate(g_chartId, premName, OBJ_RECTANGLE, 0, startTime, top, currentTime, premiumLevel);
   ObjectSetInteger(g_chartId, premName, OBJPROP_COLOR, InpPremiumColor);
   ObjectSetInteger(g_chartId, premName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, premName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, premName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, premName, OBJPROP_SELECTABLE, false);
   
   string premLbl = g_prefix + "PD_PREMIUM_LBL";
   ObjectDelete(g_chartId, premLbl);
   ObjectCreate(g_chartId, premLbl, OBJ_TEXT, 0, currentTime, premiumLevel);
   ObjectSetString(g_chartId, premLbl, OBJPROP_TEXT, "Premium");
   ObjectSetInteger(g_chartId, premLbl, OBJPROP_COLOR, InpPremiumColor);
   ObjectSetInteger(g_chartId, premLbl, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(g_chartId, premLbl, OBJPROP_ANCHOR, ANCHOR_TOP);
   ObjectSetInteger(g_chartId, premLbl, OBJPROP_SELECTABLE, false);
   
   // --- Discount ---
   string discName = g_prefix + "PD_DISCOUNT";
   ObjectDelete(g_chartId, discName);
   ObjectCreate(g_chartId, discName, OBJ_RECTANGLE, 0, startTime, discountLevel, currentTime, bottom);
   ObjectSetInteger(g_chartId, discName, OBJPROP_COLOR, InpDiscountColor);
   ObjectSetInteger(g_chartId, discName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, discName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, discName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, discName, OBJPROP_SELECTABLE, false);
   
   string discLbl = g_prefix + "PD_DISCOUNT_LBL";
   ObjectDelete(g_chartId, discLbl);
   ObjectCreate(g_chartId, discLbl, OBJ_TEXT, 0, currentTime, discountLevel);
   ObjectSetString(g_chartId, discLbl, OBJPROP_TEXT, "Discount");
   ObjectSetInteger(g_chartId, discLbl, OBJPROP_COLOR, InpDiscountColor);
   ObjectSetInteger(g_chartId, discLbl, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(g_chartId, discLbl, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId, discLbl, OBJPROP_SELECTABLE, false);
   
   // --- Equilibrium ---
   string eqName = g_prefix + "PD_EQUILIBRIUM";
   ObjectDelete(g_chartId, eqName);
   ObjectCreate(g_chartId, eqName, OBJ_RECTANGLE, 0, startTime, equilibrium + eqBand, currentTime, equilibrium - eqBand);
   ObjectSetInteger(g_chartId, eqName, OBJPROP_COLOR, InpEquilibriumColor);
   ObjectSetInteger(g_chartId, eqName, OBJPROP_FILL, true);
   ObjectSetInteger(g_chartId, eqName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, eqName, OBJPROP_BACK, true);
   ObjectSetInteger(g_chartId, eqName, OBJPROP_SELECTABLE, false);
   
   string eqLbl = g_prefix + "PD_EQ_LBL";
   ObjectDelete(g_chartId, eqLbl);
   ObjectCreate(g_chartId, eqLbl, OBJ_TEXT, 0, currentTime, equilibrium);
   ObjectSetString(g_chartId, eqLbl, OBJPROP_TEXT, "EQ");
   ObjectSetInteger(g_chartId, eqLbl, OBJPROP_COLOR, InpEquilibriumColor);
   ObjectSetInteger(g_chartId, eqLbl, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(g_chartId, eqLbl, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSetInteger(g_chartId, eqLbl, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 7: STRONG/WEAK HIGH-LOW + SWING POINT LABELS             |
//|                                                                |
//+------------------------------------------------------------------+
void UpdateTrailingExtremes(const double &high[], const double &low[], int bar)
{
   if(high[bar] > g_trailTop || g_trailTop == 0)
   {
      g_trailTop = high[bar];
      g_trailTopTime = iTime(_Symbol, PERIOD_CURRENT, bar);
   }
   if(low[bar] < g_trailBottom || g_trailBottom == 0)
   {
      g_trailBottom = low[bar];
      g_trailBottomTime = iTime(_Symbol, PERIOD_CURRENT, bar);
   }
   
   if(high[bar] > g_swingTracker.trailingTop || g_swingTracker.trailingTop == 0)
   {
      g_swingTracker.trailingTop = high[bar];
      g_swingTracker.trailingTopTime = iTime(_Symbol, PERIOD_CURRENT, bar);
   }
   if(low[bar] < g_swingTracker.trailingBottom || g_swingTracker.trailingBottom == 1e10)
   {
      g_swingTracker.trailingBottom = low[bar];
      g_swingTracker.trailingBottomTime = iTime(_Symbol, PERIOD_CURRENT, bar);
   }
}

void DrawStrongWeakHL(datetime currentTime, int currentBar)
{
   if(!InpShowStrongWeakHL) return;
   
   double top = g_swingTracker.trailingTop;
   double bottom = g_swingTracker.trailingBottom;
   datetime topTime = g_swingTracker.trailingTopTime;
   datetime bottomTime = g_swingTracker.trailingBottomTime;
   
   if(top <= 0 || bottom >= 1e9 || topTime == 0 || bottomTime == 0) return;
   
   ENUM_TREND_BIAS bias = g_swingTracker.trendBias;
   
   // --- Top line ---
   string topLineName = g_prefix + "SW_TOP_LINE";
   string topLblName = g_prefix + "SW_TOP_LBL";
   string topLabelText = (bias == BIAS_BEARISH) ? "Strong High" : "Weak High";
   color topColor = (bias == BIAS_BEARISH) ? clrRed : clrOrange;
   
   ObjectDelete(g_chartId, topLineName);
   ObjectDelete(g_chartId, topLblName);
   
   ObjectCreate(g_chartId, topLineName, OBJ_TREND, 0, topTime, top, currentTime, top);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_COLOR, topColor);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(g_chartId, topLineName, OBJPROP_SELECTABLE, false);
   
   ObjectCreate(g_chartId, topLblName, OBJ_TEXT, 0, currentTime, top);
   ObjectSetString(g_chartId, topLblName, OBJPROP_TEXT, topLabelText);
   ObjectSetInteger(g_chartId, topLblName, OBJPROP_COLOR, topColor);
   ObjectSetInteger(g_chartId, topLblName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(g_chartId, topLblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, topLblName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId, topLblName, OBJPROP_SELECTABLE, false);
   
   // --- Bottom line ---
   string botLineName = g_prefix + "SW_BOT_LINE";
   string botLblName = g_prefix + "SW_BOT_LBL";
   string botLabelText = (bias == BIAS_BULLISH) ? "Strong Low" : "Weak Low";
   color botColor = (bias == BIAS_BULLISH) ? clrLimeGreen : clrGold;
   
   ObjectDelete(g_chartId, botLineName);
   ObjectDelete(g_chartId, botLblName);
   
   ObjectCreate(g_chartId, botLineName, OBJ_TREND, 0, bottomTime, bottom, currentTime, bottom);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_COLOR, botColor);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(g_chartId, botLineName, OBJPROP_SELECTABLE, false);
   
   ObjectCreate(g_chartId, botLblName, OBJ_TEXT, 0, currentTime, bottom);
   ObjectSetString(g_chartId, botLblName, OBJPROP_TEXT, botLabelText);
   ObjectSetInteger(g_chartId, botLblName, OBJPROP_COLOR, botColor);
   ObjectSetInteger(g_chartId, botLblName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(g_chartId, botLblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, botLblName, OBJPROP_ANCHOR, ANCHOR_TOP);
   ObjectSetInteger(g_chartId, botLblName, OBJPROP_SELECTABLE, false);
}

void DrawSwingPointLabels(int rates_total, const datetime &time[],
                          const double &high[], const double &low[])
{
   if(!InpShowSwingPointLabels) return;
   
   int L = InpSwingLength;
   if(rates_total <= L + 2) return;
   
   int barL = L;
   
   // Pivot high
   bool isHigh = true;
   for(int i = 0; i < L; i++)
      if(high[barL] <= high[i]) { isHigh = false; break; }
   
   if(isHigh && g_hasPrevSwingHigh)
   {
      string label = (high[barL] > g_lastSwingHighPrice) ? "HH" : "LH";
      color c = (high[barL] > g_lastSwingHighPrice) ? clrOrange : clrRed;
      
      string objName = g_prefix + "SPH_" + IntegerToString(time[barL]);
      ObjectDelete(g_chartId, objName);
      ObjectCreate(g_chartId, objName, OBJ_TEXT, 0, time[barL], high[barL]);
      ObjectSetString(g_chartId, objName, OBJPROP_TEXT, label);
      ObjectSetInteger(g_chartId, objName, OBJPROP_COLOR, c);
      ObjectSetInteger(g_chartId, objName, OBJPROP_FONTSIZE, 7);
      ObjectSetString(g_chartId, objName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(g_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      ObjectSetInteger(g_chartId, objName, OBJPROP_SELECTABLE, false);
      
      g_lastSwingHighPrice = high[barL];
   }
   g_hasPrevSwingHigh = isHigh || g_hasPrevSwingHigh;
   
   // Pivot low
   bool isLow = true;
   for(int i = 0; i < L; i++)
      if(low[barL] >= low[i]) { isLow = false; break; }
   
   if(isLow && g_hasPrevSwingLow)
   {
      string label = (low[barL] > g_lastSwingLowPrice) ? "HL" : "LL";
      color c = (low[barL] > g_lastSwingLowPrice) ? clrLimeGreen : clrRed;
      
      string objName = g_prefix + "SPL_" + IntegerToString(time[barL]);
      ObjectDelete(g_chartId, objName);
      ObjectCreate(g_chartId, objName, OBJ_TEXT, 0, time[barL], low[barL]);
      ObjectSetString(g_chartId, objName, OBJPROP_TEXT, label);
      ObjectSetInteger(g_chartId, objName, OBJPROP_COLOR, c);
      ObjectSetInteger(g_chartId, objName, OBJPROP_FONTSIZE, 7);
      ObjectSetString(g_chartId, objName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(g_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      ObjectSetInteger(g_chartId, objName, OBJPROP_SELECTABLE, false);
      
      g_lastSwingLowPrice = low[barL];
   }
   g_hasPrevSwingLow = isLow || g_hasPrevSwingLow;
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 8: MTF LEVELS — Daily / Weekly / Monthly                 |
//|                                                                |
//+------------------------------------------------------------------+
void DrawMTFLevel(ENUM_TIMEFRAMES tf, color lineColor, ENUM_LINE_STYLE style,
                  string highLabel, string lowLabel, datetime currentTime)
{
   double prevHigh = iHigh(_Symbol, tf, 1);
   double prevLow = iLow(_Symbol, tf, 1);
   
   if(prevHigh == 0 || prevLow == 0) return;
   
   datetime periodStartTime = iTime(_Symbol, tf, 1);
   if(periodStartTime == 0) return;
   
   // High line
   string highLineName = g_prefix + "MTF_" + highLabel;
   ObjectDelete(g_chartId, highLineName);
   ObjectCreate(g_chartId, highLineName, OBJ_TREND, 0,
                periodStartTime, prevHigh,
                currentTime + 20 * PeriodSeconds(PERIOD_CURRENT), prevHigh);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_STYLE, style);
   ObjectSetInteger(g_chartId, highLineName, OBJPROP_SELECTABLE, false);
   
   // High label
   string highLblName = g_prefix + "MTF_" + highLabel + "_LBL";
   ObjectDelete(g_chartId, highLblName);
   ObjectCreate(g_chartId, highLblName, OBJ_TEXT, 0, currentTime, prevHigh);
   ObjectSetString(g_chartId, highLblName, OBJPROP_TEXT, highLabel);
   ObjectSetInteger(g_chartId, highLblName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, highLblName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(g_chartId, highLblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, highLblName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId, highLblName, OBJPROP_SELECTABLE, false);
   
   // Low line
   string lowLineName = g_prefix + "MTF_" + lowLabel;
   ObjectDelete(g_chartId, lowLineName);
   ObjectCreate(g_chartId, lowLineName, OBJ_TREND, 0,
                periodStartTime, prevLow,
                currentTime + 20 * PeriodSeconds(PERIOD_CURRENT), prevLow);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_STYLE, style);
   ObjectSetInteger(g_chartId, lowLineName, OBJPROP_SELECTABLE, false);
   
   // Low label
   string lowLblName = g_prefix + "MTF_" + lowLabel + "_LBL";
   ObjectDelete(g_chartId, lowLblName);
   ObjectCreate(g_chartId, lowLblName, OBJ_TEXT, 0, currentTime, prevLow);
   ObjectSetString(g_chartId, lowLblName, OBJPROP_TEXT, lowLabel);
   ObjectSetInteger(g_chartId, lowLblName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(g_chartId, lowLblName, OBJPROP_FONTSIZE, 7);
   ObjectSetString(g_chartId, lowLblName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(g_chartId, lowLblName, OBJPROP_ANCHOR, ANCHOR_TOP);
   ObjectSetInteger(g_chartId, lowLblName, OBJPROP_SELECTABLE, false);
}

void DrawMTFLevels(datetime currentTime)
{
   ENUM_TIMEFRAMES currentTF = Period();
   
   if(InpShowDaily && currentTF < PERIOD_D1)
      DrawMTFLevel(PERIOD_D1, InpDailyColor, InpDailyStyle, "PDH", "PDL", currentTime);
   
   if(InpShowWeekly && currentTF < PERIOD_W1)
      DrawMTFLevel(PERIOD_W1, InpWeeklyColor, InpWeeklyStyle, "PWH", "PWL", currentTime);
   
   if(InpShowMonthly && currentTF < PERIOD_MN1)
      DrawMTFLevel(PERIOD_MN1, InpMonthlyColor, InpMonthlyStyle, "PMH", "PML", currentTime);
}

//+------------------------------------------------------------------+
//|                                                                |
//| STAGE 9: CLEANUP                                                |
//|                                                                |
//+------------------------------------------------------------------+
void CleanupOldObjects(PivotTracker &t, int L)
{
   if(InpMode != MODE_PRESENT) return;
   // Handled by segment drawing overwriting same-name objects
}

//+------------------------------------------------------------------+
//|                                                                |
//| OnCalculate                                                     |
//|                                                                |
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
   datetime currentBarTime = time[0];
   bool isNewBar = (currentBarTime != g_lastBarTime);
   
   // Tick update for right edges only
   if(!isNewBar && prev_calculated > 0)
   {
      if(InpShowPDZones) DrawPDZones(time[0], 0);
      if(InpShowStrongWeakHL) DrawStrongWeakHL(time[0], 0);
      if(InpShowSwingOBs || InpShowIntOBs) UpdateOBs(high, low, close, 0);
      if(InpShowDaily || InpShowWeekly || InpShowMonthly) DrawMTFLevels(time[0]);
      return rates_total;
   }
   
   g_lastBarTime = currentBarTime;
   
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   // --- Continuous trailing extreme update ---
   UpdateTrailingExtremes(high, low, 0);
   
   // --- STAGE 1: Pivot Detection ---
   DetectPivot(g_swingTracker, InpSwingLength, rates_total, time, high, low);
   DetectPivot(g_intTracker, InpIntLength, rates_total, time, high, low);
   
   // --- STAGE 2: BOS/CHoCH ---
   CheckBreak(g_swingTracker, InpSwingLength, rates_total, 0, time, high, low, close);
   CheckBreak(g_intTracker, InpIntLength, rates_total, 0, time, high, low, close);
   
   // --- STAGE 3: OB Updates ---
   if(InpShowSwingOBs || InpShowIntOBs)
      UpdateOBs(high, low, close, 0);
   
   // --- STAGE 4: Equal Highs/Lows ---
   CheckEqualHighsLows(rates_total, time, high, low);
   
   // --- STAGE 5: FVGs ---
   CheckFVG(rates_total, time, open, high, low, close);
   
   // --- STAGE 6: PD Zones ---
   if(InpShowPDZones)
      DrawPDZones(time[0], 0);
   
   // --- STAGE 7: Strong/Weak HL + Labels ---
   if(InpShowStrongWeakHL)
      DrawStrongWeakHL(time[0], 0);
   DrawSwingPointLabels(rates_total, time, high, low);
   
   // --- STAGE 8: MTF Levels ---
   if(InpShowDaily || InpShowWeekly || InpShowMonthly)
      DrawMTFLevels(time[0]);
   
   // --- STAGE 9: Cleanup ---
   if(InpMode == MODE_PRESENT)
   {
      CleanupOldObjects(g_swingTracker, InpSwingLength);
      CleanupOldObjects(g_intTracker, InpIntLength);
   }
   
   return rates_total;
}
//+------------------------------------------------------------------+
