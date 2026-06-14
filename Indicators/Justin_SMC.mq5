//+------------------------------------------------------------------+
//|                                          Justin_SMC.mq5           |
//|  Smart Money Concepts — Justin's SMC Indicator                   |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"
#property description "Justin SMC: BOS/CHoCH, Order Blocks, FVG, EQH/EQL, PD Array, MTF Levels"
#property indicator_chart_window
#property indicator_buffers 14
#property indicator_plots   14

//--- Buffer enums
enum BUF_IX
{
   BUF_INT_BULL_BOS   = 0,
   BUF_INT_BEAR_BOS   = 1,
   BUF_INT_BULL_CHOCH = 2,
   BUF_INT_BEAR_CHOCH = 3,
   BUF_SWING_BULL_BOS   = 4,
   BUF_SWING_BEAR_BOS   = 5,
   BUF_SWING_BULL_CHOCH = 6,
   BUF_SWING_BEAR_CHOCH = 7,
   BUF_OB_BULL_MIT  = 8,
   BUF_OB_BEAR_MIT  = 9,
   BUF_EQH = 10,
   BUF_EQL = 11,
   BUF_FVG_BULL = 12,
   BUF_FVG_BEAR = 13
};

//--- Plot definitions
#property indicator_label1  "Int Bull BOS"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrDodgerBlue
#property indicator_width1  1
#property indicator_label2  "Int Bear BOS"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrCrimson
#property indicator_width2  1
#property indicator_label3  "Int Bull CHoCH"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLimeGreen
#property indicator_width3  1
#property indicator_label4  "Int Bear CHoCH"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrDarkOrange
#property indicator_width4  1
#property indicator_label5  "Swing Bull BOS"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrBlue
#property indicator_width5  1
#property indicator_label6  "Swing Bear BOS"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_width6  1
#property indicator_label7  "Swing Bull CHoCH"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrMediumSeaGreen
#property indicator_width7  1
#property indicator_label8  "Swing Bear CHoCH"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrTomato
#property indicator_width8  1
#property indicator_label9  "Bull OB Mit"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrGold
#property indicator_width9  1
#property indicator_label10 "Bear OB Mit"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrMagenta
#property indicator_width10 1
#property indicator_label11 "EQH"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrCyan
#property indicator_width11 1
#property indicator_label12 "EQL"
#property indicator_type12  DRAW_ARROW
#property indicator_color12 clrOrange
#property indicator_width12 1
#property indicator_label13 "Bull FVG"
#property indicator_type13  DRAW_ARROW
#property indicator_color13 clrMediumSpringGreen
#property indicator_width13 1
#property indicator_label14 "Bear FVG"
#property indicator_type14  DRAW_ARROW
#property indicator_color14 clrDeepPink
#property indicator_width14 1

//+------------------------------------------------------------------+
//| CONSTANTS                                                        |
//+------------------------------------------------------------------+
#define BULLISH_LEG  1
#define BEARISH_LEG  0
#define BULLISH      1
#define BEARISH     -1

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_MODE
{
   MODE_HISTORICAL = 0,
   MODE_PRESENT    = 1
};

enum ENUM_STYLE_THEME
{
   STYLE_COLORED    = 0,
   STYLE_MONOCHROME = 1
};

enum ENUM_DISPLAY_FILTER
{
   FILTER_ALL   = 0,
   FILTER_BOS   = 1,
   FILTER_CHOCH = 2
};

enum ENUM_LABEL_SZ
{
   LSIZE_TINY   = 0,
   LSIZE_SMALL  = 1,
   LSIZE_NORMAL = 2
};

enum ENUM_OB_FILTER
{
   OB_ATR   = 0,
   OB_RANGE = 1
};

enum ENUM_MITIGATION
{
   MIT_CLOSE   = 0,
   MIT_HIGHLOW = 1
};

//+------------------------------------------------------------------+
//| STRUCTS — mirrors LuxAlgo Pine types                             |
//+------------------------------------------------------------------+
struct Pivot
{
   double   currentLevel;
   double   lastLevel;
   bool     crossed;
   datetime barTime;
   int      barIndex;
};

struct Trend
{
   int bias;  // BULLISH or BEARISH
};

struct OrderBlock
{
   double   barHigh;
   double   barLow;
   datetime barTime;
   int      bias;   // BULLISH or BEARISH
};

struct FVG
{
   double   top;
   double   bottom;
   int      bias;
   string   topBoxName;
   string   bottomBoxName;
};

struct TrailingExtremes
{
   double   top;
   double   bottom;
   datetime barTime;
   int      barIndex;
   datetime lastTopTime;
   datetime lastBottomTime;
};

struct EqualDisplay
{
   long   lineId;
   long   labelId;
};

//+------------------------------------------------------------------+
//| INPUTS — mirrored from LuxAlgo                                   |
//+------------------------------------------------------------------+
input ENUM_MODE           InpMode                         = MODE_HISTORICAL;     // Mode
input ENUM_STYLE_THEME    InpStyle                        = STYLE_COLORED;        // Style
input bool                InpShowTrend                    = false;                // Color Candles

input bool                InpShowInternals                = true;                 // Show Internal Structure
input ENUM_DISPLAY_FILTER InpIntBullFilter                = FILTER_ALL;           // Int Bullish
input color               InpIntBullColor                 = clrDodgerBlue;        //
input ENUM_DISPLAY_FILTER InpIntBearFilter                = FILTER_ALL;           // Int Bearish
input color               InpIntBearColor                 = clrCrimson;           //
input bool                InpIntConfluence                = false;                // Confluence Filter
input ENUM_LABEL_SZ       InpIntLabelSize                 = LSIZE_TINY;           // Int Label Size

input bool                InpShowSwing                    = true;                 // Show Swing Structure
input ENUM_DISPLAY_FILTER InpSwingBullFilter              = FILTER_ALL;           // Swing Bullish
input color               InpSwingBullColor               = clrBlue;              //
input ENUM_DISPLAY_FILTER InpSwingBearFilter              = FILTER_ALL;           // Swing Bearish
input color               InpSwingBearColor               = clrRed;               //
input ENUM_LABEL_SZ       InpSwingLabelSize               = LSIZE_SMALL;          // Swing Label Size
input bool                InpShowSwings                   = false;                // Show Swing Points
input int                 InpSwingLength                  = 50;                   // Swing Length (min 10)
input bool                InpShowHighLowSwings            = true;                 // Show Strong/Weak HL

