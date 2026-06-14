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
enum ENUM_MODE { MODE_HISTORICAL = 0, MODE_PRESENT = 1 };
enum ENUM_STYLE_THEME { STYLE_COLORED = 0, STYLE_MONOCHROME = 1 };
enum ENUM_DISPLAY_FILTER { FILTER_ALL = 0, FILTER_BOS = 1, FILTER_CHOCH = 2 };
enum ENUM_LABEL_SZ { LSIZE_TINY = 0, LSIZE_SMALL = 1, LSIZE_NORMAL = 2 };
enum ENUM_OB_FILTER { OB_ATR = 0, OB_RANGE = 1 };
enum ENUM_MITIGATION { MIT_CLOSE = 0, MIT_HIGHLOW = 1 };

//+------------------------------------------------------------------+
//| STRUCTS — NO strings or dynamic arrays inside                   |
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
   int bias;
};

struct OrderBlock
{
   double   barHigh;
   double   barLow;
   int      barTime;
   int      bias;
};

struct TrailingExtremes
{
   double   top;
   double   bottom;
   int      barTime;
   int      barIndex;
   int      lastTopTime;
   int      lastBottomTime;
};

// FVG struct — NO strings! Box names built inline
struct FVG
{
   double   top;
   double   bottom;
   int      bias;
   int      barBTime;
};

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input ENUM_MODE           InpMode              = MODE_HISTORICAL;
input ENUM_STYLE_THEME    InpStyle             = STYLE_COLORED;
input bool                InpShowTrend         = false;

input bool                InpShowInternals     = true;
input ENUM_DISPLAY_FILTER InpIntBullFilter     = FILTER_ALL;
input color               InpIntBullColor      = clrDodgerBlue;
input ENUM_DISPLAY_FILTER InpIntBearFilter     = FILTER_ALL;
input color               InpIntBearColor      = clrCrimson;
input bool                InpIntConfluence     = false;
input ENUM_LABEL_SZ       InpIntLabelSize      = LSIZE_TINY;

input bool                InpShowSwing         = true;
input ENUM_DISPLAY_FILTER InpSwingBullFilter   = FILTER_ALL;
input color               InpSwingBullColor    = clrBlue;
input ENUM_DISPLAY_FILTER InpSwingBearFilter   = FILTER_ALL;
input color               InpSwingBearColor    = clrRed;
input ENUM_LABEL_SZ       InpSwingLabelSize    = LSIZE_SMALL;
input bool                InpShowSwings        = false;
input int                 InpSwingLength       = 50;
input bool                InpShowHighLowSwings = true;

input bool                InpShowIntOBs        = true;
input int                 InpIntOBMax          = 5;
input bool                InpShowSwingOBs      = false;
input int                 InpSwingOBMax        = 5;
input ENUM_OB_FILTER      InpOBFilter          = OB_ATR;
input ENUM_MITIGATION     InpOBMitigation      = MIT_HIGHLOW;
input color               InpIntOBBullColor    = clrDodgerBlue;
input color               InpIntOBBearColor    = clrCrimson;
input color               InpSwingOBBullColor  = clrBlue;
input color               InpSwingOBBearColor  = clrRed;

input bool                InpShowEQHEQL        = true;
input int                 InpEqLen             = 3;
input double              InpEqThreshold       = 0.1;
input ENUM_LABEL_SZ       InpEqLabelSize       = LSIZE_TINY;

input bool                InpShowFVG           = false;
input bool                InpFVG_AutoThreshold = true;
input ENUM_TIMEFRAMES     InpFVG_TF            = PERIOD_CURRENT;
input color               InpFVGBullColor      = clrMediumSpringGreen;
input color               InpFVGBearColor      = clrDeepPink;
input int                 InpFVG_Extend        = 1;

input bool                InpShowDaily         = false;
input ENUM_LINE_STYLE     InpDailyStyle        = STYLE_SOLID;
input color               InpDailyColor        = clrGray;
input bool                InpShowWeekly        = false;
input ENUM_LINE_STYLE     InpWeeklyStyle       = STYLE_DASH;
input color               InpWeeklyColor       = clrDarkGray;
input bool                InpShowMonthly       = false;
input ENUM_LINE_STYLE     InpMonthlyStyle      = STYLE_DOT;
input color               InpMonthlyColor      = clrDimGray;

input bool                InpShowPDZones       = false;
input color               InpPremiumColor      = clrRed;
input color               InpEqColor           = clrGray;
input color               InpDiscountColor     = clrGreen;

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+
long     g_chartId;
string   g_pref = "SMC_";
int      g_atrHandle = INVALID_HANDLE;

Pivot    g_swingHigh, g_swingLow;
Pivot    g_intHigh, g_intLow;
Pivot    g_eqHigh, g_eqLow;

Trend    g_swingTrend, g_intTrend;

// Storage arrays
double   g_parsedHighs[];
double   g_parsedLows[];
double   g_highs[];
double   g_lows[];
int      g_times[];

// Order blocks — plain arrays, no ArrayCopy
OrderBlock g_swingOBs[];
OrderBlock g_intOBs[];

// FVGs — no strings
FVG      g_fvgs[];

TrailingExtremes g_trail;

// Alerts struct (plain bools only)
struct Alerts
{
   bool intBullBOS, intBearBOS, intBullCHoCH, intBearCHoCH;
   bool swingBullBOS, swingBearBOS, swingBullCHoCH, swingBearCHoCH;
   bool intBullOB, intBearOB, swingBullOB, swingBearOB;
   bool eqHighs, eqLows;
   bool bullFVG, bearFVG;
};
Alerts g_alerts;

int      g_lastBarIndex = -1;
int      g_initTime = 0;
double   g_fvgSumPct = 0;
int      g_fvgCount = 0;

