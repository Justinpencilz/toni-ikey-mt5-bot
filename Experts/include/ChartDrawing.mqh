//+------------------------------------------------------------------+
//|                                          ChartDrawing.mqh         |
//|           Visual chart objects for market structure               |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"
#include "MarketStructure.mqh"

//+------------------------------------------------------------------+
//| INPUT GROUPS (passed from EA)                                    |
//+------------------------------------------------------------------+

// --- These are set by the EA ---
string   gd_prefix = "TI_";        // Object prefix
long     gd_chartId = 0;           // Chart ID
string   gd_symbol = "";           // Symbol

//+------------------------------------------------------------------+
//| Initialize drawing session                                       |
//+------------------------------------------------------------------+

void DrawInit(long chartId, string symbol, string prefix)
{
   gd_chartId = chartId;
   gd_symbol = symbol;
   gd_prefix = prefix;
}

//+------------------------------------------------------------------+
//| Erase all drawn objects                                           |
//+------------------------------------------------------------------+

void DrawEraseAll()
{
   ObjectsDeleteAll(gd_chartId, gd_prefix);
}

//+------------------------------------------------------------------+
//| Helper: create or update a chart object                          |
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
//| 1. DRAW SWING POINTS                                             |
//| Swing highs = ▼ down arrows (red/darkorange)                     |
//| Swing lows  = ▲ up arrows   (green/lime)                         |
//| With price labels                                                |
//+------------------------------------------------------------------+