input bool                InpShowIntOBs                   = true;                 // Internal Order Blocks
input int                 InpIntOBMax                     = 5;                    // Max Int OB
input bool                InpShowSwingOBs                 = false;                // Swing Order Blocks
input int                 InpSwingOBMax                   = 5;                    // Max Swing OB
input ENUM_OB_FILTER      InpOBFilter                     = OB_ATR;               // OB Filter Method
input ENUM_MITIGATION     InpOBMitigation                 = MIT_HIGHLOW;          // OB Mitigation
input color               InpIntOBBullColor               = clrDodgerBlue;        // Int Bull OB
input color               InpIntOBBearColor               = clrCrimson;           // Int Bear OB
input color               InpSwingOBBullColor             = clrBlue;              // Swing Bull OB
input color               InpSwingOBBearColor             = clrRed;               // Swing Bear OB

input bool                InpShowEQHEQL                   = true;                 // Equal High/Low
input int                 InpEqLen                        = 3;                    // Bars Confirmation
input double              InpEqThreshold                  = 0.1;                  // Threshold (0-0.5)
input ENUM_LABEL_SZ       InpEqLabelSize                  = LSIZE_TINY;           // Label Size

input bool                InpShowFVG                      = false;                // Fair Value Gaps
input bool                InpFVG_AutoThreshold            = true;                 // Auto Threshold
input ENUM_TIMEFRAMES     InpFVG_TF                       = PERIOD_CURRENT;       // FVG Timeframe
input color               InpFVGBullColor                 = clrMediumSpringGreen; // Bullish FVG
input color               InpFVGBearColor                 = clrDeepPink;          // Bearish FVG
input int                 InpFVG_Extend                   = 1;                    // Extend FVG

input bool                InpShowDaily                    = false;                // Daily
input ENUM_LINE_STYLE     InpDailyStyle                   = STYLE_SOLID;          //
input color               InpDailyColor                   = clrGray;              //
input bool                InpShowWeekly                   = false;                // Weekly
input ENUM_LINE_STYLE     InpWeeklyStyle                  = STYLE_DASH;           //
input color               InpWeeklyColor                  = clrDarkGray;          //
input bool                InpShowMonthly                  = false;                // Monthly
input ENUM_LINE_STYLE     InpMonthlyStyle                 = STYLE_DOT;            //
input color               InpMonthlyColor                 = clrDimGray;           //

input bool                InpShowPDZones                  = false;                // Premium/Discount Zones
input color               InpPremiumColor                 = clrRed;               // Premium
input color               InpEqColor                      = clrGray;              // Equilibrium
input color               InpDiscountColor                = clrGreen;             // Discount

//+------------------------------------------------------------------+
//| GLOBALS — mirrors Pine var declarations                           |
//+------------------------------------------------------------------+
long     g_chartId;
string   g_pref = "SMC_";
int      g_atrHandle = INVALID_HANDLE;

// Pivots
Pivot    g_swingHigh, g_swingLow;
Pivot    g_intHigh, g_intLow;
Pivot    g_eqHigh, g_eqLow;

// Trends
Trend    g_swingTrend, g_intTrend;

// Equal displays
EqualDisplay g_eqHighDisp, g_eqLowDisp;

// Storage arrays (mirror Pine var arrays)
double   g_parsedHighs[];
double   g_parsedLows[];
double   g_highs[];
double   g_lows[];
datetime g_times[];

// Order blocks
OrderBlock g_swingOBs[];
OrderBlock g_intOBs[];

// OB boxes — pre-allocated
long     g_swingOBBottoms[], g_swingOBTops[];
long     g_intOBBottoms[], g_intOBTops[];

// FVGs
FVG      g_fvgs[];

// Trailing extremes
TrailingExtremes g_trail;

// Alert struct
struct Alerts
{
   bool intBullBOS, intBearBOS, intBullCHoCH, intBearCHoCH;
   bool swingBullBOS, swingBearBOS, swingBullCHoCH, swingBearCHoCH;
   bool intBullOB, intBearOB, swingBullOB, swingBearOB;
   bool eqHighs, eqLows;
   bool bullFVG, bearFVG;
};
Alerts g_alerts;

// Bar tracking
int      g_lastBarIndex = -1;
datetime g_initTime = 0;

// FVG auto-threshold accumulators
double g_fvgSumPct = 0;
int    g_fvgCount = 0;

// Buffers
double g_bufIntBullBOS[], g_bufIntBearBOS[], g_bufIntBullCHoCH[], g_bufIntBearCHoCH[];
double g_bufSwingBullBOS[], g_bufSwingBearBOS[], g_bufSwingBullCHoCH[], g_bufSwingBearCHoCH[];
double g_bufOBBullMit[], g_bufOBBearMit[];
double g_bufEQH[], g_bufEQL[];
double g_bufFVGBull[], g_bufFVGBear[];

//+------------------------------------------------------------------+
//| HELPER: font size from enum                                      |
//+------------------------------------------------------------------+
int FontSz(ENUM_LABEL_SZ s)
{
   switch(s){case LSIZE_TINY:return 7;case LSIZE_SMALL:return 9;case LSIZE_NORMAL:return 12;}
   return 9;
}

//+------------------------------------------------------------------+
//| HELPER: ATR                                                      |
//+------------------------------------------------------------------+
double GetATR(int i)
{
   double a[];
   ArraySetAsSeries(a,true);
   if(g_atrHandle!=INVALID_HANDLE && CopyBuffer(g_atrHandle,0,i,1,a)>0) return a[0];
   double s=0;int c=0;
   for(int j=i;j<i+14&&j<10000;j++)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,j),l=iLow(_Symbol,PERIOD_CURRENT,j),pc=iClose(_Symbol,PERIOD_CURRENT,j+1);
      if(h>0&&l>0){s+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));c++;}
   }
   return c>0?s/c:0;
}

//+------------------------------------------------------------------+
//| HELPER: Cumulative true range / bar_index                        |
//+------------------------------------------------------------------+
double GetCMR()
{
   double s=0;
   int n=MathMin(1000,iBars(_Symbol,PERIOD_CURRENT)-1);
   if(n<=0)return 0;
   for(int i=0;i<n;i++)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,i),l=iLow(_Symbol,PERIOD_CURRENT,i),pc=iClose(_Symbol,PERIOD_CURRENT,i+1);
      s+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
   }
   return s/n;
}

//+------------------------------------------------------------------+
//| HELPER: parsed high/low (spike swap)                             |
//+------------------------------------------------------------------+
double ParsedHigh(int i)
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,i),l=iLow(_Symbol,PERIOD_CURRENT,i);
   double mv=InpOBFilter==OB_ATR?GetATR(i):GetCMR();
   if(mv>0&&(h-l)>=2*mv) return l;
   return h;
}
double ParsedLow(int i)
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,i),l=iLow(_Symbol,PERIOD_CURRENT,i);
   double mv=InpOBFilter==OB_ATR?GetATR(i):GetCMR();
   if(mv>0&&(h-l)>=2*mv) return h;
   return l;
}

//+------------------------------------------------------------------+
//| HELPER: style string -> long                                     |
//+------------------------------------------------------------------+
long StyleLong(ENUM_LINE_STYLE s)
{
   switch(s){case STYLE_SOLID:return STYLE_SOLID;case STYLE_DASH:return STYLE_DASH;default:return STYLE_DOT;}
}

