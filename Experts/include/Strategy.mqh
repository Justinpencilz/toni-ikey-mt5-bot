//+------------------------------------------------------------------+
//|                                                Strategy.mqh      |
//|              Toni Iyke Advanced Class - Stage 1: Foundation      |
//|                     https://github.com/Justinpencilz             |
//+------------------------------------------------------------------+
#property copyright "Justinpencilz"
#property link      "https://github.com/Justinpencilz"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+

// --- Trend Direction (Definition 1) ---
enum ENUM_TREND_DIRECTION
{
   TREND_NONE       = 0,   // No clear trend or insufficient data
   TREND_UPTREND    = 1,   // Series of Higher Highs + Higher Lows
   TREND_DOWNTREND  = 2,   // Series of Lower Highs + Lower Lows
   TREND_RANGING    = 3    // Sideways between support and resistance
};

// --- Signal Type (Definition 2) ---
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE              = 0,   // No signal
   SIGNAL_MSS_REVERSAL      = 1,   // Market Structure Shift (Reversal)
   SIGNAL_BOS_CONTINUATION  = 2    // Break of Structure (Continuation)
};

// --- POI Type (Definition 5) ---
enum ENUM_POI_TYPE
{
   POI_NONE          = 0,
   POI_ORDER_BLOCK   = 1,   // Order Block (OB)
   POI_BREAKER_BLOCK = 2    // Breaker Block (BB) - broken zone, expecting retest
};

//+------------------------------------------------------------------+
//| STRUCTS                                                          |
//+------------------------------------------------------------------+

// --- Swing Point ---
struct SwingPoint
{
   datetime    time;            // When the swing occurred (bar open time)
   double      price;           // Price level (high for swing high, low for swing low)
   bool        isHigh;          // true = swing high, false = swing low
   int         barIndex;        // Bar index (0 = current)
};

// --- Trendline (Definition 1 - psychological lines) ---
struct TrendlineInfo
{
   bool        valid;           // Whether there are enough points to draw
   double      point1Price;     // Price of first anchor
   datetime    point1Time;      // Time of first anchor
   double      point2Price;     // Price of second anchor
   datetime    point2Time;      // Time of second anchor
   double      slope;           // Price change per bar
};

// --- Market Structure (Definition 1 + 2) ---
struct MarketStructure
{
   // Current trend
   ENUM_TREND_DIRECTION    trend;           // Current identified trend
   
   // Latest detected swings
   SwingPoint              lastSwingHigh;   // Most recent swing high
   SwingPoint              lastSwingLow;    // Most recent swing low
   SwingPoint              prevSwingHigh;   // Previous swing high (for HH/LH comparison)
   SwingPoint              prevSwingLow;    // Previous swing low (for HL/LL comparison)
   
   // Trend direction confirmation counts (Definition 1)
   int                     hhCount;         // Consecutive higher highs
   int                     hlCount;         // Consecutive higher lows
   int                     lhCount;         // Consecutive lower highs
   int                     llCount;         // Consecutive lower lows
   
   // MSS (Reversal) - Definition 2
   bool                    hasMSS;          // Market Structure Shift detected
   datetime                mssTime;         // When MSS occurred
   double                  mssBrokenLevel;  // The level that was broken (last HL or LH)
   bool                    mssIsBullish;    // true = MSS to upside (buy reversal), false = sell
   
   // BOS (Continuation) - Definition 2
   bool                    hasBOS;          // Break of Structure detected
   int                     bosBreaksCount;  // Number of zones broken (1=single, 2+=multiple)
   bool                    bosIsBullish;    // true = BOS to upside, false = downside
   
   // Trendlines (Definition 1)
   TrendlineInfo           uptrendLine;     // Connecting higher lows
   TrendlineInfo           downtrendLine;   // Connecting lower highs
   TrendlineInfo           rangeResistance; // Horizontal resistance
   TrendlineInfo           rangeSupport;    // Horizontal support
};

//+------------------------------------------------------------------+
//| CONSTANTS                                                        |
//+------------------------------------------------------------------+

// --- Swing Detection ---
#define SWING_BARS_LOOKBACK    3     // Bars on each side to confirm swing
#define MIN_SWING_ATR_FACTOR   0.2   // Min swing size as fraction of ATR

// --- MSS Confirmation (Definition 2) ---
// MSS requires price to break the swing point AND close beyond it
#define MSS_CLOSE_BEYOND       true  // Must close beyond the broken level

// --- BOS Zone Counting ---
#define BOS_MIN_MULTIPLE       2     // Minimum zones body-broken for multiple BOS
#define BOS_BODY_ONLY          1     // Only count breaks where candle CLOSES beyond level
#define BOS_LOOKBACK_BARS      30    // Bars to look back for zone counting

//+------------------------------------------------------------------+