void DrawSwingPoints()
{
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // --- Swing Highs ---
   for(int i = 0; i < hCount; i++)
   {
      string id = "SH_" + IntegerToString(i);
      datetime t = g_swingHighs[i].time;
      double p = g_swingHighs[i].price;
      
      // Arrow down ▼
      DrawObject(id, OBJ_ARROW_DOWN, t, p);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_ANCHOR, ANCHOR_TOP);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
      
      // Price label above
      string labelId = "SHL_" + IntegerToString(i);
      string labelName = gd_prefix + labelId;
      if(ObjectFind(gd_chartId, labelName) < 0)
         ObjectCreate(gd_chartId, labelName, OBJ_TEXT, 0, t, p);
      ObjectSetString(gd_chartId, labelName, OBJPROP_TEXT, DoubleToString(p, gd_symbol == "" ? _Digits : (int)SymbolInfoInteger(gd_symbol, SYMBOL_DIGITS)));
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(gd_chartId, labelName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   
   // Delete excess objects if swing count decreased
   CleanupObjects("SH_", hCount);
   CleanupObjects("SHL_", hCount);
   
   // --- Swing Lows ---
   for(int i = 0; i < lCount; i++)
   {
      string id = "SL_" + IntegerToString(i);
      datetime t = g_swingLows[i].time;
      double p = g_swingLows[i].price;
      
      // Arrow up ▲
      DrawObject(id, OBJ_ARROW_UP, t, p);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
      
      // Price label below
      string labelId = "SLL_" + IntegerToString(i);
      string labelName = gd_prefix + labelId;
      if(ObjectFind(gd_chartId, labelName) < 0)
         ObjectCreate(gd_chartId, labelName, OBJ_TEXT, 0, t, p);
      ObjectSetString(gd_chartId, labelName, OBJPROP_TEXT, DoubleToString(p, gd_symbol == "" ? _Digits : (int)SymbolInfoInteger(gd_symbol, SYMBOL_DIGITS)));
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(gd_chartId, labelName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, labelName, OBJPROP_ANCHOR, ANCHOR_TOP);
   }
   
   CleanupObjects("SL_", lCount);
   CleanupObjects("SLL_", lCount);
}

//+------------------------------------------------------------------+
//| 2. DRAW TRENDLINES (Definition 1)                                |
//| Uptrend: solid green line connecting higher lows                 |
//| Downtrend: solid red line connecting lower highs                 |
//| Range: dashed yellow lines at support and resistance            |
//+------------------------------------------------------------------+

void DrawTrendlines()
{
   string id;
   
   // --- Uptrend Line ---
   id = "TRENDLINE";
   if(g_ms.uptrendLine.valid && g_ms.uptrendLine.point2Time > 0)
   {
      datetime t1 = g_ms.uptrendLine.point1Time;
      double   p1 = g_ms.uptrendLine.point1Price;
      datetime t2 = g_ms.uptrendLine.point2Time;
      double   p2 = g_ms.uptrendLine.point2Price;
      
      DrawObject(id, OBJ_TREND, t1, p1, t2, p2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrLimeGreen);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
      
      // Label: "UPTREND"
      string lblId = "TRENDLINE_LBL";
      string lblName = gd_prefix + lblId;
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
      
      DrawObject(id, OBJ_TREND, t1, p1, t2, p2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + id, OBJPROP_BACK, true);
      
      string lblId = "TRENDLINE_LBL";
      string lblName = gd_prefix + lblId;
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
      // Range support line
      string idSup = "RANGE_SUPPORT";
      datetime supT1 = g_ms.rangeSupport.point1Time;
      double   supP1 = g_ms.rangeSupport.point1Price;
      datetime supT2 = g_ms.rangeSupport.point2Time;
      
      DrawObject(idSup, OBJ_TREND, supT1, supP1, supT2, supP1);
      ObjectSetInteger(gd_chartId, gd_prefix + idSup, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, gd_prefix + idSup, OBJPROP_WIDTH, 1);
      ObjectSetInteger(gd_chartId, gd_prefix + idSup, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(gd_chartId, gd_prefix + idSup, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + idSup, OBJPROP_BACK, true);
      
      // Label: "Support"
      string lblS = "RANGE_SUPPORT_LBL";
      string lblNameS = gd_prefix + lblS;
      if(ObjectFind(gd_chartId, lblNameS) < 0)
         ObjectCreate(gd_chartId, lblNameS, OBJ_TEXT, 0, supT2, supP1);
      ObjectSetString(gd_chartId, lblNameS, OBJPROP_TEXT, "Support");
      ObjectSetInteger(gd_chartId, lblNameS, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, lblNameS, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblNameS, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblNameS, OBJPROP_ANCHOR, ANCHOR_TOP);
      
      // Range resistance line
      string idRes = "RANGE_RESISTANCE";
      double   resP1 = g_ms.rangeResistance.point1Price;
      datetime resT2 = g_ms.rangeResistance.point2Time;
      
      DrawObject(idRes, OBJ_TREND, supT1, resP1, resT2, resP1);
      ObjectSetInteger(gd_chartId, gd_prefix + idRes, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, gd_prefix + idRes, OBJPROP_WIDTH, 1);
      ObjectSetInteger(gd_chartId, gd_prefix + idRes, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(gd_chartId, gd_prefix + idRes, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(gd_chartId, gd_prefix + idRes, OBJPROP_BACK, true);
      
      string lblR = "RANGE_RESISTANCE_LBL";
      string lblNameR = gd_prefix + lblR;
      if(ObjectFind(gd_chartId, lblNameR) < 0)
         ObjectCreate(gd_chartId, lblNameR, OBJ_TEXT, 0, resT2, resP1);
      ObjectSetString(gd_chartId, lblNameR, OBJPROP_TEXT, "Resistance");
      ObjectSetInteger(gd_chartId, lblNameR, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(gd_chartId, lblNameR, OBJPROP_FONTSIZE, 9);
      ObjectSetString(gd_chartId, lblNameR, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(gd_chartId, lblNameR, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   else
   {
      // No trendline valid — delete the objects
      ObjectDelete(gd_chartId, gd_prefix + "TRENDLINE");
      ObjectDelete(gd_chartId, gd_prefix + "TRENDLINE_LBL");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_SUPPORT");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_SUPPORT_LBL");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_RESISTANCE");
      ObjectDelete(gd_chartId, gd_prefix + "RANGE_RESISTANCE_LBL");
   }
}

//+------------------------------------------------------------------+
//| 3. DRAW MSS MARKER (Reversal)                                    |
//| Horizontal line at the broken swing level (CSS level)            |
//| With "MSS BUY" or "MSS SELL" label                               |
//+------------------------------------------------------------------+

void DrawMSS()
{
   if(g_ms.hasMSS)
   {
      datetime mssTime = g_ms.mssTime;
      double   mssLevel = g_ms.mssBrokenLevel;
      bool     isBullish = g_ms.mssIsBullish;
      
      // Horizontal line at the broken level
      string id = "MSS_LINE";
      string objName = gd_prefix + id;
      
      if(ObjectFind(gd_chartId, objName) < 0)
         ObjectCreate(gd_chartId, objName, OBJ_HLINE, 0, 0, mssLevel);
      ObjectSetDouble(gd_chartId, objName, OBJPROP_PRICE, mssLevel);
      
      color mssColor = isBullish ? clrDodgerBlue : clrRed;
      ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, mssColor);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(gd_chartId, objName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "MSS Level");
      ObjectSetInteger(gd_chartId, objName, OBJPROP_BACK, true);
      
      // Label at the line
      string lblId = "MSS_LABEL";
      string lblName = gd_prefix + lblId;
      string lblText = isBullish ? "← MSS BUY REVERSAL" : "← MSS SELL REVERSAL";
      
      if(ObjectFind(gd_chartId, lblName) < 0)
         ObjectCreate(gd_chartId, lblName, OBJ_TEXT, 0, mssTime, mssLevel);
      else
         ObjectMove(gd_chartId, lblName, 0, mssTime, mssLevel);
      
      ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, lblText);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, mssColor);
      ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 11);
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
//| 4. DRAW BOS ZONES (Continuation)                                 |
//| Horizontal lines at each broken swing level                      |
//| Internal = different color from external                         |
//| Shows "BOS x2 VALID" or "BOS x1 IGNORE" label                   |
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
         // Draw horizontal lines at the most recent broken swing highs
         // (these were already identified by DetectBOS)
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
         
         // Cleanup unused BOS_H objects
         int maxToKeep = breaks + 2;
         for(int i = maxToKeep; i < 100; i++)
         {
            if(!ObjectDelete(gd_chartId, gd_prefix + "BOS_H_" + IntegerToString(i)))
               break;
         }
         
         // Label
         string lblId = "BOS_LABEL";
         string lblName = gd_prefix + lblId;
         string lblText = "BOS x" + IntegerToString(breaks) + " ";
         lblText += (breaks >= BOS_MIN_MULTIPLE) ? "VALID ✓" : "IGNORE (single)";
         lblText += " → " + (isBullish ? "BUYS" : "SELLS");
         
         color lblColor = (breaks >= BOS_MIN_MULTIPLE) ? clrLimeGreen : clrDarkGray;
         
         if(ObjectFind(gd_chartId, lblName) < 0)
            ObjectCreate(gd_chartId, lblName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_XDISTANCE, 10);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_YDISTANCE, 190);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, lblText);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, lblColor);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 12);
         ObjectSetString(gd_chartId, lblName, OBJPROP_FONT, "Consolas");
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
         
         string lblId = "BOS_LABEL";
         string lblName = gd_prefix + lblId;
         string lblText = "BOS x" + IntegerToString(breaks) + " ";
         lblText += (breaks >= BOS_MIN_MULTIPLE) ? "VALID ✓" : "IGNORE (single)";
         lblText += " → " + (isBullish ? "BUYS" : "SELLS");
         
         color lblColor = (breaks >= BOS_MIN_MULTIPLE) ? clrLimeGreen : clrDarkGray;
         
         if(ObjectFind(gd_chartId, lblName) < 0)
            ObjectCreate(gd_chartId, lblName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_XDISTANCE, 10);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_YDISTANCE, 190);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(gd_chartId, lblName, OBJPROP_TEXT, lblText);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_COLOR, lblColor);
         ObjectSetInteger(gd_chartId, lblName, OBJPROP_FONTSIZE, 12);
         ObjectSetString(gd_chartId, lblName, OBJPROP_FONT, "Consolas");
      }
   }
   else
   {
      // Clean up BOS objects
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
//| 5. DRAW HH/HL/LH/LL CONFIRMATION SEQUENCE                       |
//| Shows arrows with HH, HL, LH, LL labels at each swing point      |
//+------------------------------------------------------------------+

void DrawSwingSequence()
{
   bool isUp = (g_ms.trend == TREND_UPTREND);
   bool isDown = (g_ms.trend == TREND_DOWNTREND);
   
   if(!isUp && !isDown) return;
   
   // For uptrend: label each swing as HH or HL
   if(isUp)
   {
      for(int i = 0; i < MathMin(ArraySize(g_swingHighs), 10); i++)
      {
         string id = "SQH_" + IntegerToString(i);
         string objName = gd_prefix + id;
         
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingHighs[i].time, g_swingHighs[i].price);
         
         // Determine if this is HH or LH relative to previous
         string label = "HH";
         if(i + 1 < ArraySize(g_swingHighs) && g_swingHighs[i].price < g_swingHighs[i+1].price)
            label = "LH";
         
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, label);
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
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingLows[i].time, g_swingLows[i].price);
         
         string label = "HL";
         if(i + 1 < ArraySize(g_swingLows) && g_swingLows[i].price < g_swingLows[i+1].price)
            label = "LL";
         
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, label);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrLimeGreen);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
   }
   else if(isDown)
   {
      for(int i = 0; i < MathMin(ArraySize(g_swingHighs), 10); i++)
      {
         string id = "SQH_" + IntegerToString(i);
         string objName = gd_prefix + id;
         
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingHighs[i].time, g_swingHighs[i].price);
         
         string label = "LH";
         if(i + 1 < ArraySize(g_swingHighs) && g_swingHighs[i].price > g_swingHighs[i+1].price)
            label = "HH";
         
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, label);
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
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingLows[i].time, g_swingLows[i].price);
         
         string label = "LL";
         if(i + 1 < ArraySize(g_swingLows) && g_swingLows[i].price > g_swingLows[i+1].price)
            label = "HL";
         
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, label);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
   }
   
   // Cleanup excess SQ objects
   CleanupObjects("SQH_", 10);
   CleanupObjects("SQL_", 10);
}