// Buffers
double g_bufIntBullBOS[], g_bufIntBearBOS[], g_bufIntBullCHoCH[], g_bufIntBearCHoCH[];
double g_bufSwingBullBOS[], g_bufSwingBearBOS[], g_bufSwingBullCHoCH[], g_bufSwingBearCHoCH[];
double g_bufOBBullMit[], g_bufOBBearMit[];
double g_bufEQH[], g_bufEQL[];
double g_bufFVGBull[], g_bufFVGBear[];

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
int FontSz(ENUM_LABEL_SZ s)
{
   switch(s){case LSIZE_TINY:return 7;case LSIZE_SMALL:return 9;case LSIZE_NORMAL:return 12;}
   return 9;
}

double GetATR(int i)
{
   double a[]; ArraySetAsSeries(a,true);
   if(g_atrHandle!=INVALID_HANDLE && CopyBuffer(g_atrHandle,0,i,1,a)>0) return a[0];
   double s=0;int c=0;
   for(int j=i;j<i+14&&j<10000;j++)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,j),l=iLow(_Symbol,PERIOD_CURRENT,j),pc=iClose(_Symbol,PERIOD_CURRENT,j+1);
      if(h>0&&l>0){s+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));c++;}
   }
   return c>0?s/c:0;
}

double GetCMR()
{
   double s=0;
   int n=MathMin(1000,iBars(_Symbol,PERIOD_CURRENT)-1); if(n<=0)return 0;
   for(int i=0;i<n;i++)
   {
      double h=iHigh(_Symbol,PERIOD_CURRENT,i),l=iLow(_Symbol,PERIOD_CURRENT,i),pc=iClose(_Symbol,PERIOD_CURRENT,i+1);
      s+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
   }
   return s/n;
}

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
//| PIVOT: leg()                                                     |
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
//| DRAW LABEL                                                       |
//+------------------------------------------------------------------+
void DrawLabel(int t, double price, string tag, color c, int anchor)
{
   string n=g_pref+"LBL_"+tag+"_"+IntegerToString(t);
   if(InpMode==MODE_PRESENT) ObjectDelete(g_chartId,n);
   if(ObjectFind(g_chartId,n)<0) ObjectCreate(g_chartId,n,OBJ_TEXT,0,(datetime)t,price);
   else ObjectMove(g_chartId,n,0,(datetime)t,price);
   ObjectSetString(g_chartId,n,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,n,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,n,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,n,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,n,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(g_chartId,n,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| DRAW STRUCTURE — SEGMENT pivot bar -> current bar               |
//+------------------------------------------------------------------+
void DrawStructure(Pivot &p, string tag, color c, long lineStyle, int lblAnchor, ENUM_LABEL_SZ sz)
{
   string id=g_pref+"STRUCT_"+IntegerToString(p.barTime);
   string ln=id+"_L", lb=id+"_LB";
   if(InpMode==MODE_PRESENT){ObjectDelete(g_chartId,ln);ObjectDelete(g_chartId,lb);}
   
   int nowTime=iTime(_Symbol,PERIOD_CURRENT,0);
   if(ObjectFind(g_chartId,ln)<0) ObjectCreate(g_chartId,ln,OBJ_TREND,0,(datetime)p.barTime,p.currentLevel,(datetime)nowTime,p.currentLevel);
   else {ObjectMove(g_chartId,ln,0,(datetime)p.barTime,p.currentLevel);ObjectMove(g_chartId,ln,1,(datetime)nowTime,p.currentLevel);}
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,ln,OBJPROP_WIDTH,lineStyle==STYLE_SOLID?2:1);
   ObjectSetInteger(g_chartId,ln,OBJPROP_STYLE,lineStyle);
   ObjectSetInteger(g_chartId,ln,OBJPROP_SELECTABLE,false);
   
   int midIdx=(p.barIndex+1)/2;
   int midTime=iTime(_Symbol,PERIOD_CURRENT,midIdx);
   if(ObjectFind(g_chartId,lb)<0) ObjectCreate(g_chartId,lb,OBJ_TEXT,0,(datetime)midTime,p.currentLevel);
   else ObjectMove(g_chartId,lb,0,(datetime)midTime,p.currentLevel);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,FontSz(sz));
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,lblAnchor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| DRAW EQH/EQL — NO reference+ternary, use separate blocks        |
//+------------------------------------------------------------------+
void DrawEqualHighLow(Pivot &p, double level, int size, bool isHigh)
{
   string tag=isHigh?"EQH":"EQL";
   color c=isHigh?InpSwingBearColor:InpSwingBullColor;
   int anc=isHigh?ANCHOR_BOTTOM:ANCHOR_TOP;
   
   if(InpMode==MODE_PRESENT)
   {
      ObjectDelete(g_chartId,g_pref+(isHigh?"EQH_":"EQL_")+"LINE");
      ObjectDelete(g_chartId,g_pref+(isHigh?"EQH_":"EQL_")+"LBL");
   }
   
   string ln=g_pref+(isHigh?"EQH_":"EQL_")+"LINE";
   string lb=g_pref+(isHigh?"EQH_":"EQL_")+"LBL";
   
   int t2=iTime(_Symbol,PERIOD_CURRENT,size);
   if(ObjectFind(g_chartId,ln)<0) ObjectCreate(g_chartId,ln,OBJ_TREND,0,(datetime)p.barTime,p.currentLevel,(datetime)t2,level);
   else {ObjectMove(g_chartId,ln,0,(datetime)p.barTime,p.currentLevel);ObjectMove(g_chartId,ln,1,(datetime)t2,level);}
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ln,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,ln,OBJPROP_WIDTH,1);
   ObjectSetInteger(g_chartId,ln,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(g_chartId,ln,OBJPROP_SELECTABLE,false);
   
   int midIdx=(p.barIndex+size)/2;
   int midTime=iTime(_Symbol,PERIOD_CURRENT,midIdx);
   double midPrice=(p.currentLevel+level)/2;
   
   if(ObjectFind(g_chartId,lb)<0) ObjectCreate(g_chartId,lb,OBJ_TEXT,0,(datetime)midTime,midPrice);
   else ObjectMove(g_chartId,lb,0,(datetime)midTime,midPrice);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,tag);
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,c);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,FontSz(InpEqLabelSize));
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,anc);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| GET CURRENT STRUCTURE — no reference+ternary patterns           |
//+------------------------------------------------------------------+
void GetCurrentStructure(int size, bool eqhl, bool internal,
                         const datetime &time[], const double &high[], const double &low[], int rates_total)
{
   int curLeg=Leg(size,high,low,rates_total);
   bool newPivot=StartOfNewLeg(curLeg);
   bool pivotLow=StartOfBullishLeg(curLeg);
   bool pivotHigh=StartOfBearishLeg(curLeg);
   if(!newPivot) return;
   
   double atr=GetATR(size);
   
   if(pivotLow)
   {
      // Determine which pivot gets updated
      if(eqhl)
         UpdateLowPivot(g_eqLow, low[size], (int)time[size], size, atr, true, false);
      else if(internal)
         UpdateLowPivot(g_intLow, low[size], (int)time[size], size, atr, false, true);
      else
         UpdateLowPivot(g_swingLow, low[size], (int)time[size], size, atr, false, false);
      
      if(eqhl && g_eqLow.currentLevel>0 && MathAbs(g_eqLow.currentLevel-low[size])<InpEqThreshold*atr)
      {
         DrawEqualHighLow(g_eqLow,low[size],size,false);
         g_alerts.eqLows=true; g_bufEQL[size]=low[size];
      }
   }
   else // pivotHigh
   {
      if(eqhl)
         UpdateHighPivot(g_eqHigh, high[size], (int)time[size], size, atr, true, false);
      else if(internal)
         UpdateHighPivot(g_intHigh, high[size], (int)time[size], size, atr, false, true);
      else
         UpdateHighPivot(g_swingHigh, high[size], (int)time[size], size, atr, false, false);
      
      if(eqhl && g_eqHigh.currentLevel>0 && MathAbs(g_eqHigh.currentLevel-high[size])<InpEqThreshold*atr)
      {
         DrawEqualHighLow(g_eqHigh,high[size],size,true);
         g_alerts.eqHighs=true; g_bufEQH[size]=high[size];
      }
   }
}

