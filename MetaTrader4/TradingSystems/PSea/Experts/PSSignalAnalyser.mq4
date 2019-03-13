//+------------------------------------------------------------------+
//|                                             PSSignalAnalyser.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Checking Open and Close signals send form the PSSignal class.
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "3.00"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int OpenSignalId = 1; // Open signal system Id form 1 to 9
extern int CloseSignalId = 0; // Close signal system 1 to 3 (0 - no signal)
extern double DynOpenCoeff = 0.07; // Dynamic open order coefficient 0.01 to 0.2. Default: 0.07
extern double DynCloseCoeff = 0.07; // Dynamic close order coefficient 0.01 to 0.2. Default: 0.07

string _symbol;
int _period;
double _point;
int _lastBarNumber;
int _lastSignal;

CFileLog *_log;
PSSignals* _signals;
PSMarket *_market;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    _symbol = Symbol();
    _period = Period();

    string fileName = StringConcatenate("PSSignalAnalyser_", _symbol, "_", _period, "_", OpenSignalId, ".log");
    //Initialise _log with filename = "example.log", Level = WARNING and Print to console
    _log = new CFileLog(fileName, INFO, true, IsOptimization());

    _signals = new PSSignals(_log, _symbol, _period, OpenSignalId, Digits, DynOpenCoeff, CloseSignalId, DynCloseCoeff);

	_market = new PSMarket(_log, _symbol, _period, Digits);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }

    _lastBarNumber = Bars;
    _lastSignal = OP_NONE;

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    delete _signals;
    delete _market;
    delete _log;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsTradeAllowed()) 
    {
        return;
    }

    int currentBarNumber = Bars;

    // Process logics only if new bar is arrived.
    if(currentBarNumber == _lastBarNumber)
    {
        return;
    }
    _lastBarNumber = currentBarNumber;

    // Close signal
    if(CloseSignalId != 0 && _lastSignal != OP_NONE)
    {
        int closeSignal = _signals.Close(_lastSignal);
        if (closeSignal != OP_NONE) 
        {
            _lastSignal = OP_NONE;
            _market.DrawVLine(_market.OrderTypeToColor(closeSignal, false), StringConcatenate(_market.OrderTypeToString(closeSignal), " close"), STYLE_DOT);
        }
    }

    // Open signal
    int openSignal = _signals.Open();
    if(OpenSignalId != 0 && openSignal != OP_NONE)
    {
        _lastSignal = openSignal;
        _market.DrawVLine(_market.OrderTypeToColor(openSignal, true), StringConcatenate(_market.OrderTypeToString(openSignal), " open"), STYLE_DASH);
    }
}