#include "Candle.mqh"
#include "Logger.mqh"
#include <Trade/Trade.mqh>

input int MA_FAST_PERIOD = 15;
input int MA_SLOW_PERIOD = 55;

input int BANDS_PERIOD = 20;
input int BANDS_SHIFT = 0;
input double BANDS_DEVIATION = 2.0;

input int BANDS_STOP_PERIOD = 20;
input int BANDS_STOP_SHIFT = 0;
input double BANDS_STOP_DEVIATION = 3.0;

input double LOT = 0.01;
input ulong EXPERT_MAGIC = 777777;

// Indicator handles
int maFastHandle;
int maSlowHandle;
int bandsHandle;
int bandsStopHandle;

// Indicator buffers
double maFastBuffer[];
double maSlowBuffer[];
double bandsBuffer[];
double bandsStopBuffer[];

// State variables
enum TrendDirection { UP, DOWN } trendDirection;

double bandsUpper;
double bandsMiddle;
double bandsLower;

double bandsStopUpper;
double bandsStopMiddle;
double bandsStopLower;

Candle currentCandle;

bool positionExist = false;

int OnInit() {
    Logger::Info("Initialize...");

    // Moving Average
    maFastHandle = iMA(Symbol(), PERIOD_CURRENT, MA_FAST_PERIOD, 0, MODE_EMA, PRICE_CLOSE);
    maSlowHandle = iMA(Symbol(), PERIOD_CURRENT, MA_SLOW_PERIOD, 0, MODE_EMA, PRICE_CLOSE);

    // Bollinger Bands
    bandsHandle = iBands(Symbol(), PERIOD_CURRENT, BANDS_PERIOD, BANDS_SHIFT, BANDS_DEVIATION, PRICE_CLOSE);
    bandsStopHandle =
        iBands(Symbol(), PERIOD_CURRENT, BANDS_STOP_PERIOD, BANDS_STOP_SHIFT, BANDS_STOP_DEVIATION, PRICE_CLOSE);

    Logger::Info("Initialize complete!");
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
    Logger::Info("Deinitialize...");

    IndicatorRelease(maFastHandle);
    IndicatorRelease(maSlowHandle);
    IndicatorRelease(bandsHandle);
    IndicatorRelease(bandsStopHandle);

    Logger::Info("Deinitialize complete! ReasonCode: " + IntegerToString(reason));
}

void OnTick() {
    updateTrendDirectionState();
    updateBollingerBandsState();
    updateBollingerBandsStopState();
    updateCurrentBarState();
    updatePositionsState();
    findEntryPointAndTrade();
}

void updateTrendDirectionState() {
    int res = CopyBuffer(maFastHandle, 0, 0, 1, maFastBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    res = CopyBuffer(maSlowHandle, 0, 0, 1, maSlowBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    Logger::Debug("MA Fast = " + DoubleToString(maFastBuffer[0]));
    Logger::Debug("MA Slow = " + DoubleToString(maSlowBuffer[0]));

    trendDirection = maFastBuffer[0] > maSlowBuffer[0] ? UP : DOWN;
    Logger::Debug("Trend Direction = " + EnumToString(trendDirection));
}

void updateBollingerBandsState() {
    int res = CopyBuffer(bandsHandle, 0, 0, 1, bandsBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsMiddle = bandsBuffer[0];

    res = CopyBuffer(bandsHandle, 1, 0, 1, bandsBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsUpper = bandsBuffer[0];

    res = CopyBuffer(bandsHandle, 2, 0, 1, bandsBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsLower = bandsBuffer[0];

    Logger::Debug("Bands Upper = " + DoubleToString(bandsUpper));
    Logger::Debug("Bands Lower = " + DoubleToString(bandsLower));
    Logger::Debug("Bands Middle = " + DoubleToString(bandsMiddle));
}

void updateBollingerBandsStopState() {
    int res = CopyBuffer(bandsStopHandle, 0, 0, 1, bandsStopBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsStopMiddle = bandsStopBuffer[0];

    res = CopyBuffer(bandsStopHandle, 1, 0, 1, bandsStopBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsStopUpper = bandsStopBuffer[0];

    res = CopyBuffer(bandsStopHandle, 2, 0, 1, bandsStopBuffer);

    if (res < 0) {
        Logger::PrintLastError(__FUNCSIG__, __LINE__);
        return;
    }

    bandsStopLower = bandsStopBuffer[0];

    Logger::Debug("Bands Stop Upper = " + DoubleToString(bandsStopUpper));
    Logger::Debug("Bands Stop Lower = " + DoubleToString(bandsStopLower));
    Logger::Debug("Bands Stop Middle = " + DoubleToString(bandsStopMiddle));
}

void updateCurrentBarState() {
    currentCandle = Candle(
        iTime(Symbol(), PERIOD_CURRENT, 0),
        iOpen(Symbol(), PERIOD_CURRENT, 0),
        iHigh(Symbol(), PERIOD_CURRENT, 0),
        iLow(Symbol(), PERIOD_CURRENT, 0),
        iClose(Symbol(), PERIOD_CURRENT, 0),
        iSpread(Symbol(), PERIOD_CURRENT, 0) * 0.00001
    );

    Logger::Debug("Current Candle: " + currentCandle.toString());
}

void updatePositionsState() {
    if (!positionExist) {
        return;
    }

    if (PositionsTotal() == 0) {
        Logger::Info("All positions is closed");
        positionExist = false;
    }
}

void findEntryPointAndTrade() {
    if (positionExist) {
        return;
    }

    if (trendDirection == UP) {
        findEntryPointBuy();
    } else {
        findEntryPointSell();
    }
}

void findEntryPointBuy() {
    if (currentCandle.getLow() <= bandsLower) {
        CTrade trade;
        bool res = trade.Buy(LOT, Symbol(), 0.0, bandsStopLower, bandsMiddle);

        if (!res) {
            Logger::PrintLastError(__FUNCSIG__, __LINE__);
            return;
        }

        positionExist = true;
    }
}

void findEntryPointSell() {
    if (currentCandle.getHigh() >= bandsUpper) {
        CTrade trade;
        bool res = trade.Sell(LOT, Symbol(), 0.0, bandsStopUpper, bandsMiddle);

        if (!res) {
            Logger::PrintLastError(__FUNCSIG__, __LINE__);
            return;
        }

        positionExist = true;
    }
}