// Separate helpers to avoid pointer/reference issues
void UpdateLowPivot(Pivot &p, double price, int t, int idx, double atr, bool eqhl, bool internal)
{
   p.lastLevel=p.currentLevel;
   p.currentLevel=price;
   p.crossed=false;
   p.barTime=t;
   p.barIndex=idx;
   
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
      DrawLabel(t,p.currentLevel,lbl,lc,ANCHOR_TOP);
   }
}

void UpdateHighPivot(Pivot &p, double price, int t, int idx, double atr, bool eqhl, bool internal)
{
   p.lastLevel=p.currentLevel;
   p.currentLevel=price;
   p.crossed=false;
   p.barTime=t;
   p.barIndex=idx;
   
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
      DrawLabel(t,p.currentLevel,lbl,lc,ANCHOR_BOTTOM);
   }
}

//+------------------------------------------------------------------+
//| ORDER BLOCK helper — manual array copy avoids ArrayCopy issues  |
//+------------------------------------------------------------------+
void CopyOBArray(OrderBlock &dst[], OrderBlock &src[])
{
   int n=ArraySize(src);
   ArrayResize(dst,n);
   for(int i=0;i<n;i++) dst[i]=src[i];
}

void ArrayRemoveOB(OrderBlock &arr[], int idx)
{
   int n=ArraySize(arr);
   if(idx<0||idx>=n) return;
   for(int i=idx;i<n-1;i++) arr[i]=arr[i+1];
   ArrayResize(arr,n-1);
}

