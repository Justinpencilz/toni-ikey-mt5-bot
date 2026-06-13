//+------------------------------------------------------------------+
//|                                            RiskManager.mqh        |
//|        Position sizing and risk management                        |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"

#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| Calculate lot size based on risk % of account                    |
//+------------------------------------------------------------------+

double CalculateLotSize(
   string symbol,
   double riskPercent,
   double entryPrice,
   double stopLoss
)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (riskPercent / 100.0);

   double tickSize     = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue    = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double minLot       = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot       = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep      = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   if(tickSize == 0 || tickValue == 0) return minLot;

   // Calculate stop distance in ticks
   double stopDistance = MathAbs(entryPrice - stopLoss);
   double ticksAtRisk = stopDistance / tickSize;

   // Calculate lot size
   double lotSize = 0;
   if(ticksAtRisk > 0)
      lotSize = riskAmount / (ticksAtRisk * tickValue);

   // Round to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   // Clamp to min/max
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate stop loss for a POI entry                             |
//| SL = below the POI zone for buys, above the POI zone for sells  |
//+------------------------------------------------------------------+

double CalculateStopLoss(OrderBlock &poi, bool isBuy, double atr)
{
   if(isBuy)
   {
      // SL goes below the POI (below the order block low)
      // If Breaker Block: SL below the BB low
      // If Order Block: SL below the OB low
      return poi.priceLow - (atr * 0.3); // 0.3 ATR buffer below POI
   }
   else
   {
      // SL goes above the POI
      return poi.priceHigh + (atr * 0.3);
   }
}

//+------------------------------------------------------------------+
//| Calculate risk-reward ratio                                      |
//+------------------------------------------------------------------+

double CalculateRiskReward(double entry, double stopLoss, double takeProfit)
{
   double risk  = MathAbs(entry - stopLoss);
   double reward = MathAbs(takeProfit - entry);

   if(risk == 0) return 0;
   return reward / risk;
}

//+------------------------------------------------------------------+
//| Check if trade meets minimum risk-reward                         |
//+------------------------------------------------------------------+

bool MeetsRiskReward(double entry, double sl, double tp, double minRR)
{
   double rr = CalculateRiskReward(entry, sl, tp);
   return (rr >= minRR);
}

//+------------------------------------------------------------------+
//| ENUM for position sizing mode                                    |
//+------------------------------------------------------------------+

enum ENUM_RISK_MODE
{
   RISK_FIXED_LOT,       // Fixed lot size
   RISK_PERCENT_BALANCE  // % of account balance
};

//+------------------------------------------------------------------+
