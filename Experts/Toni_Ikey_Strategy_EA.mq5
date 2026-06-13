//+------------------------------------------------------------------+
//|                                    Toni_Ikey_Strategy_EA.mq5     |
//|     Expert Advisor based on Toni Iyke Advanced Class strategy    |
//|     4 Pillars: Market Structure → Liquidity → POI → Bias        |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"
#property description "Toni Iyke Advanced Class Strategy EA"
#property description "Built on 4 pillars:"
#property description "  1. Market Structure (MSS / MBS)"
#property description "  2. Inducement (first valid pullback)"
#property description "  3. Points of Interest (OB / Breaker Block)"
#property description "  4. Directional Bias + Liquidity TP"

#include "include/Strategy.mqh"
#include "include/MarketStructure.mqh"
#include "include/OrderBlocks.mqh"
#include "include/Inducement.mqh"
#include "include/Liquidity.mqh"
#include "include/DirectionalBias.mqh"
#include "include/RiskManager.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

// --- Timeframe Settings ---
input group "=== Timeframe Settings ==="
input ENUM_TIMEFRAMES InpBiasTF       = PERIOD_D1;    // Bias timeframe
input ENUM_TIMEFRAMES InpEntryTF      = PERIOD_H1;    // Entry timeframe

// --- Market Structure ---
input group "=== Market Structure ==="
input int    InpSwingLookback         = 50;           // Swing lookback bars
input double InpMinSwingPercent       = 0.3;          // Min swing size (% of ATR)
input int    InpMSSConfirmationBars   = 1;            // MSS confirmation bars

// --- Inducement ---
input group "=== Inducement ==="
input double InpIDMBodyPercent        = 0.3;          // IDM body close % to take out

// --- POI Selection ---
input group "=== POI (Point of Interest) ==="
input double InpMaxPOIDistance        = 3.0;          // Max POI distance from IDM (ATR)

// --- Risk Management ---
input group "=== Risk Management ==="
input ENUM_RISK_MODE InpRiskMode      = RISK_PERCENT_BALANCE; // Risk mode
input double InpRiskPercent           = 1.0;          // Risk % per trade
input double InpFixedLot              = 0.01;         // Fixed lot size
input double InpMinRR                 = 1.5;          // Min risk-reward ratio

// --- TP Settings ---
input group "=== Take Profit ==="
input bool   InpUseTrendlineTP        = true;         // Use trendline liquidity TP
input bool   InpUseRangeTP            = true;         // Use range liquidity TP
input bool   InpUseLastSwingTP        = true;         // Use last swing TP

// --- Trade Filters ---
input group "=== Trade Filters ==="
input bool   InpUseBiasFilter         = true;         // Only trade with daily bias
input bool   InpReversalOnly          = false;        // MSS reversals only (no MBS)
input bool   InpContinuationOnly      = false;        // MBS continuations only (no MSS)

// --- Misc ---
input group "=== Misc ==="
input int    InpMagicNumber           = 202401;       // EA magic number
input string InpComment               = "ToniIkye";   // Trade comment

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

StrategySettings g_settings;
MarketStructure  g_msEntry;     // Market structure on entry TF
TradeSetup       g_setup;       // Current trade setup
int              g_handleATR;   // ATR indicator handle
datetime         g_lastBarTime; // Last processed bar time

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   // Populate settings
   g_settings.biasTimeframe       = InpBiasTF;
   g_settings.entryTimeframe      = InpEntryTF;
   g_settings.swingLookback       = InpSwingLookback;
   g_settings.minSwingPercent     = InpMinSwingPercent;
   g_settings.mssConfirmationBars = InpMSSConfirmationBars;
   g_settings.inducementBodyPercent = InpIDMBodyPercent;
   g_settings.maxPoiDistanceATR   = InpMaxPOIDistance;
   g_settings.riskPercent         = InpRiskPercent;
   g_settings.riskRewardMin       = InpMinRR;
   g_settings.useTrendlineTP      = InpUseTrendlineTP;
   g_settings.useRangeTP          = InpUseRangeTP;
   g_settings.useLastSwingTP      = InpUseLastSwingTP;

   // Create ATR handle
   g_handleATR = iATR(_Symbol, InpEntryTF, 14);
   if(g_handleATR == INVALID_HANDLE)
   {
      Print("Failed to create ATR handle");
      return INIT_FAILED;
   }

   g_lastBarTime = 0;

   // Log startup info
   Print("═══ Toni Iyke Strategy EA ═══");
   Print("Symbol: ", _Symbol, " | Entry TF: ", EnumToString(InpEntryTF));
   Print("Bias TF: ", EnumToString(InpBiasTF));
   Print("Magic: ", InpMagicNumber, " | Risk: ", InpRiskPercent, "%");
   Print("═══ Ready ═══");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   if(g_handleATR != INVALID_HANDLE)
      IndicatorRelease(g_handleATR);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // Only process on new bar to avoid repainting
   datetime currentBarTime = iTime(_Symbol, InpEntryTF, 0);
   if(currentBarTime == g_lastBarTime) return;
   g_lastBarTime = currentBarTime;

   // Run the full strategy scan
   RunStrategy();
}

//+------------------------------------------------------------------+
//| Main strategy scan                                               |
//+------------------------------------------------------------------+

