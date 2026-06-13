//+------------------------------------------------------------------+
//|                                          ChartDrawing.mqh         |
//|           Visual chart objects for market structure               |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

string   gd_prefix = "TI_";
long     gd_chartId = 0;
string   gd_symbol = "";

//+------------------------------------------------------------------+
//| Init / Clear                                                     |
//+------------------------------------------------------------------+

void DrawInit(long chartId, string symbol, string prefix)
{
   gd_chartId = chartId;
   gd_symbol = symbol;
   gd_prefix = prefix;
}

void DrawEraseAll()
{
   ObjectsDeleteAll(gd_chartId, gd_prefix);
}

//+------------------------------------------------------------------+
//| Helper: create or update chart object                            |
//+------------------------------------------------------------------+

void DrawObject(string name, ENUM_OBJECT type, datetime time1, double price1, 
                datetime time2 = 0, double price2 = 0)
{
   string objName = gd_prefix + name;
   
   if(ObjectFind(gd_chartId, objName) < 0)
      ObjectCreate(gd_chartId, objName, type, 0, time1, price1, time2, price2);
   else
      ObjectMove(gd_chartId, objName, 0, time1, price1);
   
   if(time2 > 0 && price2 > 0)
      ObjectMove(gd_chartId, objName, 1, time2, price2);
}

//+------------------------------------------------------------------+
//| 1. SWING POINTS — arrows only, NO price labels                   |
//+------------------------------------------------------------------+

void DrawSwingPoints()
{
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // Swing highs ▼
   for(int i = 0; i < hCount; i++)
   {
      string id = "SH_" + IntegerToString(i);
      DrawObject(id, OBJ_ARROW_DOWN, g_swingHighs[i].time, g_swingHighs[i].price);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_ANCHOR, ANCHOR_TOP);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
   }
   CleanupObjects("SH_", hCount);
   
   // Swing lows ▲
   for(int i = 0; i < lCount; i++)
   {
      string id = "SL_" + IntegerToString(i);
      DrawObject(id, OBJ_ARROW_UP, g_swingLows[i].time, g_swingLows[i].price);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
   }
   CleanupObjects("SL_", lCount);
}

//+------------------------------------------------------------------+
//| 2. TRENDLINES — slanted lines with direction label               |
//+------------------------------------------------------------------+

void DrawTrendlines()
{
   if(g_ms.uptrendLine.valid && g_ms.uptrendLine.point2Time > 0)
   {
      datetime t1 = g_ms.uptrendLine.point1Time;
      double   p1 = g_ms.uptrendLine.point1Price;
      datetime t2 = g_ms.uptrendLine.point2Time;
      double   p2 = g_ms.uptrendLine.point2Price;
      
      DrawObject("TRENDLINE", OBJ_TREND, t1, p1, t2, p2);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_BACK, true);
      
      // Label just "Uptrend" at the right end
      string lblName = gd_prefix + "TRENDLINE_LBL";
      if(ObjectFind(gd_chartId, lblName) < 0)
         ObjectCreate(gd_chartId, lblName, OBJ_TEXT, 0, t2, p2);
      ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, "Uptrend");
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   else if(g_ms.downtrendLine.valid && g_ms.downtrendLine.point2Time > 0)
   {
      datetime t1 = g_ms.downtrendLine.point1Time;
      double   p1 = g_ms.downtrendLine.point1Price;
      datetime t2 = g_ms.downtrendLine.point2Time;
      double   p2 = g_ms.downtrendLine.point2Price;
      
      DrawObject("TRENDLINE", OBJ_TREND, t1, p1, t2, p2);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + "TRENDLINE", OBJPROP_BACK, true);
      
      string lblName = gd_prefix + "TRENDLINE_LBL";
      if(ObjectFind(gd_chartId, lblName) < 0)
         ObjectCreate(gd_chartId, lblName, OBJ_TEXT, 0, t2, p2);
      ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, "Downtrend");
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_ANCHOR, ANCHOR_TOP);
   }
   else if(g_ms.rangeResistance.valid && g_ms.rangeSupport.valid)
   {
      // Resistance horizontal line
      double resPrice = g_ms.rangeResistance.point1Price;
      string objRes = gd_prefix + "RANGE_RESISTANCE";
      if(ObjectFind(gd_chartId, objRes) < 0)
         ObjectCreate(gd_chartId, objRes, OBJ_HLINE, 0, 0, resPrice);
      ObjectSetDouble(gd_chartId, objRes, OBJPROP_PRICE, resPrice);
      ObjectSetInteger(gd_chartId, objRes, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, objRes, OBJPROP_WIDTH, 1);
      ObjectSetInteger(gd_chartId, objRes, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(gd_chartId, objRes, OBJPROP_BACK, true);
      
      // Just "Resistance" label
      string lblR = gd_prefix + "RANGE_RESISTANCE_LBL";
      if(ObjectFind(gd_chartId, lblR) < 0)
         ObjectCreate(gd_chartId, lblR, OBJ_TEXT, 0, g_ms.rangeResistance.point2Time, resPrice);
      ObjectSetString(gd_chartId, lblR, OBJPROP_TEXT, "Resistance");
      ObjectSetInteger(gd_chartId, lblR, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, lblR, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblR, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblR, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      
      // Support horizontal line
      double supPrice = g_ms.rangeSupport.point1Price;
      string objSup = gd_prefix + "RANGE_SUPPORT";
      if(ObjectFind(gd_chartId, objSup) < 0)
         ObjectCreate(gd_chartId, objSup, OBJ_HLINE, 0, 0, supPrice);
      ObjectSetDouble(gd_chartId, objSup, OBJPROP_PRICE, supPrice);
      ObjectSetInteger(gd_chartId, objSup, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, objSup, OBJPROP_WIDTH, 1);
      ObjectSetInteger(gd_chartId, objSup, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(gd_chartId, objSup, OBJPROP_BACK, true);
      
      string lblS = gd_prefix + "RANGE_SUPPORT_LBL";
      if(ObjectFind(gd_chartId, lblS) < 0)
         ObjectCreate(gd_chartId, lblS, OBJ_TEXT, 0, g_ms.rangeSupport.point2Time, supPrice);
      ObjectSetString(gd_chartId, lblS, OBJPROP_TEXT, "Support");
      ObjectSetInteger(gd_chartId, lblS, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, lblS, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblS, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblS, OBJPROP_ANCHOR, ANCHOR_TOP);
   }
   else
   {
      ObjectDelete(gd_chartId, gd_prefix + "TRENDLINE");
      ObjectDelete(gd_chartId, gd_prefix + "TRENDLINE_LBL");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_RESISTANCE");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_RESISTANCE_LBL");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_SUPPORT");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_SUPPORT_LBL");
   }
}

