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

extern int  SignalId = 1; // Open signal system Id form 1 to 8
extern bool CloseSignal = false; // Close signal system

string _symbol;
int _period;
double _point;
int _lastBarNumber;
int _lastSignal;

CFileLog *_log;
PSSignals* _signals;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    _symbol = Symbol();
    _period = Period();

    string fileName = StringConcatenate("PSea_", _symbol, "_", _period, "_", SignalId, ".log");
    //Initialise _log with filename = "example.log", Level = WARNING and Print to console
    _log = new CFileLog(fileName, INFO, true, IsOptimization());
    MarketFileLog = _log;

    _signals = new PSSignals(_log, _symbol, _period, SignalId);

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

   GlobalVariablesDeleteAll();
   delete _signals;
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
    if(_lastSignal != OP_NONE)
    {
        int closeSignal = _signals.Close(_lastSignal, CloseSignal);
        if (closeSignal != OP_NONE) 
        {
            _lastSignal = OP_NONE;
            VLineCreate(closeSignal == OP_BUY ? clrHotPink : clrSkyBlue, closeSignal == OP_BUY ? "Buy close" : "Sell close", STYLE_DOT);
        }
    }

    // Open signal
    int openSignal = _signals.Open();
    if(openSignal != OP_NONE)
    {
        _lastSignal = openSignal;
        VLineCreate(openSignal == OP_BUY ? clrRed : clrBlue, openSignal == OP_BUY ? "Buy open" : "Sell open", STYLE_DASH);
    }
}