//+------------------------------------------------------------------+
//|                                                Strategy.mqh      |
//|              Toni Iyke Advanced Class - Core Framework           |
//|                     https://github.com/Justinpencilz             |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+

// --- Trend Direction ---
enum ENUM_TREND_DIRECTION
{
   TREND_NONE      = 0,   // No clear trend
   TREND_UPTREND   = 1,   // Higher Highs + Higher Lows
   TREND_DOWNT REND = 2,   // Lower Highs + Lower Lows
   TREND_RANGING   = 3    // Sideways / consolidation
};

// --- Entry Signal Type ---
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE             = 0,   // No signal
   SIGNAL_MSS_REVERSAL     = 1,   // Market Structure Shift (Reversal)
   SIGNAL_MBS_CONTINUATION = 2    // Multiple Break of Structure (Continuation)
};

// --- POI (Point of Interest) Type ---
enum ENUM_POI_TYPE
{
   POI_NONE         = 0,
   POI_ORDER_BLOCK  = 1,   // Order Block (OB)
   POI_BREAKER_BLOCK= 2    // Breaker Block (BB) - failed OB
};

// --- Position Status ---
enum ENUM_POSITION_REASON
{
   REASON_ENTRY     = 0,   // Entry triggered
   REASON_TP_HIT    = 1,   // Take profit reached
   REASON_SL_HIT    = 2,   // Stop loss reached
   REASON_INVALID   = 3    // POI invalidated
};

//+------------------------------------------------------------------+
//| STRUCTS                                                          |
//+------------------------------------------------------------------+

// --- Swing Point ---
struct SwingPoint
{
   datetime    time;           // Time of the swing
   double      price;          // Price level
   bool        isHigh;         // true = swing high, false = swing low
   int         index;          // Bar index
};

// --- Market Structure ---
struct MarketStructure
{
   ENUM_TREND_DIRECTION    trend;       // Current trend
   SwingPoint              lastHH;      // Last higher high
   SwingPoint              lastHL;      // Last higher low
   SwingPoint              lastLH;      // Last lower high
   SwingPoint              lastLL;      // Last lower low
   bool                    hasMSS;      // Market Structure Shift detected
   datetime                mssTime;     // When MSS occurred
   double                  mssLevel;    // The level that was broken for MSS
   bool                    hasMBS;      // Multiple Break of Structure
   int                     breaksCount; // Number of zones broken for MBS
};

// --- Order Block ---
struct OrderBlock
{
   ENUM_POI_TYPE   type;          // OB or BB
   datetime        timeStart;     // Start of OB formation
   datetime        timeEnd;       // End of OB formation
   double          priceHigh;     // High of OB zone
   double          priceLow;      // Low of OB zone
   bool            bullish;       // Bullish OB or Bearish OB
   bool            isMitigated;   // Whether price has touched this OB
   bool            isDisqualified;// Disqualified by rule #3
   double          distanceToIDM; // Distance from inducement (Rule #4)
};

// --- Inducement ---
struct Inducement
{
   bool        isValid;           // Is a valid inducement detected
   datetime    time;              // When inducement happened
   double      level;             // The level taken out (body close of MSS/MBS)
   double      pullbackLow;       // Low of the pullback
   double      pullbackHigh;      // High of the pullback
};

// --- Liquidity Zone ---
struct LiquidityZone
{
   double      priceHigh;         // Top of liquidity zone
   double      priceLow;          // Bottom of liquidity zone
   bool        isBuySide;         // Buy-side liquidity (above)
   bool        isSellSide;        // Sell-side liquidity (below)
   bool        isTrendline;       // Trend line liquidity
   bool        isRange;           // Range liquidity
};

// --- Trade Setup ---
struct TradeSetup
{
   bool                isValid;        // Is this setup valid for entry
   ENUM_SIGNAL_TYPE    signalType;     // MSS reversal or MBS continuation
   ENUM_POI_TYPE       poiType;        // OB or BB
   bool                isBuy;          // true=buy, false=sell
   double              entryPrice;     // Entry price
   double              stopLoss;       // Stop loss
   double              takeProfit;     // Take profit
   double              lotSize;        // Position size
   OrderBlock          poi;            // The selected POI
   Inducement          inducement;     // The inducement that triggered
   MarketStructure     structure;      // Current market structure
   LiquidityZone       tpZone;         // TP target liquidity zone
   datetime            timestamp;      // When signal was generated
};

//+------------------------------------------------------------------+
//| CONSTANTS                                                        |
//+------------------------------------------------------------------+

#define MSS_BODY_CLOSE_PERCENT  0.3   // % of candle body that must be taken out for inducement
#define MIN_SWING_DISTANCE_PIPS 10    // Min pips between swings to be valid
#define OB_MIN_BARS             1     // Min bars in an order block
#define MAX_POI_DISTANCE_FACTOR 3.0   // Max distance from IDM as multiple of ATR

//+------------------------------------------------------------------+
//| GLOBAL SETTINGS (configured via EA inputs)                        |
//+------------------------------------------------------------------+

struct StrategySettings
{
   // Timeframes
   ENUM_TIMEFRAMES biasTimeframe;      // Daily timeframe for bias (default: PERIOD_D1)
   ENUM_TIMEFRAMES entryTimeframe;     // Entry timeframe (default: PERIOD_H1)

   // Market Structure
   int    swingLookback;               // Bars to look back for swing points (default: 50)
   double minSwingPercent;             // Min swing size as % of ATR (default: 0.3)
   int    mssConfirmationBars;         // Bars after MSS to confirm (default: 1)

   // Inducement
   double inducementBodyPercent;       // % of body close to take out (default: 0.3)

   // POI selection
   double maxPoiDistanceATR;           // Max POI distance from IDM in ATR (default: 3.0)

   // Risk Management
   double riskPercent;                 // Risk per trade % of balance (default: 1.0)
   double riskRewardMin;               // Min risk-reward ratio (default: 1.5)

   // Liquidity / TP
   bool   useTrendlineTP;              // Use trendline liquidity for TP (default: true)
   bool   useRangeTP;                  // Use range liquidity for TP (default: true)
   bool   useLastSwingTP;              // Use last swing HL for TP (default: true)
};
//+------------------------------------------------------------------+
