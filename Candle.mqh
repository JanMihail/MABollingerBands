//###<Experts/MABollingerBands/MABollingerBands.mq5>

enum CandleType { BULL, BEAR, DOJI };

class Candle {

private:
    datetime time;
    double open;
    double high;
    double low;
    double close;
    double spread;

public:
    Candle() {}

    Candle(datetime pTime, double pOpen, double pHigh, double pLow, double pClose, double pSpread)
        : time(pTime), open(pOpen), high(pHigh), low(pLow), close(pClose), spread(pSpread) {}

    Candle(const Candle &candle) {
        this.time = candle.time;
        this.open = candle.open;
        this.high = candle.high;
        this.low = candle.low;
        this.close = candle.close;
        this.spread = candle.spread;
    }

    datetime getTime() const {
        return time;
    }

    double getOpen() const {
        return open;
    }

    double getHigh() const {
        return high;
    }

    double getLow() const {
        return low;
    }

    double getClose() const {
        return close;
    }

    double getSpread() const {
        return spread;
    }

    CandleType getType() const {
        if (open == close) {
            return DOJI;
        }

        return open < close ? BULL : BEAR;
    }

    string toString() const {
        return StringFormat(
            "Candle(time=%s, open=%s, high=%s, low=%s, close=%s, spread=%s)",
            TimeToString(time),
            DoubleToString(open),
            DoubleToString(high),
            DoubleToString(low),
            DoubleToString(close),
            DoubleToString(spread)
        );
    }
};