//+------------------------------------------------------------------+
//| PIVOT: leg() function — exactly matches Pine                     |
//+------------------------------------------------------------------+
int Leg(int size, const double &high[], const double &low[], int rates_total)
{
   static int legVal=0;
   if(rates_total<=size+2) return legVal;
   bool newHigh=high[size]>ArrayMaximum(high,0,size);
   bool newLow =low[size]<ArrayMinimum(low,0,size);
   if(newHigh)      legVal=BEARISH_LEG;
   else if(newLow)  legVal=BULLISH_LEG;
   return legVal;
}

bool StartOfNewLeg(int leg) { static int lastLeg=0; bool chg=(leg!=lastLeg); lastLeg=leg; return chg; }
bool StartOfBearishLeg(int leg) { static int lastLegB=0; bool chg=(leg!=lastLegB && leg==BEARISH_LEG); lastLegB=leg; return chg; }
bool StartOfBullishLeg(int leg) { static int lastLegBu=0; bool chg=(leg!=lastLegBu && leg==BULLISH_LEG); lastLegBu=leg; return chg; }

//+------------------------------------------------------------------+
//| DRAW LABEL — exactly matches Pine drawLabel()                    |
//+------------------------------------------------------------------+
void DrawLabel(datetime t, double price, string tag, color c, int anchor)
{
   string n=g_pref+"LBL_"+tag+"_"+IntegerToString(t);
   if(InpMode==MODE_PRESENT) ObjectDelete(g_chartId,n);
   if(ObjectFind(g_chartId,n)<0) ObjectCreate(g_chartId,n,OBJ_TEXT,0,t,price);
   else ObjectMove(g_chartId,n,0,t,price);
   ObjectSetString(g_chartId,n,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,n,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,n,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,n,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,n,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(g_chartId,n,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| DRAW STRUCTURE — exactly matches Pine drawStructure()            |
//| LINE from pivot bar time -> current bar time at pivot price      |
//| LABEL at bar_index midpoint                                      |
//+------------------------------------------------------------------+
void DrawStructure(Pivot &p, string tag, color c, long lineStyle, int lblAnchor, ENUM_LABEL_SZ sz)
{
   string id=g_pref+"STRUCT_"+IntegerToString(p.barTime);
   string ln=id+"_L", lb=id+"_LB";
   
   if(InpMode==MODE_PRESENT){ObjectDelete(g_chartId,ln);ObjectDelete(g_chartId,lb);}
   
   // Line: pivot bar time -> current bar time, at pivot price (SEGMENT, not HLINE)
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
   if(ObjectFind(g_chartId,ln)<0) ObjectCreate(g_chartId,ln,OBJ_TREND,0,p.barTime,p.currentLevel,now,p.currentLevel);
   else {ObjectMove(g_chartId,ln,0,p.barTime,p.currentLevel);ObjectMove(g_chartId,ln,1,now,p.currentLevel);}
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,ln,OBJPROP_WIDTH,lineStyle==STYLE_SOLID?2:1);
   ObjectSetInteger(g_chartId,ln,OBJPROP_STYLE,lineStyle);
   ObjectSetInteger(g_chartId,ln,OBJPROP_SELECTABLE,false);
   
   // Label at bar_index midpoint (matching Pine: math.round(0.5*(p.barIndex + bar_index)))
   int midIdx=(p.barIndex+1)/2;  // bar_index is 0 at current, so we use (p.barIndex + currentBarIndex)/2
   datetime midTime=iTime(_Symbol,PERIOD_CURRENT,midIdx);
   
   if(ObjectFind(g_chartId,lb)<0) ObjectCreate(g_chartId,lb,OBJ_TEXT,0,midTime,p.currentLevel);
   else ObjectMove(g_chartId,lb,0,midTime,p.currentLevel);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,FontSz(sz));
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,lblAnchor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| DRAW EQH/EQL — matches Pine drawEqualHighLow()                   |
//+------------------------------------------------------------------+
void DrawEqualHighLow(Pivot &p, double level, int size, bool isHigh)
{
   EqualDisplay &d = isHigh ? g_eqHighDisp : g_eqLowDisp;
   string tag = isHigh ? "EQH" : "EQL";
   color c = isHigh ? InpSwingBearColor : InpSwingBullColor;
   int anc = isHigh ? ANCHOR_BOTTOM : ANCHOR_TOP;
   
   if(InpMode==MODE_PRESENT)
   {
      if(d.lineId>0 && ObjectFind(g_chartId,(string)d.lineId)>=0) ObjectDelete(g_chartId,(string)d.lineId);
      if(d.labelId>0 && ObjectFind(g_chartId,(string)d.labelId)>=0) ObjectDelete(g_chartId,(string)d.labelId);
   }
   
   string ln=g_pref+(isHigh?"EQH_":"EQL_")+"LINE";
   string lb=g_pref+(isHigh?"EQH_":"EQL_")+"LBL";
   
   datetime t2=iTime(_Symbol,PERIOD_CURRENT,size);
   if(ObjectFind(g_chartId,ln)<0) ObjectCreate(g_chartId,ln,OBJ_TREND,0,p.barTime,p.currentLevel,t2,level);
   else {ObjectMove(g_chartId,ln,0,p.barTime,p.currentLevel);ObjectMove(g_chartId,ln,1,t2,level);}
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,ln,OBJPROP_WIDTH,1);
   ObjectSetInteger(g_chartId,ln,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(g_chartId,ln,OBJPROP_SELECTABLE,false);
   d.lineId=(long)ObjectFind(g_chartId,ln)>=0?StringToInteger(ln):0; // store reference
   
   int midIdx=(p.barIndex+size)/2;
   datetime midTime=iTime(_Symbol,PERIOD_CURRENT,midIdx);
   double midPrice=(p.currentLevel+level)/2;
   
   if(ObjectFind(g_chartId,lb)<0) ObjectCreate(g_chartId,lb,OBJ_TEXT,0,midTime,midPrice);
   else ObjectMove(g_chartId,lb,0,midTime,midPrice);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,FontSz(InpEqLabelSize));
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,anc);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| GET CURRENT STRUCTURE — matches Pine getCurrentStructure()       |
//| Processes pivot detection for a given size, optionally EQH or int|
//+------------------------------------------------------------------+
void GetCurrentStructure(int size, bool eqhl=false, bool internal=false,
                         const datetime &time[], const double &high[], const double &low[], int rates_total)
{
   int curLeg = Leg(size,high,low,rates_total);
   bool newPivot = StartOfNewLeg(curLeg);
   bool pivotLow  = StartOfBullishLeg(curLeg);
   bool pivotHigh = StartOfBearishLeg(curLeg);
   
   if(!newPivot) return;
   
   double atr=GetATR(size);
   
   if(pivotLow)
   {
      Pivot &p = eqhl ? g_eqLow : (internal ? g_intLow : g_swingLow);
      
      if(eqhl && p.currentLevel>0 && MathAbs(p.currentLevel-low[size])<InpEqThreshold*atr)
      {
         DrawEqualHighLow(p,low[size],size,false);
         g_alerts.eqLows=true;
         g_bufEQL[size]=low[size];
      }
      
      p.lastLevel=p.currentLevel;
      p.currentLevel=low[size];
      p.crossed=false;
      p.barTime=time[size];
      p.barIndex=size;
      
      if(!eqhl && !internal)
      {
         g_trail.bottom=p.currentLevel;
         g_trail.barTime=p.barTime;
         g_trail.barIndex=p.barIndex;
         g_trail.lastBottomTime=p.barTime;
      }
      
      if(InpShowSwings && !internal && !eqhl)
      {
         string lbl=(p.currentLevel < p.lastLevel)?"LL":"HL";
         color lc=(p.currentLevel < p.lastLevel)?clrRed:clrLimeGreen;
         DrawLabel(time[size],p.currentLevel,lbl,lc,ANCHOR_TOP);
      }
   }
   else // pivotHigh
   {
      Pivot &p = eqhl ? g_eqHigh : (internal ? g_intHigh : g_swingHigh);
      
      if(eqhl && p.currentLevel>0 && MathAbs(p.currentLevel-high[size])<InpEqThreshold*atr)
      {
         DrawEqualHighLow(p,high[size],size,true);
         g_alerts.eqHighs=true;
         g_bufEQH[size]=high[size];
      }
      
      p.lastLevel=p.currentLevel;
      p.currentLevel=high[size];
      p.crossed=false;
      p.barTime=time[size];
      p.barIndex=size;
      
      if(!eqhl && !internal)
      {
         g_trail.top=p.currentLevel;
         g_trail.barTime=p.barTime;
         g_trail.barIndex=p.barIndex;
         g_trail.lastTopTime=p.barTime;
      }
      
      if(InpShowSwings && !internal && !eqhl)
      {
         string lbl=(p.currentLevel > p.lastLevel)?"HH":"LH";
         color lc=(p.currentLevel > p.lastLevel)?clrOrange:clrRed;
         DrawLabel(time[size],p.currentLevel,lbl,lc,ANCHOR_BOTTOM);
      }
   }
}

//+------------------------------------------------------------------+
//| STORE ORDER BLOCK — matches Pine storeOrdeBlock()                |
//+------------------------------------------------------------------+
void StoreOrderBlock(Pivot &p, bool internal, int bias)
{
   bool show = internal ? InpShowIntOBs : InpShowSwingOBs;
   if(!show) return;
   
   int startBar=p.barIndex;
   int endBar=1; // current bar index (0=current, 1=last closed)
   if(startBar<=endBar) return;
   
   double searchVal=(bias==BEARISH)?-1e10:1e10;
   int impulseBar=startBar;
   
   for(int i=startBar;i>=endBar;i--)
   {
      double ph=ParsedHigh(i), pl=ParsedLow(i);
      double val=(bias==BEARISH)?ph:pl;
      if((bias==BEARISH && val>searchVal)||(bias==BULLISH && val<searchVal))
      {
         searchVal=val;
         impulseBar=i;
      }
   }
   
   OrderBlock ob;
   ob.barHigh=ParsedHigh(impulseBar);
   ob.barLow=ParsedLow(impulseBar);
   ob.barTime=iTime(_Symbol,PERIOD_CURRENT,impulseBar);
   ob.bias=bias;
   
   OrderBlock arr[];
   ArrayCopy(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   int max=internal?InpIntOBMax:InpSwingOBMax;
   
   if(sz>=max)
   {
      // Remove oldest
      for(int i=0;i<sz-1;i++) arr[i]=arr[i+1];
      ArrayResize(arr,max-1);
   }
   ArrayResize(arr,ArraySize(arr)+1);
   arr[ArraySize(arr)-1]=ob;
   
   if(internal) ArrayCopy(g_intOBs,arr);
   else ArrayCopy(g_swingOBs,arr);
}

//+------------------------------------------------------------------+
//| DELETE ORDER BLOCKS — matches Pine deleteOrderBlocks()           |
//+------------------------------------------------------------------+
void DeleteOrderBlocks(bool internal)
{
   OrderBlock arr[];
   ArrayCopy(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   if(sz==0) return;
   
   double bearSrc=(InpOBMitigation==MIT_CLOSE)?iClose(_Symbol,PERIOD_CURRENT,0):iHigh(_Symbol,PERIOD_CURRENT,0);
   double bullSrc=(InpOBMitigation==MIT_CLOSE)?iClose(_Symbol,PERIOD_CURRENT,0):iLow(_Symbol,PERIOD_CURRENT,0);
   
   OrderBlock newArr[];
   for(int i=0;i<sz;i++)
   {
      bool crossed=false;
      if(arr[i].bias==BEARISH && bearSrc>arr[i].barHigh) crossed=true;
      else if(arr[i].bias==BULLISH && bullSrc<arr[i].barLow) crossed=true;
      
      if(crossed)
      {
         if(internal)
         {
            if(arr[i].bias==BULLISH) g_alerts.intBullOB=true;
            else g_alerts.intBearOB=true;
            g_bufOBBullMit[0]=arr[i].barHigh;
         }
         else
         {
            if(arr[i].bias==BULLISH) g_alerts.swingBullOB=true;
            else g_alerts.swingBearOB=true;
            g_bufOBBearMit[0]=arr[i].barLow;
         }
         // Remove the box objects
         string boxN=g_pref+(internal?"IN_":"SW_")+"OB_"+IntegerToString(arr[i].barTime)+"_BOX";
         ObjectDelete(g_chartId,boxN);
      }
      else
      {
         int ns=ArraySize(newArr);
         ArrayResize(newArr,ns+1);
         newArr[ns]=arr[i];
      }
   }
   
   if(internal) ArrayCopy(g_intOBs,newArr);
   else ArrayCopy(g_swingOBs,newArr);
}

//+------------------------------------------------------------------+
//| DRAW ORDER BLOCKS — matches Pine drawOrderBlocks()               |
//+------------------------------------------------------------------+
void DrawOrderBlocks(bool internal)
{
   OrderBlock arr[];
   ArrayCopy(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   int max=internal?InpIntOBMax:InpSwingOBMax;
   int drawN=MathMin(sz,max);
   if(drawN<=0) return;
   
   for(int i=0;i<drawN;i++)
   {
      color boxC;
      if(InpStyle==STYLE_MONOCHROME)
         boxC=arr[i].bias==BEARISH?clrDimGray:clrLightGray;
      else if(internal)
         boxC=arr[i].bias==BEARISH?InpIntOBBearColor:InpIntOBBullColor;
      else
         boxC=arr[i].bias==BEARISH?InpSwingOBBearColor:InpSwingOBBullColor;
      
      string boxN=g_pref+(internal?"IN_":"SW_")+"OB_"+IntegerToString(arr[i].barTime)+"_BOX";
      datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
      
      if(ObjectFind(g_chartId,boxN)<0)
         ObjectCreate(g_chartId,boxN,OBJ_RECTANGLE,0,arr[i].barTime,arr[i].barHigh,now,arr[i].barLow);
      else
      {
         ObjectMove(g_chartId,boxN,0,arr[i].barTime,arr[i].barHigh);
         ObjectMove(g_chartId,boxN,1,now,arr[i].barLow);
      }
      ObjectSetInteger(g_chartId,boxN,OBJPROP_COLOR,boxC);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_FILL,true);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_WIDTH,1);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_BACK,true);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_STYLE,STYLE_SOLID);
   }
}