//+------------------------------------------------------------------+
//| 6. DRAW INTERNAL vs EXTERNAL ZONE LABELS                        |
//| Zones made during current trend = "INTERNAL"                     |
//| Zones from previous trend = "EXTERNAL"                           |
//+------------------------------------------------------------------+

void DrawZoneLabels()
{
   if(g_ms.trend != TREND_UPTREND && g_ms.trend != TREND_DOWNTREND) return;
   
   bool isUp = (g_ms.trend == TREND_UPTREND);
   int hCount = ArraySize(g_swingHighs);
   int lCount = ArraySize(g_swingLows);
   
   // In uptrend: recent swings are internal, older ones are external
   // Internal = supports current trend
   // External = from the previous opposite trend
   
   // Label external zones (oldest swings that don't fit the current trend pattern)
   for(int i = 0; i < MathMin(hCount, 5); i++)
   {
      bool isExternal = false;
      if(isUp && i + 1 < hCount && g_swingHighs[i].price < g_swingHighs[i+1].price)
         isExternal = true;  // This high is lower than the previous = from downtrend
      if(!isUp && i + 1 < hCount && g_swingHighs[i].price > g_swingHighs[i+1].price)
         isExternal = true;
      
      if(isExternal)
      {
         string id = "EXT_H_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingHighs[i].time, g_swingHighs[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "EXT");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      }
      else
      {
         ObjectDelete(gd_chartId, gd_prefix + "EXT_H_" + IntegerToString(i));
      }
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
         string id = "EXT_L_" + IntegerToString(i);
         string objName = gd_prefix + id;
         if(ObjectFind(gd_chartId, objName) < 0)
            ObjectCreate(gd_chartId, objName, OBJ_TEXT, 0, 
                         g_swingLows[i].time, g_swingLows[i].price);
         ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "EXT");
         ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, clrGray);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(gd_chartId, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      }
      else
      {
         ObjectDelete(gd_chartId, gd_prefix + "EXT_L_" + IntegerToString(i));
      }
   }
}