//+------------------------------------------------------------------+
//| 3. MSS — dotted line + reversal label (no price)                 |
//+------------------------------------------------------------------+

void DrawMSS()
{
   if(g_ms.hasMSS)
   {
      double mssLevel = g_ms.mssBrokenLevel;
      bool isBullish = g_ms.mssIsBullish;
      color mssColor = isBullish ? clrDodgerBlue : clrRed;
      
      string objName = gd_prefix + "MSS_LINE";
      if(ObjectFind(gd_chartId, objName) < 0)
         ObjectCreate(gd_chartId, objName, OBJ_HLINE, 0, 0, mssLevel);
      ObjectSetDouble(gd_chartId, objName, OBJPROP_PRICE, mssLevel);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, mssColor);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, true);
      
      string label = isBullish ? "MSS BUY" : "MSS SELL";
      string lblName = gd_prefix + "MSS_LABEL";
      if(ObjectFind(gd_chartId, lblName) < 0)
         ObjectCreate(gd_chartId, lblName, OBJ_TEXT, 0, g_ms.mssTime, mssLevel);
      ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, label);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, mssColor);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(gd_chartId, lblName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }
   else
   {
      ObjectDelete(gd_chartId, gd_prefix + "MSS_LINE");
      ObjectDelete(gd_chartId, gd_prefix + "MSS_LABEL");
   }
}

//+------------------------------------------------------------------+
//| 4. BOS — dotted lines at broken levels (NO price labels)         |
//+------------------------------------------------------------------+

void DrawBOS()
{
   if(g_ms.hasBOS)
   {
      bool isBullish = g_ms.bosIsBullish;
      int breaks = g_ms.bosBreaksCount;
      color bosColor = isBullish ? clrCyan : clrMagenta;
      
      if(isBullish && ArraySize(g_swingHighs) > 0)
      {
         int drawCount = MathMin(breaks, ArraySize(g_swingHighs));
         for(int i = 0; i < drawCount; i++)
         {
            string id = "BOS_H_" + IntegerToString(i);
            string objName = gd_prefix + id;
            double level = g_swingHighs[i].price;
            
            if(ObjectFind(gd_chartId, objName) < 0)
               ObjectCreate(gd_chartId, objName, OBJ_HLINE, 0, 0, level);
            ObjectSetDouble(gd_chartId, objName, OBJPROP_PRICE, level);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, bosColor);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, true);
         }
         
         int maxToKeep = breaks + 2;
         for(int i = maxToKeep; i < 100; i++)
         {
            if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_H_" + IntegerToString(i)))
               break;
         }
      }
      else if(!isBullish && ArraySize(g_swingLows) > 0)
      {
         int drawCount = MathMin(breaks, ArraySize(g_swingLows));
         for(int i = 0; i < drawCount; i++)
         {
            string id = "BOS_L_" + IntegerToString(i);
            string objName = gd_prefix + id;
            double level = g_swingLows[i].price;
            
            if(ObjectFind(gd_chartId, objName) < 0)
               ObjectCreate(gd_chartId, objName, OBJ_HLINE, 0, 0, level);
            ObjectSetDouble(gd_chartId, objName, OBJPROP_PRICE, level);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, bosColor);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, true);
         }
         
         int maxToKeep = breaks + 2;
         for(int i = maxToKeep; i < 100; i++)
         {
            if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_L_" + IntegerToString(i)))
               break;
         }
      }
   }
   else
   {
      ObjectDelete(gd_chartId, gd_prefix + "BOS_LABEL");
      for(int i = 0; i < 100; i++)
      {
         if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_H_" + IntegerToString(i)))
         if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_L_" + IntegerToString(i)))
            break;
      }
   }
}