//+------------------------------------------------------------------+
//| DISPLAY STRUCTURE — matches Pine displayStructure()             |
//| Checks crossover/crossunder for BOS/CHoCH detection             |
//+------------------------------------------------------------------+
void DisplayStructure(bool internal, const datetime &time[],
                      const double &high[], const double &low[], const double &close[], int rates_total)
{
   // --- Bullish break: close crosses above pivot high ---
   Pivot &pHi = internal ? g_intHigh : g_swingHigh;
   Trend &t = internal ? g_intTrend : g_swingTrend;
   
   long lStyle = internal ? STYLE_DASH : STYLE_SOLID;
   ENUM_LABEL_SZ lsz = internal ? InpIntLabelSize : InpSwingLabelSize;
   
   // Confluence filter (Pine: high - max(close,open) > min(close,open) - low for bullish)
   bool bullishBar=true, bearishBar=true;
   if(InpIntConfluence && internal)
   {
      double c=close[0], o=iOpen(_Symbol,PERIOD_CURRENT,0), h=high[0], l=low[0];
      bullishBar = (h-MathMax(c,o)) > (MathMin(c,o)-l);
      bearishBar = (h-MathMax(c,o)) < (MathMin(c,o)-l);
   }
   
   // Extra condition for internal: internalHigh != swingHigh
   bool extraCondBull = internal ? (g_intHigh.currentLevel!=g_swingHigh.currentLevel && bullishBar) : true;
   bool extraCondBear = internal ? (g_intLow.currentLevel!=g_swingLow.currentLevel && bearishBar) : true;
   
   // --- Bullish BOS/CHoCH ---
   if(close[0]>pHi.currentLevel && pHi.currentLevel>0 && !pHi.crossed && extraCondBull)
   {
      bool isCHoCH=(t.bias==BEARISH);
      string tag=isCHoCH?"CHoCH":"BOS";
      
      if(internal)
      {
         if(isCHoCH) g_alerts.intBullCHoCH=true; else g_alerts.intBullBOS=true;
      }
      else
      {
         if(isCHoCH) g_alerts.swingBullCHoCH=true; else g_alerts.swingBullBOS=true;
      }
      
      pHi.crossed=true;
      t.bias=BULLISH;
      
      // Display filter
      bool show=false;
      if(internal)
      {
         ENUM_DISPLAY_FILTER f=InpIntBullFilter;
         show=InpShowInternals && (f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));
      }
      else
      {
         ENUM_DISPLAY_FILTER f=InpSwingBullFilter;
         show=InpShowSwing && (f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));
      }
      
      color c=InpStyle==STYLE_MONOCHROME?clrLightGray:(internal?InpIntBullColor:InpSwingBullColor);
      if(show) DrawStructure(pHi,tag,c,lStyle,ANCHOR_TOP,lsz);
      
      SetBufferBreak(internal,true,isCHoCH,pHi.currentLevel,0);
      
      // Store OB
      if((internal&&InpShowIntOBs)||(!internal&&InpShowSwingOBs))
         StoreOrderBlock(pHi,internal,BULLISH);
   }
   
   // --- Bearish BOS/CHoCH ---
   Pivot &pLo = internal ? g_intLow : g_swingLow;
   
   if(close[0]<pLo.currentLevel && pLo.currentLevel>0 && !pLo.crossed && extraCondBear)
   {
      bool isCHoCH=(t.bias==BULLISH);
      string tag=isCHoCH?"CHoCH":"BOS";
      
      if(internal)
      {
         if(isCHoCH) g_alerts.intBearCHoCH=true; else g_alerts.intBearBOS=true;
      }
      else
      {
         if(isCHoCH) g_alerts.swingBearCHoCH=true; else g_alerts.swingBearBOS=true;
      }
      
      pLo.crossed=true;
      t.bias=BEARISH;
      
      bool show=false;
      if(internal)
      {
         ENUM_DISPLAY_FILTER f=InpIntBearFilter;
         show=InpShowInternals && (f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));
      }
      else
      {
         ENUM_DISPLAY_FILTER f=InpSwingBearFilter;
         show=InpShowSwing && (f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));
      }
      
      color c=InpStyle==STYLE_MONOCHROME?clrDimGray:(internal?InpIntBearColor:InpSwingBearColor);
      if(show) DrawStructure(pLo,tag,c,lStyle,ANCHOR_BOTTOM,lsz);
      
      SetBufferBreak(internal,false,isCHoCH,pLo.currentLevel,0);
      
      if((internal&&InpShowIntOBs)||(!internal&&InpShowSwingOBs))
         StoreOrderBlock(pLo,internal,BEARISH);
   }
}

