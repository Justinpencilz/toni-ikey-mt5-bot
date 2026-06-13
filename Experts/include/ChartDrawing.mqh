//+------------------------------------------------------------------+
//|                                          ChartDrawing.mqh         |
//|           Clean swing point arrows + sequence labels only         |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

string   gd_prefix = "TI_";
long     gd_chartId = 0;

void DrawInit(long chartId, string symbol, string prefix)
{
   gd_chartId = chartId;
   gd_prefix = prefix;
}

void DrawEraseAll()
{
   ObjectsDeleteAll(gd_chartId, gd_prefix);
}

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
//| SWING POINTS — arrows + HH/HL/LH/LL labels only                 |
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
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, false);
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
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, false);
   }
   CleanupObjects("SL_", lCount);
}

//+------------------------------------------------------------------+
//| SEQUENCE LABELS — HH/HL/LH/LL next to each swing point          |
//+------------------------------------------------------------------+

void DrawSwingSequence()
{
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   if(g_ms.trend == TREND_UPTREND)
   {
      // Highs: HH
      for(int i = 0; i < MathMin(hCount, 10); i++)
      {
         string objName = gd_prefix + "SQH_" + IntegerToString(i);
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "HH");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      // Lows: HL
      for(int i = 0; i < MathMin(lCount, 10); i++)
      {
         string objName = gd_prefix + "SQL_" + IntegerToString(i);
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
      for(int i = 0; i < MathMin(hCount, 10); i++)
      {
         string objName = gd_prefix + "SQH_" + IntegerToString(i);
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "LH");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      for(int i = 0; i < MathMin(lCount, 10); i++)
      {
         string objName = gd_prefix + "SQL_" + IntegerToString(i);
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, g_swingLows[i].time, g_swingLows[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "LL");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
   }
}

//+------------------------------------------------------------------+
//| CLEANUP                                                          |
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
//| MAIN — draw swing points + sequence labels + BOS                |
//+------------------------------------------------------------------+

void DrawAllStructures(string biasStr)
{
   DrawSwingPoints();
   DrawSwingSequence();
   DrawBOS();
}

//+------------------------------------------------------------------+
//| BOS — dotted lines at body-broken swing levels only              |
//+------------------------------------------------------------------+

void DrawBOS()
{
   if(g_ms.hasBOS)
   {
      bool isBullish = g_ms.bosIsBullish;
      int breaks = g_ms.bosBreaksCount;
      color bosColor = isBullish ? clrCyan : clrMagenta;
      
      // Draw dotted lines at body-broken swing highs
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
            ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, false);
         }
         // Cleanup excess
         int maxToKeep = breaks + 2;
         for(int i = maxToKeep; i < 100; i++)
            if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_H_" + IntegerToString(i)))
               break;
      }
      
      // Draw dotted lines at body-broken swing lows
      if(!isBullish && ArraySize(g_swingLows) > 0)
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
            ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, false);
         }
         int maxToKeep = breaks + 2;
         for(int i = maxToKeep; i < 100; i++)
            if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_L_" + IntegerToString(i)))
               break;
      }
   }
   else
   {
      // Clean all BOS objects
      for(int i = 0; i < 100; i++)
      {
         if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_H_" + IntegerToString(i)))
         if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_L_" + IntegerToString(i)))
            break;
      }
   }
}

//+------------------------------------------------------------------+
