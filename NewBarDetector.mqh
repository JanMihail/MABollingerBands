//###<Experts/MABollingerBands/MABollingerBands.mq5>

#include "Candle.mqh"

class NewBarDetector {

private:
    ENUM_TIMEFRAMES timeframe;
    Candle lastDetectedCandle;

public:
    NewBarDetector(ENUM_TIMEFRAMES pTimeframe) : timeframe(pTimeframe) {
        this.lastDetectedCandle = Candle(
            iTime(Symbol(), this.timeframe, 1),
            iOpen(Symbol(), this.timeframe, 1),
            iHigh(Symbol(), this.timeframe, 1),
            iLow(Symbol(), this.timeframe, 1),
            iClose(Symbol(), this.timeframe, 1)
        );
    }

    bool update() {
        datetime currentTime = iTime(Symbol(), this.timeframe, 1);

        if (currentTime > lastDetectedCandle.getTime()) {
            this.lastDetectedCandle = Candle(
                currentTime,
                iOpen(Symbol(), this.timeframe, 1),
                iHigh(Symbol(), this.timeframe, 1),
                iLow(Symbol(), this.timeframe, 1),
                iClose(Symbol(), this.timeframe, 1)
            );

            Logger::Debug("LastDetectedCandle: " + lastDetectedCandle.toString());
            return true;
        }

        return false;
    }

    Candle getLastDetectedCandle() const {
        return this.lastDetectedCandle;
    }
};