void StoreOrderBlock(Pivot &p, bool internal, int bias)
{
   bool show=internal?InpShowIntOBs:InpShowSwingOBs;
   if(!show) return;
   
   int startBar=p.barIndex;
   int endBar=1;
   if(startBar<=endBar) return;
   
   double searchVal=(bias==BEARISH)?-1e10:1e10;
   int impulseBar=startBar;
   for(int i=startBar;i>=endBar;i--)
   {
      double val=(bias==BEARISH)?ParsedHigh(i):ParsedLow(i);
      if((bias==BEARISH && val>searchVal)||(bias==BULLISH && val<searchVal))
      {searchVal=val;impulseBar=i;}
   }
   
   OrderBlock ob;
   ob.barHigh=ParsedHigh(impulseBar);
   ob.barLow=ParsedLow(impulseBar);
   ob.barTime=(int)iTime(_Symbol,PERIOD_CURRENT,impulseBar);
   ob.bias=bias;
   
   OrderBlock arr[]; CopyOBArray(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   int max=internal?InpIntOBMax:InpSwingOBMax;
   if(sz>=max) ArrayRemoveOB(arr,0);
   int ns=ArraySize(arr); ArrayResize(arr,ns+1); arr[ns]=ob;
   
   if(internal) CopyOBArray(g_intOBs,arr);
   else CopyOBArray(g_swingOBs,arr);
}

void DeleteOrderBlocks(bool internal)
{
   OrderBlock arr[]; CopyOBArray(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   if(sz==0) return;
   
   double bearSrc=(InpOBMitigation==MIT_CLOSE)?iClose(_Symbol,PERIOD_CURRENT,0):iHigh(_Symbol,PERIOD_CURRENT,0);
   double bullSrc=(InpOBMitigation==MIT_CLOSE)?iClose(_Symbol,PERIOD_CURRENT,0):iLow(_Symbol,PERIOD_CURRENT,0);
   
   bool removed=false;
   for(int i=sz-1;i>=0;i--)
   {
      bool crossed=false;
      if(arr[i].bias==BEARISH && bearSrc>arr[i].barHigh) crossed=true;
      else if(arr[i].bias==BULLISH && bullSrc<arr[i].barLow) crossed=true;
      
      if(crossed)
      {
         string boxN=g_pref+(internal?"IN_":"SW_")+"OB_"+IntegerToString(arr[i].barTime)+"_BOX";
         ObjectDelete(g_chartId,boxN);
         if(internal)
         {
            if(arr[i].bias==BULLISH) g_alerts.intBullOB=true;
            else g_alerts.intBearOB=true;
         }
         else
         {
            if(arr[i].bias==BULLISH) g_alerts.swingBullOB=true;
            else g_alerts.swingBearOB=true;
         }
         ArrayRemoveOB(arr,i);
         removed=true;
      }
   }
   
   if(removed)
   {
      if(internal) CopyOBArray(g_intOBs,arr);
      else CopyOBArray(g_swingOBs,arr);
   }
}

void DrawOrderBlocks(bool internal)
{
   OrderBlock arr[]; CopyOBArray(arr,internal?g_intOBs:g_swingOBs);
   int sz=ArraySize(arr);
   int drawN=MathMin(sz,internal?InpIntOBMax:InpSwingOBMax);
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
      int nowTime=iTime(_Symbol,PERIOD_CURRENT,0);
      
      if(ObjectFind(g_chartId,boxN)<0)
         ObjectCreate(g_chartId,boxN,OBJ_RECTANGLE,0,(datetime)arr[i].barTime,arr[i].barHigh,(datetime)nowTime,arr[i].barLow);
      else
      {
         ObjectMove(g_chartId,boxN,0,(datetime)arr[i].barTime,arr[i].barHigh);
         ObjectMove(g_chartId,boxN,1,(datetime)nowTime,arr[i].barLow);
      }
      ObjectSetInteger(g_chartId,boxN,OBJPROP_COLOR,boxC);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_FILL,true);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_BACK,true);
      ObjectSetInteger(g_chartId,boxN,OBJPROP_SELECTABLE,false);
   }
}

//+------------------------------------------------------------------+
//| BUFFER HELPER                                                     |
//+------------------------------------------------------------------+
void SetBuf(bool internal, bool bull, bool choch, double price, int bar)
{
   if(bull&&!choch)      {if(internal)g_bufIntBullBOS[bar]=price;else g_bufSwingBullBOS[bar]=price;}
   else if(bull&&choch)  {if(internal)g_bufIntBullCHoCH[bar]=price;else g_bufSwingBullCHoCH[bar]=price;}
   else if(!bull&&!choch){if(internal)g_bufIntBearBOS[bar]=price;else g_bufSwingBearBOS[bar]=price;}
   else                  {if(internal)g_bufIntBearCHoCH[bar]=price;else g_bufSwingBearCHoCH[bar]=price;}
}

//+------------------------------------------------------------------+
//| DISPLAY STRUCTURE                                                |
//+------------------------------------------------------------------+
void DisplayStructure(bool internal, const datetime &time[],
                      const double &high[], const double &low[], const double &close[], int rates_total)
{
   long lStyle=internal?STYLE_DASH:STYLE_SOLID;
   ENUM_LABEL_SZ lsz=internal?InpIntLabelSize:InpSwingLabelSize;
   
   bool bullishBar=true, bearishBar=true;
   if(InpIntConfluence && internal)
   {
      double c=close[0], o=iOpen(_Symbol,PERIOD_CURRENT,0), h=high[0], l=low[0];
      bullishBar=(h-MathMax(c,o))>(MathMin(c,o)-l);
      bearishBar=(h-MathMax(c,o))<(MathMin(c,o)-l);
   }
   
   bool extraBull=internal?(g_intHigh.currentLevel!=g_swingHigh.currentLevel && bullishBar):true;
   bool extraBear=internal?(g_intLow.currentLevel!=g_swingLow.currentLevel && bearishBar):true;
   
   // Bullish break — pass internal flag to determine which pivot
   if(internal)
      CheckBullishBreak(g_intHigh, g_intTrend, true, lStyle, lsz, extraBull, close);
   else
      CheckBullishBreak(g_swingHigh, g_swingTrend, false, lStyle, lsz, extraBull, close);
   
   // Bearish break
   if(internal)
      CheckBearishBreak(g_intLow, g_intTrend, true, lStyle, lsz, extraBear, close);
   else
      CheckBearishBreak(g_swingLow, g_swingTrend, false, lStyle, lsz, extraBear, close);
}

void CheckBullishBreak(Pivot &pHi, Trend &t, bool internal, long lStyle, ENUM_LABEL_SZ lsz, bool extra, const double &close[])
{
   if(close[0]>pHi.currentLevel && pHi.currentLevel>0 && !pHi.crossed && extra)
   {
      bool isCHoCH=(t.bias==BEARISH);
      string tag=isCHoCH?"CHoCH":"BOS";
      if(internal){if(isCHoCH)g_alerts.intBullCHoCH=true;else g_alerts.intBullBOS=true;}
      else{if(isCHoCH)g_alerts.swingBullCHoCH=true;else g_alerts.swingBullBOS=true;}
      pHi.crossed=true; t.bias=BULLISH;
      
      bool show;
      if(internal){ENUM_DISPLAY_FILTER f=InpIntBullFilter;show=InpShowInternals&&(f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));}
      else{ENUM_DISPLAY_FILTER f=InpSwingBullFilter;show=InpShowSwing&&(f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));}
      
      color col=InpStyle==STYLE_MONOCHROME?clrLightGray:(internal?InpIntBullColor:InpSwingBullColor);
      if(show) DrawStructure(pHi,tag,col,lStyle,ANCHOR_TOP,lsz);
      SetBuf(internal,true,isCHoCH,pHi.currentLevel,0);
      if((internal&&InpShowIntOBs)||(!internal&&InpShowSwingOBs)) StoreOrderBlock(pHi,internal,BULLISH);
   }
}