void SetBufferBreak(bool internal, bool bull, bool choch, double price, int bar)
{
   if(bull&&!choch)      {if(internal)g_bufIntBullBOS[bar]=price;else g_bufSwingBullBOS[bar]=price;}
   else if(bull&&choch)  {if(internal)g_bufIntBullCHoCH[bar]=price;else g_bufSwingBullCHoCH[bar]=price;}
   else if(!bull&&!choch){if(internal)g_bufIntBearBOS[bar]=price;else g_bufSwingBearBOS[bar]=price;}
   else                  {if(internal)g_bufIntBearCHoCH[bar]=price;else g_bufSwingBearCHoCH[bar]=price;}
}

//+------------------------------------------------------------------+
//| FVG — matches Pine drawFairValueGaps() + deleteFairValueGaps()  |
//+------------------------------------------------------------------+
void DeleteFairValueGaps()
{
   double currLow=iLow(_Symbol,PERIOD_CURRENT,0);
   double currHigh=iHigh(_Symbol,PERIOD_CURRENT,0);
   
   FVG newArr[];
   for(int i=0;i<ArraySize(g_fvgs);i++)
   {
      bool filled=false;
      if(g_fvgs[i].bias==BULLISH && currLow<g_fvgs[i].bottom) filled=true;
      if(g_fvgs[i].bias==BEARISH && currHigh>g_fvgs[i].top) filled=true;
      
      if(filled)
      {
         ObjectDelete(g_chartId,g_fvgs[i].topBoxName);
         ObjectDelete(g_chartId,g_fvgs[i].bottomBoxName);
      }
      else
      {
         int ns=ArraySize(newArr);
         ArrayResize(newArr,ns+1);
         newArr[ns]=g_fvgs[i];
      }
   }
   ArrayCopy(g_fvgs,newArr);
}

