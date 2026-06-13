//+------------------------------------------------------------------+
//|                                      Toni_Ikey_Structure.mq5     |
//|           Market Structure Indicator — Swing Points Only         |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"
#property description "Toni Iyke Market Structure — swing point detection only"
#property description "Draws ▲ ▼ at swing highs/lows with HH/HL/LH/LL labels."
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include "include/Strategy.mqh"
#include "include/MarketStructure.mqh"
#include "include/ChartDrawing.mqh"

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+

input ENUM_TIMEFRAMES InpTFTrend     = PERIOD_H1;   // Structure TF
input int    InpSwingLookback        = 100;          // Bars to scan
input int    InpSwingBars            = 3;            // Bars each side for swing confirmation

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

long g_chartId;

//+------------------------------------------------------------------+

void OnInit()
{
   g_chartId = ChartID();
   if(InpSwingBars < 1 || InpSwingBars > 10)
   {
      Print("ERROR: SwingBars must be between 1 and 10");
      return;
   }
   InitMarketStructure();
   DrawInit(g_chartId, _Symbol, "TI_");
   IndicatorSetString(INDICATOR_SHORTNAME, "TI Structure (" + EnumToString(InpTFTrend) + ")");
}

void OnDeinit(const int reason)
{
   DrawEraseAll();
}

//+------------------------------------------------------------------+
//| OnCalculate — runs once per new bar                              |
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
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(currentBarTime == lastBarTime && prev_calculated > 0)
      return rates_total;
   lastBarTime = currentBarTime;
   
   // Detect swing points + trend
   DetectSwingPoints(_Symbol, InpTFTrend, InpSwingLookback);
   DetermineTrend(_Symbol, InpTFTrend);
   
   // Draw swings + labels
   DrawAllStructures("");
   
   return rates_total;
}

//+------------------------------------------------------------------+