void CheckBearishBreak(Pivot &pLo, Trend &t, bool internal, long lStyle, ENUM_LABEL_SZ lsz, bool extra, const double &close[])
{
   if(close[0]<pLo.currentLevel && pLo.currentLevel>0 && !pLo.crossed && extra)
   {
      bool isCHoCH=(t.bias==BULLISH);
      string tag=isCHoCH?"CHoCH":"BOS";
      if(internal){if(isCHoCH)g_alerts.intBearCHoCH=true;else g_alerts.intBearBOS=true;}
      else{if(isCHoCH)g_alerts.swingBearCHoCH=true;else g_alerts.swingBearBOS=true;}
      pLo.crossed=true; t.bias=BEARISH;
      
      bool show;
      if(internal){ENUM_DISPLAY_FILTER f=InpIntBearFilter;show=InpShowInternals&&(f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));}
      else{ENUM_DISPLAY_FILTER f=InpSwingBearFilter;show=InpShowSwing&&(f==FILTER_ALL||(f==FILTER_BOS&&!isCHoCH)||(f==FILTER_CHOCH&&isCHoCH));}
      
      color col=InpStyle==STYLE_MONOCHROME?clrDimGray:(internal?InpIntBearColor:InpSwingBearColor);
      if(show) DrawStructure(pLo,tag,col,lStyle,ANCHOR_BOTTOM,lsz);
      SetBuf(internal,false,isCHoCH,pLo.currentLevel,0);
      if((internal&&InpShowIntOBs)||(!internal&&InpShowSwingOBs)) StoreOrderBlock(pLo,internal,BEARISH);
   }
}

//+------------------------------------------------------------------+
//| FVG — no strings in struct                                       |
//+------------------------------------------------------------------+
void DeleteFairValueGaps()
{
   double cL=iLow(_Symbol,PERIOD_CURRENT,0), cH=iHigh(_Symbol,PERIOD_CURRENT,0);
   for(int i=ArraySize(g_fvgs)-1;i>=0;i--)
   {
      bool filled=false;
      if(g_fvgs[i].bias==BULLISH && cL<g_fvgs[i].bottom) filled=true;
      if(g_fvgs[i].bias==BEARISH && cH>g_fvgs[i].top) filled=true;
      if(filled)
      {
         string p=g_pref+"FVG_"+IntegerToString(g_fvgs[i].barBTime);
         ObjectDelete(g_chartId,p+"_TOP"); ObjectDelete(g_chartId,p+"_BOT");
         // Remove from array
         for(int j=i;j<ArraySize(g_fvgs)-1;j++) g_fvgs[j]=g_fvgs[j+1];
         ArrayResize(g_fvgs,ArraySize(g_fvgs)-1);
      }
   }
}

void AddFVG(int tA, int tB, int tC, double top, double bottom, bool bullish)
{
   for(int i=0;i<ArraySize(g_fvgs);i++)
      if(g_fvgs[i].top==top && g_fvgs[i].bottom==bottom) return;
   
   FVG f; f.top=top; f.bottom=bottom; f.bias=bullish?BULLISH:BEARISH; f.barBTime=tB;
   
   double mid=(top+bottom)/2;
   int end=tC+InpFVG_Extend*PeriodSeconds(PERIOD_CURRENT);
   color col=bullish?InpFVGBullColor:InpFVGBearColor;
   string p=g_pref+"FVG_"+IntegerToString(tB);
   
   ObjectDelete(g_chartId,p+"_TOP"); ObjectDelete(g_chartId,p+"_BOT");
   ObjectCreate(g_chartId,p+"_TOP",OBJ_RECTANGLE,0,(datetime)tB,top,(datetime)end,mid);
   ObjectSetInteger(g_chartId,p+"_TOP",OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,p+"_TOP",OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,p+"_TOP",OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,p+"_TOP",OBJPROP_SELECTABLE,false);
   
   ObjectCreate(g_chartId,p+"_BOT",OBJ_RECTANGLE,0,(datetime)tB,mid,(datetime)end,bottom);
   ObjectSetInteger(g_chartId,p+"_BOT",OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,p+"_BOT",OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,p+"_BOT",OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,p+"_BOT",OBJPROP_SELECTABLE,false);
   
   int sz=ArraySize(g_fvgs); ArrayResize(g_fvgs,sz+1); g_fvgs[sz]=f;
   int bufBar=iBarShift(_Symbol,PERIOD_CURRENT,(datetime)tB);
   if(bufBar>=0){if(bullish)g_bufFVGBull[bufBar]=bottom;else g_bufFVGBear[bufBar]=top;}
}

void DrawFairValueGaps()
{
   ENUM_TIMEFRAMES fvgTF=(InpFVG_TF==PERIOD_CURRENT)?Period():InpFVG_TF;
   int fvgBars=iBars(_Symbol,fvgTF);
   if(fvgBars<4) return;
   
   for(int shiftC=2;shiftC<MathMin(fvgBars,100);shiftC++)
   {
      int shiftB=shiftC+1, shiftA=shiftC+2;
      double aH=iHigh(_Symbol,fvgTF,shiftA), aL=iLow(_Symbol,fvgTF,shiftA);
      double bO=iOpen(_Symbol,fvgTF,shiftB), bC=iClose(_Symbol,fvgTF,shiftB);
      double cL=iLow(_Symbol,fvgTF,shiftC), cH=iHigh(_Symbol,fvgTF,shiftC);
      int tB=(int)iTime(_Symbol,fvgTF,shiftB), tC=(int)iTime(_Symbol,fvgTF,shiftC), tA=(int)iTime(_Symbol,fvgTF,shiftA);
      
      double pct=(bO>0)?(bC-bO)/bO*100.0:0;
      bool newTF=(shiftC==2);
      double thresh=0;
      if(InpFVG_AutoThreshold){g_fvgSumPct+=MathAbs(pct);g_fvgCount++;double avg=(g_fvgCount>0)?g_fvgSumPct/g_fvgCount:0;if(avg>0)thresh=2*avg;}
      
      if(cL>aH && bC>aH && MathAbs(pct)>thresh && newTF){g_alerts.bullFVG=true;AddFVG(tA,tB,tC,cL,aH,true);}
      if(cH<aL && bC<aL && MathAbs(pct)>thresh && newTF){g_alerts.bearFVG=true;AddFVG(tA,tB,tC,aL,cH,false);}
   }
}