void DrawFairValueGaps()
{
   ENUM_TIMEFRAMES fvgTF=(InpFVG_TF==PERIOD_CURRENT)?Period():InpFVG_TF;
   
   int fvgBars=iBars(_Symbol,fvgTF);
   if(fvgBars<4) return;
   
   for(int shiftC=2;shiftC<MathMin(fvgBars,100);shiftC++)
   {
      int shiftB=shiftC+1;
      int shiftA=shiftC+2;
      
      double aHigh=iHigh(_Symbol,fvgTF,shiftA), aLow=iLow(_Symbol,fvgTF,shiftA);
      double bOpen=iOpen(_Symbol,fvgTF,shiftB), bClose=iClose(_Symbol,fvgTF,shiftB);
      double cLow=iLow(_Symbol,fvgTF,shiftC), cHigh=iHigh(_Symbol,fvgTF,shiftC);
      datetime tB=iTime(_Symbol,fvgTF,shiftB), tC=iTime(_Symbol,fvgTF,shiftC), tA=iTime(_Symbol,fvgTF,shiftA);
      
      double pctMove=(bOpen>0)?(bClose-bOpen)/bOpen*100.0:0;
      bool newTF=(shiftC==2); // newest FVG bar
      
      double threshold=0;
      if(InpFVG_AutoThreshold)
      {
         g_fvgSumPct+=MathAbs(pctMove);
         g_fvgCount++;
         double avg=(g_fvgCount>0)?g_fvgSumPct/g_fvgCount:0;
         if(avg>0) threshold=2*avg;
      }
      
      // Bullish FVG: cLow > aHigh && bClose > aHigh && pctMove > threshold && newTF
      if(cLow>aHigh && bClose>aHigh && MathAbs(pctMove)>threshold && newTF)
      {
         g_alerts.bullFVG=true;
         AddFVG(tA,tB,tC,cLow,aHigh,true);
      }
      
      // Bearish FVG: cHigh < aLow && bClose < aLow && pctMove > threshold && newTF
      if(cHigh<aLow && bClose<aLow && MathAbs(pctMove)>threshold && newTF)
      {
         g_alerts.bearFVG=true;
         AddFVG(tA,tB,tC,aLow,cHigh,false);
      }
   }
}

void AddFVG(datetime tA, datetime tB, datetime tC, double top, double bottom, bool bullish)
{
   // Dedup
   for(int i=0;i<ArraySize(g_fvgs);i++)
      if(g_fvgs[i].top==top && g_fvgs[i].bottom==bottom) return;
   
   FVG f;
   f.top=top; f.bottom=bottom; f.bias=bullish?BULLISH:BEARISH;
   
   double mid=(top+bottom)/2;
   datetime end=tC+InpFVG_Extend*PeriodSeconds(PERIOD_CURRENT);
   color col=bullish?InpFVGBullColor:InpFVGBearColor;
   
   string pref=g_pref+"FVG_"+IntegerToString(tB);
   f.topBoxName=pref+"_TOP";
   f.bottomBoxName=pref+"_BOT";
   
   // Upper box
   ObjectDelete(g_chartId,f.topBoxName);
   ObjectCreate(g_chartId,f.topBoxName,OBJ_RECTANGLE,0,tB,top,end,mid);
   ObjectSetInteger(g_chartId,f.topBoxName,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,f.topBoxName,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,f.topBoxName,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,f.topBoxName,OBJPROP_SELECTABLE,false);
   
   // Lower box
   ObjectDelete(g_chartId,f.bottomBoxName);
   ObjectCreate(g_chartId,f.bottomBoxName,OBJ_RECTANGLE,0,tB,mid,end,bottom);
   ObjectSetInteger(g_chartId,f.bottomBoxName,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,f.bottomBoxName,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,f.bottomBoxName,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,f.bottomBoxName,OBJPROP_SELECTABLE,false);
   
   int sz=ArraySize(g_fvgs);
   ArrayResize(g_fvgs,sz+1);
   g_fvgs[sz]=f;
   
   int bufBar=iBarShift(_Symbol,PERIOD_CURRENT,tB);
   if(bufBar>=0)
   {
      if(bullish) g_bufFVGBull[bufBar]=bottom;
      else g_bufFVGBear[bufBar]=top;
   }
}

