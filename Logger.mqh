//###<Experts/MABollingerBands/MABollingerBands.mq5>

class Logger {

private:
    static void Log(string level, string message) {
        PrintFormat("%s: %s", level, message);
    }

public:
    static void PrintLastError(string functionName, int lineNumber) {
        Log("FATAL ERROR", StringFormat("func: %s, line: %d, errorCode: %d", functionName, lineNumber, GetLastError()));
    }

    static void Debug(string message) {
        // Log("DEBUG", message);
    }

    static void Info(string message) {
        Log("INFO", message);
    }

    static void Warn(string message) {
        Log("WARN", message);
    }

    static void Error(string message) {
        Log("ERROR", message);
    }
};