//+------------------------------------------------------------------+
//| MTF LEVELS                                                       |
//+------------------------------------------------------------------+
void DrawLevels(ENUM_TIMEFRAMES tf, bool sameTF, ENUM_LINE_STYLE style, color col,
                string highLabel, string lowLabel, int currentTime)
{
   double tH=iHigh(_Symbol,tf,1), tL=iLow(_Symbol,tf,1);
   if(tH==0||tL==0) return;
   double pHigh=tH, pLow=tL;
   int pTH=(int)iTime(_Symbol,tf,1), pTL=(int)iTime(_Symbol,tf,1);
   
   if(!sameTF)
   {
      int pEnd=(int)iTime(_Symbol,tf,0), pStart=(int)iTime(_Symbol,tf,1);
      int lIdx=-1, rIdx=-1;
      for(int i=0;i<ArraySize(g_times);i++)
      {
         if(g_times[i]==pStart) lIdx=i;
         if(g_times[i]>=pEnd-1){rIdx=i;break;}
      }
      if(lIdx>=0&&rIdx>lIdx)
      {
         double maxH=-1e10, minL=1e10;
         int maxIdx=lIdx, minIdx=lIdx;
         for(int i=lIdx;i<=rIdx&&i<ArraySize(g_highs);i++)
         {
            if(g_highs[i]>maxH){maxH=g_highs[i];maxIdx=i;}
            if(g_lows[i]<minL){minL=g_lows[i];minIdx=i;}
         }
         pHigh=maxH; pTH=g_times[maxIdx];
         pLow=minL; pTL=g_times[minIdx];
      }
   }
   
   int rEnd=currentTime+20*PeriodSeconds(PERIOD_CURRENT);
   
   // High
   string hl=g_pref+"MTF_"+highLabel;
   ObjectDelete(g_chartId,hl);
   ObjectCreate(g_chartId,hl,OBJ_TREND,0,(datetime)pTH,pHigh,(datetime)rEnd,pHigh);
   ObjectSetInteger(g_chartId,hl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,hl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,hl,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,hl,OBJPROP_STYLE,style);
   ObjectSetInteger(g_chartId,hl,OBJPROP_SELECTABLE,false);
   
   string hlb=g_pref+"MTF_"+highLabel+"_LBL";
   ObjectDelete(g_chartId,hlb);
   ObjectCreate(g_chartId,hlb,OBJ_TEXT,0,(datetime)rEnd,pHigh);
   ObjectSetString(g_chartId,hlb,OBJPROP_TEXT,highLabel);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,hlb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,hlb,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId,hlb,OBJPROP_SELECTABLE,false);
   
   // Low
   string ll=g_pref+"MTF_"+lowLabel;
   ObjectDelete(g_chartId,ll);
   ObjectCreate(g_chartId,ll,OBJ_TREND,0,(datetime)pTL,pLow,(datetime)rEnd,pLow);
   ObjectSetInteger(g_chartId,ll,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,ll,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,ll,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,ll,OBJPROP_STYLE,style);
   ObjectSetInteger(g_chartId,ll,OBJPROP_SELECTABLE,false);
   
   string llb=g_pref+"MTF_"+lowLabel+"_LBL";
   ObjectDelete(g_chartId,llb);
   ObjectCreate(g_chartId,llb,OBJ_TEXT,0,(datetime)rEnd,pLow);
   ObjectSetString(g_chartId,llb,OBJPROP_TEXT,lowLabel);
   ObjectSetInteger(g_chartId,llb,OBJPROP_COLOR,col);
   ObjectSetInteger(g_chartId,llb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,llb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,llb,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(g_chartId,llb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| TRAILING + HIGH/LOW SWINGS                                        |
//+------------------------------------------------------------------+
void UpdateTrailingExtremes()
{
   double h=iHigh(_Symbol,PERIOD_CURRENT,0), l=iLow(_Symbol,PERIOD_CURRENT,0);
   int t=(int)iTime(_Symbol,PERIOD_CURRENT,0);
   if(h>g_trail.top||g_trail.top==0){g_trail.top=h;g_trail.lastTopTime=t;}
   if(l<g_trail.bottom||g_trail.bottom==0){g_trail.bottom=l;g_trail.lastBottomTime=t;}
}

void DrawHighLowSwings()
{
   if(g_trail.top==0||g_trail.bottom==0) return;
   int rEnd=(int)iTime(_Symbol,PERIOD_CURRENT,0)+20*PeriodSeconds(PERIOD_CURRENT);
   
   string tl=g_pref+"HLSW_TOP";
   ObjectDelete(g_chartId,tl);
   ObjectCreate(g_chartId,tl,OBJ_TREND,0,(datetime)g_trail.lastTopTime,g_trail.top,(datetime)rEnd,g_trail.top);
   ObjectSetInteger(g_chartId,tl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,tl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,tl,OBJPROP_COLOR,InpSwingBearColor);
   ObjectSetInteger(g_chartId,tl,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(g_chartId,tl,OBJPROP_SELECTABLE,false);
   
   string tlb=g_pref+"HLSW_TOP_LBL";
   ObjectDelete(g_chartId,tlb);
   ObjectCreate(g_chartId,tlb,OBJ_TEXT,0,(datetime)rEnd,g_trail.top);
   ObjectSetString(g_chartId,tlb,OBJPROP_TEXT,g_swingTrend.bias==BEARISH?"Strong High":"Weak High");
   ObjectSetInteger(g_chartId,tlb,OBJPROP_COLOR,InpSwingBearColor);
   ObjectSetInteger(g_chartId,tlb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,tlb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,tlb,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId,tlb,OBJPROP_SELECTABLE,false);
   
   string bl=g_pref+"HLSW_BOT";
   ObjectDelete(g_chartId,bl);
   ObjectCreate(g_chartId,bl,OBJ_TREND,0,(datetime)g_trail.lastBottomTime,g_trail.bottom,(datetime)rEnd,g_trail.bottom);
   ObjectSetInteger(g_chartId,bl,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(g_chartId,bl,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(g_chartId,bl,OBJPROP_COLOR,InpSwingBullColor);
   ObjectSetInteger(g_chartId,bl,OBJPROP_STYLE,STYLE_DASH);
   ObjectSetInteger(g_chartId,bl,OBJPROP_SELECTABLE,false);
   
   string blb=g_pref+"HLSW_BOT_LBL";
   ObjectDelete(g_chartId,blb);
   ObjectCreate(g_chartId,blb,OBJ_TEXT,0,(datetime)rEnd,g_trail.bottom);
   ObjectSetString(g_chartId,blb,OBJPROP_TEXT,g_swingTrend.bias==BULLISH?"Strong Low":"Weak Low");
   ObjectSetInteger(g_chartId,blb,OBJPROP_COLOR,InpSwingBullColor);
   ObjectSetInteger(g_chartId,blb,OBJPROP_FONTSIZE,7);
   ObjectSetString(g_chartId,blb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,blb,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(g_chartId,blb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| PD ZONES                                                         |
//+------------------------------------------------------------------+
void DrawPDZones()
{
   if(g_trail.top<=0||g_trail.bottom<=0||g_trail.top<=g_trail.bottom) return;
   double range=g_trail.top-g_trail.bottom;
   double pBot=0.95*g_trail.top+0.05*g_trail.bottom;
   double dTop=0.95*g_trail.bottom+0.05*g_trail.top;
   double eMid=(g_trail.top+g_trail.bottom)/2;
   double eTop=0.525*g_trail.top+0.475*g_trail.bottom;
   double eBot=0.525*g_trail.bottom+0.475*g_trail.top;
   int now=(int)iTime(_Symbol,PERIOD_CURRENT,0);
   int midIdx=(int)iTime(_Symbol,PERIOD_CURRENT,g_trail.barIndex/2);
   
   // Premium
   string bx=g_pref+"PD_Premium";
   ObjectDelete(g_chartId,bx);
   ObjectCreate(g_chartId,bx,OBJ_RECTANGLE,0,(datetime)g_trail.barTime,g_trail.top,(datetime)now,pBot);
   ObjectSetInteger(g_chartId,bx,OBJPROP_COLOR,InpPremiumColor);
   ObjectSetInteger(g_chartId,bx,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_SELECTABLE,false);
   string lb=g_pref+"PD_Premium_LBL";
   ObjectDelete(g_chartId,lb);
   ObjectCreate(g_chartId,lb,OBJ_TEXT,0,(datetime)midIdx,g_trail.top);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,"Premium");
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,InpPremiumColor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,8);
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
   
   // Equilibrium
   bx=g_pref+"PD_Equilibrium";
   ObjectDelete(g_chartId,bx);
   ObjectCreate(g_chartId,bx,OBJ_RECTANGLE,0,(datetime)g_trail.barTime,eTop,(datetime)now,eBot);
   ObjectSetInteger(g_chartId,bx,OBJPROP_COLOR,InpEqColor);
   ObjectSetInteger(g_chartId,bx,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_SELECTABLE,false);
   lb=g_pref+"PD_Equilibrium_LBL";
   ObjectDelete(g_chartId,lb);
   ObjectCreate(g_chartId,lb,OBJ_TEXT,0,(datetime)now,eMid);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,"Equilibrium");
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,InpEqColor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,8);
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
   
   // Discount
   bx=g_pref+"PD_Discount";
   ObjectDelete(g_chartId,bx);
   ObjectCreate(g_chartId,bx,OBJ_RECTANGLE,0,(datetime)g_trail.barTime,dTop,(datetime)now,g_trail.bottom);
   ObjectSetInteger(g_chartId,bx,OBJPROP_COLOR,InpDiscountColor);
   ObjectSetInteger(g_chartId,bx,OBJPROP_FILL,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_BACK,true);
   ObjectSetInteger(g_chartId,bx,OBJPROP_SELECTABLE,false);
   lb=g_pref+"PD_Discount_LBL";
   ObjectDelete(g_chartId,lb);
   ObjectCreate(g_chartId,lb,OBJ_TEXT,0,(datetime)midIdx,g_trail.bottom);
   ObjectSetString(g_chartId,lb,OBJPROP_TEXT,"Discount");
   ObjectSetInteger(g_chartId,lb,OBJPROP_COLOR,InpDiscountColor);
   ObjectSetInteger(g_chartId,lb,OBJPROP_FONTSIZE,8);
   ObjectSetString(g_chartId,lb,OBJPROP_FONT,"Consolas");
   ObjectSetInteger(g_chartId,lb,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(g_chartId,lb,OBJPROP_SELECTABLE,false);
}

//+------------------------------------------------------------------+
//| ONINIT                                                           |
//+------------------------------------------------------------------+
void OnInit()
{
   g_chartId=ChartID();
   SetIndexBuffer(BUF_INT_BULL_BOS,g_bufIntBullBOS,INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_BOS,g_bufIntBearBOS,INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BULL_CHOCH,g_bufIntBullCHoCH,INDICATOR_DATA);
   SetIndexBuffer(BUF_INT_BEAR_CHOCH,g_bufIntBearCHoCH,INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_BOS,g_bufSwingBullBOS,INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_BOS,g_bufSwingBearBOS,INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BULL_CHOCH,g_bufSwingBullCHoCH,INDICATOR_DATA);
   SetIndexBuffer(BUF_SWING_BEAR_CHOCH,g_bufSwingBearCHoCH,INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BULL_MIT,g_bufOBBullMit,INDICATOR_DATA);
   SetIndexBuffer(BUF_OB_BEAR_MIT,g_bufOBBearMit,INDICATOR_DATA);
   SetIndexBuffer(BUF_EQH,g_bufEQH,INDICATOR_DATA);
   SetIndexBuffer(BUF_EQL,g_bufEQL,INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BULL,g_bufFVGBull,INDICATOR_DATA);
   SetIndexBuffer(BUF_FVG_BEAR,g_bufFVGBear,INDICATOR_DATA);
   for(int i=0;i<14;i++){PlotIndexSetInteger(i,PLOT_ARROW,(i%2==0)?233:234);PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0.0);}
   PlotIndexSetInteger(BUF_OB_BULL_MIT,PLOT_ARROW,76);
   PlotIndexSetInteger(BUF_OB_BEAR_MIT,PLOT_ARROW,77);
   g_atrHandle=iATR(_Symbol,PERIOD_CURRENT,200);
   if(g_atrHandle==INVALID_HANDLE) Print("WARN: ATR handle failed");
   IndicatorSetString(INDICATOR_SHORTNAME,"Justin SMC ("+IntegerToString(InpSwingLength)+")");
   ObjectsDeleteAll(g_chartId,g_pref);
   g_initTime=(int)iTime(_Symbol,PERIOD_CURRENT,0);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(g_chartId,g_pref);
   if(g_atrHandle!=INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
//| ONCALCULATE                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[], const double &high[],
                const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   int curBar=rates_total-1;
   bool newBar=(g_lastBarIndex!=curBar);
   g_lastBarIndex=curBar;
   
   if(!newBar && prev_calculated>0)
   {
      if(InpShowHighLowSwings||InpShowPDZones){UpdateTrailingExtremes();if(InpShowHighLowSwings)DrawHighLowSwings();if(InpShowPDZones)DrawPDZones();}
      if(InpShowIntOBs||InpShowSwingOBs){DeleteOrderBlocks(true);DeleteOrderBlocks(false);DrawOrderBlocks(true);DrawOrderBlocks(false);}
      return rates_total;
   }
   
   // Store data
   int asz=ArraySize(g_highs);
   if(asz>5000)
   {
      int tr=1000;
      for(int i=0;i<asz-tr;i++){g_highs[i]=g_highs[i+tr];g_lows[i]=g_lows[i+tr];g_parsedHighs[i]=g_parsedHighs[i+tr];g_parsedLows[i]=g_parsedLows[i+tr];g_times[i]=g_times[i+tr];}
      ArrayResize(g_highs,asz-tr);ArrayResize(g_lows,asz-tr);ArrayResize(g_parsedHighs,asz-tr);ArrayResize(g_parsedLows,asz-tr);ArrayResize(g_times,asz-tr);
      asz-=tr;
   }
   asz=ArraySize(g_highs);
   ArrayResize(g_highs,asz+1);ArrayResize(g_lows,asz+1);ArrayResize(g_parsedHighs,asz+1);ArrayResize(g_parsedLows,asz+1);ArrayResize(g_times,asz+1);
   g_highs[asz]=high[0];g_lows[asz]=low[0];g_parsedHighs[asz]=ParsedHigh(0);g_parsedLows[asz]=ParsedLow(0);g_times[asz]=(int)time[0];
   
   ZeroMemory(g_alerts);
   
   // Trailing + PD
   if(InpShowHighLowSwings||InpShowPDZones){UpdateTrailingExtremes();if(InpShowHighLowSwings)DrawHighLowSwings();if(InpShowPDZones)DrawPDZones();}
   
   // FVG delete
   if(InpShowFVG) DeleteFairValueGaps();
   
   // Structure
   GetCurrentStructure(InpSwingLength,false,false,time,high,low,rates_total);
   GetCurrentStructure(5,false,true,time,high,low,rates_total);
   if(InpShowEQHEQL) GetCurrentStructure(InpEqLen,true,false,time,high,low,rates_total);
   
   // Display
   if(InpShowInternals||InpShowIntOBs||InpShowTrend) DisplayStructure(true,time,high,low,close,rates_total);
   if(InpShowSwing||InpShowSwingOBs||InpShowHighLowSwings) DisplayStructure(false,time,high,low,close,rates_total);
   
   // Delete OB
   if(InpShowIntOBs) DeleteOrderBlocks(true);
   if(InpShowSwingOBs) DeleteOrderBlocks(false);
   
   // FVG draw
   if(InpShowFVG) DrawFairValueGaps();
   
   // Draw OB
   if(InpShowIntOBs) DrawOrderBlocks(true);
   if(InpShowSwingOBs) DrawOrderBlocks(false);
   
   // MTF levels
   if(InpShowDaily && Period()<PERIOD_D1) DrawLevels(PERIOD_D1,false,InpDailyStyle,InpDailyColor,"PDH","PDL",(int)time[0]);
   if(InpShowWeekly && Period()<PERIOD_W1) DrawLevels(PERIOD_W1,false,InpWeeklyStyle,InpWeeklyColor,"PWH","PWL",(int)time[0]);
   if(InpShowMonthly && Period()<PERIOD_MN1) DrawLevels(PERIOD_MN1,false,InpMonthlyStyle,InpMonthlyColor,"PMH","PML",(int)time[0]);
   
   return rates_total;
}
//+------------------------------------------------------------------+