//+------------------------------------------------------------------+
//| MTF LEVELS — matches Pine drawLevels()                           |
//+------------------------------------------------------------------+
void DrawLevels(ENUM_TIMEFRAMES tf, bool sameTF, ENUM_LINE_STYLE style, color col,
                string highLabel, string lowLabel, datetime currentTime)
{
   double tHigh=iHigh(_Symbol,tf,1), tLow=iLow(_Symbol,tf,1);
   if(tHigh==0||tLow==0) return;
   
   double pHigh=tHigh, pLow=tLow;
   datetime pTimeHigh=iTime(_Symbol,tf,1), pTimeLow=iTime(_Symbol,tf,1);
   
   if(!sameTF)
   {
      datetime periodEnd=iTime(_Symbol,tf,0);
      datetime periodStart=iTime(_Symbol,tf,1);
      
      // Find exact bar positions in stored arrays
      int leftIdx=-1, rightIdx=-1;
      for(int i=0;i<ArraySize(g_times);i++)
      {
         if(g_times[i]==periodStart) leftIdx=i;
         if(g_times[i]==periodEnd-1) {rightIdx=i; break;}
      }
      if(leftIdx>=0&&rightIdx>leftIdx)
      {
         double maxH=-1e10, minL=1e10;
         int maxIdx=leftIdx, minIdx=leftIdx;
         for(int i=leftIdx;i<=rightIdx&&i<ArraySize(g_highs);i++)
         {
            if(g_highs[i]>maxH){maxH=g_highs[i];maxIdx=i;}
            if(g_lows[i]<minL){minL=g_lows[i];minIdx=i;}
         }
         pHigh=maxH; pTimeHigh=g_times[maxIdx];
         pLow=minL; pTimeLow=g_times[minIdx];
      }
   }
   
   datetime rEnd=currentTime+20*PeriodSeconds(PERIOD_CURRENT);
   long stl=StyleLong(style);
   
   // High line + label
   string hl=g_pref+"MTF_"+highLabel;
   ObjectDelete(g_chartId,hl);
   ObjectCreate(g_chartId,hl,OBJ_TREND,0,pTimeHigh,pHigh,rEnd,pHigh);
   ObjectSetInteger(g_chartId,hl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,hl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,hl,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,hl,OBJPROP_STYLE,stl);
   ObjectSetInteger(g_chartId,hl,OBJPROP_SELECTABLE,false);
   
   string hlb=g_pref+"MTF_"+highLabel+"_LBL";
   ObjectDelete(g_chartId,hlb);
   ObjectCreate(g_chartId,hlb,OBJ_TEXT,0,rEnd,pHigh);
   ObjectSetString(g_chartId,hlb,OBJPROP_TEXT,highLabel);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,hlb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,hlb,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_SELECTABLE,false);
   
   // Low line + label
   string ll=g_pref+"MTF_"+lowLabel;
   ObjectDelete(g_chartId,ll);
   ObjectCreate(g_chartId,ll,OBJ_TREND,0,pTimeLow,pLow,rEnd,pLow);
   ObjectSetInteger(g_chartId,ll,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ll,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ll,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,ll,OBJPROP_STYLE,stl);
   ObjectSetInteger(g_chartId,ll,OBJPROP_SELECTABLE,false);
   
   string llb=g_pref+"MTF_"+lowLabel+"_LBL";
   ObjectDelete(g_chartId,llb);
   ObjectCreate(g_chartId,llb,OBJ_TEXT,0,rEnd,pLow);
   ObjectSetString(g_chartId,llb,OBJPROP_TEXT,lowLabel);
   ObjectSetInteger(g_chartId,llb,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,llb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,llb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,llb,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(g_chartId,llb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| UPDATE TRAILING EXTREMES — matches Pine                          |
//+------------------------------------------------------------------+
void UpdateTrailingExtremes()
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,0), l=iLow(_Symbol,PERIOD_CURRENT,0);
   datetime t=iTime(_Symbol,PERIOD_CURRENT,0);
   
   if(h>g_trail.top||g_trail.top==0)
   {
      g_trail.top=h;
      g_trail.lastTopTime=t;
   }
   if(l<g_trail.bottom||g_trail.bottom==0)
   {
      g_trail.bottom=l;
      g_trail.lastBottomTime=t;
   }
}