//+------------------------------------------------------------------+
//| 5. SEQUENCE LABELS — just HH/HL/LH/LL (no numbers)              |
//+------------------------------------------------------------------+

void DrawSwingSequence()
{
   if(g_ms.trend == TREND_UPTREND)
   {
      for(int i = 0; i < MathMin(ArraySize(g_swingHighs), 10); i++)
      {
         string id = "SQH_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "HH");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      for(int i = 0; i < MathMin(ArraySize(g_swingLows), 10); i++)
      {
         string id = "SQL_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingLows[i].time, g_swingLows[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "HL");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrLimeGreen);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
   }
   else if(g_ms.trend == TREND_DOWNTREND)
   {
      for(int i = 0; i < MathMin(ArraySize(g_swingHighs), 10); i++)
      {
         string id = "SQH_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "LH");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      for(int i = 0; i < MathMin(ArraySize(g_swingLows), 10); i++)
      {
         string id = "SQL_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingLows[i].time, g_swingLows[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "LL");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
   }
   else
   {
      CleanupObjects("SQH_", 0);
      CleanupObjects("SQL_", 0);
   }
}

//+------------------------------------------------------------------+
//| 6. ZONE LABELS — just "EXT" on external zones                   |
//+------------------------------------------------------------------+

void DrawZoneLabels()
{
   if(g_ms.trend != TREND_UPTREND && g_ms.trend != TREND_DOWNTREND)
   {
      CleanupObjects("EXT_H_", 0);
      CleanupObjects("EXT_L_", 0);
      return;
   }
   
   bool isUp = (g_ms.trend == TREND_UPTREND);
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   for(int i = 0; i < MathMin(hCount, 5); i++)
   {
      bool isExternal = false;
      if(isUp && i + 1 < hCount && g_swingHighs[i].price < g_swingHighs[i+1].price)
         isExternal = true;
      if(!isUp && i + 1 < hCount && g_swingHighs[i].price > g_swingHighs[i+1].price)
         isExternal = true;
      
      if(isExternal)
      {
         string objName = gd_prefix + "EXT_H_" + IntegerToString(i);
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "EXT");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      else
         ObjectDelete(gd_chartId, gd_prefix + "EXT_H_" + IntegerToString(i));
   }
   
   for(int i = 0; i < MathMin(lCount, 5); i++)
   {
      bool isExternal = false;
      if(isUp && i + 1 < lCount && g_swingLows[i].price < g_swingLows[i+1].price)
         isExternal = true;
      if(!isUp && i + 1 < lCount && g_swingLows[i].price > g_swingLows[i+1].price)
         isExternal = true;
      
      if(isExternal)
      {
         string objName = gd_prefix + "EXT_L_" + IntegerToString(i);
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingLows[i].time, g_swingLows[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "EXT");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
      else
         ObjectDelete(gd_chartId, gd_prefix + "EXT_L_" + IntegerToString(i));
   }
}

//+------------------------------------------------------------------+
//| 7. BIAS INDICATOR — minimal                                      |
//+------------------------------------------------------------------+

void DrawBiasIndicator(string biasStr)
{
   color clr = clrGray;
   if(StringFind(biasStr, "BUYS") >= 0) clr = clrLimeGreen;
   else if(StringFind(biasStr, "SELLS") >= 0) clr = clrRed;
   
   string objName = gd_prefix + "BIAS_INDICATOR";
   if(ObjectFind(gd_chartId, objName) < 0)
      ObjectCreate(gd_chartId, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_YDISTANCE, 170);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "Bias: " + biasStr);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| HELPER: cleanup excess objects                                   |
//+------------------------------------------------------------------+

void CleanupObjects(string prefix, int maxKeep)
{
   for(int i = maxKeep; i < maxKeep + 50; i++)
   {
      string objName = gd_prefix + prefix + IntegerToString(i);
      if(ObjectFind(gd_chartId, objName) >= 0)
         ObjectDelete(gd_chartId, objName);
      else
         break;
   }
}

//+------------------------------------------------------------------+
//| MAIN — draw everything                                           |
//+------------------------------------------------------------------+

void DrawAllStructures(string biasStr)
{
   DrawSwingPoints();
   DrawTrendlines();
   DrawMSS();
   DrawBOS();
   DrawSwingSequence();
   DrawZoneLabels();
   DrawBiasIndicator(biasStr);
}

//+------------------------------------------------------------------+