void RunStrategy()
{
   // ─── Phase 1: Determine Directional Bias ───
   ENUM_TREND_DIRECTION bias = GetDirectionalBias(_Symbol);
   Print("═══ Scan ═══ Bias: ", GetBiasDescription(bias));

   // ─── Phase 2: Detect Market Structure on Entry TF ───
   InitMarketStructure();
   DetectSwingPoints(_Symbol, InpEntryTF, InpSwingLookback);
   g_msEntry.trend = DetermineTrend(_Symbol, InpEntryTF);

   bool hasMSS = DetectMSS(_Symbol, InpEntryTF, InpSwingLookback);
   bool hasMBS = DetectMBS(_Symbol, InpEntryTF, InpSwingLookback);

   if(!hasMSS && !hasMBS)
   {
      Print("No MSS or MBS detected — waiting for structure");
      return;
   }

   // Apply trade filters
   if(InpReversalOnly && !hasMSS) return;
   if(InpContinuationOnly && !hasMBS) return;

   // ─── Phase 3: Detect Inducement ───
   bool hasIDM = DetectInducement(_Symbol, InpEntryTF, g_msEntry, InpIDMBodyPercent);
   if(!hasIDM)
   {
      Print("No inducement detected — waiting for pullback");
      return;
   }

   // ─── Phase 4: Select Best POI using 4 Rules ───
   bool isBuySignal = (g_msEntry.trend == TREND_UPTREND);

   // Check bias alignment
   if(InpUseBiasFilter && !AlignsWithBias(isBuySignal))
   {
      Print("Signal against daily bias — skipping");
      return;
   }

   OrderBlock bestPOI = SelectBestPOI(g_msEntry, g_inducement, _Symbol, InpEntryTF, isBuySignal);

   if(bestPOI.type == POI_NONE)
   {
      Print("No valid POI found after applying 4 rules");
      return;
   }

   // ─── Phase 5: Calculate Entry, SL, TP ───
   double atr[1];
   if(CopyBuffer(g_handleATR, 0, 0, 1, atr) < 1) return;

   double entryPrice = 0;
   double stopLoss   = 0;

   if(isBuySignal)
   {
      entryPrice = bestPOI.priceLow;   // Entry at POI low
      stopLoss   = CalculateStopLoss(bestPOI, true, atr[0]);
   }
   else
   {
      entryPrice = bestPOI.priceHigh;  // Entry at POI high
      stopLoss   = CalculateStopLoss(bestPOI, false, atr[0]);
   }

   double takeProfit = CalculateTakeProfit(
      _Symbol, InpEntryTF, g_msEntry, entryPrice, isBuySignal, g_settings
   );

   // ─── Phase 6: Risk Check ───
   if(!MeetsRiskReward(entryPrice, stopLoss, takeProfit, InpMinRR))
   {
      Print("Risk-reward too low — RR: ",
         CalculateRiskReward(entryPrice, stopLoss, takeProfit), " < Min: ", InpMinRR);
      return;
   }

   // ─── Phase 7: Execute Trade ───
   double lotSize = 0;
   if(InpRiskMode == RISK_FIXED_LOT)
      lotSize = InpFixedLot;
   else
      lotSize = CalculateLotSize(_Symbol, InpRiskPercent, entryPrice, stopLoss);

   ExecuteTrade(isBuySignal, lotSize, entryPrice, stopLoss, takeProfit, bestPOI);

   // Log the full setup
   Print("═══ TRADE SIGNAL ═══");
   Print("Type: ", isBuySignal ? "BUY" : "SELL");
   Print("Signal: ", hasMSS ? "MSS Reversal" : "MBS Continuation");
   Print("POI: ", bestPOI.type == POI_ORDER_BLOCK ? "Order Block" : "Breaker Block");
   Print("Entry: ", entryPrice, " | SL: ", stopLoss, " | TP: ", takeProfit);
   Print("Lot: ", lotSize, " | RR: ", CalculateRiskReward(entryPrice, stopLoss, takeProfit));
   Print("═══ ════════════ ═══");
}

//+------------------------------------------------------------------+
//| Execute market order                                             |
//+------------------------------------------------------------------+

void ExecuteTrade(
   bool isBuy,
   double lotSize,
   double entryPrice,
   double stopLoss,
   double takeProfit,
   OrderBlock &poi
)
{
   // Check if we already have a position with this magic number
   if(PositionSelectByMagic(_Symbol, InpMagicNumber))
   {
      Print("Position already exists — skipping new entry");
      return;
   }

   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   request.action    = TRADE_ACTION_DEAL;
   request.symbol    = _Symbol;
   request.volume    = lotSize;
   request.type      = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price     = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                             : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl        = stopLoss;
   request.tp        = takeProfit;
   request.deviation = 10;
   request.magic     = InpMagicNumber;
   request.comment   = InpComment;

   if(OrderSend(request, result))
   {
      Print("Order executed successfully! Ticket: ", result.order);
      Print("Entry: ", request.price, " | SL: ", stopLoss, " | TP: ", takeProfit);
   }
   else
   {
      Print("Order failed: ", result.retcode, " — ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Check if we have an open position with this magic number          |
//+------------------------------------------------------------------+

bool PositionSelectByMagic(string symbol, int magic)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == symbol &&
            PositionGetInteger(POSITION_MAGIC) == magic)
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