//+------------------------------------------------------------------+
//| DRAW HIGH/LOW SWINGS — matches Pine drawHighLowSwings()         |
//+------------------------------------------------------------------+
void DrawHighLowSwings()
{
   if(g_trail.top==0||g_trail.bottom==0) return;
   
   datetime rEnd=iTime(_Symbol,PERIOD_CURRENT,0)+20*PeriodSeconds(PERIOD_CURRENT);
   
   // Top line
   string tl=g_pref+"HLSW_TOP";
   ObjectDelete(g_chartId,tl);
   ObjectCreate(g_chartId,tl,OBJ_TREND,0,g_trail.lastTopTime,g_trail.top,rEnd,g_trail.top);
   ObjectSetInteger(g_chartId,tl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,tl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,tl,OBJPROP_COLOR,InpSwingBearColor);
   ObjectSetInteger(g_chartId,tl,OBJPROP_WIDTH,1);
   ObjectSetInteger(g_chartId,tl,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(g_chartId,tl,OBJPROP_SELECTABLE,false);
   
   string tlb=g_pref+"HLSW_TOP_LBL";
   ObjectDelete(g_chartId,tlb);
   ObjectCreate(g_chartId,tlb,OBJ_TEXT,0,rEnd,g_trail.top);
   ObjectSetString(g_chartId,tlb,OBJPROP_TEXT,g_swingTrend.bias==BEARISH?"Strong High":"Weak High");
   ObjectSetInteger(g_chartId,tlb,OBJPROP_COLOR,InpSwingBearColor);
   ObjectSetInteger(g_chartId,tlb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,tlb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,tlb,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId,tlb,OBJPROP_SELECTABLE,false);
   
   // Bottom line
   string bl=g_pref+"HLSW_BOT";
   ObjectDelete(g_chartId,bl);
   ObjectCreate(g_chartId,bl,OBJ_TREND,0,g_trail.lastBottomTime,g_trail.bottom,rEnd,g_trail.bottom);
   ObjectSetInteger(g_chartId,bl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,bl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,bl,OBJPROP_COLOR,InpSwingBullColor);
   ObjectSetInteger(g_chartId,bl,OBJPROP_WIDTH,1);
   ObjectSetInteger(g_chartId,bl,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(g_chartId,bl,OBJPROP_SELECTABLE,false);
   
   string blb=g_pref+"HLSW_BOT_LBL";
   ObjectDelete(g_chartId,blb);
   ObjectCreate(g_chartId,blb,OBJ_TEXT,0,rEnd,g_trail.bottom);
   ObjectSetString(g_chartId,blb,OBJPROP_TEXT,g_swingTrend.bias==BULLISH?"Strong Low":"Weak Low");
   ObjectSetInteger(g_chartId,blb,OBJPROP_COLOR,InpSwingBullColor);
   ObjectSetInteger(g_chartId,blb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,blb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,blb,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(g_chartId,blb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| PREMIUM/DISCOUNT ZONES — matches Pine                            |
//+------------------------------------------------------------------+
void DrawZone(double labelLevel, int labelIdx, double top, double bottom, string tag, color c, int anchor)
{
   // Box
   string bx=g_pref+"PD_"+tag;
   ObjectDelete(g_chartId,bx);
   datetime now=iTime(_Symbol,PERIOD_CURRENT,0);
   ObjectCreate(g_chartId,bx,OBJ_RECTANGLE,0,g_trail.barTime,top,now,bottom);
   ObjectSetInteger(g_chartId,bx,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,bx,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_SELECTABLE,false);
   
   // Label
   string lb=g_pref+"PD_"+tag+"_LBL";
   ObjectDelete(g_chartId,lb);
   datetime midTime=iTime(_Symbol,PERIOD_CURRENT,labelIdx/2);
   ObjectCreate(g_chartId,lb,OBJ_TEXT,0,midTime,labelLevel);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,8);
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

void DrawPDZones()
{
   if(g_trail.top<=0||g_trail.bottom<=0||g_trail.top<=g_trail.bottom) return;
   
   double range=g_trail.top-g_trail.bottom;
   double premBot=0.95*g_trail.top+0.05*g_trail.bottom;
   double discTop=0.95*g_trail.bottom+0.05*g_trail.top;
   double eqMid=(g_trail.top+g_trail.bottom)/2;
   double eqTop=0.525*g_trail.top+0.475*g_trail.bottom;
   double eqBot=0.525*g_trail.bottom+0.475*g_trail.top;
   int midIdx=(g_trail.barIndex+0)/2;
   
   DrawZone(g_trail.top,midIdx,g_trail.top,premBot,"Premium",InpPremiumColor,ANCHOR_BOTTOM);
   DrawZone(eqMid,0,eqTop,eqBot,"Equilibrium",InpEqColor,ANCHOR_CENTER);
   DrawZone(g_trail.bottom,midIdx,discTop,g_trail.bottom,"Discount",InpDiscountColor,ANCHOR_TOP);
}

//+------------------------------------------------------------------+
//| ONINIT                                                            |
//+------------------------------------------------------------------+
void OnInit()
{
   g_chartId=ChartID();
   
   // Setup buffers
   SetIndexBuffer(BUF_INT_BULL_BOS,   g_bufIntBullBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_BOS,   g_bufIntBearBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BULL_CHOCH, g_bufIntBullCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_CHOCH, g_bufIntBearCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_BOS,   g_bufSwingBullBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_BOS,   g_bufSwingBearBOS,   INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_CHOCH, g_bufSwingBullCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_CHOCH, g_bufSwingBearCHoCH, INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BULL_MIT,  g_bufOBBullMit,  INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BEAR_MIT,  g_bufOBBearMit,  INDICATOR_DATA);
   SetIndexBuffer(BUF_EQH, g_bufEQH, INDICATOR_DATA);
   SetIndexBuffer(BUF_EQL, g_bufEQL, INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BULL, g_bufFVGBull, INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BEAR, g_bufFVGBear, INDICATOR_DATA);
   
   for(int i=0;i<14;i++)
   {
      PlotIndexSetInteger(i,PLOT_ARROW,(i%2==0)?233:234);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0.0);
   }
   PlotIndexSetInteger(BUF_OB_BULL_MIT,PLOT_ARROW,76);
   PlotIndexSetInteger(BUF_OB_BEAR_MIT,PLOT_ARROW,77);
   
   g_atrHandle=iATR(_Symbol,PERIOD_CURRENT,200);
   if(g_atrHandle==INVALID_HANDLE) Print("WARN: ATR handle failed");
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Justin SMC ("+IntegerToString(InpSwingLength)+")");
   ObjectsDeleteAll(g_chartId,g_pref);
   
   g_initTime=iTime(_Symbol,PERIOD_CURRENT,0);
}

//+------------------------------------------------------------------+
//| ONDEINIT                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(g_chartId,g_pref);
   if(g_atrHandle!=INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
//| ONCALCULATE — execution order matches Pine script                |
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
   // New bar?
   int curBar=rates_total-1;
   bool newBar=(g_lastBarIndex!=curBar);
   g_lastBarIndex=curBar;
   
   if(!newBar && prev_calculated>0)
   {
      // Per-tick updates (right edge extension + OB updates + PD zones)
      if(InpShowHighLowSwings||InpShowPDZones) UpdateTrailingExtremes();
      if(InpShowHighLowSwings) DrawHighLowSwings();
      if(InpShowPDZones) DrawPDZones();
      if(InpShowIntOBs||InpShowSwingOBs)
      {
         DeleteOrderBlocks(true);
         DeleteOrderBlocks(false);
         DrawOrderBlocks(true);
         DrawOrderBlocks(false);
      }
      return rates_total;
   }
   
   // Store data arrays (mirroring Pine var arrays)
   int arrSz=ArraySize(g_highs);
   if(arrSz>5000) // prevent unlimited growth
   {
      int trim=1000;
      ArrayCopy(g_highs,g_highs,0,trim);
      ArrayCopy(g_lows,g_lows,0,trim);
      ArrayCopy(g_parsedHighs,g_parsedHighs,0,trim);
      ArrayCopy(g_parsedLows,g_parsedLows,0,trim);
      ArrayCopy(g_times,g_times,0,trim);
      arrSz-=trim;
   }
   
   ArrayResize(g_highs,arrSz+1);
   ArrayResize(g_lows,arrSz+1);
   ArrayResize(g_parsedHighs,arrSz+1);
   ArrayResize(g_parsedLows,arrSz+1);
   ArrayResize(g_times,arrSz+1);
   
   g_highs[arrSz]=high[0];
   g_lows[arrSz]=low[0];
   g_parsedHighs[arrSz]=ParsedHigh(0);
   g_parsedLows[arrSz]=ParsedLow(0);
   g_times[arrSz]=time[0];
   
   // Reset alerts
   ZeroMemory(g_alerts);
   
   // --- Candle coloring ---
   if(InpShowTrend)
   {
      // The Pine code plots candles colored by internalTrend.bias
      // In MT5 indicator we can't recolor candles, but we buffer the info
   }
   
   // --- Trailing extremes update ---
   if(InpShowHighLowSwings||InpShowPDZones)
   {
      UpdateTrailingExtremes();
      if(InpShowHighLowSwings) DrawHighLowSwings();
      if(InpShowPDZones) DrawPDZones();
   }
   
   // --- FVG delete ---
   if(InpShowFVG) DeleteFairValueGaps();
   
   // --- Get current structure (swing) ---
   GetCurrentStructure(InpSwingLength,false,false,time,high,low,rates_total);
   
   // --- Get current structure (internal, size=5) ---
   GetCurrentStructure(5,false,true,time,high,low,rates_total);
   
   // --- Equal highs/lows ---
   if(InpShowEQHEQL)
      GetCurrentStructure(InpEqLen,true,false,time,high,low,rates_total);
   
   // --- Display internal structure ---
   if(InpShowInternals||InpShowIntOBs||InpShowTrend)
      DisplayStructure(true,time,high,low,close,rates_total);
   
   // --- Display swing structure ---
   if(InpShowSwing||InpShowSwingOBs||InpShowHighLowSwings)
      DisplayStructure(false,time,high,low,close,rates_total);
   
   // --- Delete order blocks ---
   if(InpShowIntOBs) DeleteOrderBlocks(true);
   if(InpShowSwingOBs) DeleteOrderBlocks(false);
   
   // --- Draw Fair Value Gaps ---
   if(InpShowFVG) DrawFairValueGaps();
   
   // --- Draw order blocks (on last bar or realtime) ---
   if(InpShowIntOBs) DrawOrderBlocks(true);
   if(InpShowSwingOBs) DrawOrderBlocks(false);
   
   // --- MTF Levels (on bar close or realtime new bar) ---
   if(InpShowDaily && Period()<PERIOD_D1)
      DrawLevels(PERIOD_D1,false,InpDailyStyle,InpDailyColor,"PDH","PDL",time[0]);
   if(InpShowWeekly && Period()<PERIOD_W1)
      DrawLevels(PERIOD_W1,false,InpWeeklyStyle,InpWeeklyColor,"PWH","PWL",time[0]);
   if(InpShowMonthly && Period()<PERIOD_MN1)
      DrawLevels(PERIOD_MN1,false,InpMonthlyStyle,InpMonthlyColor,"PMH","PML",time[0]);
   
   return rates_total;
}
//+------------------------------------------------------------------+