//+------------------------------------------------------------------+
//| 7. DRAW BIAS INDICATOR                                           |
//| Shows directional bias on the right edge of the chart            |
//+------------------------------------------------------------------+

void DrawBiasIndicator(string biasStr)
{
   string id = "BIAS_INDICATOR";
   string objName = gd_prefix + id;
   
   color biasColor = clrGray;
   if(StringFind(biasStr, "BUYS") >= 0)
      biasColor = clrLimeGreen;
   else if(StringFind(biasStr, "SELLS") >= 0)
      biasColor = clrRed;
   
   if(ObjectFind(gd_chartId, objName) < 0)
      ObjectCreate(gd_chartId, objName, OBJ_LABEL, 0, 0, 0);
   
   ObjectSetInteger(gd_chartId, objName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_YDISTANCE, 170);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(gd_chartId, objName, OBJPROP_TEXT, "BIAS: " + biasStr);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_COLOR, biasColor);
   ObjectSetInteger(gd_chartId, objName, OBJPROP_FONTSIZE, 11);
   ObjectSetString(gd_chartId, objName, OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| HELPER: Cleanup excess objects when count decreases              |
//+------------------------------------------------------------------+

void CleanupObjects(string prefix, int maxKeep)
{
   for(int i = maxKeep; i < maxKeep + 50; i++)
   {
      string objName = gd_prefix + prefix + IntegerToString(i);
      if(ObjectFind(gd_chartId, objName) >= 0)
         ObjectDelete(gd_chartId, objName);
      else
         break;  // No more objects with this prefix
   }
}

//+------------------------------------------------------------------+
//| MAIN DRAW FUNCTION — Called each update                          |
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
